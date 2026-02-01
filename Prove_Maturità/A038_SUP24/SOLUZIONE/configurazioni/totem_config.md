# Totem informativi – configurazione tecnica (esempio)

> Supporto alla **Prima Parte – Punto 3 (tecnologie di comunicazione con totem)**.

## Connettività consigliata (ibrida)

- Centro storico: fibra/FTTH dove disponibile.
- Periferia: router 4G/5G con SIM M2M e APN privato.
- Area evento temporanea: WiFi mesh + uplink in fibra/5G.

## Stack software

- OS: Linux LTS (kiosk)
- App: WebApp in modalità kiosk (Chromium) o Electron
- Gestione remota: MDM/RMM (inventario, patching, remote view)

## Flussi rete

- Totem → API ticketing (DMZ): `HTTPS 443` (mTLS)
- Totem → PSP pagamenti: `HTTPS 443` (allowlist FQDN/IP)
- Totem → Telemetria/heartbeat: `MQTTS 8883` (opzionale)

## Hardening

- Full-disk encryption
- Secure boot (se supportato)
- Account locale disabilitato o con password random ruotata
- Solo uscita verso destinazioni necessarie (egress filtering)
- Update OTA firmati

## Dati e privacy

- Non memorizzare PAN/carte: demandare a lettore certificato PCI + PSP.
- Log applicativi minimizzati e pseudonimizzati.
