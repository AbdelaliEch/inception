COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_DIR = /home/aechahid/data


all: up

prepare:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress

build:
	$(COMPOSE) build

up: prepare
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

stop:
	$(COMPOSE) stop

start:
	$(COMPOSE) start

logs:
	$(COMPOSE) logs -f

clean:
	$(COMPOSE) down --remove-orphans

fclean:
	$(COMPOSE) down -v --remove-orphans --rmi all

re: fclean all

.PHONY: all prepare build up down stop start logs clean fclean re
