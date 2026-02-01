# Note DB (modello concettuale → logico)

> Riferimento: **Prima Parte – Punto 2**.

## Modello concettuale (sintesi)

Entità principali:

- POI, Media
- Visitor, Ticket, Tariff
- Device (tablet), InfoPoint, Rental
- Ticket_POI_ADV (selezione 3 POI avanzati)
- Access_log (audit)
- Feedback (Quesito I)

Diagramma ER: `diagrammi/er_poi.mmd`.

## Scelte progettuali

- Password del biglietto: memorizzata come `password_hash` (mai in chiaro).
- Validità giornaliera: `valid_date`.
- Per tariffa intermedia: tabella `ticket_poi_adv` limita a 3 righe per ticket (enforced in logica applicativa o constraint/trigger).
- Audit: `access_log` permette verifiche e incident response.
