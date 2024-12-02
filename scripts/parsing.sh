#!/usr/bin/env bash
# parsing.sh - Functions to parse properties files and extract keys, key-value pairs, and descriptions.

# Function to extract key-value-description triples from a properties file
function parse_properties_file() {
  local filelocation="$1"

  # Check if the file exists and is readable
  if [[ ! -f "${filelocation}" || ! -r "${filelocation}" ]]; then
    print_error "Properties file not found or not readable: ${filelocation}"
    exit 1
  fi

  # Extract keys, values, and descriptions
  local kvd
  kvd=$(grep -v '^#' "${filelocation}" | grep '=' | awk -F '=' '
    {
      key=$1;
      value=$2;
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key);  # Trim spaces around key
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value);  # Trim spaces around value
      split(value, desc, "#");  # Split value on first "#" for description
      value=desc[1];
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value);  # Trim spaces around value
      gsub(/"/, "\\\"", value);  # Escape quotes in value for JSON
      description=(length(desc) > 1 ? desc[2] : "");  # Extract description if present
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", description);  # Trim spaces around description
      printf "{\"key\":\"%s\",\"value\":\"%s\",\"description\":\"%s\"},", key, value, description;
    }' | sed 's/,$//')  # Remove trailing comma from JSON array

  # Check if any data was found
  if [[ -z "${kvd}" ]]; then
    print_error "No valid entries found in properties file: ${filelocation}"
    exit 1
  fi

  # Output JSON array of key-value-description triples
  echo "{\"entries\":[${kvd}]}" | jq -c
}

# Function to parse key-value properties from Azure CLI output
function parse_az_kv_properties() {
  local json_output="$1"

  # Validate the JSON structure
  if ! echo "${json_output}" | jq -e '. | type == "array"' &>/dev/null; then
    print_error "Invalid Azure CLI output: must be a JSON array."
    exit 1
  fi

  # Convert the JSON to the desired format
  local parsed
  parsed=$(echo "${json_output}" | jq -c '[.[] | {key: .key, value: .value, description: (.tags.description // "")}] | {entries: .}')

  # Ensure the output is not empty
  if [[ -z "${parsed}" || "${parsed}" == "{}" ]]; then
    print_error "No valid entries found in Azure CLI output for key-value properties."
    exit 1
  fi

  echo "${parsed}"
}

# Function to parse feature flags from Azure CLI output
function parse_az_features() {
  local json_output="$1"

  # Validate the JSON structure
  if ! echo "${json_output}" | jq -e '. | type == "array"' &>/dev/null; then
    print_error "Invalid Azure CLI output: must be a JSON array."
    exit 1
  fi

  # Convert the JSON to the desired format
  local parsed
  parsed=$(echo "${json_output}" | jq -c '[.[] | {key: .name, value: .state, description: (.description // "")}] | {entries: .}')

  # Ensure the output is not empty
  if [[ -z "${parsed}" || "${parsed}" == "{}" ]]; then
    print_error "No valid entries found in Azure CLI output for features."
    exit 1
  fi

  echo "${parsed}"
}