ARGS = $(filter-out $@,$(MAKECMDGOALS))
MAKEFLAGS += --silent

.DEFAULT_GOAL := help

.PHONY: build
build: ## Build containers
	docker-compose build

.PHONY: up-develop
up-develop: ## Create and start develop containers
	docker-compose up -d

.PHONY: up-production
up-production: build ## Create and start production containers
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up --no-deps -d

.PHONY: logs
logs: ## View output from containers
	docker-compose logs -f

.PHONY: status
status: ## List containers
	docker-compose ps -a

.PHONY: stop
stop: ## Stop containers
	docker-compose stop

.PHONY: clean
clean: stop ## Stop and remove containers, networks, images, and volumes
	docker-compose down --volumes --remove-orphans

.PHONY: test
test: ## Test app
	[ -f ./tests/test.sh ] && ./tests/test.sh || true

help:
	cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

-include include.mk
