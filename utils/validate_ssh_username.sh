#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

validate_username() {
    local username="$1"
    local username_regex='^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$'

    if [[ ! "$username" =~ $username_regex ]]; then
        printf "Error: Invalid username\n" >&2
        return 1
    fi
    return 0
}

# Only run this part when the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -eq 0 ]]; then
        printf "Usage: %s <username>\n" "$(basename "$0")" >&2
        exit 1
    fi

    validate_username "$1"
fi
