# 04 — Difese Pratiche per la Sicurezza DNS

> 🛡️ **Guida teorica** | ES03 — Sicurezza DNS  
> Livello: Scuola superiore, 4a/5a anno  
> Prerequisiti: DNS base (ES02), ACL Cisco (ES01), concetti firewall

---

## 1. Response Rate Limiting (RRL)

### 1.1 Cos'è RRL

Il **Response Rate Limiting** è una funzionalità dei server DNS authoritative che limita la frequenza con cui il server risponde a richieste simili provenienti dallo stesso indirizzo IP (o range di IP). Introdotto nel 2012 specificamente per contrastare gli attacchi DNS amplification.

### 1.2 Come funziona

```
Senza RRL:
ATTACCANTE → [10.000 query/sec con IP vittima] → DNS SERVER
                                                       ↓
VITTIMA ← [10.000 risposte/sec × 50x amplification = 500.000 risposte/sec]

Con RRL:
ATTACCANTE → [10.000 query/sec con IP vittima] → DNS SERVER
                                                       ↓ (RRL: max 5/sec per IP)
VITTIMA ← [5 risposte/sec × 50x = 250 risposte/sec] (inefficace per DDoS)
```

### 1.3 Parametri RRL tipici

| Parametro | Valore tipico | Descrizione |
|-----------|--------------|-------------|
| `responses-per-second` | 5–10 | Risposte identiche max al secondo per IP |
| `referrals-per-second` | 5 | Referral (deleghe) max al secondo |
| `nodata-per-second` | 5 | Risposte NODATA max al secondo |
| `nxdomains-per-second` | 5 | Risposte NXDOMAIN max al secondo |
| `errors-per-second` | 5 | Risposte di errore max al secondo |
| `slip` | 2 | Ogni N risposte bloccate, invia una TRUNCATED (fa retry TCP) |
| `window` | 15 secondi | Finestra temporale per il conteggio |

### 1.4 Configurazione BIND9

```
// In named.conf
options {
    rate-limit {
        responses-per-second 10;
        referrals-per-second 5;
        nodata-per-second 5;
        nxdomains-per-second 5;
        errors-per-second 5;
        slip 2;
        window 15;
        // Whitelist: non limitare questi IP (es. monitoring interno)
        exempt-clients { 192.168.1.0/24; localhost; };
        // Log quando viene applicato il limite
        log-only no;  // yes = solo log senza limitare (test mode)
    };
};
```

### 1.5 Monitoraggio RRL

```bash
# Controllare le statistiche RRL in BIND9
rndc stats
grep "rate limit" /var/named/data/named_stats.txt

# Log di esempio quando RRL è attivo:
# client 1.2.3.4#12345: rate limit slip response to 5.6.7.8#53
```

---

## 2. ACL sui Resolver: da Open a Closed Resolver

### 2.1 Il problema dell'Open Resolver

Un **open resolver** è un server DNS configurato per eseguire query ricorsive per chiunque faccia una richiesta, indipendentemente dall'indirizzo IP sorgente. Questo è:
- ✅ Conveniente in ambienti controllati (uso interno)
- ❌ Pericoloso su Internet: può essere sfruttato come amplificatore DDoS

> 💡 Il resolver di Google (`8.8.8.8`) e Cloudflare (`1.1.1.1`) sono open resolver SOLO perché sono progettati per uso pubblico e hanno protezioni avanzate (RRL, anycast, infrastruttura massiccia). Un normale server DNS aziendale NON dovrebbe essere un open resolver.

### 2.2 Configurare un Closed Resolver (BIND9)

```
// In named.conf
acl "reti-interne" {
    10.0.0.0/8;         // Tutte le reti private classe A
    172.16.0.0/12;      // Reti private classe B
    192.168.0.0/16;     // Reti private classe C
    127.0.0.1;          // Localhost
    ::1;                // IPv6 localhost
};

options {
    // Permetti query ricorsive SOLO dalla rete interna
    allow-recursion { "reti-interne"; };
    
    // Permetti query (anche non ricorsive) SOLO dalla rete interna
    allow-query { "reti-interne"; };
    
    // Chi può fare trasferimenti di zona (AXFR)
    allow-transfer { "dns-secondari"; };
    
    // Non rispondere a query da IP non autorizzati
    // (BIND non risponde affatto, invece di dare REFUSED)
    // blackhole { !reti-interne; any; };
};
```

### 2.3 ACL Cisco per Bloccare Open Resolver (IOS)

Come visto nell'Esercizio A, le ACL Cisco possono bloccare query DNS non autorizzate:

```ios
! Scenario: blocca query DNS in uscita tranne dal DNS interno
ip access-list extended BLOCK-DNS-OUTBOUND
 remark Permetti DNS solo dal server DNS interno
 permit udp host 192.168.1.10 any eq 53
 permit tcp host 192.168.1.10 any eq 53
 remark Blocca DNS da tutti gli altri (previene uso DNS esterno non autorizzato)
 deny   udp 192.168.1.0 0.0.0.255 any eq 53
 deny   tcp 192.168.1.0 0.0.0.255 any eq 53
 remark Permetti tutto il traffico restante
 permit ip any any

! Scenario: blocca accesso al resolver dall'esterno (anti-open-resolver)
ip access-list extended PROTECT-DNS-SERVER
 remark Permetti query DNS solo dalla LAN
 permit udp 192.168.1.0 0.0.0.255 host 192.168.1.10 eq 53
 permit tcp 192.168.1.0 0.0.0.255 host 192.168.1.10 eq 53
 remark Blocca tutto il resto verso il DNS server
 deny   udp any host 192.168.1.10 eq 53
 deny   tcp any host 192.168.1.10 eq 53
 permit ip any any
```

### 2.4 Verifica Open Resolver

```bash
# Test se un server è un open resolver
# (sostituisci 192.168.1.10 con l'IP del resolver da testare)
dig +short test.openresolver.com TXT @192.168.1.10
# Se risponde → open resolver (pericoloso!)
# Se timeout/REFUSED → closed resolver (sicuro)

# Alternativa: query esterna al resolver interno
dig @192.168.1.10 google.com
# Un resolver correttamente configurato dovrebbe rispondere REFUSED
# se la query proviene da fuori la rete autorizzata
```

---

## 3. DNSSEC Validation sul Resolver

### 3.1 Differenza tra "firmare" e "validare"

| Operazione | Chi la fa | Cosa fa |
|-----------|-----------|---------|
| **Firmare** la zona | Server authoritative | Aggiunge RRSIG ai record |
| **Validare** le risposte | Resolver | Verifica le firme RRSIG |

Un resolver DEVE validare le firme per completare la catena di fiducia. Se il resolver non valida, le firme DNSSEC sulle zone authoritative sono inutili per i client.

### 3.2 Abilitare validazione in BIND9

```
options {
    // Validazione automatica con trust anchor dalla root
    dnssec-validation auto;
    
    // Specifica manuale del trust anchor (root DNSKEY):
    // trusted-keys { ... };  // deprecato
    // trust-anchors { . initial-key ... };  // RFC 5011
};
```

### 3.3 Abilitare validazione in Unbound

```
server:
    # Abilita DNSSEC validation
    module-config: "validator iterator"
    
    # Trust anchor automatico (root)
    auto-trust-anchor-file: "/etc/unbound/root.key"
    
    # Aggiorna automaticamente il trust anchor (RFC 5011)
    root-hints: "/etc/unbound/root.hints"
```

### 3.4 Test validazione

```bash
# Test con dominio DNSSEC correttamente firmato
dig @127.0.0.1 cloudflare.com +dnssec
# Deve includere "ad" nei flags

# Test con dominio DNSSEC rotto (verifica che il resolver validi davvero)
dig @127.0.0.1 sigfail.verteiltesysteme.net
# Con validazione abilitata → SERVFAIL
# Senza validazione → risponde normalmente (pericoloso)

# Test dnssec-failed.org (dominio deliberatamente rotto)
dig @127.0.0.1 www.dnssec-failed.org
# Deve restituire SERVFAIL se la validazione funziona
```

---

## 4. Monitoraggio e Alerting

### 4.1 Cosa monitorare

Il monitoraggio del DNS è fondamentale per rilevare attività anomale. I principali indicatori di anomalia:

#### 📊 Volume di query

```bash
# Numero di query al secondo (QPS) insolito
# Baseline tipica aziendale: 10–100 QPS
# Durante un attacco: 10.000+ QPS

# Monitoraggio con BIND9 stats
rndc stats && grep "queries resulted" /var/named/data/named_stats.txt
```

#### 📊 NXDOMAIN Rate

Un alto tasso di risposte NXDOMAIN (dominio inesistente) può indicare:
- **DGA** (*Domain Generation Algorithm*) — malware che genera domini casuali per C2
- **Ricognizione** — scansione DNS di subdomain inesistenti
- **Misconfiguration** — client con configurazione errata

```bash
# Monitoraggio NXDOMAIN in BIND9 (nei log)
grep "NXDOMAIN" /var/log/named/queries.log | \
  awk '{print $NF}' | sort | uniq -c | sort -rn | head -20
```

Soglia di allerta: se la NXDOMAIN rate supera il 20–30% delle query totali.

#### 📊 Query di tipo insolito

| Tipo query | Uso normale | Uso sospetto |
|-----------|------------|-------------|
| `A`, `AAAA`, `MX`, `CNAME` | Navigazione normale | — |
| `TXT` | Verifica SPF/DKIM | Volume alto o payload lungo → tunneling |
| `NULL` | Rarissimo | Quasi sempre tunneling |
| `ANY` | Debug, raramente usato | Volume alto → amplification prep |
| `AXFR` | Trasferimento di zona (tra NS) | Da IP non autorizzato → ricognizione |
| `PTR` (reverse) | Lookup inverso | Molti PTR su range IP → scansione |

#### 📊 Entropia dei nomi di dominio

I malware che usano DGA o DNS tunneling generano nomi di dominio con alta entropia (sembrano casuali):
```
# Alta entropia (sospetto):
xj3k9mq2plw.evil.com
aaabbb123ccc.tunnel.attacker.com

# Bassa entropia (normale):
www.google.com
mail.azienda.it
```

### 4.2 Tool di monitoraggio DNS

#### dnstop (packet capture)
```bash
# Analisi in tempo reale delle query DNS
sudo dnstop -l 1 eth0
# -l 1 = mostra solo query di tipo A
```

#### tcpdump per query DNS
```bash
# Cattura tutto il traffico DNS
sudo tcpdump -i eth0 -n 'port 53' -w dns_capture.pcap

# Analisi in tempo reale (solo query, senza risposte)
sudo tcpdump -i eth0 -n 'udp port 53 and (udp[10] & 0x80) = 0'

# Conta query per dominio
sudo tcpdump -i eth0 -n 'udp port 53' -l | \
  awk '/A\?/ {print $NF}' | sort | uniq -c | sort -rn | head -20
```

#### Elasticsearch + Kibana (ELK Stack)
Per ambienti enterprise, i log DNS vengono inviati a un SIEM (Security Information and Event Management):
1. Abilita query logging su BIND9/Unbound
2. Logstash parsifica i log DNS
3. Elasticsearch indicizza
4. Kibana visualizza dashboard e alert

#### Pi-hole (per piccole reti)
Pi-hole è un **DNS sinkhole** per reti domestiche e piccole aziende:
- Blocca domini pubblicitari e malware noti
- Dashboard web con statistiche query in tempo reale
- Blacklist aggiornabili automaticamente
- Facilmente configurabile su Raspberry Pi

---

## 5. Firewall DNS e Filtraggio per Categoria

### 5.1 DNS Firewall / RPZ (Response Policy Zone)

Il **DNS Firewall** (implementato tramite RPZ in BIND9) permette di bloccare l'accesso a domini malevoli a livello DNS, prima che il client stabilisca una connessione TCP.

```
// Configurazione RPZ in BIND9
options {
    response-policy { zone "rpz.blocklist"; };
};

zone "rpz.blocklist" {
    type master;
    file "/etc/bind/rpz.blocklist.db";
    // Nessun trasferimento di zona all'esterno
    allow-transfer { none; };
};
```

```
// File /etc/bind/rpz.blocklist.db
$TTL 60
@   IN SOA localhost. root.localhost. (1 1h 15m 30d 2m)
@   IN NS localhost.

; Blocca malware.example.com e tutti i suoi subdomain
malware.example.com        CNAME .   ; rende NXDOMAIN
*.malware.example.com      CNAME .

; Reindirizza phishing.example.com verso una pagina di avviso
phishing.example.com       A 192.168.1.100  ; IP del portale di avviso
```

### 5.2 Cisco Umbrella

**Cisco Umbrella** è un servizio DNS cloud-based per la sicurezza enterprise:
- Blocca domini malevoli, phishing, C2 malware a livello DNS
- Categorizzazione di 60+ categorie di contenuti (social, gambling, adulti, ecc.)
- Enforcement a livello di rete (tutti i dispositivi, anche mobili off-network)
- Integrazione con Cisco SecureX, SIEM, directory aziendali
- Visibilità completa su tutte le query DNS dell'organizzazione

Funziona reindirizzando le query DNS verso i resolver Umbrella invece di quelli ISP:
```
# Configurazione semplificata: punta i resolver al servizio Umbrella
DNS Primario: 208.67.222.222
DNS Secondario: 208.67.220.220
```

---

## 6. Segmentazione DNS: DMZ e Separazione Resolver

### 6.1 Architettura sicura del DNS aziendale

```
INTERNET
    │
┌───┴────────────────────────────────────────────────┐
│  FIREWALL ESTERNO                                  │
│  Permette: UDP/TCP 53 in ingresso verso DNS-AUTH   │
│  Blocca: tutto il resto verso la DMZ               │
└───┬────────────────────────────────────────────────┘
    │
┌───┴──────────────────────────────────────────────────┐
│  DMZ                                                 │
│  ┌─────────────────────┐                             │
│  │  DNS-AUTH (authNS)  │ ← risponde a query dal web  │
│  │  (solo authoritative│   per i domini pubblici     │
│  │   per domini pubblici│                            │
│  └─────────────────────┘                             │
└───┬──────────────────────────────────────────────────┘
    │
┌───┴─────────────────────────────────────────────────┐
│  FIREWALL INTERNO                                   │
│  Blocca: query DNS dirette dall'esterno verso intern│
│  Permette: solo DNS-AUTH in DMZ verso DNS interno   │
└───┬─────────────────────────────────────────────────┘
    │
┌───┴─────────────────────────────────────────────────┐
│  RETE INTERNA                                       │
│  ┌──────────────────────┐                           │
│  │  DNS-RESOLVER         │ ← resolver per i client  │
│  │  (ricorsivo, closed)  │   interni                │
│  │  + zona interna       │   + forward a DNS-AUTH   │
│  └──────────────────────┘                           │
│                                                     │
│  PC-1   PC-2   PC-3  ... (usano DNS-RESOLVER)       │
└─────────────────────────────────────────────────────┘
```

### 6.2 Separazione authoritative vs resolver

| Ruolo | Server | Accessibile da | Note |
|-------|--------|---------------|------|
| **Authoritative pubblico** | DNS-AUTH in DMZ | Internet + interno | Risponde per i domini pubblici dell'azienda |
| **Resolver interno** | DNS-RESOLVER in LAN | Solo rete interna | Query ricorsive per i client; forward verso DNS-AUTH per zone interne; forward verso DNS pubblici (8.8.8.8) per Internet |

**Perché separarli?**
- Un attacco al DNS-AUTH (pubblico) non compromette la risoluzione interna
- Il DNS-RESOLVER non è accessibile da Internet → non può essere usato come amplificatore
- Controllo granulare: zone private visibili solo dall'interno

---

## 7. Hardening Checklist del Server DNS

### 7.1 Checklist completa

**🔒 Configurazione di base**
- [ ] Aggiornare BIND9/Unbound/Windows DNS all'ultima versione stabile
- [ ] Disabilitare servizi non necessari sul server DNS
- [ ] Applicare tutti i security patch del sistema operativo
- [ ] Configurare un account non-root per eseguire il servizio DNS (es. `named` su Linux)
- [ ] Abilitare chroot jail per BIND9 (`/var/named/chroot/`)

**🔒 Controllo accessi**
- [ ] Configurare `allow-query` per permettere solo IP autorizzati
- [ ] Configurare `allow-recursion` (solo rete interna)
- [ ] Configurare `allow-transfer` (solo server DNS secondari autorizzati)
- [ ] Disabilitare zone transfer verso IP non autorizzati
- [ ] Blacklistare IP noti malevoli con `blackhole`

**🔒 Funzionalità**
- [ ] Abilitare RRL con parametri appropriati
- [ ] Abilitare DNSSEC validation (`dnssec-validation auto`)
- [ ] Configurare RPZ con blacklist aggiornata (se applicabile)
- [ ] Disabilitare query di tipo ANY o limitarle con RRL

**🔒 Logging**
- [ ] Abilitare il logging delle query DNS
- [ ] Configurare log rotation (evitare riempimento disco)
- [ ] Inviare i log a un SIEM centralizzato
- [ ] Configurare alert per NXDOMAIN rate anomala, volume query anomalo

**🔒 Rete**
- [ ] Server DNS in zona di rete segregata (DMZ o VLAN dedicata)
- [ ] Firewall: permetti solo UDP/TCP 53 da IP autorizzati
- [ ] Firewall: blocca accesso SSH al DNS server da reti non gestione
- [ ] Configurare fail2ban o equivalente per tentativi di accesso non autorizzati

**🔒 Alta disponibilità**
- [ ] Configurare DNS secondario (almeno 2 server totali)
- [ ] Trasferimento di zona automatico tra primario e secondario
- [ ] Monitoraggio uptime del servizio DNS (Nagios, Zabbix, Prometheus)
- [ ] Procedura documentata per failover manuale

**🔒 DNSSEC (se gestisce zone pubbliche)**
- [ ] Zone firmate con ZSK e KSK
- [ ] DS record pubblicati nella zona padre (registro TLD)
- [ ] Rotazione ZSK automatizzata (ogni 1–3 mesi)
- [ ] Monitoraggio scadenza RRSIG (alert almeno 7 giorni prima)

---

## 8. Incident Response per Attacchi DNS

### 8.1 Rilevamento dell'incidente

**Segnali di allerta**:
```
⚠️  Utenti segnalano reindirizzamenti verso siti sconosciuti
⚠️  Alert del SIEM per volume DNS anomalo
⚠️  Certificati SSL non validi su siti normalmente affidabili
⚠️  nslookup restituisce IP diversi da quelli attesi
⚠️  Latenza DNS aumentata notevolmente
⚠️  Log DNS mostrano alto NXDOMAIN rate
```

### 8.2 Piano di risposta passo per passo

#### 🔴 FASE 1 — Rilevamento e Conferma (0–15 minuti)

```bash
# Passo 1: Verificare se le risposte DNS sono corrette
dig www.azienda.com @resolver_interno
dig www.azienda.com @8.8.8.8
# Confronta: se diversi → possibile cache poisoning

# Passo 2: Verificare da un secondo resolver non potenzialmente compromesso
dig www.azienda.com @1.1.1.1
dig www.azienda.com @9.9.9.9

# Passo 3: Controllare DNSSEC (se abilitato)
dig +dnssec www.azienda.com @resolver_interno
# SERVFAIL con dnssec → resolver non riesce a validare

# Passo 4: Controllare i log del resolver
tail -f /var/log/named/queries.log | grep "suspicious_domain"
```

#### 🟠 FASE 2 — Contenimento (15–60 minuti)

```bash
# Passo 5: Svuotare la cache del resolver compromesso
rndc flush                      # BIND9: svuota tutta la cache
rndc flushname www.malware.com  # BIND9: svuota solo un nome specifico
unbound-control flush_zone .    # Unbound: svuota tutta la cache

# Passo 6: Se il resolver è compromesso, isolarlo
# - Disabilita il servizio sul server compromesso
# - Reindirizza i client al DNS secondario (modifica DHCP)
# - Blocca accesso al resolver compromesso via firewall

# Passo 7: Comunicazione interna
# - Notifica il team IT e il CISO
# - Avverti gli utenti di non inserire credenziali
```

#### 🟡 FASE 3 — Analisi (1–4 ore)

```bash
# Passo 8: Analisi dei log per scope dell'impatto
grep "FORMERR\|SERVFAIL\|REFUSED" /var/log/named/queries.log | wc -l
grep "suspicious_domain" /var/log/named/queries.log

# Passo 9: Identificare record corrotti in cache
# (dump della cache del resolver)
rndc dumpdb -cache
cat /var/named/data/cache_dump.db | grep -v "^;" | head -100

# Passo 10: Identificare chi ha eseguito la query ai record corrotti
# (correlazione log DNS con log firewall/proxy)
```

#### 🟢 FASE 4 — Ripristino (4–24 ore)

```bash
# Passo 11: Ripristino del resolver
# - Reinstallazione/reset configurazione se compromesso
# - Reimportazione configurazione da backup verificato

# Passo 12: Riduzione TTL temporanea (per propagazione rapida)
# Nel file di zona, riduce TTL a 300 secondi:
# $TTL 300

# Passo 13: Verifica completa post-ripristino
dig +dnssec www.azienda.com @resolver_ripristinato
# Deve rispondere con IP corretto e flag "ad"

# Passo 14: Comunicazione agli utenti
# - Conferma risoluzione incidente
# - Istruzioni per svuotare cache DNS locale dei PC
ipconfig /flushdns          # Windows
sudo systemd-resolve --flush-caches  # Linux
sudo dscacheutil -flushcache         # macOS
```

#### 📋 FASE 5 — Post-Incident (1–7 giorni)

- **Root Cause Analysis**: come è avvenuto l'attacco? Vulnerabilità sfruttata?
- **Documentazione**: timeline dell'incidente, azioni intraprese, impatto stimato
- **Miglioramenti**: quali controlli avrebbero rilevato prima l'attacco?
- **Aggiornamento procedure**: aggiornare il piano di incident response
- **Training**: formazione del team sulle nuove misure
- **Notifiche legali**: se richiesto (GDPR Art. 33 — notifica entro 72h se dati personali coinvolti)

### 8.3 Checklist di Incident Response

| Fase | Azione | Responsabile | Completato |
|------|--------|-------------|------------|
| Rilevamento | Conferma anomalia DNS | SOC / IT | ☐ |
| Rilevamento | Identifica scope impatto | SOC | ☐ |
| Contenimento | Flush cache resolver | DNS Admin | ☐ |
| Contenimento | Notifica CISO/Management | IT Manager | ☐ |
| Contenimento | Isola resolver compromesso | Network Admin | ☐ |
| Analisi | Analisi log DNS | SOC | ☐ |
| Analisi | Identifica vettore attacco | Security Analyst | ☐ |
| Ripristino | Ripristina resolver | DNS Admin | ☐ |
| Ripristino | Verifica funzionamento | IT | ☐ |
| Ripristino | Comunica agli utenti | IT Manager | ☐ |
| Post-Incident | Root Cause Analysis | Security Analyst | ☐ |
| Post-Incident | Aggiorna procedure | CISO | ☐ |
| Post-Incident | Notifiche legali (se richiesto) | DPO / Legal | ☐ |

---

## 9. Riepilogo: Mappa delle Difese DNS

| Minaccia | Difesa primaria | Difesa secondaria | Rilevamento |
|----------|----------------|-------------------|-------------|
| **Cache Poisoning** | DNSSEC validation | Source port randomization | Log anomalie, confronto resolver |
| **DNS Spoofing** | DNSSEC | HTTPS (cert validation) | MITM detection |
| **DNS Hijacking locale** | EDR/antimalware | Monitoraggio file hosts | Log modifche sistema |
| **DNS Hijacking router** | Hardening router, 2FA | VLAN, segmentazione | Monitoraggio gateway DNS |
| **Amplification DDoS** | Closed resolver | RRL, BCP38 (anti-spoofing) | QPS anomalo |
| **DNS Tunneling** | DNS inspection (DPI) | Blocco query tipo NULL/TXT anomale | Alto entropia nomi, volume TXT |
| **Open Resolver abuse** | ACL `allow-recursion` | Firewall perimetrale | Query da IP esterni |
| **Zone enumeration** | NSEC3 invece di NSEC | Zone transfer ACL | Molti query AXFR |
| **DGA malware** | RPZ blacklist | Threat intelligence feed | Alto NXDOMAIN rate |
