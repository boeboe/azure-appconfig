#!/usr/bin/env bash
# parsing.sh - Functions to parse properties files, Azure CLI JSON output, and YAML files.

# Function to parse key-value pairs from a properties file
# Input:
#   - Path to a properties file
# Output:
#   - JSON object with entries containing keys and values
# Example:
#   Input file:
#     key1=value1
#     key2=value2
#   Output:
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2","value":"value2"}]}
function parse_properties_file() {
  local filelocation="${1}"

  # Check if the file exists and is readable
  if [[ ! -f "${filelocation}" || ! -r "${filelocation}" ]]; then
    print_error "Properties file not found or not readable: ${filelocation}"
    exit 1
  fi

  # Extract keys and values
  local kv_pairs
  kv_pairs=$(grep -v '^#' "${filelocation}" | grep '=' | awk -F '=' '
    {
      key=$1;
      value=$2;
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key);  # Trim spaces around key
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value);  # Trim spaces around value
      gsub(/"/, "\\\"", value);  # Escape quotes in value for JSON
      printf "{\"key\":\"%s\",\"value\":\"%s\"},", key, value;
    }' | sed 's/,$//')  # Remove trailing comma from JSON array

  # Check if any data was found
  if [[ -z "${kv_pairs}" ]]; then
    print_error "No valid entries found in properties file: ${filelocation}"
    exit 1
  fi

  # Output JSON array of key-value pairs
  echo "{\"entries\":[${kv_pairs}]}" | jq -c
}

# Function to parse and flatten JSON content with a customizable separator
# Input:
#   - Raw JSON string
#   - Separator (optional, defaults to ".")
# Output:
#   - Flattened JSON as key-value pairs in "entries" format
# Example:
#   Input JSON:
#     {"key1":"value1","key2":{"key2.1":"value2.1"}}
#   Output with default separator:
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2.key2.1","value":"value2.1"}]}
#   Output with custom separator ("/"):
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2/key2.1","value":"value2.1"}]}
function flatten_json_content() {
  local json_content="$1"
  local separator="${2:-.}" # Default to "." if no separator is provided

  # Validate JSON content
  if ! echo "${json_content}" | jq empty 2>/dev/null; then
    print_error "Invalid JSON content provided."
    exit 1
  fi

  # Flatten the JSON structure into key-value pairs
  local flattened
  flattened=$(echo "${json_content}" | jq -c --arg separator "${separator}" '
    def flatten_object(obj; prefix):
      reduce (obj | to_entries)[] as $item ({}; . +
        if ($item.value | type) == "object" then
          flatten_object($item.value; (if prefix == "" then "" else (prefix + $separator) end) + $item.key)
        else
          {((if prefix == "" then "" else (prefix + $separator) end) + $item.key): ($item.value // "")}
        end
      );
    flatten_object(. ; "")
  ') || {
    print_error "Failed to parse or flatten JSON content."
    exit 1
  }

  # Convert flattened key-value pairs into an "entries" JSON object
  local entries
  entries=$(echo "${flattened}" | jq -c 'to_entries | map({key: .key, value: (.value // "")})') || {
    print_error "Failed to convert flattened JSON into entries format."
    exit 1
  }

  # Output final JSON structure
  echo "{\"entries\":${entries}}" | jq -c
}

# Function to parse JSON files
# Input:
#   - Path to a JSON file
#   - Separator (optional, defaults to ".")
# Output:
#   - JSON object in "entries" format
# Example:
#   Input file:
#     {"key1":"value1","key2":{"key2.1":"value2.1"}}
#   Output with default separator:
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2.key2.1","value":"value2.1"}]}
#   Output with custom separator ("/"):
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2/key2.1","value":"value2.1"}]}
function parse_json_file() {
  local file="$1"
  local separator="${2:-.}" # Default separator is "."

  # Check if the file exists and is readable
  if [[ ! -f "${file}" || ! -r "${file}" ]]; then
    print_error "JSON file not found or not readable: ${file}"
    exit 1
  fi

  # Read the file content and call `flatten_json_content`
  local json_content
  json_content=$(cat "${file}")
  flatten_json_content "${json_content}" "${separator}"
}

# Function to parse YAML files
# Input:
#   - Path to a YAML file
#   - Separator (optional, defaults to ".")
# Output:
#   - JSON object in "entries" format
# Example:
#   Input YAML:
#     key1: value1
#     key2:
#       key2.1: value2.1
#   Output with default separator:
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2.key2.1","value":"value2.1"}]}
#   Output with custom separator ("/"):
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2/key2.1","value":"value2.1"}]}
function parse_yaml_file() {
  local file="$1"
  local separator="${2:-.}" # Default separator is "."

  # Check if the file exists and is readable
  if [[ ! -f "${file}" || ! -r "${file}" ]]; then
    print_error "YAML file not found or not readable: ${file}"
    exit 1
  fi

  # Convert YAML to JSON and call `flatten_json_content`
  local json_content
  json_content=$(yq eval -o=json . "${file}") || {
    print_error "Failed to convert YAML to JSON for file: ${file}"
    exit 1
  }
  flatten_json_content "${json_content}" "${separator}"
}

# Function to parse key-value properties from Azure CLI output
# Input:
#   - JSON array from Azure CLI output
# Output:
#   - JSON object with entries containing keys and values
# Example:
#   Input JSON:
#     [{"key":"key1","value":"value1"},{"key":"key2","value":"value2"}]
#   Output:
#     {"entries":[{"key":"key1","value":"value1"},{"key":"key2","value":"value2"}]}
function parse_az_kv_properties() {
  local json_output="${1}"

  # Validate the JSON structure
  if ! echo "${json_output}" | jq -e '. | type == "array"' &>/dev/null; then
    print_error "Invalid Azure CLI output: must be a JSON array."
    exit 1
  fi

  # Convert the JSON to the desired format
  local parsed
  parsed=$(echo "${json_output}" | jq -c '[.[] | {key: .key, value: .value}] | {entries: .}')

  # Ensure the output is not empty
  if [[ -z "${parsed}" || "${parsed}" == "{}" ]]; then
    print_error "No valid entries found in Azure CLI output for key-value properties."
    exit 1
  fi

  echo "${parsed}"
}

# Function to parse feature flags from Azure CLI output
# Input:
#   - JSON array from Azure CLI output
# Output:
#   - JSON object with entries containing feature names and states
# Example:
#   Input JSON:
#     [{"name":"feature1","state":"on"},{"name":"feature2","state":"off"}]
#   Output:
#     {"entries":[{"key":"feature1","value":"on"},{"key":"feature2","value":"off"}]}
function parse_az_features() {
  local json_output="${1}"

  # Validate the JSON structure
  if ! echo "${json_output}" | jq -e '. | type == "array"' &>/dev/null; then
    print_error "Invalid Azure CLI output: must be a JSON array."
    exit 1
  fi

  # Convert the JSON to the desired format
  local parsed
  parsed=$(echo "${json_output}" | jq -c '[.[] | {key: .name, value: .state}] | {entries: .}')

  # Ensure the output is not empty
  if [[ -z "${parsed}" || "${parsed}" == "{}" ]]; then
    print_error "No valid entries found in Azure CLI output for features."
    exit 1
  fi

  echo "${parsed}"
}

# Function to parse feature state and return "true" or "false"
# Input:
#   - Feature state string (e.g., "on", "off", "true", "false")
# Output:
#   - "true" or "false"
# Example:
#   Input: "on"
#   Output: "true"
function parse_az_feature_state() {
  local state="${1}"

  # Convert the input state to lowercase for case-insensitive comparison
  local normalized_state
  normalized_state=$(echo "${state}" | tr '[:upper:]' '[:lower:]')

  # Map valid states to "true" or "false"
  case "${normalized_state}" in
    true|enable|enabled|on)
      echo "true"
      ;;
    false|disable|disabled|off)
      echo "false"
      ;;
    *)
      print_error "Invalid feature state: ${state}. Valid values are: true, enable, enabled, on, false, disable, disabled, off."
      exit 1
      ;;
  esac
}