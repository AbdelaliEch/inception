FROM debian:12

RUN apt-get update && apt-get install -y \
    nginx \
    openssl


COPY ./conf/inception.conf /etc/nginx/conf.d/inception.conf

COPY ./tools/nginx-entrypoint.sh /usr/local/bin/nginx-entrypoint.sh
RUN chmod +x /usr/local/bin/nginx-entrypoint.sh \
    && rm -f /etc/nginx/sites-enabled/default


ENTRYPOINT ["/usr/local/bin/nginx-entrypoint.sh"]