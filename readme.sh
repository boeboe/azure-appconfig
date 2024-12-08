#!/usr/bin/env bash
# readme.sh - Script to generate README.md from action.yml file

set -euo pipefail
trap 'echo "[ERROR] Script failed at line $LINENO with exit code $? (last command: $BASH_COMMAND)"' ERR

function print_usage() {
    echo "Usage: $0 --input <action.yml> --output <README.md>"
}

function generate_readme() {
    local input_file="$1"
    local output_file="$2"

    # Extract action details
    local name description
    name=$(yq eval '.name' "$input_file")
    description=$(yq eval '.description' "$input_file")

    # Generate README.md content
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

    echo "[INFO] README.md generated at $output_file"
}

# Parse arguments
INPUT_FILE=""
OUTPUT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --input)
            INPUT_FILE="$2"
            shift 2
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
if [[ -z "$INPUT_FILE" || -z "$OUTPUT_FILE" ]]; then
    print_usage
    exit 1
fi

if [[ ! -f "$INPUT_FILE" || ! -r "$INPUT_FILE" ]]; then
    echo "[ERROR] Input file '$INPUT_FILE' does not exist or is not readable."
    exit 1
fi

generate_readme "$INPUT_FILE" "$OUTPUT_FILE"