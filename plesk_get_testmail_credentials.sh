#!/usr/bin/env bash
set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

source "$(\dirname "${BASH_SOURCE[0]}")/utils/domain_validator.sh"
source "$(\dirname "${BASH_SOURCE[0]}")/utils/generate_password.sh"
#!/usr/bin/env bash

set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

TEST_MAIL_LOGIN='testsupportmail'
MAIL_DESCRIPTION='throwaway mail for troubleshooting purposes. You may delete it at will.'
MAIL_PASSWORD_LENGTH='15'

get_mail_password() {
    local domain="$1"
    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" 1>&2
        exit 1
    fi
    /usr/local/psa/admin/bin/mail_auth_view | grep -F "${TEST_MAIL_LOGIN}@${domain}" | tr -d '[:space:]' | awk -F'|' '{print $4}'
}

create_testmail() {
    local domain="$1"
    local password="$2"
    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" 1>&2
        exit 1
    fi
    plesk bin mail --create "${TEST_MAIL_LOGIN}@${domain}" -passwd "${password}" -mailbox true -description "$MAIL_DESCRIPTION"
}

plesk_get_testmail_credentials() {
    local domain="$1"
    if ! is_valid_domain "$domain"; then
        printf "Error: Invalid input\n" 1>&2
        exit 1
    fi
    local password
    password="$(generate_password "$MAIL_PASSWORD_LENGTH")"
    local login_link="https://webmail.${domain}/roundcube/index.php?_user=${TEST_MAIL_LOGIN}%40${domain}"
    local new_email_created=false

    if [[ -z "$(get_mail_password "$domain")" ]]; then
        create_testmail "$domain" "$password"
        new_email_created=true
    fi

    printf '{"login_link": "%s", "password": "%s", "new_email_created": %s}\n' "$login_link" "$password" "$new_email_created"
}
