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

class DomainMilterExpressionParser:
    T_LEFT_PARENS = 1
    T_RIGHT_PARENS = 2
    T_FUNCTION = 3
    T_COMMA = 4
    T_AND = 5
    T_OR = 6
    T_NOT = 7
    T_STRING = 8
    T_EOS = 9
    T_FUNCTION_AND_ARGS = 10
    T_BOOLEAN = 11

    @staticmethod
    def nextToken(s, pos=0):
        origPos = pos
        try:
            while pos < len(s) and s[pos] == ' ': pos+=1
            if pos == len(s):
                return ( (DomainMilterExpressionParser.T_EOS, '', pos), pos)
            if s[pos] == '(':
                return ( (DomainMilterExpressionParser.T_LEFT_PARENS, '(', pos), pos+1 )
            if s[pos] == ')':
                return ( (DomainMilterExpressionParser.T_RIGHT_PARENS, ')', pos), pos+1 )
            if s[pos] == ',':
                return ( (DomainMilterExpressionParser.T_COMMA, ',', pos), pos+1 )
            if s[pos:pos+3].lower() == 'and' and not (ord(s[pos+3].lower()) >= ord('a') and ord(s[pos+3].lower()) <= ord('z') or s[pos+3] == '_' or s[pos+3] == '-'):
                return ( (DomainMilterExpressionParser.T_AND, 'and', pos), pos+3 )
            if s[pos:pos+2].lower() == 'or' and not (ord(s[pos+2].lower()) >= ord('a') and ord(s[pos+2].lower()) <= ord('z') or s[pos+2] == '_' or s[pos+2] == '-'):
                return ( (DomainMilterExpressionParser.T_OR, 'or', pos), pos+2 )
            if s[pos:pos+3].lower() == 'not' and not (ord(s[pos+3].lower()) >= ord('a') and ord(s[pos+3].lower()) <= ord('z') or s[pos+3] == '_' or s[pos+3] == '-'):
                return ( (DomainMilterExpressionParser.T_NOT, 'not', pos), pos+3 )
            if ord(s[pos].lower()) >= ord('a') and ord(s[pos].lower()) <= ord('z') or s[pos] == '_':
                beg = pos
                while pos < len(s) and (ord(s[pos].lower()) >= ord('a') and ord(s[pos].lower()) <= ord('z') or s[pos] == '_' or s[pos] == '-'):
                    pos+=1
                return ( (DomainMilterExpressionParser.T_FUNCTION, s[beg:pos], pos), pos )
            if s[pos] == '"':
                beg = pos+1
                pos+=1
                while s[pos] != '"':
                    if s[pos] == '\\':
                        pos += 2
                    else:
                        pos += 1
                return ( (DomainMilterExpressionParser.T_STRING, re.sub(r'\\(.)', r'\1', s[beg:pos])), pos+1) 

        except IndexError:
            raise Exception("Error parsing string while tokenizing on character %d '%s...'" % (origPos, s[pos:][:3]))
        raise Exception("Error parsing string while tokenizing on character %d '%s...'" % (origPos, s[pos:][:3]))

    @staticmethod
    def tokenize(s):
        result = []
        pos = 0
        while True:
            (token, pos) = DomainMilterExpressionParser.nextToken(s, pos)
            if token[0] == DomainMilterExpressionParser.T_EOS:
                break
            result.append(token)
        source = result
        result = []
        curToken = 0
        # Consolidate T_FUNCTION_AND_ARGS tokens from lower level tokens
        while curToken < len(source):
            if source[curToken][0] == DomainMilterExpressionParser.T_FUNCTION:
                func_name = source[curToken][1]
                func_pos = source[curToken][2]
                args = []
                if curToken+1 < len(source) and source[curToken+1][0] == DomainMilterExpressionParser.T_LEFT_PARENS:
                    curToken += 2
                    if source[curToken][0] != DomainMilterExpressionParser.T_STRING and source[curToken][0] != DomainMilterExpressionParser.T_RIGHT_PARENS:
                        raise Exception("Unexpected token on character %d '%s...'" % (source[curToken][2], s[source[curToken][2]:][:3]))
                    while source[curToken][0] == DomainMilterExpressionParser.T_STRING:
                        args.append(source[curToken][1])
                        curToken += 1
                        if source[curToken][0] != DomainMilterExpressionParser.T_COMMA and source[curToken][0] != DomainMilterExpressionParser.T_RIGHT_PARENS:
                            raise Exception("Unexpected token on character %d '%s...'" % (source[curToken][2], s[source[curToken][2]:][:3]))
                        if source[curToken][0] == DomainMilterExpressionParser.T_COMMA:
                            curToken += 1
                            if source[curToken][0] != DomainMilterExpressionParser.T_STRING:
                                raise Exception("Unexpected token on character %d '%s...'" % (source[curToken][2], s[source[curToken][2]:][:3]))
                result.append( (DomainMilterExpressionParser.T_FUNCTION_AND_ARGS, (func_name, args), func_pos) )
                curToken += 1

            else:
                result.append(source[curToken])
                curToken += 1
        return result

    @staticmethod
    def infix_to_prefix(tokens):
        result = []
        stack = []
        tokens.reverse()
        precedenceMap = {
            DomainMilterExpressionParser.T_OR: [ DomainMilterExpressionParser.T_OR, DomainMilterExpressionParser.T_AND, DomainMilterExpressionParser.T_NOT ],
            DomainMilterExpressionParser.T_AND: [ DomainMilterExpressionParser.T_AND, DomainMilterExpressionParser.T_NOT ],
            DomainMilterExpressionParser.T_NOT: [ DomainMilterExpressionParser.T_NOT ],
            DomainMilterExpressionParser.T_LEFT_PARENS: [ ]
        }
        while len(tokens) > 0:
            t = tokens.pop()
            if t[0] == DomainMilterExpressionParser.T_FUNCTION_AND_ARGS:
                result.append(t)
            elif t[0] == DomainMilterExpressionParser.T_LEFT_PARENS:
                stack.append(t)
            elif t[0] == DomainMilterExpressionParser.T_RIGHT_PARENS:
                while stack[len(stack)-1][0] != DomainMilterExpressionParser.T_LEFT_PARENS:
                    result.append(stack.pop())
                    if len(stack) == 0: raise Exception("Unbalanced parenthesis in expression")
                stack.pop()
            else:
                while len(stack) > 0 and stack[len(stack)-1][0] in precedenceMap[t[0]]:
                    result.append(stack.pop())
                stack.append(t)
        while len(stack) > 0:
            result.append(stack.pop())

        result = [ (x[0], x[1]) for x in result ]
        return result

    @staticmethod
    def expression(s):
        return DomainMilterExpressionParser.infix_to_prefix(DomainMilterExpressionParser.tokenize(s))

class DomainMilter(SoomaMilter.SoomaMilterBase):

    def __init__(self):
        SoomaMilter.SoomaMilterBase.__init__(self)
        self.rules = {}
        self.db_connection = None
        self.expression_function_map = {
                'recipient_exists': self.expr_recipient_exists,
                'recipient_domain_exists': self.expr_recipient_domain_exists,
                'sender_is': self.expr_sender_is,
                'sender_domain_is': self.expr_sender_domain_is,
                'sender_domain_ends_with': self.expr_sender_domain_ends_with,
                'header_exists': self.expr_header_exists,
                'header_matches': self.expr_header_matches,
                'header_equals': self.expr_header_equals,
                'header_contains': self.expr_header_contains,
                'header_begins_with': self.expr_header_begins_with,
                'header_ends_with': self.expr_header_ends_with,
                'between_authorized_domains': self.expr_between_authorized_domains,
                'accept': self.expr_accept,
                'reject': self.expr_reject,
                'bcc': self.expr_bcc,
                'from_to_replyto': self.expr_from_to_replyto,
                'replace_from': self.expr_replace_from,
                'remove_recipient': self.expr_remove_recipient,
                'remove_all_recipients': self.expr_remove_all_recipients,
                'add_recipient': self.expr_add_recipient,
                'add_header': self.expr_add_header,
                'remove_headers': self.expr_remove_headers,
                'fix_messageid': self.expr_fix_messageid,
                'source_smtp_server': self.expr_source_smtp_server,
                'whitelist': self.expr_whitelist,
                'request_delivery_notification': self.expr_request_delivery_notification,
                'request_read_notification': self.expr_request_read_notification,
                'import': self.expr_import,
                }

    def db(self):
        if self.db_connection is None:
            self.db_connection = psycopg2.connect("host='%s' port=%d dbname='%s' user='%s' password='%s'" % (self.delegator.cfg['DBHost'], self.delegator.cfg['DBPort'], self.delegator.cfg['DBDatabase'], self.delegator.cfg['DBUser'], self.delegator.cfg['DBPassword']))
        return self.db_connection
    
    def all_recipients(self, recipients):
        SoomaMilter.SoomaMilterBase.all_recipients(self, recipients)
        sender_and_recipients = recipients
        sender_and_recipients.append(self.delegator.mail_from)
        self.rules = dict( (x[0], x[1]) for x in [ self.load_rules(recipient) for recipient in sender_and_recipients ] )
        if len(self.rules) == 0: 
            self.logger.log_with_id_maybe("No rules found, accepting message", syslog.LOG_INFO)
            return Milter.ACCEPT
        for recipient in self.rules.keys():
            for rule in self.rules[recipient]:
                try:
                    rule['match_expression'] = DomainMilterExpressionParser.expression(rule['match'])
                except:
                    exc_type, exc_obj, exc_tb = sys.exc_info()
                    self.delegator.log_exception_error("Ignoring rule because match expression failed parse: %s" % (rule['match'],), exc_type, exc_obj, exc_tb)
                    rule['match_expression'] = None
                try:
                    rule['action_expression'] = DomainMilterExpressionParser.expression(rule['action'])
                except:
                    exc_type, exc_obj, exc_tb = sys.exc_info()
                    self.delegator.log_exception_error("Ignoring rule because action expression failed parse: %s" % (rule['action'],), exc_type, exc_obj, exc_tb)
                    rule['action_expression'] = None
            self.rules[recipient] = [ x for x in self.rules[recipient] if x['match_expression'] is not None and x['action_expression'] is not None ]

    def load_rules(self, recipient):
        try:
            domain = recipient.split('@')[1]
        except IndexError:
            return ( '', [] )
        try:
            self.logger.log_with_id_maybe("Loading rules from domain %s" % (domain,), syslog.LOG_DEBUG)
            cursor = self.db().cursor()
            cursor.execute("""
SELECT match_rule as match, action_rule as action
FROM postfix.domain_filters
WHERE domain = LOWER(%s) OR domain = 'filtermaster.sooma.com'
ORDER BY CASE WHEN domain = 'filtermaster.sooma.com' THEN 0 ELSE 1 END
"""
                , (domain,))
            result = [ { 'match': row[0], 'action': row[1] } for row in cursor ]
            importRules = list(filter(lambda r: r['action'].startswith('import('), result))
            if len(importRules):
                importDomains = list(map(lambda r: r['action'][8:-2], importRules))
                importDomains.append(domain)
                importDomains.append('filtermaster.sooma.com')
                cursor.close()
                cursor = self.db().cursor()
                cursor.execute("""
SELECT match_rule as match, action_rule as action
FROM postfix.domain_filters
WHERE domain IN (__) AND action_rule NOT LIKE 'import(%%'
ORDER BY CASE WHEN domain = 'filtermaster.sooma.com' THEN 0 ELSE 1 END
"""
                .replace('__', ', '.join(list(map(lambda d: '%s', importDomains))), 1),
                importDomains)
                result = [ { 'match': row[0], 'action': row[1] } for row in cursor ]
            if len(result):
                self.logger.log_with_id_maybe("Loaded rules %s" % (result,), syslog.LOG_DEBUG)
            else:
                self.logger.log_with_id_maybe("No rules loaded", syslog.LOG_DEBUG)
                
            cursor.close()
        except (psycopg2.OperationalError, psycopg2.InternalError):
            # This is the exception raised when the DB connection closes on the other end. This
            # request now is doomed, but we reset the connection here to retry connecting on the next one
            self.db_connection = None
            raise # Re-throw the exception
        return ( domain, result )

    def all_headers(self, headers):
        return SoomaMilter.SoomaMilterBase.all_headers(self, headers)

    def eom(self):
        accept = None
        for recipient,rules in self.rules.items():
            for rule in rules:
                if accept is None:
                    if self.evaluate_expression(rule['match_expression']):
                        result = self.evaluate_expression(rule['action_expression'], is_action_expression = True)
                        if result == True:
                            self.logger.log_with_id_maybe("Accept from recipient %s rule %s" % (recipient, rule['match']), syslog.LOG_INFO)
                            accept = True
                        if result == False:
                            self.logger.log_with_id_maybe("Reject from recipient %s rule %s" % (recipient, rule['match']), syslog.LOG_NOTICE)
                            accept = False
        if accept == True:
            self.logger.log_with_id_maybe("Accepting message after processing all rules", syslog.LOG_INFO)
            return Milter.CONTINUE # This is not Milter.ACCEPT, on purpose, so that self.delegator.eom still runs and executes message change operations
        if accept == False:
            self.logger.log_with_id_maybe("Rejecting message after processing all rules", syslog.LOG_NOTICE)
            return Milter.REJECT
        return Milter.CONTINUE

    # This evaluator has two different modes:
    #  - is_action_expression == False: None value is absorvent in AND, OR and NOT operations
    #  - is_action_expression == True: None value is neutral in AND, OR and NOT operations
    def evaluate_expression(self, expression_stack, is_action_expression = False):
        calc_stack = []
        for operand_or_operation in expression_stack:

            if operand_or_operation[0] == DomainMilterExpressionParser.T_AND:
                left = calc_stack.pop()
                right = calc_stack.pop()
                if left is None or right is None:
                    result = None if not is_action_expression else left if right is None else right
                else:
                    result = left and right
                calc_stack.append(result)
            elif operand_or_operation[0] == DomainMilterExpressionParser.T_OR:
                left = calc_stack.pop()
                right = calc_stack.pop()
                if left is None or right is None:
                    result = None if not is_action_expression else left if right is None else right
                else:
                    result = left or right
                calc_stack.append(result)
            elif operand_or_operation[0] == DomainMilterExpressionParser.T_NOT:
                left = calc_stack.pop()
                if left is None:
                    result = None
                else:
                    result = not left
                calc_stack.append(result)
            elif operand_or_operation[0] == DomainMilterExpressionParser.T_FUNCTION_AND_ARGS:
                calc_stack.append(self.eval_function(operand_or_operation[1][0], operand_or_operation[1][1]))

        if len(calc_stack) != 1:
            raise Exception("Internal error evaluating expression (final operation stack contains %d != 1 element)" % len(calc_stack))
        
        return calc_stack[0]

    def eval_function(self, f_name, f_args):
        if f_name not in self.expression_function_map:
            raise Exception("Expression uses unknown function %s" % f_name)
        return self.expression_function_map[f_name](*f_args)

    def expr_recipient_exists(self, recipient):
        recipientsToTest = recipient.replace(',', ' ').lower().split()
        return 0 < len(set(recipient.replace(',', ' ').lower().split()).intersection(self.delegator.rcpt_to))

    def expr_recipient_domain_exists(self, domain):
        domainsToTest = domain.replace(',', ' ').lower().split()
        return True in [rcptDomain in domainsToTest for rcptDomain in [rcpt.lower().split('@')[1] for rcpt in self.delegator.rcpt_to if '@' in rcpt]]

    def sender_from_mail_from_or_header(self):
        if self.delegator.mail_from is not None: return self.delegator.mail_from
        candidate = [x['value'] for x in self.delegator.headers if x['header'].lower() == 'from']
        if len(candidate) == 0: return None
        return '@'.join(Milter.utils.parse_addr(candidate[0])).lower()

    def expr_sender_is(self, sender_address):
        mail_from = self.sender_from_mail_from_or_header()
        if mail_from is None:
            raise Exception("sender_is called when mail_from is None")
        if self.delegator.mail_from is None:
            return False
        return mail_from.lower() in sender_address.replace(',', ' ').lower().split()

    def expr_sender_domain_is(self, domain):
        mail_from = self.sender_from_mail_from_or_header()
        if mail_from is None:
            raise Exception("sender_is called when mail_from is None")
        try:
            return mail_from.lower().split('@')[1] in domain.replace(',', ' ').lower().split()
        except IndexError:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning("(expr_sender_domain_is) Invalid mail_from %s" % (mail_from.lower(),), exc_obj, exc_tb)
            return False

    def expr_sender_domain_ends_with(self, end_match):
        mail_from = self.sender_from_mail_from_or_header()
        if mail_from is None:
            raise Exception("sender_domain_ends_with called when mail_from is None")
        try:
            return mail_from.lower().split('@')[1].endswith(end_match.lower())
        except IndexError:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning("(expr_sender_domain_ends_with) Invalid mail_from %s" % (mail_from.lower(),), exc_obj, exc_tb)
            return False

    def expr_header_exists(self, header):
        return header.lower() in [x['header'].lower() for x in self.delegator.headers]

    def expr_header_matches(self, header, value):
        regular_expression = re.compile(value)
        header = header.lower()
        return True in [regular_expression.match(x['value']) is not None for x in self.delegator.headers if x['header'].lower() == header]

    def expr_header_equals(self, header, testValue):
        header = header.lower()
        return testValue in [x['value'] for x in self.delegator.headers if x['header'].lower() == header]

    def expr_header_contains(self, header, substring):
        header = header.lower()
        return True in  [substring.lower() in x['value'].lower() for x in self.delegator.headers if x['header'].lower() == header]

    def expr_header_begins_with(self, header, substring):
        header = header.lower()
        return True in  [x['value'].startswith(substring) for x in self.delegator.headers if x['header'].lower() == header]
    
    def expr_header_ends_with(self, header, substring):
        header = header.lower()
        return True in  [x['value'].endswith(substring) for x in self.delegator.headers if x['header'].lower() == header]

    def expr_between_authorized_domains(self, authorized_domains_list):
        authorized_domains_list = authorized_domains_list.replace(',', ' ').lower().split()
        mail_from = self.sender_from_mail_from_or_header()
        mail_from_domain = ''
        if mail_from is None:
            raise Exception("between_authorized_domains called when mail_from is None")
        try:
            mail_from_domain = mail_from.split('@')[1].lower()
            if mail_from_domain in authorized_domains_list: return True
        except IndexError:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning("(expr_between_authorized_domains) Invalid mail_from %s" % (mail_from.lower(),), exc_obj, exc_tb)
        for rcpt in self.delegator.rcpt_to:
            try:
                if not rcpt.split('@')[1].lower() in authorized_domains_list and rcpt.split('@')[1].lower() != mail_from_domain:
                    return False
            except (IndexError,TypeError):
                exc_type, exc_obj, exc_tb = sys.exc_info()
                self.logger.log_exception_warning("(expr_between_authorized_domains) Invalid recipient %s" % (rcpt.lower(),), exc_obj, exc_tb)
        return True

    def expr_accept(self):
        return True

    def expr_reject(self):
        return False

    def expr_bcc(self, bcc):
        self.logger.log_with_id_maybe("Adding bcc recipient %s" % (bcc,), syslog.LOG_INFO)
        bcc = bcc.lower()
        self.delegator.rcpt_to_to_add.append(bcc)

    def expr_from_to_replyto(self, replaceWith):
        self.logger.log_with_id_maybe("Moving from to rcpt_to and setting from to %s" % (replaceWith,), syslog.LOG_INFO)
        current_from = self.delegator.mail_from
        from_header = self.delegator.get_or_create_header('From')
        replyto_header = self.delegator.get_or_create_header('Reply-To')
        from_header['value'] = replaceWith
        from_header['modified'] = True
        replyto_header['value'] = current_from
        replyto_header['modified'] = True

    def expr_replace_from(self, replaceWith):
        self.logger.log_with_id_maybe("Setting from to %s" % (replaceWith,), syslog.LOG_INFO)
        current_from = self.delegator.mail_from
        from_header = self.delegator.get_or_create_header('From')
        from_header['value'] = replaceWith
        from_header['modified'] = True

    def expr_remove_recipient(self, recipient):
        for recipient in recipient.replace(',', ' ').lower().split():
            self.logger.log_with_id_maybe("Removing recipient %s (if it exists)" % (recipient,), syslog.LOG_INFO)
            recipient = recipient.lower()
            self.delegator.rcpt_to_to_delete.append(recipient)
    
    def expr_remove_all_recipients(self):
        for recipient in self.delegator.rcpt_to:
            self.logger.log_with_id_maybe("Removing recipient %s" % (recipient,), syslog.LOG_INFO)
            self.delegator.rcpt_to_to_delete.append(recipient)
    
    def expr_add_recipient(self, recipient):
        self.logger.log_with_id_maybe("Adding recipient %s" % (recipient,), syslog.LOG_INFO)
        recipient = recipient.lower()
        self.delegator.rcpt_to_to_add.append(recipient)
        for header in [h for h in self.delegator.headers if h['header'].lower() == 'cc']:
            header['value'] += ", " + recipient
            header['modified'] = True
            header['deleted'] = False
        else:
            self.delegator.headers.append( { 'header': 'Cc', 'value': recipient, 'modified': False, 'deleted': False, 'new': True } )
    
    def expr_add_header(self, header, value):
        self.delegator.headers.append( { 'header': header, 'value': value, 'modified': False, 'deleted': False, 'new': True } )
    
    def expr_request_delivery_notification(self):
        self.delegator.headers.append( { 'header': 'Disposition-Notification-To', 'value': self.delegator.mail_from, 'modified': False, 'deleted': False, 'new': True } )
    
    def expr_request_read_notification(self):
        self.delegator.headers.append( { 'header': 'Return-Receipt-To', 'value': self.delegator.mail_from, 'modified': False, 'deleted': False, 'new': True } )

    def expr_import(self):
        pass

    def expr_remove_headers(self, header):
        for toDelete in [h for h in self.delegator.headers if h['header'].lower() == header]:
            toDelete['deleted'] = True

    def expr_fix_messageid(self):
        messageId = self.delegator.get_or_create_header('Message-ID')
        if messageId['value'] == '':
            ts = datetime.datetime.now()
            messageId['value'] = ts.strftime("%s") + "." + ("%s" % (ts.microsecond,))
            messageId['modified'] = True

        if '@' not in messageId['value']:
            try:
                domain = self.delegator.mail_from.split('@')[1]
            except IndexError:
                domain = 'sooma.com'
            messageId['value'] += '@' + domain
            messageId['modified'] = True
        
        self.logger.log_with_id_maybe("Fixing message id: %s" % (messageId['value'],) , syslog.LOG_INFO)

    def expr_source_smtp_server(self, ip_to_match):
        try:
            return ip_to_match == self.delegator.remote['address'][0]
        except:
            exc_type, exc_obj, exc_tb = sys.exc_info()
            self.logger.log_exception_warning("Exception evaluating source_smtp_server. Returning false from match.", exc_obj, exc_tb)
            return False

    def expr_whitelist(self):
        sooma_whitelist = self.delegator.get_or_create_header('X-Sooma-Whitelist')
        sooma_whitelist['value'] = 'whitelisted'
        sooma_whitelist['modified'] = True

SoomaMilter.SoomaMilterFactory('domain_milter', DomainMilter, default_cfg = { 
    'loglevel': syslog.LOG_DEBUG,
    'DBPort': 5432,
    'DBHost': 'localhost',
    'DBDatabase': 'mail_profissional',
    'DBUser': 'postfix',
    'DBPassword': 'postfix'
    }).run()
