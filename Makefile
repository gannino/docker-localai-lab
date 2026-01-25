# Docker AI Lab - Modular Makefile
# Main entry point that includes all modular components

# Strict error handling
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: help

# Default target
help: ## Show this help message
	@echo "Docker Infrastructure - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) makefiles/*.mk | \
		sed 's|makefiles/[^:]*:||' | \
		sort -u | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Include modular makefiles
include makefiles/setup.mk
include makefiles/services.mk
include makefiles/backup.mk
include makefiles/testing.mk
