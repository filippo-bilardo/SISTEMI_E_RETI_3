#!/usr/bin/env bash
set -euo pipefail

KEEP="${1:-14}"

if ! [[ "$KEEP" =~ ^[0-9]+$ ]]; then
  echo "Uso: $0 [numero_backup_da_tenere]" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"

mkdir -p "$BACKUP_DIR"

mapfile -t files < <(ls -1t "$BACKUP_DIR"/*.dump 2>/dev/null || true)
count="${#files[@]}"

if (( count <= KEEP )); then
  echo "Nessuna rotazione: backup presenti=$count, keep=$KEEP"
  exit 0
fi

echo "Rotazione backup: presenti=$count, keep=$KEEP"

to_delete=("${files[@]:$KEEP}")
for f in "${to_delete[@]}"; do
  echo "Cancello: $f"
  rm -f -- "$f"
done

echo "OK: rotazione completata"
