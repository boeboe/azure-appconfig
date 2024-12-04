#!/usr/bin/env bash
# sync-config.sh - Script to validate inputs and perform sync operations for Azure App Configuration
# shellcheck disable=SC1091

set -euo pipefail

# Source the shared logging and validation utilities
source "${SCRIPTS_DIR}/functions/logging.sh"
source "${SCRIPTS_DIR}/functions/validation.sh"
source "${SCRIPTS_DIR}/functions/parsing.sh"
source "${SCRIPTS_DIR}/functions/json.sh"
source "${SCRIPTS_DIR}/functions/az-appconfig.sh"

# Usage message
function usage() {
  local usage_message="Usage: $0 [ACTION] [ARGUMENTS]\n"
  usage_message+="Action:\n"
  usage_message+="  validate-inputs\n"
  usage_message+="  execute\n"
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

  # Optional fields
  [[ -n "${INPUT_STRICT:-}" ]] && validate_boolean "INPUT_STRICT" "${INPUT_STRICT}"
  [[ -n "${INPUT_DEPTH:-}" ]] && validate_positive_integer "INPUT_DEPTH" "${INPUT_DEPTH}"
  [[ -n "${INPUT_TAGS:-}" ]] && validate_json "INPUT_TAGS" "${INPUT_TAGS}"

  print_success "All inputs validated successfully."
}

# Main function to perform sync operation
function perform_config_sync() {
  print_info "Starting sync operation..."

  # Assume changes_applied is false initially
  local changes_applied=false

  # Step 1: Parse the input file
  local desired_items
  desired_items=$(parse_properties_file "${INPUT_CONFIGURATION_FILE}") || {
    print_error "Failed to parse input file: ${INPUT_CONFIGURATION_FILE}"
    exit 1
  }
  if [[ -n "${INPUT_PREFIX:-}" ]]; then
    print_info "Adding prefix '${INPUT_PREFIX}' to desired items."
    desired_items=$(add_prefix_to_keys "${desired_items}" "${INPUT_PREFIX}") || {
      print_error "Failed to add prefix '${INPUT_PREFIX}' to desired items."
      exit 1
    }
  fi
  if [[ "${INPUT_CONTENT_TYPE}" == "featureflag" ]]; then
    print_info "Transforming feature states for desired feature flags."
    desired_items=$(transform_feature_state "${desired_items}") || {
      print_error "Failed to transform feature states for desired feature flags."
      exit 1
    }
  fi

  # Step 2: Fetch existing items based on content type
  local existing_items
  if [[ "${INPUT_CONTENT_TYPE}" == "featureflag" ]]; then
    print_info "Fetching current feature flags from Azure App Configuration..."
    existing_items=$(get_current_az_features) || {
      print_error "Failed to fetch existing Azure feature flags."
      exit 1
    }
  else
    print_info "Fetching current properties from Azure App Configuration..."
    existing_items=$(get_current_az_properties) || {
      print_error "Failed to fetch existing Azure properties."
      exit 1
    }
  fi

  # Step 3: Handle strict mode
  if [[ "${INPUT_STRICT:-false}" == "true" ]]; then
    local to_delete
    to_delete=$(get_deleted_keys "${existing_items}" "${desired_items}") || {
      print_error "Failed to determine items to delete."
      exit 1
    }
    if [[ -n "${to_delete}" ]]; then
      changes_applied=true
      if [[ "${INPUT_CONTENT_TYPE}" == "featureflag" ]]; then
        delete_current_az_features "${to_delete}" || {
          print_error "Failed to delete feature flags in strict mode."
          exit 1
        }
      else
        delete_current_az_properties "${to_delete}" || {
          print_error "Failed to delete properties in strict mode."
          exit 1
        }
      fi
    fi
  fi

  # Step 4: Compare and sync items
  local common_equal common_changed added
  common_equal=$(get_common_keys_equal "${existing_items}" "${desired_items}") || {
    print_error "Failed to determine common equal items."
    exit 1
  }

  common_changed=$(get_common_keys_changed "${existing_items}" "${desired_items}") || {
    print_error "Failed to determine common changed items."
    exit 1
  }

  added=$(get_added_keys "${existing_items}" "${desired_items}") || {
    print_error "Failed to determine added items."
    exit 1
  }

  # Log untouched items
  if [[ "${INPUT_CONTENT_TYPE}" == "featureflag" ]]; then
    keep_current_az_features "${common_equal}"
  else
    keep_current_az_properties "${common_equal}"
  fi

  # Update and create items
  if [[ -n "${common_changed}" || -n "${added}" ]]; then
    changes_applied=true
    if [[ "${INPUT_CONTENT_TYPE}" == "featureflag" ]]; then
      update_current_az_features "${common_changed}" || {
        print_error "Failed to update existing feature flags."
        exit 1
      }

      create_new_az_features "${added}" || {
        print_error "Failed to create new feature flags."
        exit 1
      }
    else
      update_current_az_properties "${common_changed}" || {
        print_error "Failed to update existing properties."
        exit 1
      }

      create_new_az_properties "${added}" || {
        print_error "Failed to create new properties."
        exit 1
      }
    fi
  fi

  # Export the changes_applied variable to the GitHub environment
  print_info "Changes applied: ${changes_applied}"
  echo "CHANGES_APPLIED=${changes_applied}" >> "${GITHUB_ENV}"

  print_success "Sync operation completed successfully."
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
      perform_config_sync
      ;;
    *)
      print_error "Invalid action: $ACTION"
      usage
      ;;
  esac
}

# Execute the main function with all arguments
main "$@"