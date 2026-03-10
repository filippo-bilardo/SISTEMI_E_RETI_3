# ES03 — Sicurezza DNS: Minacce e Contromisure

## Introduzione

Il **DNS** (*Domain Name System*) è uno dei protocolli fondamentali di Internet, progettato negli anni '80 in un contesto di rete aperta e fiduciosa. Nato senza meccanismi di autenticazione né crittografia, oggi rappresenta uno dei vettori di attacco più sfruttati: compromettere il DNS significa poter **redirigere silenziosamente** gli utenti verso siti malevoli, intercettare comunicazioni, amplificare attacchi DDoS e persino esfiltrare dati.

Questa esercitazione analizza le **principali minacce al protocollo DNS** — dal cache poisoning al DNS tunneling — e le **tecnologie difensive** più adottate in ambito enterprise: DNSSEC, DNS over HTTPS (DoH), DNS over TLS (DoT), ACL sui resolver e monitoring avanzato.

> 💡 **Prerequisiti consigliati**: completamento di ES02 (configurazione DNS interno), conoscenza base di TCP/IP, subnetting, routing Cisco IOS.

**Competenze coperte:**
- DNS spoofing e cache poisoning: meccanismo e conseguenze
- DNS hijacking (locale, remoto, ISP-level)
- Attacchi DDoS tramite DNS amplification/reflection
- DNSSEC: firme digitali, catena di fiducia, record RRSIG/DNSKEY/DS
- DNS over HTTPS (DoH) e DNS over TLS (DoT): privacy vs monitoring
- Configurazione ACL su resolver Cisco per bloccare open resolver
- Monitoraggio di query DNS anomale e incident response

---

## 📚 Guide Teoriche

Nella cartella [`docs/`](docs/) sono disponibili le guide di riferimento:

| # | Guida | Argomento |
|---|-------|-----------|
| 1 | [01_Minacce_DNS.md](docs/01_Minacce_DNS.md) | Vulnerabilità by design del DNS, DNS poisoning, hijacking, amplification DDoS, tunneling |
| 2 | [02_DNSSEC.md](docs/02_DNSSEC.md) | DNSSEC: firme digitali, ZSK/KSK, catena di fiducia, record RRSIG/DNSKEY/DS/NSEC |
| 3 | [03_DoH_DoT.md](docs/03_DoH_DoT.md) | DNS over HTTPS e DNS over TLS: privacy, implicazioni aziendali, resolver pubblici sicuri |
| 4 | [04_Difese_Pratiche.md](docs/04_Difese_Pratiche.md) | RRL, ACL resolver, DNSSEC validation, monitoring, hardening checklist, incident response |

---

## 🗂️ Esercizi

| # | Esercizio | Descrizione | Tipo |
|---|-----------|-------------|------|
| A | [esercizio_a.md](esercizio_a.md) | Simulazione attacco DNS e configurazione difese in Cisco Packet Tracer — rete `192.168.1.0/24` (9 step con 10 screenshot) | Laboratorio pratico |
| B | [esercizio_b.md](esercizio_b.md) | Piano di sicurezza DNS per l'azienda "SecureNet S.r.l." con 3 subnet `/27`, ACL anti-amplification, documentazione | Progetto autonomo |
| C | [esercizio_c.md](esercizio_c.md) | 20 domande di teoria su minacce DNS, DNSSEC, DoH/DoT, difese pratiche e scenari reali (70 pt) | Verifica teorica |

---

## 📁 Struttura del Progetto

```
ES03-DNS-Security/
├── README.md               ← questo file
├── esercizio_a.md          ← laboratorio guidato (Packet Tracer, attacco + difesa)
├── esercizio_b.md          ← progetto autonomo (SecureNet S.r.l.)
├── esercizio_c.md          ← domande di teoria (20 domande, 70 pt)
├── img/
│   └── ...                 ← screenshot topologie e schemi
└── docs/                   ← guide teoriche
    ├── 01_Minacce_DNS.md
    ├── 02_DNSSEC.md
    ├── 03_DoH_DoT.md
    └── 04_Difese_Pratiche.md
```

---

## ⚠️ Nota didattica

Le simulazioni di attacco descritte in questa esercitazione sono eseguite **esclusivamente in ambienti virtuali isolati** (Cisco Packet Tracer). Le tecniche illustrate hanno scopo puramente educativo: comprendere come funziona un attacco è il primo passo per difendersi efficacemente.
