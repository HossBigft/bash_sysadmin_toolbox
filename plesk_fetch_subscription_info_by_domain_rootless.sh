#!/usr/bin/env bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes
set +x # disable debugging

source "$(dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/execute_mysql_cmd.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/require_wrapper_execution.sh"

validate_input() {
    if [[ $# -ne 1 ]]; then
        printf "Error: Too many or no arguments provided\n" >&2
        exit 1
    fi

    local domain="$1"

    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" >&2
        exit 1
    fi

    echo "$domain"
}

build_sql_query() {
    local domain="$1"
    cat <<EOF
SELECT 
    base.subscription_id AS result,
    (SELECT name FROM domains WHERE id = base.subscription_id) AS name,
    (SELECT pname FROM clients WHERE id = base.cl_id) AS username,
    (SELECT login FROM clients WHERE id = base.cl_id) AS userlogin,
    (SELECT GROUP_CONCAT(CONCAT(d2.name, ':', d2.status) SEPARATOR ',')
        FROM domains d2 
        WHERE base.subscription_id IN (d2.id, d2.webspace_id)) AS domains,
    (SELECT overuse FROM domains WHERE id = base.subscription_id) as is_space_overused,
    (SELECT ROUND(real_size/1024/1024) FROM domains WHERE id = base.subscription_id) as subscription_size_mb,
    (SELECT status FROM domains WHERE id = base.subscription_id) as subscription_status
FROM (
    SELECT 
        CASE 
            WHEN webspace_id = 0 THEN id 
            ELSE webspace_id 
        END AS subscription_id,
        cl_id,
        name
    FROM domains 
    WHERE name LIKE '$domain'
) AS base;
EOF
}

main() {
    require_wrapper_execution
    
    local domain
    domain="$(validate_input "$@")"

    local sql_query
    sql_query="$(build_sql_query "$domain")"

    execute_query "$sql_query"
}

main "$@"
