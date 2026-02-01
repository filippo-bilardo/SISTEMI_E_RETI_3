# Gestione tariffe, scelta POI e scelta lingua

> Riferimento: **Prima Parte – Punto 4**.

## Tariffe (come da testo)

- **Tariffa base**: pagine base per ogni POI.
- **Tariffa intermedia**: pagine avanzate per **3 POI scelti** + base per gli altri.
- **Tariffa piena**: avanzate per ogni POI.

## Modellazione (DB)

- Tabella `ticket` contiene `tariff_id` e `valid_date`.
- Tabella `ticket_poi_adv` contiene i 3 POI abilitati (solo per tariffa intermedia).

Regola: per un ticket `INTERMEDIA` devono esistere **esattamente 3** righe in `ticket_poi_adv` (enforced in applicazione o trigger).

## Flusso scelta 3 POI (tariffa intermedia)

1. All’InfoPoint (o sul tablet prima della visita) l’utente seleziona 3 POI.
2. Il server salva i POI in `ticket_poi_adv`.
3. Durante la fruizione, se l’utente apre una pagina avanzata:
   - se `PIENA` ⇒ sempre permesso
   - se `INTERMEDIA` ⇒ permesso solo se `poi_id` ∈ `ticket_poi_adv`
   - se `BASE` ⇒ negato (mostrare base).

## Gestione lingue

- **Base**: video in IT con sottotitoli EN + immagini con caption IT/EN.
- **Avanzata**: contenuti in 1 di 7 lingue (IT incluso).

Scelte possibili:

- `ticket.lang_pref`: lingua scelta all’inizio visita (vale per tutta la giornata), oppure
- scelta lingua per singolo POI (più flessibile, ma più complessa UX).

Implementazione suggerita:

- `lang_pref` nel ticket (default IT)
- endpoint `PUT /v1/tickets/lang` per cambiare lingua durante la giornata (se consentito)
- tabella `media` con campo `lang`.

## Enforcement lato server

- Ogni richiesta pagina calcola `effective_tariff` e `effective_lang` in base al ticket.
- Logga accesso in `access_log`.
