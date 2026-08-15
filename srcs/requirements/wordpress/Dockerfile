FROM debian:12

RUN apt update && apt install -y \
    php-fpm \
    php-cli \
    php-mysql \
    php-curl \
    php-imagick \
    php-mbstring \
    php-xml \
    php-zip \
    php-intl \
    curl \
    mariadb-client \
    ca-certificates

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp


RUN sed -i \
    's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' \
    /etc/php/8.2/fpm/pool.d/www.conf


COPY ./tools/wordpress-entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/wordpress-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/wordpress-entrypoint.sh"]