-- Schema DB (PostgreSQL) - modello logico
-- Riferimento: Prima Parte - Punto 2 (modello concettuale + logico)

CREATE TABLE tariff (
  tariff_id SMALLINT PRIMARY KEY,
  name TEXT UNIQUE NOT NULL CHECK (name IN ('BASE','INTERMEDIA','PIENA'))
);

CREATE TABLE poi (
  poi_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  poi_type TEXT NOT NULL,
  address TEXT,
  lat NUMERIC(9,6),
  lon NUMERIC(9,6)
);

CREATE TABLE media (
  media_id SERIAL PRIMARY KEY,
  poi_id INT NOT NULL REFERENCES poi(poi_id) ON DELETE CASCADE,
  kind TEXT NOT NULL CHECK (kind IN ('video_base','video_adv','image')),
  url TEXT NOT NULL,
  lang TEXT NOT NULL,
  caption TEXT,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE visitor (
  visitor_id SERIAL PRIMARY KEY,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ticket (
  ticket_id SERIAL PRIMARY KEY,
  visitor_id INT NOT NULL REFERENCES visitor(visitor_id) ON DELETE RESTRICT,
  tariff_id SMALLINT NOT NULL REFERENCES tariff(tariff_id),
  valid_date DATE NOT NULL,
  password_hash TEXT NOT NULL,
  lang_pref TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (visitor_id, valid_date)
);

CREATE TABLE infopoint (
  infopoint_id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  location TEXT NOT NULL
);

CREATE TABLE device (
  device_id SERIAL PRIMARY KEY,
  serial TEXT UNIQUE NOT NULL,
  cert_fingerprint TEXT UNIQUE,
  status TEXT NOT NULL DEFAULT 'AVAILABLE' CHECK (status IN ('AVAILABLE','RENTED','MAINT','LOST'))
);

-- consegna tablet + cauzione (documento o carta)
CREATE TABLE rental (
  rental_id SERIAL PRIMARY KEY,
  ticket_id INT NOT NULL REFERENCES ticket(ticket_id) ON DELETE CASCADE,
  device_id INT NOT NULL REFERENCES device(device_id) ON DELETE RESTRICT,
  infopoint_out INT NOT NULL REFERENCES infopoint(infopoint_id),
  infopoint_in INT REFERENCES infopoint(infopoint_id),
  collateral_type TEXT NOT NULL CHECK (collateral_type IN ('ID','CC')),
  collateral_ref TEXT NOT NULL,
  out_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  in_at TIMESTAMPTZ,
  UNIQUE (ticket_id),
  UNIQUE (device_id) DEFERRABLE INITIALLY IMMEDIATE
);

-- Per tariffa intermedia: tre POI avanzati selezionati
CREATE TABLE ticket_poi_adv (
  ticket_id INT NOT NULL REFERENCES ticket(ticket_id) ON DELETE CASCADE,
  poi_id INT NOT NULL REFERENCES poi(poi_id) ON DELETE RESTRICT,
  PRIMARY KEY (ticket_id, poi_id)
);

-- Log accessi (audit + enforcement)
CREATE TABLE access_log (
  log_id BIGSERIAL PRIMARY KEY,
  ticket_id INT REFERENCES ticket(ticket_id) ON DELETE SET NULL,
  device_id INT REFERENCES device(device_id) ON DELETE SET NULL,
  poi_id INT REFERENCES poi(poi_id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  source_net TEXT,
  ts TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Seconda parte, Quesito I: commenti e voti
CREATE TABLE feedback (
  feedback_id BIGSERIAL PRIMARY KEY,
  poi_id INT NOT NULL REFERENCES poi(poi_id) ON DELETE CASCADE,
  ticket_id INT NOT NULL REFERENCES ticket(ticket_id) ON DELETE CASCADE,
  rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (poi_id, ticket_id)
);

-- Vista: media voti per POI
CREATE VIEW poi_rating_avg AS
SELECT p.poi_id, p.name,
       ROUND(AVG(f.rating)::numeric, 2) AS avg_rating,
       COUNT(*) AS votes
FROM poi p
LEFT JOIN feedback f ON f.poi_id = p.poi_id
GROUP BY p.poi_id, p.name
ORDER BY p.name;
