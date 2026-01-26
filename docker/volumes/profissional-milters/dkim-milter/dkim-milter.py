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
from dkim import sign as dkim_sign


class DKIMMilter(SoomaMilter.SoomaMilterBase):
    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)
        self.db_connection = None

    def set_delegator(self, delegator):
        self.delegator = delegator
        delegator.cfg["enable_body"] = True

    def reset(self):
        SoomaMilter.SoomaMilterBase.reset(self)
        (
            self.dkim_enabled,
            self.dkim_selector,
            self.dkim_key_private,
            self.dkim_key_public,
            self.dkim_domain,
        ) = (False, None, None, None, None)

    def db(self):
        if self.db_connection is None:
            if self.delegator.cfg["DBType"] == "mysql":
                self.db_connection = mysql.connector.connect(
                    user=self.delegator.cfg["DBUser"],
                    password=self.delegator.cfg["DBPassword"],
                    host=self.delegator.cfg["DBHost"],
                    port=self.delegator.cfg["DBPort"],
                    database=self.delegator.cfg["DBDatabase"],
                )
            else:
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

    def all_headers(self, headers):
        try:
            for header in headers:
                if header["header"].lower() == "from":
                    try:
                        domain = header["value"].split("@")[1].split(">")[0]
                        return self.load_dkim_keys(domain)
                    except IndexError:
                        # Domain without '@'
                        return Milter.ACCEPT
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning(
                "Exception retrieving dkim keys: ", exc_obj, exc_tb
            )
            return Milter.ACCEPT
        return Milter.CONTINUE

    def eom(self):
        try:
            headers_to_sign = self.delegator.cfg["signed-headers"].split(":")
            signing_payload = (
                b"\n".join(
                    [
                        (header_name + ": " + header_value["raw"]).encode('ASCII')
                        for header_name in headers_to_sign
                        for header_value in self.delegator.get_headers(header_name)
                    ]
                )
                + b"\n\n"
                + self.delegator.rawbody
            )

            (signature_header_name, signature_header_value) = (
                dkim_sign(
                    signing_payload,
                    self.dkim_selector.encode('ASCII'),
                    self.dkim_domain.encode('ASCII'),
                    ("-----BEGIN RSA PRIVATE KEY-----\n%s\n-----END RSA PRIVATE KEY-----"
                    % (self.dkim_key_private,)).encode('ASCII'),
                    canonicalize=(b"relaxed", b"relaxed"),
                    include_headers=headers_to_sign,
                )
                .decode('ASCII')
                .replace("\n", "")
                .replace("\r", "")
                .split(":", 1)
            )
            self.delegator.headers.append(
                {
                    "header": signature_header_name,
                    "value": signature_header_value,
                    "modified": False,
                    "deleted": False,
                    "new": True,
                }
            )
            self.logger.log_with_id_maybe("DKIM-signed message", syslog.LOG_INFO)
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning(
                "Exception signing message: ", exc_obj, exc_tb
            )
            return Milter.ACCEPT

    def load_dkim_keys(self, domain):
        self.logger.log_with_id_maybe(
            "Loading dkim keys for domain %s" % (domain,), syslog.LOG_INFO
        )
        try:
            cursor = self.db().cursor()
            cursor.execute(self.delegator.cfg["DKIMQuery"], (domain,))
            result = [row for row in cursor]
            if len(result) != 1:
                (
                    self.dkim_enabled,
                    self.dkim_selector,
                    self.dkim_key_private,
                    self.dkim_key_public,
                    self.dkim_domain,
                ) = (False, None, None, None, None)
            else:
                (
                    self.dkim_enabled,
                    self.dkim_selector,
                    self.dkim_key_private,
                    self.dkim_key_public,
                ) = result[0]
                self.dkim_domain = domain
            if not self.dkim_enabled:
                self.logger.log_with_id_maybe(
                    "DKIM disabled for %s. Accepting message." % (domain,),
                    syslog.LOG_INFO,
                )
                return Milter.ACCEPT
        except (psycopg2.OperationalError, psycopg2.InternalError):
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning(
                "Could not get dkim keys for domain %s" % (domain,), exc_obj, exc_tb
            )
            return Milter.ACCEPT
        self.logger.log_with_id_maybe(
            "Got DKIM keys for %s. Milter continuing" % (domain,), syslog.LOG_INFO
        )
        return Milter.CONTINUE


SoomaMilter.SoomaMilterFactory(
    "dkim_milter",
    DKIMMilter,
    default_cfg={
        "loglevel": syslog.LOG_INFO,
        "DBType": "postgresql",
        "DBPort": 5432,
        "DBHost": "localhost",
        "DBDatabase": "mail_profissional",
        "DBUser": "postfix",
        "DBPassword": "postfix",
        "DKIMQuery": "SELECT dkim_enabled, dkim_selector, dkim_key_private, dkim_key_public FROM postfix.domains WHERE name = LOWER(%s) LIMIT 1",
        "signed-headers": "mime-version:date:message-id:subject:from:to:in-reply-to:references:user-agent",
    },
).run()
