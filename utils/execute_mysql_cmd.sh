#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

source "$(dirname "${BASH_SOURCE[0]}")/load_dotenv.sh" #Load dotenv
source "$(dirname "${BASH_SOURCE[0]}")/is_mysql_installed.sh"

get_mysql_cli_name() {
    local mysql_version
    mysql_version="$(mysql --version)"

    if [[ "$mysql_version" =~ 'MariaDB' ]]; then
        echo "mariadb"
    else
        echo "mysql"
    fi
}

execute_query() {
    if ! is_mysql_installed; then
        printf "Error: MySQL not installed. Query not executed.\n" >&2
        exit 1
    fi

    local sql_query="$1"
    local db_user
    db_user="$DATABASE_USER"
    local db_pass="$DATABASE_PASSWORD"
    local db_name="psa"
    local db_host="localhost"
    local mysql_cli_name
    mysql_cli_name="$(get_mysql_cli_name)"

    if [[ "$db_user" = "root" ]]; then
        printf "Error: Execution as root is not allowed.\n" >&2
        exit 1
    fi

    "$mysql_cli_name" --host="$db_host" --user="$db_user" --password="$db_pass" --database="$db_name" --batch --skip-column-names --raw -e "$sql_query"
}
