# Reverse proxy / API Gateway (DMZ) – esempio di criterio

> Supporto alla **Prima Parte – Punto 1** e al **Quesito II**.

## Perché

- Centralizzare autenticazione, WAF, rate-limit e logging.
- Non esporre direttamente i server interni.

## Regole tipiche

- Termina TLS in DMZ.
- Verifica mTLS per totem e dispositivi.
- Inserisce header di tracciamento (`X-Request-Id`).
- Limita metodi HTTP ammessi per path.

## Esempio policy

- `/ticketing/*`: solo `GET/POST`, rate-limit per IP/device.
- `/iot/*`: solo `GET/POST/PUT/DELETE`, obbligo header `X-Operator-Id` per azioni.
- Blocca payload > 1MB.
