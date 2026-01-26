#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import asyncio
import io
import psycopg2
import time
import syslog
import csv
import ipaddress
import functools
import re


def run_in_foreground(task, *, loop=None):
    """Runs event loop in current thread until the given task completes

    Returns the result of the task.
    For more complex conditions, combine with asyncio.wait()
    To include a timeout, combine with asyncio.wait_for()
    """
    if loop is None:
        loop = asyncio.get_event_loop()
    return loop.run_until_complete(asyncio.ensure_future(task, loop=loop))


class Server:
    def __init__(self, policyHandler=None):
        self.policyHandler = policyHandler

    async def handle_request(self, reader, writer):
        while True:
            request = {}
            line = (await reader.readline()).decode()
            if line == "":
                return
            line = line.rstrip()
            while line != "":
                try:
                    (attribute, value) = line.split("=", 1)
                    request[attribute] = value
                except ValueError:
                    pass
                line = (await reader.readline()).decode()
                if line == "":
                    reader.close()
                    raise Exception("EOF mid-request")

                line = line.rstrip()

            # For submission servers behind dovecot-submission, sasl_username is not present. Use sender
            if ('sasl_username' not in request or request['sasl_username'] == '') and 'sender' in request: 
                request['sasl_username'] = request['sender']

            response = await self.policyHandler.handle_request(request)

            if "action" not in response:
                raise Exception("Response did not contain an action")
            if "message" in response:
                result = "action=%s %s\n\n" % (response["action"], response["message"])
            else:
                result = "action=%s\n\n" % (response["action"],)

            writer.write(result.encode("utf-8"))
            await writer.drain()


class BasePolicyHandler:
    log_initalized = False

    def __init__(self):
        pass

    def log(self, message, level):
        if not BasePolicyHandler.log_initalized:
            syslog.openlog("outbound-policyd", syslog.LOG_PID, syslog.LOG_MAIL)
        syslog.syslog(level, message)

    def log_with_id(self, request, message, level):
        if "queue_id" not in request or request["queue_id"] == "":
            queue_id = "NOQUEUE"
        else:
            queue_id = request["queue_id"]
        self.log("%s: %s" % (queue_id, message), level)

    async def handle_request(self, request):
        return {
            "action": "defer_if_permit Service temporarily unavailable (Demo policy handler)"
        }


class FilteringPolicyHandler(BasePolicyHandler):
    def __init__(self, matchPolicyHandler, nonmatchPolicyHandler):
        BasePolicyHandler.__init__(self)
        self.matchPolicyHandler = matchPolicyHandler
        self.nonmatchPolicyHandler = nonmatchPolicyHandler

    async def handle_request(self, request):
        if await self.match(request):
            if self.matchPolicyHandler is None:
                return {"action": "OK"}
            return await self.matchPolicyHandler.handle_request(request)
        if self.nonmatchPolicyHandler is None:
            return {"action": "OK"}

        return await self.nonmatchPolicyHandler.handle_request(request)

    async def match(self, request):
        return false


class RCPTFilterPolicyHandler(FilteringPolicyHandler):
    def __init__(self, matchPolicyHandler, nonmatchPolicyHandler):
        FilteringPolicyHandler.__init__(self, matchPolicyHandler, nonmatchPolicyHandler)

    async def match(self, request):
        if (
            request["protocol_name"] not in ("SMTP", "ESMTP")
            or request["protocol_state"] != "RCPT"
            or request["sasl_username"] == ""
        ):
            return False
        if "@" not in request["sasl_username"]:
            self.log_with_id(
                request,
                "Received non-empty sasl_username without domain: %s"
                % (request["sasl_username"],),
                syslog.LOG_ERR,
            )
            return False
        if "@" not in request["recipient"]:
            self.log_with_id(
                request,
                "Received recipient without domain: %s" % (request["recipient"],),
                syslog.LOG_ERR,
            )
            return False
        return True


class GeoIPFilterPolicyHandler(FilteringPolicyHandler):
    def __init__(self, matchPolicyHandler, nonmatchPolicyHandler, country_iso_codes, forceNonMatchNetworks = [], forceMatchNetworks = []):
        FilteringPolicyHandler.__init__(self, matchPolicyHandler, nonmatchPolicyHandler)
        self.forceNonMatchNetworks = forceNonMatchNetworks
        self.forceMatchNetworks = forceMatchNetworks
        with open(
            "%s/%s"
            % (
                os.path.dirname(os.path.abspath(__file__)),
                "GeoLite2-Country-Locations-en.csv",
            ),
            "r",
        ) as csvFile:
            reader = csv.reader(csvFile, delimiter=",", quotechar='"')
            row = reader.__next__()
            iso_code_index = row.index("country_iso_code")
            geoname_id_index = row.index("geoname_id")
            self.matchCountries = {
                row[geoname_id_index]: row[iso_code_index]
                for row in reader
                if row[iso_code_index] in country_iso_codes
            }
        with open(
            "%s/%s"
            % (
                os.path.dirname(os.path.abspath(__file__)),
                "GeoLite2-Country-Blocks-IPv4.csv",
            ),
            "r",
        ) as csvFile:
            reader = csv.reader(csvFile, delimiter=",", quotechar='"')
            row = reader.__next__()
            network_index = row.index("network")
            geoname_id_index = row.index("geoname_id")
            self.matchNetworks = {
                ipaddress.IPv4Network(row[network_index]): self.matchCountries[
                    row[geoname_id_index]
                ]
                for row in reader
                if row[geoname_id_index] in self.matchCountries
            }

    async def match(self, request):
        ip = ipaddress.ip_address(request["client_address"])
        for network in self.matchNetworks:
            if ip in network:
                # self.log_with_id(request, 'Matched GeoIP filter', syslog.LOG_INFO)
                return True
        for network in self.forceNonMatchNetworks:
            # self.log_with_id(request, 'Negatively matched GeoIP filter', syslog.LOG_INFO)
            if ip in network:
                return False
        return False


class ClientNameFilterPolicyHandler(FilteringPolicyHandler):
    def __init__(self, matchPolicyHandler, nonmatchPolicyHandler, matchNames):
        FilteringPolicyHandler.__init__(self, matchPolicyHandler, nonmatchPolicyHandler)
        self.matchRegex = [re.compile(x, re.IGNORECASE) for x in matchNames]

    async def match(self, request):
        for regex in self.matchRegex:
            if regex.match(request["client_name"]):
                return True
        return False


class SASLRateLimitPolicyHandler(BasePolicyHandler):
    def __init__(self, rejectMessage, period, rate, burst):
        BasePolicyHandler.__init__(self)
        self.local_domains = {}
        self.refresh_local_domains()
        self.rejectMessage = rejectMessage
        self.bucketMax = burst + rate
        gcd = self.gcd(rate, period)
        self.decrement = rate / gcd
        self.decrement_period = period / gcd
        self.buckets = {}

    def gcd(self, x, y):
        while y != 0:
            (x, y) = (y, x % y)
        return x

    def refresh_local_domains(self):
        self.local_domains = { 'portugalmail.pt': True, 'portugalmail.com': True, 'xekmail.pt': True, 'aeiou.pt': True }

    async def handle_request(self, request):
        # TODO: Allow whitelisting/country definition from database
        if request['sasl_username'] in [ 'allan.maes@itl-transport.pt', 'andrea.c.lopez@naturaselection.com.pt', 'andrecarapito@silvavinha.pt', 'apoioaoclienteenvio@celeiro.pt', 'nuno.caiano@vestimpor.com', 'paulo.lima@enoport.com', 'fernando.marques@movicortes.pt', 'encomendas@movicortes.pt', 'paulo.fidalgo@movicortes.pt', 'paulo.valente@movicortes.pt', 'site@ccdbraga.pt', 'natalia.fonseca@movicortes.pt', 'lafitte@xactiveliterie.fr', 'dianaramos@glam.com.pt', 'nuno.franca@fsm.pt', 'daniellopes@retailconcept.pt', 'paulo.renato@fsm.pt', 'miguel.ramos@enoport.pt', 'site@admedic.pt', 'joseblanco@arblanco.com', 'veronique@deborafonseca.com' ]: return { 'action': 'OK' }
        if 'herdadedorocim.com' in request['sasl_username']: return { 'action': 'OK' } 
        domain = request['recipient'].split('@', 1)[1]
        if domain in self.local_domains:
            self.log_with_id(
                request, "Local delivery. Not rate limited", syslog.LOG_INFO
            )
            return {"action": "OK"}

        now = time.time()
        if request["sasl_username"] not in self.buckets:
            self.buckets[request["sasl_username"]] = {"count": 0, "updated": now}

        if (
            now - self.buckets[request["sasl_username"]]["updated"]
            > self.decrement_period
        ):
            num_periods = (
                now - self.buckets[request["sasl_username"]]["updated"]
            ) // self.decrement_period
            self.buckets[request["sasl_username"]]["updated"] = (
                self.buckets[request["sasl_username"]]["updated"]
                + num_periods * self.decrement_period
            )
            self.buckets[request["sasl_username"]]["count"] -= num_periods * self.decrement
            if self.buckets[request["sasl_username"]]["count"] <= 0:
                (
                    self.buckets[request["sasl_username"]]["updated"],
                    self.buckets[request["sasl_username"]]["count"],
                ) = (now, 0)

        if self.buckets[request["sasl_username"]]["count"] >= self.bucketMax:
            self.log_with_id(
                request,
                "Rate limit exceeded %d >= %d. Deferring message. client_address=%s sasl_username=%s"
                % (
                    self.buckets[request["sasl_username"]]["count"],
                    self.bucketMax,
                    request["client_address"],
                    request["sasl_username"],
                ),
                syslog.LOG_INFO,
            )
            return {"action": "defer_if_permit", "message": self.rejectMessage}

        self.buckets[request["sasl_username"]]["count"] = (
            self.buckets[request["sasl_username"]]["count"] + 1
        )
        self.buckets[request["sasl_username"]]["updated"] = now

        self.log_with_id(
            request,
            "Accepted message. Current count and limit: %d of %d"
            % (self.buckets[request["sasl_username"]]["count"], self.bucketMax),
            syslog.LOG_INFO,
        )
        return {"action": "OK"}


class ReducePolicyHandler(BasePolicyHandler):
    def __init__(self, operation, policyHandlers):
        BasePolicyHandler.__init__(self)
        self.policyHandlers = policyHandlers
        self.operation = operation

    @staticmethod
    def all_pass(reduction, nextResult):
        if reduction is None:
            return nextResult
        if reduction["action"] != "OK":
            if "message" in nextResult:
                if "message" in reduction:
                    reduction["message"] = "%s; %s" % (
                        reduction["message"],
                        nextResult["message"],
                    )
                else:
                    reduction["message"] = nextResult["message"]
            return reduction
        return nextResult

    async def handle_request(self, request):
        all_results = []
        for handler in self.policyHandlers:
            all_results.append(await handler.handle_request(request))
        return functools.reduce(self.operation, all_results)

server = Server(
    RCPTFilterPolicyHandler(
        GeoIPFilterPolicyHandler(
            ClientNameFilterPolicyHandler(
                None, 
                ReducePolicyHandler(ReducePolicyHandler.all_pass,
                [
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the per minute outbound message limit. Please try again later. (NML)",
                        60,
                        100,
                        100
                    ),
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the hourly outbound message limit. Please try again later. (NHL)",
                        3600,
                        100,
                        200
                    ),
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the daily outbound message limit. Please try again later. (NDL)",
                        86400,
                        400,
                        100
                    ),
                ]
            ), 
                [
                ]
            ), 
            ClientNameFilterPolicyHandler(
                None, 
                ReducePolicyHandler(ReducePolicyHandler.all_pass,
                [
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the per minute outbound message limit. Please try again later. (IML)",
                        60,
                        20,
                        10
                    ),
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the hourly outbound message limit. Please try again later. (IHL)",
                        3600,
                        50,
                        50
                    ),
                    SASLRateLimitPolicyHandler(
                        "You have exceeded the daily outbound message limit. Please try again later. (IDL)",
                        86400,
                        100,
                        50
                    ),
                ]
            ), 
                [
                ]
            ), 
            ['PT'], 
            [], 
            [ 
            ]
        ), 
        None
    )
)

asyncio.get_event_loop().run_until_complete(
    run_in_foreground(
        asyncio.start_server(server.handle_request, "127.0.0.1", port=10000)
    ).wait_closed()
)
