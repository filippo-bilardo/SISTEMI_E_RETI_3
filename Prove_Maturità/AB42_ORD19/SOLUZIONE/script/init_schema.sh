#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_FILE="$SCRIPT_DIR/../codice/schema.sql"

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "ERRORE: schema non trovato: $SCHEMA_FILE" >&2
  exit 1
fi

: "${PGHOST:=127.0.0.1}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=poi_service}"
: "${PGUSER:=poi_app}"

echo "Applico schema su $PGHOST:$PGPORT db=$PGDATABASE user=$PGUSER"

psql \
  --host "$PGHOST" \
  --port "$PGPORT" \
  --username "$PGUSER" \
  --dbname "$PGDATABASE" \
  --set ON_ERROR_STOP=on \
  --file "$SCHEMA_FILE"

echo "OK: schema applicato"
