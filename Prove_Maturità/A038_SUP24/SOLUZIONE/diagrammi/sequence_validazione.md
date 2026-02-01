# Sequenza: validazione biglietto (QR)

> Usare per la **Prima Parte – Punto 2 (validazione biglietti)**.

```mermaid
sequenceDiagram
  autonumber
  actor Addetto as Addetto in loco
  participant App as App Mobile
  participant API as API Ticketing (sede)
  participant DB as DB Ticketing

  Addetto->>App: Scansione QR/Barcode
  App->>API: POST /v1/tickets/validate (token)
  API->>DB: SELECT ticket + stato
  DB-->>API: Dati biglietto + policy
  alt Biglietto valido e non usato
    API->>DB: UPDATE ticket = USED + timestamp
    DB-->>API: OK
    API-->>App: 200 VALID + dettagli
    App-->>Addetto: Schermata verde + beep
  else Non valido / già usato / evento errato
    API-->>App: 409/422 INVALID + motivo
    App-->>Addetto: Schermata rossa + motivo
  end
```

## Variante: modalità offline (fallback)

- L’app conserva una **cache firmata** di ticket attesi per quel varco/slot.
- Se rete assente, valida localmente la firma e registra in coda.
- Alla riconnessione, invia `POST /v1/tickets/sync` con gli eventi di uso.
