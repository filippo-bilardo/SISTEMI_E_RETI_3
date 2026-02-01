# Monitoring (Zabbix) – cosa monitorare e soglie

> Supporto alla **Prima Parte – Punto 4**.

## Obiettivi

- Rilevare guasti prima dell’utente (proattivo).
- Correlare eventi (rete, applicazioni, dispositivi).

## Target

- Firewall/router: WAN up/down, CPU, sessioni, IPS events.
- Switch: link down, STP changes, errori CRC.
- Server: CPU/RAM/disk, servizi (HTTP/DB/MQTT).
- VPN: peer up/down, handshake age.
- Telecamere: reachability, bitrate, storage NVR.
- Totem: heartbeat, stato kiosk, stampante, lettore pagamenti.

## Soglie esempio

- WAN packet loss > 2% per 5 min ⇒ Warning
- VPN peer down > 60s ⇒ Critical
- Storage NVR > 85% ⇒ Warning; > 95% ⇒ Critical
- API error rate > 2% per 5 min ⇒ Critical

## Alerting

- Warning: email
- Critical: SMS/telefonata (gateway)
- Escalation: 15 min senza ack ⇒ responsabile
