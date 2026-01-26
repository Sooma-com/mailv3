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
from pprint import pprint


class PasswordMilter(SoomaMilter.SoomaMilterBase):
    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)
        self.db_connection = None

    def reset(self):
        SoomaMilter.SoomaMilterBase.reset(self)
        self.tag_subject = False
        self.subject_tags = []
        self.required_password = None

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

    def received_rcpt_to(self, rcpt, parameters):
        if not self.allow_sender(rcpt):
            self.logger.log_with_id_maybe(
                "Rejecting. Sender %s is not allowed for %s"
                % (self.delegator.mail_from, rcpt),
                syslog.LOG_INFO,
            )
            return (
                "550",
                "5.1.3",
                "Sender is not listed as authorized for destination",
            )
        if self.required_password is None:
            self.required_password = self.email_receive_password(rcpt)
        if self.required_password is not None and len(self.delegator.rcpt_to) > 1:
            self.logger.log_with_id_maybe(
                "Rejecting. Multiple recipients in message when one recipient is password-bound"
            )
            return (
                "550",
                "5.1.3",
                "Password-bound recipient must be the single recipient of a mail message",
            )
        if self.email_tag_subject(rcpt):
            self.tag_subject = True
            self.subject_tags.append("[%s]" % (rcpt.split("@")[0],))

        return None

    def received_header(self, header, value):
        if header != "subject":
            return None
        if self.required_password is not None:
            self.logger.log_with_id_maybe(value)
            if not value.lstrip().startswith(self.required_password):
                self.logger.log_with_id_maybe(
                    "Rejecting. Password required for recipient not found in Subject"
                )
                return (
                    "550",
                    "5.1.3",
                    "Password-bound recipient requires correct password in message subject",
                )
            self.logger.log_with_id_maybe(
                "Password matches. Removing password from header.", syslog.LOG_INFO
            )
            value = value.lstrip()[len(self.required_password) :]

        if self.tag_subject:
            self.logger.log_with_id_maybe("Tagging subject")
            value = "%s %s" % ("".join(self.subject_tags), value)
        return value

    def allow_sender(self, email):
        try:
            cursor = self.db().cursor()
            cursor.execute(
                """
SELECT 
 permitted_senders_own_list,
 permitted_senders_definition
FROM 
  postfix.aliases
WHERE 
 (aliases.alias_username, aliases.alias_domain) = (LOWER(%s), LOWER(%s))
""",
                (email.split("@")[0],email.split("@")[1]),
            )
            record = cursor.fetchone()
            cursor.close()
            if record is None:
                return True
            if record[1] == "own_list":
                senders_own_list = re.findall(r'"([^"]+)"', record[0])
                return self.delegator.mail_from in senders_own_list
            if record[1] == "maildrop":
                cursor = self.db().cursor()
                cursor.execute(
                    """
SELECT
 count(*) AS exists
FROM
  postfix.aliases
WHERE
 (aliases.alias_username, aliases.alias_domain, aliases.destination) = (LOWER(%s), LOWER(%s), LOWER(%s))
""",
                    (email.split("@")[0],email.split("@")[1], self.delegator.mail_from),
                )
                record = cursor.fetchone()
                cursor.close()
                if record is None:
                    self.logger.log_with_id_maybe("Allowing sende although maildrop query returned no results", syslog.LOG_WARNING)
                    return True
                if record[0] == 0:
                    return False
                return True
            return True
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_error("email_allow_sender", exc_type, exc_obj, exc_tb)
            self.db_connection = None
            return True

    def email_receive_password(self, email):
        try:
            cursor = self.db().cursor()
            cursor.execute(
                """
SELECT 
 receive_password
FROM 
  profissional_emails
WHERE 
 email = LOWER(%s)
""",
                (email,),
            )
            record = cursor.fetchone()
            if record is None:
                cursor.close()
                return None
            result = list(record).pop()
            if result is None:
                cursor.close()
                return None
            cursor.close()
            result = result.strip(" ")
            if len(result) == 0:
                return None
            return result
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_error(
                "email_receive_password", exc_type, exc_obj, exc_tb
            )
            self.db_connection = None
            return None

    def email_tag_subject(self, email):
        try:
            cursor = self.db().cursor()
            cursor.execute(
                """
SELECT 
 tag_subject
FROM 
  postfix.aliases
WHERE 
 (aliases.alias_username, aliases.alias_domain) = (LOWER(%s), LOWER(%s))
""",
                (email.split("@")[0],email.split("@")[1]),
            )
            record = cursor.fetchone()
            if record is None:
                cursor.close()
                return False
            result = list(record).pop()
            if result is None:
                cursor.close()
                return False
            cursor.close()
            return result
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_error("email_tag_subject", exc_type, exc_obj, exc_tb)
            self.db_connection = None
            return None


SoomaMilter.SoomaMilterFactory(
    "password_milter",
    PasswordMilter,
    default_cfg={
        "loglevel": syslog.LOG_DEBUG,
        "DBPort": 5432,
        "DBHost": "localhost",
        "DBDatabase": "mail_profissional",
        "DBUser": "postfix",
        "DBPassword": "postfix",
    },
).run()
