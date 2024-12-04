#!/usr/bin/env bash
# set-keyvalue.sh - Script to validate inputs and set a single key-value pair in Azure App Configuration
# shellcheck disable=SC1091

set -euo pipefail

# Source the shared logging and validation utilities
source "${SCRIPTS_DIR}/functions/logging.sh"
source "${SCRIPTS_DIR}/functions/validation.sh"
source "${SCRIPTS_DIR}/functions/az-appconfig.sh"

# Usage message
function usage() {
  local usage_message="Usage: $0 [ACTION] [ARGUMENTS]\n"
  usage_message+="Action:\n"
  usage_message+="  validate-inputs\n"
  usage_message+="  execute\n"
  usage_message+="Arguments:\n"
  usage_message+="  --connection-string <string>\n"
  usage_message+="  --key <key>\n"
  usage_message+="  --value <value>\n"
  usage_message+="  --prefix <prefix>\n"
  usage_message+="  --label <label>\n"
  usage_message+="  --tags <tags>\n"
  print_info "$usage_message"
  exit 1
}

# Parse arguments into variables
function parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --connection-string)
        INPUT_CONNECTION_STRING="$2"
        shift 2
        ;;
      --key)
        INPUT_KEY="$2"
        shift 2
        ;;
      --value)
        INPUT_VALUE="$2"
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
      --tags)
        INPUT_TAGS="$2"
        shift 2
        ;;
      validate-inputs)
        ACTION="validate_inputs"
        shift
        ;;
      execute)
        ACTION="execute"
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
    print_error "No action specified. Use validate-inputs or execute."
    usage
  fi
}

# Function to print all parsed arguments
function print_env_vars() {
  local env_vars_message="Debugging environment variables for action:\n"
  env_vars_message+="  INPUT_CONNECTION_STRING=${INPUT_CONNECTION_STRING:-<not set>}\n"
  env_vars_message+="  INPUT_KEY=${INPUT_KEY:-<not set>}\n"
  env_vars_message+="  INPUT_VALUE=${INPUT_VALUE:-<not set>}\n"
  env_vars_message+="  INPUT_PREFIX=${INPUT_PREFIX:-<not set>}\n"
  env_vars_message+="  INPUT_LABEL=${INPUT_LABEL:-<not set>}\n"
  env_vars_message+="  INPUT_TAGS=${INPUT_TAGS:-<not set>}\n"
  print_info "$env_vars_message"
}

# Function to validate inputs
function validate_inputs() {
  print_info "Validating inputs..."
  print_env_vars

  # Required fields
  validate_set "INPUT_CONNECTION_STRING" "${INPUT_CONNECTION_STRING:-}"
  validate_set "INPUT_KEY" "${INPUT_KEY:-}"
  validate_set "INPUT_VALUE" "${INPUT_VALUE:-}"

  # Optional fields
  [[ -n "${INPUT_TAGS:-}" ]] && validate_json "INPUT_TAGS" "${INPUT_TAGS}"

  print_success "All inputs validated successfully."
}

# Main function to perform the set key-value operation
function perform_set_keyvalue() {
  print_info "Starting set key-value operation..."

  # Construct the JSON payload
  local args
  args=$(jq -n \
    --arg connectionString "${INPUT_CONNECTION_STRING}" \
    --arg key "${INPUT_KEY}" \
    --arg value "${INPUT_VALUE}" \
    --arg prefix "${INPUT_PREFIX}" \
    --arg label "${INPUT_LABEL}" \
    --arg tags "${INPUT_TAGS}" \
    '{
      connectionString: $connectionString,
      key: $key,
      value: $value
    }
    + if $prefix != "" and $prefix != "null" then {prefix: $prefix} else {} end
    + if $label != "" and $label != "null" and $label != "\0" then {label: $label} else {} end
    + if $tags != "" and $tags != "null" then {tags: $tags} else {} end') || {
      print_error "Failed to construct JSON payload with jq"
      exit 1
  }

  # Step 1: Write the key-value pair to Azure App Configuration
  set_az_keyvalue "${args}"
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
    execute)
      perform_set_keyvalue
      ;;
    *)
      print_error "Invalid action: $ACTION"
      usage
      ;;
  esac
}

# Execute the main function with all arguments
main "$@"