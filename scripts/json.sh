#!/usr/bin/env bash
# json.sh - Functions for JSON validation, comparison, and manipulation

# Function to validate JSON format
function validate_json_entries() {
  local json="$1"

  # Check if the 'entries' key exists and is an array
  if ! echo "${json}" | jq -e '.entries | type == "array"' &>/dev/null; then
    print_error "Invalid JSON format: 'entries' key must exist and be an array."
    exit 1
  fi

  # If the 'entries' array is empty, it's still valid
  if [[ "$(echo "${json}" | jq '.entries | length')" -eq 0 ]]; then
    return 0
  fi

  # Validate that each entry in the array contains 'key', 'value', and 'description'
  if ! echo "${json}" | jq -e '.entries[] | has("key") and has("value") and has("description")' &>/dev/null; then
    print_error "Invalid JSON format: Each entry must contain 'key', 'value', and 'description'."
    exit 1
  fi
}

# Function to get deleted keys (keys in original but not in new)
function get_deleted_keys() {
  local original="$1"
  local new="$2"

  # Validate JSON structure
  validate_json_entries "${original}"
  validate_json_entries "${new}"

  # Handle empty entries explicitly
  if [[ "$(echo "${original}" | jq '.entries | length')" -eq 0 ]]; then
    echo '{"entries":[]}' | jq -c
    return
  fi

  if [[ "$(echo "${new}" | jq '.entries | length')" -eq 0 ]]; then
    echo "${original}" | jq -c
    return
  fi

  # Calculate deleted keys
  local deleted
  deleted=$(jq -n \
    --argjson original "$(echo "${original}" | jq '.entries')" \
    --argjson new "$(echo "${new}" | jq '.entries')" \
    '$original - $new | { entries: . }') || {
    print_error "Failed to calculate deleted keys."
    exit 1
  }

  echo "${deleted}" | jq -c
}

# Function to get common keys with equal entries
function get_common_keys_equal() {
  local original="$1"
  local new="$2"

  validate_json_entries "${original}"
  validate_json_entries "${new}"

  # Handle empty cases
  if [[ "$(echo "${original}" | jq '.entries | length')" -eq 0 || "$(echo "${new}" | jq '.entries | length')" -eq 0 ]]; then
    echo '{"entries":[]}' | jq -c
    return
  fi

  local common_equal
  common_equal=$(jq -n \
    --argjson original "$(echo "${original}" | jq '.entries')" \
    --argjson new "$(echo "${new}" | jq '.entries')" \
    '[ $original[] as $o | $new[] | select(. == $o) ] | { entries: . }') || {
    print_error "Failed to calculate common keys with equal entries."
    exit 1
  }

  echo "${common_equal}" | jq -c
}

# Function to get common keys with changed entries
function get_common_keys_changed() {
  local original="$1"
  local new="$2"

  validate_json_entries "${original}"
  validate_json_entries "${new}"

  # Handle empty cases
  if [[ "$(echo "${original}" | jq '.entries | length')" -eq 0 || "$(echo "${new}" | jq '.entries | length')" -eq 0 ]]; then
    echo '{"entries":[]}' | jq -c
    return
  fi

  local common_changed
  common_changed=$(jq -n \
    --argjson original "$(echo "${original}" | jq '.entries')" \
    --argjson new "$(echo "${new}" | jq '.entries')" \
    '[ $original[] as $o | $new[] | select(.key == $o.key and . != $o) ] | { entries: . }') || {
    print_error "Failed to calculate common keys with changed entries."
    exit 1
  }

  echo "${common_changed}" | jq -c
}

# Function to get added keys (keys in new but not in original)
function get_added_keys() {
  local original="$1"
  local new="$2"

  validate_json_entries "${original}"
  validate_json_entries "${new}"

  # Handle empty cases
  if [[ "$(echo "${new}" | jq '.entries | length')" -eq 0 ]]; then
    echo '{"entries":[]}' | jq -c
    return
  fi

  if [[ "$(echo "${original}" | jq '.entries | length')" -eq 0 ]]; then
    echo "${new}" | jq -c
    return
  fi

  local added
  added=$(jq -n \
    --argjson original "$(echo "${original}" | jq '.entries')" \
    --argjson new "$(echo "${new}" | jq '.entries')" \
    '$new - $original | { entries: . }') || {
    print_error "Failed to calculate added keys."
    exit 1
  }

  echo "${added}" | jq -c
}

# Function to add a prefix to every key in the JSON structure
function add_prefix_to_keys() {
  local json="$1"
  local prefix="$2"

  # Validate the JSON structure
  validate_json_entries "${json}"

  # If the 'entries' array is empty, return the same structure
  if [[ "$(echo "${json}" | jq '.entries | length')" -eq 0 ]]; then
    echo "${json}" | jq -c
    return
  fi

  # Add the prefix to each key
  local updated_json
  updated_json=$(echo "${json}" | jq -c --arg prefix "${prefix}" '
    .entries |= map(.key = "\($prefix)\(.key)")
  ') || {
    print_error "Failed to add prefix to keys."
    exit 1
  }

  echo "${updated_json}" | jq -c
}