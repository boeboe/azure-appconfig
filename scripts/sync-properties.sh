#!/usr/bin/env bash
# sync-properties.sh
# shellcheck disable=SC1091
# Script to validate inputs and perform sync operations for Azure App Configuration

set -euo pipefail

# Source the shared logging and validation utilities
source "${SCRIPTS_DIR}/logging.sh"
source "${SCRIPTS_DIR}/validation.sh"

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

  # Optional fields
  [[ -n "${INPUT_STRICT:-}" ]] && validate_boolean "INPUT_STRICT" "${INPUT_STRICT}"
  [[ -n "${INPUT_DEPTH:-}" ]] && validate_positive_integer "INPUT_DEPTH" "${INPUT_DEPTH}"
  [[ -n "${INPUT_TAGS:-}" ]] && validate_json "INPUT_TAGS" "${INPUT_TAGS}"

  print_success "All inputs validated successfully."
}

# Function to perform the property sync operation
function perform_property_sync() {
  print_info "Performing property sync operation..."

  # Build the az appconfig kv import command
  local cmd=("az appconfig kv import")

  # Required fields
  cmd+=("--yes")
  cmd+=("--source file")
  cmd+=("--path '${INPUT_CONFIGURATION_FILE}'")
  cmd+=("--format '${INPUT_FORMAT}'")
  cmd+=("--connection-string '${INPUT_CONNECTION_STRING}'")

  # Optional fields
  [[ -n "${INPUT_SEPARATOR:-}" ]] && cmd+=("--separator '${INPUT_SEPARATOR}'")
  [[ -n "${INPUT_STRICT:-}" ]] && cmd+=("--strict '${INPUT_STRICT}'")
  [[ -n "${INPUT_PREFIX:-}" ]] && cmd+=("--prefix '${INPUT_PREFIX}'")
  [[ -n "${INPUT_LABEL:-}" ]] && cmd+=("--label '${INPUT_LABEL}'")
  [[ -n "${INPUT_DEPTH:-}" ]] && cmd+=("--depth '${INPUT_DEPTH}'")
  [[ -n "${INPUT_CONTENT_TYPE:-}" ]] && cmd+=("--content-type '${INPUT_CONTENT_TYPE}'")

  # Execute the command
  print_command "Executing: ${cmd[*]}"
  eval "${cmd[*]}"

  if [[ $? -eq 0 ]]; then
    print_success "Property sync operation completed successfully."
  else
    print_error "Property sync operation failed."
    exit 1
  fi
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