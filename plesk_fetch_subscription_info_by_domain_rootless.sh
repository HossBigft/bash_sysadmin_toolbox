#!/usr/bin/env bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes

source "$(dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"
source "$(dirname "${BASH_SOURCE[0]}")/utils/load_dotenv.sh"

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

get_mysql_cli_name() {
    local mysql_version
    mysql_version="$(mysql --version)"
    
    if [[ "$mysql_version" =~ 'MariaDB' ]]; then
        echo "mariadb"
    else
        echo "mysql"
    fi
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

execute_query() {
    local mysql_cli_name="$1"
    local sql_query="$2"

    local db_user
    db_user="$DATABASE_USER"
    local db_pass="$DATABASE_PASSWORD"
    local db_name="psa"
    local db_host="localhost"

    "$mysql_cli_name" --host="$db_host" --user="$db_user" --password="$db_pass" --database="$db_name" --batch --skip-column-names --raw -e "$sql_query"
}

main() {
    local domain
    domain="$(validate_input "$@")"

    local mysql_cli_name
    mysql_cli_name="$(get_mysql_cli_name)"

    local sql_query
    sql_query="$(build_sql_query "$domain")"

    execute_query "$mysql_cli_name" "$sql_query"
}

main "$@"
