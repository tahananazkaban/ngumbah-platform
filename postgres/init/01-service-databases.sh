#!/bin/sh
# Creates one database and one login role per service; runs only on an empty data volume.
set -eu

# Service roles may only connect to their own database
psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c 'REVOKE CONNECT ON DATABASE postgres FROM PUBLIC;'

for svc in $NGUMBAH_SERVICES; do
  role="${svc}_svc"
  db="${svc}_db"
  pw_var="$(echo "$role" | tr '[:lower:]' '[:upper:]')_DB_PASSWORD"
  pw="$(eval "printf '%s' \"\${$pw_var:-}\"")"
  if [ -z "$pw" ]; then
    echo "missing $pw_var for service '$svc'" >&2
    exit 1
  fi

  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres \
    -v role="$role" -v db="$db" -v pw="$pw" <<'SQL'
CREATE ROLE :"role" LOGIN PASSWORD :'pw';
CREATE DATABASE :"db" OWNER :"role";
REVOKE CONNECT ON DATABASE :"db" FROM PUBLIC;
GRANT CONNECT ON DATABASE :"db" TO :"role";
SQL

  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$db" -v role="$role" <<'SQL'
ALTER SCHEMA public OWNER TO :"role";
SQL

  echo "created $db owned by $role"
done
