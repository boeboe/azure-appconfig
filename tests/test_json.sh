#!/usr/bin/env bash
# test_json.sh - Unit tests for json.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the JSON utility script and logging functions
SCRIPTS_DIR=$(dirname "$0")/../scripts
source "${SCRIPTS_DIR}/functions/json.sh"
source "${SCRIPTS_DIR}/functions/logging.sh"

# Initialize a variable to track failed tests
FAILED_TESTS=()

# Test for deleted keys
function test_get_deleted_keys() {
  print_info "Running test: test_get_deleted_keys"

  # Scenario 1: Regular case
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[{"key":"key2","value":"value2","description":"desc2"}]}'

  local result
  result=$(get_deleted_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_deleted_keys - Regular case passed."
  else
    print_error "test_get_deleted_keys - Regular case failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_deleted_keys - Regular case")
  fi

  # Scenario 2: Empty original
  local original='{"entries":[]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[]}'

  result=$(get_deleted_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_deleted_keys - Empty original passed."
  else
    print_error "test_get_deleted_keys - Empty original failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_deleted_keys - Empty original")
  fi

  # Scenario 3: Empty new
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[]}'
  local expected='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'

  result=$(get_deleted_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_deleted_keys - Empty new passed."
  else
    print_error "test_get_deleted_keys - Empty new failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_deleted_keys - Empty new")
  fi
}

# Test for common keys with equal entries
function test_get_common_keys_equal() {
  print_info "Running test: test_get_common_keys_equal"

  # Scenario 1: Regular case
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'

  local result
  result=$(get_common_keys_equal "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_equal - Regular case passed."
  else
    print_error "test_get_common_keys_equal - Regular case failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_equal - Regular case")
  fi

  # Scenario 2: Empty original
  local original='{"entries":[]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[]}'

  result=$(get_common_keys_equal "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_equal - Empty original passed."
  else
    print_error "test_get_common_keys_equal - Empty original failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_equal - Empty original")
  fi

  # Scenario 3: Empty new
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[]}'
  local expected='{"entries":[]}'

  result=$(get_common_keys_equal "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_equal - Empty new passed."
  else
    print_error "test_get_common_keys_equal - Empty new failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_equal - Empty new")
  fi
}

# Test for common keys with changed entries
function test_get_common_keys_changed() {
  print_info "Running test: test_get_common_keys_changed"

  # Scenario 1: Regular case
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"newvalue","description":"newdesc"}]}'
  local expected='{"entries":[{"key":"key1","value":"newvalue","description":"newdesc"}]}'

  local result
  result=$(get_common_keys_changed "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_changed - Regular case passed."
  else
    print_error "test_get_common_keys_changed - Regular case failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_changed - Regular case")
  fi

  # Scenario 2: Empty original
  local original='{"entries":[]}'
  local new='{"entries":[{"key":"key1","value":"newvalue","description":"newdesc"}]}'
  local expected='{"entries":[]}'

  result=$(get_common_keys_changed "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_changed - Empty original passed."
  else
    print_error "test_get_common_keys_changed - Empty original failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_changed - Empty original")
  fi

  # Scenario 3: Empty new
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[]}'
  local expected='{"entries":[]}'

  result=$(get_common_keys_changed "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_changed - Empty new passed."
  else
    print_error "test_get_common_keys_changed - Empty new failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_changed - Empty new")
  fi
}

# Test for added keys
function test_get_added_keys() {
  print_info "Running test: test_get_added_keys"

  # Scenario 1: Regular case
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local expected='{"entries":[{"key":"key2","value":"value2","description":"desc2"}]}'

  local result
  result=$(get_added_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_added_keys - Regular case passed."
  else
    print_error "test_get_added_keys - Regular case failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_added_keys - Regular case")
  fi

  # Scenario 2: Empty original
  local original='{"entries":[]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'

  result=$(get_added_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_added_keys - Empty original passed."
  else
    print_error "test_get_added_keys - Empty original failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_added_keys - Empty original")
  fi

  # Scenario 3: Empty new
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[]}'
  local expected='{"entries":[]}'

  result=$(get_added_keys "${original}" "${new}")
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_added_keys - Empty new passed."
  else
    print_error "test_get_added_keys - Empty new failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_added_keys - Empty new")
  fi
}

# Test for adding a prefix to keys
function test_add_prefix_to_keys() {
  print_info "Running test: test_add_prefix_to_keys"

  # Scenario 1: Regular case
  local input_json='{
    "entries": [
      {"key": "key1", "value": "value1", "description": "desc1"},
      {"key": "key2", "value": "value2", "description": "desc2"}
    ]
  }'
  local prefix="/myprefix/"
  local expected_json='{
    "entries": [
      {"key": "/myprefix/key1", "value": "value1", "description": "desc1"},
      {"key": "/myprefix/key2", "value": "value2", "description": "desc2"}
    ]
  }'

  local result
  result=$(add_prefix_to_keys "${input_json}" "${prefix}" | jq -c) # Compact output for consistent comparison
  local expected
  expected=$(echo "${expected_json}" | jq -c)
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_add_prefix_to_keys - Regular case passed."
  else
    print_error "test_add_prefix_to_keys - Regular case failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_add_prefix_to_keys - Regular case")
  fi

  # Scenario 2: Empty entries list
  input_json='{"entries":[]}'
  expected_json='{"entries":[]}'

  result=$(add_prefix_to_keys "${input_json}" "${prefix}" | jq -c)
  expected=$(echo "${expected_json}" | jq -c)
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_add_prefix_to_keys - Empty entries passed."
  else
    print_error "test_add_prefix_to_keys - Empty entries failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_add_prefix_to_keys - Empty entries")
  fi
}

# Test for transforming feature states
function test_transform_feature_state() {
  print_info "Running test: test_transform_feature_state"

  # Scenario 1: All valid state strings
  local input_json='{
    "entries": [
      {"key": "feature1", "value": "enabled", "description": "Feature 1 description"},
      {"key": "feature2", "value": "ENABLED", "description": "Feature 2 description"},
      {"key": "feature3", "value": "on", "description": "Feature 3 description"},
      {"key": "feature4", "value": "true", "description": "Feature 4 description"},
      {"key": "feature5", "value": "disabled", "description": "Feature 5 description"},
      {"key": "feature6", "value": "DISABLED", "description": "Feature 6 description"},
      {"key": "feature7", "value": "off", "description": "Feature 7 description"},
      {"key": "feature8", "value": "false", "description": "Feature 8 description"}
    ]
  }'
  local expected_json='{
    "entries": [
      {"key": "feature1", "value": "on", "description": "Feature 1 description"},
      {"key": "feature2", "value": "on", "description": "Feature 2 description"},
      {"key": "feature3", "value": "on", "description": "Feature 3 description"},
      {"key": "feature4", "value": "on", "description": "Feature 4 description"},
      {"key": "feature5", "value": "off", "description": "Feature 5 description"},
      {"key": "feature6", "value": "off", "description": "Feature 6 description"},
      {"key": "feature7", "value": "off", "description": "Feature 7 description"},
      {"key": "feature8", "value": "off", "description": "Feature 8 description"}
    ]
  }'

  local result
  result=$(transform_feature_state "${input_json}" | jq -c) # Compact output for consistent comparison
  local expected
  expected=$(echo "${expected_json}" | jq -c)
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_transform_feature_state - All valid states passed."
  else
    print_error "test_transform_feature_state - All valid states failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_transform_feature_state - All valid states")
  fi

  # Scenario 2: Invalid state strings
  input_json='{
    "entries": [
      {"key": "feature1", "value": "invalid", "description": "Invalid state"},
      {"key": "feature2", "value": "12345", "description": "Invalid state"}
    ]
  }'
  expected_json='{
    "entries": [
      {"key": "feature1", "value": "invalid", "description": "Invalid state"},
      {"key": "feature2", "value": "12345", "description": "Invalid state"}
    ]
  }'

  result=$(transform_feature_state "${input_json}" | jq -c)
  expected=$(echo "${expected_json}" | jq -c)
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_transform_feature_state - Invalid states passed."
  else
    print_error "test_transform_feature_state - Invalid states failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_transform_feature_state - Invalid states")
  fi

  # Scenario 3: Empty entries list
  input_json='{"entries":[]}'
  expected='{"entries":[]}'

  result=$(transform_feature_state "${input_json}" | jq -c)
  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_transform_feature_state - Empty entries passed."
  else
    print_error "test_transform_feature_state - Empty entries failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_transform_feature_state - Empty entries")
  fi
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for json.sh"
  
  test_get_deleted_keys
  test_get_common_keys_equal
  test_get_common_keys_changed
  test_get_added_keys

  test_add_prefix_to_keys
  test_transform_feature_state

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests