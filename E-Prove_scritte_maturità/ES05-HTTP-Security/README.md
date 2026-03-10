# ES05 — Sicurezza HTTP: Minacce e Contromisure

## Introduzione

Il protocollo **HTTP nasce senza sicurezza**: progettato negli anni '90 per scambiare documenti di testo in una rete accademica, non prevedeva autenticazione dell'origine, cifratura dei dati o protezione dall'integrità. Il **web moderno**, invece, è bersaglio di attacchi sofisticati che sfruttano esattamente queste lacune originarie.

In questa esercitazione si analizzano le **principali minacce alla sicurezza delle applicazioni web** — XSS, CSRF, SQL Injection, MITM, Clickjacking, Session Hijacking — e le **tecnologie difensive** che il protocollo HTTP/HTTPS mette a disposizione: TLS, Content Security Policy, HSTS, cookie sicuri, header di sicurezza e WAF.

Il percorso combina **laboratorio pratico in Cisco Packet Tracer**, **progettazione autonoma** di una rete sicura e **domande di teoria** che coprono l'intero spettro delle conoscenze richieste per le prove scritte di maturità.

**Competenze coperte:**
- Analisi delle vulnerabilità web più comuni (OWASP Top 10 — cenni)
- Differenza tra attacchi sul canale (network), sull'applicazione e sull'utente
- Configurazione HTTPS e analisi del traffico cifrato in Cisco Packet Tracer (Simulation Mode)
- Header di sicurezza HTTP: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- Attributi dei cookie sicuri: `HttpOnly`, `Secure`, `SameSite`
- Web Application Firewall (WAF) — funzionamento e differenza da firewall di rete
- ACL su router Cisco per protezione perimetrale della DMZ
- Threat model di un'applicazione web: asset, attaccanti, vettori

---

## 📚 Guide Teoriche

Nella cartella [`docs/`](docs/) sono disponibili le guide di riferimento:

| # | Guida | Argomento |
|---|-------|-----------|
| 1 | [01_Vulnerabilita_HTTP.md](docs/01_Vulnerabilita_HTTP.md) | Perché HTTP è insicuro, OWASP Top 10, categorie di attacchi, threat model, strumenti di analisi |
| 2 | [02_Attacchi_Web.md](docs/02_Attacchi_Web.md) | XSS (reflected/stored/DOM), CSRF, Clickjacking, Session Hijacking, SQL Injection, Directory Traversal, MITM/SSL Stripping — meccanismo, esempio, difesa |
| 3 | [03_Header_Sicurezza.md](docs/03_Header_Sicurezza.md) | HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, CORS — sintassi, esempi, tabella comparativa |
| 4 | [04_HTTPS_Configurazione_Sicura.md](docs/04_HTTPS_Configurazione_Sicura.md) | Versioni TLS, cipher suites, certificati, HSTS preload, redirect 301, mixed content, OCSP stapling, checklist hardening |

---

## 🗂️ Esercizi

| # | Esercizio | Descrizione | Tipo |
|---|-----------|-------------|------|
| A | [esercizio_a.md](esercizio_a.md) | Simulazione attacchi HTTP e configurazione difese in Packet Tracer — rete `192.168.2.0/24` (9 step, 10 screenshot) | Laboratorio guidato |
| B | [esercizio_b.md](esercizio_b.md) | Piano di sicurezza web per "SafeWeb S.r.l." — 3 subnet `/26`, DMZ, ACL, HTTPS obbligatorio, report sicurezza | Progetto autonomo |
| C | [esercizio_c.md](esercizio_c.md) | 20 domande di teoria in 6 sezioni: vulnerabilità HTTP, attacchi lato client, attacchi sul canale, attacchi lato server, contromisure, best practices | Verifica teorica |

---

## 📁 Struttura del Progetto

```
ES05-HTTP-Security/
├── README.md                          ← questo file
├── esercizio_a.md                     ← laboratorio guidato (Packet Tracer)
├── esercizio_b.md                     ← progetto autonomo (SafeWeb S.r.l.)
├── esercizio_c.md                     ← domande di teoria (20 domande, 70 pt)
├── img/
│   └── ...                            ← screenshot e schemi topologia
└── docs/                              ← guide teoriche
    ├── 01_Vulnerabilita_HTTP.md
    ├── 02_Attacchi_Web.md
    ├── 03_Header_Sicurezza.md
    └── 04_HTTPS_Configurazione_Sicura.md
```

---

> 💡 **Prerequisiti consigliati**: ES04-HTTP (protocollo HTTP/HTTPS, configurazione web server in PT, TLS di base), ES03-DNS-Security (concetti di sicurezza DNS, threat model).
