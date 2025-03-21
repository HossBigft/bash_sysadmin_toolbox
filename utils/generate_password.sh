#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

#src https://infotechys.com/generate-secure-random-passwords-with-bash/
# Function to generate a random password
generate_password() {
    local length=$1
    # Define the character set for the password
    local char_set="A-Za-z0-9!@#$%^&*()-_=+[]{}|;:,.<>?"

    # Generate a random password using the specified length
    tr -dc "$char_set" </dev/urandom | head -c "$length"
    echo
}

