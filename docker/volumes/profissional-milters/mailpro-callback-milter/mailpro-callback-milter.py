#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import Milter
import SoomaMilter
import syslog
import redis
import time
import urllib
import json

class MailproCallbackMilter(SoomaMilter.SoomaMilterBase):

    def __init__(self):
        self.redis_connection = None
        SoomaMilter.SoomaMilterBase.__init__(self)
    def redis(self):
        if self.redis_connection is None:
            self.redis_connection = redis.Redis(host=self.delegator.cfg['RedisHost'], port=self.delegator.cfg['RedisPort'], password=self.delegator.cfg['RedisPassword'])
        return self.redis_connection

    def all_headers(self, headers):
        msgId = self.delegator.getsymval("i")
        httpDSN = None
        for toDelete in [h for h in self.delegator.headers if h['header'].lower() == 'X-Mailpro-HTTPDSN'.lower()]:
            httpDSN = toDelete['value']
            toDelete['deleted'] = True
        if httpDSN is not None:
            parsedHttpDSN = urllib.parse.urlparse(httpDSN)
            queryParams = urllib.parse.parse_qs(parsedHttpDSN.query, True, False)
            normalizedHttpDSN = ""
            if parsedHttpDSN.scheme:
                normalizedHttpDSN += parsedHttpDSN.scheme + ":"
            normalizedHttpDSN += "//" + parsedHttpDSN.netloc + parsedHttpDSN.path
            redisData = {
                'Queue-ID': msgId,
                'HTTPDSN': normalizedHttpDSN,
                'HTTPDSN-Params': json.dumps(queryParams),
                'timestamp-sent': time.time(),
                'Delivery-Status': 'Unknown',
                'Notification-Pending': 'No'
            }
            self.redis().hmset(msgId, redisData)
            self.redis().expire(msgId, 60 * 60 * 24 * 7)

        return SoomaMilter.SoomaMilterBase.all_headers(self, headers)

SoomaMilter.SoomaMilterFactory('mailpro-callback-milter', MailproCallbackMilter, default_cfg = { 
    'loglevel': syslog.LOG_DEBUG,
    'RedisPort': 6379,
    'RedisHost': 'localhost',
    'RedisPassword': ''
    }).run()
