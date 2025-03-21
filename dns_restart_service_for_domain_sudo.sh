#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

source "$(dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"

main() {

    if [[ $# -ne 1 ]]; then
        printf "Error: Too many or no arguments provided\n" 1>&2
        exit 1
    fi
    declare domain="$1"

    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" 1>&2
        exit 1
    fi

    if ! \plesk bin dns --off "$domain" 1>/dev/null; then
        exit 1
    fi

    if ! \plesk bin dns --on "$domain" 1>/dev/null; then
        exit 1
    fi
}

main "$@"
