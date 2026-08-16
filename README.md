*This project has been created as part of the 42 curriculum by aechahid.*

# Inception

## Description

Inception is a system administration project whose goal is to build and run a small web infrastructure using Docker Compose inside a virtual machine.

The mandatory infrastructure contains three services, each running in its own Docker container:

- **NGINX** — the only external entry point. It accepts HTTPS connections on port `443`, handles TLS, serves static files, and forwards PHP requests to PHP-FPM.
- **WordPress + PHP-FPM** — runs the WordPress PHP application. PHP-FPM listens on port `9000` inside the Docker network.
- **MariaDB** — stores WordPress database data such as users, posts, comments, and settings.

The containers communicate through a dedicated Docker network.

The architecture is:

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

Only NGINX publishes a port to the host.

The project also uses two persistent Docker named volumes:

```text
WordPress files
    -> wp_data
    -> /home/aechahid/data/wordpress

MariaDB data
    -> wp_db_data
    -> /home/aechahid/data/mariadb
```

This allows the website files and database data to survive container recreation.

---

## Project Structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/
│   ├── db_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── z-inception.cnf
        │   └── tools/
        │       └── mariadb-entrypoint.sh
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   └── tools/
        │       └── wordpress-entrypoint.sh
        │
        └── nginx/
            ├── Dockerfile
            ├── conf/
            │   └── inception.conf
            └── tools/
                └── nginx-entrypoint.sh
```

The secret files and `.env` file contain local configuration or confidential values and are not committed to Git.

---

## Instructions

### Prerequisites

The project is designed to run inside a Linux virtual machine with:

- Docker Engine
- Docker Compose
- GNU Make

The following host directories are used for persistent data:

```text
/home/aechahid/data/mariadb
/home/aechahid/data/wordpress
```

The Makefile creates them automatically when starting the project.

The domain used by the project is:

```text
aechahid.42.fr
```

It must resolve to the IP address of the virtual machine.

For local testing, this can be configured in `/etc/hosts`:

```text
<VM_IP> aechahid.42.fr
```

### Environment configuration

The project uses:

```text
srcs/.env
```

for non-secret configuration such as:

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

Passwords are stored separately in:

```text
secrets/db_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Secret values must not be committed to Git.

### Build and start

From the project root:

```bash
make
```

This:

1. creates the required persistent-data directories;
2. builds the Docker images;
3. starts the complete infrastructure with Docker Compose.

The website is then available at:

```text
https://aechahid.42.fr
```

Because the project uses a self-signed TLS certificate, the browser may display a certificate warning during local testing.

Plain HTTP on port `80` is not provided.

### Makefile commands

Start/build the project:

```bash
make
```

or:

```bash
make up
```

Build the images without starting the containers:

```bash
make build
```

Stop and remove the Compose containers and network:

```bash
make down
```

Stop the containers without removing them:

```bash
make stop
```

Start previously stopped containers:

```bash
make start
```

Follow container logs:

```bash
make logs
```

Clean the Compose project:

```bash
make clean
```

Remove containers, Compose volume objects, and project images:

```bash
make fclean
```

Rebuild the project from a clean Docker project state:

```bash
make re
```

The underlying persistent files in:

```text
/home/aechahid/data/
```

are not deleted by `make fclean`.

---

## Main Design Choices

### One service per container

NGINX, WordPress/PHP-FPM, and MariaDB run in separate containers.

This keeps each container focused on one main responsibility and allows the services to have separate configurations and lifecycles.

### NGINX as the only external entry point

Only NGINX publishes a host port:

```text
443 -> 443
```

WordPress/PHP-FPM and MariaDB are reachable only through the internal Docker network.

This means clients cannot directly connect to PHP-FPM or MariaDB from outside the Docker infrastructure.

### HTTPS only

NGINX handles TLS using a certificate and private key.

The configuration enables only:

```text
TLSv1.2
TLSv1.3
```

The certificate is self-signed for the project domain.

### Dedicated Docker network

All three services are connected to the same user-defined Docker network.

Services communicate using Compose service names, for example:

```text
wordpress -> mariadb
nginx -> wordpress
```

Docker's internal DNS resolves these names to the corresponding containers.

No host networking or legacy Docker links are used.

### Persistent storage

WordPress files and MariaDB database files have different persistence requirements, so two volumes are used:

```text
wp_data
wp_db_data
```

The volumes are Docker named volumes configured with the local driver so their data is stored under:

```text
/home/aechahid/data/
```

### Secrets separated from normal configuration

Normal configuration values are passed through environment variables.

Passwords are kept in separate secret files and mounted only into the containers that require them.

The services read the secret values from `/run/secrets/` at runtime.

### Real services as container processes

The containers run their actual long-running services in the foreground:

- `nginx`
- `php-fpm`
- `mariadbd`

Entrypoint scripts finish their initialization work and then use `exec` to replace the shell with the real service process.

Artificial keep-alive commands such as `tail -f` or `sleep infinity` are not used.

---

## Virtual Machines vs Docker

A **virtual machine** virtualizes an entire computer.

It has its own:

- operating system;
- kernel;
- virtual hardware;
- processes;
- filesystem.

Because every VM includes a complete operating system, virtual machines generally require more resources.

A **Docker container** isolates an application and its environment while sharing the host machine's kernel.

Containers are therefore generally lighter and faster to create than complete virtual machines.

In this project both are used:

```text
Physical machine
    |
    v
Virtual Machine
    |
    v
Docker Engine
    |
    +-- NGINX container
    +-- WordPress container
    +-- MariaDB container
```

The VM provides an isolated machine for the project, while Docker provides isolated environments for the individual services inside that VM.

---

## Secrets vs Environment Variables

### Environment variables

Environment variables are useful for normal application configuration.

Examples in this project include:

```text
DOMAIN_NAME
MARIADB_DATABASE
MARIADB_USER
WP_TITLE
```

They are available to the processes running inside the container.

They should not be treated as the preferred place for confidential passwords.

### Secrets

Secrets are intended for confidential values.

This project uses secret files for:

```text
MariaDB password
WordPress administrator password
WordPress normal-user password
```

Docker Compose mounts them into the required containers under:

```text
/run/secrets/
```

The application can then read the value from the file when it needs it.

So, conceptually:

```text
Environment variable
-> normal configuration

Secret
-> confidential configuration
```

---

## Docker Network vs Host Network

### Docker network

A user-defined Docker network gives containers their own isolated networking environment.

Containers connected to the same network can communicate with each other using service names.

For example:

```text
nginx -> wordpress:9000
wordpress -> mariadb
```

Only ports explicitly published through Compose become accessible from outside.

This is what the project uses.

### Host network

With host networking, a container shares the host's network namespace directly.

The container would use the host's networking stack instead of the isolated Docker networking model.

This reduces network isolation and bypasses normal Docker port publishing.

Host networking is not used in this project.

---

## Docker Volumes vs Bind Mounts

### Docker volume

A Docker volume is a storage object managed through Docker.

A service refers to the volume by its logical name:

```text
wp_data
wp_db_data
```

This separates the service configuration from the physical storage location.

In this project, the named volumes use the `local` driver with bind options so their data is stored in the required host directories:

```text
/home/aechahid/data/wordpress
/home/aechahid/data/mariadb
```

The service still mounts a Docker **named volume**, rather than declaring the host directory directly as a service bind mount.

### Bind mount

A direct bind mount maps a specific host path directly into a container.

Conceptually:

```text
/host/path -> /container/path
```

The service configuration therefore directly depends on that host filesystem path.

The mandatory persistent storage in this project is exposed to the services through Docker named volumes rather than direct service bind mounts.

---

## Resources

Resources used while studying and implementing the project included:

- **Docker documentation**
  - Docker Engine
  - Dockerfiles
  - Docker Compose
  - networking
  - volumes
  - environment variables
  - secrets
  - restart policies
- **NGINX documentation**
  - server configuration
  - TLS configuration
  - `try_files`
  - FastCGI configuration
- **PHP documentation**
  - PHP-FPM
- **WordPress documentation**
  - WordPress configuration
  - WordPress CLI
- **MariaDB documentation**
  - MariaDB server configuration
  - client connections
  - server initialization
- **OpenSSL documentation**
  - creation of a self-signed TLS certificate

Useful official documentation:

```text
https://docs.docker.com/
https://nginx.org/en/docs/
https://www.php.net/manual/en/install.fpm.php
https://developer.wordpress.org/cli/commands/
https://mariadb.com/kb/en/
https://docs.openssl.org/
```

---

## Use of AI

AI was used as a learning and review tool during the project.

It was used to:

- explain unfamiliar service-specific concepts such as NGINX, PHP-FPM, FastCGI, WordPress, MariaDB, and TLS;
- explain configuration directives and shell commands before they were used;
- help diagnose errors encountered during services configurations;
