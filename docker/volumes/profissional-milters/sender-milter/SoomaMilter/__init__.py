import syslog
import sys
import os
import Milter
import configparser
import Milter.utils
import email.header
import traceback
import copy


class SoomaMilterBase:
    def __init__(self):
        pass

    def set_logger(self, logger):
        self.logger = logger

    def set_delegator(self, delegator):
        self.delegator = delegator

    def reset(self):
        self.logger.log_with_id_maybe("Resetting", syslog.LOG_DEBUG)

    def connected(self):
        hostname = (
            self.delegator.remote["hello_hostname"]
            if "hello_hostname" in self.delegator.remote
            else "Unknown hello_hostname"
        )
        address = (
            self.delegator.remote["address"][0]
            if "address" in self.delegator.remote
            and self.delegator.remote["address"] is not None
            and 0 in self.delegator.remote["address"]
            else "Unknown address"
        )
        self.logger.log_with_id_maybe(
            "Connection from %s ([%s])" % (hostname, address), syslog.LOG_DEBUG
        )
        return None

    def received_mail_from(self, fromAddress, parameters):
        self.logger.log_with_id_maybe(
            "Received MAIL_FROM. Sender: %s. Params: %s" % (fromAddress, parameters),
            syslog.LOG_NOTICE,
        )
        return None

    def received_rcpt_to(self, rcpt, parameters):
        self.logger.log_with_id_maybe(
            "Received RCPT_TO. Recipient: %s. Params: %s" % (rcpt, parameters),
            syslog.LOG_DEBUG,
        )
        return None

    def all_recipients(self, recipients):
        self.logger.log_with_id_maybe(
            "All recipients known: %s" % (recipients,), syslog.LOG_DEBUG
        )
        return None

    def received_header(self, header, value):
        self.logger.log_with_id_maybe(
            "Received header %s: %s" % (header, value), syslog.LOG_DEBUG
        )
        return None

    def all_headers(self, headers):
        self.logger.log_with_id_maybe(
            "All headers known: %s" % (headers,), syslog.LOG_DEBUG
        )
        return None

    def body(self, body):
        self.logger.log_with_id_maybe("Body complete: %s" % (body,), syslog.LOG_DEBUG)
        return None

    def eom(self):
        self.logger.log_with_id_maybe("End-of-message", syslog.LOG_DEBUG)


class SoomaMilterDelegator(Milter.Base):
    def __init__(self, name, delegate, cfg, header_callbacks):
        self.log_initialized = False
        self.name = name
        self.delegate = delegate
        self.cfg = cfg
        self.header_callbacks = header_callbacks
        self.action_on_error = self.cfg["action_on_error"]
        delegate.set_logger(self)
        delegate.set_delegator(self)
        self.reset()

    def reset(self):
        self.delegate.reset()
        self.remote = {}
        self.mail_from = None
        self.mail_from_params = []
        self.rcpt_to = []
        self.rcpt_to_to_add = []
        self.rcpt_to_to_replace = {}
        self.rcpt_to_to_delete = []

        self.headers = []
        self.rawbody = b""

    def get_headers(self, header):
        header = header.lower()
        return [h for h in self.headers if h["header"].lower() == header]

    def get_header(self, header):
        candidates = self.get_headers(header)
        if len(candidates) == 0:
            return None
        return candidates[0]

    def get_or_create_header(self, header):
        result = self.get_header(header)
        if result is None:
            self.headers.append(
                {
                    "header": header,
                    "value": "",
                    "modified": False,
                    "deleted": False,
                    "new": True,
                }
            )
            return self.headers[len(self.headers) - 1]
        return result

    def log_exception_notice(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_NOTICE, exc_ob, exc_tb)

    def log_exception_warning(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_WARNING, exc_ob, exc_tb)

    def log_exception_error(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_ERR, exc_ob, exc_tb)

    def log_exception(self, method, exc_type, loglevel, exc_ob=None, exc_tb=None):
        if exc_ob is None or exc_tb is None:
            self.log_with_id_maybe("Exception on method %s: %s" % (method, exc_type))
            return
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        self.log_with_id_maybe(
            "Exception on method %s: %s @%s+%d. %s"
            % (
                method,
                exc_type,
                fname,
                exc_tb.tb_lineno,
                ";".join(
                    [
                        line.replace("\n", "")
                        for line in traceback.format_list(traceback.extract_tb(exc_tb))
                    ]
                ),
            ),
            loglevel,
        )
        if self.cfg["loglevel"] == syslog.LOG_DEBUG:
            traceback.print_exception(exc_type, exc_ob, exc_tb)

    def log_with_id_maybe(self, msg, level=syslog.LOG_NOTICE):
        try:
            self.log_with_id(msg, level)
        except:
            self.log(msg, level)

    def log_with_id(self, msg, level=syslog.LOG_NOTICE):
        if self.getsymval("i") is None:
            self.log("%s: %s" % ("NOQUEUE", msg), level)
        else:
            self.log("%s: %s" % (self.getsymval("i"), msg), level)

    def log(self, msg, level=syslog.LOG_NOTICE):
        if level > self.cfg["loglevel"]:
            return
        if not self.log_initialized:
            syslog.openlog(
                self.cfg["syslog_name"], syslog.LOG_PID, self.cfg["logfacility"]
            )
        syslog.syslog(level, msg)
        if self.cfg["loglevel"] >= syslog.LOG_DEBUG:
            sys.stderr.write(msg)
            sys.stderr.write("\n")

    def call_delegate(self, method, default_value, *args):
        try:
            result = method(*args)
            if isinstance(result, tuple) and len(result) == 3:
                self.setreply(result[0], result[1], result[2])
                return (Milter.REJECT, default_value)
            if isinstance(result, int):
                return (result, default_value)
            if result is None:
                return (Milter.CONTINUE, default_value)
            return (Milter.CONTINUE, result)
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_error(method.__name__, exc_type, exc_obj, exc_tb)
            return (self.action_on_error, default_value)

    def connect(self, hostname, family, hostaddr):
        for k, v in {
            "hostname": hostname,
            "address": hostaddr,
            "family": family,
        }.items():
            self.remote[k] = v
        return Milter.CONTINUE

    def hello(self, hostname):
        self.remote["hello_hostname"] = hostname
        return self.call_delegate(self.delegate.connected, None)[0]

    def envfrom(self, f, *params):
        soft_reset_remote = self.remote
        self.reset()
        self.remote = soft_reset_remote

        self.mail_from = "@".join(Milter.utils.parse_addr(f)).lower().rstrip(".")
        self.mail_from_params = params
        (result, new_from) = self.call_delegate(
            self.delegate.received_mail_from, self.mail_from, self.mail_from, params
        )
        self.changed_from = new_from != self.mail_from
        if self.changed_from:
            self.mail_from = new_from
        return result

    def envrcpt(self, to, *params):
        rcpt_to = "@".join(Milter.utils.parse_addr(to)).lower()
        (result, new_rcpt_to) = self.call_delegate(
            self.delegate.received_rcpt_to, rcpt_to, rcpt_to, params
        )
        if isinstance(new_rcpt_to, list):
            if rcpt_to in new_rcpt_to:
                self.rcpt_to.append(rcpt_to)
            else:
                self.rcpt_to_to_delete.append(rcpt_to)
            self.rcpt_to_to_add.extend([x for x in new_rcpt_to if x != rcpt_to])
            self.rcpt_to.extend([x for x in new_rcpt_to if x != rcpt_to])
        elif new_rcpt_to == "":
            self.rcpt_to_to_delete.append(rcpt_to)
        elif new_rcpt_to != rcpt_to:
            self.rcpt_to_to_replace[rcpt_to] = new_rcpt_to
            self.rcpt_to.append(new_rcpt_to)
        else:
            self.rcpt_to.append(rcpt_to)
        return result

    def data(self):
        self.rcpt_to = list(set(self.rcpt_to))
        (result, new_rcpt_to) = self.call_delegate(
            self.delegate.all_recipients, self.rcpt_to, self.rcpt_to
        )
        if not isinstance(new_rcpt_to, list):
            self.log_with_id_maybe(
                "Received a non-list from call to all_recipients on delegate. Will do nothing.",
                syslog.LOG_ERR,
            )
            return Milter.CONTINUE
        new_rcpt_to = list(set(new_rcpt_to))
        self.rcpt_to_to_delete.extend([x for x in self.rcpt_to if x not in new_rcpt_to])
        self.rcpt_to_to_add.extend([x for x in new_rcpt_to if x not in self.rcpt_to])
        return result

    def header(self, field, value):
        try:
            decoded_header = ''.join([ t[0] if isinstance(t[0], str) else t[0].decode(t[1] if t[1] is not None else 'ASCII') for t in email.header.decode_header(value) ])
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_error("decode_header", exc_type, exc_obj, exc_tb)
            # We can't store an unencoded header for further analysis, return default action (which should be Milter.ACCEPT or Milter.REJECT, never Milter.CONTINUE (as our internal state will be inconsistent with the message state)
            return self.action_on_error
        canonical_field = field.lower()
        self.headers.append(
            {
                "header": field,
                "raw": value,
                "value": decoded_header,
                "modified": False,
                "deleted": False,
                "new": False,
            }
        )
        (result, new_value) = self.call_delegate(
            self.delegate.received_header,
            decoded_header,
            canonical_field,
            decoded_header,
        )
        if result == Milter.CONTINUE and canonical_field in self.header_callbacks:
            for callback in self.header_callbacks[canonical_field]:
                (result, new_value) = self.call_delegate(callback, new_value, new_value)
                if result != Milter.CONTINUE:
                    break
        if new_value is None:
            self.headers[len(self.headers) - 1]["deleted"] = True
        elif new_value != decoded_header:
            self.headers[len(self.headers) - 1]["value"] = new_value
            self.headers[len(self.headers) - 1]["modified"] = True
        return result

    def eoh(self):
        new_headers = [x for x in self.headers if x["new"]]
        self.headers = [x for x in self.headers if not x["new"]]
        self.headers.extend(new_headers)
        (result, self.headers) = self.call_delegate(
            self.delegate.all_headers, self.headers, self.headers
        )
        return result

    def body(self, blk):
        if not self.cfg["enable_body"]:
            return Milter.CONTINUE

        self.rawbody += blk
        return Milter.CONTINUE

    def eom(self):
        delegate_result = self.call_delegate(self.delegate.eom, None)[0]

        if self.changed_from:
            self.log_with_id_maybe(
                "Changed from address to %s" % (self.mail_from), syslog.LOG_NOTICE
            )
            self.chgfrom("<%s>" % (self.mail_from,), *self.mail_from_params)

        if (
            len(self.rcpt_to_to_add)
            + len(self.rcpt_to_to_replace)
            + len(self.rcpt_to_to_delete)
            > 0
        ):
            sanity_check = [
                x for x in self.rcpt_to_to_add if x in self.rcpt_to_to_delete
            ]
            if len(sanity_check) > 0:
                self.log_with_id_maybe(
                    "RCPT_TO marked for both addition and removal will be ignored: %s"
                    % (sanity_check,),
                    syslog.LOG_ERR,
                )
                self.rcpt_to_to_add = [
                    x for x in self.rcpt_to_to_add if x not in sanity_check
                ]
                self.rcpt_to_to_delete = [
                    x for x in self.rcpt_to_to_delete if x not in sanity_check
                ]
            sanity_check = [
                x
                for x in self.rcpt_to_to_replace.values()
                if x in self.rcpt_to_to_delete
            ]
            if len(sanity_check) > 0:
                self.log_with_id_maybe(
                    "RCPT_TO marked for both replacement and removal (conflicting operation; will skip removal): %s"
                    % (sanity_check,),
                    syslog.LOG_ERR,
                )
                self.rcpt_to_to_delete = [
                    x for x in self.rcpt_to_to_delete if x not in sanity_check
                ]
            sanity_check = [
                x for x in self.rcpt_to_to_replace.keys() if x in self.rcpt_to_to_delete
            ]
            if len(sanity_check) > 0:
                self.log_with_id_maybe(
                    "RCPT_TO marked for both replacement and removal (redundant operation): %s"
                    % (sanity_check,),
                    syslog.LOG_ERR,
                )
                self.rcpt_to_to_delete = [
                    x for x in self.rcpt_to_to_delete if x not in sanity_check
                ]
            sanity_check = [
                x for x in self.rcpt_to_to_replace.keys() if x in self.rcpt_to_to_add
            ]
            if len(sanity_check) > 0:
                self.log_with_id_maybe(
                    "RCPT_TO marked for both replacement and addition (conflicting operation; will skip replacement): %s"
                    % (sanity_check,),
                    syslog.LOG_ERR,
                )
                self.rcpt_to_to_replace = dict(
                    (x, y)
                    for (x, y) in self.rcpt_to_to_replace.items()
                    if x not in sanity_check
                )
            sanity_check = [
                x for x in self.rcpt_to_to_replace.values() if x in self.rcpt_to_to_add
            ]
            if len(sanity_check) > 0:
                self.log_with_id_maybe(
                    "RCPT_TO marked for both replacement and addition (redundant operation): %s"
                    % (sanity_check,),
                    syslog.LOG_ERR,
                )
                self.rcpt_to_to_add = [
                    x for x in self.rcpt_to_to_add if x not in sanity_check
                ]

            for rcpt in list(set(self.rcpt_to_to_add)):
                self.log_with_id_maybe("Adding RCPT: %s" % (rcpt,), syslog.LOG_NOTICE)
                self.addrcpt("<%s>" % (rcpt,))
            for rcpt in list(set(self.rcpt_to_to_delete)):
                self.log_with_id_maybe("Deleting RCPT: %s" % (rcpt,), syslog.LOG_NOTICE)
                self.delrcpt("<%s>" % (rcpt,))
            for (rcpt_old, rcpt_new) in self.rcpt_to_to_replace.items():
                self.log_with_id_maybe(
                    "Replacing RCPT: %s -> %s" % (rcpt_old, rcpt_new), syslog.LOG_NOTICE
                )
                self.addrcpt("<%s>" % (rcpt_new,))
                self.delrcpt("<%s>" % (rcpt_old,))

        new_headers = [x for x in self.headers if x["new"]]
        self.headers = [x for x in self.headers if not x["new"]]
        self.headers.extend(new_headers)
        headerCounts = {}
        for header in self.headers:
            if header["header"] not in headerCounts:
                headerCounts[header["header"]] = 0
            headerCounts[header["header"]] += 1
            if header["deleted"]:
                header["count"] = headerCounts[header["header"]]
            elif header["new"] or header["modified"]:
                if header["new"]:
                    self.log_with_id_maybe(
                        "Adding header %s: %s" % (header["header"], header["value"])
                    )
                else:
                    self.log_with_id_maybe(
                        "Replacing header %s: %s" % (header["header"], header["value"])
                    )
                if all(ord(c) < 128 for c in header["value"]):
                    self.chgheader(
                        header["header"],
                        headerCounts[header["header"]],
                        header["value"],
                    )
                else:
                    self.chgheader(
                        header["header"],
                        headerCounts[header["header"]],
                        email.header.Header(header["value"], "utf-8").encode(),
                    )

        for i in range(len(self.headers) - 1, -1, -1):
            if self.headers[i]["deleted"]:
                self.log_with_id_maybe(
                    "Deleting header %s" % (self.headers[i]["header"],)
                )
                self.chgheader(
                    self.headers[i]["header"], self.headers[i]["count"], None
                )

        if self.cfg["enable_body"]:
            (result, new_body) = self.call_delegate(
                self.delegate.body, self.rawbody, self.rawbody
            )
            if new_body != self.rawbody:
                self.log_with_id_maybe("Replacing body")
                self.replacebody(new_body)
            return result

        return delegate_result


class SoomaMilterFactory:
    def __init__(
        self,
        name,
        delegateClass,
        configurationFile=None,
        configurationDirectory=None,
        default_cfg=None,
    ):
        self.name = name
        self.header_callbacks = {}
        self.delegateFactory = delegateClass
        self.cfg = {
            "socket": "/var/spool/postfix/milter/%s.sock" % (name,),
            "umask": "002",
            "timeout": 600,
            "header-replace-prefix": "X-Original-",
            "logfacility": syslog.LOG_MAIL,
            "loglevel": syslog.LOG_NOTICE,
            "syslog_name": name,
            "enable_body": False,
            "action_on_error": Milter.ACCEPT,
        }
        for key in default_cfg.keys():
            self.cfg[key] = default_cfg[key]

        if configurationFile is None:
            if configurationDirectory is None:
                cfgFile = "/etc/milter/%s.ini" % (name,)
            else:
                cfgFile = "%s/%s.ini" % (configurationDirectory, configurationFile)
        else:
            cfgFile = configurationFile

        try:
            parsedConfig = configparser.ConfigParser()
            parsedConfig.read(cfgFile)
            for key in self.cfg.keys():
                if not parsedConfig.has_option(self.name, key):
                    continue
                if isinstance(self.cfg[key], int):
                    self.cfg[key] = parsedConfig.getint(self.name, key)
                elif isinstance(self.cfg[key], bool):
                    self.cfg[key] = parsedConfig.getboolean(self.name, key)
                else:
                    self.cfg[key] = parsedConfig.get(self.name, key)
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.log_exception_warning(
                "__init__",
                "Unable to parse config file '%s'" % (cfgFile,),
                exc_obj,
                exc_tb,
            )

    def log_exception_notice(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_NOTICE, exc_ob, exc_tb)

    def log_exception_warning(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_WARNING, exc_ob, exc_tb)

    def log_exception_error(self, method, exc_type, exc_ob=None, exc_tb=None):
        self.log_exception(method, exc_type, syslog.LOG_ERR, exc_ob, exc_tb)

    def log_exception(self, method, exc_type, loglevel, exc_ob=None, exc_tb=None):
        if exc_ob is None or exc_tb is None:
            self.log("Exception on method %s: %s" % (method, exc_type))
            return
        fname = os.path.split(exc_tb.tb_frame.f_code.co_filename)[1]
        self.log(
            "Exception on method %s: %s @%s+%d. %s"
            % (
                method,
                exc_type,
                fname,
                exc_tb.tb_lineno,
                ";".join(
                    [
                        line.replace("\n", "")
                        for line in traceback.format_list(traceback.extract_tb(exc_tb))
                    ]
                ),
            ),
            loglevel,
        )
        if self.cfg["loglevel"] == syslog.LOG_DEBUG:
            traceback.print_exception(exc_type, exc_ob, exc_tb)

    def log(self, msg, level=syslog.LOG_NOTICE):
        if level > self.cfg["loglevel"]:
            return
        if not self.log_initialized:
            syslog.openlog(
                self.cfg["syslog_name"], syslog.LOG_PID, self.cfg["logfacility"]
            )
        syslog.syslog(level, msg)
        if self.cfg["loglevel"] >= syslog.LOG_DEBUG:
            sys.stderr.write(msg)
            sys.stderr.write("\n")

    def register_header_callback(self, header, callback):
        header = header.lower()
        if header not in self.header_callbacks:
            self.header_callbacks[header] = []
        if callback not in self.header_callbacks[header]:
            self.header_callbacks[header].append(callback)

    def run(self):
        Milter.factory = self.factory
        Milter.set_exception_policy(Milter.CONTINUE)
        Milter.runmilter(self.name, self.cfg["socket"], self.cfg["timeout"])

    def factory(self):
        result = SoomaMilterDelegator(
            self.name, self.delegateFactory(), self.cfg, self.header_callbacks
        )
        return result
