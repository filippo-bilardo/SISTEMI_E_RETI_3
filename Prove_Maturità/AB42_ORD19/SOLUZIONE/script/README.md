# Script operativi (AB42_ORD19)

Questi script sono **esempi operativi** a supporto della soluzione (backup DB, restore DB, init schema).

## Prerequisiti

- Linux + Bash
- PostgreSQL client tools: `psql`, `pg_dump`, `pg_restore`

## Configurazione

Gli script leggono le credenziali da variabili d'ambiente (consigliato) oppure da parametri.

Variabili supportate:

- `PGHOST` (es. `127.0.0.1`)
- `PGPORT` (es. `5432`)
- `PGDATABASE` (es. `poi_service`)
- `PGUSER` (es. `poi_app`)
- `PGPASSWORD` (solo se non usi `.pgpass`)

Suggerito: usa `.pgpass` per evitare password in chiaro in shell history.

## Script

- `init_schema.sh`: applica lo schema SQL contenuto in `../codice/schema.sql`
- `backup_db.sh`: esegue un backup del DB (formato custom) in `./backups/`
- `restore_db.sh`: ripristina un backup creato con `backup_db.sh`
- `rotate_backups.sh`: mantiene gli ultimi N backup e cancella i più vecchi

## Esempi

Applicare schema:

```bash
cd script
./init_schema.sh
```

Fare un backup:

```bash
cd script
./backup_db.sh
ls -lh backups/
```

Ripristinare:

```bash
cd script
./restore_db.sh backups/poi_service_2025-01-30_120000.dump
```

Ruotare backup (tieni ultimi 14):

```bash
cd script
./rotate_backups.sh 14
```
