#!/usr/bin/env bash
# sync-properties.sh
# shellcheck disable=SC1091
# Script to validate inputs and perform sync operations for Azure App Configuration

set -euo pipefail

# Source the shared logging utilities
source "${SCRIPTS_DIR}/logging.sh"

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

# Function to validate inputs
function validate_inputs() {
  print_info "Validating inputs..."

  # Required fields
  [[ -z "${INPUT_CONFIGURATION_FILE:-}" ]] && print_error "INPUT_CONFIGURATION_FILE is required but not set." && exit 1
  [[ ! -f "${INPUT_CONFIGURATION_FILE}" ]] && print_error "INPUT_CONFIGURATION_FILE does not exist: ${INPUT_CONFIGURATION_FILE}" && exit 1
  [[ -z "${INPUT_FORMAT:-}" ]] && print_error "INPUT_FORMAT is required but not set." && exit 1
  [[ "${INPUT_FORMAT}" != "json" && "${INPUT_FORMAT}" != "yaml" && "${INPUT_FORMAT}" != "properties" ]] && print_error "INPUT_FORMAT must be one of: json, yaml, properties. Provided: ${INPUT_FORMAT}" && exit 1
  [[ -z "${INPUT_CONNECTION_STRING:-}" ]] && print_error "INPUT_CONNECTION_STRING is required but not set." && exit 1
  [[ -z "${INPUT_SEPARATOR:-}" ]] && print_error "INPUT_SEPARATOR is required but not set." && exit 1

  # Optional fields
  [[ -n "${INPUT_STRICT:-}" && "${INPUT_STRICT}" != "true" && "${INPUT_STRICT}" != "false" ]] && print_error "INPUT_STRICT must be either 'true' or 'false'. Provided: ${INPUT_STRICT}" && exit 1
  [[ -n "${INPUT_DEPTH:-}" && ! "${INPUT_DEPTH}" =~ ^[0-9]+$ ]] && print_error "INPUT_DEPTH must be a positive integer. Provided: ${INPUT_DEPTH}" && exit 1
  if [[ -n "${INPUT_TAGS:-}" && ! $(echo "${INPUT_TAGS}" | jq . > /dev/null 2>&1) ]]; then
    print_error "INPUT_TAGS must be a valid JSON string. Provided: ${INPUT_TAGS}"
    exit 1
  fi

  print_success "All inputs validated successfully."
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

# Placeholder for performing sync
function perform_property_sync() {
  print_info "Performing property sync operation..."
  print_env_vars
  # Implement the actual sync logic here
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