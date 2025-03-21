#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

load_dotenv() {
    ENV_FILE="$PROJECT_ROOT/.env"
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "Error: $ENV_FILE not found" >&2
        exit 1
    fi

    source <(cat "$ENV_FILE" | sed -e '/^#/d;/^\s*$/d' -e "s/'/'\\\''/g" -e "s/=\(.*\)/='\1'/g")
}
load_dotenv
