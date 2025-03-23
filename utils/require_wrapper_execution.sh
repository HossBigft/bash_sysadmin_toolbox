#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

WRAPPER_NAME="verify_signature.sh"
WRAPPER_PROCESS_INFO_TMP_PATH="/tmp/wrapper_process_info_"

get_parent_info_file() {
    local parent_info_file
    parent_info_file="$(find "$WRAPPER_PROCESS_INFO_TMP_PATH"* -maxdepth 0 -type f -printf "%T@ %p\n"  2>/dev/null| sort -k1,1nr | awk '{print $2; exit}')"


    if [[ -z "$parent_info_file" ]]; then
        echo "ERROR: No parent info file found."
        return 1  
    fi

    echo "$parent_info_file" 
}

read_parent_info() {
    local parent_process_info_file="$1"
    if [[ -f "$parent_process_info_file" ]]; then
        {
            read -r parent_pid
            read -r caller_script
        } <"$parent_process_info_file"
        rm -f "$parent_process_info_file"
    else
        echo "ERROR: Parent info file is missing!" >&2
        exit 1
    fi
}

validate_parent_process() {
    if ! ps -p "$parent_pid" >/dev/null 2>&1; then
        echo "ERROR: Parent process $parent_pid does not exist!" >&2
        exit 1
    fi
}

validate_caller_script() {
    if [[ "$caller_script" != *"$WRAPPER_NAME"* ]]; then
        echo "ERROR: Unauthorized caller ($caller_script)!" >&2
        exit 1
    fi
}

require_wrapper_execution() {
    local parent_info_file
    parent_info_file="$(get_parent_info_file)"
    read_parent_info "$parent_info_file"
    validate_caller_script
    validate_parent_process
}
