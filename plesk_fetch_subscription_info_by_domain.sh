#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

source "$(\dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"
source "$(\dirname "${BASH_SOURCE[0]}")/utils/load_dotenv.sh"

main() {

    if [[ $# -ne 1 ]]; then
        printf "Error: Too many or no arguments provided\n" 1>&2
        exit 1
    fi
    local domain="$1"

    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" 1>&2
        exit 1
    fi

    local mysql_version
    mysql_version="$(mysql --version)"
    local mysql_cli_name=""
    if [[ "$mysql_version" =~ 'MariaDB' ]]; then
        mysql_cli_name='mariadb'
    else
        mysql_cli_name='mysql'
    fi

    DB_USER="$(\whoami)"
    DB_PASS="$DATABASE_PASSWORD"
    DB_NAME="psa"
    DB_HOST="localhost"

    SQL_QUERY="
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
"

    $mysql_cli_name --host="$DB_HOST" --user="$DB_USER" --password="$DB_PASS" --database="$DB_NAME" --batch --skip-column-names --raw -e "$SQL_QUERY"

}
main "$@"
