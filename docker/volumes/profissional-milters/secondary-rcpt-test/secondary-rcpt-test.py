#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import Milter
import SoomaMilter
import syslog
import re
import psycopg2
import functools
import time
import datetime
import sys
from smtplib import SMTP,SMTPException

class SecondaryRcptTestMilter(SoomaMilter.SoomaMilterBase):
    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)
        self.db_connection = None
        self._domain_servers = None
        self._domain_servers_timestamp = None
        self.failures_exist = False
        self.successes_exist = False
        self.smtp = {}

    def reset(self):
        SoomaMilter.SoomaMilterBase.reset(self)
        self.failures_exist = False
        self.successes_exist = False
        self.smtp = {}

    def db(self):
        if self.db_connection is None:
            self.db_connection = psycopg2.connect(
                "host='%s' port=%d dbname='%s' user='%s' password='%s'"
                % (
                    self.delegator.cfg["DBHost"],
                    self.delegator.cfg["DBPort"],
                    self.delegator.cfg["DBDatabase"],
                    self.delegator.cfg["DBUser"],
                    self.delegator.cfg["DBPassword"],
                )
            )
        return self.db_connection

    def domain_servers(self):
        if self._domain_servers is None or time.time() - self._domain_servers_timestamp > 300:
            try:
                cursor = self.db().cursor()
                cursor.execute(
                    """
SELECT 
 profissional_domains.name, 
 profissional_domain_secondary_target.target 
FROM 
 profissional_domain_secondary_target 
 JOIN profissional_domains ON profissional_domain_secondary_target.id = profissional_domains.id
"""
                )
                query_result = cursor.fetchall()
                cursor.close()
                self._domain_servers = {}
                self._domain_servers_timestamp = time.time()
                for name,target in query_result:
                    self._domain_servers[name] = target
            except:
                exc_type, exc_obj, exc_tb = sys.exc_info()
                self.logger.log_exception_error("domain_servers", exc_type, exc_obj, exc_tb)
                self._domain_servers = {}
                self._domain_servers_timestamp = time.time()
        return self._domain_servers
    
    def received_rcpt_to(self, rcpt, parameters):
        domain = rcpt.split("@")
        if len(domain) < 2:
            return None
        domain = domain[1]
        if not domain in self.domain_servers():
            self.successes_exist = True
            return None
        if self.test_rcpt(rcpt, self.domain_servers()[domain]):
            self.successes_exist = True
        else:
            self.failures_exist = True

        return None

    def test_rcpt(self, rcpt, server):
        if not server in self.smtp:
            try:
                self.smtp[server] = SMTP(server, 25, self.delegator.cfg["SMTPHostname"], 5)
                self.smtp[server].set_debuglevel(1)
                self.smtp[server].ehlo(self.delegator.cfg["SMTPHostname"])
                (smtp_code, smtp_text) = self.smtp[server].docmd("MAIL FROM:", "<%s>" % (self.delegator.cfg["SMTPFrom"],))
                if not (smtp_code >= 200 and smtp_code <= 299):
                    raise SMTPException("Non 2XX return code: %s" % (smtp_code,))
            except:
                exc_type, exc_obj, exc_tb = sys.exc_info()
                self.logger.log_exception_error("test_rcpt", exc_type, exc_obj, exc_tb)
                if server in self.smtp:
                    del self.smtp[server]
                return True
        try:
            (smtp_code, smtp_text) = self.smtp[server].docmd("RCPT TO:", "<%s>" % (rcpt,))
            if smtp_code >= 500 and smtp_code <= 599:
                self.logger.log_with_id_maybe(
                        "Recipient %s rejected by upstream return code %d: %s."
                    % (rcpt, smtp_code, smtp_text),
                    syslog.LOG_INFO,
                )
                return False
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_error("test_rcpt", exc_type, exc_obj, exc_tb)
            if server in self.smtp:
                del self.smtp[server]

        return True

    
    def eom(self):
        for target,smtp in self.smtp.items():
            smtp.quit()
        self.smtp = {}
        if self.failures_exist and not self.successes_exist:
            self.logger.log_with_id_maybe( "All recipients failed. Rejecting message", syslog.LOG_INFO)
            return Milter.REJECT
        return Milter.CONTINUE

SoomaMilter.SoomaMilterFactory(
    "secondary-rcpt-test",
    SecondaryRcptTestMilter,
    default_cfg={
        "loglevel": syslog.LOG_DEBUG,
        "DBPort": 5432,
        "DBHost": "10.3.9.3",
        "DBDatabase": "mail_profissional",
        "DBUser": "postfix",
        "DBPassword": "postfix",
        "SMTPHostname": "a.mx.smail.eu",
        "SMTPFrom": "postmaster+rcpttest@smail.eu",
    },
).run()
#milter = SoomaMilter.SoomaMilterFactory(
#    "secondary-rcpt-test",
#    SecondaryRcptTestMilter,
#    default_cfg={
#        "loglevel": syslog.LOG_DEBUG,
#        "DBPort": 5432,
#        "DBHost": "10.3.9.3",
#        "DBDatabase": "mail_profissional",
#        "DBUser": "postfix",
#        "DBPassword": "postfix",
#        "SMTPHostname": "a.mx.smail.eu",
#        "SMTPFrom": "postmaster+rcpttest@smail.eu",
#    },
#).factory()
#milter.delegate.received_rcpt_to("sergio.carvalho@sooma.com", {})
#milter.delegate.received_rcpt_to("nonexistant@dominio.pt", {})
#milter.delegate.received_rcpt_to("nonexistant@tcontas.pt", {})
#milter.delegate.received_rcpt_to("testerelay@tcontas.pt", {})
#print(milter.delegate.eom())
