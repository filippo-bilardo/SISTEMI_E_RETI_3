# Accesso solo da tablet forniti (vincolo di progetto)

> Riferimento: vincoli progettuali ("consultazione abilitata esclusivamente ai dispositivi (minitablet) forniti...").

## Soluzione proposta (robusta)

1. **MDM** (Mobile Device Management)
   - Enrollment obbligatorio dei tablet.
   - Blocco installazione app non autorizzate.
   - Remote wipe.

2. **WiFi WPA2/WPA3-Enterprise** con **802.1X (EAP-TLS)**
   - Ogni tablet ha un certificato client.
   - RADIUS valida il certificato e assegna VLAN (anche per-POI).

3. **mTLS / device attestation** lato applicazione
   - Reverse proxy accetta richieste solo con certificato client valido.
   - Mapping `cert_fingerprint` → `device_id` (tabella `device`).

4. **Token applicativo** (password del biglietto)
   - Dopo l’inserimento password, server rilascia token giornaliero.

## Misure “minime” (se si vuole semplificare)

- MAC whitelist + captive portal
  - Più semplice, ma meno sicuro (MAC spoofing).

## Motivazione

- L’unione di 802.1X + MDM riduce significativamente l’uso di device non autorizzati.
