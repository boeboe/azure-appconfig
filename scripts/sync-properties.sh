#!/usr/bin/env bash
# sync-properties.sh - Script to validate inputs and perform sync operations for Azure App Configuration
# shellcheck disable=SC1091

set -euo pipefail

# Source the shared logging and validation utilities
source "${SCRIPTS_DIR}/logging.sh"
source "${SCRIPTS_DIR}/validation.sh"
source "${SCRIPTS_DIR}/parsing.sh"
source "${SCRIPTS_DIR}/json.sh"

# Usage message
function usage() {
  local usage_message="Usage: $0 --validate-inputs | --perform-property-sync [ARGUMENTS]\n"
  usage_message+="Arguments:\n"
  usage_message+="  --configuration-file <file>\n"
  usage_message+="  --format <json|yaml|properties>\n"
  usage_message+="  --connection-string <string>\n"
  usage_message+="  --separator <separator>\n"
  usage_message+="  --strict <true|false>\n"
  usage_message+="  --prefix <prefix>\n"
  usage_message+="  --label <label>\n"
  usage_message+="  --depth <depth>\n"
  usage_message+="  --tags <tags>\n"
  usage_message+="  --content-type <contentType>\n"
  print_info "$usage_message"
  exit 1
}

# Parse arguments into variables
function parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --configuration-file)
        INPUT_CONFIGURATION_FILE="$2"
        shift 2
        ;;
      --format)
        INPUT_FORMAT="$2"
        shift 2
        ;;
      --connection-string)
        INPUT_CONNECTION_STRING="$2"
        shift 2
        ;;
      --separator)
        INPUT_SEPARATOR="$2"
        shift 2
        ;;
      --strict)
        INPUT_STRICT="$2"
        shift 2
        ;;
      --prefix)
        INPUT_PREFIX="$2"
        shift 2
        ;;
      --label)
        INPUT_LABEL="$2"
        shift 2
        ;;
      --depth)
        INPUT_DEPTH="$2"
        shift 2
        ;;
      --tags)
        INPUT_TAGS="$2"
        shift 2
        ;;
      --content-type)
        INPUT_CONTENT_TYPE="$2"
        shift 2
        ;;
      --validate-inputs)
        ACTION="validate_inputs"
        shift
        ;;
      --perform-property-sync)
        ACTION="perform_property_sync"
        shift
        ;;
      *)
        print_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Ensure an action is specified
  if [[ -z "${ACTION:-}" ]]; then
    print_error "No action specified (e.g., --validate-inputs or --perform-property-sync)."
    usage
  fi
}

# Function to print all parsed arguments
function print_env_vars() {
  local env_vars_message="Debugging environment variables for action:\n"
  env_vars_message+="  INPUT_CONFIGURATION_FILE=${INPUT_CONFIGURATION_FILE:-<not set>}\n"
  env_vars_message+="  INPUT_FORMAT=${INPUT_FORMAT:-<not set>}\n"
  env_vars_message+="  INPUT_CONNECTION_STRING=${INPUT_CONNECTION_STRING:-<not set>}\n"
  env_vars_message+="  INPUT_SEPARATOR=${INPUT_SEPARATOR:-<not set>}\n"
  env_vars_message+="  INPUT_STRICT=${INPUT_STRICT:-<not set>}\n"
  env_vars_message+="  INPUT_PREFIX=${INPUT_PREFIX:-<not set>}\n"
  env_vars_message+="  INPUT_LABEL=${INPUT_LABEL:-<not set>}\n"
  env_vars_message+="  INPUT_DEPTH=${INPUT_DEPTH:-<not set>}\n"
  env_vars_message+="  INPUT_TAGS=${INPUT_TAGS:-<not set>}\n"
  env_vars_message+="  INPUT_CONTENT_TYPE=${INPUT_CONTENT_TYPE:-<not set>}\n"
  print_info "$env_vars_message"
}

# Function to validate inputs
function validate_inputs() {
  print_info "Validating inputs..."
  print_env_vars

  # Required fields
  validate_set "INPUT_CONFIGURATION_FILE" "${INPUT_CONFIGURATION_FILE:-}"
  validate_file_exists "INPUT_CONFIGURATION_FILE" "${INPUT_CONFIGURATION_FILE}"
  validate_set "INPUT_FORMAT" "${INPUT_FORMAT:-}"
  validate_enum "INPUT_FORMAT" "${INPUT_FORMAT}" "json" "yaml" "properties"
  validate_set "INPUT_CONNECTION_STRING" "${INPUT_CONNECTION_STRING:-}"

  # Conditional validation for INPUT_SEPARATOR
  if [[ "${INPUT_FORMAT}" == "json" || "${INPUT_FORMAT}" == "yaml" ]]; then
    validate_set "INPUT_SEPARATOR" "${INPUT_SEPARATOR:-}"
  elif [[ "${INPUT_FORMAT}" == "properties" && -n "${INPUT_SEPARATOR:-}" ]]; then
    print_error "INPUT_SEPARATOR is not valid for 'properties' format."
    exit 1
  fi

  # Validation for INPUT_CONTENT_TYPE
  validate_enum "INPUT_CONTENT_TYPE" "${INPUT_CONTENT_TYPE:-keyvalue}" "keyvalue" "keyvaultref" "featureflag"
  if [[ "${INPUT_CONTENT_TYPE}" =~ ^(keyvaultref|featureflag)$ && "${INPUT_FORMAT}" != "json" ]]; then
    print_error "INPUT_CONTENT_TYPE '${INPUT_CONTENT_TYPE}' requires INPUT_FORMAT to be 'json'. Provided: '${INPUT_FORMAT}'"
    exit 1
  fi

  # Optional fields
  [[ -n "${INPUT_STRICT:-}" ]] && validate_boolean "INPUT_STRICT" "${INPUT_STRICT}"
  [[ -n "${INPUT_DEPTH:-}" ]] && validate_positive_integer "INPUT_DEPTH" "${INPUT_DEPTH}"
  [[ -n "${INPUT_TAGS:-}" ]] && validate_json "INPUT_TAGS" "${INPUT_TAGS}"

  print_success "All inputs validated successfully."
}

# Function to fetch current Azure properties
function get_current_az_properties() {
  local cmd=("az appconfig kv list")
  cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")
  [[ -n "${INPUT_PREFIX:-}" ]] && cmd+=("--key '${INPUT_PREFIX}'")
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
    az appconfig kv delete --yes --connection-string "${INPUT_CONNECTION_STRING}" --key "${key}" || {
      print_error "Failed to delete key: ${key}"
      return 1
    }
    print_success "Deleted key: ${key}"
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

    az appconfig kv set --yes --connection-string "${INPUT_CONNECTION_STRING}" \
      --key "${key}" --value "${value}" --tags "description=${description}" || {
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

    az appconfig kv set --yes --connection-string "${INPUT_CONNECTION_STRING}" \
      --key "${key}" --value "${value}" \
      --tags "description=${description}" \
      ${INPUT_CONTENT_TYPE:+--content-type "${INPUT_CONTENT_TYPE}"} || {
      print_error "Failed to create key: ${key}"
      return 1
    }
    print_success "Created key: ${key}"
  done
}

# Main function to perform property sync
function perform_property_sync() {
  print_info "Starting property sync operation..."

  # Step 1: Parse the input file
  local desired_properties
  desired_properties=$(parse_properties_file "${INPUT_CONFIGURATION_FILE}") || {
    print_error "Failed to parse input file: ${INPUT_CONFIGURATION_FILE}"
    exit 1
  }

  print_info "---------------"
  print_info "${desired_properties}"
  print_info "---------------"

  # Step 2: Fetch existing properties
  print_info "Fetching current properties from Azure App Configuration..."
  local existing_properties
  existing_properties=$(get_current_az_properties) || {
    print_error "Failed to fetch existing Azure properties."
    exit 1
  }

  # Step 3: Handle strict mode
  if [[ "${INPUT_STRICT:-false}" == "true" ]]; then
    local to_delete
    to_delete=$(get_deleted_keys "${existing_properties}" "${desired_properties}") || {
      print_error "Failed to determine keys to delete."
      exit 1
    }

    delete_current_az_properties "${to_delete}" || {
      print_error "Failed to delete keys in strict mode."
      exit 1
    }
  fi

  # Step 4: Compare and sync properties
  local common_equal common_changed added
  common_equal=$(get_common_keys_equal "${existing_properties}" "${desired_properties}") || {
    print_error "Failed to determine common equal keys."
    exit 1
  }

  common_changed=$(get_common_keys_changed "${existing_properties}" "${desired_properties}") || {
    print_error "Failed to determine common changed keys."
    exit 1
  }

  added=$(get_added_keys "${existing_properties}" "${desired_properties}") || {
    print_error "Failed to determine added keys."
    exit 1
  }

  # Update and create keys
  update_current_az_properties "${common_changed}" || {
    print_error "Failed to update existing keys."
    exit 1
  }

  create_new_az_properties "${added}" || {
    print_error "Failed to create new keys."
    exit 1
  }

  print_success "Property sync operation completed successfully."
}

# Main script logic
function main() {
  if [[ $# -eq 0 ]]; then
    print_error "No arguments provided."
    usage
  fi

  # Parse arguments
  parse_arguments "$@"

  # Perform action
  case "$ACTION" in
    validate_inputs)
      validate_inputs
      ;;
    perform_property_sync)
      perform_property_sync
      ;;
    *)
      print_error "Invalid action: $ACTION"
      usage
      ;;
  esac
}

# Execute the main function with all arguments
main "$@"