# NVR / VMS – configurazione e storage

> Supporto al **Quesito I (salvataggio filmati/immagini)** e alla **Prima Parte – Punto 1**.

## Scelte progettuali

- VMS centralizzato in sede per accesso rapido.
- Storage locale (NAS/RAID) per retention breve.
- Replica/archivio su cloud per retention lunga o DR.

## Parametri tipici

- Codec: H.265
- FPS: 15 (adeguato per monitoraggio flussi)
- Bitrate target: 3–6 Mbps per cam 4K (dipende scena)
- Retention locale: 7–14 giorni
- Archivio: 30+ giorni su cloud (tiering)

## On-prem vs cloud (linee guida)

- On-prem: latenza minima, costo prevedibile, ma investimento iniziale.
- Cloud: scalabilità e geo-ridondanza, ma costo banda e compliance.

## Approccio ibrido (raccomandato)

- Live + ultime 1-2 settimane in sede.
- Sync/archiviazione notturna su cloud.
