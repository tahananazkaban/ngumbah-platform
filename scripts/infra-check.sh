#!/bin/sh
# Verifies running infrastructure from the outside; exits non-zero on any failure.
set -u
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
load_env

failures=0
pass() { ok "$*"; }
bad()  { fail "$*"; failures=$((failures + 1)); }

endpoint="http://localhost:${FLOCI_PORT}"

# Floci
if curl -fsS "$endpoint/_localstack/health" >/dev/null 2>&1; then
  pass "floci: endpoint answers on $endpoint"
else
  bad "floci: no answer on $endpoint"
fi

# S3 round trip through the AWS CLI with dummy credentials
if command -v aws >/dev/null 2>&1; then
  bucket="ngumbah-infra-check-$$"
  if aws --endpoint-url "$endpoint" s3api create-bucket --bucket "$bucket" >/dev/null 2>&1 \
    && aws --endpoint-url "$endpoint" s3api list-buckets --query 'Buckets[].Name' --output text | grep -q "$bucket" \
    && aws --endpoint-url "$endpoint" s3api delete-bucket --bucket "$bucket" >/dev/null 2>&1; then
    pass "floci: s3 create/list/delete works"
  else
    bad "floci: s3 round trip failed"
  fi
else
  bad "floci: aws cli not installed, cannot test s3 (run make doctor)"
fi

# Postgres
if compose exec -T postgres pg_isready -U "$POSTGRES_USER" -d postgres >/dev/null 2>&1; then
  pass "postgres: accepting connections"
else
  bad "postgres: not ready"
fi

# psql_as <role> <password> <database>; uses the container hostname so password auth applies
psql_as() {
  compose exec -T -e PGPASSWORD="$2" postgres \
    psql -h postgres -U "$1" -d "$3" -tAc 'select 1' 2>&1
}

first_role=""; first_pw=""
for svc in $NGUMBAH_SERVICES; do
  role="${svc}_svc"; db="${svc}_db"
  pw_var="$(echo "$role" | tr '[:lower:]' '[:upper:]')_DB_PASSWORD"
  pw="$(eval "printf '%s' \"\${$pw_var:-}\"")"
  if [ "$(psql_as "$role" "$pw" "$db")" = 1 ]; then
    pass "postgres: $role connects to $db"
  else
    bad "postgres: $role cannot connect to $db"
  fi
  [ -z "$first_role" ] && first_role="$role" && first_pw="$pw"
done

# Isolation: the first service role must be refused on every other service database
for svc in $NGUMBAH_SERVICES; do
  db="${svc}_db"
  [ "${svc}_svc" = "$first_role" ] && continue
  out="$(psql_as "$first_role" "$first_pw" "$db")"
  if printf '%s' "$out" | grep -q 'permission denied'; then
    pass "postgres: $first_role refused on $db"
  else
    bad "postgres: $first_role NOT refused on $db ($out)"
  fi
done

# Valkey
if [ "$(compose exec -T valkey valkey-cli ping 2>/dev/null | tr -d '\r')" = PONG ]; then
  pass "valkey: answers ping"
else
  bad "valkey: no answer to ping"
fi

echo
if [ $failures -ne 0 ]; then
  fail "infra-check: $failures check(s) failed"
  exit 1
fi
ok "infra-check: all checks passed"
