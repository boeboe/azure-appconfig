#!/usr/bin/env bash
# create-snapshot.sh - Script to validate inputs and create a snapshot in Azure App Configuration
# shellcheck disable=SC1091

set -euo pipefail

# Source shared utility scripts
source "${SCRIPTS_DIR}/functions/logging.sh"
source "${SCRIPTS_DIR}/functions/validation.sh"

# Usage message
function usage() {
  local usage_message="Usage: $0 validate-inputs | execute [ARGUMENTS]\n"
  usage_message+="Arguments:\n"
  usage_message+="  --connection-string <string> : Connection string for the App Configuration instance.\n"
  usage_message+="  --name <string>              : Name of the snapshot to be created.\n"
  usage_message+="  --filters <string>           : Space-separated list of escaped JSON objects for key and label filters.\n"
  usage_message+="  --composition-type <string>  : Composition type for building the snapshot (key or key_label).\n"
  usage_message+="  --retention-period <number>  : Retention period in seconds before the snapshot expires.\n"
  usage_message+="  --tags <string>              : JSON string of tags to attach to the snapshot.\n"
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
      --name)
        INPUT_NAME="$2"
        shift 2
        ;;
      --filters)
        INPUT_FILTERS="$2"
        shift 2
        ;;
      --composition-type)
        INPUT_COMPOSITION_TYPE="$2"
        shift 2
        ;;
      --retention-period)
        INPUT_RETENTION_PERIOD="$2"
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
    print_error "No action specified (e.g., validate-inputs or execute)."
    usage
  fi
}

# Function to print all parsed arguments
function print_env_vars() {
  local env_vars_message="Debugging environment variables for action:\n"
  env_vars_message+="  INPUT_CONNECTION_STRING=${INPUT_CONNECTION_STRING:-<not set>}\n"
  env_vars_message+="  INPUT_NAME=${INPUT_NAME:-<not set>}\n"
  env_vars_message+="  INPUT_FILTERS=${INPUT_FILTERS:-<not set>}\n"
  env_vars_message+="  INPUT_COMPOSITION_TYPE=${INPUT_COMPOSITION_TYPE:-<not set>}\n"
  env_vars_message+="  INPUT_RETENTION_PERIOD=${INPUT_RETENTION_PERIOD:-<not set>}\n"
  env_vars_message+="  INPUT_TAGS=${INPUT_TAGS:-<not set>}\n"
  print_info "$env_vars_message"
}

# Function to validate inputs
function validate_inputs() {
  print_info "Validating inputs..."
  print_env_vars

  # Required fields
  validate_set "INPUT_CONNECTION_STRING" "${INPUT_CONNECTION_STRING:-}"
  validate_set "INPUT_NAME" "${INPUT_NAME:-}"
  validate_set "INPUT_FILTERS" "${INPUT_FILTERS:-}"

  # Optional fields
  validate_enum "INPUT_COMPOSITION_TYPE" "${INPUT_COMPOSITION_TYPE:-key}" "key" "key_label"
  [[ -n "${INPUT_RETENTION_PERIOD:-}" ]] && validate_positive_integer "INPUT_RETENTION_PERIOD" "${INPUT_RETENTION_PERIOD}"
  [[ -n "${INPUT_TAGS:-}" ]] && validate_json "INPUT_TAGS" "${INPUT_TAGS}"

  print_success "All inputs validated successfully."
}

# Main function to execute snapshot creation
function execute() {
  print_info "Executing snapshot creation..."
  create_snapshot
  print_success "Snapshot created successfully."
}

# Main function to perform the snapshot creation operation
function perform_create_snapshot() {
  print_info "Starting snapshot creation operation..."

  # Construct the JSON payload
  local args
  args=$(jq -n \
    --arg connectionString "${INPUT_CONNECTION_STRING}" \
    --arg name "${INPUT_NAME}" \
    --arg filters "${INPUT_FILTERS}" \
    --arg compositionType "${INPUT_COMPOSITION_TYPE:-key}" \
    --arg retentionPeriod "${INPUT_RETENTION_PERIOD:-}" \
    --arg tags "${INPUT_TAGS:-}" \
    '{
      connectionString: $connectionString,
      name: $name,
      filters: $filters,
      compositionType: $compositionType,
      retentionPeriod: $retentionPeriod,
      tags: $tags
    }')

  # Step 1: Create the snapshot in Azure App Configuration
  create_az_snapshot "${args}"
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
      perform_create_snapshot
      ;;
    *)
      print_error "Invalid action: $ACTION"
      usage
      ;;
  esac
}

# Execute the main function with all arguments
main "$@"