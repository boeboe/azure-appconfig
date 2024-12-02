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
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key);
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value);
      split(value, desc, "#");
      value=desc[1];
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value);
      description=(length(desc) > 1 ? desc[2] : "");
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", description);
      printf "{\"key\": \"%s\", \"value\": \"%s\", \"description\": \"%s\"},", key, value, description;
    }' | sed 's/,$//')

  # Check if any data was found
  if [[ -z "${kvd}" ]]; then
    print_error "No valid entries found in properties file: ${filelocation}"
    exit 1
  fi

  # Output JSON array of key-value-description triples
  echo "{\"entries\":[${kvd}]}" | jq -c
}