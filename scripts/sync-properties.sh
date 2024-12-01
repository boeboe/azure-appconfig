#!/usr/bin/env bash
# sync-properties.sh
# Script to validate inputs and perform sync operations for Azure App Configuration

set -euo pipefail

# Source the shared logging utilities
echo "${SCRIPTS_DIR}/logging.sh"
ls "${SCRIPTS_DIR}"
source "${SCRIPTS_DIR}/logging.sh"

# Usage message
function usage() {
  echo "Usage: $0 --validate-inputs | --perform-property-sync [ARGUMENTS]"
  echo "Arguments:"
  echo "  --configuration-file <file>"
  echo "  --format <json|yaml|properties>"
  echo "  --connection-string <string>"
  echo "  --separator <separator>"
  echo "  --strict <true|false>"
  echo "  --prefix <prefix>"
  echo "  --label <label>"
  echo "  --depth <depth>"
  echo "  --tags <tags>"
  echo "  --content-type <contentType>"
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
        log_error "Unknown argument: $1"
        usage
        ;;
    esac
  done

  # Ensure an action is specified
  if [[ -z "${ACTION:-}" ]]; then
    log_error "No action specified (e.g., --validate-inputs or --perform-property-sync)."
    usage
  fi
}

# Function to validate inputs
function validate_inputs() {
  log_info "Validating inputs..."

  # Required fields
  [[ -z "${INPUT_CONFIGURATION_FILE:-}" ]] && log_error "INPUT_CONFIGURATION_FILE is required but not set." && exit 1
  [[ ! -f "${INPUT_CONFIGURATION_FILE}" ]] && log_error "INPUT_CONFIGURATION_FILE does not exist: ${INPUT_CONFIGURATION_FILE}" && exit 1
  [[ -z "${INPUT_FORMAT:-}" ]] && log_error "INPUT_FORMAT is required but not set." && exit 1
  [[ "${INPUT_FORMAT}" != "json" && "${INPUT_FORMAT}" != "yaml" && "${INPUT_FORMAT}" != "properties" ]] && log_error "INPUT_FORMAT must be one of: json, yaml, properties. Provided: ${INPUT_FORMAT}" && exit 1
  [[ -z "${INPUT_CONNECTION_STRING:-}" ]] && log_error "INPUT_CONNECTION_STRING is required but not set." && exit 1
  [[ -z "${INPUT_SEPARATOR:-}" ]] && log_error "INPUT_SEPARATOR is required but not set." && exit 1

  # Optional fields
  [[ -n "${INPUT_STRICT:-}" && "${INPUT_STRICT}" != "true" && "${INPUT_STRICT}" != "false" ]] && log_error "INPUT_STRICT must be either 'true' or 'false'. Provided: ${INPUT_STRICT}" && exit 1
  [[ -n "${INPUT_DEPTH:-}" && ! "${INPUT_DEPTH}" =~ ^[0-9]+$ ]] && log_error "INPUT_DEPTH must be a positive integer. Provided: ${INPUT_DEPTH}" && exit 1
  if [[ -n "${INPUT_TAGS:-}" && ! $(echo "${INPUT_TAGS}" | jq . > /dev/null 2>&1) ]]; then
    log_error "INPUT_TAGS must be a valid JSON string. Provided: ${INPUT_TAGS}"
    exit 1
  fi

  log_info "All inputs validated successfully."
}

# Function to print all parsed arguments
function print_debug() {
  log_info "Parsed arguments:"
  log_info "  INPUT_CONFIGURATION_FILE=${INPUT_CONFIGURATION_FILE:-<not set>}"
  log_info "  INPUT_FORMAT=${INPUT_FORMAT:-<not set>}"
  log_info "  INPUT_CONNECTION_STRING=${INPUT_CONNECTION_STRING:-<not set>}"
  log_info "  INPUT_SEPARATOR=${INPUT_SEPARATOR:-<not set>}"
  log_info "  INPUT_STRICT=${INPUT_STRICT:-<not set>}"
  log_info "  INPUT_PREFIX=${INPUT_PREFIX:-<not set>}"
  log_info "  INPUT_LABEL=${INPUT_LABEL:-<not set>}"
  log_info "  INPUT_DEPTH=${INPUT_DEPTH:-<not set>}"
  log_info "  INPUT_TAGS=${INPUT_TAGS:-<not set>}"
  log_info "  INPUT_CONTENT_TYPE=${INPUT_CONTENT_TYPE:-<not set>}"
}

# Placeholder for performing sync
function perform_property_sync() {
  log_info "Performing property sync operation..."
  print_debug
  # Implement the actual sync logic here
}

# Main script logic
function main() {
  if [[ $# -eq 0 ]]; then
    log_error "No arguments provided."
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
      log_error "Invalid action: $ACTION"
      usage
      ;;
  esac
}

# Execute the main function with all arguments
main "$@"