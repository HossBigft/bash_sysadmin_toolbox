#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

validate_subscription_id() {
    local id="$1"
    local int10_pattern='^(0|[1-9][0-9]{0,8}|42949672[0-8][0-9]|429496729[0-5])$' #plesk uses int10 internally

    if [[ ! "$id" =~ $int10_pattern ]]; then
        printf "Error: Invalid subscription id\n" >&2
        return 1
    fi

    return 0
}

# Only run this part when the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    if [[ $# -eq 0 ]]; then
        printf "Usage: %s <subscription id>\n" "$(basename "$0")" >&2
        exit 1
    fi

    validate_subscription_id "$1"
fi
