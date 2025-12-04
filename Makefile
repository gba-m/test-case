SHELL := /bin/bash

LOCALSTACK_TF_DIR := terraform/localstack
TFLLOCAL ?= tflocal
LOCALSTACK_TF_VARS ?= tflocal.tfvars
DOCKER_COMPOSE_CMD := $(shell if command -v docker-compose >/dev/null 2>&1; then echo docker-compose; else echo "docker compose"; fi)

.PHONY: setup tf-local-init tf-local-plan tf-local-apply tf-local-up tf-lint

setup:
	if ! command -v terraform >/dev/null 2>&1; then \
		brew tap hashicorp/tap; \
		brew install hashicorp/tap/terraform; \
	fi
	brew install uv || true
	uv python install 3.15
	uv venv --python 3.15
	. .venv/bin/activate && uv pip install -r requirements.txt

tf-local-init:
	cd $(LOCALSTACK_TF_DIR) && $(TFLLOCAL) init

tf-local-plan:
	cd $(LOCALSTACK_TF_DIR) && $(TFLLOCAL) plan -var-file=$(LOCALSTACK_TF_VARS)

tf-local-apply:
	cd $(LOCALSTACK_TF_DIR) && $(TFLLOCAL) apply -auto-approve -var-file=$(LOCALSTACK_TF_VARS)

tf-local-up:
	$(DOCKER_COMPOSE_CMD) up -d localstack
	$(MAKE) tf-local-init
	$(MAKE) tf-local-plan
	$(MAKE) tf-local-apply

tf-lint:
	$(MAKE) tf-local-init
	cd $(LOCALSTACK_TF_DIR) && terraform fmt -check
	cd $(LOCALSTACK_TF_DIR) && $(TFLLOCAL) validate
