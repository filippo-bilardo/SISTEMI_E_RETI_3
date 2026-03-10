# 03 — DNS over HTTPS (DoH) e DNS over TLS (DoT)

> 🔒 **Guida teorica** | ES03 — Sicurezza DNS  
> Livello: Scuola superiore, 4a/5a anno  
> Prerequisiti: TLS/HTTPS, porte di rete, privacy digitale

---

## 1. Il Problema della Privacy nel DNS Tradizionale

### 1.1 Le query DNS sono in chiaro

Nel DNS tradizionale, ogni query viaggia in chiaro su **UDP porta 53**. Questo significa che chiunque sia in posizione di intercettare il traffico può vedere:

- Quali siti stai visitando (anche se il sito usa HTTPS!)
- A che ora li visiti
- Con quale frequenza
- Da quale IP stai facendo le query

> ⚠️ **Paradosso HTTPS**: anche se visiti `https://www.banca.it` con una connessione HTTPS cifrata, la query DNS "qual è l'IP di www.banca.it?" viaggia in chiaro. Il contenuto della comunicazione è protetto, ma il fatto che tu stia visitando quella banca no.

### 1.2 Chi può intercettare le query DNS?

| Attore | Come intercetta | Scopo |
|--------|----------------|-------|
| **ISP** | Posizione privilegiata sul percorso | Profilazione, vendita dati, censura |
| **Attaccante locale** (stesso Wi-Fi) | Passive sniffing, ARP poisoning | Ricognizione, targeting |
| **Attaccante MITM** | Interposizione sul percorso | Modifica risposte, phishing |
| **Nodo intermedio** (router, proxy) | Inspection sul percorso | Filtro contenuti, sorveglianza |
| **Governo / Autorità** | Richiesta all'ISP | Sorveglianza, censura |

### 1.3 La soluzione: cifrare le query DNS

Le due soluzioni standardizzate sono:
- **DoT** — DNS over TLS (RFC 7858, 2016)
- **DoH** — DNS over HTTPS (RFC 8484, 2018)

Entrambe cifrano le query DNS usando **TLS** (Transport Layer Security), ma in modo diverso.

---

## 2. DNS over TLS (DoT)

### 2.1 Cos'è DoT

**DoT** (*DNS over TLS*, RFC 7858) è il protocollo che cifra le query DNS usando TLS, su una **porta dedicata: 853**.

### 2.2 Come funziona

```
CLIENT                              RESOLVER DoT
  |                                      |
  |-- TCP SYN (porta 853) -------------> |
  |<- TCP SYN/ACK ---------------------- |
  |-- TCP ACK -------------------------->|
  |                                      |
  |=== TLS Handshake =================== |
  |  (verifica certificato del resolver) |
  |===================================== |
  |                                      |
  |-- [query DNS cifrata con TLS] -----> |
  |<- [risposta DNS cifrata con TLS] --- |
  |                                      |
```

### 2.3 Caratteristiche DoT

| Caratteristica | Valore |
|---------------|--------|
| Porta | **853/TCP** |
| Protocollo base | TCP |
| Cifratura | TLS 1.2 o 1.3 |
| Visibilità firewall | Traffico su porta 853 → facilmente identificabile come DoT |
| Latenza aggiuntiva | TLS handshake + TCP (più lento del DNS tradizionale) |
| Persistent connection | Sì, la connessione TLS rimane aperta per query multiple |
| RFC | RFC 7858 (2016) |

### 2.4 Pro e Contro DoT

✅ **Vantaggi**:
- Query DNS cifrate e autenticate
- Il resolver è verificato tramite certificato TLS
- Facilmente identificabile e controllabile da firewall aziendali (porta dedicata 853)
- Supporto nativo in Android 9+, systemd-resolved (Linux), BIND9, Unbound

❌ **Svantaggi**:
- Porta 853 potrebbe essere bloccata da firewall restrittivi
- Overhead TCP + TLS (latenza maggiore rispetto a UDP/53)
- Richiede configurazione esplicita sul client o resolver

---

## 3. DNS over HTTPS (DoH)

### 3.1 Cos'è DoH

**DoH** (*DNS over HTTPS*, RFC 8484) è il protocollo che cifra le query DNS incapsulandole in richieste **HTTPS** su **porta 443**. Le query DNS appaiono come normale traffico web.

### 3.2 Come funziona

```
CLIENT                              RESOLVER DoH
  |                                      |
  |-- HTTPS POST/GET (porta 443) ----->  |
  |   Host: dns.cloudflare.com           |
  |   Content-Type: application/dns-message
  |   Body: [query DNS codificata]       |
  |                                      |
  |<- HTTP 200 OK ---------------------- |
  |   Content-Type: application/dns-message
  |   Body: [risposta DNS codificata]    |
  |                                      |
```

Le query usano il formato **wire format** del DNS, codificate in Base64url e inviate come parametro GET o nel body di una POST.

Esempio di URL DoH:
```
https://dns.cloudflare.com/dns-query?dns=AAABAAABAAAAAAAAA3d3dwdleGFtcGxlA2NvbQAAAQAB
```

### 3.3 Caratteristiche DoH

| Caratteristica | Valore |
|---------------|--------|
| Porta | **443/TCP** (identica a HTTPS normale) |
| Protocollo base | HTTP/2 o HTTP/3 su TLS |
| Cifratura | TLS 1.2 o 1.3 |
| Visibilità firewall | **Invisibile** — indistinguibile da traffico HTTPS normale |
| Latenza aggiuntiva | HTTP overhead (leggermente più alto di DoT) |
| Supporto browser | Chrome, Firefox, Edge — integrazione nativa |
| RFC | RFC 8484 (2018) |

### 3.4 Pro e Contro DoH

✅ **Vantaggi**:
- Query DNS invisibili agli ISP e a chiunque analizzi il traffico
- Non bloccabile da firewall che bloccano solo porta 853
- Integrazione nativa nei browser moderni
- Beneficia delle ottimizzazioni HTTP/2 (multiplexing)

❌ **Svantaggi**:
- **Problematico per le aziende**: il team di sicurezza non può più analizzare le query DNS
- Bypassa i sistemi di filtro DNS aziendali
- Il DNS risolto non è quello dell'organizzazione ma del provider DoH (es. Cloudflare)
- Maggiore dipendenza da pochi provider centralizzati (Cloudflare, Google)

---

## 4. Confronto DNS Tradizionale, DoT, DoH

| Caratteristica | DNS Tradizionale | DoT | DoH |
|---------------|-----------------|-----|-----|
| **Porta** | 53 (UDP/TCP) | 853 (TCP) | 443 (TCP) |
| **Cifratura** | ❌ Nessuna | ✅ TLS | ✅ TLS |
| **Autenticazione resolver** | ❌ No | ✅ Certificato TLS | ✅ Certificato TLS |
| **Protezione da MITM** | ❌ No | ✅ Sì | ✅ Sì |
| **Visibile a firewall** | ✅ Sì | ✅ Sì (porta 853) | ❌ No (443 = HTTPS) |
| **Filtrabile da azienda** | ✅ Facilmente | ✅ Facilmente | ⚠️ Difficile |
| **Supporto nativo OS** | ✅ Universale | Android 9+, Linux | Windows 11, Android |
| **Supporto browser** | N/A | N/A | Chrome, Firefox, Edge |
| **Overhead latenza** | Minimo | Medio (TLS+TCP) | Medio-alto (HTTP) |
| **RFC** | RFC 1035 (1987) | RFC 7858 (2016) | RFC 8484 (2018) |
| **Privacy da ISP** | ❌ Nessuna | ✅ Alta | ✅ Alta |

---

## 5. Resolver Pubblici Sicuri

### 5.1 I principali provider DoH/DoT

#### 🌐 Cloudflare — 1.1.1.1

| Proprietà | Valore |
|-----------|--------|
| IP primario | `1.1.1.1` |
| IP secondario | `1.0.0.1` |
| DoT hostname | `one.one.one.one` |
| DoH URL | `https://cloudflare-dns.com/dns-query` |
| Privacy | Non registra query per più di 24h; audit indipendente |
| DNSSEC | ✅ Validazione DNSSEC |
| Malware blocking | `1.1.1.2` (filtra malware), `1.1.1.3` (filtra malware + adulti) |

#### 🌐 Google — 8.8.8.8

| Proprietà | Valore |
|-----------|--------|
| IP primario | `8.8.8.8` |
| IP secondario | `8.8.4.4` |
| DoT hostname | `dns.google` |
| DoH URL | `https://dns.google/dns-query` |
| Privacy | Alcune query logged per 24–48h; integrazione con ecosistema Google |
| DNSSEC | ✅ Validazione DNSSEC |

#### 🌐 Quad9 — 9.9.9.9

| Proprietà | Valore |
|-----------|--------|
| IP primario | `9.9.9.9` |
| IP secondario | `149.112.112.112` |
| DoT hostname | `dns.quad9.net` |
| DoH URL | `https://dns.quad9.net/dns-query` |
| Privacy | No log di IP; sede legale in Svizzera (protezione GDPR forte) |
| DNSSEC | ✅ Validazione DNSSEC |
| Malware blocking | ✅ Blocca domini malevoli noti (threat intelligence) |

#### 🌐 NextDNS — personalizzabile

NextDNS offre un resolver DoH/DoT completamente configurabile: filtri per categorie, allowlist/blocklist personalizzate, log dettagliati con controllo privacy. Ideale per uso aziendale.

### 5.2 Test dei resolver

```bash
# Test connettività DNS tradizionale
dig @1.1.1.1 www.example.com

# Test DoT con kdig (knot-dns)
kdig -d @1.1.1.1 +tls-ca +tls-hostname=one.one.one.one www.example.com

# Test DoH con curl
curl -H 'accept: application/dns-json' \
  'https://1.1.1.1/dns-query?name=example.com&type=A'

# Verifica DNSSEC su Cloudflare
dig @1.1.1.1 +dnssec +short cloudflare.com
```

---

## 6. Configurazione DoH nei Browser

### 6.1 Mozilla Firefox

Firefox è stato il primo browser a implementare DoH (Trusted Recursive Resolver):

1. Apri **Impostazioni** → cerca "DNS"
2. Scorrere fino a **Impostazioni di connessione** → **Impostazioni...**
3. Abilita **DNS over HTTPS**
4. Scegli il provider (Cloudflare predefinito) o inserisci URL personalizzato

Oppure tramite `about:config`:
```
network.trr.mode = 2         (usa DoH con fallback a DNS normale)
network.trr.mode = 3         (usa SOLO DoH, nessun fallback)
network.trr.uri = https://mozilla.cloudflare-dns.com/dns-query
```

### 6.2 Google Chrome / Edge

1. Apri **Impostazioni** → **Privacy e sicurezza** → **Sicurezza**
2. Abilita **Usa DNS sicuro**
3. Scegli provider o inserisci URL personalizzato

### 6.3 Windows 11 (sistema operativo)

Windows 11 supporta DoH a livello di sistema:
1. **Impostazioni** → **Rete e Internet** → **Wi-Fi/Ethernet** → seleziona la connessione
2. **Modifica server DNS** → imposta DoH
3. Inserisci IP del resolver (es. `1.1.1.1`) → seleziona **DNS over HTTPS (automatico)**

### 6.4 Android 9+ (Private DNS)

1. **Impostazioni** → **Rete e Internet** → **DNS privato**
2. Seleziona **Nome host provider DNS privato**
3. Inserisci hostname DoT: `one.one.one.one` (Cloudflare) o `dns.google` (Google)

---

## 7. Implicazioni Aziendali di DoH

### 7.1 Il problema per i team di sicurezza

DoH è un **doppio taglio** in ambito aziendale:

**Problema 1 — Bypass del filtro DNS aziendale**:
- Le aziende spesso filtrano i siti tramite il DNS interno (blocco per categoria: social, gambling, phishing)
- Se il browser usa DoH verso Cloudflare/Google, bypassa completamente il DNS aziendale
- I siti bloccati diventano accessibili

**Problema 2 — Impossibilità di monitoraggio**:
- I sistemi IDS/IPS analizzano le query DNS per rilevare malware (query verso domini C2, DGA)
- Con DoH il traffico DNS è cifrato → i sistemi di sicurezza sono ciechi
- DNS tunneling tramite DoH è praticamente invisibile

**Problema 3 — Compliance e audit**:
- Molte normative richiedono il logging delle comunicazioni (es. GDPR per DLP, PCI-DSS)
- Il logging DNS è parte dell'audit trail
- DoH verso provider esterni rende impossibile il logging centralizzato

### 7.2 Strategie di mitigazione per le aziende

**Strategia 1 — Bloccare i resolver DoH noti**:
```
# Firewall: blocca accesso ai resolver DoH più comuni
# IP da bloccare (esempio, non esaustivo):
1.1.1.1/32      (Cloudflare)
1.0.0.1/32      (Cloudflare)
8.8.8.8/32      (Google)
8.8.4.4/32      (Google)
9.9.9.9/32      (Quad9)

# Blocca il dominio (richiede DNS inspection)
dns.cloudflare.com
dns.google
dns.quad9.net
```

**Strategia 2 — Gestione browser tramite Group Policy (Windows)**:
```
# GPO per disabilitare DoH in Chrome
Configurazione computer → Modelli amministrativi → Google Chrome:
- "Configura DNS-over-HTTPS" = Disabilitato

# GPO per Firefox:
Aggiungere in policies.json:
{
  "DNSOverHTTPS": {
    "Enabled": false,
    "Locked": true
  }
}
```

**Strategia 3 — Deployment di un resolver DoH interno**:
- Configurare il resolver aziendale per supportare DoH/DoT
- Distribuire la configurazione tramite GPO per puntare al resolver interno
- Il traffico DNS è cifrato dal client al resolver aziendale, ma il resolver aziendale può ancora filtrare e loggare

**Strategia 4 — TLS Inspection (SSL Decryption)**:
- I next-gen firewall possono decriptare il traffico TLS (incluso DoH) per ispezionarlo
- Richiede installazione di un certificato CA aziendale nei browser/OS
- Invasivo e richiede consenso informato degli utenti (implicazioni privacy/legali)

---

## 8. Split-horizon DNS e DoH: Problemi e Soluzioni

### 8.1 Il conflitto

Lo **split-horizon DNS** (DNS con visione divisa) serve risposte diverse a seconda della rete di provenienza:
- Dalla rete interna: `intranet.azienda.com` → `10.0.0.1` (IP privato)
- Da Internet: `intranet.azienda.com` → non risponde (o IP diverso)

Con DoH il client usa un resolver esterno (es. Cloudflare) che non conosce la zona interna. Quindi:
- `nslookup intranet.azienda.com` → NXDOMAIN (Cloudflare non sa dell'IP privato)
- L'accesso a risorse interne tramite nome diventa impossibile

### 8.2 Soluzione: Override DoH per domini interni

Sia Firefox che Chrome permettono di configurare eccezioni al DoH per specifici domini:

```
# Firefox about:config
network.trr.excluded_domains = azienda.com, corp.local, .local
# Per questi domini usa DNS tradizionale (resolver interno)
```

In ambiente aziendale gestito, il **resolver DoH interno** viene configurato come preferred resolver, così il traffico DNS è cifrato MA passa per il sistema aziendale.

---

## 9. DoH vs DoT: Quale Scegliere?

| Scenario | Raccomandazione | Motivo |
|----------|----------------|--------|
| **Uso personale** | DoH | Integrazione browser, no configurazione |
| **Android/mobile** | DoT (Private DNS) | Supporto nativo OS, porta 853 raramente bloccata |
| **Ambiente aziendale** | DoT interno | Controllabile, porta dedicata, logging possibile |
| **Rete con firewall restrittivo** | DoH | Porta 443 quasi sempre aperta |
| **Privacy massima** | DoH | Indistinguibile da HTTPS, bypass sorveglianza |
| **Monitoring di sicurezza** | Nessuno (o DoT interno) | DoH bypass i sistemi di sicurezza |
