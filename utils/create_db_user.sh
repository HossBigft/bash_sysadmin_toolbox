#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

source "$(dirname "${BASH_SOURCE[0]}")/generate_password.sh"
source "$(dirname "${BASH_SOURCE[0]}")/is_mysql_installed.sh"

readonly DB_USER="sysadmin_toolbox"
readonly DB_USER_ENV_VARIABLE="DATABASE_USER"
readonly DB_PASS_ENV_VARIABLE="DATABASE_PASSWORD"
create_db_user() {

    if ! is_mysql_installed; then
        printf "MySQL not installed. Skipping db user creation.\n"
        exit 1
    fi

    local password
    password="$(generate_password 15)"
    local is_user_exists

    is_user_exists="$(plesk db -Ne "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '${DB_USER}')")"

    if [[ is_user_exists -eq 0 ]]; then
        plesk db "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${password}';"
        #grant redonly access to all databases and tables
        plesk db "GRANT SELECT on *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;"

        echo "Writing database user to .env"
        echo "${DB_USER_ENV_VARIABLE}=${DB_USER}" >>.env

        echo "Writing database user password to .env"
        echo "${DB_PASS_ENV_VARIABLE}=${password}" >>.env
    else
        printf "Database user %s already exists.\n" "$DB_USER"

        if ! grep -q "$DB_USER_ENV_VARIABLE" ".env"; then
            echo "Writing database user to .env"
            echo "${DB_USER_ENV_VARIABLE}=${DB_USER}" >>.env
        fi
        exit
    fi
}
