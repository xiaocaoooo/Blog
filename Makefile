MIZUKI_REPO ?= LyraVoid/Shirone
MIZUKI_DIR  ?= mizuki
CONTENT_DIR ?= .

override MIZUKI_DIR  := $(abspath $(MIZUKI_DIR))
override CONTENT_DIR := $(abspath $(CONTENT_DIR))

MIZUKI_NAME := $(notdir $(MIZUKI_DIR))
PATCH_FILE  := $(CONTENT_DIR)/diff.patch

.PHONY: all setup install sync build preview clean help

all: build

help:
	@echo "Available targets:"
	@echo "  setup       - Clone Mizuki repository if not exists and install dependencies"
	@echo "  install     - Install dependencies in Mizuki directory"
	@echo "  sync        - Sync content files to Mizuki directory"
	@echo "  build       - Sync content and build the blog site"
	@echo "  preview     - Build site and start preview server"
	@echo "  clean       - Clean build artifacts in Mizuki directory"

ifndef SKIP_SETUP
sync: setup
else
sync:
endif

setup:
	@if [ ! -d "$(MIZUKI_DIR)" ] || [ ! -d "$(MIZUKI_DIR)/.git" ]; then \
		echo "Cloning $(MIZUKI_REPO)..."; \
		rm -rf "$(MIZUKI_DIR)"; \
		git clone --depth 1 "https://github.com/$(MIZUKI_REPO).git" "$(MIZUKI_DIR)"; \
	else \
		CURRENT_REMOTE=$$(cd "$(MIZUKI_DIR)" && git config --get remote.origin.url || true); \
		if ! echo "$$CURRENT_REMOTE" | grep -q "$(MIZUKI_REPO)"; then \
			echo "Remote URL mismatch (current: $$CURRENT_REMOTE). Re-cloning $(MIZUKI_REPO)..."; \
			rm -rf "$(MIZUKI_DIR)"; \
			git clone --depth 1 "https://github.com/$(MIZUKI_REPO).git" "$(MIZUKI_DIR)"; \
		else \
			echo "Updating $(MIZUKI_DIR) repository..."; \
			cd "$(MIZUKI_DIR)" && git reset --hard HEAD && git clean -fd && (git pull origin $$(git rev-parse --abbrev-ref HEAD) || true); \
		fi; \
	fi
	@cd "$(MIZUKI_DIR)" && pnpm install

install:
	@cd "$(MIZUKI_DIR)" && pnpm install

sync:
	@mkdir -p "$(MIZUKI_DIR)/src/content/posts"
	@rm -rf "$(MIZUKI_DIR)/src/content/posts/"* || true
	@rsync -av "$(CONTENT_DIR)/" "$(MIZUKI_DIR)/" \
		--exclude=.git \
		--exclude=.gitignore \
		--exclude=.github \
		--exclude=$(MIZUKI_NAME) \
		--exclude=Makefile \
		--exclude=node_modules
	@if [ -f "$(PATCH_FILE)" ]; then \
		echo "Applying patch: $(PATCH_FILE)"; \
		cd "$(MIZUKI_DIR)" && git apply "$(PATCH_FILE)"; \
	else \
		echo "WARN: patch not found at $(PATCH_FILE), skipping."; \
	fi

build: sync
	cd "$(MIZUKI_DIR)" && pnpm build

preview: build
	cd "$(MIZUKI_DIR)" && pnpm preview

clean:
	rm -rf "$(MIZUKI_DIR)/dist" "$(MIZUKI_DIR)/.astro"
