# API Validazione biglietti (REST) – specifica di esempio

> Supporto alla **Prima Parte – Punto 2 (validazione ingressi)**.

## Requisiti

- Autenticazione: OAuth2/OIDC oppure JWT firmato dal server (scadenza breve).
- Autorizzazione: RBAC (es. `ROLE_STAFF`, `ROLE_SUPERVISOR`).
- Audit: log di validazione (who/when/where).

## Endpoint

### POST `/v1/tickets/validate`

**Scopo**: validare un biglietto (QR/Barcode).

Request:

```http
POST /v1/tickets/validate HTTP/1.1
Host: api.sede.example
Authorization: Bearer <JWT>
Content-Type: application/json

{
  "eventId": "EVT-2024-07-15",
  "gateId": "GATE-A-01",
  "ticketCode": "QR:ABCD-1234-XYZ",
  "deviceId": "MOB-OP-042"
}
```

Response (valido):

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "result": "VALID",
  "ticketId": "TCK-00112233",
  "holder": {
    "displayName": "Rossi M.",
    "type": "STANDARD"
  },
  "validatedAt": "2024-07-15T14:30:01Z"
}
```

Response (già usato):

```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "result": "INVALID",
  "reason": "ALREADY_USED",
  "usedAt": "2024-07-15T14:10:00Z",
  "gateId": "GATE-A-02"
}
```

Response (non valido):

```http
HTTP/1.1 422 Unprocessable Entity
Content-Type: application/json

{
  "result": "INVALID",
  "reason": "NOT_FOUND"
}
```

## Offline fallback

### GET `/v1/tickets/offline-pack?eventId=...&gateId=...`

- Restituisce un pacchetto firmato (lista o bloom filter + firma) per validare offline.

### POST `/v1/tickets/sync`

- Invia la coda di validazioni avvenute offline.

## Misure anti-frode

- Token device-bound (legato a MDM/attestazione device).
- Rate limit per `deviceId`.
- QR con firma (JWS) per evitare generazione fraudolenta.
