#!/usr/bin/env bash
set -euo pipefail

# Esempio minimale di controllo dispositivi via HTTP API
# Uso: ./controllo_dispositivi.sh https://iot-semaforo-a-01

BASE_URL="${1:?Uso: $0 <base_url>}"
TOKEN="${TOKEN:-}"

hdr_auth=()
if [[ -n "$TOKEN" ]]; then
  hdr_auth=(-H "Authorization: Bearer $TOKEN")
fi

echo "[+] STATUS"
curl -fsS "${hdr_auth[@]}" "$BASE_URL/api/v1/status" | jq .

echo "[+] SET RED (300s)"
curl -fsS "${hdr_auth[@]}" \
  -H 'Content-Type: application/json' \
  -d '{"cmdId":"CMD-demo-0001","action":"set_state","params":{"state":"red","durationSec":300},"operatorId":"OP-042","reason":"Test"}' \
  "$BASE_URL/api/v1/commands" | jq .
