#!/usr/bin/env bash
# multipass.sh - Script to manage Multipass VM lifecycle and configuration
set -euo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO with exit code $?."' ERR

# Configuration
VM_NAME="test-azure-appconfig"
VM_MEMORY="2G"
VM_DISK="10G"
VM_CPUS="2"
VM_MOUNT_PATH="/home/ubuntu/azure-appconfig"
PWD_PATH=$(pwd)
SCRIPTS_DIR="${VM_MOUNT_PATH}/scripts"
TEST_DIR="${VM_MOUNT_PATH}/tests"

# Helper functions
function print_usage() {
    echo "Usage: ${0} <action>"
    echo "Actions:"
    echo "  start      Start the VM and mount the current directory"
    echo "  stop              Stop the VM"
    echo "  delete            Delete the VM"
    echo "  ssh               SSH into the VM"
}

function do_check() {
    if ! command -v multipass &>/dev/null; then
        echo "[ERROR] Multipass is not installed. Please install Multipass to proceed."
        exit 1
    fi
    echo "[INFO] Multipass is installed."
}

function do_start() {
    do_check
    if ! multipass list | grep -q "${VM_NAME}"; then
        echo "[INFO] Starting Multipass VM '${VM_NAME}'..."
        multipass launch --name "${VM_NAME}" --memory "${VM_MEMORY}" --disk "${VM_DISK}" --cpus "${VM_CPUS}"
    else
        echo "[INFO] Multipass VM '${VM_NAME}' is already running."
    fi

    if ! multipass info "${VM_NAME}" | grep -q "${VM_MOUNT_PATH}"; then
        echo "[INFO] Mounting '${PWD_PATH}' to '${VM_NAME}:${VM_MOUNT_PATH}'..."
        multipass mount "${PWD_PATH}" "${VM_NAME}:${VM_MOUNT_PATH}"
    else
        echo "[INFO] '${VM_MOUNT_PATH}' is already mounted in '${VM_NAME}'."
    fi

    echo "[INFO] Ensuring SCRIPTS_DIR and TEST_DIR are added to the PATH inside the VM..."
    multipass exec "${VM_NAME}" -- bash -c "
        grep -q 'export SCRIPTS_DIR=${SCRIPTS_DIR}' ~/.bashrc || echo 'export SCRIPTS_DIR=${SCRIPTS_DIR}' >> ~/.bashrc
        grep -q 'export PATH=${SCRIPTS_DIR}:\$PATH' ~/.bashrc || echo 'export PATH=${SCRIPTS_DIR}:\$PATH' >> ~/.bashrc
        grep -q 'export PATH=${TEST_DIR}:\$PATH' ~/.bashrc || echo 'export PATH=${TEST_DIR}:\$PATH' >> ~/.bashrc
    "

    install_tools
}

function do_stop() {
    do_check
    if multipass list | grep -q "${VM_NAME}"; then
        echo "[INFO] Stopping Multipass VM '${VM_NAME}'..."
        multipass stop "${VM_NAME}"
    else
        echo "[INFO] Multipass VM '${VM_NAME}' is not running."
    fi
}

function do_delete() {
    do_check
    if multipass list | grep -q "${VM_NAME}"; then
        echo "[INFO] Deleting Multipass VM '${VM_NAME}'..."
        multipass delete "${VM_NAME}"
        multipass purge
    else
        echo "[INFO] Multipass VM '${VM_NAME}' does not exist."
    fi
}

function do_ssh() {
    do_check
    if multipass list | grep -q "${VM_NAME}"; then
        echo "[INFO] Connecting to Multipass VM '${VM_NAME}'..."
        multipass shell "${VM_NAME}"
    else
        echo "[ERROR] Multipass VM '${VM_NAME}' is not running. Please start it first."
        exit 1
    fi
}

function install_tools() {
    echo "[INFO] Installing az CLI and yq inside the Multipass VM..."

    # Check if az CLI is installed in the VM
    multipass exec "${VM_NAME}" -- bash -c "
        if ! command -v az &>/dev/null; then
            echo '[INFO] Azure CLI is not installed. Installing...'
            sudo apt update -y
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        else
            echo '[INFO] Azure CLI is already installed.'
        fi
    "

    # Check if yq is installed in the VM
    multipass exec "${VM_NAME}" -- bash -c "
        if ! command -v yq &>/dev/null; then
            echo '[INFO] yq is not installed. Installing...'
            sudo add-apt-repository -y ppa:rmescandon/yq
            sudo apt update -y
            sudo apt install -y yq
        else
            echo '[INFO] yq is already installed.'
        fi
    "

    echo "[INFO] az CLI and yq installation check completed."
}

# Main script logic
if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

action="$1"
shift

case "${action}" in
    start)         do_start ;;
    stop)          do_stop ;;
    delete)        do_delete ;;
    ssh)           do_ssh ;;
    *) 
        echo "[ERROR] Unknown action: ${action}"
        print_usage
        exit 1
        ;;
esac