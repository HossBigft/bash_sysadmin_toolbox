#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

# Get absolute path of the script and user info
get_script_info() {
    local script_path
    script_path="$(realpath "$0")"
    local user_name
    user_name="$(echo "$script_path" | awk -F'/' '{print $3}')"
    local scripts_dir
    scripts_dir="$(realpath "$(dirname "$script_path")/..")"

    echo "$user_name" "$scripts_dir"
}

# Find all *_sudo.sh scripts and generate sudo rules
generate_sudo_rules() {
    local user_name="$1"
    local scripts_dir="$2"
    local rules=""

    for script in "${scripts_dir}"/*_sudo.sh; do
        [ -f "$script" ] || continue # Skip if no matching files
        local rule="${user_name} ALL=(ALL) NOPASSWD: ${script} *"

        # Add rule if it doesn't exist
        if ! sudo grep -Fxq "$rule" /etc/sudoers; then
            rules+="${rule}\n"
        fi
    done

    echo -e "$rules"
}

# Print added sudo rules
print_sudo_rules() {
    local username="$1"
    printf "\nAdded rules:\n"
    sudo -l -U "$username" | grep 'NOPASSWD'
}

# Append new sudo rules if they are not already present
add_sudo_rules() {
    local rules="$1"
    if [[ -n "$rules" ]]; then
        printf "%b" "$rules" | sudo EDITOR='tee -a' visudo >/dev/null 2>&1
        local username
        username="$(echo "$rules" | awk -F'/' '{print $3}' | head -n1)"
        print_sudo_rules "$username"
    else
        printf "No new rules added. They already exist.\n"
    fi
}

# Main function
main() {
    # Extract user and scripts directory
    read -r user_name scripts_dir <<<"$(get_script_info)"

    # Generate rules
    rules="$(generate_sudo_rules "$user_name" "$scripts_dir")"

    # Apply rules
    add_sudo_rules "$rules"
}

main
