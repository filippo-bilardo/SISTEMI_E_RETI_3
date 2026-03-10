# ES04 — Protocollo HTTP/HTTPS: Configurazione e Analisi del Web

## Introduzione

Il **protocollo HTTP** (*HyperText Transfer Protocol*) è il fondamento del World Wide Web: ogni volta che un browser richiede una pagina, un'immagine o un file, utilizza HTTP per comunicare con il server. In questa esercitazione si configura un **web server in Cisco Packet Tracer**, si analizza la struttura delle richieste e risposte HTTP, si comprende la differenza fondamentale tra HTTP e HTTPS, e si simulano scenari reali di navigazione web in una LAN aziendale.

L'evoluzione verso **HTTPS** (*HTTP Secure*) ha reso la comunicazione web cifrata e autenticata, proteggendo gli utenti da intercettazioni e attacchi *man-in-the-middle*. Comprendere entrambi i protocolli — il loro funzionamento, i codici di stato, i cookie, la cache e i certificati — è competenza fondamentale per qualsiasi tecnico di reti.

**Competenze coperte:**
- Configurazione del servizio HTTP/HTTPS in Cisco Packet Tracer (GUI → Services → HTTP)
- Metodi HTTP: GET, POST, HEAD, PUT, DELETE — differenze e casi d'uso
- Codici di stato HTTP: classi 2xx, 3xx, 4xx, 5xx — significato e troubleshooting
- Header HTTP di richiesta e risposta — struttura e campi principali
- Cookie e sessioni: meccanismo Set-Cookie/Cookie, session vs persistent cookie
- HTTPS e TLS: handshake, certificati X.509, CA, HSTS
- Virtual hosting: più siti su un singolo server IP
- Analisi del traffico HTTP in Simulation Mode di Packet Tracer

---

## 📚 Guide Teoriche

Nella cartella [`docs/`](docs/) sono disponibili le guide di riferimento sugli argomenti trattati:

| # | Guida | Argomento |
|---|-------|-----------|
| 1 | [01_HTTP.md](docs/01_HTTP.md) | Cos'è HTTP, storia delle versioni, modello client-server, struttura richiesta/risposta, metodi, URL, connessioni, configurazione in PT |
| 2 | [02_Codici_Stato_Header.md](docs/02_Codici_Stato_Header.md) | Tutti i codici di stato HTTP (1xx–5xx), header principali di richiesta e risposta, MIME types, esempi reali |
| 3 | [03_HTTPS_TLS.md](docs/03_HTTPS_TLS.md) | Perché HTTP non è sicuro, TLS e versioni, handshake TLS, certificati X.509, HSTS, redirect HTTP→HTTPS, PT e HTTPS |
| 4 | [04_Cookie_Sessioni_Cache.md](docs/04_Cookie_Sessioni_Cache.md) | Statelessness HTTP, cookie e attributi, sessioni lato server, autenticazione, cache HTTP, CDN, LocalStorage |

---

## 🗂️ Esercizi

| # | Esercizio | Descrizione | Tipo |
|---|-----------|-------------|------|
| A | [esercizio_a.md](esercizio_a.md) | Configurazione guidata Web Server HTTP/HTTPS in Cisco Packet Tracer — rete `192.168.1.0/24` (9 step con 10 screenshot) | Laboratorio pratico |
| B | [esercizio_b.md](esercizio_b.md) | Progettazione autonoma web server per "WebFactory S.r.l." con 3 subnet `/26` e 3 siti distinti | Progetto autonomo |
| C | [esercizio_c.md](esercizio_c.md) | 20 domande di teoria su HTTP/HTTPS, metodi, codici di stato, cookie, cache, HTTPS/TLS e troubleshooting | Verifica teorica |

---

## 📁 Struttura del Progetto

```
ES04-HTTP/
├── README.md               ← questo file
├── esercizio_a.md          ← laboratorio guidato (Packet Tracer)
├── esercizio_b.md          ← progetto autonomo (WebFactory S.r.l.)
├── esercizio_c.md          ← domande di teoria (20 domande)
├── img/
│   └── ...                 ← screenshot e schemi topologia
└── docs/                   ← guide teoriche
    ├── 01_HTTP.md
    ├── 02_Codici_Stato_Header.md
    ├── 03_HTTPS_TLS.md
    └── 04_Cookie_Sessioni_Cache.md
```

---

## 🔗 Prerequisiti Consigliati

Prima di affrontare questa esercitazione è utile aver completato:
- **ES01** — Progetto VLAN (subnetting e routing di base)
- **ES02** — DNS interno (configurazione DNS in Packet Tracer, necessario per la risoluzione dei nomi)

La conoscenza del modello **OSI** e dei livelli **3 (Network)** e **4 (Transport)** è assunta come prerequisito.

---

> 💡 **Nota per il docente:** L'esercizio A è pensato per essere svolto in laboratorio (2–3 ore). L'esercizio B richiede una sessione autonoma (3–4 ore) con relazione. L'esercizio C è una verifica scritta da 45 minuti a libri chiusi.
