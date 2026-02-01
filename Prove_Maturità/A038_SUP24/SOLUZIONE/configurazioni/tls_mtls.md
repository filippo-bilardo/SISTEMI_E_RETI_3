# TLS/mTLS – linee guida operative

> Supporto alla sicurezza in **Prima Parte – Punto 1/3/4** e **Quesito II**.

## Perché mTLS

- Totem e dispositivi IoT sono “endpoint non umani”: l’identità migliore è un certificato client.
- Riduce rischio di credenziali riutilizzate/esfiltrate.

## Raccomandazioni

- CA interna dedicata per IoT/totem.
- Certificati client con scadenza breve (es. 90 giorni) e rotazione automatica.
- Revoca immediata (CRL/OCSP) per dispositivi compromessi.

## Checklist configurazione

- Reverse proxy in DMZ verifica cert client
- Mapping cert → `device_id`
- RBAC: un device può agire solo sulle proprie risorse
- Audit log: ogni comando con `operator_id`, `reason`, timestamp
