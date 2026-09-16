FROM debian:bullseye

# Matches the era of this Horde checkout (PHP 5.3||7 per its composer.json
# constraints); bullseye's default 'php' metapackage is 7.4.
# bullseye is EOL and gone from the regular mirrors - pull from the archive.
RUN echo "deb http://archive.debian.org/debian bullseye main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian bullseye-updates main" >> /etc/apt/sources.list

RUN apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y --no-install-recommends --allow-downgrades \
    perl-base=5.32.1-4+deb11u3 \
    php-cli php-common php-curl php-gd php-intl php-mbstring php-pgsql \
    php-xml php-zip php-bz2 php-php-gettext \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
CMD ["php", "-a"]
