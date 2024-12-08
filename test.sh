#!/usr/bin/env bash
# test.sh - Script to execute all test-*.sh scripts in the ./tests directory

set -euo pipefail
trap 'echo "[ERROR] Test script failed at line $LINENO with exit code $?."' ERR

echo "[INFO] Running all test scripts in ./tests..."

# Find and execute all test-*.sh scripts
find ./tests -type f -name 'test_*.sh' -exec bash {} \;

echo "[INFO] All test scripts executed successfully."