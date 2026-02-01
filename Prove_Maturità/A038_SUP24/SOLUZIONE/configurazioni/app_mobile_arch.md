# App mobile personale in loco – architettura e requisiti

> Supporto alla **Prima Parte – Punto 2 (comunicazione + validazione)**.

## Funzioni richieste

- Validazione biglietti (QR/Barcode; opzionale NFC)
- Ricezione alert in tempo reale (push)
- Chat/Voce (PTT) per coordinamento
- Stato dispositivi (dashboard sintetica)

## Connettività

- Preferibile: rete 4G/5G (SIM M2M o aziendale)
- Alternativa: WiFi dedicato nell’area evento
- Sicurezza: HTTPS + token; opzionale VPN per funzioni “sensibili”

## Gestione dispositivi (MDM)

- Enroll obbligatorio (Android Enterprise / iOS MDM)
- PIN/biometria obbligatori
- Cifratura storage abilitata
- Remote wipe

## Modalità offline (fallback)

- Cache ticket “ammessi” per varco/slot firmata dal server
- Queue locale eventi di validazione
- Sync quando rete torna disponibile
