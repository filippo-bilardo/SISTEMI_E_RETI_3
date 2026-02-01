#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <file.dump>" >&2
  exit 2
fi

DUMP_FILE="$1"

if [[ ! -f "$DUMP_FILE" ]]; then
  echo "ERRORE: dump non trovato: $DUMP_FILE" >&2
  exit 1
fi

: "${PGHOST:=127.0.0.1}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=poi_service}"
: "${PGUSER:=poi_app}"

echo "Ripristino $DUMP_FILE su $PGHOST:$PGPORT db=$PGDATABASE user=$PGUSER"

pg_restore \
  --host "$PGHOST" \
  --port "$PGPORT" \
  --username "$PGUSER" \
  --dbname "$PGDATABASE" \
  --clean \
  --if-exists \
  "$DUMP_FILE"

echo "OK: restore completato"
