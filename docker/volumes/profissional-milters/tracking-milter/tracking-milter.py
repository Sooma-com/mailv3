#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import SoomaMilter
import Milter
import Milter.utils
import syslog
from pprint import pprint


class TrackingMilter(SoomaMilter.SoomaMilterBase):
    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)

    def set_delegator(self, delegator):
        delegator.cfg["enable_body"] = True
        self.delegator = delegator

    def reset(self):
        SoomaMilter.SoomaMilterBase.reset(self)

    def body(self, body):
        if "..--..".encode("utf-8") in body:
            self.logger.log_with_id_maybe("Watermark pattern found in body", syslog.LOG_INFO)
        return None
        
SoomaMilter.SoomaMilterFactory(
    "tracking_milter", TrackingMilter, default_cfg={"loglevel": syslog.LOG_INFO}
).run()
