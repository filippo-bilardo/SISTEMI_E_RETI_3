#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

: "${PGHOST:=127.0.0.1}"
: "${PGPORT:=5432}"
: "${PGDATABASE:=poi_service}"
: "${PGUSER:=poi_app}"

mkdir -p "$BACKUP_DIR"

TS="$(date +%F_%H%M%S)"
OUT="$BACKUP_DIR/${PGDATABASE}_${TS}.dump"

echo "Backup DB $PGDATABASE -> $OUT"

pg_dump \
  --host "$PGHOST" \
  --port "$PGPORT" \
  --username "$PGUSER" \
  --format=custom \
  --file "$OUT" \
  --dbname "$PGDATABASE"

echo "OK: backup creato: $OUT"
