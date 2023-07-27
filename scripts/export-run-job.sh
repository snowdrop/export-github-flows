#!/usr/bin/env bash
SCRIPTS_DIR="$(cd $(dirname "${BASH_SOURCE}") && pwd)"
source ${SCRIPTS_DIR}/scripts/toolbox.sh

set -euo pipefail

parse_yaml() {
    local file="$1"
    local yaml_content
    yaml_content=$(cat "$file")

    local job_blocks
    job_blocks=$(echo "$yaml_content" | grep -oP '(?<=jobs:)[\s\S]*?(?=steps:)')

    while IFS='' read -r job; do
        local job_name
        job_name=$(echo "$job" | grep -oP '(?<=name: ).*')

        local run_block
        run_block=$(echo "$job" | grep -oP '(?<=run:)[\s\S]*?(?=script:)')

        local script_block
        script_block=$(echo "$job" | grep -oP '(?<=script:)[\s\S]*?(?=-|[])')

        if [ -n "$run_block" ]; then
            echo "$run_block" > "job${job_name}.txt"
        elif [ -n "$script_block" ]; then
            echo "$script_block" > "job${job_name}.txt"
        else
            echo "Error: Unable to find 'run:' or 'script:' block for job $job_name"
            exit 1
        fi
    done <<< "$job_blocks"
}

main() {
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <github_workflow.yml>"
        exit 1
    fi

    local yaml_file="$1"
    parse_yaml "$yaml_file"
}

main "$@"
