# Logging e audit (comandi e validazioni)

> Supporto alla **Prima Parte – Punto 4 (continuità e gestione incidenti)** e al **Quesito II**.

## Cosa loggare

- Validazioni biglietti: esito, gate, deviceId, operatore.
- Comandi IoT: cmdId, operatorId, reason, target device, esito.
- Accessi API: token subject, IP, user-agent.
- Eventi sicurezza: auth fallite, rate-limit, cert revocati.

## Dove

- Centralizzare su syslog/ELK/Opensearch.
- Retention:
  - Log operativi: 30-90 giorni
  - Audit: 180+ giorni (secondo policy)

## Correlazione

- Usare `X-Request-Id` e `cmdId` per ricostruire la catena di eventi.
