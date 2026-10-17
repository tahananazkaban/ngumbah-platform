#!/bin/sh
# Shared helpers sourced by the other scripts.

PLATFORM_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck disable=SC2034 # used by scripts that source this file
WORKSPACE_DIR="$(dirname "$PLATFORM_DIR")"

if [ -t 1 ]; then
  C_GREEN="$(printf '\033[32m')"; C_RED="$(printf '\033[31m')"
  C_YELLOW="$(printf '\033[33m')"; C_RESET="$(printf '\033[0m')"
else
  C_GREEN=""; C_RED=""; C_YELLOW=""; C_RESET=""
fi

ok()   { printf '%s[ ok ]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
fail() { printf '%s[fail]%s %s\n' "$C_RED" "$C_RESET" "$*"; }
warn() { printf '%s[warn]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
info() { printf '[info] %s\n' "$*"; }

# Creates .env from the example on first use, then exports every variable in it
load_env() {
  if [ ! -f "$PLATFORM_DIR/.env" ]; then
    cp "$PLATFORM_DIR/.env.example" "$PLATFORM_DIR/.env"
    info "created .env from .env.example"
  fi
  set -a
  # shellcheck disable=SC1091
  . "$PLATFORM_DIR/.env"
  set +a
}

# Prints repository names from repos.txt, skipping comments and blank lines
list_repos() {
  grep -v '^[[:space:]]*#' "$PLATFORM_DIR/repos.txt" | grep -v '^[[:space:]]*$'
}

compose() {
  docker compose --project-directory "$PLATFORM_DIR" --profile infra "$@"
}

# Includes services that depend on infra, so stopping never leaves them orphaned
compose_all() {
  docker compose --project-directory "$PLATFORM_DIR" --profile infra --profile core "$@"
}

# Returns success when version $1 >= version $2 (dotted numbers only)
version_ge() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    n = split(a, x, "."); m = split(b, y, ".");
    for (i = 1; i <= (n > m ? n : m); i++) {
      if ((x[i] + 0) > (y[i] + 0)) exit 0;
      if ((x[i] + 0) < (y[i] + 0)) exit 1;
    }
    exit 0
  }'
}
