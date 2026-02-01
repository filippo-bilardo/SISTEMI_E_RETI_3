# Policy firewall (alto livello)

> Riferimento: **Prima Parte – Punto 1.b/1.c** (servizi e vincoli di accesso).

## Porte pubbliche minime

- `443/TCP` (HTTPS) verso WAF/reverse proxy in DMZ.

## Flussi interni consentiti

- DMZ → APP: `443/TCP`
- APP → DB: `5432/TCP` (PostgreSQL)
- APP → MEDIA: `443/TCP` (S3 compatibile) o `2049/TCP` (NFS) se NAS
- AP/Controller → RADIUS: `1812/UDP` + `1813/UDP`
- Apparati → Monitoring: `161/UDP` (SNMP) + syslog `514/UDP`/`6514/TCP`

## Vincoli di progetto (enforcement)

- Bloccare richieste alle pagine POI se:
  - device non è autenticato (manca token), oppure
  - device non è un tablet gestito (manca certificato/attestazione), oppure
  - source network non corrisponde al POI (VLAN/SSID mismatch).

## Egress filtering

- Tablet/POI VLAN → Internet: negato, salvo update/CRL/OCSP e servizi strettamente necessari.
