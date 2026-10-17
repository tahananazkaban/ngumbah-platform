#!/bin/sh
# Starts, stops and inspects the infra compose profile.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
load_env

case "${1:-}" in
  up)
    # --wait blocks until every health check passes
    compose up --detach --wait
    ok "infrastructure is up and healthy; run make infra-check to verify"
    ;;
  down)
    compose_all down
    ok "infrastructure stopped, data kept"
    ;;
  status)
    compose_all ps
    echo
    ids="$(compose_all ps --quiet)"
    if [ -n "$ids" ]; then
      # shellcheck disable=SC2086
      docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' $ids
    fi
    ;;
  *)
    echo "usage: $0 up|down|status" >&2
    exit 2
    ;;
esac
