#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

is_valid_domain() {
    local domain="$1"
    local domain_regex='^([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,6}\.?$'

    if [[ ! "$domain" =~ $domain_regex ]]; then
        return 1
    fi

    return 0
}
