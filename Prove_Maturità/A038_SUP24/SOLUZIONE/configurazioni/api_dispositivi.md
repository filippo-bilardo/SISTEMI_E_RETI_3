# API dispositivi remoti (HTTP) – specifica di esempio

> Supporto al **Quesito II (gestione dispositivi remoti dotati di server HTTP interno)** e alla **Prima Parte – Punto 1**.

## Premesse

- Ogni dispositivo espone un server HTTP “locale”.
- La sede accede via **VPN** e con **mTLS** (consigliato) oppure token.
- L’API deve essere idempotente ove possibile.

## Modello risorsa

- `deviceId`: identificativo univoco (es. `SEM-001`).
- `capabilities`: cosa può fare (es. `set_state`, `open`, `set_message`).

## Endpoint minimi

### GET `/api/v1/status`

**Scopo**: lettura stato.

```http
GET /api/v1/status HTTP/1.1
Host: iot-semaforo-a-01

HTTP/1.1 200 OK
Content-Type: application/json

{
  "deviceId": "SEM-001",
  "type": "traffic_light",
  "state": "green",
  "health": "ok",
  "lastCmdId": "CMD-20240715-0001",
  "ts": "2024-07-15T14:30:00Z"
}
```

### POST `/api/v1/commands`

**Scopo**: invio comando.

```http
POST /api/v1/commands HTTP/1.1
Host: iot-semaforo-a-01
Content-Type: application/json

{
  "cmdId": "CMD-20240715-0002",
  "action": "set_state",
  "params": { "state": "red", "durationSec": 300 },
  "operatorId": "OP-042",
  "reason": "Sovraffollamento zona A"
}

HTTP/1.1 202 Accepted
Content-Type: application/json

{ "accepted": true, "cmdId": "CMD-20240715-0002" }
```

### PUT `/api/v1/config`

**Scopo**: modifica configurazione (es. pannello LED).

### DELETE `/api/v1/schedules/{id}`

**Scopo**: rimuovere una schedulazione.

## Uso dei metodi HTTP (richiesta del Quesito II)

- `GET`: leggere stato/config.
- `POST`: creare un comando (operazione) e ottenerne tracking.
- `PUT`: aggiornare configurazione idempotente.
- `DELETE`: rimuovere schedule/risorsa.

## Sicurezza e audit

- mTLS obbligatorio (cert client → `deviceId`).
- Rate limit (es. 100 req/min).
- Audit log: `cmdId`, `operatorId`, `reason`, timestamp.
- Replay protection: rifiuto `cmdId` duplicati.
