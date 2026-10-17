#!/bin/sh
# Builds and runs service containers (core profile) on top of the infrastructure; each image ships a health subcommand.
set -eu
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
load_env

core_services="tenant-svc gateway"

case "${1:-}" in
  up)
    for svc in $core_services; do
      if [ ! -d "$WORKSPACE_DIR/ngumbah-$svc" ]; then
        fail "ngumbah-$svc is not cloned next to ngumbah-platform; run make bootstrap"
        exit 1
      fi
    done
    compose_all up --detach --build --wait
    # Seeding is idempotent, so it is safe on every start
    compose_all exec -T tenant-svc /tenant-svc seed >/dev/null
    ok "core services are up, healthy and seeded; run make core-check to verify"
    ;;
  down)
    # shellcheck disable=SC2086
    compose_all stop $core_services
    ok "core services stopped; infrastructure keeps running"
    ;;
  check)
    failures=0
    for svc in $core_services; do
      if compose_all exec -T "$svc" "/$svc" health >/dev/null 2>&1; then
        ok "$svc: healthy"
      else
        fail "$svc: not healthy"
        failures=$((failures + 1))
      fi
    done
    [ "$failures" -eq 0 ] || exit 1
    ;;
  *)
    echo "usage: $0 up|down|check" >&2
    exit 2
    ;;
esac
