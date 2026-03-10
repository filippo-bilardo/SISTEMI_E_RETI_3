# ES02 — Progetto DNS: Configurazione di un Server DNS Interno

## Introduzione

In questa esercitazione si affronta la configurazione di un **server DNS interno** in una rete aziendale simulata con **Cisco Packet Tracer**. Il DNS (*Domain Name System*) è il sistema che permette di tradurre i nomi simbolici (es. `www.azienda.local`) in indirizzi IP, rendendo la rete più usabile e gestibile.

Attraverso le attività proposte si imparerà a installare e configurare un server DNS in una LAN, creare record DNS di vario tipo (A, CNAME, MX), verificare la risoluzione dei nomi tramite `nslookup` e `ping`, e gestire un DNS interno separato da quello pubblico.

**Competenze coperte:**
- Configurazione del servizio DNS in Cisco Packet Tracer (GUI → Services → DNS)
- Creazione e gestione dei record DNS (A, CNAME, MX)
- Impostazione del DNS sui client Windows (PC Packet Tracer)
- Test e verifica: `nslookup`, `ping` per nome, apertura URL nel browser simulato
- Concetti di DNS interno vs DNS pubblico, split-horizon, DNS secondario

---

## 📚 Guide Teoriche

Nella cartella [`docs/`](docs/) sono disponibili le guide di riferimento sugli argomenti trattati:

| # | Guida | Argomento |
|---|-------|-----------|
| 1 | [01_DNS.md](docs/01_DNS.md) | Cos'è il DNS, gerarchia, risoluzione ricorsiva/iterativa, tipi di record, configurazione in PT |
| 2 | [02_Record_DNS.md](docs/02_Record_DNS.md) | Guida dettagliata ai record DNS: A, AAAA, CNAME, MX, PTR, NS, SOA, TXT |
| 3 | [03_DNS_Interno.md](docs/03_DNS_Interno.md) | DNS interno aziendale, split-horizon, zone locali, forwarding verso DNS pubblico |
| 4 | [04_Troubleshooting_DNS.md](docs/04_Troubleshooting_DNS.md) | Problemi comuni, comandi diagnostici, scenari di errore con soluzioni |

---

## 🗂️ Esercizi

| # | Esercizio | Descrizione | Tipo |
|---|-----------|-------------|------|
| A | [esercizio_a.md](esercizio_a.md) | Configurazione guidata DNS interno in Cisco Packet Tracer — rete `192.168.1.0/24` (9 step con screenshot) | Laboratorio pratico |
| B | [esercizio_b.md](esercizio_b.md) | Progettazione autonoma DNS per l'azienda "MediaCorp" con due reparti, DNS primario e secondario | Progetto autonomo |
| C | [esercizio_c.md](esercizio_c.md) | 20 domande di teoria su DNS, record, DNS interno, protocolli, troubleshooting e scenari avanzati | Verifica teorica |

---

## 📁 Struttura del Progetto

```
ES02-DNS/
├── README.md               ← questo file
├── esercizio_a.md          ← laboratorio guidato (Packet Tracer)
├── esercizio_b.md          ← progetto autonomo (MediaCorp)
├── esercizio_c.md          ← domande di teoria (20 domande)
├── img/
│   └── ...                 ← screenshot e schemi topologia
└── docs/                   ← guide teoriche
    ├── 01_DNS.md
    ├── 02_Record_DNS.md
    ├── 03_DNS_Interno.md
    └── 04_Troubleshooting_DNS.md
```
