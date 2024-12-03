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

# Function to fetch current Azure features
function get_current_az_features() {
  local cmd=("az appconfig feature list")
  cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
  [[ -n "${INPUT_PREFIX:-}" ]] && cmd+=("--feature '${INPUT_PREFIX}*'")
  [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")
  cmd+=("--fields name state description --output json")

  local output
  output=$(eval "${cmd[*]}") || {
    print_error "Failed to fetch current Azure features."
    exit 1
  }

  parse_az_features "${output}"
}

# Function to delete features from Azure App Configuration
function delete_current_az_features() {
  local to_delete="$1"

  print_info "Deleting features from Azure App Configuration..."
  echo "${to_delete}" | jq -c '.entries[]' | while read -r entry; do
    local name
    name=$(echo "${entry}" | jq -r '.key')

    local cmd=("az appconfig feature delete")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--name '${name}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to delete feature: ${name}"
      return 1
    }
    print_success "Deleted feature: ${name}"
  done
}

# Function to log features that are left untouched
function keep_current_az_features() {
  local common_equal="$1"

  print_info "Keeping existing features unchanged in Azure App Configuration..."
  echo "${common_equal}" | jq -c '.entries[]' | while read -r entry; do
    local name
    name=$(echo "${entry}" | jq -r '.key')

    print_info "Feature remains unchanged: ${name}"
  done
}

# Function to update existing features in Azure App Configuration
function update_current_az_features() {
  local to_update="$1"

  print_info "Updating features in Azure App Configuration..."
  echo "${to_update}" | jq -c '.entries[]' | while read -r entry; do
    local name state description
    name=$(echo "${entry}" | jq -r '.key')
    state=$(echo "${entry}" | jq -r '.value')
    description=$(echo "${entry}" | jq -r '.description')

    local cmd=("az appconfig feature set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--name '${name}'")
    cmd+=("--state '${state}'")
    [[ -n "${description}" ]] && cmd+=("--description '${description}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to update feature: ${name}"
      return 1
    }
    print_success "Updated feature: ${name}"
  done
}

# Function to create new features in Azure App Configuration
function create_new_az_features() {
  local to_create="$1"

  print_info "Creating new features in Azure App Configuration..."
  echo "${to_create}" | jq -c '.entries[]' | while read -r entry; do
    local name state description
    name=$(echo "${entry}" | jq -r '.key')
    state=$(echo "${entry}" | jq -r '.value')
    description=$(echo "${entry}" | jq -r '.description')

    local cmd=("az appconfig feature set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--name '${name}'")
    cmd+=("--state '${state}'")
    [[ -n "${description}" ]] && cmd+=("--description '${description}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to create feature: ${name}"
      return 1
    }
    print_success "Created feature: ${name}"
  done
}
