use std::ffi::{CString};

use clap::{Parser, command};
use indymilter::{Callbacks, Context, Status, EomContext};
use tokio::signal;
use syslog::Facility;
use postgres::{Client, NoTls};
use regex::Regex;
#[macro_use]
extern crate ini;

#[derive(Debug, Default)]
struct ContextData {
    mail_from: Option<String>,
    rcpt_to: Vec<String>,
    subject: Option<String>,
    queue_id: Option<String>
}
#[derive(Debug, Default, Clone)]
struct Config {
    db_host: &'static str,
    db_port: &'static str,
    db_user: &'static str,
    db_password: &'static str,
    db_database: &'static str,
    smtp_server: &'static str,
}
static mut CONFIG: Config = Config { 
    db_host: "",
    db_port: "",
    db_user: "",
    db_password: "",
    db_database: "",
    smtp_server: "",
};
#[derive(Parser, Debug)]
#[command(name = "submission-record")]
#[command(author = "Sooma.com")]
#[command(version = "1.0")]
#[command(about = "Records email submission into database", long_about = None)]
struct CliArguments {
    #[arg(short='c', long="config-file")]
    config_file: Option<String>,
}

#[tokio::main]
async fn main() {
    syslog::init(Facility::LOG_USER,
        log::LevelFilter::Debug,
        Some("submission-record")).unwrap();
    let mut cli = CliArguments::parse();
    if cli.config_file.is_none() {
        cli.config_file = Some("/etc/milter/submission-record.ini".to_string());
    }
    let ini_file_settings = ini!(&cli.config_file.unwrap());
    unsafe {
        if let Some(settings) = ini_file_settings.get("submission-milter") {
            CONFIG.db_host = Box::leak(settings.get("dbhost").unwrap_or(&None).clone().unwrap_or_default().into_boxed_str());
            CONFIG.db_port = Box::leak(settings.get("dbport").unwrap_or(&None).clone().unwrap_or_default().into_boxed_str());
            CONFIG.db_user = Box::leak(settings.get("dbuser").unwrap_or(&None).clone().unwrap_or_default().into_boxed_str());
            CONFIG.db_password = Box::leak(settings.get("dbhost").unwrap_or(&None).clone().unwrap_or_default().into_boxed_str());
            CONFIG.db_database = Box::leak(settings.get("dbdatabase").unwrap_or(&None).clone().unwrap_or_default().into_boxed_str());
            CONFIG.smtp_server = Box::leak(settings.get("smtp_server").unwrap_or(&None).clone().unwrap_or_else(|| "unnamed-smtp-server".to_string()).into_boxed_str());
        }
    }

    /*
    let listener = tokio::net::UnixListener::bind("/var/spool/postfix/milter/submission-record.sock")
    .expect("cannot open milter socket");
    */
    let listener = tokio::net::TcpListener::bind("0.0.0.0:35042")
        .await
        .expect("cannot open milter tcp socket");

    let callbacks = Callbacks::new()
        .on_mail(|context, mail_from| {
            Box::pin(handle_mail(context, mail_from))
        })
        .on_rcpt(|context, rcpt| {
            Box::pin(handle_rcpt(context, rcpt))
        })
        .on_header(|context, name, value| {
            Box::pin(handle_header(context, name, value))
        })
        .on_eom(|context| {
            Box::pin(handle_eom(context))
        });

    let indymilter_config = Default::default();

    indymilter::run(listener, callbacks, indymilter_config, signal::ctrl_c())
        .await
        .expect("milter execution failed");
}

fn get_config() -> Config {
    unsafe {
        CONFIG.clone()
    }
}

async fn handle_mail( context: &mut Context<ContextData>, from: Vec<CString> ) -> Status {
    context.data = Some(ContextData{ ..Default::default() });
    if let Some(data) = &mut context.data {
        for val in from.iter() {
            if val.as_bytes()[0] == b'<' { // Workaround for indymilter possible bug: Callback is being called with values such as SIZE= or BODY=
                data.mail_from = Some(String::from_utf8_lossy(val.to_bytes()).to_string());
            }
        }
    }
    Status::Continue
}
async fn handle_rcpt( context: &mut Context<ContextData>, rcpt: Vec<CString> ) -> Status {
    if let Some(data) = &mut context.data {
        for val in rcpt.iter() {
            if val.as_bytes()[0] == b'<' { // Workaround for indymilter possible bug: Callback is being called with values such as SIZE= or BODY= (actually, this has only been observed in the MAIL callback, but just to be safe...)
                data.rcpt_to.push( String::from_utf8_lossy(val.to_bytes()).to_string() );
            }
        }
    }
    Status::Continue
}
async fn handle_header( context: &mut Context<ContextData>, name: CString, value: CString ) -> Status {
    if let Some(data) = &mut context.data { 
        if String::from_utf8_lossy(name.to_bytes()).to_string().to_lowercase() == *"subject" {
            match rfc2047_decoder::decode(value.to_bytes()) {
                Ok(subject) => { data.subject = Some(subject) },
                Err(err) => {
                    match context
                        .macros
                        .get(&CString::new("i").unwrap())
                        .map(|cstr| String::from_utf8_lossy(cstr.to_bytes()).to_string()) {
                            Some(queue_id) => log::error!("{}: Error decoding subject header: {}", queue_id, err.to_string()),
                            None => log::error!("NOQUEUE: Error decoding subject header: {}", err.to_string()),
                        }
                    }
            }
        }
    }
    Status::Continue
}
async fn handle_eom( context: &mut EomContext<ContextData> ) -> Status {
    if let Some(data) = &mut context.data {
        data.queue_id = context
            .macros
            .get(&CString::new("i").unwrap())
            .map(|cstr| String::from_utf8_lossy(cstr.to_bytes()).to_string());
        let email_extract_regex = Regex::new(r"<(?P<email>[^>]*)>").unwrap();
        
        // Data fields to be moved into thread
        let queue_id = data.queue_id.clone().unwrap_or_else(|| "NOQUEUE".to_string());
        let mail_from: String = email_extract_regex.replace_all(&data.mail_from.clone().unwrap_or_default(), "${email}").to_string();
        if mail_from == "timestamp@sooma.com" {
            return Status::Continue
        }
        let rcpt_to = data.rcpt_to
            .iter()
            .map(|rcpt| email_extract_regex.replace_all(rcpt, "${email}").to_string())
            .collect::<Vec<String>>();
        let subject: String = data.subject.clone().unwrap_or_default();
        tokio::task::spawn_blocking(move || {
            let config = get_config();
            match Client::connect(&format!("host={} port={} user={} password={} dbname={}", 
                    config.db_host,
                    config.db_port,
                    config.db_user,
                    config.db_password,
                    config.db_database),
                NoTls) {
                    Err(err) => {
                        log::error!("{}: Error connecting to database: {}; mail_from={}, subject={}, rcpt_to={:?}", queue_id, err.to_string(), mail_from, subject, rcpt_to);
                    }
                    Ok(mut psql) => {
                        let domain = mail_from.rsplit("@").next().unwrap_or_default();
                        log::info!("{}: Processing mail: mail_from={}, domain={}, subject={}, rcpt_to={:?}", queue_id, mail_from, domain, subject, rcpt_to);
                        let active_service = match psql.query(r#"SELECT CAST($1 as character varying(255)) IN (SELECT profissional_domains.name FROM profissional_domains JOIN profissional_timestamp_domains ON profissional_domains.id = profissional_timestamp_domains.id)"#, &[&domain]) {
                            Ok(rows) => rows.iter().fold(false, |_acc, row| row.get(0)),
                            Err(err) => {
                                log::error!("{}: Error querying if timestamp service is enabled. Returning false: {}", queue_id, err.to_string());
                                false
                            }
                        };
                        if active_service {
                            for rcpt in rcpt_to {
                                match psql.execute(r#"
INSERT INTO "postfix"."timestamp_queue"("smtp_server", "queue_id", "mail_from", "rcpt_to", "subject") VALUES($1, $2, $3, $4, $5)"#,
                                &[&config.smtp_server, &queue_id, &mail_from, &rcpt, &subject]) {
                                    Ok(_) => {},
                                    Err(err) => {
                                        log::error!("{}: Error inserting message record in database: {}; mail_from={}, subject={}, rcpt_to={}", queue_id, err.to_string(), mail_from, subject, rcpt);
                                        
                                    }
                                }
                            }
                        }
                    }
                }
        }).await.expect("Database insertion task launch panicked");
    }

    Status::Continue
}