#!/usr/bin/env bash
# test_parsing.sh - Unit tests for parser.sh
# shellcheck disable=SC1091

set -euo pipefail
trap 'print_error "Test script failed at line $LINENO with exit code $? (last command: $BASH_COMMAND)"' ERR

# Source the parser and logging scripts
SCRIPTS_DIR=$(dirname "$0")/../scripts
source "${SCRIPTS_DIR}/functions/parsing.sh"
source "${SCRIPTS_DIR}/functions/logging.sh"

# Initialize a variable to track failed tests
FAILED_TESTS=()

# Function to parse a file using the correct parser
# Input: Path to the file, optional separator
# Output: Parsed JSON result
function parse_file() {
  local file="$1"
  local separator="${2:-}"

  case "${file}" in
    *.properties) parse_properties_file "${file}" ;;
    *.yaml) parse_yaml_file "${file}" "${separator}" ;;
    *.json) parse_json_file "${file}" "${separator}" ;;
    *)
      print_error "Unsupported file type: ${file}"
      exit 1
      ;;
  esac
}

# Function to run a test with expected output
# Input: Test name, file path, expected output, optional separator
function run_test() {
  local test_name="$1"
  local file="$2"
  local expected="$3"
  local separator="${4:-}"

  print_info "Running test: ${test_name} (${file})"
  local result
  result=$(parse_file "${file}" "${separator}")

  if [[ "${result}" == "${expected}" ]]; then
    print_success "${test_name} passed for ${file}."
  else
    print_error "${test_name} failed for ${file}. Expected: ${expected}, Got: ${result}"
    FAILED_TESTS+=("${test_name} (${file})")
  fi
}

# Tests for basic key-value pairs
function test_parse_basic_file() {
  local file="$1"
  local expected='{"entries":[{"key":"key1","value":"value1"},{"key":"key2","value":"value2"},{"key":"key3","value":"value3"}]}'
  run_test "test_parse_basic_file" "${file}" "${expected}"
}

# Tests for empty values
function test_parse_empty_values_file() {
  local file="$1"
  local expected='{"entries":[{"key":"key1","value":"value1"},{"key":"key2","value":""},{"key":"key3","value":"value3"}]}'
  run_test "test_parse_empty_values_file" "${file}" "${expected}"
}

# Tests for nested structures
function test_parse_nested_file() {
  local file="$1"
  local expected='{"entries":[{"key":"key1","value":"value1"},{"key":"key2.key2.1","value":"value2.1"},{"key":"key2.key2.2","value":"value2.2"},{"key":"key2.key2.3.key2.3.1","value":"value2.3.1"},{"key":"key2.key2.3.key2.3.2","value":"value2.3.2"},{"key":"key3","value":"value3"}]}'
  run_test "test_parse_nested_file" "${file}" "${expected}"
}

# Tests for files with empty lines and comments
function test_parse_with_comments_file() {
  local file="$1"
  local expected='{"entries":[{"key":"key1","value":"value1"},{"key":"key2","value":"value2"},{"key":"key3","value":"value3"}]}'
  run_test "test_parse_with_comments_file" "${file}" "${expected}"
}

# Tests for Key Vault reference secrets
function test_parse_keyvaultref_file() {
  local file="$1"
  local expected='{"entries":[{"key":"secret1","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue1\"}"},{"key":"secret2","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue2\"}"},{"key":"secret3","value":"{\"uri\":\"https://my-key-vault.vault.azure.net/secrets/secretvalue3\"}"}]}'
  run_test "test_parse_keyvaultref_file" "${file}" "${expected}"
}

# Tests for nested structures with custom separator
function test_parse_custom_separator_file() {
  local file="$1"
  local expected='{"entries":[{"key":"key1","value":"value1"},{"key":"key2/key2.1","value":"value2.1"},{"key":"key2/key2.2","value":"value2.2"},{"key":"key2/key2.3/key2.3.1","value":"value2.3.1"},{"key":"key2/key2.3/key2.3.2","value":"value2.3.2"},{"key":"key3","value":"value3"}]}'
  run_test "test_parse_nested_file" "${file}" "${expected}" "/"
}

# Run all tests
function run_tests() {
  print_info "Starting unit tests for parser.sh"

  # Files for testing
  local files=("tests/files/test_parsing_1.json"
               "tests/files/test_parsing_1.properties"
               "tests/files/test_parsing_1.yaml"
               "tests/files/test_parsing_2.json"
               "tests/files/test_parsing_2.properties"
               "tests/files/test_parsing_2.yaml"
               "tests/files/test_parsing_3.json"
               "tests/files/test_parsing_3.properties"
               "tests/files/test_parsing_3.yaml"
               "tests/files/test_parsing_4.json"
               "tests/files/test_parsing_4.properties"
               "tests/files/test_parsing_4.yaml"
               "tests/files/test_parsing_5.json"
               "tests/files/test_parsing_5.properties"
               "tests/files/test_parsing_5.yaml"
               "tests/files/test_parsing_6.json"
               "tests/files/test_parsing_6.properties"
               "tests/files/test_parsing_6.yaml")

  # Test each file
  for file in "${files[@]}"; do
    case "${file}" in
      *test_parsing_1*) test_parse_basic_file "${file}" ;;
      *test_parsing_2*) test_parse_empty_values_file "${file}" ;;
      *test_parsing_3*) test_parse_nested_file "${file}" ;;
      *test_parsing_4*) test_parse_with_comments_file "${file}" ;;
      *test_parsing_5*) test_parse_keyvaultref_file "${file}" ;;
      *test_parsing_6*) test_parse_custom_separator_file "${file}" ;;
    esac
  done

  if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    print_success "All tests passed successfully!"
  else
    print_error "The following tests failed:"
    print_failed_tests "${FAILED_TESTS[@]}"
    exit 1
  fi
}

# Function to print failed tests in a clean format
function print_failed_tests() {
  local failed_tests=("$@")
  if [[ ${#failed_tests[@]} -eq 0 ]]; then return; fi
  echo "[ERROR] The following tests failed:"
  for test in "${failed_tests[@]}"; do
    printf "  - %s\n" "${test}"
  done
}

run_tests