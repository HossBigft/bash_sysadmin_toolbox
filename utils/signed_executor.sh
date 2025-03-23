#!/bin/bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes
set +x          # disable debugging

PUBLIC_KEY_FILE="ed25519_public.pem" # Ensure this file contains a valid Ed25519 public key
MESSAGE=""
SIGNATURE_B64=""
WRAPPER_PROCESS_INFO_TMP_PATH="/tmp/wrapper_process_info_"

# Function to extract message and signature from token
extract_token_parts() {
    local token="$1"
    MESSAGE="$(echo "$token" | rev | cut -d'|' -f2- | rev)"
    SIGNATURE_B64="$(echo "$token" | rev | cut -d'|' -f1 | rev)"
}

# Function to verify the signature
verify_signature() {
    local message="$1"
    local signature_b64="$2"
    local message_file
    message_file="$(mktemp)"
    local signature_file
    signature_file="$(mktemp)"

    echo -n "$message" >"$message_file"
    echo "$signature_b64" | base64 -d >"$signature_file"

    if ! openssl pkeyutl -verify -pubin -inkey "$PUBLIC_KEY_FILE" -sigfile "$signature_file" -rawin -in "$message_file" 1>/dev/null; then
        echo "ERROR: Invalid signature"
        rm -f "$message_file" "$signature_file"
        exit 1
    fi

    rm -f "$message_file" "$signature_file"
}

# Function to check if the token has expired
check_expiry() {
    local expiry_time="$1"
    local current_time
    current_time="$(date +%s)"
    if [ "$current_time" -gt "$expiry_time" ]; then
        echo "ERROR: Token has expired"
        exit 1
    fi
}

save_wrapper_process_info() {
    local parent_pid="$$"
    local caller_script="$0"
    local parent_info_file="${WRAPPER_PROCESS_INFO_TMP_PATH}${parent_pid}.txt"
    echo "$parent_pid" >"$parent_info_file"
    echo "$caller_script" >>"$parent_info_file"
}

# Main function
main() {
    local token="$1"
    if [ -z "$token" ]; then
        echo "ERROR: No token provided"
        exit 1
    fi

    extract_token_parts "$token"
    verify_signature "$MESSAGE" "$SIGNATURE_B64"

    # Extract token components from message
    IFS='|' read -r TIMESTAMP NONCE EXPIRY COMMAND <<<"$MESSAGE"

    check_expiry "$EXPIRY"

    save_wrapper_process_info
    eval "$COMMAND"
}

# Execute main function with the provided token
main "$1"
