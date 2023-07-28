#!/usr/bin/env bash
SCRIPTS_DIR="$(cd $(dirname "${BASH_SOURCE}") && pwd)"
source ${SCRIPTS_DIR}/toolbox.sh

parse_yaml() {
  yaml_file="$1"
  local json_content=$(yq -o json $yaml_file | jq -r 'walk(if type == "null" then "" else . end)')

  env_pairs=$(echo "$json_content" | jq -r '.. | .env? | select(.) | to_entries[] | "\(.key)=\(.value)"')

  # Export each key-value pair as environment variables
  echo "################# ENV VARIABLES #################"
  while IFS='=' read -r key value; do
    echo "export $key"="$value"
  done <<< "$env_pairs"
  echo "################# end env variable #################"

  # Iterate through each job key
  echo "$json_content" | jq -r '.jobs | keys[]' | while read -r job; do
    echo "################# Job name: $job #################"

    # Get the steps array for the current job
    steps=$(echo "$json_content" | jq -r ".jobs[\"$job\"].steps")

    # Check if steps array is not null
    if [ "$steps" != "null" ]; then
      # Iterate through the steps and echo their names and run content
      echo "$steps" | jq -r 'map(select(has("run"))) | .[] | "# Step: \(.name)\n\(.run)"'
    else
      echo "No steps found for this job."
    fi

    echo "################# end job #################"
  done
}

main() {
  if [ $# -eq 0 ]; then
    echo "Usage: $0 <github_workflow.yml>"
    exit 1
  fi

  parse_yaml "$1"
}

main "$@"
