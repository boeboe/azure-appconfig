#!/usr/bin/env bash
# az-appconfig.sh - Functions to interact with Azure App Configuration using Azure CLI

# Function to fetch current Azure properties (do not forget the wildcard for prefix filtering with --key)
function get_current_az_properties() {
  local cmd=("az appconfig kv list")
  cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
  [[ -n "${INPUT_PREFIX:-}" ]] && cmd+=("--key '${INPUT_PREFIX}*'")
  [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")
  cmd+=("--fields key value tags --output json")

  local output
  output=$(eval "${cmd[*]}") || {
    print_error "Failed to fetch current Azure properties."
    exit 1
  }

  parse_az_kv_properties "${output}"
}

# Function to delete keys from Azure App Configuration
function delete_current_az_properties() {
  local to_delete="$1"

  print_info "Deleting keys from Azure App Configuration..."
  echo "${to_delete}" | jq -c '.entries[]' | while read -r entry; do
    local key
    key=$(echo "${entry}" | jq -r '.key')

    local cmd=("az appconfig kv delete")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--key '${key}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to delete key: ${key}"
      return 1
    }
    print_success "Deleted key: ${key}"
  done
}

# Function to log keys that are left untouched
function keep_current_az_properties() {
  local common_equal="$1"

  print_info "Keeping existing keys unchanged in Azure App Configuration..."
  echo "${common_equal}" | jq -c '.entries[]' | while read -r entry; do
    local key
    key=$(echo "${entry}" | jq -r '.key')

    print_info "Key remains unchanged: ${key}"
  done
}

# Function to update existing keys in Azure App Configuration
function update_current_az_properties() {
  local to_update="$1"

  print_info "Updating keys in Azure App Configuration..."
  echo "${to_update}" | jq -c '.entries[]' | while read -r entry; do
    local key value description
    key=$(echo "${entry}" | jq -r '.key')
    value=$(echo "${entry}" | jq -r '.value')
    description=$(echo "${entry}" | jq -r '.description')

    local cmd=("az appconfig kv set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--key '${key}'")
    cmd+=("--value '${value}'")
    cmd+=("--tags 'description=${description}'")
    [[ "${INPUT_CONTENT_TYPE}" == "keyvaultref" ]] && cmd+=("--content-type 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to update key: ${key}"
      return 1
    }
    print_success "Updated key: ${key}"
  done
}

# Function to create new keys in Azure App Configuration
function create_new_az_properties() {
  local to_create="$1"

  print_info "Creating new keys in Azure App Configuration..."
  echo "${to_create}" | jq -c '.entries[]' | while read -r entry; do
    local key value description
    key=$(echo "${entry}" | jq -r '.key')
    value=$(echo "${entry}" | jq -r '.value')
    description=$(echo "${entry}" | jq -r '.description')

    local cmd=("az appconfig kv set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--key '${key}'")
    cmd+=("--value '${value}'")
    cmd+=("--tags 'description=${description}'")
    [[ "${INPUT_CONTENT_TYPE}" == "keyvaultref" ]] && cmd+=("--content-type 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to create key: ${key}"
      return 1
    }
    print_success "Created key: ${key}"
  done
}