# Soluzione completa – AB42_ORD19 (Seconda prova 2019)

Riferimento: traccia in `../AB42_ORD19.md`.

Scelta quesiti seconda parte: **Quesito I** (feedback + media voti) e **Quesito IV** (accesso remoto/VPN).

## Mappa dei contenuti (allegati)

- Diagrammi:
  - `diagrammi/schema_rete_servizio.md` (architettura rete/servizi)
  - `diagrammi/sequence_accesso_poi.md` (flusso accesso con password + rete)
  - `diagrammi/er_poi.mmd` (ER concettuale)
- Configurazioni:
  - `configurazioni/piano_indirizzamento.md`
  - `configurazioni/vlan_config.md`
  - `configurazioni/firewall_policy.md`
  - `configurazioni/accesso_tablet_sicurezza.md`
  - `configurazioni/tariffe_lingue.md`
  - `configurazioni/accesso_remoto_vpn.md` (Quesito IV)
- DB e codice:
  - `codice/schema.sql` (modello logico SQL)
  - `codice/db_notes.md`
  - `codice/config.php`
  - `codice/poi_base.php` (punto 3, porzione significativa)
  - `codice/ratings_avg.php` (Quesito I)
- Operatività:
  - `script/README.md` + script DB

---

## Analisi della realtà e ipotesi

La traccia richiede un servizio cittadino con: InfoPoint (chioschi), tablet consegnati al visitatore, contenuti su server, accesso tramite password giornaliera e vincolo di fruizione vicino/al POI.

Ipotesi aggiuntive (coerenti con la traccia):

- Esiste un CED comunale (o locale tecnico centralizzato) dove collocare i server principali e l’accesso Internet.
- Ogni POI ha copertura Wi‑Fi dedicata (AP) e backhaul verso il CED (fibra/ponte radio); per musei/mostre indoor si privilegia cablaggio.
- I contenuti multimediali (video/immagini) sono serviti via HTTPS da un web server; il DB centralizzato gestisce ticket e autorizzazioni.
- I tablet sono gestiti da MDM (inventario, blocchi, wipe) e dispongono di certificato client (per 802.1X e opzionale mTLS).

---

## Punto 1 – Infrastruttura tecnologica

### 1a) Architettura rete e sistemi server (motivazione e collocazione)

Richiesta: “progetto … architettura della rete e caratteristiche del/dei sistemi server … motivando luoghi”.

Soluzione proposta:

- Server in CED (centralizzati):
  - Web/App tier (DMZ o segmento applicativo): erogazione pagine, API, autenticazione ticket.
  - DB PostgreSQL (segmento interno): ticket, tariffe, scelte POI, log, feedback.
  - Object storage/NAS (segmento interno): video e immagini (o storage su server web con replica).
  - AAA/RADIUS + PKI (segmento infrastruttura): 802.1X EAP‑TLS e gestione certificati.
  - MDM (segmento management): policy tablet e provisioning.

Motivazione collocazione:

- Centralizzare i server nel CED semplifica: backup, patching, monitoraggio, sicurezza fisica e logica.
- I POI ospitano solo AP/switch (e opzionali beacon BLE) riducendo manutenzione e superfici d’attacco.

Diagramma di riferimento: `diagrammi/schema_rete_servizio.md`.

Piano IP e VLAN: `configurazioni/piano_indirizzamento.md` e `configurazioni/vlan_config.md`.

### 1b) Comunicazione server ↔ dispositivi (protocolli e servizi software)

Richiesta: “modalità di comunicazione … descrivendo protocolli e servizi software … per gestire la rete e fornire pagine”.

Canali e protocolli:

- Tablet ↔ rete Wi‑Fi: WPA2/3‑Enterprise con 802.1X (EAP‑TLS) per ammettere **solo** tablet gestiti.
- Tablet ↔ server: HTTPS (TLS) per pagine e API; opzionale mTLS per ulteriore binding “solo tablet”.
- Logging/audit: inserimento eventi in DB (tabella `access_log`) e/o log centralizzati.

Servizi software chiave:

- RADIUS/AAA: autentica i tablet (certificato) e assegna VLAN/ACL.
- Web server/app (es. Nginx+PHP-FPM o Apache+PHP): serve pagine base/avanzate e applica regole tariffarie.
- DB PostgreSQL: autorizzazioni per tariffa, lingua, scelte “3 POI” per intermedia.

Documento di riferimento (tablet-only + autenticazione): `configurazioni/accesso_tablet_sicurezza.md`.

### 1c) Limitare fruizione solo in prossimità/interno POI

Richiesta: “elementi dell’infrastruttura utili a limitare la fruizione … in prossimità o all’interno dei POI”.

Soluzione (approccio “rete come prova di prossimità”):

- SSID e/o VLAN per‑POI (o gruppo di POI vicini) con routing controllato.
- Policy sul server: associazione “subnet/VLAN → poi_id” e permesso di accesso alle pagine del POI solo se la richiesta proviene dalla rete del POI.

Alternative/rafforzamenti (opzionali):

- Beacon BLE o geofencing (se i tablet lo supportano) per verifica aggiuntiva indoor.
- Captive portal “di POI” con token a breve durata rilasciato solo da AP/edge del POI.

Policy firewall correlata: `configurazioni/firewall_policy.md`.

---

## Punto 2 – Progetto base dati (concettuale + logico)

Richiesta: “modello concettuale ed il corrispondente modello logico”.

- Modello concettuale (ER): `diagrammi/er_poi.mmd`
- Modello logico (PostgreSQL SQL DDL): `codice/schema.sql`

Aspetti coperti nello schema:

- POI e media associati (video/immagini, lingua)
- Ticket con password, tariffa, data validità, lingua preferita
- Selezione 3 POI per tariffa intermedia (relazione dedicata)
- Device (tablet) e assegnazione/reso presso InfoPoint
- Log accessi (audit)
- Integrazione feedback/voti (Quesito I)

Note implementative: `codice/db_notes.md`.

---

## Punto 3 – Progettazione pagina web (tariffa base) + codice significativo

Richiesta: “pagine web … tariffa base … fruizione contenuti relativi al POI presso cui si trova … codificandone una porzione significativa”.

Scelte:

- Pagina “base” mostra:
  - video breve (IT + sottotitoli EN come risorsa media)
  - massimo 3 immagini con didascalia IT/EN
- Controlli lato server:
  - verifica ticket (password/identificativo) e validità giornaliera
  - verifica dispositivo “ammesso” (a livello rete e/o mTLS)
  - verifica prossimità POI (rete del POI)

Porzione codificata (PHP): `codice/poi_base.php`.

Config DB (placeholder): `codice/config.php`.

---

## Punto 4 – Tariffe, scelta 3 POI (intermedia), scelta lingua (intermedia/piena)

Richiesta: “analisi di massima … tre fasce tariffarie … opzioni per scelta 3 POI … scelta lingua”.

Documento dedicato: `configurazioni/tariffe_lingue.md`.

Sintesi regole:

- Base: solo pagine base per tutti i POI.
- Intermedia: avanzata solo per 3 POI salvati sul server, base per gli altri.
- Piena: avanzata per tutti.
- Lingua: 1 tra 7 (IT incluso) per contenuti avanzati; `lang_pref` a livello ticket o scelta per sessione.

---

## Seconda parte – Quesito I (commento + voto + media voti)

Richiesta: “integrazione DB … pagina web per visualizzare media voti per ciascun POI”.

- Integrazione DB: tabella `feedback` e vista `poi_rating_avg` in `codice/schema.sql`.
- Pagina web (PHP) di visualizzazione medie: `codice/ratings_avg.php`.

---

## Seconda parte – Quesito IV (accesso remoto e VPN)

Richiesta: “tipologie e protocolli accesso remoto … possibilità VPN … esempio 2 sedi + agenti commerciali”.

Documento dedicato: `configurazioni/accesso_remoto_vpn.md`.

---

## Operatività (backup/restore schema DB)

Script: `script/README.md`.

Obiettivo: garantire ripristino rapido (es. fine giornata) e conservazione backup secondo policy.
