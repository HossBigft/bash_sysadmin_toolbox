#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

source "$(\dirname "${BASH_SOURCE[0]}")/utils/validate_ssh_username.sh"
source "$(\dirname "${BASH_SOURCE[0]}")/utils/validate_subscription_id.sh"
source "$(\dirname "${BASH_SOURCE[0]}")/utils/execute_mysql_cmd.sh"

REDIRECTION_HEADER="&success_redirect_url=%2Fadmin%2Fsubscription%2Foverview%2Fid%2F"

# Function to check if a subscription ID exists
is_subscription_id_exist() {
    local subscription_id="$1"

    local get_subscription_name_cmd="plesk db -Ne \"SELECT name FROM domains WHERE webspace_id=0 AND id=$subscription_id\""
    local result
    result=$(eval "$get_subscription_name_cmd" 2>/dev/null)

    if [[ -z "$result" ]]; then
        return 1 # Subscription does not exist
    else
        return 0 # Subscription exists
    fi
}

# Function to fetch Plesk login link
plesk_fetch_plesk_login_link() {
    local ssh_username="$1"
    validate_username "$ssh_username"
    local cmd_to_run
    cmd_to_run="plesk login ${ssh_username}"

    local result
    result=$(eval "$cmd_to_run" 2>/dev/null)

    echo "$result"
}

get_admin_list() {
    local admin_list
    local query
    query='SELECT login FROM smb_users WHERE isLocked=0'
    admin_list="$(execute_query "$query" | grep -v 'admin')" #exclude anonymous user
    echo "$admin_list"
}

validate_admin_username() {
    local username="$1"
    if get_admin_list | grep -wq "$username"; then
        echo "Error: wrong username" >&2
        exit 1
    else
        exit 0
    fi
}

plesk_generate_subscription_login_link() {
    if [[ $# -ne 2 ]]; then
        printf "Error: Too many or no arguments provided\n" >&2
        exit 1
    fi

    local subscription_id="$1"
    validate
    local ssh_username="$2"
    validate_username "$ssh_username"

    if ! is_subscription_id_exist "$subscription_id"; then
        echo "Error: Subscription with ID $subscription_id doesn't exist." >&2
        exit 1
    fi

    local plesk_login_link
    plesk_login_link=$(plesk_fetch_plesk_login_link "$ssh_username")

    local subscription_login_link="${plesk_login_link}${REDIRECTION_HEADER}${subscription_id}"

    echo "$subscription_login_link"
}

plesk_generate_subscription_login_link "$@"
