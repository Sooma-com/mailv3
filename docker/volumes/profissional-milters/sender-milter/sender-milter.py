#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import SoomaMilter
import Milter
import Milter.utils
import syslog


class SenderMilter(SoomaMilter.SoomaMilterBase):
    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)

    def set_delegator(self, delegator):
        self.delegator = delegator

    def reset(self):
        SoomaMilter.SoomaMilterBase.reset(self)

    def all_headers(self, headers):
        self.logger.log_with_id_maybe("all_headers", syslog.LOG_DEBUG)
        authenticated_sender_headers = self.delegator.get_headers(
            "x-authenticated-sender"
        )
        for h in authenticated_sender_headers:
            h["deleted"] = True
        if len(authenticated_sender_headers) == 0:
            return SoomaMilter.SoomaMilterBase.all_headers(self, headers)

        for h in self.delegator.get_headers("sender"):
            h["deleted"] = True
        from_headers = self.delegator.get_headers("from")
        from_value = ""
        if len(from_headers) != 0:
            from_value = "@".join(
                Milter.utils.parse_addr(from_headers[0]["value"])
            ).lower()
        if "<" in from_value and ">" in from_value:
            from_value = from_value.split("<")[1].split(">")[0]
        if (
            from_value
            != "@".join(
                Milter.utils.parse_addr(authenticated_sender_headers[0]["value"])
            ).lower()
        ):
            sender_header = self.delegator.get_or_create_header("Sender")
            sender_header["value"] = authenticated_sender_headers[0]["value"]
            sender_header["deleted"] = False
            sender_header["modified"] = True

        return SoomaMilter.SoomaMilterBase.all_headers(self, headers)


SoomaMilter.SoomaMilterFactory(
    "sender_milter", SenderMilter, default_cfg={"loglevel": syslog.LOG_INFO}
).run()
