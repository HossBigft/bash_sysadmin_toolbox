#!/bin/bash
set -o errexit  # Abort on nonzero exit status
set -o nounset  # Abort on unbound variable
set -o pipefail # Don't hide errors within pipes

main() {
    curl -s http://localhost:8000/api/v1/plesk/publickey >public_key.pem
}
main
