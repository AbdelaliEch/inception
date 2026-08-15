#!/bin/sh
set -e

DB_PASSWORD="$(cat /run/secrets/db_password)"

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

cat > /run/mysqld/init.sql <<EOF
CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
EOF

chown mysql:mysql /run/mysqld/init.sql
chmod 600 /run/mysqld/init.sql

exec mariadbd --user=mysql --init-file=/run/mysqld/init.sql