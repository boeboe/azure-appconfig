#!/usr/bin/env bash
# readme.sh - Script to generate README.md files from action.yml files

set -euo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO with exit code $? (last command: $BASH_COMMAND)"' ERR

function print_usage() {
    echo "Usage:"
    echo "  $0 action --input <action.yml> --output <README.md>"
    echo "  $0 general --input <action1.yml> <action2.yml> ... --output <README.md>"
}

function generate_action_readme() {
    local input_file="$1"
    local output_file="$2"

    # Extract action details
    local name description
    name=$(yq eval '.name' "$input_file")
    description=$(yq eval '.description' "$input_file")

    # Generate README.md content for individual action
    {
        printf "# %s\n\n" "$name"
        printf "%s\n\n" "$description"

        # Inputs Section
        echo "## Inputs"
        echo "| Name               | Mandatory | Default         | Description                                    |"
        echo "|--------------------|-----------|-----------------|------------------------------------------------|"
        yq eval -o=json '.inputs | to_entries[]' "$input_file" | \
        jq -r '. | "| " + .key + " | " + (.value.required | tostring) + " | " + (.value.default // "None") + " | " + (.value.description // "No description") + " |"'

        # Outputs Section
        echo -e "\n## Outputs"
        echo "| Name               | Description                                    |"
        echo "|--------------------|------------------------------------------------|"
        yq eval -o=json '.outputs | to_entries[]' "$input_file" | \
        jq -r '. | "| " + .key + " | " + (.value.description // "No description") + " |"'

        # Steps Section
        echo -e "\n## Steps"
        echo "| Step ID            | Step Name                                      |"
        echo "|--------------------|------------------------------------------------|"
        yq eval -o=json '.runs.steps' "$input_file" | \
        jq -r '.[] | "| " + (.id // "Unnamed ID") + " | " + (.name // "Unnamed Step") + " |"'
    } > "$output_file"

    echo "[INFO] README.md generated for action at $output_file"
}

function generate_general_readme() {
    local output_file="$1"
    shift
    local input_files=("$@")

    # Generate general README content
    {
        printf "# Azure App Configuration Actions\n\n"
        printf "This repository contains the following actions for managing Azure App Configuration:\n\n"
        printf "## Actions Overview\n"
        printf "| Action             | Name                            | Description                                    |\n"
        printf "|--------------------|---------------------------------|------------------------------------------------|\n"

        for input_file in "${input_files[@]}"; do
            local action name description
            action=$(basename "$(dirname "$input_file")")
            name=$(yq eval '.name' "$input_file")
            description=$(yq eval '.description' "$input_file")
            printf "| [%s](./%s/README.md) | %-31s | %-47s |\n" "$action" "$action" "$name" "$description"
        done
    } > "$output_file"

    echo "[INFO] General README.md generated at $output_file"
}

# Parse arguments
MODE=""
INPUT_FILES=()
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        action)
            MODE="action"
            shift
            ;;
        general)
            MODE="general"
            shift
            ;;
        --input)
            shift
            while [[ $# -gt 0 && $1 != --output ]]; do
                INPUT_FILES+=("$1")
                shift
            done
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$MODE" || -z "$OUTPUT_FILE" || ${#INPUT_FILES[@]} -eq 0 ]]; then
    print_usage
    exit 1
fi

for input_file in "${INPUT_FILES[@]}"; do
    if [[ ! -f "$input_file" || ! -r "$input_file" ]]; then
        echo "[ERROR] Input file '$input_file' does not exist or is not readable."
        exit 1
    fi
done

# Generate the appropriate README.md
if [[ "$MODE" == "action" ]]; then
    if [[ ${#INPUT_FILES[@]} -ne 1 ]]; then
        echo "[ERROR] 'action' mode requires exactly one input file."
        exit 1
    fi
    generate_action_readme "${INPUT_FILES[0]}" "$OUTPUT_FILE"
elif [[ "$MODE" == "general" ]]; then
    generate_general_readme "$OUTPUT_FILE" "${INPUT_FILES[@]}"
else
    print_usage
    exit 1
fi