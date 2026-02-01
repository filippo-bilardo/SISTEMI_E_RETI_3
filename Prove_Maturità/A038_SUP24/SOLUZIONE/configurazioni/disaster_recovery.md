# Disaster Recovery (DR)

> Supporto alla **Prima Parte – Punto 4**.

## Scenari

- Guasto singolo server/app: HA automatico.
- Guasto storage: restore snapshot + replica.
- Guasto sede (incendio/allagamento): attivazione sito secondario o cloud.

## RTO/RPO (esempio)

| Servizio | RTO | RPO |
|---------|-----|-----|
| Ticketing DB | 30 min | 15 min |
| API ticketing | 30 min | 0 |
| IoT control | 30 min | 0-5 min |
| Archivio video | 4 h | 1 h |

## Runbook sintetico

1. Dichiarazione incidente (responsabile turno).
2. Attivazione canale emergenza (telefono + chat).
3. Switch DNS/Reverse proxy verso sito DR.
4. Ripristino DB da replica/snapshot.
5. Verifica funzionale: validate ticket, comandi IoT, live stream.
6. Comunicazione chiusura incidente.
