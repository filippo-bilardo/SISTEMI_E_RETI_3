#!/usr/bin/env bash
set -euo pipefail

# Backup semplificato (esempio): DB ticketing + configurazioni + log audit
# Uso: ./backup_script.sh /backup/target

TARGET_DIR="${1:-/var/backups/evento}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p "$TARGET_DIR"/"$TS"

# 1) Dump DB (placeholder: adattare a host/utente)
# Richiede: pg_dump in PATH e variabili d'ambiente (PGHOST/PGUSER/PGPASSWORD)
if command -v pg_dump >/dev/null 2>&1; then
  echo "[+] DB dump..."
  pg_dump -Fc "${PGDATABASE:-ticketing}" > "$TARGET_DIR/$TS/ticketing.dump"
else
  echo "[!] pg_dump non trovato: salto dump DB"
fi

# 2) Backup configurazioni (cartella soluzione)
echo "[+] Backup configurazioni..."
cp -a "$(dirname "$0")/../configurazioni" "$TARGET_DIR/$TS/" || true
cp -a "$(dirname "$0")/../diagrammi" "$TARGET_DIR/$TS/" || true

# 3) Log audit (placeholder)
AUDIT_SRC="/var/log/evento-audit"
if [[ -d "$AUDIT_SRC" ]]; then
  echo "[+] Backup audit logs..."
  tar -czf "$TARGET_DIR/$TS/audit_logs.tgz" -C "$AUDIT_SRC" .
fi

# 4) Hash integrità
echo "[+] Genero SHA256SUMS..."
( cd "$TARGET_DIR/$TS" && sha256sum * 2>/dev/null > SHA256SUMS || true )

echo "[OK] Backup completato in $TARGET_DIR/$TS"
