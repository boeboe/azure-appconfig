#!/usr/bin/env bash
# test_parsing.sh - Unit tests for parser.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the parser and logging scripts
SCRIPTS_DIR=$(dirname "$0")/..
source "${SCRIPTS_DIR}/scripts/parsing.sh"
source "${SCRIPTS_DIR}/scripts/logging.sh"

# Initialize a variable to track failed tests
FAILED_TESTS=()

# Test parsing properties file with basic key-value pairs
function test_parse_basic_properties_file() {
  local file="tests/files/test_parsing_1.properties"
  local expected='{"entries":[{"key":"key1","value":"value1","description":""},{"key":"key2","value":"value2","description":""},{"key":"key3","value":"value3","description":""}]}'

  print_info "Running test: test_parse_basic_properties_file"
  local result
  result=$(parse_properties_file "${file}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_basic_properties_file passed."
  else
    print_error "test_parse_basic_properties_file failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_basic_properties_file")
  fi
}

# Test parsing properties file with empty values
function test_parse_empty_values_properties_file() {
  local file="tests/files/test_parsing_2.properties"
  local expected='{"entries":[{"key":"key1","value":"value1","description":""},{"key":"key2","value":"","description":""},{"key":"key3","value":"value3","description":""}]}'

  print_info "Running test: test_parse_empty_values_properties_file"
  local result
  result=$(parse_properties_file "${file}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_empty_values_properties_file passed."
  else
    print_error "test_parse_empty_values_properties_file failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_empty_values_properties_file")
  fi
}

# Test parsing properties file with key-value-description triples
function test_parse_with_descriptions_properties_file() {
  local file="tests/files/test_parsing_3.properties"
  local expected='{"entries":[{"key":"key1","value":"value1","description":"First key description"},{"key":"key2","value":"value2","description":""},{"key":"key3","value":"value3","description":"Another description"}]}'

  print_info "Running test: test_parse_with_descriptions_properties_file"
  local result
  result=$(parse_properties_file "${file}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_with_descriptions_properties_file passed."
  else
    print_error "test_parse_with_descriptions_properties_file failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_with_descriptions_properties_file")
  fi
}

# Test parsing properties file with empty lines and comments
function test_parse_with_comments_properties_file() {
  local file="tests/files/test_parsing_4.properties"
  local expected='{"entries":[{"key":"key1","value":"value1","description":""},{"key":"key2","value":"value2","description":""},{"key":"key3","value":"value3","description":""}]}'

  print_info "Running test: test_parse_with_comments_properties_file"
  local result
  result=$(parse_properties_file "${file}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_with_comments_properties_file passed."
  else
    print_error "test_parse_with_comments_properties_file failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_with_comments_properties_file")
  fi
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for parser.sh"
  test_parse_basic_properties_file
  test_parse_empty_values_properties_file
  test_parse_with_descriptions_properties_file
  test_parse_with_comments_properties_file

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests