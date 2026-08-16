# Inception User Documentation

## Services Provided

The Inception stack provides a WordPress website through three Docker services:

- **NGINX** — the only external entry point. It serves the website over HTTPS on port `443` and forwards PHP requests to WordPress/PHP-FPM.
- **WordPress + PHP-FPM** — runs the WordPress website application.
- **MariaDB** — stores WordPress database data such as users, posts, comments, and settings.

The website is available at:

```text
https://aechahid.42.fr
```

Only HTTPS is exposed. Plain HTTP on port `80` is not provided.

Because the project uses a self-signed TLS certificate, a browser may show a certificate warning during local testing.

## Start and Stop the Project

Run commands from the repository root.

Start or build the complete project:

```bash
make
```

or:

```bash
make up
```

Stop and remove the project containers and Compose network:

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

Follow service logs:

```bash
make logs
```

## Access the Website

Open:

```text
https://aechahid.42.fr
```

A user who is not logged in can access the public WordPress website.

The normal WordPress website user can log in at:

```text
https://aechahid.42.fr/wp-login.php
```

The normal user has limited permissions and does not have administrator privileges.

## Access the Administration Panel

The WordPress administration panel is available at:

```text
https://aechahid.42.fr/wp-admin
```

Log in with the administrator account configured for the project.

The administrator can manage the website, including pages, posts, comments, users, and WordPress settings.

## Credentials

Non-secret account and application configuration is stored in:

```text
srcs/.env
```

This includes values such as:

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

These files must remain private and must not be committed to Git.

For existing WordPress accounts, password changes should normally be performed through WordPress account/admin tools rather than by only editing the original secret file, because those secret files are primarily used by the project's initialization scripts.

## Check That the Services Are Running

From the project root, run:

```bash
docker compose -f srcs/docker-compose.yml ps
```

The expected services are:

```text
mariadb
wordpress
nginx
```

All three should be running.

Only NGINX should publish a host port, with HTTPS available on port `443`.

You can also verify the website directly in a browser:

```text
https://aechahid.42.fr
```

To inspect logs if something is not working:

```bash
make logs
```

The WordPress website and its stored data should remain available after the containers are recreated because the WordPress files and MariaDB database data are stored persistently on the host.
