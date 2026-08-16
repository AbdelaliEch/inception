# Inception Developer Documentation

## Prerequisites

The project is designed to run inside a Linux virtual machine.

Required tools:

- Docker Engine
- Docker Compose
- GNU Make

The project uses the domain:

```text
aechahid.42.fr
```

It must resolve to the virtual machine's local IP address.

For local testing, add an entry such as the following to `/etc/hosts`:

```text
<VM_IP> aechahid.42.fr
```

## Project Configuration

The Docker Compose file is:

```text
srcs/docker-compose.yml
```

Service-specific files are under:

```text
srcs/requirements/
```

The project contains one Dockerfile for each mandatory service:

```text
srcs/requirements/mariadb/Dockerfile
srcs/requirements/wordpress/Dockerfile
srcs/requirements/nginx/Dockerfile
```

The services are built as:

```text
mariadb:1.0
wordpress:1.0
nginx:1.0
```

## Environment Variables

Non-secret configuration is stored in:

```text
srcs/.env
```

The current project expects values for:

```text
MARIADB_DATABASE
MARIADB_USER
DOMAIN_NAME
WP_TITLE
WP_ADMIN_USER
WP_ADMIN_EMAIL
WP_USER
WP_USER_EMAIL
```

Docker Compose passes only the environment variables required by each service into its container.

## Secrets

Confidential values are stored outside `srcs/.env` in:

```text
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Docker Compose mounts the required secret files inside containers under:

```text
/run/secrets/
```

The secrets directory and `srcs/.env` must not be committed to Git.

The repository `.gitignore` should contain:

```text
srcs/.env
secrets/
```

## Build and Launch

From the repository root, run:

```bash
make
```

The default Makefile target prepares the persistent-data directories and starts the full stack with Docker Compose.

The persistent host directories are:

```text
/home/aechahid/data/mariadb
/home/aechahid/data/wordpress
```

The Makefile creates them if they do not already exist.

The Compose command used by the Makefile is based on:

```bash
docker compose -f srcs/docker-compose.yml
```

To build and start explicitly:

```bash
make up
```

To build the images without starting the containers:

```bash
make build
```

## Container Management

Show the current service status:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Stop the running containers without removing them:

```bash
make stop
```

Start previously stopped containers:

```bash
make start
```

Stop and remove the Compose containers and network:

```bash
make down
```

Follow logs:

```bash
make logs
```

Clean the Compose project and remove orphan containers:

```bash
make clean
```

Remove the Compose containers, volume objects, and project images:

```bash
make fclean
```

Rebuild and start from a cleaned Docker project state:

```bash
make re
```

## Network Architecture

The three services share a user-defined Docker network named by Compose from `app-net`.

Communication is:

```text
Browser
   |
   | HTTPS :443
   v
NGINX
   |
   | FastCGI :9000
   v
WordPress + PHP-FPM
   |
   | MariaDB connection
   v
MariaDB
```

Only NGINX publishes a port to the host:

```text
443:443
```

WordPress/PHP-FPM and MariaDB are accessible only through the internal Docker network.

Service names are used for internal DNS resolution:

```text
nginx -> wordpress:9000
wordpress -> mariadb
```

## Persistent Storage

The project defines two Docker named volumes:

```text
wp_data
wp_db_data
```

They use the Docker `local` volume driver with bind options so that the actual persistent files are stored under the required host paths.

WordPress files:

```text
wp_data
-> /home/aechahid/data/wordpress
-> /var/www/html inside the WordPress and NGINX containers
```

MariaDB database files:

```text
wp_db_data
-> /home/aechahid/data/mariadb
-> /var/lib/mysql inside the MariaDB container
```

Removing the Docker volume objects with:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

does not delete the files stored in those host directories.

When Compose creates the named volume objects again, they point back to the same host directories and the existing data is available again.

Deleting the contents of the host directories themselves deletes the actual persistent WordPress or MariaDB data.

## Service Configuration

### MariaDB

MariaDB configuration is under:

```text
srcs/requirements/mariadb/
```

The server listens on the Docker network and stores its database files in `/var/lib/mysql`.

Its entrypoint prepares the runtime directory, creates an initialization SQL file from environment variables and the database secret, and then starts `mariadbd` as the foreground service process.

### WordPress + PHP-FPM

WordPress configuration is under:

```text
srcs/requirements/wordpress/
```

The image installs PHP-FPM, the PHP extensions required by WordPress, WP-CLI, and the MariaDB client.

PHP-FPM is configured to listen on:

```text
0.0.0.0:9000
```

The entrypoint:

1. reads the database secret;
2. downloads WordPress if the persistent files do not already exist;
3. creates `wp-config.php` if needed;
4. waits for MariaDB to become reachable;
5. initializes WordPress if the database is not already initialized;
6. creates the normal WordPress website user if needed;
7. starts PHP-FPM in the foreground.

### NGINX + TLS

NGINX configuration is under:

```text
srcs/requirements/nginx/
```

NGINX listens on HTTPS port `443` and enables only:

```text
TLSv1.2
TLSv1.3
```

It serves files from:

```text
/var/www/html
```

and sends PHP requests to:

```text
wordpress:9000
```

using FastCGI.

The NGINX entrypoint creates a self-signed TLS certificate if one does not exist in the container and then starts NGINX in the foreground.

## Persistence Behavior

The persistent data is not stored only inside the containers.

The important host locations are:

```text
/home/aechahid/data/wordpress
/home/aechahid/data/mariadb
```

Therefore, recreating the containers does not remove the website files or database data.

After the project is started again, WordPress should retain its users, comments, pages, settings, and other database-backed content, together with the persisted WordPress files.

## Useful Validation Commands

Show Compose configuration after environment interpolation:

```bash
docker compose -f srcs/docker-compose.yml config
```

Show running services:

```bash
docker compose -f srcs/docker-compose.yml ps
```

Show project images:

```bash
docker image ls
```

Follow logs:

```bash
make logs
```

Test HTTPS while ignoring the self-signed certificate warning:

```bash
curl -k https://aechahid.42.fr/
```

Plain HTTP should not be available:

```bash
curl http://aechahid.42.fr/
```

The final stack should contain the three mandatory services, one user-defined Docker network, two persistent volumes, and only NGINX exposed externally on port `443`.
