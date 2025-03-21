#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

# Get absolute path of the script
SCRIPT_PATH="$(realpath "$0")"

# Extract username from the script path (assuming the format is /home/<user>/...)
USER_NAME="$(echo "$SCRIPT_PATH" | awk -F'/' '{print $3}')"

# Get the directory containing this script (parent directory)
SCRIPTS_DIR="$(dirname "$SCRIPT_PATH")"

# Find all *_sudo.sh scripts in the parent directory
RULES=""
for script in "${SCRIPTS_DIR}"/*_sudo.sh; do
    [ -f "$script" ] || continue  # Skip if no matching files
    RULE="${USER_NAME} ALL=(ALL) NOPASSWD: ${script}"
    
    # Add rule if it doesn't exist
    if ! sudo grep -Fxq "$RULE" /etc/sudoers; then
        RULES+="${RULE}\n"
    fi
done

# If there are new rules, append them using visudo
if [[ -n "$RULES" ]]; then
    printf "%b" "$RULES" | sudo EDITOR='tee -a' visudo
    printf "Added the following sudoers rules:\n%b" "$RULES"
else
    printf "No new rules added. They already exist.\n"
fi

# Verify updated sudoers file
printf "\nUpdated sudoers file:\n"
sudo -l -U "$USER_NAME"
