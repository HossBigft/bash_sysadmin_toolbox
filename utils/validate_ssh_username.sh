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
