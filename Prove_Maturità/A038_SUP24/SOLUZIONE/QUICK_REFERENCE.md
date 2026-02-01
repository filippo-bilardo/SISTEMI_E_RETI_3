# Quick Reference – Operazioni e sicurezza (evento)

## Comandi utili

### Rete (Linux)

- IP e route: `ip a`, `ip r`
- DNS test: `dig <nome>`, `nslookup <nome>`
- Connessioni e porte: `ss -tulpn`, `lsof -i -P -n | head`
- Traceroute: `traceroute <ip>`, `mtr <ip>`
- Test HTTP: `curl -vk https://api.sede.example/health`

### WireGuard

- Stato: `wg show`
- Avvio: `systemctl start wg-quick@wg0`
- Log: `journalctl -u wg-quick@wg0 -n 200 --no-pager`

### Mosquitto (MQTT)

- Stato: `systemctl status mosquitto`
- Log: `journalctl -u mosquitto -n 200 --no-pager`

### Ticketing API / Dispositivi

- Validazione (esempio):
  - `curl -sS -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"eventId":"EVT-...","gateId":"GATE-A-01","ticketCode":"QR:...","deviceId":"MOB-..."}' https://api.sede.example/v1/tickets/validate`
- Stato dispositivo: `curl -sS https://iot-semaforo-a-01/api/v1/status | jq .`

## Checklist pre-produzione (T-7 → T-0)

- Connettività sede: doppia WAN attiva e test failover.
- VPN: peer remoti registrati; test handshake; policy firewall applicate.
- TLS/mTLS: certificati validi, non in scadenza (>= 7 giorni).
- Totem: aggiornati, kiosk mode, stampante e pagamenti testati.
- App mobile: MDM attivo, PIN/biometria, test offline pack.
- NVR/VMS: storage libero, registrazione attiva, retention configurata.
- Monitoring: Zabbix con alert e escalation, contatti on-call.
- Backup: test restore (almeno DB e config).
- Runbook DR: reperibile e condiviso.

## Porte pubbliche esposte (minimo indispensabile)

- `443/TCP` (HTTPS) verso reverse proxy/API in DMZ
- `51820/UDP` (WireGuard) solo da IP/APN consentiti

Consigliato NON esporre:
- MQTT `8883/TCP` su Internet (solo su VPN)
- RTSP `554/TCP` su Internet (solo su VPN)

## Policy password e accessi

- Account umani: password min 14 char, blocco dopo 5 tentativi, MFA obbligatorio.
- Account servizio: credenziali in vault, rotazione ogni 90 giorni.
- Dispositivi (totem/IoT): preferire mTLS; se password, random 24+ char.
- Accesso admin solo via bastion; niente SSH diretto da Internet.

## Contatti emergenza (placeholder)

- Responsabile infrastruttura (on-call): NOME / TEL
- Responsabile sicurezza (on-call): NOME / TEL
- Reperibilità vendor connettività: NOME / TEL
- Forze dell’ordine / 112: emergenza

## File importanti

- Diagramma rete: `SOLUZIONE/diagrammi/schema_rete_sede.md`
- Piano IP: `SOLUZIONE/configurazioni/piano_indirizzamento.md`
- VLAN: `SOLUZIONE/configurazioni/vlan_config.md`
- Firewall policy: `SOLUZIONE/configurazioni/firewall_policy.md`
- VPN: `SOLUZIONE/configurazioni/vpn_config.md`
- MQTT: `SOLUZIONE/configurazioni/mqtt_config.md`
- API validazione: `SOLUZIONE/configurazioni/api_validazione.md`
- API dispositivi: `SOLUZIONE/configurazioni/api_dispositivi.md`
- HA/DR: `SOLUZIONE/configurazioni/high_availability.md`, `SOLUZIONE/configurazioni/disaster_recovery.md`
- Monitoring: `SOLUZIONE/configurazioni/monitoring.md`
- Script: `SOLUZIONE/script/`
