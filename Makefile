# Compatible with GNU Make 3.81 (macOS) and 4.x (WSL2).
SHELL := /bin/sh
.DEFAULT_GOAL := help

.PHONY: help doctor bootstrap pull-all infra-up infra-down infra-reset infra-status infra-check clean

help: ## List available commands
	@grep -E '^[a-zA-Z_-]+:.*## ' $(firstword $(MAKEFILE_LIST)) | \
		awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

doctor: ## Check required tools and Docker resources
	@sh scripts/doctor.sh

bootstrap: ## Clone every repository in repos.txt next to this one
	@sh scripts/bootstrap.sh

pull-all: ## Update main in every cloned repository (skips dirty ones)
	@sh scripts/pull-all.sh

infra-up: ## Start Floci, Postgres and Valkey and wait until healthy
	@sh scripts/infra.sh up

infra-down: ## Stop infrastructure, keep data
	@sh scripts/infra.sh down

infra-reset: ## Stop infrastructure and DELETE its data (asks first; FORCE=1 skips)
	@sh scripts/infra-reset.sh

infra-status: ## Show infrastructure containers, health and memory
	@sh scripts/infra.sh status

infra-check: ## Verify infrastructure health and database isolation
	@sh scripts/infra-check.sh

clean: ## Remove dangling Docker images and build cache
	@sh scripts/clean.sh
