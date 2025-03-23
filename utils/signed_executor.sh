#!/bin/bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes
set +x          # Disable debugging

source "$(dirname "${BASH_SOURCE[0]}")/load_dotenv.sh" # Load dotenv

MESSAGE=""
SIGNATURE_B64=""
WRAPPER_PARENT_INFO_DIR="/tmp/signed_executor/"
USED_TOKENS_FILE="/tmp/signed_executor/used_tokens.txt" # File to store used tokens

# Ensure used_tokens.txt file and its parent directory exist
ensure_used_tokens_file_exists() {
    # Check if the directory exists, if not create it
    if [ ! -d "$(dirname "$USED_TOKENS_FILE")" ]; then
        mkdir -p "$(dirname "$USED_TOKENS_FILE")"
    fi

    # If the file doesn't exist, create it
    if [ ! -f "$USED_TOKENS_FILE" ]; then
        touch "$USED_TOKENS_FILE"
    fi
}

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
    echo "$signature_b64" | base64 -d >"$signature_file" 2>/dev/null || {
        printf "ERROR: Malformed base64 signature.\n" >&2
        exit 1
    }
    if ! openssl pkeyutl -verify -pubin -inkey "$PUBLIC_KEY_FILE" -sigfile "$signature_file" -rawin -in "$message_file" 1>/dev/null; then
        printf "ERROR: Invalid signature.\n" >&2
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
        printf "ERROR: Token has expired.\n" >&2
        exit 1
    fi
}

# Function to check if token has already been used
check_token_used() {
    local token="$1"

    # Ensure the used tokens file exists before checking
    ensure_used_tokens_file_exists

    # Check if token is in the list of used tokens
    if grep -q "$token" "$USED_TOKENS_FILE"; then
        printf "ERROR: Token has already been used.\n" >&2
        exit 1
    fi
}

# Function to mark the token as used
mark_token_as_used() {
    local token="$1"

    # Ensure the used tokens file exists before writing
    ensure_used_tokens_file_exists

    # Append the token to the used tokens file
    echo "$token" >>"$USED_TOKENS_FILE"
}

# Save the parent process info (to /tmp/signed_executor/)
save_wrapper_process_info() {
    local parent_pid="$$"
    local caller_script="$0"

    mkdir -p "$WRAPPER_PARENT_INFO_DIR"

    local parent_info_file="${WRAPPER_PARENT_INFO_DIR}parent_process_info_${parent_pid}.txt"

    echo "$parent_pid" >"$parent_info_file"
    echo "$caller_script" >>"$parent_info_file"
}

# Main function
main() {
    local token="$1"
    if [ -z "$token" ]; then
        printf "ERROR: No token provided.\n" >&2
        exit 1
    fi

    # Check if the token has already been used
    check_token_used "$token"

    extract_token_parts "$token"
    verify_signature "$MESSAGE" "$SIGNATURE_B64"
    local timestap nonce expiry command
    # Extract token components from message
    IFS='|' read -r timestap nonce expiry command <<<"$MESSAGE"

    check_expiry "$expiry"

    # Save process info before executing the command
    save_wrapper_process_info

    # Execute the command
    eval "$command"

    # After successful execution, mark the token as used
    mark_token_as_used "$token"
}

# Execute main function with the provided token
main "$1"
