#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

# Get absolute path of the script
get_script_info() {
    SCRIPT_PATH="$(realpath "$0")"
    USER_NAME="$(echo "$SCRIPT_PATH" | awk -F'/' '{print $3}')"
    SCRIPTS_DIR="$(realpath "$(dirname "$SCRIPT_PATH")/..")"
}

# Find all *_sudo.sh scripts and generate sudo rules
generate_sudo_rules() {
    RULES=""
    for script in "${SCRIPTS_DIR}"/*_sudo.sh; do
        [ -f "$script" ] || continue # Skip if no matching files
        RULE="${USER_NAME} ALL=(ALL) NOPASSWD: ${script} *"

        # Add rule if it doesn't exist
        if ! sudo grep -Fxq "$RULE" /etc/sudoers; then
            RULES+="${RULE}\n"
        fi
    done
}

add_sudo_rules() {
    if [[ -n "$RULES" ]]; then
        printf "%b" "$RULES" | sudo EDITOR='tee -a' visudo
        print_sudo_rules
    else
        printf "No new rules added. They already exist.\n"
    fi
}

print_sudo_rules() {
    printf "\nSudo rules:\n"
    sudo -l -U "$USER_NAME" | grep 'NOPASSWD'
}

main() {
    get_script_info
    generate_sudo_rules
    add_sudo_rules
}

main
