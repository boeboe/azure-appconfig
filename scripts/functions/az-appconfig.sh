#!/usr/bin/env bash
# az-appconfig.sh - Functions to interact with Azure App Configuration using Azure CLI

# Function to set a key-value pair in Azure App Configuration
function set_az_keyvalue() {
  local payload="$1"

  local connectionString key value prefix label tags
  connectionString=$(echo "${payload}" | jq -r '.connectionString')
  key=$(echo "${payload}" | jq -r '.key')
  value=$(echo "${payload}" | jq -r '.value')
  prefix=$(echo "${payload}" | jq -r '.prefix')
  label=$(echo "${payload}" | jq -r '.label')
  tags=$(echo "${payload}" | jq -r '.tags')

  [[ -n "${prefix}" && "${prefix}" != "null" ]] && key="${prefix}${key}"

  local cmd=("az appconfig kv set")
  cmd+=("--yes")
  cmd+=("--connection-string '${connectionString}'")
  cmd+=("--key '${key}'")
  cmd+=("--value '${value}'")
  [[ -n "${label}" && "${label}" != "null" ]] && cmd+=("--label '${label}'")
  [[ -n "${tags}" && "${tags}" != "null" ]] && cmd+=("--tags '${tags}'")

  eval "${cmd[*]}" || {
    print_error "Failed to set key-value pair in Azure App Configuration: ${key}"
    exit 1
  }

  print_success "Successfully set key-value pair: ${key}"
}

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
    local key value
    key=$(echo "${entry}" | jq -r '.key')
    value=$(echo "${entry}" | jq -r '.value')

    local cmd=("az appconfig kv set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--key '${key}'")
    cmd+=("--value '${value}'")
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
    local key value
    key=$(echo "${entry}" | jq -r '.key')
    value=$(echo "${entry}" | jq -r '.value')

    local cmd=("az appconfig kv set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--key '${key}'")
    cmd+=("--value '${value}'")
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
  cmd+=("--fields name state --output json")

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
    local feature
    feature=$(echo "${entry}" | jq -r '.key')

    local cmd=("az appconfig feature delete")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--feature '${feature}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to delete feature: ${feature}"
      return 1
    }
    print_success "Deleted feature: ${feature}"
  done
}

# Function to log features that are left untouched
function keep_current_az_features() {
  local common_equal="$1"

  print_info "Keeping existing features unchanged in Azure App Configuration..."
  echo "${common_equal}" | jq -c '.entries[]' | while read -r entry; do
    local feature
    feature=$(echo "${entry}" | jq -r '.key')

    print_info "Feature remains unchanged: ${feature}"
  done
}

# Function to update existing feature flags in Azure App Configuration
function update_current_az_features() {
  local to_update="$1"

  print_info "Updating feature flags in Azure App Configuration..."
  echo "${to_update}" | jq -c '.entries[]' | while read -r entry; do
    local feature enabled
    feature=$(echo "${entry}" | jq -r '.key')
    enabled=$(echo "${entry}" | jq -r '.value')

    # Parse the enabled state
    enabled=$(parse_az_feature_state "${enabled}") || {
      print_warning "Invalid state for feature: ${feature}. Skipping..."
      continue
    }

    # Step 1: Create or update the feature flag
    local cmd=("az appconfig feature set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--feature '${feature}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to create or update feature flag: ${feature}"
      return 1
    }
    print_success "Created or updated feature flag: ${feature}"

    # Step 2: Set the state of the feature flag
    set_feature_flag_state "${feature}" "${enabled}" || {
      print_error "Failed to set state for feature flag: ${feature}"
      return 1
    }

    print_success "Feature flag updated successfully: ${feature}"
  done
}

# Function to create new feature flags in Azure App Configuration
function create_new_az_features() {
  local to_create="$1"

  print_info "Creating new feature flags in Azure App Configuration..."
  echo "${to_create}" | jq -c '.entries[]' | while read -r entry; do
    local feature enabled
    feature=$(echo "${entry}" | jq -r '.key')
    enabled=$(echo "${entry}" | jq -r '.value')

    # Parse the enabled state
    enabled=$(parse_az_feature_state "${enabled}") || {
      print_warning "Invalid state for feature: ${feature}. Skipping..."
      continue
    }

    # Step 1: Create or update the feature flag
    local cmd=("az appconfig feature set")
    cmd+=("--yes")
    cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
    cmd+=("--feature '${feature}'")
    [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")

    eval "${cmd[*]}" || {
      print_error "Failed to create feature flag: ${feature}"
      return 1
    }
    print_success "Created feature flag: ${feature}"

    # Step 2: Set the state of the feature flag
    set_feature_flag_state "${feature}" "${enabled}" || {
      print_error "Failed to set state for feature flag: ${feature}"
      return 1
    }

    print_success "Feature flag created successfully: ${feature}"
  done
}

# Function to set the state of a feature flag in Azure App Configuration
function set_feature_flag_state() {
  local feature="$1"
  local enabled="$2"

  # Ensure the enabled state is valid
  local cmd=()

  if [[ "${enabled}" == "true" ]]; then
    print_info "Enabling feature flag: ${feature}"
    cmd=("az appconfig feature enable")
  else
    print_info "Disabling feature flag: ${feature}"
    cmd=("az appconfig feature disable")
  fi

  cmd+=("--yes")
  cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
  cmd+=("--feature '${feature}'")
  [[ -n "${INPUT_LABEL:-}" && "${INPUT_LABEL}" != '\0' ]] && cmd+=("--label '${INPUT_LABEL}'")

  eval "${cmd[*]}" || {
    print_error "Failed to set state for feature flag: ${feature}"
    return 1
  }
  print_success "Feature flag state set successfully: ${feature}"
}

# Function to create a snapshot in Azure App Configuration
function create_az_snapshot() {
  local payload="$1"

  local connectionString name filters compositionType retentionPeriod tags
  connectionString=$(echo "${payload}" | jq -r '.connectionString')
  name=$(echo "${payload}" | jq -r '.name')
  filters=$(echo "${payload}" | jq -r '.filters')
  compositionType=$(echo "${payload}" | jq -r '.compositionType // "key"')
  retentionPeriod=$(echo "${payload}" | jq -r '.retentionPeriod // null')
  tags=$(echo "${payload}" | jq -r '.tags // null')

  # Construct the az CLI command
  local cmd=("az appconfig snapshot create")
  cmd+=("--snapshot-name '${name}'")
  cmd+=("--connection-string '${connectionString}'")
  cmd+=("--filters ${filters}")
  cmd+=("--composition-type '${compositionType}'")
  [[ -n "${retentionPeriod}" && "${retentionPeriod}" != "null" ]] && cmd+=("--retention-period '${retentionPeriod}'")
  [[ -n "${tags}" && "${tags}" != "null" ]] && cmd+=("--tags '${tags}'")

  # Execute the command
  eval "${cmd[*]}" || {
    print_error "Failed to create snapshot in Azure App Configuration: ${name}"
    exit 1
  }

  print_success "Successfully created snapshot: ${name}"
}