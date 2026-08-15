FROM debian:12

RUN apt update && apt install -y mariadb-server

COPY ./conf/z-inception.cnf /etc/mysql/mariadb.conf.d/

COPY ./tools/mariadb-entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/mariadb-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/mariadb-entrypoint.sh"]
