#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

validate_subscription_id() {
    local id="$1"
    local int10_pattern='^(?:0|[1-9]\d{0,8}|42949672[0-8]\d|429496729[0-5])$' #plesk uses int10 internally

    if [[ ! "$id" =~ $int10_pattern ]]; then
        printf "Error: Invalid subscription id\n" >&2
        return 1
    fi

    return 0
}

validate_subscription_id "$@"
