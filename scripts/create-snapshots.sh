#!/usr/bin/env bash
# create-snapshots.sh - Script to validate inputs and create snapshots for Azure App Configuration
# shellcheck disable=SC1091

set -euo pipefail

# Source the shared logging and validation utilities
source "${SCRIPTS_DIR}/functions/logging.sh"
source "${SCRIPTS_DIR}/functions/validation.sh"
source "${SCRIPTS_DIR}/functions/parsing.sh"
source "${SCRIPTS_DIR}/functions/json.sh"
source "${SCRIPTS_DIR}/functions/az-appconfig.sh"
