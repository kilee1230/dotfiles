.PHONY: help install adopt dry-run relink clean-backups

SHELL := /bin/bash
REPO_DIR := $(shell cd "$(dir $(lastword $(MAKEFILE_LIST)))" && pwd)
INSTALL := $(REPO_DIR)/install.sh

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"}; /^[a-zA-Z0-9_-]+:.*?##/ {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Symlink configs from repo to home (~/.config, ~, ~/.ssh)
	@bash $(INSTALL)

adopt: ## Move existing configs from home into repo, then symlink
	@bash $(INSTALL) --adopt

dry-run: ## Preview actions (adopt + link) without changing anything
	@bash $(INSTALL) --dry-run --adopt

relink: ## Force re-link by removing existing symlinks at destinations
	@bash -lc 'find $$HOME -maxdepth 1 -type l -name ".*" -print0 | xargs -0 -I{} rm -v {} || true; find $$HOME/.config -type l -print0 | xargs -0 -I{} rm -v {} || true; find $$HOME/.ssh -maxdepth 1 -type l -print0 | xargs -0 -I{} rm -v {} || true;'; \
	bash $(INSTALL)

clean-backups: ## Remove backups created by install script (.bak.*)
	@bash -lc 'find $$HOME -maxdepth 1 -name "*.bak.*" -delete; find $$HOME/.config -name "*.bak.*" -delete; find $$HOME/.ssh -name "*.bak.*" -delete' 