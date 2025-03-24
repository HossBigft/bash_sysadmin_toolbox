#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [[ -z "${LOG_FILE:-}" ]]; then
    printf "%s" "ERROR: LOG_FILE is not set. Please set it before sourcing this script." >&2
    exit 1  
fi

# Logging function
log() {
    local log_file
    log_file="$LOG_FILE"
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "[${timestamp}] [${level}] ${message}" >>"$log_file"
    fi

    # Print errors and warnings to stderr
    if [[ "$level" == "ERROR" || "$level" == "WARNING" ]]; then
        echo "[${level}] ${message}" >&2
    elif [[ "$level" == "DEBUG" && -n "${DEBUG:-}" ]]; then
        echo "[${level}] ${message}" >&2
    fi
}
