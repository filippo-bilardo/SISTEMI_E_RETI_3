# Quick reference – AB42_ORD19

## Obiettivo (in 10 secondi)

Servizio turistico per POI con pagine web (base/avanzate) fruibili **solo** da minitablet forniti agli InfoPoint, con accesso tramite **password su biglietto** (valida giornalmente) e con vincolo di fruizione **solo vicino/al POI**.

## File principali

- Soluzione completa: `SOLUZIONE_COMPLETA.md`
- Testo d'esame (trascritto): `../AB42_ORD19.md`

## Cartelle

- Diagrammi: `diagrammi/`
- Configurazioni: `configurazioni/`
- DB + pagine web: `codice/`
- Script: `script/`

## Esecuzione demo (locale, opzionale)

1) DB: applicare lo schema (PostgreSQL richiesto)

```bash
cd script
./init_schema.sh
```

2) Avvio web PHP (demo)

```bash
cd ../codice
php -S 127.0.0.1:8080
```

Apri (esempi):

- `http://127.0.0.1:8080/poi_base.php?poi_id=1&ticket=ABCDEF1234`
- `http://127.0.0.1:8080/ratings_avg.php`

## Operatività DB

Backup:

```bash
cd script
./backup_db.sh
```

Restore:

```bash
cd script
./restore_db.sh backups/poi_service_YYYY-MM-DD_HHMMSS.dump
```

Rotazione backup:

```bash
cd script
./rotate_backups.sh 14
```

## Porte/servizi (lista essenziale)

- Tablet → server web: `443/tcp` (HTTPS)
- Wi‑Fi enterprise / AAA:
  - AP → RADIUS: `1812/udp` (auth), `1813/udp` (accounting)
- (Interno) Web/App → DB PostgreSQL: `5432/tcp`
- DNS: `53/udp,tcp`
- NTP: `123/udp`

## Checklist sicurezza (minima)

- Device management (MDM): inventario tablet, blocco installazione app, wipe remoto
- Wi‑Fi WPA2/3‑Enterprise 802.1X con **EAP‑TLS** (certificato client su tablet)
- Web: HTTPS + (opzionale) mTLS; rate limiting e logging accessi
- Ticket: password lunga, valida solo per la data del biglietto; lockout/limiting
- Segregazione rete: VLAN CED/DMZ e VLAN per‑POI; policy firewall default‑deny

## Riferimenti rapidi ai documenti

- Rete e flussi:
  - `diagrammi/schema_rete_servizio.md`
  - `diagrammi/sequence_accesso_poi.md`
- Prossimità POI e “solo tablet”:
  - `configurazioni/accesso_tablet_sicurezza.md`
- IP/VLAN/Firewall:
  - `configurazioni/piano_indirizzamento.md`
  - `configurazioni/vlan_config.md`
  - `configurazioni/firewall_policy.md`
- Tariffe/lingue/3 POI:
  - `configurazioni/tariffe_lingue.md`
- DB + codice:
  - `diagrammi/er_poi.mmd`
  - `codice/schema.sql`
  - `codice/poi_base.php`
  - `codice/ratings_avg.php`
- Quesito IV (VPN):
  - `configurazioni/accesso_remoto_vpn.md`
