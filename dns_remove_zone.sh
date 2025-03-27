#!/bin/bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes

source "$(\dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/wrapper_manager.sh"

validate_input() {
    if [[ $# -ne 1 ]]; then
        printf "Error: Too many or no arguments provided\n" >&2
        exit 1
    fi

    local domain="$1"

    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid domain name\n" >&2
        exit 1
    fi

    echo "$domain"
}

main() {
    require_wrapper_execution
    local domain
    domain="$(validate_input "$@")"
    /opt/isc/isc-bind/root/usr/sbin/rndc delzone -clean "$domain"
}

main "$@"
