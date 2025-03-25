#!/usr/bin/env bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes

source "$(dirname "${BASH_SOURCE[0]}")/utils/ensure_permissions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/sudo_rules_manager.sh"
main () {
    ensure_permissions
    
}

main