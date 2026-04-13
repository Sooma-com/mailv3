ARG debian_version=trixie

FROM debian:${debian_version}

RUN apt-get update && apt-get install -y curl vim rsyslog git s6 zsh locales iproute2 sudo postgresql-all dovecot-core dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-pgsql dovecot-pop3d dovecot-sieve dovecot-submissiond dovecot-ldap python3-psycopg2 postfix postfix-pgsql postfix-cdb postfix-ldap python3-pip python3-milter php-common php-composer-ca-bundle php-composer-class-map-generator php-composer-metadata-minifier php-composer-pcre php-composer-semver php-composer-spdx-licenses php-composer-xdebug-handler php-curl php-enum php-fpm php-gd php-intl php-json-schema php-ldap php-mbstring php-mysql php-net-ldap2 php-pear php-pgsql php-psr-container php-psr-log php-react-promise php-seld-signal-handler php-symfony-console php-symfony-deprecation-contracts php-symfony-filesystem php-symfony-finder php-symfony-process php-symfony-service-contracts php-symfony-string php-xml php-zip nginx unzip && rm -rf /var/lib/apt/lists/*
COPY files/system/locale.gen /etc/locale.gen
RUN /usr/sbin/locale-gen
COPY files/rsyslog/rsyslog.conf /etc/rsyslog.conf

RUN mkdir -p /etc/s6
ADD files/s6 /etc/s6
RUN git clone --recurse-submodules https://github.com/sergiosgc/zsh.d.git /root/.zsh.d && ln -s /root/.zsh.d/zshrc /root/.zshrc
RUN git clone --recurse-submodules https://github.com/sergiosgc/vim.d.git /root/.vim.d && ln -s /root/.vim.d/vimrc /root/.vimrc
ADD files/system/home /root
RUN rm -f /root/.zsh.d/env/SSLKEYLOGFILE

ARG postgresql_version=17
COPY files/postgresql/pg_hba.conf /etc/postgresql/${postgresql_version}/main/pg_hba.conf
COPY files/postgresql/postgresql.conf /etc/postgresql/${postgresql_version}/main/postgresql.conf
RUN sed --in-place "s/{postgresql_version}/${postgresql_version}/g" /etc/postgresql/${postgresql_version}/main/postgresql.conf
RUN sed --in-place "s/{postgresql_version}/${postgresql_version}/g" /etc/s6/postgresql/run
COPY files/postgresql/db_dump.sql /tmp/db_dump.sql
RUN /etc/init.d/postgresql start && psql -U postgres -f /tmp/db_dump.sql && /etc/init.d/postgresql stop && rm /tmp/db_dump.sql

RUN groupadd --gid 1008 vmail && useradd --gid 1008 --uid 500 --create-home --shell /bin/bash vmail
COPY files/dovecot/multi /etc/dovecot/multi
RUN /usr/bin/sievec /etc/dovecot/multi/imap/ext/spam.sieve
RUN mkdir -p /mnt/email/vmail && chown vmail:vmail /mnt/email/vmail

COPY files/postfix/main.cf /etc/postfix/main.cf
COPY files/postfix/postfix-profissional-mx /etc/postfix-profissional-mx
RUN mkdir /var/spool/postfix-profissional-mx

COPY files/milter/etc/milter /etc/milter
RUN mkdir -p /var/spool/postfix/milter && chown postfix:postfix /var/spool/postfix/milter

ARG php_version=8.4
RUN sed --in-place "s/{php_version}/${php_version}/g" /etc/s6/php-fpm/run
COPY files/php/php.ini /etc/php/${php_version}/fpm/
COPY files/php/composer.phar /usr/local/bin/composer
COPY files/openssl/openssl.cnf /usr/lib/ssl/openssl.cnf

COPY files/nginx/vhost /etc/nginx/sites-available/default
RUN sed --in-place "s/{php_version}/${php_version}/g" /etc/nginx/sites-available/default

RUN git config --global --add safe.directory /srv/www

COPY files/system/docker_go /usr/local/bin/docker_go

CMD [ "/usr/local/bin/docker_go" ]
