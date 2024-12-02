#!/usr/bin/env bash
# test_json.sh - Unit tests for json.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the JSON utility script and logging functions
SCRIPTS_DIR=$(dirname "$0")/..
source "${SCRIPTS_DIR}/scripts/json.sh"
source "${SCRIPTS_DIR}/scripts/logging.sh"

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

# Run all tests
function run_tests() {
  print_info "Starting unit tests for json.sh"
  test_get_deleted_keys
  test_get_common_keys_equal
  test_get_common_keys_changed
  test_get_added_keys

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests