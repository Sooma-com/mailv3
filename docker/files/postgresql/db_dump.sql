--
-- PostgreSQL database cluster dump
--

\restrict ZAGeqheNS9tRfeHlOl9LZ9HeG7pyuyNdzoxEM9KOqktRisBcs8mUm3wXtIbmh2A

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE amavis;
ALTER ROLE amavis WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE horde;
ALTER ROLE horde WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE openldap;
ALTER ROLE openldap WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postfix;
ALTER ROLE postfix WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;

--
-- User Configurations
--








\unrestrict ZAGeqheNS9tRfeHlOl9LZ9HeG7pyuyNdzoxEM9KOqktRisBcs8mUm3wXtIbmh2A

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict bqLNOdlv9mrrblnp5yGnho1z9pTxFmAa3DkfIy5gTyinJwQoidprja5rnGObZiN

-- Dumped from database version 17.6 (Debian 17.6-0+deb13u1)
-- Dumped by pg_dump version 17.6 (Debian 17.6-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict bqLNOdlv9mrrblnp5yGnho1z9pTxFmAa3DkfIy5gTyinJwQoidprja5rnGObZiN

--
-- Database "mail_profissional" dump
--

--
-- PostgreSQL database dump
--

\restrict fTyhMD6tPGXF4GbIX5q4zrDbMQhTAvB4BYFMTnkTqwEhVgHKOt2KRlXdXh8L5al

-- Dumped from database version 17.6 (Debian 17.6-0+deb13u1)
-- Dumped by pg_dump version 17.6 (Debian 17.6-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: mail_profissional; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE mail_profissional WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C.UTF-8';


ALTER DATABASE mail_profissional OWNER TO postgres;

\unrestrict fTyhMD6tPGXF4GbIX5q4zrDbMQhTAvB4BYFMTnkTqwEhVgHKOt2KRlXdXh8L5al
\connect mail_profissional
\restrict fTyhMD6tPGXF4GbIX5q4zrDbMQhTAvB4BYFMTnkTqwEhVgHKOt2KRlXdXh8L5al

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: amavis; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA amavis;


ALTER SCHEMA amavis OWNER TO postgres;

--
-- Name: invoicexpress; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA invoicexpress;


ALTER SCHEMA invoicexpress OWNER TO postgres;

--
-- Name: openldap; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA openldap;


ALTER SCHEMA openldap OWNER TO postgres;

--
-- Name: postfix; Type: SCHEMA; Schema: -; Owner: horde
--

CREATE SCHEMA postfix;


ALTER SCHEMA postfix OWNER TO horde;

--
-- Name: postfix_submission; Type: SCHEMA; Schema: -; Owner: postfix
--

CREATE SCHEMA postfix_submission;


ALTER SCHEMA postfix_submission OWNER TO postfix;

--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: profissional_alias_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_alias_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 DELETE FROM profissional_email_aliases WHERE email_id = OLD.id;
 DELETE FROM profissional_emails WHERE id = OLD.id;
END;
$$;


ALTER FUNCTION public.profissional_alias_delete() OWNER TO postgres;

--
-- Name: profissional_alias_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_alias_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 new_id integer;
 result profissional_alias;
BEGIN
 INSERT INTO profissional_emails(email, parent, active, type, receive_password, permitted_senders) VALUES(NEW.email, NEW.parent, NEW.active, 'a', NEW.receive_password, NEW.permitted_senders) RETURNING id INTO new_id;
 INSERT INTO profissional_email_aliases(email_id, maildrop, tag_subject, maildrop_definition, permitted_senders_definition, maildrop_group_list_array) VALUES(new_id, NEW.maildrop, NEW.tag_subject, NEW.maildrop_definition, NEW.permitted_senders_definition, NEW.maildrop_group_list_array);
 SELECT * FROM profissional_alias WHERE id = new_id INTO result;
 RETURN result;
END;
$$;


ALTER FUNCTION public.profissional_alias_insert() OWNER TO postgres;

--
-- Name: profissional_alias_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_alias_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 result profissional_alias;
BEGIN
 UPDATE profissional_emails SET email = NEW.email, parent = NEW.parent, active = NEW.active, receive_password = NEW.receive_password, permitted_senders = NEW.permitted_senders WHERE id = OLD.id;
 UPDATE profissional_email_aliases SET maildrop = NEW.maildrop, tag_subject = NEW.tag_subject, maildrop_definition = NEW.maildrop_definition, permitted_senders_definition = NEW.permitted_senders_definition, maildrop_group_list_array = NEW.maildrop_group_list_array WHERE email_id = OLD.id;
 SELECT * FROM profissional_alias WHERE id = OLD.id INTO result;
 RETURN result;
END;
$$;


ALTER FUNCTION public.profissional_alias_update() OWNER TO postgres;

--
-- Name: profissional_domains_emails_username_trigger(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_domains_emails_username_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
-- This function exists because of the deprecated profissional_emails.email field.
-- If the field is dropped, and replaced by (profissional_emails.username, profissional_domains.name)
-- then this function and corresponding trigger are no longer necessary
BEGIN
    IF (NEW.name != OLD.name) THEN
        UPDATE profissional_emails SET email = username || '@' || NEW.name WHERE parent = NEW.id;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_domains_emails_username_trigger() OWNER TO horde;

--
-- Name: profissional_domains_horde_groups_members_trigger(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_domains_horde_groups_members_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.name != OLD.name) THEN
        UPDATE horde_groups_members SET user_uid = split_part(user_uid, '@', 1) || '@' || NEW.name WHERE user_uid LIKE '%@' || OLD.name;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_domains_horde_groups_members_trigger() OWNER TO horde;

--
-- Name: profissional_domains_horde_prefs_trigger(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_domains_horde_prefs_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (NEW.name != OLD.name) THEN
        UPDATE horde_prefs SET pref_uid = split_part(pref_uid, '@', 1) || '@' || NEW.name WHERE pref_uid LIKE '%@' || OLD.name;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_domains_horde_prefs_trigger() OWNER TO horde;

--
-- Name: profissional_email_aliases_maildrop_trigger(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_email_aliases_maildrop_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.maildrop_array := array_agg(email) FROM (SELECT (regexp_matches(NEW.maildrop, '"([^"]*)"', 'g'))[1] AS email) AS foo;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_email_aliases_maildrop_trigger() OWNER TO horde;

--
-- Name: profissional_email_users_quota_deprecation(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_email_users_quota_deprecation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 product_count integer;
BEGIN
    IF (NEW.product_id IS NULL and NEW.quota IS NOT NULL) THEN
        NEW.product_id = id FROM profissional_products WHERE profissional_products.quota = NEW.quota;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        IF OLD.quota != NEW.quota THEN
            NEW.product_id = id FROM profissional_products WHERE profissional_products.quota = NEW.quota;
        END IF;
    END IF;
    product_count = count(*) FROM public.profissional_products WHERE id = NEW.product_id;
    IF product_count = 0 THEN
        RAISE EXCEPTION 'product_id not found in profissional_products';
    END IF;
    NEW.quota = quota FROM public.profissional_products WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_email_users_quota_deprecation() OWNER TO horde;

--
-- Name: profissional_emails_username_trigger(); Type: FUNCTION; Schema: public; Owner: horde
--

CREATE FUNCTION public.profissional_emails_username_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.username := split_part(NEW.email, '@', 1);
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.profissional_emails_username_trigger() OWNER TO horde;

--
-- Name: profissional_sync_queue_edit(text, text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_sync_queue_edit(text, text, text, text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
 arg_email_to ALIAS FOR $1;
 arg_email_from ALIAS FOR $2;
 arg_imap_from ALIAS FOR $3;
 arg_state ALIAS FOR $4;
 result integer;
BEGIN
 LOCK TABLE profissional_sync_queue IN EXCLUSIVE MODE;
 UPDATE profissional_sync_queue SET email_from = COALESCE(arg_email_from, email_from), imap_from = COALESCE(arg_imap_from, imap_from), state = COALESCE(arg_state, state) WHERE email_to = arg_email_to AND state != 'SYNCING';
 GET DIAGNOSTICS result = ROW_COUNT;
 RETURN result;
END;
$_$;


ALTER FUNCTION public.profissional_sync_queue_edit(text, text, text, text) OWNER TO postgres;

--
-- Name: profissional_sync_queue_resync_next(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_sync_queue_resync_next(text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
 arg_domain ALIAS FOR $1;
 result integer;
BEGIN
 LOCK TABLE profissional_sync_queue IN EXCLUSIVE MODE;
 result := id FROM profissional_sync_queue WHERE email_to LIKE '%@' || arg_domain AND state = 'ALREADY_SYNCED' ORDER BY last_sync_ts LIMIT 1;
 UPDATE profissional_sync_queue SET state = 'SYNCING', last_sync_ts = now() WHERE id = result;
 RETURN result;
END;
$_$;


ALTER FUNCTION public.profissional_sync_queue_resync_next(text) OWNER TO postgres;

--
-- Name: profissional_sync_queue_sync_next(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_sync_queue_sync_next(text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
 arg_domain ALIAS FOR $1;
 result integer;
BEGIN
 LOCK TABLE profissional_sync_queue IN EXCLUSIVE MODE;
 result := id FROM profissional_sync_queue WHERE email_to LIKE '%@' || arg_domain AND state = 'NEVER_SYNCED' ORDER BY id LIMIT 1;
 UPDATE profissional_sync_queue SET state = 'SYNCING', last_sync_ts = now() WHERE id = result;
 RETURN result;
END;
$_$;


ALTER FUNCTION public.profissional_sync_queue_sync_next(text) OWNER TO postgres;

--
-- Name: profissional_users_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_users_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
 DELETE FROM profissional_email_users WHERE email_id = OLD.id;
 DELETE FROM profissional_emails WHERE id = OLD.id;
END;
$$;


ALTER FUNCTION public.profissional_users_delete() OWNER TO postgres;

--
-- Name: profissional_users_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_users_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 new_id integer;
 result profissional_users;
BEGIN
 INSERT INTO profissional_emails(email, parent, active, type) VALUES(NEW.email, NEW.parent, NEW.active, 'u') RETURNING id INTO new_id;
 INSERT INTO profissional_email_users(email_id, password, homedir, apikey, blocked_contents, mailbox, imapserver, smtpserver, must_change_password, product_id, pop3_disabled, outbound_volume, webmail_disabled) VALUES(new_id, NEW.password, NEW.homedir, NEW.apikey, NEW.blocked_contents, NEW.mailbox, NEW.imapserver, NEW.smtpserver, NEW.must_change_password, NEW.product_id, NEW.pop3_disabled, NEW.outbound_volume, NEW.webmail_disabled);
 SELECT * FROM profissional_users WHERE id = new_id INTO result;
 RETURN result;
END;
$$;


ALTER FUNCTION public.profissional_users_insert() OWNER TO postgres;

--
-- Name: profissional_users_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.profissional_users_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
 new_id integer;
 result profissional_users;
BEGIN
 UPDATE profissional_email_users SET password = NEW.password, homedir = NEW.homedir, apikey = NEW.apikey, blocked_contents = NEW.blocked_contents, mailbox = NEW.mailbox, imapserver = NEW.imapserver, smtpserver = NEW.smtpserver, must_change_password = NEW.must_change_password, product_id = NEW.product_id, pop3_disabled = NEW.pop3_disabled, outbound_volume = NEW.outbound_volume, webmail_disabled = NEW.webmail_disabled WHERE email_id = OLD.id;
 UPDATE profissional_emails SET email = NEW.email, parent = NEW.parent, active = NEW.active WHERE id = OLD.id;
 SELECT * FROM profissional_users WHERE id = OLD.id INTO result;

 RETURN result;
END;
$$;


ALTER FUNCTION public.profissional_users_update() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: mailaddr; Type: TABLE; Schema: amavis; Owner: postgres
--

CREATE TABLE amavis.mailaddr (
    id integer NOT NULL,
    priority integer DEFAULT 9 NOT NULL,
    email bytea NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE amavis.mailaddr OWNER TO postgres;

--
-- Name: mailaddr_id_seq; Type: SEQUENCE; Schema: amavis; Owner: postgres
--

CREATE SEQUENCE amavis.mailaddr_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE amavis.mailaddr_id_seq OWNER TO postgres;

--
-- Name: mailaddr_id_seq; Type: SEQUENCE OWNED BY; Schema: amavis; Owner: postgres
--

ALTER SEQUENCE amavis.mailaddr_id_seq OWNED BY amavis.mailaddr.id;


--
-- Name: policy; Type: TABLE; Schema: amavis; Owner: postgres
--

CREATE TABLE amavis.policy (
    id integer NOT NULL,
    policy_name character varying(32),
    virus_lover character(1) DEFAULT NULL::bpchar,
    spam_lover character(1) DEFAULT NULL::bpchar,
    unchecked_lover character(1) DEFAULT NULL::bpchar,
    banned_files_lover character(1) DEFAULT NULL::bpchar,
    bad_header_lover character(1) DEFAULT NULL::bpchar,
    bypass_virus_checks character(1) DEFAULT NULL::bpchar,
    bypass_spam_checks character(1) DEFAULT NULL::bpchar,
    bypass_banned_checks character(1) DEFAULT NULL::bpchar,
    bypass_header_checks character(1) DEFAULT NULL::bpchar,
    virus_quarantine_to character varying(64) DEFAULT NULL::character varying,
    spam_quarantine_to character varying(64) DEFAULT NULL::character varying,
    banned_quarantine_to character varying(64) DEFAULT NULL::character varying,
    unchecked_quarantine_to character varying(64) DEFAULT NULL::character varying,
    bad_header_quarantine_to character varying(64) DEFAULT NULL::character varying,
    clean_quarantine_to character varying(64) DEFAULT NULL::character varying,
    archive_quarantine_to character varying(64) DEFAULT NULL::character varying,
    spam_tag_level real,
    spam_tag2_level real,
    spam_tag3_level real,
    spam_kill_level real,
    spam_dsn_cutoff_level real,
    spam_quarantine_cutoff_level real,
    addr_extension_virus character varying(64) DEFAULT NULL::character varying,
    addr_extension_spam character varying(64) DEFAULT NULL::character varying,
    addr_extension_banned character varying(64) DEFAULT NULL::character varying,
    addr_extension_bad_header character varying(64) DEFAULT NULL::character varying,
    warnvirusrecip character(1) DEFAULT NULL::bpchar,
    warnbannedrecip character(1) DEFAULT NULL::bpchar,
    warnbadhrecip character(1) DEFAULT NULL::bpchar,
    newvirus_admin character varying(64) DEFAULT NULL::character varying,
    virus_admin character varying(64) DEFAULT NULL::character varying,
    banned_admin character varying(64) DEFAULT NULL::character varying,
    bad_header_admin character varying(64) DEFAULT NULL::character varying,
    spam_admin character varying(64) DEFAULT NULL::character varying,
    spam_subject_tag character varying(64) DEFAULT NULL::character varying,
    spam_subject_tag2 character varying(64) DEFAULT NULL::character varying,
    spam_subject_tag3 character varying(64) DEFAULT NULL::character varying,
    message_size_limit integer,
    banned_rulenames character varying(64) DEFAULT NULL::character varying,
    disclaimer_options character varying(64) DEFAULT NULL::character varying,
    forward_method character varying(64) DEFAULT NULL::character varying,
    sa_userconf character varying(64) DEFAULT NULL::character varying,
    sa_username character varying(64) DEFAULT NULL::character varying
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE amavis.policy OWNER TO postgres;

--
-- Name: policy_id_seq; Type: SEQUENCE; Schema: amavis; Owner: postgres
--

CREATE SEQUENCE amavis.policy_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE amavis.policy_id_seq OWNER TO postgres;

--
-- Name: policy_id_seq; Type: SEQUENCE OWNED BY; Schema: amavis; Owner: postgres
--

ALTER SEQUENCE amavis.policy_id_seq OWNED BY amavis.policy.id;


--
-- Name: profissional_clients; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_clients (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    parent integer NOT NULL,
    address character varying(512),
    city character varying(128),
    postalcode character varying(128),
    nif character varying(128),
    phonenumber character varying(128),
    contactname character varying(255),
    email character varying(128),
    active boolean DEFAULT true NOT NULL,
    logo bytea,
    creation_time timestamp without time zone DEFAULT now() NOT NULL,
    offer boolean DEFAULT false,
    offer_reason text,
    external_id character varying(128),
    we_manage_domain boolean,
    billing_period character varying(128),
    theme_colors text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_clients OWNER TO horde;

--
-- Name: profissional_domains; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_domains (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    parent integer NOT NULL,
    active boolean NOT NULL,
    userslimit integer DEFAULT 1000,
    logo bytea,
    creation_time timestamp without time zone DEFAULT now() NOT NULL,
    language character varying(255) DEFAULT 'pt_PT'::character varying NOT NULL,
    setup_complete boolean DEFAULT false NOT NULL,
    timezone character varying(255) DEFAULT 'Europe/Lisbon'::character varying NOT NULL,
    offer boolean DEFAULT false,
    offer_reason text,
    migrating boolean DEFAULT false NOT NULL,
    dkim_enabled boolean DEFAULT false,
    dkim_selector character varying(255) DEFAULT NULL::character varying,
    dkim_key_private character varying(2048) DEFAULT NULL::character varying,
    dkim_key_public character varying(2048) DEFAULT NULL::character varying,
    pref_usersmusthavegroups boolean DEFAULT false,
    theme_colors text,
    spam_header_threshold integer DEFAULT 0,
    spam_subject_threshold integer DEFAULT 5,
    spam_flag_threshold integer DEFAULT 7,
    spam_refuse_threshold integer DEFAULT 10,
    password_rotation interval
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_domains OWNER TO horde;

--
-- Name: profissional_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_domains_id_seq OWNER TO horde;

--
-- Name: profissional_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_domains_id_seq OWNED BY public.profissional_domains.id;


--
-- Name: profissional_domain_aliases; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_domain_aliases (
    id integer DEFAULT nextval('public.profissional_domains_id_seq'::regclass) NOT NULL,
    name character varying(255) NOT NULL,
    parent integer NOT NULL,
    active boolean DEFAULT false NOT NULL,
    dkim_enabled boolean DEFAULT false
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_domain_aliases OWNER TO horde;

--
-- Name: profissional_resellers; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_resellers (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    active boolean DEFAULT true NOT NULL,
    logo bytea,
    creation_time timestamp without time zone DEFAULT now() NOT NULL,
    offer boolean DEFAULT false,
    offer_reason text,
    nif character varying(255) DEFAULT 0 NOT NULL,
    webmaildomain character varying(255),
    theme_colors text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_resellers OWNER TO horde;

--
-- Name: domains; Type: VIEW; Schema: postfix; Owner: horde
--

CREATE VIEW postfix.domains AS
 SELECT domains.id,
    domains.alias_id,
    domains.name,
    domains.parent,
    domains.active,
    domains.userslimit,
    domains.logo,
    domains.creation_time,
    domains.language,
    domains.setup_complete,
    domains.timezone,
    domains.offer,
    domains.offer_reason,
    domains.migrating,
    domains.dkim_enabled,
    domains.dkim_selector,
    domains.dkim_key_private,
    domains.dkim_key_public
   FROM ((( SELECT profissional_domains.id,
            NULL::integer AS alias_id,
            lower((profissional_domains.name)::text) AS name,
            profissional_domains.parent,
            profissional_domains.active,
            profissional_domains.userslimit,
            profissional_domains.logo,
            profissional_domains.creation_time,
            profissional_domains.language,
            profissional_domains.setup_complete,
            profissional_domains.timezone,
            profissional_domains.offer,
            profissional_domains.offer_reason,
            profissional_domains.migrating,
            profissional_domains.dkim_enabled,
            profissional_domains.dkim_selector,
            profissional_domains.dkim_key_private,
            profissional_domains.dkim_key_public
           FROM public.profissional_domains
          WHERE profissional_domains.active
        UNION
         SELECT profissional_domains.id,
            profissional_domain_aliases.id AS alias_id,
            lower((profissional_domain_aliases.name)::text) AS name,
            profissional_domains.parent,
            profissional_domains.active,
            profissional_domains.userslimit,
            profissional_domains.logo,
            profissional_domains.creation_time,
            profissional_domains.language,
            profissional_domains.setup_complete,
            profissional_domains.timezone,
            profissional_domains.offer,
            profissional_domains.offer_reason,
            profissional_domains.migrating,
            profissional_domain_aliases.dkim_enabled,
            profissional_domains.dkim_selector,
            profissional_domains.dkim_key_private,
            profissional_domains.dkim_key_public
           FROM (public.profissional_domain_aliases
             JOIN public.profissional_domains ON ((profissional_domain_aliases.parent = profissional_domains.id)))
          WHERE (profissional_domains.active AND profissional_domain_aliases.active)) domains
     JOIN public.profissional_clients ON (((domains.parent = profissional_clients.id) AND profissional_clients.active)))
     JOIN public.profissional_resellers ON (((profissional_resellers.id = profissional_clients.parent) AND profissional_resellers.active)));


ALTER VIEW postfix.domains OWNER TO horde;

--
-- Name: profissional_emails; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_emails (
    id integer NOT NULL,
    email character varying(512) NOT NULL,
    parent integer NOT NULL,
    active boolean NOT NULL,
    type character(1) NOT NULL,
    username character varying(512),
    sync_guid character varying(1024),
    receive_password character varying(512) DEFAULT NULL::character varying,
    permitted_senders text,
    CONSTRAINT fk_profissional_emails_type CHECK (((type = 'u'::bpchar) OR (type = 'a'::bpchar)))
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_emails OWNER TO horde;

--
-- Name: users; Type: VIEW; Schema: amavis; Owner: postgres
--

CREATE VIEW amavis.users AS
 SELECT profissional_emails.id,
    decode(lower((((profissional_emails.username)::text || '@'::text) || domains.name)), 'escape'::text) AS email,
    7 AS priority,
    1 AS policy_id
   FROM (public.profissional_emails
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
  WHERE profissional_emails.active;


ALTER VIEW amavis.users OWNER TO postgres;

--
-- Name: wblist; Type: TABLE; Schema: amavis; Owner: postgres
--

CREATE TABLE amavis.wblist (
    rid integer NOT NULL,
    sid integer NOT NULL,
    wb character varying(10) NOT NULL,
    CONSTRAINT wblist_rid_check CHECK ((rid >= 0)),
    CONSTRAINT wblist_sid_check CHECK ((sid >= 0))
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE amavis.wblist OWNER TO postgres;

--
-- Name: client; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.client (
    reseller integer NOT NULL,
    profissional_client integer NOT NULL,
    external_id integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.client OWNER TO postgres;

--
-- Name: invoice; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.invoice (
    id integer NOT NULL,
    reseller integer NOT NULL,
    profissional_client integer NOT NULL,
    date date NOT NULL,
    external_id integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.invoice OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: invoicexpress; Owner: postgres
--

CREATE SEQUENCE invoicexpress.invoice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE invoicexpress.invoice_id_seq OWNER TO postgres;

--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: invoicexpress; Owner: postgres
--

ALTER SEQUENCE invoicexpress.invoice_id_seq OWNED BY invoicexpress.invoice.id;


--
-- Name: invoiceline; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.invoiceline (
    id integer NOT NULL,
    invoice integer NOT NULL,
    profissional_product integer NOT NULL,
    count integer NOT NULL,
    discount integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.invoiceline OWNER TO postgres;

--
-- Name: invoiceline_id_seq; Type: SEQUENCE; Schema: invoicexpress; Owner: postgres
--

CREATE SEQUENCE invoicexpress.invoiceline_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE invoicexpress.invoiceline_id_seq OWNER TO postgres;

--
-- Name: invoiceline_id_seq; Type: SEQUENCE OWNED BY; Schema: invoicexpress; Owner: postgres
--

ALTER SEQUENCE invoicexpress.invoiceline_id_seq OWNED BY invoicexpress.invoiceline.id;


--
-- Name: item; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.item (
    reseller integer NOT NULL,
    profissional_product integer NOT NULL,
    external_id integer,
    external_id_discount integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.item OWNER TO postgres;

--
-- Name: usagemeter; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.usagemeter (
    date date NOT NULL,
    product integer NOT NULL,
    client integer NOT NULL,
    count integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.usagemeter OWNER TO postgres;

--
-- Name: monthlyusage; Type: VIEW; Schema: invoicexpress; Owner: postgres
--

CREATE VIEW invoicexpress.monthlyusage AS
 SELECT date,
    product,
    client,
    max(count) AS count
   FROM ( SELECT ((((date_part('year'::text, usagemeter_1.date) || '-'::text) || date_part('month'::text, usagemeter_1.date)) || '-01'::text))::date AS date,
            usagemeter_1.product,
            usagemeter_1.client,
            usagemeter_1.count
           FROM invoicexpress.usagemeter usagemeter_1) usagemeter
  GROUP BY date, product, client;


ALTER VIEW invoicexpress.monthlyusage OWNER TO postgres;

--
-- Name: reseller; Type: TABLE; Schema: invoicexpress; Owner: postgres
--

CREATE TABLE invoicexpress.reseller (
    id integer NOT NULL,
    reseller integer,
    accountname character varying(128) NOT NULL,
    apikey character varying(128) NOT NULL,
    active boolean DEFAULT true
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE invoicexpress.reseller OWNER TO postgres;

--
-- Name: reseller_id_seq; Type: SEQUENCE; Schema: invoicexpress; Owner: postgres
--

CREATE SEQUENCE invoicexpress.reseller_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE invoicexpress.reseller_id_seq OWNER TO postgres;

--
-- Name: reseller_id_seq; Type: SEQUENCE OWNED BY; Schema: invoicexpress; Owner: postgres
--

ALTER SEQUENCE invoicexpress.reseller_id_seq OWNED BY invoicexpress.reseller.id;


--
-- Name: domain; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap.domain AS
 SELECT profissional_domains.id,
    profissional_domains.name
   FROM ((public.profissional_domains
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
  WHERE (profissional_domains.active AND profissional_clients.active AND profissional_resellers.active);


ALTER VIEW openldap.domain OWNER TO openldap;

--
-- Name: ldap_attr_mappings; Type: TABLE; Schema: openldap; Owner: openldap
--

CREATE TABLE openldap.ldap_attr_mappings (
    id integer NOT NULL,
    oc_map_id integer NOT NULL,
    name character varying(255) NOT NULL,
    sel_expr character varying(255) NOT NULL,
    sel_expr_u character varying(255),
    from_tbls character varying(255) NOT NULL,
    join_where character varying(255),
    add_proc character varying(255),
    delete_proc character varying(255),
    param_order integer NOT NULL,
    expect_return integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE openldap.ldap_attr_mappings OWNER TO openldap;

--
-- Name: ldap_entries_suffix; Type: TABLE; Schema: openldap; Owner: openldap
--

CREATE TABLE openldap.ldap_entries_suffix (
    id integer,
    dn character varying(255),
    oc_map_id integer,
    parent integer,
    keyval integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE openldap.ldap_entries_suffix OWNER TO openldap;

--
-- Name: ldap_entries_domain; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap.ldap_entries_domain AS
 SELECT ((15 << 59) + profissional_domains.id) AS id,
    ((('ou='::text || (profissional_domains.name)::text) || ','::text) || (( SELECT ldap_entries_suffix.dn
           FROM openldap.ldap_entries_suffix
          WHERE (ldap_entries_suffix.id = 1)))::text) AS dn,
    3 AS oc_map_id,
    1 AS parent,
    profissional_domains.id AS keyval
   FROM ((public.profissional_domains
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
  WHERE (profissional_domains.active AND profissional_clients.active AND profissional_resellers.active);


ALTER VIEW openldap.ldap_entries_domain OWNER TO openldap;

--
-- Name: profissional_email_aliases; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_email_aliases (
    email_id integer NOT NULL,
    maildrop text NOT NULL,
    type character(1) DEFAULT 'a'::bpchar NOT NULL,
    maildrop_array text[],
    tag_subject boolean DEFAULT false,
    maildrop_definition character varying(64) DEFAULT 'own_list'::character varying,
    permitted_senders_definition character varying(64) DEFAULT 'own_list'::character varying,
    maildrop_group_list_array integer[],
    CONSTRAINT fk_profissional_email_aliases_type CHECK ((type = 'a'::bpchar)),
    CONSTRAINT profissional_email_aliases_maildrop_definition_check CHECK (((maildrop_definition)::text = ANY (ARRAY[('own_list'::character varying)::text, ('domain'::character varying)::text, ('group'::character varying)::text, ('group_list'::character varying)::text]))),
    CONSTRAINT profissional_email_aliases_permitted_senders_definition_check CHECK (((permitted_senders_definition)::text = ANY (ARRAY[('own_list'::character varying)::text, ('maildrop'::character varying)::text])))
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_email_aliases OWNER TO horde;

--
-- Name: profissional_email_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_email_users (
    email_id integer NOT NULL,
    password character varying(256) NOT NULL,
    last_access date,
    type character(1) DEFAULT 'u'::bpchar NOT NULL,
    quota integer DEFAULT 10485760 NOT NULL,
    homedir character varying(2048) DEFAULT '-'::character varying NOT NULL,
    creation_time timestamp without time zone DEFAULT now() NOT NULL,
    apikey character varying(255) DEFAULT md5((random())::text) NOT NULL,
    blocked_contents character varying(512),
    mailbox character varying(512) DEFAULT 'maildir:~/maildir'::character varying NOT NULL,
    imapserver character varying(32) DEFAULT '10.1.35.101'::character varying NOT NULL,
    smtpserver character varying(32) DEFAULT 'smtpin:10.1.35.101'::character varying NOT NULL,
    must_change_password boolean DEFAULT false NOT NULL,
    product_id integer NOT NULL,
    pop3_disabled boolean DEFAULT false,
    outbound_volume character varying(32),
    webmail_disabled boolean DEFAULT false,
    CONSTRAINT fk_profissional_email_users_type CHECK ((type = 'u'::bpchar))
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_email_users OWNER TO horde;

--
-- Name: user; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap."user" AS
 SELECT profissional_emails.id,
    profissional_emails.email,
    profissional_domains.id AS domain_id,
    profissional_domains.name AS domain,
    maildrop_user.password
   FROM (((((((((public.profissional_email_aliases
     JOIN public.profissional_emails ON (((profissional_email_aliases.email_id = profissional_emails.id) AND profissional_emails.active)))
     JOIN public.profissional_domains ON (((profissional_emails.parent = profissional_domains.id) AND profissional_domains.active)))
     JOIN public.profissional_clients ON (((profissional_domains.parent = profissional_clients.id) AND profissional_clients.active)))
     JOIN public.profissional_resellers ON (((profissional_clients.parent = profissional_resellers.id) AND profissional_resellers.active)))
     JOIN public.profissional_emails maildrop_email ON (((profissional_email_aliases.maildrop_array[1] = (maildrop_email.email)::text) AND profissional_emails.active)))
     JOIN public.profissional_domains maildrop_domain ON (((maildrop_email.parent = maildrop_domain.id) AND profissional_domains.active)))
     JOIN public.profissional_clients maildrop_client ON (((maildrop_domain.parent = maildrop_client.id) AND profissional_clients.active)))
     JOIN public.profissional_resellers maildrop_reseller ON (((maildrop_client.parent = maildrop_reseller.id) AND profissional_resellers.active)))
     JOIN public.profissional_email_users maildrop_user ON ((maildrop_email.id = maildrop_user.email_id)))
  WHERE (array_length(profissional_email_aliases.maildrop_array, 1) = 1)
UNION
 SELECT profissional_emails.id,
    profissional_emails.email,
    profissional_domains.id AS domain_id,
    profissional_domains.name AS domain,
    profissional_email_users.password
   FROM ((((public.profissional_email_users
     JOIN public.profissional_emails ON (((profissional_email_users.email_id = profissional_emails.id) AND profissional_emails.active)))
     JOIN public.profissional_domains ON (((profissional_emails.parent = profissional_domains.id) AND profissional_domains.active)))
     JOIN public.profissional_clients ON (((profissional_domains.parent = profissional_clients.id) AND profissional_clients.active)))
     JOIN public.profissional_resellers ON (((profissional_clients.parent = profissional_resellers.id) AND profissional_resellers.active)));


ALTER VIEW openldap."user" OWNER TO openldap;

--
-- Name: ldap_entries_user; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap.ldap_entries_user AS
 SELECT ((14 << 59) + id) AS id,
    ((((('mail='::text || (email)::text) || ',ou='::text) || (domain)::text) || ','::text) || (( SELECT ldap_entries_suffix.dn
           FROM openldap.ldap_entries_suffix
          WHERE (ldap_entries_suffix.id = 1)))::text) AS dn,
    2 AS oc_map_id,
    ((15 << 59) + domain_id) AS parent,
    id AS keyval
   FROM openldap."user";


ALTER VIEW openldap.ldap_entries_user OWNER TO openldap;

--
-- Name: ldap_entries; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap.ldap_entries AS
 SELECT ldap_entries_suffix.id,
    ldap_entries_suffix.dn,
    ldap_entries_suffix.oc_map_id,
    ldap_entries_suffix.parent,
    ldap_entries_suffix.keyval
   FROM openldap.ldap_entries_suffix
UNION
 SELECT ldap_entries_domain.id,
    ldap_entries_domain.dn,
    ldap_entries_domain.oc_map_id,
    ldap_entries_domain.parent,
    ldap_entries_domain.keyval
   FROM openldap.ldap_entries_domain
UNION
 SELECT ldap_entries_user.id,
    ldap_entries_user.dn,
    ldap_entries_user.oc_map_id,
    ldap_entries_user.parent,
    ldap_entries_user.keyval
   FROM openldap.ldap_entries_user;


ALTER VIEW openldap.ldap_entries OWNER TO openldap;

--
-- Name: ldap_entry_to_class_map; Type: TABLE; Schema: openldap; Owner: openldap
--

CREATE TABLE openldap.ldap_entry_to_class_map (
    bitmap integer,
    object_class character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE openldap.ldap_entry_to_class_map OWNER TO openldap;

--
-- Name: ldap_entry_objclasses; Type: VIEW; Schema: openldap; Owner: openldap
--

CREATE VIEW openldap.ldap_entry_objclasses AS
 SELECT ldap_entries.id AS entry_id,
    ldap_entry_to_class_map.object_class AS oc_name
   FROM (openldap.ldap_entries
     JOIN openldap.ldap_entry_to_class_map ON (((ldap_entries.id >> 59) = ldap_entry_to_class_map.bitmap)));


ALTER VIEW openldap.ldap_entry_objclasses OWNER TO openldap;

--
-- Name: ldap_oc_mappings; Type: TABLE; Schema: openldap; Owner: openldap
--

CREATE TABLE openldap.ldap_oc_mappings (
    id integer NOT NULL,
    name character varying(64) NOT NULL,
    keytbl character varying(64) NOT NULL,
    keycol character varying(64) NOT NULL,
    create_proc character varying(255),
    delete_proc character varying(255),
    expect_return integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE openldap.ldap_oc_mappings OWNER TO openldap;

--
-- Name: suffix; Type: TABLE; Schema: openldap; Owner: openldap
--

CREATE TABLE openldap.suffix (
    id integer,
    name character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE openldap.suffix OWNER TO openldap;

--
-- Name: active_email; Type: VIEW; Schema: postfix; Owner: horde
--

CREATE VIEW postfix.active_email AS
 SELECT profissional_emails.id,
    profissional_emails.email,
    profissional_emails.parent,
    profissional_emails.active,
    profissional_emails.type,
    profissional_emails.username
   FROM (public.profissional_emails
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
  WHERE (profissional_emails.active AND profissional_domains.active);


ALTER VIEW postfix.active_email OWNER TO horde;

--
-- Name: profissional_email_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_email_groups (
    id integer NOT NULL,
    group_id integer NOT NULL,
    email_id integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_email_groups OWNER TO horde;

--
-- Name: aliases; Type: VIEW; Schema: postfix; Owner: postgres
--

CREATE VIEW postfix.aliases AS
 SELECT profissional_emails.id AS email_id,
    lower((profissional_emails.username)::text) AS alias_username,
    domains.name AS alias_domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS alias_mail,
    unnest(profissional_email_aliases.maildrop_array) AS destination
   FROM ((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
  WHERE (profissional_emails.active AND ((profissional_email_aliases.maildrop_definition)::text = 'own_list'::text))
UNION
 SELECT profissional_emails.id AS email_id,
    lower((profissional_emails.username)::text) AS alias_username,
    domains.name AS alias_domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS alias_mail,
    maildrop_emails.email AS destination
   FROM (((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     LEFT JOIN public.profissional_emails maildrop_emails ON (((maildrop_emails.parent = domains.id) AND (maildrop_emails.type = 'u'::bpchar))))
  WHERE (maildrop_emails.active AND ((profissional_email_aliases.maildrop_definition)::text = 'domain'::text))
UNION
 SELECT profissional_emails.id AS email_id,
    lower((profissional_emails.username)::text) AS alias_username,
    domains.name AS alias_domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS alias_mail,
    maildrop_emails.email AS destination
   FROM (((((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     LEFT JOIN public.profissional_email_groups ON ((profissional_email_groups.email_id = profissional_emails.id)))
     JOIN public.profissional_email_groups maildrop_email_groups ON ((profissional_email_groups.group_id = maildrop_email_groups.group_id)))
     LEFT JOIN public.profissional_emails maildrop_emails ON (((maildrop_email_groups.email_id = maildrop_emails.id) AND (maildrop_emails.type = 'u'::bpchar))))
  WHERE (profissional_emails.active AND ((profissional_email_aliases.maildrop_definition)::text = 'group'::text))
UNION
 SELECT profissional_emails.id AS email_id,
    lower((profissional_emails.username)::text) AS alias_username,
    domains.name AS alias_domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS alias_mail,
    maildrop_emails.email AS destination
   FROM ((((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     JOIN public.profissional_email_groups maildrop_email_groups ON ((maildrop_email_groups.group_id = ANY (profissional_email_aliases.maildrop_group_list_array))))
     LEFT JOIN public.profissional_emails maildrop_emails ON ((maildrop_email_groups.email_id = maildrop_emails.id)))
  WHERE (profissional_emails.active AND ((profissional_email_aliases.maildrop_definition)::text = 'group_list'::text) AND (maildrop_emails.type = 'u'::bpchar));


ALTER VIEW postfix.aliases OWNER TO postgres;

--
-- Name: profissional_domain_filters; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_domain_filters (
    id integer NOT NULL,
    domain_id integer NOT NULL,
    name character varying(1024),
    match_rule text NOT NULL,
    action_rule text NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    php_match_rule text,
    php_action_rule text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_domain_filters OWNER TO postgres;

--
-- Name: domain_filters; Type: VIEW; Schema: postfix; Owner: postgres
--

CREATE VIEW postfix.domain_filters AS
 SELECT profissional_domains.name AS domain,
    profissional_domain_filters.match_rule,
    profissional_domain_filters.action_rule
   FROM (public.profissional_domain_filters
     JOIN public.profissional_domains ON ((profissional_domain_filters.domain_id = profissional_domains.id)))
  ORDER BY profissional_domain_filters.priority;


ALTER VIEW postfix.domain_filters OWNER TO postgres;

--
-- Name: emails; Type: VIEW; Schema: postfix; Owner: horde
--

CREATE VIEW postfix.emails AS
 SELECT profissional_emails.id,
    lower((profissional_emails.username)::text) AS username,
    domains.name AS domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS mail
   FROM (public.profissional_emails
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
  WHERE profissional_emails.active;


ALTER VIEW postfix.emails OWNER TO horde;

--
-- Name: logins; Type: VIEW; Schema: postfix; Owner: postgres
--

CREATE VIEW postfix.logins AS
 SELECT lower((from_email.username)::text) AS auth_user,
    lower(from_domain.name) AS auth_domain,
    lower((((to_email.username)::text || '@'::text) || to_domain.name)) AS username,
    lower(to_domain.name) AS domain,
    to_email_user.password,
    to_email_user.homedir AS home,
    to_email_user.mailbox AS mail,
    to_email_user.imapserver AS host,
    to_email_user.imapserver AS proxy_maybe,
    ('*:storage='::text || (to_email_user.quota)::text) AS quota_rule,
    to_email_user.must_change_password
   FROM (((((public.profissional_email_aliases
     JOIN public.profissional_emails from_email ON ((from_email.id = profissional_email_aliases.email_id)))
     JOIN postfix.domains from_domain ON ((from_email.parent = from_domain.id)))
     JOIN public.profissional_emails to_email ON (((to_email.email)::text = profissional_email_aliases.maildrop_array[1])))
     JOIN public.profissional_email_users to_email_user ON ((to_email.id = to_email_user.email_id)))
     JOIN postfix.domains to_domain ON ((to_domain.id = to_email.parent)))
  WHERE (((from_domain.active = true) OR (from_domain.migrating = true)) AND ((to_domain.active = true) OR (to_domain.migrating = true)) AND from_email.active AND to_email.active AND (array_length(profissional_email_aliases.maildrop_array, 1) = 1))
UNION
 SELECT lower((email.username)::text) AS auth_user,
    lower(domain.name) AS auth_domain,
    lower((((email.username)::text || '@'::text) || domain.name)) AS username,
    lower(domain.name) AS domain,
    email_user.password,
    email_user.homedir AS home,
    email_user.mailbox AS mail,
    email_user.imapserver AS host,
    email_user.imapserver AS proxy_maybe,
    ('*:storage='::text || (email_user.quota)::text) AS quota_rule,
    email_user.must_change_password
   FROM ((postfix.domains domain
     JOIN public.profissional_emails email ON (((domain.id = email.parent) AND email.active)))
     JOIN public.profissional_email_users email_user ON ((email.id = email_user.email_id)))
  WHERE (((domain.active = true) OR (domain.migrating = true)) AND email.active);


ALTER VIEW postfix.logins OWNER TO postgres;

--
-- Name: recursive_aliases_base; Type: VIEW; Schema: postfix; Owner: postgres
--

CREATE VIEW postfix.recursive_aliases_base AS
 SELECT profissional_emails.id AS source_alias_id,
    maildrop_emails.id AS destination_alias_id
   FROM (((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     LEFT JOIN public.profissional_emails maildrop_emails ON ((maildrop_emails.parent = domains.id)))
  WHERE (maildrop_emails.active AND (maildrop_emails.type = 'a'::bpchar) AND ((profissional_email_aliases.maildrop_definition)::text = 'domain'::text))
UNION
 SELECT profissional_emails.id AS source_alias_id,
    maildrop_emails.id AS destination_alias_id
   FROM (((((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     LEFT JOIN public.profissional_email_groups ON ((profissional_email_groups.email_id = profissional_emails.id)))
     JOIN public.profissional_email_groups maildrop_email_groups ON ((profissional_email_groups.group_id = maildrop_email_groups.group_id)))
     JOIN public.profissional_emails maildrop_emails ON ((maildrop_email_groups.email_id = maildrop_emails.id)))
  WHERE (profissional_emails.active AND (maildrop_emails.type = 'a'::bpchar) AND ((profissional_email_aliases.maildrop_definition)::text = 'group'::text))
UNION
 SELECT profissional_emails.id AS source_alias_id,
    maildrop_emails.id AS destination_alias_id
   FROM ((((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
     JOIN public.profissional_email_groups maildrop_email_groups ON ((maildrop_email_groups.group_id = ANY (profissional_email_aliases.maildrop_group_list_array))))
     JOIN public.profissional_emails maildrop_emails ON ((maildrop_email_groups.email_id = maildrop_emails.id)))
  WHERE (profissional_emails.active AND (maildrop_emails.type = 'a'::bpchar) AND ((profissional_email_aliases.maildrop_definition)::text = 'group_list'::text));


ALTER VIEW postfix.recursive_aliases_base OWNER TO postgres;

--
-- Name: recursive_aliases; Type: MATERIALIZED VIEW; Schema: postfix; Owner: postgres
--

CREATE MATERIALIZED VIEW postfix.recursive_aliases AS
 WITH RECURSIVE r_alias AS (
         SELECT aliases.email_id AS source_alias_id,
            aliases.email_id AS destination_alias_id
           FROM postfix.aliases
        UNION
         SELECT r_alias_1.source_alias_id,
            recursive_aliases_base.destination_alias_id
           FROM (r_alias r_alias_1
             JOIN postfix.recursive_aliases_base ON ((r_alias_1.destination_alias_id = recursive_aliases_base.source_alias_id)))
        )
 SELECT DISTINCT source.id AS email_id,
    source.username AS alias_username,
    source_domain.name AS alias_domain,
    source.email AS alias_mail,
    destination.destination
   FROM ((((r_alias
     JOIN public.profissional_emails source ON ((r_alias.source_alias_id = source.id)))
     JOIN public.profissional_domains source_domain ON ((source.parent = source_domain.id)))
     JOIN postfix.aliases destination ON ((r_alias.destination_alias_id = destination.email_id)))
     JOIN public.profissional_emails destination_type ON ((((destination_type.email)::text = destination.destination) AND (destination_type.type = 'u'::bpchar))))
  WHERE (destination.destination IS NOT NULL)
  WITH NO DATA;


ALTER MATERIALIZED VIEW postfix.recursive_aliases OWNER TO postgres;

--
-- Name: timestamp_queue; Type: TABLE; Schema: postfix; Owner: postgres
--

CREATE TABLE postfix.timestamp_queue (
    id integer NOT NULL,
    sent_ts timestamp without time zone DEFAULT now(),
    smtp_server character varying(255),
    queue_id character varying(255),
    mail_from text,
    rcpt_to text,
    subject text,
    smtp_result text,
    smtp_log text
);


ALTER TABLE postfix.timestamp_queue OWNER TO postgres;

--
-- Name: timestamp_queue_id_seq; Type: SEQUENCE; Schema: postfix; Owner: postgres
--

CREATE SEQUENCE postfix.timestamp_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE postfix.timestamp_queue_id_seq OWNER TO postgres;

--
-- Name: timestamp_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: postfix; Owner: postgres
--

ALTER SEQUENCE postfix.timestamp_queue_id_seq OWNED BY postfix.timestamp_queue.id;


--
-- Name: users; Type: VIEW; Schema: postfix; Owner: postgres
--

CREATE VIEW postfix.users AS
 SELECT profissional_emails.id AS email_id,
    lower((profissional_emails.username)::text) AS username,
    domains.name AS domain,
    lower((((profissional_emails.username)::text || '@'::text) || domains.name)) AS mail,
    profissional_email_users.password,
    profissional_email_users.quota,
    profissional_email_users.homedir,
    profissional_email_users.blocked_contents,
    profissional_email_users.mailbox,
    profissional_email_users.imapserver,
    profissional_email_users.smtpserver,
    domains.migrating
   FROM ((public.profissional_email_users
     JOIN public.profissional_emails ON ((profissional_emails.id = profissional_email_users.email_id)))
     JOIN postfix.domains ON ((profissional_emails.parent = domains.id)))
  WHERE profissional_emails.active;


ALTER VIEW postfix.users OWNER TO postgres;

--
-- Name: smtp_bind_address; Type: TABLE; Schema: postfix_submission; Owner: postfix
--

CREATE TABLE postfix_submission.smtp_bind_address (
    id integer NOT NULL,
    domain text NOT NULL,
    transport character varying(128),
    required_ip character varying(15)
);


ALTER TABLE postfix_submission.smtp_bind_address OWNER TO postfix;

--
-- Name: smtp_bind_address_id_seq; Type: SEQUENCE; Schema: postfix_submission; Owner: postfix
--

CREATE SEQUENCE postfix_submission.smtp_bind_address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE postfix_submission.smtp_bind_address_id_seq OWNER TO postfix;

--
-- Name: smtp_bind_address_id_seq; Type: SEQUENCE OWNED BY; Schema: postfix_submission; Owner: postfix
--

ALTER SEQUENCE postfix_submission.smtp_bind_address_id_seq OWNED BY postfix_submission.smtp_bind_address.id;


--
-- Name: profissional_client_softsuspend; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_client_softsuspend (
    id integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_client_softsuspend OWNER TO postgres;

--
-- Name: smtpd_sender_restrictions; Type: VIEW; Schema: postfix_submission; Owner: postfix
--

CREATE VIEW postfix_submission.smtpd_sender_restrictions AS
 SELECT
        CASE
            WHEN (NOT profissional_resellers.active) THEN 'REJECT Sender email reseller inactive'::text
            WHEN (NOT profissional_clients.active) THEN 'REJECT Sender email customer inactive'::text
            WHEN (profissional_client_softsuspend.id IS NOT NULL) THEN 'REJECT Sender customer administratively suspended. Contact billing support.'::text
            WHEN (NOT profissional_domains.active) THEN 'REJECT Sender email domain inactive'::text
            WHEN (NOT profissional_emails.active) THEN 'REJECT Sender email account inactive'::text
            ELSE 'DUNNO'::text
        END AS result,
    profissional_emails.email,
    profissional_domains.name AS domain
   FROM ((((public.profissional_emails
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
     LEFT JOIN public.profissional_client_softsuspend ON ((profissional_clients.id = profissional_client_softsuspend.id)));


ALTER VIEW postfix_submission.smtpd_sender_restrictions OWNER TO postfix;

--
-- Name: smtpd_sender_restrictions_v2; Type: VIEW; Schema: postfix_submission; Owner: postgres
--

CREATE VIEW postfix_submission.smtpd_sender_restrictions_v2 AS
 SELECT
        CASE
            WHEN (NOT profissional_resellers.active) THEN 'REJECT Sender email reseller inactive'::text
            WHEN (NOT profissional_clients.active) THEN 'REJECT Sender email customer inactive'::text
            WHEN (profissional_client_softsuspend.id IS NOT NULL) THEN 'REJECT Sender customer administratively suspended. Contact billing support.'::text
            WHEN (NOT profissional_domains.active) THEN 'REJECT Sender email domain inactive'::text
            WHEN (NOT profissional_emails.active) THEN 'REJECT Sender email account inactive'::text
            ELSE 'DUNNO'::text
        END AS result,
    profissional_emails.username,
    profissional_domains.name AS domain
   FROM ((((public.profissional_emails
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
     LEFT JOIN public.profissional_client_softsuspend ON ((profissional_clients.id = profissional_client_softsuspend.id)))
UNION
 SELECT
        CASE
            WHEN (NOT profissional_resellers.active) THEN 'REJECT Sender email reseller inactive'::text
            WHEN (NOT profissional_clients.active) THEN 'REJECT Sender email customer inactive'::text
            WHEN (profissional_client_softsuspend.id IS NOT NULL) THEN 'REJECT Sender customer administratively suspended. Contact billing support.'::text
            WHEN (NOT profissional_domains.active) THEN 'REJECT Sender email domain inactive'::text
            WHEN (NOT profissional_emails.active) THEN 'REJECT Sender email account inactive'::text
            ELSE 'DUNNO'::text
        END AS result,
    profissional_emails.username,
    profissional_domain_aliases.name AS domain
   FROM (((((public.profissional_emails
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
     JOIN public.profissional_domain_aliases ON (((profissional_domains.id = profissional_domain_aliases.parent) AND (true = profissional_domain_aliases.active))))
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
     LEFT JOIN public.profissional_client_softsuspend ON ((profissional_clients.id = profissional_client_softsuspend.id)));


ALTER VIEW postfix_submission.smtpd_sender_restrictions_v2 OWNER TO postgres;

--
-- Name: profissional_domain_secondary_target; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_domain_secondary_target (
    id integer NOT NULL,
    target text NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_domain_secondary_target OWNER TO postgres;

--
-- Name: transport_maps; Type: VIEW; Schema: postfix_submission; Owner: postfix
--

CREATE VIEW postfix_submission.transport_maps AS
 SELECT (('lmtp:inet:'::text || (profissional_email_users.imapserver)::text) || ':2525'::text) AS result,
    1 AS priority,
    NULL::character varying AS required_ip,
    profissional_emails.email,
    profissional_domains.name AS domain
   FROM (((((public.profissional_email_users
     JOIN public.profissional_emails ON ((profissional_email_users.email_id = profissional_emails.id)))
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
     LEFT JOIN public.profissional_domain_secondary_target ON ((profissional_domains.id = profissional_domain_secondary_target.id)))
  WHERE (profissional_emails.active AND profissional_domains.active AND (NOT profissional_domains.migrating) AND profissional_clients.active AND profissional_resellers.active AND (profissional_domain_secondary_target.id IS NULL))
UNION
 SELECT 'smtp_aliasmx:10.3.8.13:10026'::text AS result,
    2 AS priority,
    NULL::character varying AS required_ip,
    profissional_emails.email,
    profissional_domains.name AS domain
   FROM (((((public.profissional_email_aliases
     JOIN public.profissional_emails ON ((profissional_email_aliases.email_id = profissional_emails.id)))
     JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
     JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
     JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
     LEFT JOIN public.profissional_domain_secondary_target ON ((profissional_domains.id = profissional_domain_secondary_target.id)))
  WHERE (profissional_emails.active AND profissional_domains.active AND (NOT profissional_domains.migrating) AND profissional_clients.active AND profissional_resellers.active AND (profissional_domain_secondary_target.id IS NULL))
UNION
 SELECT smtp_bind_address.transport AS result,
    3 AS priority,
    smtp_bind_address.required_ip,
    NULL::character varying AS email,
    smtp_bind_address.domain
   FROM postfix_submission.smtp_bind_address;


ALTER VIEW postfix_submission.transport_maps OWNER TO postfix;

--
-- Name: content_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.content_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.content_schema_info OWNER TO horde;

--
-- Name: domain_filters; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.domain_filters AS
 SELECT profissional_domains.name AS domain,
    profissional_domain_filters.match_rule,
    profissional_domain_filters.action_rule
   FROM (public.profissional_domain_filters
     JOIN public.profissional_domains ON ((profissional_domain_filters.domain_id = profissional_domains.id)))
  ORDER BY profissional_domain_filters.priority;


ALTER VIEW public.domain_filters OWNER TO postgres;

--
-- Name: horde_activesync_cache; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_cache (
    cache_devid character varying(255),
    cache_user character varying(255),
    cache_data text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_cache OWNER TO postgres;

--
-- Name: horde_activesync_device; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_device (
    device_id character varying(255) NOT NULL,
    device_type character varying(255) NOT NULL,
    device_agent character varying(255) NOT NULL,
    device_supported text,
    device_policykey bigint DEFAULT 0,
    device_rwstatus integer,
    device_properties text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_device OWNER TO postgres;

--
-- Name: horde_activesync_device_users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_device_users (
    device_id character varying(255) NOT NULL,
    device_user character varying(255) NOT NULL,
    device_policykey bigint DEFAULT 0
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_device_users OWNER TO postgres;

--
-- Name: horde_activesync_mailmap; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_mailmap (
    message_uid integer DEFAULT 0 NOT NULL,
    sync_key character varying(255) NOT NULL,
    sync_devid character varying(255) NOT NULL,
    sync_folderid character varying(255) NOT NULL,
    sync_user character varying(255) NOT NULL,
    sync_read boolean,
    sync_deleted boolean,
    sync_flagged boolean,
    sync_changed boolean,
    sync_category character varying(255),
    sync_draft boolean
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_mailmap OWNER TO postgres;

--
-- Name: horde_activesync_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_map (
    message_uid character varying(255) NOT NULL,
    sync_modtime integer,
    sync_key character varying(255) NOT NULL,
    sync_devid character varying(255) NOT NULL,
    sync_folderid character varying(255) NOT NULL,
    sync_user character varying(255),
    sync_clientid character varying(255),
    sync_deleted boolean
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_map OWNER TO postgres;

--
-- Name: horde_activesync_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_activesync_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_schema_info OWNER TO horde;

--
-- Name: horde_activesync_state; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horde_activesync_state (
    sync_mod integer,
    sync_key character varying(255) NOT NULL,
    sync_devid character varying(255),
    sync_folderid character varying(255),
    sync_user character varying(255),
    sync_data bytea,
    sync_pending text,
    sync_timestamp integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_activesync_state OWNER TO postgres;

--
-- Name: horde_alarm_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_alarm_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_alarm_schema_info OWNER TO horde;

--
-- Name: horde_alarms; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_alarms (
    id integer NOT NULL,
    alarm_id character varying(255) NOT NULL,
    alarm_uid character varying(255),
    alarm_start timestamp without time zone NOT NULL,
    alarm_end timestamp without time zone,
    alarm_methods character varying(255),
    alarm_params text,
    alarm_title character varying(255) NOT NULL,
    alarm_text text,
    alarm_snooze timestamp without time zone,
    alarm_dismissed smallint DEFAULT 0 NOT NULL,
    alarm_internal text,
    alarm_instanceid character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_alarms OWNER TO horde;

--
-- Name: horde_alarms_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_alarms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_alarms_id_seq OWNER TO horde;

--
-- Name: horde_alarms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_alarms_id_seq OWNED BY public.horde_alarms.id;


--
-- Name: horde_auth_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_auth_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_auth_schema_info OWNER TO horde;

--
-- Name: horde_cache; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_cache (
    cache_id character varying(32) NOT NULL,
    cache_timestamp bigint NOT NULL,
    cache_expiration bigint NOT NULL,
    cache_data bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_cache OWNER TO horde;

--
-- Name: horde_cache_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_cache_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_cache_schema_info OWNER TO horde;

--
-- Name: horde_core_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_core_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_core_schema_info OWNER TO horde;

--
-- Name: horde_dav_collections; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_dav_collections (
    id_interface character varying(255) NOT NULL,
    id_internal character varying(255) NOT NULL,
    id_external character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_dav_collections OWNER TO horde;

--
-- Name: horde_dav_objects; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_dav_objects (
    id_collection character varying(255) NOT NULL,
    id_internal character varying(255) NOT NULL,
    id_external character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_dav_objects OWNER TO horde;

--
-- Name: horde_dav_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_dav_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_dav_schema_info OWNER TO horde;

--
-- Name: horde_group_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_group_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_group_schema_info OWNER TO horde;

--
-- Name: horde_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_groups (
    group_uid integer NOT NULL,
    group_name character varying(255) NOT NULL,
    group_parents character varying(255) NOT NULL,
    group_email character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_groups OWNER TO horde;

--
-- Name: horde_groups_group_uid_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_groups_group_uid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_groups_group_uid_seq OWNER TO horde;

--
-- Name: horde_groups_group_uid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_groups_group_uid_seq OWNED BY public.horde_groups.group_uid;


--
-- Name: horde_groups_members; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_groups_members (
    group_uid integer NOT NULL,
    user_uid character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_groups_members OWNER TO horde;

--
-- Name: horde_histories; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_histories (
    history_id integer NOT NULL,
    object_uid character varying(255) NOT NULL,
    history_action character varying(32) NOT NULL,
    history_ts bigint NOT NULL,
    history_desc text,
    history_who character varying(255),
    history_extra text,
    history_modseq integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_histories OWNER TO horde;

--
-- Name: horde_histories_history_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_histories_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_histories_history_id_seq OWNER TO horde;

--
-- Name: horde_histories_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_histories_history_id_seq OWNED BY public.horde_histories.history_id;


--
-- Name: horde_histories_modseq; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_histories_modseq (
    history_modseq integer NOT NULL,
    history_modseqempty integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_histories_modseq OWNER TO horde;

--
-- Name: horde_histories_modseq_history_modseq_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_histories_modseq_history_modseq_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_histories_modseq_history_modseq_seq OWNER TO horde;

--
-- Name: horde_histories_modseq_history_modseq_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_histories_modseq_history_modseq_seq OWNED BY public.horde_histories_modseq.history_modseq;


--
-- Name: horde_history_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_history_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_history_schema_info OWNER TO horde;

--
-- Name: horde_imap_client_data; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_imap_client_data (
    messageid integer NOT NULL,
    hostspec character varying(255) NOT NULL,
    mailbox character varying(255) NOT NULL,
    modified bigint,
    port integer NOT NULL,
    username character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_imap_client_data OWNER TO horde;

--
-- Name: horde_imap_client_data_messageid_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_imap_client_data_messageid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_imap_client_data_messageid_seq OWNER TO horde;

--
-- Name: horde_imap_client_data_messageid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_imap_client_data_messageid_seq OWNED BY public.horde_imap_client_data.messageid;


--
-- Name: horde_imap_client_message; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_imap_client_message (
    data bytea,
    msguid character varying(255) NOT NULL,
    messageid bigint NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_imap_client_message OWNER TO horde;

--
-- Name: horde_imap_client_metadata; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_imap_client_metadata (
    data bytea,
    field character varying(255) NOT NULL,
    messageid bigint NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_imap_client_metadata OWNER TO horde;

--
-- Name: horde_imap_client_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_imap_client_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_imap_client_schema_info OWNER TO horde;

--
-- Name: horde_lock_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_lock_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_lock_schema_info OWNER TO horde;

--
-- Name: horde_locks; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_locks (
    lock_id character varying(36) NOT NULL,
    lock_owner character varying(255) NOT NULL,
    lock_scope character varying(32) NOT NULL,
    lock_principal character varying(255) NOT NULL,
    lock_origin_timestamp bigint NOT NULL,
    lock_update_timestamp bigint NOT NULL,
    lock_expiry_timestamp bigint NOT NULL,
    lock_type smallint NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_locks OWNER TO horde;

--
-- Name: horde_muvfs; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_muvfs (
    vfs_id integer NOT NULL,
    vfs_type smallint NOT NULL,
    vfs_path character varying(255),
    vfs_name character varying(255) NOT NULL,
    vfs_modified bigint NOT NULL,
    vfs_owner character varying(255),
    vfs_perms smallint NOT NULL,
    vfs_data bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_muvfs OWNER TO horde;

--
-- Name: horde_muvfs_vfs_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_muvfs_vfs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_muvfs_vfs_id_seq OWNER TO horde;

--
-- Name: horde_muvfs_vfs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_muvfs_vfs_id_seq OWNED BY public.horde_muvfs.vfs_id;


--
-- Name: horde_perms; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_perms (
    perm_id integer NOT NULL,
    perm_name character varying(255) NOT NULL,
    perm_parents character varying(255),
    perm_data text
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_perms OWNER TO horde;

--
-- Name: horde_perms_perm_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_perms_perm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_perms_perm_id_seq OWNER TO horde;

--
-- Name: horde_perms_perm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_perms_perm_id_seq OWNED BY public.horde_perms.perm_id;


--
-- Name: horde_perms_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_perms_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_perms_schema_info OWNER TO horde;

--
-- Name: horde_prefs; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_prefs (
    pref_uid character varying(255) NOT NULL,
    pref_scope character varying(16) DEFAULT ''::character varying NOT NULL,
    pref_name character varying(32) NOT NULL,
    pref_value bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_prefs OWNER TO horde;

--
-- Name: horde_prefs_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_prefs_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_prefs_schema_info OWNER TO horde;

--
-- Name: horde_queue_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_queue_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_queue_schema_info OWNER TO horde;

--
-- Name: horde_queue_tasks; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_queue_tasks (
    task_id integer NOT NULL,
    task_queue character varying(255) NOT NULL,
    task_fields text NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_queue_tasks OWNER TO horde;

--
-- Name: horde_queue_tasks_task_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_queue_tasks_task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_queue_tasks_task_id_seq OWNER TO horde;

--
-- Name: horde_queue_tasks_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_queue_tasks_task_id_seq OWNED BY public.horde_queue_tasks.task_id;


--
-- Name: horde_sessionhandler; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_sessionhandler (
    session_id character varying(32) NOT NULL,
    session_lastmodified integer NOT NULL,
    session_data bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_sessionhandler OWNER TO horde;

--
-- Name: horde_sessionhandler_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_sessionhandler_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_sessionhandler_schema_info OWNER TO horde;

--
-- Name: horde_signups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_signups (
    user_name character varying(255) NOT NULL,
    signup_date integer NOT NULL,
    signup_host character varying(255) NOT NULL,
    signup_data text NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_signups OWNER TO horde;

--
-- Name: horde_syncml_anchors; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_syncml_anchors (
    syncml_syncpartner character varying(255) NOT NULL,
    syncml_db character varying(255) NOT NULL,
    syncml_uid character varying(255) NOT NULL,
    syncml_clientanchor character varying(255),
    syncml_serveranchor character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_syncml_anchors OWNER TO horde;

--
-- Name: horde_syncml_map; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_syncml_map (
    syncml_syncpartner character varying(255) NOT NULL,
    syncml_db character varying(255) NOT NULL,
    syncml_uid character varying(255) NOT NULL,
    syncml_cuid character varying(255),
    syncml_suid character varying(255),
    syncml_timestamp integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_syncml_map OWNER TO horde;

--
-- Name: horde_syncml_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_syncml_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_syncml_schema_info OWNER TO horde;

--
-- Name: horde_token_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_token_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_token_schema_info OWNER TO horde;

--
-- Name: horde_tokens; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_tokens (
    token_address character varying(100) NOT NULL,
    token_id character varying(32) NOT NULL,
    token_timestamp bigint NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_tokens OWNER TO horde;

--
-- Name: horde_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_users (
    user_uid character varying(255) NOT NULL,
    user_pass character varying(255) NOT NULL,
    user_soft_expiration_date integer,
    user_hard_expiration_date integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_users OWNER TO horde;

--
-- Name: horde_vfs; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_vfs (
    vfs_id integer NOT NULL,
    vfs_type smallint NOT NULL,
    vfs_path character varying(255),
    vfs_name character varying(255) NOT NULL,
    vfs_modified bigint NOT NULL,
    vfs_owner character varying(255),
    vfs_data bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_vfs OWNER TO horde;

--
-- Name: horde_vfs_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.horde_vfs_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.horde_vfs_schema_info OWNER TO horde;

--
-- Name: horde_vfs_vfs_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.horde_vfs_vfs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horde_vfs_vfs_id_seq OWNER TO horde;

--
-- Name: horde_vfs_vfs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.horde_vfs_vfs_id_seq OWNED BY public.horde_vfs.vfs_id;


--
-- Name: imp_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.imp_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.imp_schema_info OWNER TO horde;

--
-- Name: imp_sentmail; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.imp_sentmail (
    sentmail_id integer NOT NULL,
    sentmail_who character varying(255) NOT NULL,
    sentmail_ts bigint NOT NULL,
    sentmail_messageid character varying(255) NOT NULL,
    sentmail_action character varying(32) NOT NULL,
    sentmail_recipient character varying(255) NOT NULL,
    sentmail_success integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.imp_sentmail OWNER TO horde;

--
-- Name: imp_sentmail_sentmail_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.imp_sentmail_sentmail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.imp_sentmail_sentmail_id_seq OWNER TO horde;

--
-- Name: imp_sentmail_sentmail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.imp_sentmail_sentmail_id_seq OWNED BY public.imp_sentmail.sentmail_id;


--
-- Name: ingo_forwards; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_forwards (
    forward_owner character varying(255) NOT NULL,
    forward_addresses text,
    forward_keep integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_forwards OWNER TO horde;

--
-- Name: ingo_lists; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_lists (
    list_owner character varying(255) NOT NULL,
    list_blacklist integer DEFAULT 0,
    list_address character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_lists OWNER TO horde;

--
-- Name: ingo_rules; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_rules (
    rule_id integer NOT NULL,
    rule_owner character varying(255) NOT NULL,
    rule_name character varying(255) NOT NULL,
    rule_action integer NOT NULL,
    rule_value character varying(255),
    rule_flags integer,
    rule_conditions text,
    rule_combine integer,
    rule_stop integer,
    rule_active integer DEFAULT 1 NOT NULL,
    rule_order integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_rules OWNER TO horde;

--
-- Name: ingo_rules_rule_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.ingo_rules_rule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingo_rules_rule_id_seq OWNER TO horde;

--
-- Name: ingo_rules_rule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.ingo_rules_rule_id_seq OWNED BY public.ingo_rules.rule_id;


--
-- Name: ingo_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_schema_info OWNER TO horde;

--
-- Name: ingo_shares; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_shares (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255) NOT NULL,
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator integer DEFAULT 0 NOT NULL,
    perm_default integer DEFAULT 0 NOT NULL,
    perm_guest integer DEFAULT 0 NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc character varying(255),
    share_parents character varying(4000)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_shares OWNER TO horde;

--
-- Name: ingo_shares_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_shares_groups (
    id integer NOT NULL,
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_shares_groups OWNER TO horde;

--
-- Name: ingo_shares_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.ingo_shares_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingo_shares_groups_id_seq OWNER TO horde;

--
-- Name: ingo_shares_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.ingo_shares_groups_id_seq OWNED BY public.ingo_shares_groups.id;


--
-- Name: ingo_shares_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.ingo_shares_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingo_shares_share_id_seq OWNER TO horde;

--
-- Name: ingo_shares_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.ingo_shares_share_id_seq OWNED BY public.ingo_shares.share_id;


--
-- Name: ingo_shares_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_shares_users (
    id integer NOT NULL,
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_shares_users OWNER TO horde;

--
-- Name: ingo_shares_users_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.ingo_shares_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingo_shares_users_id_seq OWNER TO horde;

--
-- Name: ingo_shares_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.ingo_shares_users_id_seq OWNED BY public.ingo_shares_users.id;


--
-- Name: ingo_sharesng; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_sharesng (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255),
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator_2 boolean DEFAULT false NOT NULL,
    perm_creator_4 boolean DEFAULT false NOT NULL,
    perm_creator_8 boolean DEFAULT false NOT NULL,
    perm_creator_16 boolean DEFAULT false NOT NULL,
    perm_default_2 boolean DEFAULT false NOT NULL,
    perm_default_4 boolean DEFAULT false NOT NULL,
    perm_default_8 boolean DEFAULT false NOT NULL,
    perm_default_16 boolean DEFAULT false NOT NULL,
    perm_guest_2 boolean DEFAULT false NOT NULL,
    perm_guest_4 boolean DEFAULT false NOT NULL,
    perm_guest_8 boolean DEFAULT false NOT NULL,
    perm_guest_16 boolean DEFAULT false NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc character varying(255),
    share_parents character varying(4000)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_sharesng OWNER TO horde;

--
-- Name: ingo_sharesng_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_sharesng_groups (
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_sharesng_groups OWNER TO horde;

--
-- Name: ingo_sharesng_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.ingo_sharesng_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ingo_sharesng_share_id_seq OWNER TO horde;

--
-- Name: ingo_sharesng_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.ingo_sharesng_share_id_seq OWNED BY public.ingo_sharesng.share_id;


--
-- Name: ingo_sharesng_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_sharesng_users (
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_sharesng_users OWNER TO horde;

--
-- Name: ingo_spam; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_spam (
    spam_owner character varying(255) NOT NULL,
    spam_level integer DEFAULT 5,
    spam_folder character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_spam OWNER TO horde;

--
-- Name: ingo_vacations; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.ingo_vacations (
    vacation_owner character varying(255) NOT NULL,
    vacation_addresses text,
    vacation_subject character varying(255),
    vacation_reason text,
    vacation_days integer DEFAULT 7,
    vacation_start integer,
    vacation_end integer,
    vacation_excludes text,
    vacation_ignorelists integer DEFAULT 1
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.ingo_vacations OWNER TO horde;

--
-- Name: kronolith_events; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_events (
    event_id character varying(32) NOT NULL,
    event_uid character varying(255) NOT NULL,
    calendar_id character varying(255) NOT NULL,
    event_creator_id character varying(255) NOT NULL,
    event_description text,
    event_location text,
    event_status integer DEFAULT 0,
    event_attendees text,
    event_keywords text,
    event_exceptions text,
    event_title character varying(255),
    event_recurtype integer DEFAULT 0,
    event_recurinterval integer,
    event_recurdays integer,
    event_recurenddate timestamp without time zone,
    event_recurcount integer,
    event_start timestamp without time zone,
    event_end timestamp without time zone,
    event_alarm integer DEFAULT 0,
    event_modified integer DEFAULT 0,
    event_private integer DEFAULT 0 NOT NULL,
    event_allday integer DEFAULT 0,
    event_alarm_methods text,
    event_url text,
    event_baseid character varying(255) DEFAULT ''::character varying,
    event_exceptionoriginaldate timestamp without time zone,
    event_resources text,
    event_timezone character varying(50),
    event_organizer character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_events OWNER TO horde;

--
-- Name: kronolith_events_geo; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_events_geo (
    event_id character varying(32) NOT NULL,
    event_lat character varying(32) NOT NULL,
    event_lon character varying(32) NOT NULL,
    event_zoom integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_events_geo OWNER TO horde;

--
-- Name: kronolith_resources; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_resources (
    resource_id integer NOT NULL,
    resource_name character varying(255),
    resource_calendar character varying(255),
    resource_description text,
    resource_response_type integer DEFAULT 0,
    resource_type character varying(255) NOT NULL,
    resource_members text,
    resource_email character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_resources OWNER TO horde;

--
-- Name: kronolith_resources_resource_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_resources_resource_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_resources_resource_id_seq OWNER TO horde;

--
-- Name: kronolith_resources_resource_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_resources_resource_id_seq OWNED BY public.kronolith_resources.resource_id;


--
-- Name: kronolith_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_schema_info OWNER TO horde;

--
-- Name: kronolith_shares; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_shares (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255) NOT NULL,
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator integer DEFAULT 0 NOT NULL,
    perm_default integer DEFAULT 0 NOT NULL,
    perm_guest integer DEFAULT 0 NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc text,
    attribute_color character varying(7),
    share_parents character varying(4000),
    attribute_email text,
    attribute_members text,
    attribute_response_type integer,
    attribute_calendar_type integer DEFAULT 1,
    attribute_isgroup integer DEFAULT 0
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_shares OWNER TO horde;

--
-- Name: kronolith_shares_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_shares_groups (
    id integer NOT NULL,
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_shares_groups OWNER TO horde;

--
-- Name: kronolith_shares_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_shares_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_shares_groups_id_seq OWNER TO horde;

--
-- Name: kronolith_shares_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_shares_groups_id_seq OWNED BY public.kronolith_shares_groups.id;


--
-- Name: kronolith_shares_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_shares_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_shares_share_id_seq OWNER TO horde;

--
-- Name: kronolith_shares_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_shares_share_id_seq OWNED BY public.kronolith_shares.share_id;


--
-- Name: kronolith_shares_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_shares_users (
    id integer NOT NULL,
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_shares_users OWNER TO horde;

--
-- Name: kronolith_shares_users_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_shares_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_shares_users_id_seq OWNER TO horde;

--
-- Name: kronolith_shares_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_shares_users_id_seq OWNED BY public.kronolith_shares_users.id;


--
-- Name: kronolith_sharesng; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_sharesng (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255),
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator_2 boolean DEFAULT false NOT NULL,
    perm_creator_4 boolean DEFAULT false NOT NULL,
    perm_creator_8 boolean DEFAULT false NOT NULL,
    perm_creator_16 boolean DEFAULT false NOT NULL,
    perm_creator_1024 boolean DEFAULT false NOT NULL,
    perm_default_2 boolean DEFAULT false NOT NULL,
    perm_default_4 boolean DEFAULT false NOT NULL,
    perm_default_8 boolean DEFAULT false NOT NULL,
    perm_default_16 boolean DEFAULT false NOT NULL,
    perm_default_1024 boolean DEFAULT false NOT NULL,
    perm_guest_2 boolean DEFAULT false NOT NULL,
    perm_guest_4 boolean DEFAULT false NOT NULL,
    perm_guest_8 boolean DEFAULT false NOT NULL,
    perm_guest_16 boolean DEFAULT false NOT NULL,
    perm_guest_1024 boolean DEFAULT false NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc text,
    attribute_color character varying(7),
    share_parents character varying(4000),
    attribute_email text,
    attribute_members text,
    attribute_response_type integer,
    attribute_calendar_type integer DEFAULT 1,
    attribute_isgroup integer DEFAULT 0
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_sharesng OWNER TO horde;

--
-- Name: kronolith_sharesng_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_sharesng_groups (
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL,
    perm_1024 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_sharesng_groups OWNER TO horde;

--
-- Name: kronolith_sharesng_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_sharesng_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_sharesng_share_id_seq OWNER TO horde;

--
-- Name: kronolith_sharesng_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_sharesng_share_id_seq OWNED BY public.kronolith_sharesng.share_id;


--
-- Name: kronolith_sharesng_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_sharesng_users (
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL,
    perm_1024 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_sharesng_users OWNER TO horde;

--
-- Name: kronolith_storage; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.kronolith_storage (
    id integer NOT NULL,
    vfb_owner character varying(255),
    vfb_email character varying(255) NOT NULL,
    vfb_serialized text NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.kronolith_storage OWNER TO horde;

--
-- Name: kronolith_storage_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.kronolith_storage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kronolith_storage_id_seq OWNER TO horde;

--
-- Name: kronolith_storage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.kronolith_storage_id_seq OWNED BY public.kronolith_storage.id;


--
-- Name: novis_username_map; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.novis_username_map (
    username character varying(255) NOT NULL,
    email character varying(255),
    email_username character varying(255),
    email_domain character varying(255)
);


ALTER TABLE public.novis_username_map OWNER TO postgres;

--
-- Name: oa_migration; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.oa_migration (
    email text NOT NULL,
    host text NOT NULL,
    path text NOT NULL,
    last_sync timestamp without time zone
);


ALTER TABLE public.oa_migration OWNER TO postgres;

--
-- Name: profissional_alias; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.profissional_alias AS
 SELECT profissional_emails.email,
    profissional_emails.parent,
    profissional_email_aliases.maildrop,
    profissional_emails.active,
    profissional_emails.receive_password,
        CASE
            WHEN ((profissional_email_aliases.permitted_senders_definition)::text = 'maildrop'::text) THEN ( SELECT string_agg((('"'::text || replace(aliases.destination, ''::text, ''::text)) || '"'::text), ','::text) AS string_agg
               FROM postfix.aliases
              WHERE ((aliases.alias_mail = (profissional_emails.email)::text) AND ((replace(aliases.destination, ''::text, ''::text) IN ( SELECT emails.mail
                       FROM postfix.emails)) OR (NOT (split_part(replace(aliases.destination, ''::text, ''::text), '@'::text, 2) IN ( SELECT domains.name
                       FROM postfix.domains))))))
            ELSE profissional_emails.permitted_senders
        END AS permitted_senders,
    profissional_email_aliases.tag_subject,
    profissional_email_aliases.maildrop_definition,
    profissional_email_aliases.permitted_senders_definition,
    profissional_email_aliases.maildrop_group_list_array,
    profissional_emails.id
   FROM (public.profissional_emails
     JOIN public.profissional_email_aliases ON ((profissional_emails.id = profissional_email_aliases.email_id)));


ALTER VIEW public.profissional_alias OWNER TO postgres;

--
-- Name: profissional_clients_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_clients_id_seq OWNER TO horde;

--
-- Name: profissional_clients_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_clients_id_seq OWNED BY public.profissional_clients.id;


--
-- Name: profissional_domain_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_domain_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_domain_filters_id_seq OWNER TO postgres;

--
-- Name: profissional_domain_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_domain_filters_id_seq OWNED BY public.profissional_domain_filters.id;


--
-- Name: profissional_domain_notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_domain_notifications (
    id integer NOT NULL,
    domain integer NOT NULL,
    purpose character varying(64) NOT NULL,
    period_before interval,
    subject text NOT NULL,
    html text,
    plain text,
    sender_name character varying(255) NOT NULL,
    sender_username character varying(255) NOT NULL
);


ALTER TABLE public.profissional_domain_notifications OWNER TO postgres;

--
-- Name: profissional_domain_notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_domain_notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_domain_notifications_id_seq OWNER TO postgres;

--
-- Name: profissional_domain_notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_domain_notifications_id_seq OWNED BY public.profissional_domain_notifications.id;


--
-- Name: profissional_email_alias_destiny; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_email_alias_destiny (
    email_id integer NOT NULL,
    email character varying(512) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_email_alias_destiny OWNER TO horde;

--
-- Name: profissional_email_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_email_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_email_groups_id_seq OWNER TO horde;

--
-- Name: profissional_email_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_email_groups_id_seq OWNED BY public.profissional_email_groups.id;


--
-- Name: profissional_email_marketing; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_email_marketing (
    id integer NOT NULL,
    parent integer NOT NULL,
    active boolean NOT NULL,
    first_name character varying(255),
    last_name character varying(255),
    username character varying(255) NOT NULL,
    password character varying(255),
    email character varying(1024) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_email_marketing OWNER TO postgres;

--
-- Name: profissional_email_marketing_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_email_marketing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_email_marketing_id_seq OWNER TO postgres;

--
-- Name: profissional_email_marketing_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_email_marketing_id_seq OWNED BY public.profissional_email_marketing.id;


--
-- Name: profissional_email_user_credential; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_email_user_credential (
    id integer NOT NULL,
    email_id integer NOT NULL,
    last_update date DEFAULT CURRENT_DATE NOT NULL,
    type character varying(64) NOT NULL,
    hash character varying(256) NOT NULL,
    name character varying(64) NOT NULL
);


ALTER TABLE public.profissional_email_user_credential OWNER TO postgres;

--
-- Name: profissional_email_user_credential_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_email_user_credential_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_email_user_credential_id_seq OWNER TO postgres;

--
-- Name: profissional_email_user_credential_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_email_user_credential_id_seq OWNED BY public.profissional_email_user_credential.id;


--
-- Name: profissional_emails_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_emails_id_seq OWNER TO horde;

--
-- Name: profissional_emails_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_emails_id_seq OWNED BY public.profissional_emails.id;


--
-- Name: turba_objects; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_objects (
    object_id character varying(100) NOT NULL,
    owner_id character varying(255) NOT NULL,
    object_type character varying(255) DEFAULT 'Object'::character varying NOT NULL,
    object_uid character varying(255),
    object_members text,
    object_firstname character varying(255),
    object_lastname character varying(255),
    object_middlenames character varying(255),
    object_nameprefix character varying(100),
    object_namesuffix character varying(100),
    object_alias character varying(100),
    object_photo bytea,
    object_phototype character varying(100),
    object_bday character varying(100),
    object_homestreet character varying(255),
    object_homepob character varying(100),
    object_homecity character varying(255),
    object_homeprovince character varying(255),
    object_homepostalcode character varying(100),
    object_homecountry character varying(255),
    object_workstreet character varying(255),
    object_workpob character varying(100),
    object_workcity character varying(255),
    object_workprovince character varying(255),
    object_workpostalcode character varying(100),
    object_workcountry character varying(255),
    object_tz character varying(100),
    object_geo character varying(255),
    object_email character varying(255),
    object_homephone character varying(100),
    object_workphone character varying(100),
    object_cellphone character varying(100),
    object_fax character varying(100),
    object_pager character varying(100),
    object_title character varying(255),
    object_role character varying(255),
    object_logo bytea,
    object_logotype character varying(100),
    object_company character varying(255),
    object_notes text,
    object_url character varying(255),
    object_freebusyurl character varying(255),
    object_pgppublickey text,
    object_smimepublickey text,
    object_anniversary character varying(100),
    object_department character varying(255),
    object_spouse character varying(255),
    object_homefax character varying(100),
    object_nickname character varying(255),
    object_assistantphone character varying(100),
    object_imaddress character varying(255),
    object_imaddress2 character varying(255),
    object_imaddress3 character varying(255),
    object_homephone2 character varying(100),
    object_carphone character varying(100),
    object_workphone2 character varying(100),
    object_radiophone character varying(100),
    object_companyphone character varying(100),
    object_otherstreet character varying(255),
    object_otherpob character varying(100),
    object_othercity character varying(255),
    object_otherprovince character varying(255),
    object_otherpostalcode character varying(100),
    object_othercountry character varying(255),
    object_yomifirstname character varying(255),
    object_yomilastname character varying(255),
    object_manager character varying(255),
    object_assistant character varying(255),
    object_workemail character varying(255),
    object_homeemail character varying(255),
    object_photoorig bytea
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_objects OWNER TO horde;

--
-- Name: profissional_gal; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.profissional_gal AS
 SELECT galemails.reseller_id,
    galemails.client_id,
    galemails.domain_id,
    COALESCE(turba_objects.object_id, galemails.email) AS object_id,
    turba_objects.owner_id,
    turba_objects.object_type,
    turba_objects.object_uid,
    turba_objects.object_members,
    turba_objects.object_firstname,
    turba_objects.object_lastname,
    turba_objects.object_middlenames,
    turba_objects.object_nameprefix,
    turba_objects.object_namesuffix,
    turba_objects.object_alias,
    turba_objects.object_photo,
    turba_objects.object_phototype,
    turba_objects.object_bday,
    turba_objects.object_homestreet,
    turba_objects.object_homepob,
    turba_objects.object_homecity,
    turba_objects.object_homeprovince,
    turba_objects.object_homepostalcode,
    turba_objects.object_homecountry,
    turba_objects.object_workstreet,
    turba_objects.object_workpob,
    turba_objects.object_workcity,
    turba_objects.object_workprovince,
    turba_objects.object_workpostalcode,
    turba_objects.object_workcountry,
    turba_objects.object_tz,
    turba_objects.object_geo,
    COALESCE(turba_objects.object_email, galemails.email) AS object_email,
    turba_objects.object_homephone,
    turba_objects.object_workphone,
    turba_objects.object_cellphone,
    turba_objects.object_fax,
    turba_objects.object_pager,
    turba_objects.object_title,
    turba_objects.object_role,
    turba_objects.object_logo,
    turba_objects.object_logotype,
    turba_objects.object_company,
    turba_objects.object_notes,
    turba_objects.object_url,
    turba_objects.object_freebusyurl,
    turba_objects.object_pgppublickey,
    turba_objects.object_smimepublickey,
    turba_objects.object_anniversary,
    turba_objects.object_department,
    turba_objects.object_spouse,
    turba_objects.object_homefax,
    turba_objects.object_nickname,
    turba_objects.object_assistantphone,
    turba_objects.object_imaddress,
    turba_objects.object_imaddress2,
    turba_objects.object_imaddress3,
    turba_objects.object_homephone2,
    turba_objects.object_carphone,
    turba_objects.object_workphone2,
    turba_objects.object_radiophone,
    turba_objects.object_companyphone,
    turba_objects.object_otherstreet,
    turba_objects.object_otherpob,
    turba_objects.object_othercity,
    turba_objects.object_otherprovince,
    turba_objects.object_otherpostalcode,
    turba_objects.object_othercountry,
    turba_objects.object_yomifirstname,
    turba_objects.object_yomilastname,
    turba_objects.object_manager,
    turba_objects.object_assistant,
    turba_objects.object_workemail,
    turba_objects.object_homeemail,
    turba_objects.object_photoorig
   FROM ((( SELECT profissional_emails.email,
            profissional_resellers.id AS reseller_id,
            profissional_clients.id AS client_id,
            profissional_domains.id AS domain_id
           FROM (((public.profissional_emails
             JOIN public.profissional_domains ON ((profissional_emails.parent = profissional_domains.id)))
             JOIN public.profissional_clients ON ((profissional_domains.parent = profissional_clients.id)))
             JOIN public.profissional_resellers ON ((profissional_clients.parent = profissional_resellers.id)))
          WHERE (profissional_resellers.active AND profissional_clients.active AND profissional_domains.active AND profissional_emails.active AND (profissional_emails.type = 'u'::bpchar))) galemails
     LEFT JOIN ( SELECT horde_prefs.pref_uid AS email,
            split_part(convert_from(horde_prefs.pref_value, 'UTF-8'::name), ';'::text, 2) AS object_id
           FROM public.horde_prefs
          WHERE (((horde_prefs.pref_scope)::text = 'turba'::text) AND ((horde_prefs.pref_name)::text = 'own_contact'::text))) owncontact ON (((galemails.email)::text = (owncontact.email)::text)))
     LEFT JOIN public.turba_objects ON (((turba_objects.object_id)::text = owncontact.object_id)))
  WITH NO DATA;


ALTER MATERIALIZED VIEW public.profissional_gal OWNER TO postgres;

--
-- Name: profissional_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_groups (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    parent integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_groups OWNER TO horde;

--
-- Name: profissional_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_groups_id_seq OWNER TO horde;

--
-- Name: profissional_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_groups_id_seq OWNED BY public.profissional_groups.id;


--
-- Name: profissional_products; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_products (
    id integer NOT NULL,
    quota integer NOT NULL,
    name character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_products OWNER TO horde;

--
-- Name: profissional_products_sold; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_products_sold (
    product_id integer NOT NULL,
    type character varying(255) NOT NULL,
    element_id integer NOT NULL,
    quota integer DEFAULT 1000000 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');

ALTER TABLE ONLY public.profissional_products_sold REPLICA IDENTITY FULL;


ALTER TABLE public.profissional_products_sold OWNER TO horde;

--
-- Name: profissional_hierarchical_products_resellers_quota; Type: VIEW; Schema: public; Owner: horde
--

CREATE VIEW public.profissional_hierarchical_products_resellers_quota AS
 SELECT profissional_products.id AS product_id,
    'reseller'::text AS type,
    profissional_resellers.id AS element_id,
    profissional_products_sold.quota
   FROM ((public.profissional_products
     CROSS JOIN public.profissional_resellers)
     LEFT JOIN public.profissional_products_sold ON ((((profissional_products_sold.type)::text = 'reseller'::text) AND (profissional_products_sold.product_id = profissional_products.id) AND (profissional_products_sold.element_id = profissional_resellers.id))));


ALTER VIEW public.profissional_hierarchical_products_resellers_quota OWNER TO horde;

--
-- Name: profissional_hierarchical_products_clients_quota; Type: VIEW; Schema: public; Owner: horde
--

CREATE VIEW public.profissional_hierarchical_products_clients_quota AS
 SELECT profissional_products.id AS product_id,
    'client'::text AS type,
    profissional_clients.id AS element_id,
        CASE
            WHEN ((profissional_products_sold.quota IS NULL) OR (profissional_hierarchical_products_resellers_quota.quota IS NULL)) THEN
            CASE
                WHEN (profissional_hierarchical_products_resellers_quota.quota IS NULL) THEN profissional_products_sold.quota
                ELSE profissional_hierarchical_products_resellers_quota.quota
            END
            ELSE
            CASE
                WHEN ((profissional_products_sold.quota <> '-1'::integer) AND (profissional_products_sold.quota < profissional_hierarchical_products_resellers_quota.quota)) THEN profissional_products_sold.quota
                ELSE profissional_hierarchical_products_resellers_quota.quota
            END
        END AS quota
   FROM (((public.profissional_products
     CROSS JOIN public.profissional_clients)
     JOIN public.profissional_hierarchical_products_resellers_quota ON (((profissional_clients.parent = profissional_hierarchical_products_resellers_quota.element_id) AND (profissional_products.id = profissional_hierarchical_products_resellers_quota.product_id))))
     LEFT JOIN public.profissional_products_sold ON ((((profissional_products_sold.type)::text = 'client'::text) AND (profissional_products_sold.product_id = profissional_products.id) AND (profissional_products_sold.element_id = profissional_clients.id))));


ALTER VIEW public.profissional_hierarchical_products_clients_quota OWNER TO horde;

--
-- Name: profissional_hierarchical_products_domains_quota; Type: VIEW; Schema: public; Owner: horde
--

CREATE VIEW public.profissional_hierarchical_products_domains_quota AS
 SELECT profissional_products.id AS product_id,
    'domain'::text AS type,
    profissional_domains.id AS element_id,
        CASE
            WHEN ((profissional_products_sold.quota IS NULL) OR (profissional_hierarchical_products_clients_quota.quota IS NULL)) THEN
            CASE
                WHEN (profissional_hierarchical_products_clients_quota.quota IS NULL) THEN profissional_products_sold.quota
                ELSE profissional_hierarchical_products_clients_quota.quota
            END
            ELSE
            CASE
                WHEN ((profissional_products_sold.quota <> '-1'::integer) AND (profissional_products_sold.quota < profissional_hierarchical_products_clients_quota.quota)) THEN profissional_products_sold.quota
                ELSE profissional_hierarchical_products_clients_quota.quota
            END
        END AS quota
   FROM (((public.profissional_products
     CROSS JOIN public.profissional_domains)
     JOIN public.profissional_hierarchical_products_clients_quota ON (((profissional_domains.parent = profissional_hierarchical_products_clients_quota.element_id) AND (profissional_products.id = profissional_hierarchical_products_clients_quota.product_id))))
     LEFT JOIN public.profissional_products_sold ON ((((profissional_products_sold.type)::text = 'domain'::text) AND (profissional_products_sold.product_id = profissional_products.id) AND (profissional_products_sold.element_id = profissional_domains.id))));


ALTER VIEW public.profissional_hierarchical_products_domains_quota OWNER TO horde;

--
-- Name: profissional_hierarchical_products_quota; Type: VIEW; Schema: public; Owner: horde
--

CREATE VIEW public.profissional_hierarchical_products_quota AS
 SELECT profissional_hierarchical_products_domains_quota.product_id,
    profissional_hierarchical_products_domains_quota.type,
    profissional_hierarchical_products_domains_quota.element_id,
    profissional_hierarchical_products_domains_quota.quota
   FROM public.profissional_hierarchical_products_domains_quota
UNION
 SELECT profissional_hierarchical_products_clients_quota.product_id,
    profissional_hierarchical_products_clients_quota.type,
    profissional_hierarchical_products_clients_quota.element_id,
    profissional_hierarchical_products_clients_quota.quota
   FROM public.profissional_hierarchical_products_clients_quota
UNION
 SELECT profissional_hierarchical_products_resellers_quota.product_id,
    profissional_hierarchical_products_resellers_quota.type,
    profissional_hierarchical_products_resellers_quota.element_id,
    profissional_hierarchical_products_resellers_quota.quota
   FROM public.profissional_hierarchical_products_resellers_quota;


ALTER VIEW public.profissional_hierarchical_products_quota OWNER TO horde;

--
-- Name: profissional_invoice_header_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_invoice_header_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_invoice_header_id_seq OWNER TO horde;

--
-- Name: profissional_invoice_header; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_invoice_header (
    id integer DEFAULT nextval('public.profissional_invoice_header_id_seq'::regclass) NOT NULL,
    date date NOT NULL,
    nif character varying(255) NOT NULL,
    name character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_invoice_header OWNER TO horde;

--
-- Name: profissional_invoice_line; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_invoice_line (
    id integer NOT NULL,
    reference character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    quantity integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_invoice_line OWNER TO horde;

--
-- Name: profissional_logs; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_logs (
    id integer NOT NULL,
    type character varying(128) NOT NULL,
    element_id character varying(255) NOT NULL,
    code integer,
    description text,
    owner character varying(256),
    "time" timestamp without time zone,
    reseller character varying(255),
    client character varying(255),
    domain character varying(255),
    description_id integer,
    element_name character varying(255)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_logs OWNER TO horde;

--
-- Name: profissional_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_logs_id_seq OWNER TO horde;

--
-- Name: profissional_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_logs_id_seq OWNED BY public.profissional_logs.id;


--
-- Name: profissional_mailmarketing_products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_mailmarketing_products (
    id integer NOT NULL,
    quota integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_mailmarketing_products OWNER TO postgres;

--
-- Name: profissional_mailmarketing_products_sold; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_mailmarketing_products_sold (
    product_id integer NOT NULL,
    type character varying(255) NOT NULL,
    element_id integer,
    quota integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_mailmarketing_products_sold OWNER TO postgres;

--
-- Name: profissional_mailmarketing; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.profissional_mailmarketing AS
 SELECT profissional_mailmarketing_products_sold.element_id AS id,
    profissional_mailmarketing_products_sold.element_id AS parent,
    profissional_mailmarketing_products_sold.product_id,
    profissional_mailmarketing_products.quota AS maxcontacts
   FROM (public.profissional_mailmarketing_products
     JOIN public.profissional_mailmarketing_products_sold ON ((profissional_mailmarketing_products_sold.product_id = profissional_mailmarketing_products.id)))
  WHERE ((profissional_mailmarketing_products_sold.quota > 0) AND ((profissional_mailmarketing_products_sold.type)::text = 'client'::text))
  ORDER BY profissional_mailmarketing_products_sold.element_id;


ALTER VIEW public.profissional_mailmarketing OWNER TO postgres;

--
-- Name: profissional_mailmarketing_products_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_mailmarketing_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_mailmarketing_products_id_seq OWNER TO postgres;

--
-- Name: profissional_mailmarketing_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_mailmarketing_products_id_seq OWNED BY public.profissional_mailmarketing_products.id;


--
-- Name: profissional_products_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_products_id_seq OWNER TO horde;

--
-- Name: profissional_products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_products_id_seq OWNED BY public.profissional_products.id;


--
-- Name: profissional_resellers_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.profissional_resellers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_resellers_id_seq OWNER TO horde;

--
-- Name: profissional_resellers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.profissional_resellers_id_seq OWNED BY public.profissional_resellers.id;


--
-- Name: profissional_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_schema_info OWNER TO horde;

--
-- Name: profissional_sendas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_sendas (
    id integer NOT NULL,
    authorized_by integer NOT NULL,
    authorizes integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_sendas OWNER TO postgres;

--
-- Name: profissional_sendas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_sendas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_sendas_id_seq OWNER TO postgres;

--
-- Name: profissional_sendas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_sendas_id_seq OWNED BY public.profissional_sendas.id;


--
-- Name: profissional_stats; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.profissional_stats (
    email character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    hour integer NOT NULL,
    value integer DEFAULT 0 NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_stats OWNER TO horde;

--
-- Name: profissional_sync_domains; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_sync_domains (
    domain_id integer NOT NULL,
    imap_from character varying(1024),
    imap_to character varying(1024),
    master_password_from character varying(1024),
    master_password_to character varying(1024)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_sync_domains OWNER TO postgres;

--
-- Name: profissional_sync_queue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_sync_queue (
    id integer NOT NULL,
    email_from character varying(1024),
    password_from character varying(1024),
    state character varying(128) DEFAULT 'NEVER_SYNCED'::character varying,
    email_to character varying(1024),
    password_to character varying(1024),
    imap_from character varying(1024),
    imap_to character varying(1024),
    last_sync_ts timestamp without time zone DEFAULT now(),
    imapsync_extra_options character varying(1024)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_sync_queue OWNER TO postgres;

--
-- Name: profissional_sync_queue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.profissional_sync_queue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.profissional_sync_queue_id_seq OWNER TO postgres;

--
-- Name: profissional_sync_queue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.profissional_sync_queue_id_seq OWNED BY public.profissional_sync_queue.id;


--
-- Name: profissional_ticketgranting; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_ticketgranting (
    email character varying(512) NOT NULL,
    hash character varying(256) NOT NULL,
    "timestamp" timestamp without time zone NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.profissional_ticketgranting OWNER TO postgres;

--
-- Name: profissional_timestamp_domains; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.profissional_timestamp_domains (
    id integer NOT NULL
);


ALTER TABLE public.profissional_timestamp_domains OWNER TO postgres;

--
-- Name: profissional_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.profissional_users AS
 SELECT profissional_emails.email,
    profissional_emails.parent,
    profissional_email_users.password,
    profissional_emails.active,
    profissional_email_users.last_access,
    profissional_email_users.quota,
    profissional_email_users.homedir,
    profissional_email_users.creation_time,
    profissional_email_users.apikey,
    profissional_email_users.blocked_contents,
    profissional_email_users.imapserver,
    profissional_email_users.smtpserver,
    profissional_email_users.mailbox,
    profissional_email_users.must_change_password,
    profissional_email_users.product_id,
    profissional_email_users.outbound_volume,
    profissional_email_users.pop3_disabled,
    profissional_email_users.webmail_disabled,
    profissional_emails.id
   FROM (public.profissional_emails
     JOIN public.profissional_email_users ON ((profissional_emails.id = profissional_email_users.email_id)));


ALTER VIEW public.profissional_users OWNER TO postgres;

--
-- Name: rampage_objects; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_objects (
    object_id integer NOT NULL,
    object_name character varying(255) NOT NULL,
    type_id integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_objects OWNER TO horde;

--
-- Name: rampage_objects_object_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.rampage_objects_object_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rampage_objects_object_id_seq OWNER TO horde;

--
-- Name: rampage_objects_object_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.rampage_objects_object_id_seq OWNED BY public.rampage_objects.object_id;


--
-- Name: rampage_tag_stats; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_tag_stats (
    tag_id integer NOT NULL,
    count integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_tag_stats OWNER TO horde;

--
-- Name: rampage_tagged; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_tagged (
    user_id integer NOT NULL,
    object_id integer NOT NULL,
    tag_id integer NOT NULL,
    created timestamp without time zone
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_tagged OWNER TO horde;

--
-- Name: rampage_tags; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_tags (
    tag_id integer NOT NULL,
    tag_name character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_tags OWNER TO horde;

--
-- Name: rampage_tags_tag_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.rampage_tags_tag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rampage_tags_tag_id_seq OWNER TO horde;

--
-- Name: rampage_tags_tag_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.rampage_tags_tag_id_seq OWNED BY public.rampage_tags.tag_id;


--
-- Name: rampage_types; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_types (
    type_id integer NOT NULL,
    type_name character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_types OWNER TO horde;

--
-- Name: rampage_types_type_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.rampage_types_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rampage_types_type_id_seq OWNER TO horde;

--
-- Name: rampage_types_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.rampage_types_type_id_seq OWNED BY public.rampage_types.type_id;


--
-- Name: rampage_user_tag_stats; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_user_tag_stats (
    user_id integer NOT NULL,
    tag_id integer NOT NULL,
    count integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_user_tag_stats OWNER TO horde;

--
-- Name: rampage_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.rampage_users (
    user_id integer NOT NULL,
    user_name character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.rampage_users OWNER TO horde;

--
-- Name: rampage_users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.rampage_users_user_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rampage_users_user_id_seq OWNER TO horde;

--
-- Name: rampage_users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.rampage_users_user_id_seq OWNED BY public.rampage_users.user_id;


--
-- Name: sybil_contact; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.sybil_contact (
    contact_id integer NOT NULL,
    contact_idowner character varying(255) NOT NULL,
    contact_idcard character varying(255),
    contact_firstname character varying(255),
    contact_lastname character varying(255),
    contact_middlenames character varying(255),
    contact_nameprefix character varying(255),
    contact_namesuffix character varying(255),
    contact_gender character varying(31),
    contact_nickname character varying(255),
    contact_notes text,
    contact_mainemail character varying(255),
    contact_mainphone character varying(255),
    contact_type character varying(31) DEFAULT 'contact'::character varying NOT NULL,
    contact_cardphoto_name character varying(255),
    contact_pgppublickey text,
    contact_smimepublickey text,
    contact_birthday timestamp without time zone,
    contact_alternativeemail character varying(255),
    contact_company character varying(255),
    contact_jobposition character varying(255),
    contact_addressbook character varying(255),
    contact_freebusy character varying(1024)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.sybil_contact OWNER TO horde;

--
-- Name: sybil_contact_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.sybil_contact_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sybil_contact_seq OWNER TO horde;

--
-- Name: sybil_contact_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.sybil_contact_seq OWNED BY public.sybil_contact.contact_id;


--
-- Name: sybil_contactemail; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.sybil_contactemail (
    contactemail_id integer NOT NULL,
    contactemail_contact_id integer NOT NULL,
    contactemail_email character varying(255) NOT NULL,
    contactemail_type character varying(255) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.sybil_contactemail OWNER TO horde;

--
-- Name: sybil_contactemail_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.sybil_contactemail_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sybil_contactemail_seq OWNER TO horde;

--
-- Name: sybil_contactemail_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.sybil_contactemail_seq OWNED BY public.sybil_contactemail.contactemail_id;


--
-- Name: sybil_contactim; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.sybil_contactim (
    contactim_id integer NOT NULL,
    contactim_contact_id integer NOT NULL,
    contactim_im character varying(255) NOT NULL,
    contactim_type character varying(255) NOT NULL,
    contactim_client character varying(63) NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.sybil_contactim OWNER TO horde;

--
-- Name: sybil_contactim_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.sybil_contactim_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sybil_contactim_seq OWNER TO horde;

--
-- Name: sybil_contactim_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.sybil_contactim_seq OWNED BY public.sybil_contactim.contactim_id;


--
-- Name: sybil_contactphone; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.sybil_contactphone (
    contactphone_id integer NOT NULL,
    contactphone_contact_id integer NOT NULL,
    contactphone_phone character varying(255) NOT NULL,
    contactphone_type character varying(255) NOT NULL,
    contactphone_model character varying(63) DEFAULT 'land'::character varying NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.sybil_contactphone OWNER TO horde;

--
-- Name: sybil_contactphone_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.sybil_contactphone_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sybil_contactphone_seq OWNER TO horde;

--
-- Name: sybil_contactphone_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.sybil_contactphone_seq OWNED BY public.sybil_contactphone.contactphone_id;


--
-- Name: temp; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.temp (
    email text
);


ALTER TABLE public.temp OWNER TO postgres;

--
-- Name: turba_schema_info; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_schema_info (
    version integer
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_schema_info OWNER TO horde;

--
-- Name: turba_shares; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_shares (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255) NOT NULL,
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator integer DEFAULT 0 NOT NULL,
    perm_default integer DEFAULT 0 NOT NULL,
    perm_guest integer DEFAULT 0 NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc character varying(255),
    attribute_params text,
    share_parents character varying(4000)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_shares OWNER TO horde;

--
-- Name: turba_shares_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_shares_groups (
    id integer NOT NULL,
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_shares_groups OWNER TO horde;

--
-- Name: turba_shares_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.turba_shares_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.turba_shares_groups_id_seq OWNER TO horde;

--
-- Name: turba_shares_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.turba_shares_groups_id_seq OWNED BY public.turba_shares_groups.id;


--
-- Name: turba_shares_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.turba_shares_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.turba_shares_share_id_seq OWNER TO horde;

--
-- Name: turba_shares_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.turba_shares_share_id_seq OWNED BY public.turba_shares.share_id;


--
-- Name: turba_shares_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_shares_users (
    id integer NOT NULL,
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm integer NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_shares_users OWNER TO horde;

--
-- Name: turba_shares_users_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.turba_shares_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.turba_shares_users_id_seq OWNER TO horde;

--
-- Name: turba_shares_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.turba_shares_users_id_seq OWNED BY public.turba_shares_users.id;


--
-- Name: turba_sharesng; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_sharesng (
    share_id integer NOT NULL,
    share_name character varying(255) NOT NULL,
    share_owner character varying(255),
    share_flags integer DEFAULT 0 NOT NULL,
    perm_creator_2 boolean DEFAULT false NOT NULL,
    perm_creator_4 boolean DEFAULT false NOT NULL,
    perm_creator_8 boolean DEFAULT false NOT NULL,
    perm_creator_16 boolean DEFAULT false NOT NULL,
    perm_default_2 boolean DEFAULT false NOT NULL,
    perm_default_4 boolean DEFAULT false NOT NULL,
    perm_default_8 boolean DEFAULT false NOT NULL,
    perm_default_16 boolean DEFAULT false NOT NULL,
    perm_guest_2 boolean DEFAULT false NOT NULL,
    perm_guest_4 boolean DEFAULT false NOT NULL,
    perm_guest_8 boolean DEFAULT false NOT NULL,
    perm_guest_16 boolean DEFAULT false NOT NULL,
    attribute_name character varying(255) NOT NULL,
    attribute_desc character varying(255),
    attribute_params text,
    share_parents character varying(4000)
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_sharesng OWNER TO horde;

--
-- Name: turba_sharesng_groups; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_sharesng_groups (
    share_id integer NOT NULL,
    group_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_sharesng_groups OWNER TO horde;

--
-- Name: turba_sharesng_share_id_seq; Type: SEQUENCE; Schema: public; Owner: horde
--

CREATE SEQUENCE public.turba_sharesng_share_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.turba_sharesng_share_id_seq OWNER TO horde;

--
-- Name: turba_sharesng_share_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: horde
--

ALTER SEQUENCE public.turba_sharesng_share_id_seq OWNED BY public.turba_sharesng.share_id;


--
-- Name: turba_sharesng_users; Type: TABLE; Schema: public; Owner: horde
--

CREATE TABLE public.turba_sharesng_users (
    share_id integer NOT NULL,
    user_uid character varying(255) NOT NULL,
    perm_2 boolean DEFAULT false NOT NULL,
    perm_4 boolean DEFAULT false NOT NULL,
    perm_8 boolean DEFAULT false NOT NULL,
    perm_16 boolean DEFAULT false NOT NULL
)
WITH (autovacuum_vacuum_cost_delay='20');


ALTER TABLE public.turba_sharesng_users OWNER TO horde;

--
-- Name: mailaddr id; Type: DEFAULT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.mailaddr ALTER COLUMN id SET DEFAULT nextval('amavis.mailaddr_id_seq'::regclass);


--
-- Name: policy id; Type: DEFAULT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.policy ALTER COLUMN id SET DEFAULT nextval('amavis.policy_id_seq'::regclass);


--
-- Name: invoice id; Type: DEFAULT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoice ALTER COLUMN id SET DEFAULT nextval('invoicexpress.invoice_id_seq'::regclass);


--
-- Name: invoiceline id; Type: DEFAULT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoiceline ALTER COLUMN id SET DEFAULT nextval('invoicexpress.invoiceline_id_seq'::regclass);


--
-- Name: reseller id; Type: DEFAULT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.reseller ALTER COLUMN id SET DEFAULT nextval('invoicexpress.reseller_id_seq'::regclass);


--
-- Name: timestamp_queue id; Type: DEFAULT; Schema: postfix; Owner: postgres
--

ALTER TABLE ONLY postfix.timestamp_queue ALTER COLUMN id SET DEFAULT nextval('postfix.timestamp_queue_id_seq'::regclass);


--
-- Name: smtp_bind_address id; Type: DEFAULT; Schema: postfix_submission; Owner: postfix
--

ALTER TABLE ONLY postfix_submission.smtp_bind_address ALTER COLUMN id SET DEFAULT nextval('postfix_submission.smtp_bind_address_id_seq'::regclass);


--
-- Name: horde_alarms id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_alarms ALTER COLUMN id SET DEFAULT nextval('public.horde_alarms_id_seq'::regclass);


--
-- Name: horde_groups group_uid; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_groups ALTER COLUMN group_uid SET DEFAULT nextval('public.horde_groups_group_uid_seq'::regclass);


--
-- Name: horde_histories history_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_histories ALTER COLUMN history_id SET DEFAULT nextval('public.horde_histories_history_id_seq'::regclass);


--
-- Name: horde_histories_modseq history_modseq; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_histories_modseq ALTER COLUMN history_modseq SET DEFAULT nextval('public.horde_histories_modseq_history_modseq_seq'::regclass);


--
-- Name: horde_imap_client_data messageid; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_imap_client_data ALTER COLUMN messageid SET DEFAULT nextval('public.horde_imap_client_data_messageid_seq'::regclass);


--
-- Name: horde_muvfs vfs_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_muvfs ALTER COLUMN vfs_id SET DEFAULT nextval('public.horde_muvfs_vfs_id_seq'::regclass);


--
-- Name: horde_perms perm_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_perms ALTER COLUMN perm_id SET DEFAULT nextval('public.horde_perms_perm_id_seq'::regclass);


--
-- Name: horde_queue_tasks task_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_queue_tasks ALTER COLUMN task_id SET DEFAULT nextval('public.horde_queue_tasks_task_id_seq'::regclass);


--
-- Name: horde_vfs vfs_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_vfs ALTER COLUMN vfs_id SET DEFAULT nextval('public.horde_vfs_vfs_id_seq'::regclass);


--
-- Name: imp_sentmail sentmail_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.imp_sentmail ALTER COLUMN sentmail_id SET DEFAULT nextval('public.imp_sentmail_sentmail_id_seq'::regclass);


--
-- Name: ingo_rules rule_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_rules ALTER COLUMN rule_id SET DEFAULT nextval('public.ingo_rules_rule_id_seq'::regclass);


--
-- Name: ingo_shares share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares ALTER COLUMN share_id SET DEFAULT nextval('public.ingo_shares_share_id_seq'::regclass);


--
-- Name: ingo_shares_groups id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares_groups ALTER COLUMN id SET DEFAULT nextval('public.ingo_shares_groups_id_seq'::regclass);


--
-- Name: ingo_shares_users id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares_users ALTER COLUMN id SET DEFAULT nextval('public.ingo_shares_users_id_seq'::regclass);


--
-- Name: ingo_sharesng share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_sharesng ALTER COLUMN share_id SET DEFAULT nextval('public.ingo_sharesng_share_id_seq'::regclass);


--
-- Name: kronolith_resources resource_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_resources ALTER COLUMN resource_id SET DEFAULT nextval('public.kronolith_resources_resource_id_seq'::regclass);


--
-- Name: kronolith_shares share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares ALTER COLUMN share_id SET DEFAULT nextval('public.kronolith_shares_share_id_seq'::regclass);


--
-- Name: kronolith_shares_groups id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares_groups ALTER COLUMN id SET DEFAULT nextval('public.kronolith_shares_groups_id_seq'::regclass);


--
-- Name: kronolith_shares_users id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares_users ALTER COLUMN id SET DEFAULT nextval('public.kronolith_shares_users_id_seq'::regclass);


--
-- Name: kronolith_sharesng share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_sharesng ALTER COLUMN share_id SET DEFAULT nextval('public.kronolith_sharesng_share_id_seq'::regclass);


--
-- Name: kronolith_storage id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_storage ALTER COLUMN id SET DEFAULT nextval('public.kronolith_storage_id_seq'::regclass);


--
-- Name: profissional_clients id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_clients ALTER COLUMN id SET DEFAULT nextval('public.profissional_clients_id_seq'::regclass);


--
-- Name: profissional_domain_filters id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_filters ALTER COLUMN id SET DEFAULT nextval('public.profissional_domain_filters_id_seq'::regclass);


--
-- Name: profissional_domain_notifications id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_notifications ALTER COLUMN id SET DEFAULT nextval('public.profissional_domain_notifications_id_seq'::regclass);


--
-- Name: profissional_domains id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_domains ALTER COLUMN id SET DEFAULT nextval('public.profissional_domains_id_seq'::regclass);


--
-- Name: profissional_email_groups id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_groups ALTER COLUMN id SET DEFAULT nextval('public.profissional_email_groups_id_seq'::regclass);


--
-- Name: profissional_email_marketing id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_marketing ALTER COLUMN id SET DEFAULT nextval('public.profissional_email_marketing_id_seq'::regclass);


--
-- Name: profissional_email_user_credential id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_user_credential ALTER COLUMN id SET DEFAULT nextval('public.profissional_email_user_credential_id_seq'::regclass);


--
-- Name: profissional_emails id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_emails ALTER COLUMN id SET DEFAULT nextval('public.profissional_emails_id_seq'::regclass);


--
-- Name: profissional_groups id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_groups ALTER COLUMN id SET DEFAULT nextval('public.profissional_groups_id_seq'::regclass);


--
-- Name: profissional_logs id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_logs ALTER COLUMN id SET DEFAULT nextval('public.profissional_logs_id_seq'::regclass);


--
-- Name: profissional_mailmarketing_products id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_mailmarketing_products ALTER COLUMN id SET DEFAULT nextval('public.profissional_mailmarketing_products_id_seq'::regclass);


--
-- Name: profissional_products id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_products ALTER COLUMN id SET DEFAULT nextval('public.profissional_products_id_seq'::regclass);


--
-- Name: profissional_resellers id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_resellers ALTER COLUMN id SET DEFAULT nextval('public.profissional_resellers_id_seq'::regclass);


--
-- Name: profissional_sendas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sendas ALTER COLUMN id SET DEFAULT nextval('public.profissional_sendas_id_seq'::regclass);


--
-- Name: profissional_sync_queue id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sync_queue ALTER COLUMN id SET DEFAULT nextval('public.profissional_sync_queue_id_seq'::regclass);


--
-- Name: rampage_objects object_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_objects ALTER COLUMN object_id SET DEFAULT nextval('public.rampage_objects_object_id_seq'::regclass);


--
-- Name: rampage_tags tag_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_tags ALTER COLUMN tag_id SET DEFAULT nextval('public.rampage_tags_tag_id_seq'::regclass);


--
-- Name: rampage_types type_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_types ALTER COLUMN type_id SET DEFAULT nextval('public.rampage_types_type_id_seq'::regclass);


--
-- Name: rampage_users user_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_users ALTER COLUMN user_id SET DEFAULT nextval('public.rampage_users_user_id_seq'::regclass);


--
-- Name: sybil_contact contact_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contact ALTER COLUMN contact_id SET DEFAULT nextval('public.sybil_contact_seq'::regclass);


--
-- Name: sybil_contactemail contactemail_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactemail ALTER COLUMN contactemail_id SET DEFAULT nextval('public.sybil_contactemail_seq'::regclass);


--
-- Name: sybil_contactim contactim_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactim ALTER COLUMN contactim_id SET DEFAULT nextval('public.sybil_contactim_seq'::regclass);


--
-- Name: sybil_contactphone contactphone_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactphone ALTER COLUMN contactphone_id SET DEFAULT nextval('public.sybil_contactphone_seq'::regclass);


--
-- Name: turba_shares share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares ALTER COLUMN share_id SET DEFAULT nextval('public.turba_shares_share_id_seq'::regclass);


--
-- Name: turba_shares_groups id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares_groups ALTER COLUMN id SET DEFAULT nextval('public.turba_shares_groups_id_seq'::regclass);


--
-- Name: turba_shares_users id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares_users ALTER COLUMN id SET DEFAULT nextval('public.turba_shares_users_id_seq'::regclass);


--
-- Name: turba_sharesng share_id; Type: DEFAULT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_sharesng ALTER COLUMN share_id SET DEFAULT nextval('public.turba_sharesng_share_id_seq'::regclass);


--
-- Data for Name: mailaddr; Type: TABLE DATA; Schema: amavis; Owner: postgres
--

COPY amavis.mailaddr (id, priority, email) FROM stdin;
\.


--
-- Data for Name: policy; Type: TABLE DATA; Schema: amavis; Owner: postgres
--

COPY amavis.policy (id, policy_name, virus_lover, spam_lover, unchecked_lover, banned_files_lover, bad_header_lover, bypass_virus_checks, bypass_spam_checks, bypass_banned_checks, bypass_header_checks, virus_quarantine_to, spam_quarantine_to, banned_quarantine_to, unchecked_quarantine_to, bad_header_quarantine_to, clean_quarantine_to, archive_quarantine_to, spam_tag_level, spam_tag2_level, spam_tag3_level, spam_kill_level, spam_dsn_cutoff_level, spam_quarantine_cutoff_level, addr_extension_virus, addr_extension_spam, addr_extension_banned, addr_extension_bad_header, warnvirusrecip, warnbannedrecip, warnbadhrecip, newvirus_admin, virus_admin, banned_admin, bad_header_admin, spam_admin, spam_subject_tag, spam_subject_tag2, spam_subject_tag3, message_size_limit, banned_rulenames, disclaimer_options, forward_method, sa_userconf, sa_username) FROM stdin;
\.


--
-- Data for Name: wblist; Type: TABLE DATA; Schema: amavis; Owner: postgres
--

COPY amavis.wblist (rid, sid, wb) FROM stdin;
\.


--
-- Data for Name: client; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.client (reseller, profissional_client, external_id) FROM stdin;
\.


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.invoice (id, reseller, profissional_client, date, external_id) FROM stdin;
\.


--
-- Data for Name: invoiceline; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.invoiceline (id, invoice, profissional_product, count, discount) FROM stdin;
\.


--
-- Data for Name: item; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.item (reseller, profissional_product, external_id, external_id_discount) FROM stdin;
\.


--
-- Data for Name: reseller; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.reseller (id, reseller, accountname, apikey, active) FROM stdin;
\.


--
-- Data for Name: usagemeter; Type: TABLE DATA; Schema: invoicexpress; Owner: postgres
--

COPY invoicexpress.usagemeter (date, product, client, count) FROM stdin;
\.


--
-- Data for Name: ldap_attr_mappings; Type: TABLE DATA; Schema: openldap; Owner: openldap
--

COPY openldap.ldap_attr_mappings (id, oc_map_id, name, sel_expr, sel_expr_u, from_tbls, join_where, add_proc, delete_proc, param_order, expect_return) FROM stdin;
\.


--
-- Data for Name: ldap_entries_suffix; Type: TABLE DATA; Schema: openldap; Owner: openldap
--

COPY openldap.ldap_entries_suffix (id, dn, oc_map_id, parent, keyval) FROM stdin;
\.


--
-- Data for Name: ldap_entry_to_class_map; Type: TABLE DATA; Schema: openldap; Owner: openldap
--

COPY openldap.ldap_entry_to_class_map (bitmap, object_class) FROM stdin;
\.


--
-- Data for Name: ldap_oc_mappings; Type: TABLE DATA; Schema: openldap; Owner: openldap
--

COPY openldap.ldap_oc_mappings (id, name, keytbl, keycol, create_proc, delete_proc, expect_return) FROM stdin;
\.


--
-- Data for Name: suffix; Type: TABLE DATA; Schema: openldap; Owner: openldap
--

COPY openldap.suffix (id, name) FROM stdin;
\.


--
-- Data for Name: timestamp_queue; Type: TABLE DATA; Schema: postfix; Owner: postgres
--

COPY postfix.timestamp_queue (id, sent_ts, smtp_server, queue_id, mail_from, rcpt_to, subject, smtp_result, smtp_log) FROM stdin;
\.


--
-- Data for Name: smtp_bind_address; Type: TABLE DATA; Schema: postfix_submission; Owner: postfix
--

COPY postfix_submission.smtp_bind_address (id, domain, transport, required_ip) FROM stdin;
\.


--
-- Data for Name: content_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.content_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_activesync_cache; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_cache (cache_devid, cache_user, cache_data) FROM stdin;
\.


--
-- Data for Name: horde_activesync_device; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_device (device_id, device_type, device_agent, device_supported, device_policykey, device_rwstatus, device_properties) FROM stdin;
\.


--
-- Data for Name: horde_activesync_device_users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_device_users (device_id, device_user, device_policykey) FROM stdin;
\.


--
-- Data for Name: horde_activesync_mailmap; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_mailmap (message_uid, sync_key, sync_devid, sync_folderid, sync_user, sync_read, sync_deleted, sync_flagged, sync_changed, sync_category, sync_draft) FROM stdin;
\.


--
-- Data for Name: horde_activesync_map; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_map (message_uid, sync_modtime, sync_key, sync_devid, sync_folderid, sync_user, sync_clientid, sync_deleted) FROM stdin;
\.


--
-- Data for Name: horde_activesync_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_activesync_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_activesync_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.horde_activesync_state (sync_mod, sync_key, sync_devid, sync_folderid, sync_user, sync_data, sync_pending, sync_timestamp) FROM stdin;
\.


--
-- Data for Name: horde_alarm_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_alarm_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_alarms; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_alarms (id, alarm_id, alarm_uid, alarm_start, alarm_end, alarm_methods, alarm_params, alarm_title, alarm_text, alarm_snooze, alarm_dismissed, alarm_internal, alarm_instanceid) FROM stdin;
\.


--
-- Data for Name: horde_auth_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_auth_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_cache; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_cache (cache_id, cache_timestamp, cache_expiration, cache_data) FROM stdin;
\.


--
-- Data for Name: horde_cache_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_cache_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_core_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_core_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_dav_collections; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_dav_collections (id_interface, id_internal, id_external) FROM stdin;
\.


--
-- Data for Name: horde_dav_objects; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_dav_objects (id_collection, id_internal, id_external) FROM stdin;
\.


--
-- Data for Name: horde_dav_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_dav_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_group_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_group_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_groups (group_uid, group_name, group_parents, group_email) FROM stdin;
\.


--
-- Data for Name: horde_groups_members; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_groups_members (group_uid, user_uid) FROM stdin;
\.


--
-- Data for Name: horde_histories; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_histories (history_id, object_uid, history_action, history_ts, history_desc, history_who, history_extra, history_modseq) FROM stdin;
\.


--
-- Data for Name: horde_histories_modseq; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_histories_modseq (history_modseq, history_modseqempty) FROM stdin;
\.


--
-- Data for Name: horde_history_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_history_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_imap_client_data; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_imap_client_data (messageid, hostspec, mailbox, modified, port, username) FROM stdin;
\.


--
-- Data for Name: horde_imap_client_message; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_imap_client_message (data, msguid, messageid) FROM stdin;
\.


--
-- Data for Name: horde_imap_client_metadata; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_imap_client_metadata (data, field, messageid) FROM stdin;
\.


--
-- Data for Name: horde_imap_client_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_imap_client_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_lock_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_lock_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_locks; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_locks (lock_id, lock_owner, lock_scope, lock_principal, lock_origin_timestamp, lock_update_timestamp, lock_expiry_timestamp, lock_type) FROM stdin;
\.


--
-- Data for Name: horde_muvfs; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_muvfs (vfs_id, vfs_type, vfs_path, vfs_name, vfs_modified, vfs_owner, vfs_perms, vfs_data) FROM stdin;
\.


--
-- Data for Name: horde_perms; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_perms (perm_id, perm_name, perm_parents, perm_data) FROM stdin;
\.


--
-- Data for Name: horde_perms_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_perms_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_prefs; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_prefs (pref_uid, pref_scope, pref_name, pref_value) FROM stdin;
\.


--
-- Data for Name: horde_prefs_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_prefs_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_queue_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_queue_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_queue_tasks; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_queue_tasks (task_id, task_queue, task_fields) FROM stdin;
\.


--
-- Data for Name: horde_sessionhandler; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_sessionhandler (session_id, session_lastmodified, session_data) FROM stdin;
\.


--
-- Data for Name: horde_sessionhandler_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_sessionhandler_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_signups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_signups (user_name, signup_date, signup_host, signup_data) FROM stdin;
\.


--
-- Data for Name: horde_syncml_anchors; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_syncml_anchors (syncml_syncpartner, syncml_db, syncml_uid, syncml_clientanchor, syncml_serveranchor) FROM stdin;
\.


--
-- Data for Name: horde_syncml_map; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_syncml_map (syncml_syncpartner, syncml_db, syncml_uid, syncml_cuid, syncml_suid, syncml_timestamp) FROM stdin;
\.


--
-- Data for Name: horde_syncml_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_syncml_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_token_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_token_schema_info (version) FROM stdin;
\.


--
-- Data for Name: horde_tokens; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_tokens (token_address, token_id, token_timestamp) FROM stdin;
\.


--
-- Data for Name: horde_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_users (user_uid, user_pass, user_soft_expiration_date, user_hard_expiration_date) FROM stdin;
\.


--
-- Data for Name: horde_vfs; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_vfs (vfs_id, vfs_type, vfs_path, vfs_name, vfs_modified, vfs_owner, vfs_data) FROM stdin;
\.


--
-- Data for Name: horde_vfs_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.horde_vfs_schema_info (version) FROM stdin;
\.


--
-- Data for Name: imp_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.imp_schema_info (version) FROM stdin;
\.


--
-- Data for Name: imp_sentmail; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.imp_sentmail (sentmail_id, sentmail_who, sentmail_ts, sentmail_messageid, sentmail_action, sentmail_recipient, sentmail_success) FROM stdin;
\.


--
-- Data for Name: ingo_forwards; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_forwards (forward_owner, forward_addresses, forward_keep) FROM stdin;
\.


--
-- Data for Name: ingo_lists; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_lists (list_owner, list_blacklist, list_address) FROM stdin;
\.


--
-- Data for Name: ingo_rules; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_rules (rule_id, rule_owner, rule_name, rule_action, rule_value, rule_flags, rule_conditions, rule_combine, rule_stop, rule_active, rule_order) FROM stdin;
\.


--
-- Data for Name: ingo_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_schema_info (version) FROM stdin;
\.


--
-- Data for Name: ingo_shares; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_shares (share_id, share_name, share_owner, share_flags, perm_creator, perm_default, perm_guest, attribute_name, attribute_desc, share_parents) FROM stdin;
\.


--
-- Data for Name: ingo_shares_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_shares_groups (id, share_id, group_uid, perm) FROM stdin;
\.


--
-- Data for Name: ingo_shares_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_shares_users (id, share_id, user_uid, perm) FROM stdin;
\.


--
-- Data for Name: ingo_sharesng; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_sharesng (share_id, share_name, share_owner, share_flags, perm_creator_2, perm_creator_4, perm_creator_8, perm_creator_16, perm_default_2, perm_default_4, perm_default_8, perm_default_16, perm_guest_2, perm_guest_4, perm_guest_8, perm_guest_16, attribute_name, attribute_desc, share_parents) FROM stdin;
\.


--
-- Data for Name: ingo_sharesng_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_sharesng_groups (share_id, group_uid, perm_2, perm_4, perm_8, perm_16) FROM stdin;
\.


--
-- Data for Name: ingo_sharesng_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_sharesng_users (share_id, user_uid, perm_2, perm_4, perm_8, perm_16) FROM stdin;
\.


--
-- Data for Name: ingo_spam; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_spam (spam_owner, spam_level, spam_folder) FROM stdin;
\.


--
-- Data for Name: ingo_vacations; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.ingo_vacations (vacation_owner, vacation_addresses, vacation_subject, vacation_reason, vacation_days, vacation_start, vacation_end, vacation_excludes, vacation_ignorelists) FROM stdin;
\.


--
-- Data for Name: kronolith_events; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_events (event_id, event_uid, calendar_id, event_creator_id, event_description, event_location, event_status, event_attendees, event_keywords, event_exceptions, event_title, event_recurtype, event_recurinterval, event_recurdays, event_recurenddate, event_recurcount, event_start, event_end, event_alarm, event_modified, event_private, event_allday, event_alarm_methods, event_url, event_baseid, event_exceptionoriginaldate, event_resources, event_timezone, event_organizer) FROM stdin;
\.


--
-- Data for Name: kronolith_events_geo; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_events_geo (event_id, event_lat, event_lon, event_zoom) FROM stdin;
\.


--
-- Data for Name: kronolith_resources; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_resources (resource_id, resource_name, resource_calendar, resource_description, resource_response_type, resource_type, resource_members, resource_email) FROM stdin;
\.


--
-- Data for Name: kronolith_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_schema_info (version) FROM stdin;
\.


--
-- Data for Name: kronolith_shares; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_shares (share_id, share_name, share_owner, share_flags, perm_creator, perm_default, perm_guest, attribute_name, attribute_desc, attribute_color, share_parents, attribute_email, attribute_members, attribute_response_type, attribute_calendar_type, attribute_isgroup) FROM stdin;
\.


--
-- Data for Name: kronolith_shares_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_shares_groups (id, share_id, group_uid, perm) FROM stdin;
\.


--
-- Data for Name: kronolith_shares_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_shares_users (id, share_id, user_uid, perm) FROM stdin;
\.


--
-- Data for Name: kronolith_sharesng; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_sharesng (share_id, share_name, share_owner, share_flags, perm_creator_2, perm_creator_4, perm_creator_8, perm_creator_16, perm_creator_1024, perm_default_2, perm_default_4, perm_default_8, perm_default_16, perm_default_1024, perm_guest_2, perm_guest_4, perm_guest_8, perm_guest_16, perm_guest_1024, attribute_name, attribute_desc, attribute_color, share_parents, attribute_email, attribute_members, attribute_response_type, attribute_calendar_type, attribute_isgroup) FROM stdin;
\.


--
-- Data for Name: kronolith_sharesng_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_sharesng_groups (share_id, group_uid, perm_2, perm_4, perm_8, perm_16, perm_1024) FROM stdin;
\.


--
-- Data for Name: kronolith_sharesng_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_sharesng_users (share_id, user_uid, perm_2, perm_4, perm_8, perm_16, perm_1024) FROM stdin;
\.


--
-- Data for Name: kronolith_storage; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.kronolith_storage (id, vfb_owner, vfb_email, vfb_serialized) FROM stdin;
\.


--
-- Data for Name: novis_username_map; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.novis_username_map (username, email, email_username, email_domain) FROM stdin;
\.


--
-- Data for Name: oa_migration; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.oa_migration (email, host, path, last_sync) FROM stdin;
\.


--
-- Data for Name: profissional_client_softsuspend; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_client_softsuspend (id) FROM stdin;
\.


--
-- Data for Name: profissional_clients; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_clients (id, name, parent, address, city, postalcode, nif, phonenumber, contactname, email, active, logo, creation_time, offer, offer_reason, external_id, we_manage_domain, billing_period, theme_colors) FROM stdin;
1	Sooma.com - Web Services, Lda	1	Rua Ricardo Severo nº3 5ºdto, Porto, Portugal	Porto	4050-515	504766821	226075610	Sérgio Carvalho	sergio.carvalho@sooma.com	t	\\x646174613a696d6167652f706e673b6261736536342c6956424f5277304b47676f414141414e5355684555674141414c51414141416f43415941414142586164414b41414141475852465748525462325a30643246795a5142425a4739695a53424a6257466e5a564a6c5957523563636c6c504141414264644a52454655654e72736e643178347a595178794750432b41393544466a6553627634565551756f4b6a4b7768566765554b6a6c654264425651726b432b43756972514d78375a73524d48764e41646141417557574d342b304343314b7949416f37672f474d5250373567522b57757774516e6f686777516a37352b646635764c5037374c4632736531624d2b7966667270377a39337670337a4a4852624d41546b7166797a376f44634e51587a6e595336436b414838786e6d5350375a79445a6c624b366766692b68726e30352f36765168634536746d624372457a422f7a46343647412b7838774c35437356566e79523756665a55755437643737453039654d6252495973564d744b5644744a534467485a4178654d322b686e6e626d5952315a59452b396f5748617750454438526f3145316478424e6b76627541314d6c4e77567765554f395268786c73355450515638674e57634e4e53526e374b2f414c3262617935514f39513743424a754654554d304f4a506369395a62456f4d4753512b2b53777367425a436f353241536f5477373143727a6f5550744d664a34686e39552b4a6f556c654e79686468666961792f6936534839576375426359746f5276413031703357546d37377a70667276745a4758554b4d764d3841614b5746475239676e77694a7151504d66746939774f764a4f77684c544745433956324239506d7a547866646575694e2b48465771414a76757a4f4547584e494874754c664b2b4248387950716b654a4f5237705665386374544941756d7533506b3273544f4269472b78456d624652424e36364374375a5336685453505337747049677a7067614356453955657335637438384e48617946586a62594f4f416d706f776d53466c4f613658722b532b336a46793552684442547650797365537148775541437746633054457a5457456f384a486f4446344578484b62324f44656b626b4e79577372714f53774268786476632b4c6831746761615375455841594853474a666e2f546161424e396139732b702f624537693062636c6f316a49675a5665714b773232506c363652304264617a334e565130356b515375504c3547696461694547744156436a385446554d4561564a464c4f36684d347477337948627371346750516262795547625a5651442b4a77307972746a61467831725553546865784c4470314550704a75444e4b75547a42426e34706b6d4746496c4858336f36696b523876774a53743266426d417551554f63435831323377796f61347476624b5764564c476a66564e68626d71705a35774f547876614a5944714f79304c7a592b6757326a3635466f5a74446472625474775a7762364e777a365578584475653062444a736f7771465756593239705454652b506a64624d4739615837427a706e35376a4f7749756e754762746d42726e44556a69337775353750777648367472612b5561444b7472454148597352574f4c5147593367723941724844754632396e483043313761757233785857667848412b387835364f634e4c5438454c597a442f66332f322b2f315a4e4e7372574f7143486a69504c326c4c5342354e4d655461454a2b336a326a71574e51366b575070326c61726362533773576d6c786668545176504f45484a73744a685774622b3037322b514163716138515576334530456c7a4a6d6674534248704d6c54433959474f4c7a68686e50786b51735837366872736c445939714a77534e545952506c636165574f44707966464b784b782b615a2f3742515a794c682b35545062416c4a696e6836626e776d784c55354931304b61414c7939504d4e546b726d5066507866483041687167586b424d4856304b30427950744758413054435379536d697654695362734545326d5a63373238434d4763634a394a4b6832324c43623345455772302f6f306436506278317a43397441314d626d4a57486b68337a5143764439436c4939444345656a456f58545843326a794a4d38453643452f4e4b4d536a6e734437436237796a7a47563652444436483768364f754435614a2f753938586f774e2f65556b6c5a5858794f63336a497a2f474462575a6138704552625649727a32646c4367425147304c59376c65735162354b6c77437431543277495a754b71386477742f565a745979715958422f5261394a74756a686d50394334774835694a54326f5a504d665339636d6d534a3951693857714150513379364754557967317a5a6e373534513372704451704473494d6f7632484e482b386b613676674864745763527a4b6d4d315a62664d67764d314551433578694e49555449694f306a706d3436554e656e4b676457696f734e672f57697178776d4d50554f4c324337584c7a2b394265312f64775142314b7a69796e632b457a514d3352767265734c304a47773137636a517a3965484e4352474c34515a386773486165564a39443171513564456b2f5131734759466b4a64484e4236434e4563436559683848462b4c2b3859756a34426e517a6f6c347346756f314a433065777551765564666934797a337a452b71756856387a68526e547153544d65487555514538737061336641504945715337555542336f6d3345723351667875673542313235313677507271706e4546564d3337677a55696e4774336465734f4b394464617375706e3355745830557236396774535648645731505774576e315654313675576867443448432f2b534974696f675035586741454147435645564274794b444d41414141415355564f524b35435949493d	2012-06-12 11:39:26.01806	t	Domínio interno e demos	\N	f	1	\N
\.


--
-- Data for Name: profissional_domain_aliases; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_domain_aliases (id, name, parent, active, dkim_enabled) FROM stdin;
\.


--
-- Data for Name: profissional_domain_filters; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_domain_filters (id, domain_id, name, match_rule, action_rule, priority, php_match_rule, php_action_rule) FROM stdin;
\.


--
-- Data for Name: profissional_domain_notifications; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_domain_notifications (id, domain, purpose, period_before, subject, html, plain, sender_name, sender_username) FROM stdin;
\.


--
-- Data for Name: profissional_domain_secondary_target; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_domain_secondary_target (id, target) FROM stdin;
\.


--
-- Data for Name: profissional_domains; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_domains (id, name, parent, active, userslimit, logo, creation_time, language, setup_complete, timezone, offer, offer_reason, migrating, dkim_enabled, dkim_selector, dkim_key_private, dkim_key_public, pref_usersmusthavegroups, theme_colors, spam_header_threshold, spam_subject_threshold, spam_flag_threshold, spam_refuse_threshold, password_rotation) FROM stdin;
1	sooma.com	1	t	100	\\x646174613a696d6167652f706e673b6261736536342c6956424f5277304b47676f414141414e5355684555674141414c51414141416f43415941414142586164414b41414141475852465748525462325a30643246795a5142425a4739695a53424a6257466e5a564a6c5957523563636c6c504141414264644a52454655654e72736e643178347a595178794750432b41393544466a6553627634565551756f4b6a4b7768566765554b6a6c654264425651726b432b43756972514d78375a73524d48764e41646141417557574d342b304343314b7949416f37672f474d5250373567522b57757774516e6f686777516a37352b646635764c5037374c4632736531624d2b7966667270377a39337670337a4a4852624d41546b7166797a376f44634e51587a6e595336436b414838786e6d5350375a79445a6c624b366766692b68726e30352f36765168634536746d624372457a422f7a46343647412b7838774c35437356566e79523756665a55755437643737453039654d6252495973564d744b5644744a534467485a4178654d322b686e6e626d5952315a59452b396f5748617750454438526f3145316478424e6b76627541314d6c4e77567765554f395268786c73355450515638674e57634e4e53526e374b2f414c3262617935514f39513743424a754654554d304f4a506369395a62456f4d4753512b2b53777367425a436f353241536f5477373143727a6f5550744d664a34686e39552b4a6f556c654e79686468666961792f6936534839576375426359746f5276413031703357546d37377a70667276745a4758554b4d764d3841614b5746475239676e77694a7151504d66746939774f764a4f77684c544745433956324239506d7a547866646575694e2b48465771414a76757a4f4547584e494874754c664b2b4248387950716b654a4f5237705665386374544941756d7533506b3273544f4269472b78456d624652424e36364374375a5336685453505337747049677a7067614356453955657335637438384e48617946586a62594f4f416d706f776d53466c4f613658722b532b336a46793552684442547650797365537148775541437746633054457a5457456f384a486f4446344578484b62324f44656b626b4e79577372714f53774268786476632b4c6831746761615375455841594853474a666e2f546161424e396139732b702f624537693062636c6f316a49675a5665714b773232506c363652304264617a334e565130356b515375504c3547696461694547744156436a385446554d4561564a464c4f36684d347477337948627371346750516262795547625a5651442b4a77307972746a61467831725553546865784c4470314550704a75444e4b75547a42426e34706b6d4746496c4858336f36696b523876774a53743266426d417551554f63435831323377796f61347476624b5764564c476a66564e68626d71705a35774f547876614a5944714f79304c7a592b6757326a3635466f5a74446472625474775a7762364e777a365578584475653062444a736f7771465756593239705454652b506a64624d4739615837427a706e35376a4f7749756e754762746d42726e44556a69337775353750777648367472612b5561444b7472454148597352574f4c5147593367723941724844754632396e483043313761757233785857667848412b387835364f634e4c5438454c597a442f66332f322b2f315a4e4e7372574f7143486a69504c326c4c5342354e4d655461454a2b336a326a71574e51366b575070326c61726362533773576d6c786668545176504f45484a73744a685774622b3037322b514163716138515576334530456c7a4a6d6674534248704d6c54433959474f4c7a68686e50786b51735837366872736c445939714a77534e545952506c636165574f44707966464b784b782b615a2f3742515a794c682b35545062416c4a696e6836626e776d784c55354931304b61414c7939504d4e546b726d5066507866483041687167586b424d4856304b30427950744758413054435379536d697654695362734545326d5a63373238434d4763634a394a4b6832324c43623345455772302f6f306436506278317a43397441314d626d4a57486b68337a5143764439436c4939444345656a456f58545843326a794a4d38453643452f4e4b4d536a6e734437436237796a7a47563652444436483768364f754435614a2f753938586f774e2f65556b6c5a5858794f63336a497a2f474462575a6138704552625649727a32646c4367425147304c59376c65735162354b6c77437431543277495a754b71386477742f565a745979715958422f5261394a74756a686d50394334774835694a54326f5a504d665339636d6d534a3951693857714150513379364754557967317a5a6e373534513372704451704473494d6f7632484e482b386b613676674864745763527a4b6d4d315a62664d67764d314551433578694e49555449694f306a706d3436554e656e4b676457696f734e672f57697178776d4d50554f4c324337584c7a2b394265312f64775142314b7a69796e632b457a514d3352767265734c304a47773137636a517a3965484e4352474c34515a386773486165564a39443171513564456b2f5131734759466b4a64484e4236434e4563436559683848462b4c2b3859756a34426e517a6f6c347346756f314a433065777551765564666934797a337a452b71756856387a68526e547153544d65487555514538737061336641504945715337555542336f6d3345723351667875673542313235313677507271706e4546564d3337677a55696e4774336465734f4b394464617375706e3355745830557236396774535648645731505774576e315654313675576867443448432f2b534974696f675035586741454147435645564274794b444d41414141415355564f524b35435949493d	2012-06-12 12:18:09.4383	pt_PT	t	Europe/Lisbon	\N	\N	f	t	20160829	MIICWwIBAAKBgQCUrNpRSBAG/RT9DAJ1R9dg1Az3+p2HmjizZL/vlZVYo7mAo2UFRYFI7Y8mc+SgtYwMIzp+hXZAFrpvx0e5NJPnnAqQGecE2jvZUQ0EQJfmNme+hVP6TcBeIspIhftXbjRs2xgljoKga3bDLiah7sS2VC2NNe3zPqGItPWDEFc0yQIDAQABAoGAAnKiGYp9MRBDozLqa3HmWuLC3+ZRZ6UjX9i9zD0DO3VenX6TMDYHveKjY7euwPKcPqrp0KFz4/Q715FJXgQ+lyAu3+LAcJ1ijGaM4Yl+rZrZMMm2k+t8u5VCbgFnNap4uzhIhbLEPT2JQ12Rww4lTSwTizMXlP5/FS+7EpSbIbECQQDFhDeKNZhQNeeSZLDd609C1x4thJNSOpGwlg6c1pknGGvuhwMv6iWzfFKp1+ieBvtbITbzaKBxeS4jSGGbvGkFAkEAwLJ1mGTwu5I2w1X6Fna1br/tPK0WTL8ytKIDYZ5wiH98xMTcT20PS263+Ih3YUO0ei7pNUlG64IcsHVNL95X9QJAEmY7qkNN2gL7fHamxzV5X7ecVw8njhxon/OKju+quqqau1CWams8cdjd9nZnc/kghx+z977CW2+3bY/7j79gZQJAFBsKtgniLFAHMr5nx6w/Jf0Ujb4pk3xnl/1HiQn1B+j1Zbp8mjTw4Zf9zgq/GgDsdcsrPgoVQkFjKO40TYhPeQJACBm7nHt5Qy04nQ9kgIOCt+sG2963PJ3GYDOjC8EwTiwhZsgdjwyCjaBFr7BHsLm5NwoiDQuxjqYujvCelQ0/FQ==	MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCUrNpRSBAG/RT9DAJ1R9dg1Az3+p2HmjizZL/vlZVYo7mAo2UFRYFI7Y8mc+SgtYwMIzp+hXZAFrpvx0e5NJPnnAqQGecE2jvZUQ0EQJfmNme+hVP6TcBeIspIhftXbjRs2xgljoKga3bDLiah7sS2VC2NNe3zPqGItPWDEFc0yQIDAQAB	f	{"highlight":"#e60013","topbar":"#474747"}	-99	5	7	10	\N
\.


--
-- Data for Name: profissional_email_alias_destiny; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_email_alias_destiny (email_id, email) FROM stdin;
\.


--
-- Data for Name: profissional_email_aliases; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_email_aliases (email_id, maildrop, type, maildrop_array, tag_subject, maildrop_definition, permitted_senders_definition, maildrop_group_list_array) FROM stdin;
\.


--
-- Data for Name: profissional_email_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_email_groups (id, group_id, email_id) FROM stdin;
\.


--
-- Data for Name: profissional_email_marketing; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_email_marketing (id, parent, active, first_name, last_name, username, password, email) FROM stdin;
\.


--
-- Data for Name: profissional_email_user_credential; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_email_user_credential (id, email_id, last_update, type, hash, name) FROM stdin;
\.


--
-- Data for Name: profissional_email_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_email_users (email_id, password, last_access, type, quota, homedir, creation_time, apikey, blocked_contents, mailbox, imapserver, smtpserver, must_change_password, product_id, pop3_disabled, outbound_volume, webmail_disabled) FROM stdin;
1	{SSHA}8x3wGvXryaFvGWWTg/7fln+VK65hMzkzYzA5MTVj	\N	u	10485760	/mnt/email/vmail/sooma.com/sergio.carvalho	2012-07-31 19:01:08.315797	48a33eb80fdf068adc689e8715d019a8	a:0:{}	maildir:~/maildir	127.0.0.1	smtpin:127.0.0.1	f	1	f	normal	f
\.


--
-- Data for Name: profissional_emails; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_emails (id, email, parent, active, type, username, sync_guid, receive_password, permitted_senders) FROM stdin;
1	sergio.carvalho@sooma.com	1	t	u	sergio.carvalho	\N	\N	\N
\.


--
-- Data for Name: profissional_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_groups (id, name, parent) FROM stdin;
\.


--
-- Data for Name: profissional_invoice_header; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_invoice_header (id, date, nif, name) FROM stdin;
\.


--
-- Data for Name: profissional_invoice_line; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_invoice_line (id, reference, description, quantity) FROM stdin;
\.


--
-- Data for Name: profissional_logs; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_logs (id, type, element_id, code, description, owner, "time", reseller, client, domain, description_id, element_name) FROM stdin;
\.


--
-- Data for Name: profissional_mailmarketing_products; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_mailmarketing_products (id, quota) FROM stdin;
\.


--
-- Data for Name: profissional_mailmarketing_products_sold; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_mailmarketing_products_sold (product_id, type, element_id, quota) FROM stdin;
\.


--
-- Data for Name: profissional_products; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_products (id, quota, name) FROM stdin;
1	10485760	10GB
2	26214400	25GB
3	1048576	1GB
4	5242880	5GB
5	52428800	50GB
6	3145728	3GB
7	104857600	100GB
8	5242880	5GB (base)
9	7864320	7.5GB
\.


--
-- Data for Name: profissional_products_sold; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_products_sold (product_id, type, element_id, quota) FROM stdin;
\.


--
-- Data for Name: profissional_resellers; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_resellers (id, name, active, logo, creation_time, offer, offer_reason, nif, webmaildomain, theme_colors) FROM stdin;
1	Sooma	t	\\x646174613a696d6167652f706e673b6261736536342c6956424f5277304b47676f414141414e5355684555674141414c51414141416f43415941414142586164414b41414141426d4a4c523051412f77442f41502b6776616554414141414358424957584d41414173544141414c457745416d707759414141414233524a54555548336763524451596b334f547245514141434c564a52454655654e72746e486d5146385556787a2b2f6257445863447371527a534163664549756c3549454167427454775144306f70705377354a47567461636f794b6a456d58706a53556c4568436f556b7076424152594d5237777444496b53686a466e4c6731676d49724b3679446f4949724b4976542f2f6d4465316e62466e356e653679342f2b566d334e2f50716337766564312b2b39376c6c7763484277634f6959794c52487037355341344536594469776e7a7a485775447677427050362f564f4e4134646e74432b5574584173384450552f7065346d6c396c684f505134636c744b2f556163436a514a6363717a5144777a7974317a6f784f58516f5176744b545149574656433146646a583037724a6963716851784461562b6f77344d30696d6e67544f4d4c544f757645355a4347716a49534f654d72745366775270464e3151476e4f564535744c75473970563641686966554b514a2b417a49417673416657504b6266613037753345356443654776727347444b4870734d49594a436e39574765316e5641662b41764d633331387058617a346e4c495656442b30714e416b34736362745a34414b676e795876632b4241542b766d6d4265684b555a546a2f533058756c453570434554754a30505158302b4a37365044324f7a49495059776a6432596e4c4964586b384c542b41686741665055393944664c302f71564a456353714335786e324f416575416b4a2b376478496232744e344d6c48746e62687677757878576a446862755357507676594748685454353256674873454f5a525a6f414834424b43662b436e594b506132664263347059312b7250613133704a5135484e67724a752b544850765a413367504f46642b6677467341725953624e545541517541695537384652376c384c5265444478647072352b6d524956715359346e475444466b2f726a334c735a796f5168766a4f6c426645412f6f496d56644c33714e4f2f4a58704642496839616d2b5571754159324c7174414a2f41443469397a68326a6166314f796c6c72684474616b4e39486d4f3658713472674d654e394f3341323841776354432f63654b76504752697447553367764261703568367a5a37572b35547149564b32787a38462b7557783952325765786b347a6f6c344e7a5935444333394a544259744c485636664b56657246455a4f344f4a4d5758352b5a356a754d5a755934466a6e4969646a444a4e7446584b70767764306552375666375371314c614839644163332b524c52307131796e4a4a6779536569655a2f6d75655a61764a76346f6262637950756475542b724c553067396f5969326c796130322b6f72565674673077384c6d63322f71386e744c505a56527032766746386c2b416f4b754e386f76786e37726d745834486c674e4d45572f372b4e4f69386142423470305a777762794832384f4c70774a72492b4a593574755a4f764c6b7070423554514a767a55396f3875636a4850735643366d324730786a314a61714264793131737344724e724f4c4942786f4b2f2f6e534e6d2b346f53756a796e6642437950795775302b444c5a6d4c38314f63374e455256457a334d4c49585447562b716442504a74385a58716e556437343150496646634a42337746734334692b4263734a506d483548304a54414d474170634457744b584747553747323139444977444467426d47656b7a493454655962512f517a52317662786b595a33334366594342674533474f6c544938393641544342746c335643564a75422f627a4d796271434d4b5a2b574163554e7542534478533571424b56754f434e66576d42424a75393558716c454d62783653512b59557954634970774e63475357595965554f4e39474d6a39513478386b4b6359556b4c6362576864577373684934536271476b613735376e7559357966746a44755062494730636b6c4c7553686c7630644777646f374f5a635345764430317970474145516c354e5153486e4a4c49334557456c43535538584b6d6f395234426a6a492b48327a6352392b514e41452f444e5337372b6968614674647a4573503866537a773341546f4b4e484a756a324251546c636c616f6b72684a746550492b6d6e796f72796d576a384271426e6a764e77754b77452b61436a665332554e666a376573474539725265593946674a6b37306c5a6f62512b597159434e747533685262416347656c72764b4f506e566839456942775366452b354e73644d336b3635333165753466613848394e5069326951584f59333655784a4a7775684a674250696e4a70414f3454375a2f726163536669764e6142557748486744756b623736413563615a532b544b4d6f302b543157306d34462f6762304d735a774a6643516d4631544c50314f497a68797345543844344266417a644b76636d79756a306465595a524d736248784545487546506d7045706b577253546545754b32544452557565786c44724453305261425351356c4c4d4e637948556f42636d6d42412f45414a6b6753475364713338586d347033394f496b5053306d42773270795972546d4d30584865704a5949526d69486a436a4135756844736f414a6354504356454f49766e43483337386c3141484354334d2b54363233416b58492f474c6862377538782b6a6a5a45756e354c66417a77794739526c37343255615a52794b7248474b435852567042385070486870316341763659735854656f6259666e4659374373313143447a64536d4f79486d6531712b57694e4150797a4b2b544c515245567535336a416c74736e397655615a425a453639776f7847776d327a674757796e553063456b6b50506376597a5859576f5a564a6c784e316c746570445430416c347a58754b4e63763835775a4541674d55796a67754233305461506f693262305237472b542f324f6a6a5150352f317a63446e432b45766f54674b366266533771705864645a786a4b48344e526b69473569326f596d3031476962496f6a74474136775748384f4b7a306c6572684b7a56574e466f6337766530586c524337547a4d574235666c626a7558584b2f577253554269595a7a6b364c4c4f5551484331744175614c774d38796f69556847677a76657261513545387975614739657a7a784f363346494878686c677642526f684a564a4e44335a364758643461435547477a766769344744616a75734f4150346e393431476e56715a68366a5a5643757268556e6f4434544563795436452f6239746c477532654a6e6444664d765443365643504b4b5051484e705979507433565632704467686d78795664715a384c47795a4e6c4548686e736366695972566252574132544971706333784d2b54746a796b666237356467307078763545564e6a686d5376734a4936324870723955777059596b7a4d327868743037465467422b42484249613471517775615233556e69316d5541573478306d635a64767444424f646d2b6c7563366a4379636848426a7531433430557839792f4f4d2b374e6c5348307956614a626434484f467253506978354f4b61492f377652434e523657726451506f77534c62612f4c476e76536e51674358754a655451512b412f77424c416c6f66786757513336415739682f39413349304c344f6d6175526b7366445a6249305a476934545a456e4d56364964426259695a30455932314b6d466c3643356d5670682f6b76547865475456376d755175713834767a746c6a4b4832504654364e6e32427a574c577a625430505562714c35566e3643312b5266696c56422b43673268686e2b4634683068667a386c7a6235507874386a63764648792b4b4b763148484153336c55325172306c304e51447057466d654c307451744b386d384d504b325845657971355972686a7377566854734d4233704a78597a4b562b71764b614735724b2f554643662f69734d6763667750614f3848795a53423149334144324f7935336c61582b546b3737417245647154554572556e486e4e303371346d334b485859725151757242424448474d4b797a31744e36667a6664447275795054335a734a76642f36567a71416853542f65564f74544e68494f4467304d422b42594a444644756553346e5a4141414141424a52553545726b4a6767673d3d	2012-06-11 18:16:31	\N	\N	0	\N	\N
\.


--
-- Data for Name: profissional_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_schema_info (version) FROM stdin;
\.


--
-- Data for Name: profissional_sendas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_sendas (id, authorized_by, authorizes) FROM stdin;
\.


--
-- Data for Name: profissional_stats; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.profissional_stats (email, type, hour, value) FROM stdin;
\.


--
-- Data for Name: profissional_sync_domains; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_sync_domains (domain_id, imap_from, imap_to, master_password_from, master_password_to) FROM stdin;
\.


--
-- Data for Name: profissional_sync_queue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_sync_queue (id, email_from, password_from, state, email_to, password_to, imap_from, imap_to, last_sync_ts, imapsync_extra_options) FROM stdin;
\.


--
-- Data for Name: profissional_ticketgranting; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_ticketgranting (email, hash, "timestamp") FROM stdin;
\.


--
-- Data for Name: profissional_timestamp_domains; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.profissional_timestamp_domains (id) FROM stdin;
\.


--
-- Data for Name: rampage_objects; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_objects (object_id, object_name, type_id) FROM stdin;
\.


--
-- Data for Name: rampage_tag_stats; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_tag_stats (tag_id, count) FROM stdin;
\.


--
-- Data for Name: rampage_tagged; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_tagged (user_id, object_id, tag_id, created) FROM stdin;
\.


--
-- Data for Name: rampage_tags; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_tags (tag_id, tag_name) FROM stdin;
\.


--
-- Data for Name: rampage_types; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_types (type_id, type_name) FROM stdin;
\.


--
-- Data for Name: rampage_user_tag_stats; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_user_tag_stats (user_id, tag_id, count) FROM stdin;
\.


--
-- Data for Name: rampage_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.rampage_users (user_id, user_name) FROM stdin;
\.


--
-- Data for Name: sybil_contact; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.sybil_contact (contact_id, contact_idowner, contact_idcard, contact_firstname, contact_lastname, contact_middlenames, contact_nameprefix, contact_namesuffix, contact_gender, contact_nickname, contact_notes, contact_mainemail, contact_mainphone, contact_type, contact_cardphoto_name, contact_pgppublickey, contact_smimepublickey, contact_birthday, contact_alternativeemail, contact_company, contact_jobposition, contact_addressbook, contact_freebusy) FROM stdin;
\.


--
-- Data for Name: sybil_contactemail; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.sybil_contactemail (contactemail_id, contactemail_contact_id, contactemail_email, contactemail_type) FROM stdin;
\.


--
-- Data for Name: sybil_contactim; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.sybil_contactim (contactim_id, contactim_contact_id, contactim_im, contactim_type, contactim_client) FROM stdin;
\.


--
-- Data for Name: sybil_contactphone; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.sybil_contactphone (contactphone_id, contactphone_contact_id, contactphone_phone, contactphone_type, contactphone_model) FROM stdin;
\.


--
-- Data for Name: temp; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.temp (email) FROM stdin;
\.


--
-- Data for Name: turba_objects; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_objects (object_id, owner_id, object_type, object_uid, object_members, object_firstname, object_lastname, object_middlenames, object_nameprefix, object_namesuffix, object_alias, object_photo, object_phototype, object_bday, object_homestreet, object_homepob, object_homecity, object_homeprovince, object_homepostalcode, object_homecountry, object_workstreet, object_workpob, object_workcity, object_workprovince, object_workpostalcode, object_workcountry, object_tz, object_geo, object_email, object_homephone, object_workphone, object_cellphone, object_fax, object_pager, object_title, object_role, object_logo, object_logotype, object_company, object_notes, object_url, object_freebusyurl, object_pgppublickey, object_smimepublickey, object_anniversary, object_department, object_spouse, object_homefax, object_nickname, object_assistantphone, object_imaddress, object_imaddress2, object_imaddress3, object_homephone2, object_carphone, object_workphone2, object_radiophone, object_companyphone, object_otherstreet, object_otherpob, object_othercity, object_otherprovince, object_otherpostalcode, object_othercountry, object_yomifirstname, object_yomilastname, object_manager, object_assistant, object_workemail, object_homeemail, object_photoorig) FROM stdin;
\.


--
-- Data for Name: turba_schema_info; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_schema_info (version) FROM stdin;
\.


--
-- Data for Name: turba_shares; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_shares (share_id, share_name, share_owner, share_flags, perm_creator, perm_default, perm_guest, attribute_name, attribute_desc, attribute_params, share_parents) FROM stdin;
\.


--
-- Data for Name: turba_shares_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_shares_groups (id, share_id, group_uid, perm) FROM stdin;
\.


--
-- Data for Name: turba_shares_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_shares_users (id, share_id, user_uid, perm) FROM stdin;
\.


--
-- Data for Name: turba_sharesng; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_sharesng (share_id, share_name, share_owner, share_flags, perm_creator_2, perm_creator_4, perm_creator_8, perm_creator_16, perm_default_2, perm_default_4, perm_default_8, perm_default_16, perm_guest_2, perm_guest_4, perm_guest_8, perm_guest_16, attribute_name, attribute_desc, attribute_params, share_parents) FROM stdin;
\.


--
-- Data for Name: turba_sharesng_groups; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_sharesng_groups (share_id, group_uid, perm_2, perm_4, perm_8, perm_16) FROM stdin;
\.


--
-- Data for Name: turba_sharesng_users; Type: TABLE DATA; Schema: public; Owner: horde
--

COPY public.turba_sharesng_users (share_id, user_uid, perm_2, perm_4, perm_8, perm_16) FROM stdin;
\.


--
-- Name: mailaddr_id_seq; Type: SEQUENCE SET; Schema: amavis; Owner: postgres
--

SELECT pg_catalog.setval('amavis.mailaddr_id_seq', 1, false);


--
-- Name: policy_id_seq; Type: SEQUENCE SET; Schema: amavis; Owner: postgres
--

SELECT pg_catalog.setval('amavis.policy_id_seq', 1, false);


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: invoicexpress; Owner: postgres
--

SELECT pg_catalog.setval('invoicexpress.invoice_id_seq', 1, false);


--
-- Name: invoiceline_id_seq; Type: SEQUENCE SET; Schema: invoicexpress; Owner: postgres
--

SELECT pg_catalog.setval('invoicexpress.invoiceline_id_seq', 1, false);


--
-- Name: reseller_id_seq; Type: SEQUENCE SET; Schema: invoicexpress; Owner: postgres
--

SELECT pg_catalog.setval('invoicexpress.reseller_id_seq', 1, false);


--
-- Name: timestamp_queue_id_seq; Type: SEQUENCE SET; Schema: postfix; Owner: postgres
--

SELECT pg_catalog.setval('postfix.timestamp_queue_id_seq', 1, false);


--
-- Name: smtp_bind_address_id_seq; Type: SEQUENCE SET; Schema: postfix_submission; Owner: postfix
--

SELECT pg_catalog.setval('postfix_submission.smtp_bind_address_id_seq', 1, false);


--
-- Name: horde_alarms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_alarms_id_seq', 1, false);


--
-- Name: horde_groups_group_uid_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_groups_group_uid_seq', 1, false);


--
-- Name: horde_histories_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_histories_history_id_seq', 1, false);


--
-- Name: horde_histories_modseq_history_modseq_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_histories_modseq_history_modseq_seq', 1, false);


--
-- Name: horde_imap_client_data_messageid_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_imap_client_data_messageid_seq', 1, false);


--
-- Name: horde_muvfs_vfs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_muvfs_vfs_id_seq', 1, false);


--
-- Name: horde_perms_perm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_perms_perm_id_seq', 1, false);


--
-- Name: horde_queue_tasks_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_queue_tasks_task_id_seq', 1, false);


--
-- Name: horde_vfs_vfs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.horde_vfs_vfs_id_seq', 1, false);


--
-- Name: imp_sentmail_sentmail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.imp_sentmail_sentmail_id_seq', 1, false);


--
-- Name: ingo_rules_rule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.ingo_rules_rule_id_seq', 1, false);


--
-- Name: ingo_shares_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.ingo_shares_groups_id_seq', 1, false);


--
-- Name: ingo_shares_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.ingo_shares_share_id_seq', 1, false);


--
-- Name: ingo_shares_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.ingo_shares_users_id_seq', 1, false);


--
-- Name: ingo_sharesng_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.ingo_sharesng_share_id_seq', 1, false);


--
-- Name: kronolith_resources_resource_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_resources_resource_id_seq', 1, false);


--
-- Name: kronolith_shares_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_shares_groups_id_seq', 1, false);


--
-- Name: kronolith_shares_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_shares_share_id_seq', 1, false);


--
-- Name: kronolith_shares_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_shares_users_id_seq', 1, false);


--
-- Name: kronolith_sharesng_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_sharesng_share_id_seq', 1, false);


--
-- Name: kronolith_storage_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.kronolith_storage_id_seq', 1, false);


--
-- Name: profissional_clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_clients_id_seq', 1, true);


--
-- Name: profissional_domain_filters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_domain_filters_id_seq', 1, false);


--
-- Name: profissional_domain_notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_domain_notifications_id_seq', 1, false);


--
-- Name: profissional_domains_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_domains_id_seq', 1, true);


--
-- Name: profissional_email_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_email_groups_id_seq', 1, false);


--
-- Name: profissional_email_marketing_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_email_marketing_id_seq', 1, false);


--
-- Name: profissional_email_user_credential_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_email_user_credential_id_seq', 1, false);


--
-- Name: profissional_emails_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_emails_id_seq', 1, true);


--
-- Name: profissional_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_groups_id_seq', 1, false);


--
-- Name: profissional_invoice_header_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_invoice_header_id_seq', 1, false);


--
-- Name: profissional_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_logs_id_seq', 1, false);


--
-- Name: profissional_mailmarketing_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_mailmarketing_products_id_seq', 1, false);


--
-- Name: profissional_products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_products_id_seq', 9, true);


--
-- Name: profissional_resellers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.profissional_resellers_id_seq', 1, true);


--
-- Name: profissional_sendas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_sendas_id_seq', 1, false);


--
-- Name: profissional_sync_queue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.profissional_sync_queue_id_seq', 1, false);


--
-- Name: rampage_objects_object_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.rampage_objects_object_id_seq', 1, false);


--
-- Name: rampage_tags_tag_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.rampage_tags_tag_id_seq', 1, false);


--
-- Name: rampage_types_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.rampage_types_type_id_seq', 1, false);


--
-- Name: rampage_users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.rampage_users_user_id_seq', 1, false);


--
-- Name: sybil_contact_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.sybil_contact_seq', 1, false);


--
-- Name: sybil_contactemail_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.sybil_contactemail_seq', 1, false);


--
-- Name: sybil_contactim_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.sybil_contactim_seq', 1, false);


--
-- Name: sybil_contactphone_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.sybil_contactphone_seq', 1, false);


--
-- Name: turba_shares_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.turba_shares_groups_id_seq', 1, false);


--
-- Name: turba_shares_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.turba_shares_share_id_seq', 1, false);


--
-- Name: turba_shares_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.turba_shares_users_id_seq', 1, false);


--
-- Name: turba_sharesng_share_id_seq; Type: SEQUENCE SET; Schema: public; Owner: horde
--

SELECT pg_catalog.setval('public.turba_sharesng_share_id_seq', 1, false);


--
-- Name: mailaddr mailaddr_email_key; Type: CONSTRAINT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.mailaddr
    ADD CONSTRAINT mailaddr_email_key UNIQUE (email);


--
-- Name: mailaddr mailaddr_pkey; Type: CONSTRAINT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.mailaddr
    ADD CONSTRAINT mailaddr_pkey PRIMARY KEY (id);


--
-- Name: policy policy_pkey; Type: CONSTRAINT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.policy
    ADD CONSTRAINT policy_pkey PRIMARY KEY (id);


--
-- Name: wblist wblist_pkey; Type: CONSTRAINT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.wblist
    ADD CONSTRAINT wblist_pkey PRIMARY KEY (rid, sid);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (reseller, profissional_client);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: invoice invoice_unique_reseller_profissional_client_date; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoice
    ADD CONSTRAINT invoice_unique_reseller_profissional_client_date UNIQUE (reseller, profissional_client, date);


--
-- Name: invoiceline invoiceline_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoiceline
    ADD CONSTRAINT invoiceline_pkey PRIMARY KEY (id);


--
-- Name: invoiceline invoiceline_unique_invoice_product; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoiceline
    ADD CONSTRAINT invoiceline_unique_invoice_product UNIQUE (invoice, profissional_product);


--
-- Name: item item_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (reseller, profissional_product);


--
-- Name: reseller reseller_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.reseller
    ADD CONSTRAINT reseller_pkey PRIMARY KEY (id);


--
-- Name: usagemeter usagemeter_pkey; Type: CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.usagemeter
    ADD CONSTRAINT usagemeter_pkey PRIMARY KEY (date, product, client);


--
-- Name: ldap_attr_mappings ldap_attr_mappings_pkey; Type: CONSTRAINT; Schema: openldap; Owner: openldap
--

ALTER TABLE ONLY openldap.ldap_attr_mappings
    ADD CONSTRAINT ldap_attr_mappings_pkey PRIMARY KEY (id);


--
-- Name: ldap_oc_mappings ldap_oc_mappings_pkey; Type: CONSTRAINT; Schema: openldap; Owner: openldap
--

ALTER TABLE ONLY openldap.ldap_oc_mappings
    ADD CONSTRAINT ldap_oc_mappings_pkey PRIMARY KEY (id);


--
-- Name: timestamp_queue timestamp_queue_pkey; Type: CONSTRAINT; Schema: postfix; Owner: postgres
--

ALTER TABLE ONLY postfix.timestamp_queue
    ADD CONSTRAINT timestamp_queue_pkey PRIMARY KEY (id);


--
-- Name: smtp_bind_address smtp_bind_address_pkey; Type: CONSTRAINT; Schema: postfix_submission; Owner: postfix
--

ALTER TABLE ONLY postfix_submission.smtp_bind_address
    ADD CONSTRAINT smtp_bind_address_pkey PRIMARY KEY (id);


--
-- Name: sybil_contact contact_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contact
    ADD CONSTRAINT contact_pkey PRIMARY KEY (contact_id);


--
-- Name: sybil_contactemail contactemail_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactemail
    ADD CONSTRAINT contactemail_pkey PRIMARY KEY (contactemail_id);


--
-- Name: sybil_contactim contactim_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactim
    ADD CONSTRAINT contactim_pkey PRIMARY KEY (contactim_id);


--
-- Name: sybil_contactphone contactphone_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.sybil_contactphone
    ADD CONSTRAINT contactphone_pkey PRIMARY KEY (contactphone_id);


--
-- Name: horde_activesync_device horde_activesync_device_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horde_activesync_device
    ADD CONSTRAINT horde_activesync_device_pkey PRIMARY KEY (device_id);


--
-- Name: horde_activesync_state horde_activesync_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horde_activesync_state
    ADD CONSTRAINT horde_activesync_state_pkey PRIMARY KEY (sync_key);


--
-- Name: horde_alarms horde_alarms_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_alarms
    ADD CONSTRAINT horde_alarms_pkey PRIMARY KEY (id);


--
-- Name: horde_cache horde_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_cache
    ADD CONSTRAINT horde_cache_pkey PRIMARY KEY (cache_id);


--
-- Name: horde_groups horde_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_groups
    ADD CONSTRAINT horde_groups_pkey PRIMARY KEY (group_uid);


--
-- Name: horde_histories_modseq horde_histories_modseq_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_histories_modseq
    ADD CONSTRAINT horde_histories_modseq_pkey PRIMARY KEY (history_modseq);


--
-- Name: horde_histories horde_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_histories
    ADD CONSTRAINT horde_histories_pkey PRIMARY KEY (history_id);


--
-- Name: horde_imap_client_data horde_imap_client_data_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_imap_client_data
    ADD CONSTRAINT horde_imap_client_data_pkey PRIMARY KEY (messageid);


--
-- Name: horde_locks horde_locks_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_locks
    ADD CONSTRAINT horde_locks_pkey PRIMARY KEY (lock_id);


--
-- Name: horde_muvfs horde_muvfs_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_muvfs
    ADD CONSTRAINT horde_muvfs_pkey PRIMARY KEY (vfs_id);


--
-- Name: horde_perms horde_perms_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_perms
    ADD CONSTRAINT horde_perms_pkey PRIMARY KEY (perm_id);


--
-- Name: horde_prefs horde_prefs_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_prefs
    ADD CONSTRAINT horde_prefs_pkey PRIMARY KEY (pref_uid, pref_scope, pref_name);


--
-- Name: horde_queue_tasks horde_queue_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_queue_tasks
    ADD CONSTRAINT horde_queue_tasks_pkey PRIMARY KEY (task_id);


--
-- Name: horde_sessionhandler horde_sessionhandler_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_sessionhandler
    ADD CONSTRAINT horde_sessionhandler_pkey PRIMARY KEY (session_id);


--
-- Name: horde_signups horde_signups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_signups
    ADD CONSTRAINT horde_signups_pkey PRIMARY KEY (user_name);


--
-- Name: horde_tokens horde_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_tokens
    ADD CONSTRAINT horde_tokens_pkey PRIMARY KEY (token_address, token_id);


--
-- Name: horde_users horde_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_users
    ADD CONSTRAINT horde_users_pkey PRIMARY KEY (user_uid);


--
-- Name: horde_vfs horde_vfs_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.horde_vfs
    ADD CONSTRAINT horde_vfs_pkey PRIMARY KEY (vfs_id);


--
-- Name: imp_sentmail imp_sentmail_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.imp_sentmail
    ADD CONSTRAINT imp_sentmail_pkey PRIMARY KEY (sentmail_id);


--
-- Name: ingo_rules ingo_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_rules
    ADD CONSTRAINT ingo_rules_pkey PRIMARY KEY (rule_id);


--
-- Name: ingo_shares_groups ingo_shares_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares_groups
    ADD CONSTRAINT ingo_shares_groups_pkey PRIMARY KEY (id);


--
-- Name: ingo_shares ingo_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares
    ADD CONSTRAINT ingo_shares_pkey PRIMARY KEY (share_id);


--
-- Name: ingo_shares_users ingo_shares_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_shares_users
    ADD CONSTRAINT ingo_shares_users_pkey PRIMARY KEY (id);


--
-- Name: ingo_sharesng ingo_sharesng_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_sharesng
    ADD CONSTRAINT ingo_sharesng_pkey PRIMARY KEY (share_id);


--
-- Name: ingo_spam ingo_spam_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_spam
    ADD CONSTRAINT ingo_spam_pkey PRIMARY KEY (spam_owner);


--
-- Name: ingo_vacations ingo_vacations_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.ingo_vacations
    ADD CONSTRAINT ingo_vacations_pkey PRIMARY KEY (vacation_owner);


--
-- Name: kronolith_events_geo kronolith_events_geo_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_events_geo
    ADD CONSTRAINT kronolith_events_geo_pkey PRIMARY KEY (event_id);


--
-- Name: kronolith_events kronolith_events_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_events
    ADD CONSTRAINT kronolith_events_pkey PRIMARY KEY (event_id);


--
-- Name: kronolith_resources kronolith_resources_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_resources
    ADD CONSTRAINT kronolith_resources_pkey PRIMARY KEY (resource_id);


--
-- Name: kronolith_shares_groups kronolith_shares_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares_groups
    ADD CONSTRAINT kronolith_shares_groups_pkey PRIMARY KEY (id);


--
-- Name: kronolith_shares kronolith_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares
    ADD CONSTRAINT kronolith_shares_pkey PRIMARY KEY (share_id);


--
-- Name: kronolith_shares_users kronolith_shares_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_shares_users
    ADD CONSTRAINT kronolith_shares_users_pkey PRIMARY KEY (id);


--
-- Name: kronolith_sharesng kronolith_sharesng_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_sharesng
    ADD CONSTRAINT kronolith_sharesng_pkey PRIMARY KEY (share_id);


--
-- Name: kronolith_storage kronolith_storage_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.kronolith_storage
    ADD CONSTRAINT kronolith_storage_pkey PRIMARY KEY (id);


--
-- Name: novis_username_map novis_username_map_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.novis_username_map
    ADD CONSTRAINT novis_username_map_pkey PRIMARY KEY (username);


--
-- Name: oa_migration oa_migration_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.oa_migration
    ADD CONSTRAINT oa_migration_pkey PRIMARY KEY (email);


--
-- Name: profissional_client_softsuspend profissional_client_softsuspend_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_client_softsuspend
    ADD CONSTRAINT profissional_client_softsuspend_pkey PRIMARY KEY (id);


--
-- Name: profissional_clients profissional_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_clients
    ADD CONSTRAINT profissional_clients_pkey PRIMARY KEY (id);


--
-- Name: profissional_domain_aliases profissional_domain_alias_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_domain_aliases
    ADD CONSTRAINT profissional_domain_alias_pkey PRIMARY KEY (id);


--
-- Name: profissional_domain_filters profissional_domain_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_filters
    ADD CONSTRAINT profissional_domain_filters_pkey PRIMARY KEY (id);


--
-- Name: profissional_domain_notifications profissional_domain_notifications_domain_purpose_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_notifications
    ADD CONSTRAINT profissional_domain_notifications_domain_purpose_unique UNIQUE (domain, purpose, period_before);


--
-- Name: profissional_domain_notifications profissional_domain_notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_notifications
    ADD CONSTRAINT profissional_domain_notifications_pkey PRIMARY KEY (id);


--
-- Name: profissional_domain_secondary_target profissional_domain_secondary_target_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_secondary_target
    ADD CONSTRAINT profissional_domain_secondary_target_pkey PRIMARY KEY (id);


--
-- Name: profissional_domains profissional_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_domains
    ADD CONSTRAINT profissional_domains_pkey PRIMARY KEY (id);


--
-- Name: profissional_email_alias_destiny profissional_email_alias_destiny_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_alias_destiny
    ADD CONSTRAINT profissional_email_alias_destiny_pkey PRIMARY KEY (email_id, email);


--
-- Name: profissional_email_aliases profissional_email_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_aliases
    ADD CONSTRAINT profissional_email_aliases_pkey PRIMARY KEY (email_id);


--
-- Name: profissional_email_groups profissional_email_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_groups
    ADD CONSTRAINT profissional_email_groups_pkey PRIMARY KEY (id);


--
-- Name: profissional_email_marketing profissional_email_marketing_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_marketing
    ADD CONSTRAINT profissional_email_marketing_email_key UNIQUE (email);


--
-- Name: profissional_email_marketing profissional_email_marketing_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_marketing
    ADD CONSTRAINT profissional_email_marketing_pkey PRIMARY KEY (id);


--
-- Name: profissional_email_marketing profissional_email_marketing_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_marketing
    ADD CONSTRAINT profissional_email_marketing_username_key UNIQUE (username);


--
-- Name: profissional_email_users profissional_email_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_users
    ADD CONSTRAINT profissional_email_users_pkey PRIMARY KEY (email_id);


--
-- Name: profissional_emails profissional_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_emails
    ADD CONSTRAINT profissional_emails_pkey PRIMARY KEY (id);


--
-- Name: profissional_groups profissional_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_groups
    ADD CONSTRAINT profissional_groups_pkey PRIMARY KEY (id);


--
-- Name: profissional_invoice_header profissional_invoice_header_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_invoice_header
    ADD CONSTRAINT profissional_invoice_header_pkey PRIMARY KEY (id);


--
-- Name: profissional_logs profissional_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_logs
    ADD CONSTRAINT profissional_logs_pkey PRIMARY KEY (id);


--
-- Name: profissional_mailmarketing_products profissional_mailmarketing_products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_mailmarketing_products
    ADD CONSTRAINT profissional_mailmarketing_products_pkey PRIMARY KEY (id);


--
-- Name: profissional_products profissional_products_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_products
    ADD CONSTRAINT profissional_products_pkey PRIMARY KEY (id);


--
-- Name: profissional_resellers profissional_resellers_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_resellers
    ADD CONSTRAINT profissional_resellers_pkey PRIMARY KEY (id);


--
-- Name: profissional_sendas profissional_sendas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sendas
    ADD CONSTRAINT profissional_sendas_pkey PRIMARY KEY (id);


--
-- Name: profissional_sendas profissional_sendas_unique_authorized_by_authorizes; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sendas
    ADD CONSTRAINT profissional_sendas_unique_authorized_by_authorizes UNIQUE (authorized_by, authorizes);


--
-- Name: profissional_stats profissional_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_stats
    ADD CONSTRAINT profissional_stats_pkey PRIMARY KEY (email, type, hour);


--
-- Name: profissional_sync_domains profissional_sync_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sync_domains
    ADD CONSTRAINT profissional_sync_domains_pkey PRIMARY KEY (domain_id);


--
-- Name: profissional_sync_queue profissional_sync_queue_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sync_queue
    ADD CONSTRAINT profissional_sync_queue_email_key UNIQUE (email_from);


--
-- Name: profissional_sync_queue profissional_sync_queue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sync_queue
    ADD CONSTRAINT profissional_sync_queue_pkey PRIMARY KEY (id);


--
-- Name: profissional_ticketgranting profissional_ticketgranting_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_ticketgranting
    ADD CONSTRAINT profissional_ticketgranting_pkey PRIMARY KEY (hash);


--
-- Name: profissional_timestamp_domains profissional_timestamp_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_timestamp_domains
    ADD CONSTRAINT profissional_timestamp_domains_pkey PRIMARY KEY (id);


--
-- Name: rampage_objects rampage_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_objects
    ADD CONSTRAINT rampage_objects_pkey PRIMARY KEY (object_id);


--
-- Name: rampage_tag_stats rampage_tag_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_tag_stats
    ADD CONSTRAINT rampage_tag_stats_pkey PRIMARY KEY (tag_id);


--
-- Name: rampage_tagged rampage_tagged_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_tagged
    ADD CONSTRAINT rampage_tagged_pkey PRIMARY KEY (user_id, object_id, tag_id);


--
-- Name: rampage_tags rampage_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_tags
    ADD CONSTRAINT rampage_tags_pkey PRIMARY KEY (tag_id);


--
-- Name: rampage_types rampage_types_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_types
    ADD CONSTRAINT rampage_types_pkey PRIMARY KEY (type_id);


--
-- Name: rampage_user_tag_stats rampage_user_tag_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_user_tag_stats
    ADD CONSTRAINT rampage_user_tag_stats_pkey PRIMARY KEY (user_id, tag_id);


--
-- Name: rampage_users rampage_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.rampage_users
    ADD CONSTRAINT rampage_users_pkey PRIMARY KEY (user_id);


--
-- Name: turba_objects turba_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_objects
    ADD CONSTRAINT turba_objects_pkey PRIMARY KEY (object_id);


--
-- Name: turba_shares_groups turba_shares_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares_groups
    ADD CONSTRAINT turba_shares_groups_pkey PRIMARY KEY (id);


--
-- Name: turba_shares turba_shares_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares
    ADD CONSTRAINT turba_shares_pkey PRIMARY KEY (share_id);


--
-- Name: turba_shares_users turba_shares_users_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_shares_users
    ADD CONSTRAINT turba_shares_users_pkey PRIMARY KEY (id);


--
-- Name: turba_sharesng turba_sharesng_pkey; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.turba_sharesng
    ADD CONSTRAINT turba_sharesng_pkey PRIMARY KEY (share_id);


--
-- Name: profissional_products_sold unique_product_id_type_element; Type: CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_products_sold
    ADD CONSTRAINT unique_product_id_type_element UNIQUE (product_id, type, element_id);


--
-- Name: recursive_aliases_alias_mail_destination_idx; Type: INDEX; Schema: postfix; Owner: postgres
--

CREATE UNIQUE INDEX recursive_aliases_alias_mail_destination_idx ON postfix.recursive_aliases USING btree (alias_mail, destination);


--
-- Name: recursive_aliases_alias_mail_idx; Type: INDEX; Schema: postfix; Owner: postgres
--

CREATE INDEX recursive_aliases_alias_mail_idx ON postfix.recursive_aliases USING btree (alias_mail);


--
-- Name: contact_idowner_idx; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX contact_idowner_idx ON public.sybil_contact USING btree (contact_idowner);


--
-- Name: fki_cardphotoid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX fki_cardphotoid ON public.sybil_contact USING btree (contact_cardphoto_name);


--
-- Name: fki_contactid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX fki_contactid ON public.sybil_contactemail USING btree (contactemail_contact_id);


--
-- Name: horde_activesync_cache_on_cache_devid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_cache_on_cache_devid ON public.horde_activesync_cache USING btree (cache_devid);


--
-- Name: horde_activesync_cache_on_cache_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_cache_on_cache_user ON public.horde_activesync_cache USING btree (cache_user);


--
-- Name: horde_activesync_device_users_on_device_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_device_users_on_device_id ON public.horde_activesync_device_users USING btree (device_id);


--
-- Name: horde_activesync_device_users_on_device_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_device_users_on_device_user ON public.horde_activesync_device_users USING btree (device_user);


--
-- Name: horde_activesync_mailmap_on_message_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_mailmap_on_message_uid ON public.horde_activesync_mailmap USING btree (message_uid);


--
-- Name: horde_activesync_mailmap_on_sync_devid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_mailmap_on_sync_devid ON public.horde_activesync_mailmap USING btree (sync_devid);


--
-- Name: horde_activesync_mailmap_on_sync_folderid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_mailmap_on_sync_folderid ON public.horde_activesync_mailmap USING btree (sync_folderid);


--
-- Name: horde_activesync_map_on_message_uid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_map_on_message_uid ON public.horde_activesync_map USING btree (message_uid);


--
-- Name: horde_activesync_map_on_sync_devid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_map_on_sync_devid ON public.horde_activesync_map USING btree (sync_devid);


--
-- Name: horde_activesync_map_on_sync_user; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_map_on_sync_user ON public.horde_activesync_map USING btree (sync_user);


--
-- Name: horde_activesync_state_on_sync_devid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_state_on_sync_devid ON public.horde_activesync_state USING btree (sync_devid);


--
-- Name: horde_activesync_state_on_sync_folderid; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX horde_activesync_state_on_sync_folderid ON public.horde_activesync_state USING btree (sync_folderid);


--
-- Name: index_horde_alarms_on_alarm_dismissed; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_dismissed ON public.horde_alarms USING btree (alarm_dismissed);


--
-- Name: index_horde_alarms_on_alarm_end; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_end ON public.horde_alarms USING btree (alarm_end);


--
-- Name: index_horde_alarms_on_alarm_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_id ON public.horde_alarms USING btree (alarm_id);


--
-- Name: index_horde_alarms_on_alarm_snooze; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_snooze ON public.horde_alarms USING btree (alarm_snooze);


--
-- Name: index_horde_alarms_on_alarm_start; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_start ON public.horde_alarms USING btree (alarm_start);


--
-- Name: index_horde_alarms_on_alarm_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_alarms_on_alarm_uid ON public.horde_alarms USING btree (alarm_uid);


--
-- Name: index_horde_dav_collections_on_id_external; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_horde_dav_collections_on_id_external ON public.horde_dav_collections USING btree (id_external);


--
-- Name: index_horde_dav_collections_on_id_interface; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_dav_collections_on_id_interface ON public.horde_dav_collections USING btree (id_interface);


--
-- Name: index_horde_dav_collections_on_id_internal; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_dav_collections_on_id_internal ON public.horde_dav_collections USING btree (id_internal);


--
-- Name: index_horde_dav_objects_on_id_collection; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_dav_objects_on_id_collection ON public.horde_dav_objects USING btree (id_collection);


--
-- Name: index_horde_dav_objects_on_id_external; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_dav_objects_on_id_external ON public.horde_dav_objects USING btree (id_external);


--
-- Name: index_horde_dav_objects_on_id_external_and_id_collection; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_horde_dav_objects_on_id_external_and_id_collection ON public.horde_dav_objects USING btree (id_external, id_collection);


--
-- Name: index_horde_dav_objects_on_id_internal; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_horde_dav_objects_on_id_internal ON public.horde_dav_objects USING btree (id_internal);


--
-- Name: index_horde_groups_members_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_groups_members_on_group_uid ON public.horde_groups_members USING btree (group_uid);


--
-- Name: index_horde_groups_members_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_groups_members_on_user_uid ON public.horde_groups_members USING btree (user_uid);


--
-- Name: index_horde_groups_on_group_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_horde_groups_on_group_name ON public.horde_groups USING btree (group_name);


--
-- Name: index_horde_histories_on_history_action; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_histories_on_history_action ON public.horde_histories USING btree (history_action);


--
-- Name: index_horde_histories_on_history_modseq; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_histories_on_history_modseq ON public.horde_histories USING btree (history_modseq);


--
-- Name: index_horde_histories_on_history_ts; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_histories_on_history_ts ON public.horde_histories USING btree (history_ts);


--
-- Name: index_horde_histories_on_object_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_histories_on_object_uid ON public.horde_histories USING btree (object_uid);


--
-- Name: index_horde_imap_client_data_on_hostspec_and_mailbox_and_port_a; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_imap_client_data_on_hostspec_and_mailbox_and_port_a ON public.horde_imap_client_data USING btree (hostspec, mailbox, port, username);


--
-- Name: index_horde_imap_client_message_on_msguid_and_messageid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_imap_client_message_on_msguid_and_messageid ON public.horde_imap_client_message USING btree (msguid, messageid);


--
-- Name: index_horde_imap_client_metadata_on_messageid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_imap_client_metadata_on_messageid ON public.horde_imap_client_metadata USING btree (messageid);


--
-- Name: index_horde_muvfs_on_vfs_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_muvfs_on_vfs_name ON public.horde_muvfs USING btree (vfs_name);


--
-- Name: index_horde_muvfs_on_vfs_path; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_muvfs_on_vfs_path ON public.horde_muvfs USING btree (vfs_path);


--
-- Name: index_horde_perms_on_perm_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_horde_perms_on_perm_name ON public.horde_perms USING btree (perm_name);


--
-- Name: index_horde_prefs_on_pref_scope; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_prefs_on_pref_scope ON public.horde_prefs USING btree (pref_scope);


--
-- Name: index_horde_prefs_on_pref_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_prefs_on_pref_uid ON public.horde_prefs USING btree (pref_uid);


--
-- Name: index_horde_sessionhandler_on_session_lastmodified; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_sessionhandler_on_session_lastmodified ON public.horde_sessionhandler USING btree (session_lastmodified);


--
-- Name: index_horde_syncml_anchors_on_syncml_db; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_anchors_on_syncml_db ON public.horde_syncml_anchors USING btree (syncml_db);


--
-- Name: index_horde_syncml_anchors_on_syncml_syncpartner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_anchors_on_syncml_syncpartner ON public.horde_syncml_anchors USING btree (syncml_syncpartner);


--
-- Name: index_horde_syncml_anchors_on_syncml_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_anchors_on_syncml_uid ON public.horde_syncml_anchors USING btree (syncml_uid);


--
-- Name: index_horde_syncml_map_on_syncml_cuid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_map_on_syncml_cuid ON public.horde_syncml_map USING btree (syncml_cuid);


--
-- Name: index_horde_syncml_map_on_syncml_db; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_map_on_syncml_db ON public.horde_syncml_map USING btree (syncml_db);


--
-- Name: index_horde_syncml_map_on_syncml_suid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_map_on_syncml_suid ON public.horde_syncml_map USING btree (syncml_suid);


--
-- Name: index_horde_syncml_map_on_syncml_syncpartner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_map_on_syncml_syncpartner ON public.horde_syncml_map USING btree (syncml_syncpartner);


--
-- Name: index_horde_syncml_map_on_syncml_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_syncml_map_on_syncml_uid ON public.horde_syncml_map USING btree (syncml_uid);


--
-- Name: index_horde_vfs_on_vfs_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_vfs_on_vfs_name ON public.horde_vfs USING btree (vfs_name);


--
-- Name: index_horde_vfs_on_vfs_path; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_horde_vfs_on_vfs_path ON public.horde_vfs USING btree (vfs_path);


--
-- Name: index_imp_sentmail_on_sentmail_success; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_imp_sentmail_on_sentmail_success ON public.imp_sentmail USING btree (sentmail_success);


--
-- Name: index_imp_sentmail_on_sentmail_ts; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_imp_sentmail_on_sentmail_ts ON public.imp_sentmail USING btree (sentmail_ts);


--
-- Name: index_imp_sentmail_on_sentmail_who; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_imp_sentmail_on_sentmail_who ON public.imp_sentmail USING btree (sentmail_who);


--
-- Name: index_ingo_lists_on_list_owner_and_list_blacklist; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_lists_on_list_owner_and_list_blacklist ON public.ingo_lists USING btree (list_owner, list_blacklist);


--
-- Name: index_ingo_rules_on_rule_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_rules_on_rule_owner ON public.ingo_rules USING btree (rule_owner);


--
-- Name: index_ingo_shares_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_groups_on_group_uid ON public.ingo_shares_groups USING btree (group_uid);


--
-- Name: index_ingo_shares_groups_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_groups_on_perm ON public.ingo_shares_groups USING btree (perm);


--
-- Name: index_ingo_shares_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_groups_on_share_id ON public.ingo_shares_groups USING btree (share_id);


--
-- Name: index_ingo_shares_on_perm_creator; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_on_perm_creator ON public.ingo_shares USING btree (perm_creator);


--
-- Name: index_ingo_shares_on_perm_default; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_on_perm_default ON public.ingo_shares USING btree (perm_default);


--
-- Name: index_ingo_shares_on_perm_guest; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_on_perm_guest ON public.ingo_shares USING btree (perm_guest);


--
-- Name: index_ingo_shares_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_on_share_name ON public.ingo_shares USING btree (share_name);


--
-- Name: index_ingo_shares_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_on_share_owner ON public.ingo_shares USING btree (share_owner);


--
-- Name: index_ingo_shares_users_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_users_on_perm ON public.ingo_shares_users USING btree (perm);


--
-- Name: index_ingo_shares_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_users_on_share_id ON public.ingo_shares_users USING btree (share_id);


--
-- Name: index_ingo_shares_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_shares_users_on_user_uid ON public.ingo_shares_users USING btree (user_uid);


--
-- Name: index_ingo_sharesng_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_group_uid ON public.ingo_sharesng_groups USING btree (group_uid);


--
-- Name: index_ingo_sharesng_groups_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_perm_16 ON public.ingo_sharesng_groups USING btree (perm_16);


--
-- Name: index_ingo_sharesng_groups_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_perm_2 ON public.ingo_sharesng_groups USING btree (perm_2);


--
-- Name: index_ingo_sharesng_groups_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_perm_4 ON public.ingo_sharesng_groups USING btree (perm_4);


--
-- Name: index_ingo_sharesng_groups_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_perm_8 ON public.ingo_sharesng_groups USING btree (perm_8);


--
-- Name: index_ingo_sharesng_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_groups_on_share_id ON public.ingo_sharesng_groups USING btree (share_id);


--
-- Name: index_ingo_sharesng_on_perm_creator_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_creator_16 ON public.ingo_sharesng USING btree (perm_creator_16);


--
-- Name: index_ingo_sharesng_on_perm_creator_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_creator_2 ON public.ingo_sharesng USING btree (perm_creator_2);


--
-- Name: index_ingo_sharesng_on_perm_creator_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_creator_4 ON public.ingo_sharesng USING btree (perm_creator_4);


--
-- Name: index_ingo_sharesng_on_perm_creator_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_creator_8 ON public.ingo_sharesng USING btree (perm_creator_8);


--
-- Name: index_ingo_sharesng_on_perm_default_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_default_16 ON public.ingo_sharesng USING btree (perm_default_16);


--
-- Name: index_ingo_sharesng_on_perm_default_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_default_2 ON public.ingo_sharesng USING btree (perm_default_2);


--
-- Name: index_ingo_sharesng_on_perm_default_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_default_4 ON public.ingo_sharesng USING btree (perm_default_4);


--
-- Name: index_ingo_sharesng_on_perm_default_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_default_8 ON public.ingo_sharesng USING btree (perm_default_8);


--
-- Name: index_ingo_sharesng_on_perm_guest_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_guest_16 ON public.ingo_sharesng USING btree (perm_guest_16);


--
-- Name: index_ingo_sharesng_on_perm_guest_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_guest_2 ON public.ingo_sharesng USING btree (perm_guest_2);


--
-- Name: index_ingo_sharesng_on_perm_guest_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_guest_4 ON public.ingo_sharesng USING btree (perm_guest_4);


--
-- Name: index_ingo_sharesng_on_perm_guest_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_perm_guest_8 ON public.ingo_sharesng USING btree (perm_guest_8);


--
-- Name: index_ingo_sharesng_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_share_name ON public.ingo_sharesng USING btree (share_name);


--
-- Name: index_ingo_sharesng_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_on_share_owner ON public.ingo_sharesng USING btree (share_owner);


--
-- Name: index_ingo_sharesng_users_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_perm_16 ON public.ingo_sharesng_users USING btree (perm_16);


--
-- Name: index_ingo_sharesng_users_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_perm_2 ON public.ingo_sharesng_users USING btree (perm_2);


--
-- Name: index_ingo_sharesng_users_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_perm_4 ON public.ingo_sharesng_users USING btree (perm_4);


--
-- Name: index_ingo_sharesng_users_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_perm_8 ON public.ingo_sharesng_users USING btree (perm_8);


--
-- Name: index_ingo_sharesng_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_share_id ON public.ingo_sharesng_users USING btree (share_id);


--
-- Name: index_ingo_sharesng_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_ingo_sharesng_users_on_user_uid ON public.ingo_sharesng_users USING btree (user_uid);


--
-- Name: index_kronolith_events_on_calendar_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_events_on_calendar_id ON public.kronolith_events USING btree (calendar_id);


--
-- Name: index_kronolith_events_on_event_baseid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_events_on_event_baseid ON public.kronolith_events USING btree (event_baseid);


--
-- Name: index_kronolith_events_on_event_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_events_on_event_uid ON public.kronolith_events USING btree (event_uid);


--
-- Name: index_kronolith_resources_on_resource_calendar; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_resources_on_resource_calendar ON public.kronolith_resources USING btree (resource_calendar);


--
-- Name: index_kronolith_resources_on_resource_type; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_resources_on_resource_type ON public.kronolith_resources USING btree (resource_type);


--
-- Name: index_kronolith_shares_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_groups_on_group_uid ON public.kronolith_shares_groups USING btree (group_uid);


--
-- Name: index_kronolith_shares_groups_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_groups_on_perm ON public.kronolith_shares_groups USING btree (perm);


--
-- Name: index_kronolith_shares_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_groups_on_share_id ON public.kronolith_shares_groups USING btree (share_id);


--
-- Name: index_kronolith_shares_on_perm_creator; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_on_perm_creator ON public.kronolith_shares USING btree (perm_creator);


--
-- Name: index_kronolith_shares_on_perm_default; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_on_perm_default ON public.kronolith_shares USING btree (perm_default);


--
-- Name: index_kronolith_shares_on_perm_guest; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_on_perm_guest ON public.kronolith_shares USING btree (perm_guest);


--
-- Name: index_kronolith_shares_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_on_share_name ON public.kronolith_shares USING btree (share_name);


--
-- Name: index_kronolith_shares_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_on_share_owner ON public.kronolith_shares USING btree (share_owner);


--
-- Name: index_kronolith_shares_users_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_users_on_perm ON public.kronolith_shares_users USING btree (perm);


--
-- Name: index_kronolith_shares_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_users_on_share_id ON public.kronolith_shares_users USING btree (share_id);


--
-- Name: index_kronolith_shares_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_shares_users_on_user_uid ON public.kronolith_shares_users USING btree (user_uid);


--
-- Name: index_kronolith_sharesng_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_group_uid ON public.kronolith_sharesng_groups USING btree (group_uid);


--
-- Name: index_kronolith_sharesng_groups_on_perm_1024; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_perm_1024 ON public.kronolith_sharesng_groups USING btree (perm_1024);


--
-- Name: index_kronolith_sharesng_groups_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_perm_16 ON public.kronolith_sharesng_groups USING btree (perm_16);


--
-- Name: index_kronolith_sharesng_groups_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_perm_2 ON public.kronolith_sharesng_groups USING btree (perm_2);


--
-- Name: index_kronolith_sharesng_groups_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_perm_4 ON public.kronolith_sharesng_groups USING btree (perm_4);


--
-- Name: index_kronolith_sharesng_groups_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_perm_8 ON public.kronolith_sharesng_groups USING btree (perm_8);


--
-- Name: index_kronolith_sharesng_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_groups_on_share_id ON public.kronolith_sharesng_groups USING btree (share_id);


--
-- Name: index_kronolith_sharesng_on_perm_creator_1024; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_creator_1024 ON public.kronolith_sharesng USING btree (perm_creator_1024);


--
-- Name: index_kronolith_sharesng_on_perm_creator_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_creator_16 ON public.kronolith_sharesng USING btree (perm_creator_16);


--
-- Name: index_kronolith_sharesng_on_perm_creator_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_creator_2 ON public.kronolith_sharesng USING btree (perm_creator_2);


--
-- Name: index_kronolith_sharesng_on_perm_creator_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_creator_4 ON public.kronolith_sharesng USING btree (perm_creator_4);


--
-- Name: index_kronolith_sharesng_on_perm_creator_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_creator_8 ON public.kronolith_sharesng USING btree (perm_creator_8);


--
-- Name: index_kronolith_sharesng_on_perm_default_1024; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_default_1024 ON public.kronolith_sharesng USING btree (perm_default_1024);


--
-- Name: index_kronolith_sharesng_on_perm_default_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_default_16 ON public.kronolith_sharesng USING btree (perm_default_16);


--
-- Name: index_kronolith_sharesng_on_perm_default_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_default_2 ON public.kronolith_sharesng USING btree (perm_default_2);


--
-- Name: index_kronolith_sharesng_on_perm_default_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_default_4 ON public.kronolith_sharesng USING btree (perm_default_4);


--
-- Name: index_kronolith_sharesng_on_perm_default_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_default_8 ON public.kronolith_sharesng USING btree (perm_default_8);


--
-- Name: index_kronolith_sharesng_on_perm_guest_1024; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_guest_1024 ON public.kronolith_sharesng USING btree (perm_guest_1024);


--
-- Name: index_kronolith_sharesng_on_perm_guest_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_guest_16 ON public.kronolith_sharesng USING btree (perm_guest_16);


--
-- Name: index_kronolith_sharesng_on_perm_guest_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_guest_2 ON public.kronolith_sharesng USING btree (perm_guest_2);


--
-- Name: index_kronolith_sharesng_on_perm_guest_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_guest_4 ON public.kronolith_sharesng USING btree (perm_guest_4);


--
-- Name: index_kronolith_sharesng_on_perm_guest_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_perm_guest_8 ON public.kronolith_sharesng USING btree (perm_guest_8);


--
-- Name: index_kronolith_sharesng_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_share_name ON public.kronolith_sharesng USING btree (share_name);


--
-- Name: index_kronolith_sharesng_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_on_share_owner ON public.kronolith_sharesng USING btree (share_owner);


--
-- Name: index_kronolith_sharesng_users_on_perm_1024; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_perm_1024 ON public.kronolith_sharesng_users USING btree (perm_1024);


--
-- Name: index_kronolith_sharesng_users_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_perm_16 ON public.kronolith_sharesng_users USING btree (perm_16);


--
-- Name: index_kronolith_sharesng_users_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_perm_2 ON public.kronolith_sharesng_users USING btree (perm_2);


--
-- Name: index_kronolith_sharesng_users_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_perm_4 ON public.kronolith_sharesng_users USING btree (perm_4);


--
-- Name: index_kronolith_sharesng_users_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_perm_8 ON public.kronolith_sharesng_users USING btree (perm_8);


--
-- Name: index_kronolith_sharesng_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_share_id ON public.kronolith_sharesng_users USING btree (share_id);


--
-- Name: index_kronolith_sharesng_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_sharesng_users_on_user_uid ON public.kronolith_sharesng_users USING btree (user_uid);


--
-- Name: index_kronolith_storage_on_vfb_email; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_storage_on_vfb_email ON public.kronolith_storage USING btree (vfb_email);


--
-- Name: index_kronolith_storage_on_vfb_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_kronolith_storage_on_vfb_owner ON public.kronolith_storage USING btree (vfb_owner);


--
-- Name: index_profissional_clients_on_name_and_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_clients_on_name_and_parent ON public.profissional_clients USING btree (name, parent);


--
-- Name: index_profissional_clients_on_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_clients_on_parent ON public.profissional_clients USING btree (parent);


--
-- Name: index_profissional_domain_aliases_on_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_domain_aliases_on_name ON public.profissional_domain_aliases USING btree (name);


--
-- Name: index_profissional_domain_aliases_on_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_domain_aliases_on_parent ON public.profissional_domain_aliases USING btree (parent);


--
-- Name: index_profissional_domains_aliase_on_lower_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_domains_aliase_on_lower_name ON public.profissional_domain_aliases USING btree (lower((name)::text));


--
-- Name: index_profissional_domains_on_lower_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_domains_on_lower_name ON public.profissional_domains USING btree (lower((name)::text));


--
-- Name: index_profissional_domains_on_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_domains_on_name ON public.profissional_domains USING btree (name);


--
-- Name: index_profissional_domains_on_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_domains_on_parent ON public.profissional_domains USING btree (parent);


--
-- Name: index_profissional_email_users_on_apikey; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_email_users_on_apikey ON public.profissional_email_users USING btree (apikey);


--
-- Name: index_profissional_emails_on_email; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_emails_on_email ON public.profissional_emails USING btree (email);


--
-- Name: index_profissional_emails_on_id_and_type; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_emails_on_id_and_type ON public.profissional_emails USING btree (id, type);


--
-- Name: index_profissional_emails_on_lower_username; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_emails_on_lower_username ON public.profissional_emails USING btree (lower((username)::text));


--
-- Name: index_profissional_emails_on_lower_username_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_emails_on_lower_username_parent ON public.profissional_emails USING btree (lower((username)::text), parent);


--
-- Name: index_profissional_emails_on_parent_lower_username; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_emails_on_parent_lower_username ON public.profissional_emails USING btree (parent, lower((username)::text));


--
-- Name: index_profissional_emails_on_username; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_emails_on_username ON public.profissional_emails USING btree (username);


--
-- Name: index_profissional_groups_on_name_and_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_groups_on_name_and_parent ON public.profissional_groups USING btree (name, parent);


--
-- Name: index_profissional_groups_on_parent; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_groups_on_parent ON public.profissional_groups USING btree (parent);


--
-- Name: index_profissional_logs_on_type; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_logs_on_type ON public.profissional_logs USING btree (type);


--
-- Name: index_profissional_products_sold_on_element_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_products_sold_on_element_id ON public.profissional_products_sold USING btree (element_id);


--
-- Name: index_profissional_products_sold_on_product_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_products_sold_on_product_id ON public.profissional_products_sold USING btree (product_id);


--
-- Name: index_profissional_products_sold_on_type; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_products_sold_on_type ON public.profissional_products_sold USING btree (type);


--
-- Name: index_profissional_products_sold_on_type_element_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_products_sold_on_type_element_id ON public.profissional_products_sold USING btree (type, element_id);


--
-- Name: index_profissional_resellers_on_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX index_profissional_resellers_on_name ON public.profissional_resellers USING btree (name);


--
-- Name: index_profissional_stats_on_type; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_profissional_stats_on_type ON public.profissional_stats USING btree (type);


--
-- Name: index_sybil_contact_on_contact_addressbook; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_sybil_contact_on_contact_addressbook ON public.sybil_contact USING btree (contact_addressbook);


--
-- Name: index_sybil_contact_on_contact_birthday; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_sybil_contact_on_contact_birthday ON public.sybil_contact USING btree (contact_birthday);


--
-- Name: index_sybil_contact_on_contact_gender; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_sybil_contact_on_contact_gender ON public.sybil_contact USING btree (contact_gender);


--
-- Name: index_turba_objects_on_object_email; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_objects_on_object_email ON public.turba_objects USING btree (object_email);


--
-- Name: index_turba_objects_on_object_firstname; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_objects_on_object_firstname ON public.turba_objects USING btree (object_firstname);


--
-- Name: index_turba_objects_on_object_lastname; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_objects_on_object_lastname ON public.turba_objects USING btree (object_lastname);


--
-- Name: index_turba_objects_on_owner_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_objects_on_owner_id ON public.turba_objects USING btree (owner_id);


--
-- Name: index_turba_shares_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_groups_on_group_uid ON public.turba_shares_groups USING btree (group_uid);


--
-- Name: index_turba_shares_groups_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_groups_on_perm ON public.turba_shares_groups USING btree (perm);


--
-- Name: index_turba_shares_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_groups_on_share_id ON public.turba_shares_groups USING btree (share_id);


--
-- Name: index_turba_shares_on_perm_creator; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_on_perm_creator ON public.turba_shares USING btree (perm_creator);


--
-- Name: index_turba_shares_on_perm_default; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_on_perm_default ON public.turba_shares USING btree (perm_default);


--
-- Name: index_turba_shares_on_perm_guest; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_on_perm_guest ON public.turba_shares USING btree (perm_guest);


--
-- Name: index_turba_shares_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_on_share_name ON public.turba_shares USING btree (share_name);


--
-- Name: index_turba_shares_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_on_share_owner ON public.turba_shares USING btree (share_owner);


--
-- Name: index_turba_shares_users_on_perm; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_users_on_perm ON public.turba_shares_users USING btree (perm);


--
-- Name: index_turba_shares_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_users_on_share_id ON public.turba_shares_users USING btree (share_id);


--
-- Name: index_turba_shares_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_shares_users_on_user_uid ON public.turba_shares_users USING btree (user_uid);


--
-- Name: index_turba_sharesng_groups_on_group_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_group_uid ON public.turba_sharesng_groups USING btree (group_uid);


--
-- Name: index_turba_sharesng_groups_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_perm_16 ON public.turba_sharesng_groups USING btree (perm_16);


--
-- Name: index_turba_sharesng_groups_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_perm_2 ON public.turba_sharesng_groups USING btree (perm_2);


--
-- Name: index_turba_sharesng_groups_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_perm_4 ON public.turba_sharesng_groups USING btree (perm_4);


--
-- Name: index_turba_sharesng_groups_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_perm_8 ON public.turba_sharesng_groups USING btree (perm_8);


--
-- Name: index_turba_sharesng_groups_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_groups_on_share_id ON public.turba_sharesng_groups USING btree (share_id);


--
-- Name: index_turba_sharesng_on_perm_creator_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_creator_16 ON public.turba_sharesng USING btree (perm_creator_16);


--
-- Name: index_turba_sharesng_on_perm_creator_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_creator_2 ON public.turba_sharesng USING btree (perm_creator_2);


--
-- Name: index_turba_sharesng_on_perm_creator_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_creator_4 ON public.turba_sharesng USING btree (perm_creator_4);


--
-- Name: index_turba_sharesng_on_perm_creator_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_creator_8 ON public.turba_sharesng USING btree (perm_creator_8);


--
-- Name: index_turba_sharesng_on_perm_default_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_default_16 ON public.turba_sharesng USING btree (perm_default_16);


--
-- Name: index_turba_sharesng_on_perm_default_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_default_2 ON public.turba_sharesng USING btree (perm_default_2);


--
-- Name: index_turba_sharesng_on_perm_default_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_default_4 ON public.turba_sharesng USING btree (perm_default_4);


--
-- Name: index_turba_sharesng_on_perm_default_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_default_8 ON public.turba_sharesng USING btree (perm_default_8);


--
-- Name: index_turba_sharesng_on_perm_guest_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_guest_16 ON public.turba_sharesng USING btree (perm_guest_16);


--
-- Name: index_turba_sharesng_on_perm_guest_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_guest_2 ON public.turba_sharesng USING btree (perm_guest_2);


--
-- Name: index_turba_sharesng_on_perm_guest_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_guest_4 ON public.turba_sharesng USING btree (perm_guest_4);


--
-- Name: index_turba_sharesng_on_perm_guest_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_perm_guest_8 ON public.turba_sharesng USING btree (perm_guest_8);


--
-- Name: index_turba_sharesng_on_share_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_share_name ON public.turba_sharesng USING btree (share_name);


--
-- Name: index_turba_sharesng_on_share_owner; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_on_share_owner ON public.turba_sharesng USING btree (share_owner);


--
-- Name: index_turba_sharesng_users_on_perm_16; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_perm_16 ON public.turba_sharesng_users USING btree (perm_16);


--
-- Name: index_turba_sharesng_users_on_perm_2; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_perm_2 ON public.turba_sharesng_users USING btree (perm_2);


--
-- Name: index_turba_sharesng_users_on_perm_4; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_perm_4 ON public.turba_sharesng_users USING btree (perm_4);


--
-- Name: index_turba_sharesng_users_on_perm_8; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_perm_8 ON public.turba_sharesng_users USING btree (perm_8);


--
-- Name: index_turba_sharesng_users_on_share_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_share_id ON public.turba_sharesng_users USING btree (share_id);


--
-- Name: index_turba_sharesng_users_on_user_uid; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX index_turba_sharesng_users_on_user_uid ON public.turba_sharesng_users USING btree (user_uid);


--
-- Name: profissional_domain_filters_domain_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profissional_domain_filters_domain_idx ON public.profissional_domain_filters USING btree (domain_id);


--
-- Name: profissional_domain_notifications_domain_purpose; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profissional_domain_notifications_domain_purpose ON public.profissional_domain_notifications USING btree (domain, purpose);


--
-- Name: profissional_email_user_credential_email_id_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profissional_email_user_credential_email_id_type ON public.profissional_email_user_credential USING btree (email_id, type);


--
-- Name: profissional_gal_reseller_client_domain; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX profissional_gal_reseller_client_domain ON public.profissional_gal USING btree (reseller_id, client_id, domain_id);


--
-- Name: rampage_objects_type_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX rampage_objects_type_name ON public.rampage_types USING btree (type_name);


--
-- Name: rampage_objects_type_object_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX rampage_objects_type_object_name ON public.rampage_objects USING btree (type_id, object_name);


--
-- Name: rampage_tagged_created; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX rampage_tagged_created ON public.rampage_tagged USING btree (created);


--
-- Name: rampage_tagged_object_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX rampage_tagged_object_id ON public.rampage_tagged USING btree (object_id);


--
-- Name: rampage_tagged_tag_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX rampage_tagged_tag_id ON public.rampage_tagged USING btree (tag_id);


--
-- Name: rampage_tags_tag_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX rampage_tags_tag_name ON public.rampage_tags USING btree (tag_name);


--
-- Name: rampage_user_tag_stats_tag_id; Type: INDEX; Schema: public; Owner: horde
--

CREATE INDEX rampage_user_tag_stats_tag_id ON public.rampage_user_tag_stats USING btree (tag_id);


--
-- Name: rampage_users_user_name; Type: INDEX; Schema: public; Owner: horde
--

CREATE UNIQUE INDEX rampage_users_user_name ON public.rampage_users USING btree (user_name);


--
-- Name: profissional_alias profissional_alias_delete; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE profissional_alias_delete AS
    ON DELETE TO public.profissional_alias DO INSTEAD  DELETE FROM public.profissional_emails
  WHERE ((profissional_emails.email)::text = (old.email)::text);


--
-- Name: profissional_mailmarketing profissional_mailmarketing_del; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE profissional_mailmarketing_del AS
    ON DELETE TO public.profissional_mailmarketing DO INSTEAD  DELETE FROM public.profissional_mailmarketing_products_sold
  WHERE (((profissional_mailmarketing_products_sold.type)::text = 'client'::text) AND (profissional_mailmarketing_products_sold.element_id = old.parent));


--
-- Name: profissional_mailmarketing profissional_mailmarketing_ins; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE profissional_mailmarketing_ins AS
    ON INSERT TO public.profissional_mailmarketing DO INSTEAD  INSERT INTO public.profissional_mailmarketing_products_sold (product_id, type, element_id, quota)
  VALUES (new.product_id, 'client'::character varying, new.parent, 1)
  RETURNING profissional_mailmarketing_products_sold.element_id AS id,
    profissional_mailmarketing_products_sold.element_id AS parent,
    profissional_mailmarketing_products_sold.product_id,
    ( SELECT profissional_mailmarketing_products.quota
           FROM public.profissional_mailmarketing_products
          WHERE (profissional_mailmarketing_products.id = profissional_mailmarketing_products_sold.product_id)) AS maxcontacts;


--
-- Name: profissional_mailmarketing profissional_mailmarketing_upd; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE profissional_mailmarketing_upd AS
    ON UPDATE TO public.profissional_mailmarketing DO INSTEAD  UPDATE public.profissional_mailmarketing_products_sold SET product_id = new.product_id
  WHERE ((profissional_mailmarketing_products_sold.element_id = old.parent) AND ((profissional_mailmarketing_products_sold.type)::text = 'client'::text));


--
-- Name: profissional_users profissional_users_del; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE profissional_users_del AS
    ON DELETE TO public.profissional_users DO INSTEAD  DELETE FROM public.profissional_emails
  WHERE ((profissional_emails.email)::text = (old.email)::text);


--
-- Name: profissional_domains on_update_emails_username_trigger; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER on_update_emails_username_trigger AFTER UPDATE ON public.profissional_domains FOR EACH ROW EXECUTE FUNCTION public.profissional_domains_emails_username_trigger();


--
-- Name: profissional_domains on_update_horde_groups_members_trigger; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER on_update_horde_groups_members_trigger AFTER UPDATE ON public.profissional_domains FOR EACH ROW EXECUTE FUNCTION public.profissional_domains_horde_groups_members_trigger();


--
-- Name: profissional_domains on_update_horde_prefs_trigger; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER on_update_horde_prefs_trigger AFTER UPDATE ON public.profissional_domains FOR EACH ROW EXECUTE FUNCTION public.profissional_domains_horde_prefs_trigger();


--
-- Name: profissional_alias profissional_alias_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_alias_delete INSTEAD OF DELETE ON public.profissional_alias FOR EACH ROW EXECUTE FUNCTION public.profissional_alias_delete();


--
-- Name: profissional_alias profissional_alias_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_alias_insert INSTEAD OF INSERT ON public.profissional_alias FOR EACH ROW EXECUTE FUNCTION public.profissional_alias_insert();


--
-- Name: profissional_alias profissional_alias_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_alias_update INSTEAD OF UPDATE ON public.profissional_alias FOR EACH ROW EXECUTE FUNCTION public.profissional_alias_update();


--
-- Name: profissional_email_aliases profissional_email_aliases_maildrop_insert_update_trigger; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER profissional_email_aliases_maildrop_insert_update_trigger BEFORE INSERT OR UPDATE ON public.profissional_email_aliases FOR EACH ROW EXECUTE FUNCTION public.profissional_email_aliases_maildrop_trigger();


--
-- Name: profissional_email_users profissional_email_users_quota_deprecation_trigger; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER profissional_email_users_quota_deprecation_trigger BEFORE INSERT OR UPDATE ON public.profissional_email_users FOR EACH ROW EXECUTE FUNCTION public.profissional_email_users_quota_deprecation();


--
-- Name: profissional_emails profissional_emails_update_insert_trg; Type: TRIGGER; Schema: public; Owner: horde
--

CREATE TRIGGER profissional_emails_update_insert_trg BEFORE INSERT OR UPDATE ON public.profissional_emails FOR EACH ROW EXECUTE FUNCTION public.profissional_emails_username_trigger();


--
-- Name: profissional_users profissional_users_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_users_delete INSTEAD OF DELETE ON public.profissional_users FOR EACH ROW EXECUTE FUNCTION public.profissional_users_delete();


--
-- Name: profissional_users profissional_users_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_users_insert INSTEAD OF INSERT ON public.profissional_users FOR EACH ROW EXECUTE FUNCTION public.profissional_users_insert();


--
-- Name: profissional_users profissional_users_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER profissional_users_update INSTEAD OF UPDATE ON public.profissional_users FOR EACH ROW EXECUTE FUNCTION public.profissional_users_update();


--
-- Name: wblist wblist_sid_fkey; Type: FK CONSTRAINT; Schema: amavis; Owner: postgres
--

ALTER TABLE ONLY amavis.wblist
    ADD CONSTRAINT wblist_sid_fkey FOREIGN KEY (sid) REFERENCES amavis.mailaddr(id);


--
-- Name: client client_profissional_client_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.client
    ADD CONSTRAINT client_profissional_client_fkey FOREIGN KEY (profissional_client) REFERENCES public.profissional_clients(id);


--
-- Name: client client_reseller_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.client
    ADD CONSTRAINT client_reseller_fkey FOREIGN KEY (reseller) REFERENCES invoicexpress.reseller(id);


--
-- Name: invoice invoice_profissional_client_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoice
    ADD CONSTRAINT invoice_profissional_client_fkey FOREIGN KEY (profissional_client) REFERENCES public.profissional_clients(id);


--
-- Name: invoice invoice_reseller_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoice
    ADD CONSTRAINT invoice_reseller_fkey FOREIGN KEY (reseller) REFERENCES invoicexpress.reseller(id);


--
-- Name: invoiceline invoiceline_invoice_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoiceline
    ADD CONSTRAINT invoiceline_invoice_fkey FOREIGN KEY (invoice) REFERENCES invoicexpress.invoice(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: invoiceline invoiceline_profissional_product_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.invoiceline
    ADD CONSTRAINT invoiceline_profissional_product_fkey FOREIGN KEY (profissional_product) REFERENCES public.profissional_products(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: item item_profissional_product_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.item
    ADD CONSTRAINT item_profissional_product_fkey FOREIGN KEY (profissional_product) REFERENCES public.profissional_products(id);


--
-- Name: item item_reseller_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.item
    ADD CONSTRAINT item_reseller_fkey FOREIGN KEY (reseller) REFERENCES invoicexpress.reseller(id);


--
-- Name: reseller reseller_reseller_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.reseller
    ADD CONSTRAINT reseller_reseller_fkey FOREIGN KEY (reseller) REFERENCES public.profissional_resellers(id);


--
-- Name: usagemeter usagemeter_client_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.usagemeter
    ADD CONSTRAINT usagemeter_client_fkey FOREIGN KEY (client) REFERENCES public.profissional_clients(id);


--
-- Name: usagemeter usagemeter_product_fkey; Type: FK CONSTRAINT; Schema: invoicexpress; Owner: postgres
--

ALTER TABLE ONLY invoicexpress.usagemeter
    ADD CONSTRAINT usagemeter_product_fkey FOREIGN KEY (product) REFERENCES public.profissional_products(id);


--
-- Name: ldap_attr_mappings ldap_attr_mappings_oc_map_id_fkey; Type: FK CONSTRAINT; Schema: openldap; Owner: openldap
--

ALTER TABLE ONLY openldap.ldap_attr_mappings
    ADD CONSTRAINT ldap_attr_mappings_oc_map_id_fkey FOREIGN KEY (oc_map_id) REFERENCES openldap.ldap_oc_mappings(id);


--
-- Name: profissional_products_sold fk_products_sold_product_id; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_products_sold
    ADD CONSTRAINT fk_products_sold_product_id FOREIGN KEY (product_id) REFERENCES public.profissional_products(id);


--
-- Name: profissional_clients fk_profissional_clients_parent; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_clients
    ADD CONSTRAINT fk_profissional_clients_parent FOREIGN KEY (parent) REFERENCES public.profissional_resellers(id) ON DELETE CASCADE;


--
-- Name: profissional_domains fk_profissional_domains_parent; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_domains
    ADD CONSTRAINT fk_profissional_domains_parent FOREIGN KEY (parent) REFERENCES public.profissional_clients(id) ON DELETE CASCADE;


--
-- Name: profissional_email_aliases fk_profissional_email_aliases_email_id_type; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_aliases
    ADD CONSTRAINT fk_profissional_email_aliases_email_id_type FOREIGN KEY (email_id, type) REFERENCES public.profissional_emails(id, type) ON DELETE CASCADE;


--
-- Name: profissional_email_groups fk_profissional_email_groups_email_id; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_groups
    ADD CONSTRAINT fk_profissional_email_groups_email_id FOREIGN KEY (email_id) REFERENCES public.profissional_emails(id) ON DELETE CASCADE;


--
-- Name: profissional_email_groups fk_profissional_email_groups_group_id; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_groups
    ADD CONSTRAINT fk_profissional_email_groups_group_id FOREIGN KEY (group_id) REFERENCES public.profissional_groups(id) ON DELETE CASCADE;


--
-- Name: profissional_email_users fk_profissional_email_users_email_id_type; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_users
    ADD CONSTRAINT fk_profissional_email_users_email_id_type FOREIGN KEY (email_id, type) REFERENCES public.profissional_emails(id, type) ON DELETE CASCADE;


--
-- Name: profissional_emails fk_profissional_emails_parent; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_emails
    ADD CONSTRAINT fk_profissional_emails_parent FOREIGN KEY (parent) REFERENCES public.profissional_domains(id) ON DELETE CASCADE;


--
-- Name: profissional_groups fk_profissional_groups_parent; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_groups
    ADD CONSTRAINT fk_profissional_groups_parent FOREIGN KEY (parent) REFERENCES public.profissional_domains(id) ON DELETE CASCADE;


--
-- Name: profissional_client_softsuspend profissional_client_softsuspend_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_client_softsuspend
    ADD CONSTRAINT profissional_client_softsuspend_id_fkey FOREIGN KEY (id) REFERENCES public.profissional_clients(id);


--
-- Name: profissional_domain_aliases profissional_domain_alias_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_domain_aliases
    ADD CONSTRAINT profissional_domain_alias_parent_fkey FOREIGN KEY (parent) REFERENCES public.profissional_domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_domain_filters profissional_domain_filters_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_filters
    ADD CONSTRAINT profissional_domain_filters_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES public.profissional_domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_domain_notifications profissional_domain_notifications_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_notifications
    ADD CONSTRAINT profissional_domain_notifications_domain_fkey FOREIGN KEY (domain) REFERENCES public.profissional_domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_domain_secondary_target profissional_domain_secondary_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_domain_secondary_target
    ADD CONSTRAINT profissional_domain_secondary_target_id_fkey FOREIGN KEY (id) REFERENCES public.profissional_domains(id);


--
-- Name: profissional_email_marketing profissional_email_marketing_parent_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_email_marketing
    ADD CONSTRAINT profissional_email_marketing_parent_fkey FOREIGN KEY (parent) REFERENCES public.profissional_clients(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_email_users profissional_email_users_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: horde
--

ALTER TABLE ONLY public.profissional_email_users
    ADD CONSTRAINT profissional_email_users_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.profissional_products(id);


--
-- Name: profissional_mailmarketing_products_sold profissional_mailmarketing_products_sold_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_mailmarketing_products_sold
    ADD CONSTRAINT profissional_mailmarketing_products_sold_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.profissional_mailmarketing_products(id);


--
-- Name: profissional_sendas profissional_sendas_authorized_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sendas
    ADD CONSTRAINT profissional_sendas_authorized_by_fkey FOREIGN KEY (authorized_by) REFERENCES public.profissional_emails(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_sendas profissional_sendas_authorizes_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sendas
    ADD CONSTRAINT profissional_sendas_authorizes_fkey FOREIGN KEY (authorizes) REFERENCES public.profissional_emails(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_sync_domains profissional_sync_domains_domain_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_sync_domains
    ADD CONSTRAINT profissional_sync_domains_domain_id_fkey FOREIGN KEY (domain_id) REFERENCES public.profissional_domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: profissional_timestamp_domains profissional_timestamp_domains_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.profissional_timestamp_domains
    ADD CONSTRAINT profissional_timestamp_domains_id_fkey FOREIGN KEY (id) REFERENCES public.profissional_domains(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: SCHEMA amavis; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA amavis TO amavis;


--
-- Name: SCHEMA openldap; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA openldap TO openldap;


--
-- Name: SCHEMA postfix; Type: ACL; Schema: -; Owner: horde
--

GRANT USAGE ON SCHEMA postfix TO postfix;


--
-- Name: TABLE mailaddr; Type: ACL; Schema: amavis; Owner: postgres
--

GRANT SELECT ON TABLE amavis.mailaddr TO amavis;


--
-- Name: TABLE policy; Type: ACL; Schema: amavis; Owner: postgres
--

GRANT SELECT ON TABLE amavis.policy TO amavis;


--
-- Name: TABLE profissional_clients; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_clients TO openldap;
GRANT SELECT ON TABLE public.profissional_clients TO postfix;


--
-- Name: TABLE profissional_domains; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_domains TO postfix;
GRANT SELECT ON TABLE public.profissional_domains TO openldap;


--
-- Name: TABLE profissional_resellers; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_resellers TO openldap;
GRANT SELECT ON TABLE public.profissional_resellers TO postfix;


--
-- Name: TABLE domains; Type: ACL; Schema: postfix; Owner: horde
--

GRANT SELECT ON TABLE postfix.domains TO postfix;


--
-- Name: TABLE profissional_emails; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_emails TO postfix;
GRANT SELECT ON TABLE public.profissional_emails TO amavis;
GRANT SELECT ON TABLE public.profissional_emails TO openldap;


--
-- Name: TABLE users; Type: ACL; Schema: amavis; Owner: postgres
--

GRANT SELECT ON TABLE amavis.users TO amavis;


--
-- Name: TABLE wblist; Type: ACL; Schema: amavis; Owner: postgres
--

GRANT SELECT ON TABLE amavis.wblist TO amavis;


--
-- Name: TABLE profissional_email_aliases; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_email_aliases TO openldap;
GRANT SELECT ON TABLE public.profissional_email_aliases TO postfix;


--
-- Name: TABLE profissional_email_users; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_email_users TO postfix;
GRANT SELECT ON TABLE public.profissional_email_users TO openldap;


--
-- Name: TABLE active_email; Type: ACL; Schema: postfix; Owner: horde
--

GRANT SELECT ON TABLE postfix.active_email TO postfix;


--
-- Name: TABLE aliases; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT SELECT ON TABLE postfix.aliases TO postfix;
GRANT SELECT ON TABLE postfix.aliases TO horde;


--
-- Name: TABLE profissional_domain_filters; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.profissional_domain_filters TO postfix;
GRANT ALL ON TABLE public.profissional_domain_filters TO horde;


--
-- Name: TABLE domain_filters; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT ALL ON TABLE postfix.domain_filters TO postfix;


--
-- Name: TABLE emails; Type: ACL; Schema: postfix; Owner: horde
--

GRANT SELECT ON TABLE postfix.emails TO postfix;


--
-- Name: TABLE logins; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT ALL ON TABLE postfix.logins TO postfix;
GRANT SELECT ON TABLE postfix.logins TO horde;


--
-- Name: TABLE recursive_aliases; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT SELECT ON TABLE postfix.recursive_aliases TO postfix;


--
-- Name: TABLE timestamp_queue; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT ALL ON TABLE postfix.timestamp_queue TO postfix;


--
-- Name: SEQUENCE timestamp_queue_id_seq; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT ALL ON SEQUENCE postfix.timestamp_queue_id_seq TO postfix;


--
-- Name: TABLE users; Type: ACL; Schema: postfix; Owner: postgres
--

GRANT SELECT ON TABLE postfix.users TO postfix;


--
-- Name: TABLE profissional_client_softsuspend; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_client_softsuspend TO horde;
GRANT SELECT ON TABLE public.profissional_client_softsuspend TO postfix;


--
-- Name: TABLE smtpd_sender_restrictions_v2; Type: ACL; Schema: postfix_submission; Owner: postgres
--

GRANT SELECT ON TABLE postfix_submission.smtpd_sender_restrictions_v2 TO postfix;


--
-- Name: TABLE profissional_domain_secondary_target; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_domain_secondary_target TO horde;
GRANT SELECT ON TABLE public.profissional_domain_secondary_target TO postfix;


--
-- Name: TABLE horde_activesync_cache; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_cache TO horde;


--
-- Name: TABLE horde_activesync_device; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_device TO horde;


--
-- Name: TABLE horde_activesync_device_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_device_users TO horde;


--
-- Name: TABLE horde_activesync_mailmap; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_mailmap TO horde;


--
-- Name: TABLE horde_activesync_map; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_map TO horde;


--
-- Name: TABLE horde_activesync_state; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.horde_activesync_state TO horde;


--
-- Name: TABLE novis_username_map; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.novis_username_map TO postfix;
GRANT SELECT ON TABLE public.novis_username_map TO horde;


--
-- Name: TABLE profissional_alias; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_alias TO horde;


--
-- Name: SEQUENCE profissional_domain_filters_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.profissional_domain_filters_id_seq TO horde;


--
-- Name: TABLE profissional_domain_notifications; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_domain_notifications TO horde;


--
-- Name: SEQUENCE profissional_domain_notifications_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.profissional_domain_notifications_id_seq TO horde;


--
-- Name: TABLE profissional_email_alias_destiny; Type: ACL; Schema: public; Owner: horde
--

GRANT SELECT ON TABLE public.profissional_email_alias_destiny TO postfix;


--
-- Name: TABLE profissional_email_marketing; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_email_marketing TO horde;


--
-- Name: SEQUENCE profissional_email_marketing_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.profissional_email_marketing_id_seq TO horde;


--
-- Name: TABLE profissional_email_user_credential; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_email_user_credential TO horde;


--
-- Name: SEQUENCE profissional_email_user_credential_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.profissional_email_user_credential_id_seq TO horde;


--
-- Name: TABLE profissional_gal; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.profissional_gal TO horde;


--
-- Name: TABLE profissional_mailmarketing_products; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_mailmarketing_products TO horde;


--
-- Name: TABLE profissional_mailmarketing_products_sold; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_mailmarketing_products_sold TO horde;


--
-- Name: TABLE profissional_mailmarketing; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_mailmarketing TO horde;


--
-- Name: TABLE profissional_sendas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_sendas TO horde;
GRANT SELECT ON TABLE public.profissional_sendas TO postfix;


--
-- Name: SEQUENCE profissional_sendas_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.profissional_sendas_id_seq TO horde;


--
-- Name: TABLE profissional_sync_domains; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_sync_domains TO horde;


--
-- Name: TABLE profissional_sync_queue; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_sync_queue TO horde;


--
-- Name: TABLE profissional_ticketgranting; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.profissional_ticketgranting TO horde;


--
-- Name: TABLE profissional_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.profissional_users TO horde;
GRANT ALL ON TABLE public.profissional_users TO postfix;


--
-- PostgreSQL database dump complete
--

\unrestrict fTyhMD6tPGXF4GbIX5q4zrDbMQhTAvB4BYFMTnkTqwEhVgHKOt2KRlXdXh8L5al

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict 2i87QUg4GXbpgzoC0c5cD0mekWBQvuPdMW5NeXkXghf21JUUqOs7d3H3djAbPMR

-- Dumped from database version 17.6 (Debian 17.6-0+deb13u1)
-- Dumped by pg_dump version 17.6 (Debian 17.6-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- PostgreSQL database dump complete
--

\unrestrict 2i87QUg4GXbpgzoC0c5cD0mekWBQvuPdMW5NeXkXghf21JUUqOs7d3H3djAbPMR

--
-- PostgreSQL database cluster dump complete
--

