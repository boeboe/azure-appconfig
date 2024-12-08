# HELP
# This will output the help for each task
# Thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: test-local help check-multipass start-and-mount stop-vm delete-vm ssh-vm

.DEFAULT_GOAL := help

# VM Configurations
VM_NAME := test-azure-appconfig
VM_MEMORY := 2G
VM_DISK := 10G
VM_CPUS := 2
VM_MOUNT_PATH := /home/ubuntu/azure-appconfig
PWD_PATH := $(shell pwd)
SCRIPTS_DIR := $(VM_MOUNT_PATH)/scripts
TEST_DIR := $(VM_MOUNT_PATH)/tests

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test-local: ## Run all test-*.sh scripts in ./tests
	@echo "Running all test scripts in ./tests..."
	@find ./tests -type f -name 'test_*.sh' -exec bash {} \;

check-multipass: ## Check if Multipass is installed
	@if ! command -v multipass &>/dev/null; then \
		echo "Multipass is not installed. Please install Multipass to proceed."; \
		exit 1; \
	else \
		echo "Multipass is installed."; \
	fi

start-and-mount: check-multipass ## Start the VM and mount the current directory
	@if ! multipass list | grep -q $(VM_NAME); then \
		echo "Starting Multipass VM '$(VM_NAME)'..."; \
		multipass launch --name $(VM_NAME) --memory $(VM_MEMORY) --disk $(VM_DISK) --cpus $(VM_CPUS); \
	fi; \
	if ! multipass info $(VM_NAME) | grep -q "$(VM_MOUNT_PATH)"; then \
		echo "Mounting '$(PWD_PATH)' to '$(VM_NAME):$(VM_MOUNT_PATH)'..."; \
		multipass mount $(PWD_PATH) $(VM_NAME):$(VM_MOUNT_PATH); \
	else \
		echo "'$(VM_MOUNT_PATH)' is already mounted in '$(VM_NAME)'."; \
	fi; \
	echo "Ensuring SCRIPTS_DIR and TEST_DIR are added to the PATH inside the VM..."; \
	multipass exec $(VM_NAME) -- bash -c "grep -q 'export SCRIPTS_DIR=$(SCRIPTS_DIR)' ~/.bashrc || echo 'export SCRIPTS_DIR=$(SCRIPTS_DIR)' >> ~/.bashrc"; \
	multipass exec $(VM_NAME) -- bash -c "grep -q 'export PATH=$(SCRIPTS_DIR):\$$PATH' ~/.bashrc || echo 'export PATH=$(SCRIPTS_DIR):\$$PATH' >> ~/.bashrc"; \
	multipass exec $(VM_NAME) -- bash -c "grep -q 'export PATH=$(TEST_DIR):\$$PATH' ~/.bashrc || echo 'export PATH=$(TEST_DIR):\$$PATH' >> ~/.bashrc";

stop-vm: check-multipass ## Stop the VM
	@if multipass list | grep -q $(VM_NAME); then \
		echo "Stopping Multipass VM '$(VM_NAME)'..."; \
		multipass stop $(VM_NAME); \
	else \
		echo "Multipass VM '$(VM_NAME)' is not running."; \
	fi

delete-vm: check-multipass ## Delete the VM
	@if multipass list | grep -q $(VM_NAME); then \
		echo "Deleting Multipass VM '$(VM_NAME)'..."; \
		multipass delete $(VM_NAME); \
		multipass purge; \
	else \
		echo "Multipass VM '$(VM_NAME)' does not exist."; \
	fi

ssh-vm: check-multipass ## SSH into the VM
	@if multipass list | grep -q $(VM_NAME); then \
		echo "Connecting to Multipass VM '$(VM_NAME)'..."; \
		multipass shell $(VM_NAME); \
	else \
		echo "Multipass VM '$(VM_NAME)' is not running. Please start it first."; \
	fi