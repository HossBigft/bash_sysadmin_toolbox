#!/usr/bin/env bash
set -o errexit  # Exit on error
set -o nounset  # Treat unset variables as errors
set -o pipefail # Fail pipeline if any command fails

is_mysql_installed() {
    if ! mysql --version &>/dev/null; then
        return 1
    fi
    return 0
}
