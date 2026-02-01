# Codice (DB + pagine web)

- `schema.sql`: modello logico DB (PostgreSQL) + view `poi_rating_avg`.
- `config.php`: parametri DB (placeholder).
- `poi_base.php`: pagina “tariffa base” (video breve + 3 immagini).
- `ratings_avg.php`: Quesito I (media voti per POI).

Esecuzione (esempio):

- Import schema: `psql -f schema.sql`
- Avvio PHP built-in: `php -S 0.0.0.0:8080`
