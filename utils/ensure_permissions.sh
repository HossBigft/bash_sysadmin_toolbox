#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

declare SCRIPT_DIR
SCRIPT_DIR="$(realpath .)"
readonly SCRIPT_DIR

ensure_permissions() {
    echo "Setting scripts dir $SCRIPT_DIR to 705"
    chmod  705 "$SCRIPT_DIR"

    echo "Setting  root only permissions (700) for all files in $SCRIPT_DIR"
    find "$SCRIPT_DIR" -type f -exec chmod 700 {} +

    append_sudo_rules_for_scripts
}
