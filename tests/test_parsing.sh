#!/usr/bin/env bash
# test_parsing.sh - Unit tests for parser.sh
# shellcheck disable=SC1091

set -euo pipefail

# Source the parser and logging scripts
SCRIPTS_DIR=$(dirname "$0")/../scripts
source "${SCRIPTS_DIR}/functions/parsing.sh"
source "${SCRIPTS_DIR}/functions/logging.sh"

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

# Test parsing properties file with Key Vault reference secrets
function test_parse_keyvaultref_properties_file() {
  local file="tests/files/test_parsing_5.properties"
  local expected='{"entries":[{"key":"secret1","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue1\"}","description":""},{"key":"secret2","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue2\"}","description":""},{"key":"secret3","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue3\"}","description":""}]}'

  print_info "Running test: test_parse_keyvaultref_properties_file"
  local result
  result=$(parse_properties_file "${file}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_keyvaultref_properties_file passed."
  else
    print_error "test_parse_keyvaultref_properties_file failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_keyvaultref_properties_file")
  fi
}

# Test parsing Azure CLI key-value properties JSON
function test_parse_az_kv_properties() {
  local json='[
    {"key":"/app/key1","value":"value1","tags":{"description":"desc1"}},
    {"key":"/app/key2","value":"value2","tags":{}}
  ]'
  local expected='{"entries":[{"key":"/app/key1","value":"value1","description":"desc1"},{"key":"/app/key2","value":"value2","description":""}]}'

  print_info "Running test: test_parse_az_kv_properties"
  local result
  result=$(parse_az_kv_properties "${json}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_az_kv_properties passed."
  else
    print_error "test_parse_az_kv_properties failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_az_kv_properties")
  fi
}

# Test parsing Azure CLI secrets JSON
function test_parse_az_kv_secrets() {
  local json='[
    {"key":"/secrets/key1","value":"{\"uri\":\"https://example.com\"}","tags":{"description":"secret desc"}},
    {"key":"/secrets/key2","value":"{\"uri\":\"https://example2.com\"}","tags":{}}
  ]'
  local expected='{"entries":[{"key":"/secrets/key1","value":"{\"uri\":\"https://example.com\"}","description":"secret desc"},{"key":"/secrets/key2","value":"{\"uri\":\"https://example2.com\"}","description":""}]}'

  print_info "Running test: test_parse_az_kv_secrets"
  local result
  result=$(parse_az_kv_properties "${json}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_az_kv_secrets passed."
  else
    print_error "test_parse_az_kv_secrets failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_az_kv_secrets")
  fi
}

# Test parsing Azure CLI feature flags JSON
function test_parse_az_features() {
  local json='[
    {"name":"/features/feature1","state":"on","description":"Feature 1 desc"},
    {"name":"/features/feature2","state":"off"}
  ]'
  local expected='{"entries":[{"key":"/features/feature1","value":"on","description":"Feature 1 desc"},{"key":"/features/feature2","value":"off","description":""}]}'

  print_info "Running test: test_parse_az_features"
  local result
  result=$(parse_az_features "${json}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "test_parse_az_features passed."
  else
    print_error "test_parse_az_features failed. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("test_parse_az_features")
  fi
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for parser.sh"
  
  test_parse_basic_properties_file
  test_parse_empty_values_properties_file
  test_parse_with_descriptions_properties_file
  test_parse_with_comments_properties_file
  test_parse_keyvaultref_properties_file

  test_parse_az_kv_properties
  test_parse_az_kv_secrets
  test_parse_az_features

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed: ${FAILED_TESTS[*]}"
    exit 1
  fi
}

run_tests