#!/bin/sh
# Stops infrastructure and deletes its volumes after explicit confirmation.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
load_env

if [ "${FORCE:-0}" != 1 ]; then
  printf 'This deletes ALL Floci, Postgres and Valkey data. Type "yes" to continue: '
  read -r answer
  if [ "$answer" != yes ]; then
    info "aborted, nothing deleted"
    exit 0
  fi
fi

compose_all down --volumes --remove-orphans
ok "infrastructure stopped and volumes deleted; run make infra-up for a clean start"
