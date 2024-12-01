#!/usr/bin/env bash
# sync-properties.sh
# Script to validate inputs and perform sync operations for Azure App Configuration

set -euo pipefail

# Source the shared logging utilities
source "$(dirname "$0")/logging.sh"

# Usage message
function usage() {
  echo "Usage: $0 --validate-inputs | --perform-property-sync"
  exit 1
}

# Validate input flag
function validate_flag() {
  if [[ $# -ne 1 ]]; then
    log_error "No flag provided."
    usage
  fi

  case "$1" in
    --validate-inputs | --perform-property-sync)
      # Valid flag
      ;;
    *)
      log_error "Invalid flag: $1"
      usage
      ;;
  esac
}

# Placeholder for validating inputs# validate_inputs
# Description: Validates the required and optional environment variables passed to the script.
# Ensures that all required inputs are provided, checks for valid formats, and performs basic 
# type and format validation on optional inputs. Exits with an error if any validation fails.
#
# Validations performed:
# - CONFIGURATION_FILE: Must be set and must exist (required).
# - FORMAT: Must be one of the allowed values: json, yaml, properties (required).
# - CONNECTION_STRING: Must be set (required).
# - SEPARATOR: Must be set (required).
# - STRICT: Must be either "true" or "false" (required, default is "false").
# - PREFIX: Not explicitly validated as it's an optional string.
# - LABEL: Not explicitly validated as it's an optional string.
# - DEPTH: If provided, must be a positive integer.
# - TAGS: If provided, must be a valid JSON string.
# - CONTENT_TYPE: Not explicitly validated as it's an optional string.
#
# Logs an error and exits with code 1 if validation fails.
function validate_inputs() {
  log_info "Validating inputs..."

  # Check if required inputs are set
  if [[ -z "${CONFIGURATION_FILE:-}" ]]; then
    log_error "CONFIGURATION_FILE is required but not set."
    exit 1
  elif [[ ! -f "${CONFIGURATION_FILE}" ]]; then
    log_error "CONFIGURATION_FILE does not exist or is not accessible: ${CONFIGURATION_FILE}"
    exit 1
  fi

  if [[ -z "${FORMAT:-}" ]]; then
    log_error "FORMAT is required but not set."
    exit 1
  elif [[ "${FORMAT}" != "json" && "${FORMAT}" != "yaml" && "${FORMAT}" != "properties" ]]; then
    log_error "FORMAT must be one of: json, yaml, properties. Provided: ${FORMAT}"
    exit 1
  fi

  if [[ -z "${CONNECTION_STRING:-}" ]]; then
    log_error "CONNECTION_STRING is required but not set."
    exit 1
  fi

  if [[ -z "${SEPARATOR:-}" ]]; then
    log_error "SEPARATOR is required but not set."
    exit 1
  fi

  if [[ -z "${STRICT:-}" ]]; then
    STRICT="false"
  elif [[ "${STRICT}" != "true" && "${STRICT}" != "false" ]]; then
    log_error "STRICT must be either 'true' or 'false'. Provided: ${STRICT}"
    exit 1
  fi

  # Optional inputs validation
  if [[ -n "${DEPTH:-}" && ! "${DEPTH}" =~ ^[0-9]+$ ]]; then
    log_error "DEPTH must be a positive number. Provided: ${DEPTH}"
    exit 1
  fi

  if [[ -n "${TAGS:-}" ]]; then
    if ! echo "${TAGS}" | jq . > /dev/null 2>&1; then
      log_error "TAGS must be a valid JSON string. Provided: ${TAGS}"
      exit 1
    fi
  fi

  log_info "All inputs validated successfully."
}

# Function to print all environment variables relevant to this action
function print_env_vars() {
  local env_vars_message="Debugging environment variables for action 'sync-properties':\n"
  env_vars_message+=" CONFIGURATION_FILE=${CONFIGURATION_FILE:-<not set>}\n"
  env_vars_message+=" FORMAT=${FORMAT:-<not set>}\n"
  env_vars_message+=" CONNECTION_STRING=${CONNECTION_STRING:-<not set>}\n"
  env_vars_message+=" SEPARATOR=${SEPARATOR:-<not set>}\n"
  env_vars_message+=" STRICT=${STRICT:-<not set>}\n"
  env_vars_message+=" PREFIX=${PREFIX:-<not set>}\n"
  env_vars_message+=" LABEL=${LABEL:-<not set>}\n"
  env_vars_message+=" DEPTH=${DEPTH:-<not set>}\n"
  env_vars_message+=" TAGS=${TAGS:-<not set>}\n"
  env_vars_message+=" CONTENT_TYPE=${CONTENT_TYPE:-<not set>}\n"

  print_info "$env_vars_message"
}

# Placeholder for performing sync
function perform_property_sync() {
  log_info "Performing property sync operation..."
  
  # Print all environment variables relevant to this action
  print_env_vars
}

# Main script logic
function main() {
  if [[ $# -eq 0 ]]; then
    log_error "No arguments provided."
    usage
  fi

  # Validate the flag
  validate_flag "$1"
  local flag="$1"

  # Call the appropriate function based on the flag
  case "$flag" in
    --validate-inputs)
      validate_inputs
      ;;
    --perform-property-sync)
      perform_property_sync
      ;;
  esac
}

# Execute the main function with all script arguments
main "$@"