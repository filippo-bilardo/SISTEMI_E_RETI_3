# Alta disponibilità (HA)

> Supporto alla **Prima Parte – Punto 4 (evitare interruzioni di servizio)**.

## Componenti critici e strategie

- Firewall: coppia HA (active/standby) con stato sincronizzato.
- Core switching: stack o MLAG con alimentazioni ridondate.
- Server applicativi: cluster di virtualizzazione con HA.
- DB: replica + failover (es. PostgreSQL primary/replica).
- Storage: RAID + snapshot + replica offsite.
- Connettività: dual WAN (fibra + 4G/5G) con failover.

## SLO e obiettivi

- Ticketing: disponibilità 99.9% (downtime max ~43 min/mese)
- Controllo IoT: 99.9%
- Videosorveglianza live: 99.5% (accetta degrado temporaneo, ma con buffer)

## Pattern consigliati

- Reverse proxy in HA (2 nodi) + healthcheck verso backend.
- Broker MQTT in HA (active/standby o cluster, se richiesto).
- NVR: storage locale ridondato + buffer edge (24h) per telecamere 4G.
