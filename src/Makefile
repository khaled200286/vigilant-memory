MAKEFLAGS += --silent

.DEFAULT_GOAL := all

image := weather-forecast-api

.PHONY: all
all:
	docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

.PHONY: build
build: ## Build containers
	docker-compose build
	if [ -z "`git status --porcelain`" ]; then docker tag $(image):latest $(image):$(shell git describe --tags $(git rev-list --tags --max-count=1)); fi

.PHONY: up-develop
up-develop: ## Create and start develop containers
	docker compose up --no-deps -d app

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
	docker system prune -f
	docker image prune -f
