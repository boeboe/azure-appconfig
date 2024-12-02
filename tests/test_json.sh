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
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[{"key":"key2","value":"value2","description":"desc2"}]}'

  local result
  result=$(get_deleted_keys "${original}" "${new}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_deleted_keys passed."
  else
    print_error "test_get_deleted_keys failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_deleted_keys")
  fi
}

# Test for common keys with equal entries
function test_get_common_keys_equal() {
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local expected='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'

  local result
  result=$(get_common_keys_equal "${original}" "${new}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_equal passed."
  else
    print_error "test_get_common_keys_equal failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_equal")
  fi
}

# Test for common keys with changed entries
function test_get_common_keys_changed() {
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local new='{"entries":[{"key":"key1","value":"newvalue","description":"newdesc"}]}'
  local expected='{"entries":[{"key":"key1","value":"newvalue","description":"newdesc"}]}'

  local result
  result=$(get_common_keys_changed "${original}" "${new}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_common_keys_changed passed."
  else
    print_error "test_get_common_keys_changed failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_common_keys_changed")
  fi
}

# Test for added keys
function test_get_added_keys() {
  local original='{"entries":[{"key":"key1","value":"value1","description":"desc1"}]}'
  local new='{"entries":[{"key":"key1","value":"value1","description":"desc1"},{"key":"key2","value":"value2","description":"desc2"}]}'
  local expected='{"entries":[{"key":"key2","value":"value2","description":"desc2"}]}'

  local result
  result=$(get_added_keys "${original}" "${new}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_get_added_keys passed."
  else
    print_error "test_get_added_keys failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_get_added_keys")
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