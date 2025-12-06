SHELL := /bin/bash

LOCALSTACK_TF_DIR := terraform/localstack
LOCALSTACK_TF_VARS ?= tflocal.tfvars
DOCKER_COMPOSE_CMD := $(shell if command -v docker-compose >/dev/null 2>&1; then echo docker-compose; else echo "docker compose"; fi)

setup:
	if ! command -v terraform >/dev/null 2>&1; then \
		brew tap hashicorp/tap; \
		brew install hashicorp/tap/terraform; \
	fi
	brew install uv || true
	uv python install 3.12
	uv venv --python 3.12
	. .venv/bin/activate && uv pip install -r requirements.txt

tf-local-init:
	cd $(LOCALSTACK_TF_DIR) && tflocal init

tf-local-plan:
	cd $(LOCALSTACK_TF_DIR) && tflocal plan -var-file=$(LOCALSTACK_TF_VARS)

tf-local-apply:
	cd $(LOCALSTACK_TF_DIR) && tflocal apply -auto-approve -var-file=$(LOCALSTACK_TF_VARS)

tf-local-up:
	$(DOCKER_COMPOSE_CMD) up -d
	$(DOCKER_COMPOSE_CMD) logs -f localstack &
	$(MAKE) tf-local-init
	$(MAKE) tf-local-plan
	$(MAKE) tf-local-apply

tf-local-up-test: tf-local-up
	$(MAKE) integration-test

tf-lint:
	$(MAKE) tf-local-init
	cd $(LOCALSTACK_TF_DIR) && terraform fmt

tf-lint-check:
	$(MAKE) tf-local-init
	cd $(LOCALSTACK_TF_DIR) && terraform fmt -check
	cd $(LOCALSTACK_TF_DIR) && tflocal validate

integration-test: tf-local-up
	$(DOCKER_COMPOSE_CMD) logs -f mock-producer &
	uv run --with-requirements tests/integration/requirements.txt python tests/integration/main.py
