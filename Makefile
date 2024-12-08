# HELP
# This will output the help for each task
# Thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: test-local help multipass-start multipass-stop multipass-delete multipass-ssh

.DEFAULT_GOAL := help

# Define action directories (one list for all actions)
ACTIONS := create-snapshot set-keyvalue sync-config

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

# Generate top-level README
generate-readme: ## Generate README.md files
	./readme.sh general --input $(foreach action,$(ACTIONS),./$(action)/action.yml) --output ./README.md
	$(foreach action,$(ACTIONS),./readme.sh action --input ./$(action)/action.yml --output ./$(action)/README.md &&) true
