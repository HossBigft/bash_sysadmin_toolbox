#!/bin/bash
# signed_executor_rootless.sh - Executes commands with cryptographic verification
#
# This script verifies a signed token before executing the embedded command.
# Format: timestamp|nonce|expiry|command|signature

set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes

# Load environment variables
source "$(dirname "${BASH_SOURCE[0]}")/utils/load_dotenv.sh"

# Configuration
readonly WRAPPER_PARENT_INFO_DIR="/tmp/signed_executor/"
readonly USED_TOKENS_FILE="${WRAPPER_PARENT_INFO_DIR}/used_tokens.txt"
readonly LOG_FILE="${WRAPPER_PARENT_INFO_DIR}/executor.log"

# Error codes
readonly E_NO_TOKEN=1
readonly E_TOKEN_USED=2
readonly E_BAD_SIGNATURE=3
readonly E_TOKEN_EXPIRED=4
readonly E_NO_PUBLIC_KEY=5
readonly E_GENERIC=99

# Logging function
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >>"$LOG_FILE"
    fi

    # Print errors and warnings to stderr
    if [[ "$level" == "ERROR" || "$level" == "WARNING" ]]; then
        echo "[${level}] ${message}" >&2
    elif [[ "$level" == "DEBUG" && -n "${DEBUG:-}" ]]; then
        echo "[${level}] ${message}" >&2
    fi
}

# Ensure directories and files exist
ensure_directories() {
    if [[ ! -d "$WRAPPER_PARENT_INFO_DIR" ]]; then
        mkdir -p "$WRAPPER_PARENT_INFO_DIR"
        log "INFO" "Created directory: $WRAPPER_PARENT_INFO_DIR"
    fi

    if [[ ! -f "$USED_TOKENS_FILE" ]]; then
        touch "$USED_TOKENS_FILE"
        log "INFO" "Created file: $USED_TOKENS_FILE"
    fi

    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE"
        log "INFO" "Created log file: $LOG_FILE"
    fi
}

# Extract message and signature from token
extract_token_parts() {
    local token="$1"
    local last_pipe_pos

    # Find the position of the last pipe
    last_pipe_pos="$(echo "$token" | grep -bo '|' | tail -1 | cut -d':' -f1)"

    if [[ -z "$last_pipe_pos" ]]; then
        log "ERROR" "No pipe delimiter found in token"
        return 1
    fi

    local message="${token:0:$last_pipe_pos}"
    local signature_b64="${token:$((last_pipe_pos + 1))}"

    log "DEBUG" "Extracted message: $message"
    log "DEBUG" "Extracted signature: $signature_b64"

    printf "%s\n%s" "$message" "$signature_b64"
}

# Verify the cryptographic signature
verify_signature() {
    local message="$1"
    local signature_b64="$2"
    local message_file
    local signature_file
    local result=0

    message_file="$(mktemp)"
    signature_file="$(mktemp)"

    # Write message and signature to temporary files
    echo -n "$message" >"$message_file"

    if ! echo "$signature_b64" | base64 -d >"$signature_file" 2>/dev/null; then
        log "ERROR" "Malformed base64 signature"
        rm -f "$message_file" "$signature_file"
        return $E_BAD_SIGNATURE
    fi

    # Verify signature using OpenSSL
    if ! openssl pkeyutl -verify -pubin -inkey "$PUBLIC_KEY_FILE" \
        -sigfile "$signature_file" -rawin -in "$message_file" 1>/dev/null; then
        log "ERROR" "Invalid signature"
        result=$E_BAD_SIGNATURE
    else
        log "INFO" "Signature verified successfully"
    fi

    # Clean up temporary files
    rm -f "$message_file" "$signature_file"
    return $result
}

# Check if the token has expired
check_expiry() {
    local expiry_time="$1"
    local current_time
    current_time="$(date +%s)"

    if [[ "$current_time" -gt "$expiry_time" ]]; then
        log "ERROR" "Token expired at $(date -d "@$expiry_time"), current time is $(date -d "@$current_time")"
        return $E_TOKEN_EXPIRED
    fi

    log "INFO" "Token is still valid (expires $(date -d "@$expiry_time"))"
    return 0
}

# Check if token has already been used
check_token_used() {
    local token="$1"

    # Check if token is in the list of used tokens
    if grep -q "^${token}$" "$USED_TOKENS_FILE"; then
        log "ERROR" "Token has already been used"
        return $E_TOKEN_USED
    fi

    log "INFO" "Token has not been used before"
    return 0
}

# Mark the token as used
mark_token_as_used() {
    local token="$1"

    log "INFO" "Marking token as used"
    echo "$token" >>"$USED_TOKENS_FILE"
}

# Save the parent process info
save_wrapper_process_info() {
    local parent_pid="$$"
    local caller_script="$0"
    local parent_info_file="${WRAPPER_PARENT_INFO_DIR}/parent_process_info_${parent_pid}.txt"

    log "INFO" "Saving parent process info (PID: $parent_pid)"
    echo "$parent_pid" >"$parent_info_file"
    echo "$caller_script" >>"$parent_info_file"
}

# Execute the command safely
execute_command() {
    local command="$1"

    log "INFO" "Executing command: $command"
    eval "$command"
    log "INFO" "Command executed successfully"
}

# Parse token components
parse_token() {
    local message="$1"
    local timestamp nonce expiry command

    IFS='|' read -r timestamp nonce expiry command <<<"$message"

    if [[ -z "$timestamp" || -z "$nonce" || -z "$expiry" || -z "$command" ]]; then
        log "ERROR" "Invalid token format: missing required components"
        return $E_GENERIC
    fi

    log "DEBUG" "Token timestamp: $timestamp"
    log "DEBUG" "Token nonce: $nonce"
    log "DEBUG" "Token expiry: $expiry ($(date -d "@$expiry"))"
    log "DEBUG" "Token command: $command"

    # Return the parsed components
    printf "%s\n%s\n%s\n%s" "$timestamp" "$nonce" "$expiry" "$command"
}

ensure_public_key() {
    if [[ ! -f "$PUBLIC_KEY_FILE" ]]; then
        log "ERROR" "Public key not found. Provide key for command validation."
        return "$E_NO_PUBLIC_KEY"
    fi
}

# Main function
main() {
    ensure_public_key
    if [[ $# -lt 1 ]]; then
        log "ERROR" "No token provided"
        echo "Usage: $0 <token>" >&2
        return $E_NO_TOKEN
    fi

    local token="$1"
    ensure_directories

    # Check if the token has already been used
    if ! check_token_used "$token"; then
        return $E_TOKEN_USED
    fi

    # Extract token parts
    local token_parts
    if ! token_parts=$(extract_token_parts "$token"); then
        return $E_GENERIC
    fi

    # Get message and signature
    local message signature_b64
    message=$(echo "$token_parts" | head -1)
    signature_b64=$(echo "$token_parts" | tail -1)

    # Verify signature
    if ! verify_signature "$message" "$signature_b64"; then
        return $E_BAD_SIGNATURE
    fi

    # Parse token components
    local parsed_data
    if ! parsed_data=$(parse_token "$message"); then
        return $E_GENERIC
    fi

    # Extract token components
    local timestamp nonce expiry command
    timestamp=$(echo "$parsed_data" | sed -n '1p')
    nonce=$(echo "$parsed_data" | sed -n '2p')
    expiry=$(echo "$parsed_data" | sed -n '3p')
    command=$(echo "$parsed_data" | sed -n '4p')

    # Check if token has expired
    if ! check_expiry "$expiry"; then
        return $E_TOKEN_EXPIRED
    fi

    # Save process info before executing the command
    save_wrapper_process_info

    # Execute the command
    execute_command "$command"

    # After successful execution, mark the token as used
    mark_token_as_used "$token"

    log "INFO" "Token execution completed successfully"
    return 0
}

# Execute main function with all provided arguments
main "$@"
