SHELL := /usr/bin/env bash
ROOT := ${CURDIR}

.PHONY: create
create:
	@$(ROOT)/src/scripts/create.sh -e $(ENVIRONMENT)