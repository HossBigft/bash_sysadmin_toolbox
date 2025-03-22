#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Don't hide errors within pipes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${ENV_FILE:-$PROJECT_ROOT/.env}"  # Allow overriding .env path

load_dotenv() {
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "Error: $ENV_FILE not found" >&2
        exit 1
    fi

    # Read .env file, ignoring comments & empty lines, and export variables
    while IFS='=' read -r key value; do
        key=$(echo "$key" | xargs)   # Trim whitespace
        value=$(echo "$value" | xargs) # Trim whitespace
        if [[ -n "$key" && "${key:0:1}" != "#" ]]; then
            export "$key"="$value"
        fi
        
    done < <(grep -Ev '^\s*#|^\s*$' "$ENV_FILE")
}

load_dotenv
