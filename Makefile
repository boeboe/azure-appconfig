# HELP
# This will output the help for each task
# Thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: test-local help multipass-start multipass-stop multipass-delete multipass-ssh

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

test-local: ## Run all test scripts locally
	./test.sh

multipass-start: ## Start the VM, mount the current directory and install tools
	./multipass.sh start

multipass-stop: ## Stop the VM
	./multipass.sh stop

multipass-delete: ## Delete the VM
	./multipass.sh delete

multipass-ssh: ## SSH into the VM
	./multipass.sh ssh

generate-readme: ## Generate README.md files
	./readme.sh --input ./create-snapshot/action.yml --output ./create-snapshot/README.md
	./readme.sh --input ./set-keyvalue/action.yml --output ./set-keyvalue/README.md
	./readme.sh --input ./sync-config/action.yml --output ./sync-config/README.md
