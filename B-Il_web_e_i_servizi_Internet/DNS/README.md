# Guida Completa al DNS (Domain Name System)

## Indice

1. [Introduzione al DNS](#introduzione-al-dns)
2. [Storia e Evoluzione](#storia-e-evoluzione)
3. [Architettura del DNS](#architettura-del-dns)
4. [Componenti del Sistema DNS](#componenti-del-sistema-dns)
5. [Tipi di Record DNS](#tipi-di-record-dns)
6. [Funzionamento del DNS](#funzionamento-del-dns)
7. [Gerarchia DNS](#gerarchia-dns)
8. [Server DNS](#server-dns)
9. [Processo di Risoluzione DNS](#processo-di-risoluzione-dns)
10. [Cache DNS](#cache-dns)
11. [DNS e Sicurezza](#dns-e-sicurezza)
12. [Configurazione DNS](#configurazione-dns)
13. [Troubleshooting DNS](#troubleshooting-dns)
14. [DNS Moderno e Tendenze Future](#dns-moderno-e-tendenze-future)
15. [Esercitazioni Pratiche](#esercitazioni-pratiche)

---

## Introduzione al DNS

### Cos'è il DNS?

Il **DNS (Domain Name System)** è un sistema distribuito gerarchico che traduce i nomi di dominio leggibili dagli esseri umani (come `www.example.com`) in indirizzi IP numerici (come `192.0.2.1`) che i computer utilizzano per identificarsi sulla rete.

Il DNS è spesso definito come la "rubrica telefonica di Internet" perché permette agli utenti di accedere ai siti web usando nomi facili da ricordare invece di sequenze numeriche complesse.

### Perché il DNS è Importante?

- **Usabilità**: È più facile ricordare `google.com` che `142.250.185.46`
- **Flessibilità**: Permette di cambiare server senza modificare il nome di dominio
- **Ridondanza**: Supporta più indirizzi IP per lo stesso dominio
- **Distribuzione del carico**: Consente il bilanciamento del traffico
- **Organizzazione**: Struttura gerarchica logica di Internet

### Problema Risolto dal DNS

Prima del DNS (fino al 1983), le corrispondenze nome-indirizzo erano gestite tramite un file chiamato `HOSTS.TXT`, mantenuto centralmente e distribuito a tutti i computer. Questo sistema non era scalabile con la crescita di Internet.

---

## Storia e Evoluzione

### Timeline Storica

- **1969**: ARPANET, il precursore di Internet, viene creato
- **1970s**: Uso del file HOSTS.TXT per la risoluzione dei nomi
- **1983**: Paul Mockapetris inventa il DNS (RFC 882 e RFC 883)
- **1987**: RFC 1034 e RFC 1035 definiscono lo standard DNS moderno
- **1990s**: Esplosione di Internet e crescita esponenziale del DNS
- **1999**: Introduzione di DNSSEC per la sicurezza
- **2013**: DNS over TLS (DoT) proposto
- **2018**: DNS over HTTPS (DoH) standardizzato
- **2020+**: Adozione diffusa di protocolli DNS sicuri

### Evoluzione delle Specifiche

Le RFC (Request for Comments) principali che definiscono il DNS:

- **RFC 1034**: Domain Names - Concepts and Facilities
- **RFC 1035**: Domain Names - Implementation and Specification
- **RFC 4033-4035**: DNSSEC (DNS Security Extensions)
- **RFC 7858**: DNS over TLS
- **RFC 8484**: DNS over HTTPS

---

## Architettura del DNS

### Caratteristiche Principali

1. **Distribuito**: Nessun singolo server contiene tutto il database DNS
2. **Gerarchico**: Organizzato in una struttura ad albero
3. **Decentralizzato**: Gestito da diverse organizzazioni
4. **Scalabile**: Può gestire miliardi di nomi di dominio
5. **Ridondante**: Multiple copie dei dati per affidabilità

### Struttura Gerarchica

```
                          . (root)
                          |
         +----------------+----------------+
         |                |                |
       com              org              net
         |                |                |
    +----+----+      +----+----+      +----+----+
    |         |      |         |      |         |
 google   amazon  wikipedia mozilla  ...     ...
    |
    +----+----+
    |         |
   www      mail
```

### Namespace DNS

Il namespace DNS è l'insieme di tutti i possibili nomi di dominio, organizzato in una gerarchia ad albero invertito con la root (radice) in cima.

---

## Componenti del Sistema DNS

### 1. Name Space (Spazio dei Nomi)

Lo spazio dei nomi DNS è diviso in **zone**, ciascuna gestita autonomamente.

### 2. Name Servers (Server dei Nomi)

Programmi server che memorizzano informazioni sulla struttura del namespace e rispondono alle query.

Tipi di Name Server:

- **Authoritative Name Server**: Contiene i dati ufficiali per una zona
- **Recursive Name Server**: Esegue query ricorsive per conto dei client
- **Root Name Server**: Server di livello più alto nella gerarchia
- **TLD Name Server**: Server per i domini di primo livello (.com, .org, etc.)

### 3. Resolver

Programma client che genera query DNS per conto delle applicazioni.

Tipi di Resolver:

- **Stub Resolver**: Resolver semplice che delega la risoluzione a un recursive server
- **Recursive Resolver**: Resolver completo che esegue l'intero processo di risoluzione

---

## Tipi di Record DNS

I record DNS sono le informazioni memorizzate nei name server. Ogni record ha:
- **Nome**: Il dominio a cui si riferisce
- **TTL (Time To Live)**: Quanto tempo il record può essere memorizzato in cache
- **Classe**: Solitamente IN (Internet)
- **Tipo**: Il tipo di record
- **Valore**: I dati del record

### Record Principali

#### A (Address Record)
```
example.com.    3600    IN    A    192.0.2.1
```
- **Funzione**: Associa un nome di dominio a un indirizzo IPv4
- **Utilizzo**: Mappatura base dominio-IP

#### AAAA (IPv6 Address Record)
```
example.com.    3600    IN    AAAA    2001:0db8::1
```
- **Funzione**: Associa un nome di dominio a un indirizzo IPv6
- **Utilizzo**: Supporto IPv6

#### CNAME (Canonical Name Record)
```
www.example.com.    3600    IN    CNAME    example.com.
```
- **Funzione**: Crea un alias per un altro nome di dominio
- **Utilizzo**: Redirect, sottodomini
- **Limitazione**: Non può coesistere con altri record per lo stesso nome

#### MX (Mail Exchange Record)
```
example.com.    3600    IN    MX    10 mail.example.com.
```
- **Funzione**: Specifica i server di posta per il dominio
- **Priorità**: Il numero (10) indica la priorità (più basso = più priorità)
- **Utilizzo**: Routing email

#### TXT (Text Record)
```
example.com.    3600    IN    TXT    "v=spf1 include:_spf.google.com ~all"
```
- **Funzione**: Contiene testo arbitrario
- **Utilizzo**: Verifica dominio, SPF, DKIM, DMARC

#### NS (Name Server Record)
```
example.com.    3600    IN    NS    ns1.example.com.
```
- **Funzione**: Indica i name server autorevoli per la zona
- **Utilizzo**: Delegazione di zone

#### SOA (Start of Authority Record)
```
example.com.    3600    IN    SOA    ns1.example.com. admin.example.com. (
                                    2024012901  ; Serial
                                    3600        ; Refresh
                                    1800        ; Retry
                                    604800      ; Expire
                                    86400 )     ; Minimum TTL
```
- **Funzione**: Contiene informazioni amministrative sulla zona
- **Campi**: Server primario, email amministratore, parametri di zona

#### PTR (Pointer Record)
```
1.2.0.192.in-addr.arpa.    3600    IN    PTR    example.com.
```
- **Funzione**: Risoluzione inversa (IP → nome)
- **Utilizzo**: Verifica identità server, anti-spam

#### SRV (Service Record)
```
_http._tcp.example.com.    3600    IN    SRV    10 60 80 www.example.com.
```
- **Funzione**: Specifica la posizione di servizi
- **Parametri**: Priorità, peso, porta, target
- **Utilizzo**: VoIP, messaggistica istantanea

#### CAA (Certification Authority Authorization)
```
example.com.    3600    IN    CAA    0 issue "letsencrypt.org"
```
- **Funzione**: Specifica quali CA possono emettere certificati
- **Utilizzo**: Sicurezza SSL/TLS

### Record Meno Comuni

- **HINFO**: Informazioni sull'hardware/OS
- **NAPTR**: Name Authority Pointer (URI mapping)
- **TLSA**: TLS Authentication (DANE)
- **SSHFP**: SSH Fingerprint
- **DNSKEY**: Chiave pubblica DNSSEC
- **DS**: Delegation Signer (DNSSEC)
- **RRSIG**: Firma digitale DNSSEC

---

## Funzionamento del DNS

### Query DNS

Una query DNS è una richiesta di informazioni inviata a un name server.

#### Tipi di Query

1. **Query Ricorsiva**
   - Il client chiede al server di fornire la risposta completa
   - Il server esegue tutte le ricerche necessarie
   - Utilizzata dai client verso i resolver

2. **Query Iterativa**
   - Il server risponde con il miglior riferimento che ha
   - Il client deve continuare la ricerca
   - Utilizzata tra server DNS

3. **Query Inversa**
   - Risolve un indirizzo IP in un nome di dominio
   - Usa il dominio speciale `.in-addr.arpa` (IPv4) o `.ip6.arpa` (IPv6)

#### Formato della Query

Una query DNS contiene:
- **Header**: ID, flags, contatori
- **Question Section**: Nome interrogato, tipo, classe
- **Answer Section**: Risposta (vuota nella query)
- **Authority Section**: Server autorevoli
- **Additional Section**: Informazioni aggiuntive

---

## Gerarchia DNS

### Root Zone (Zona Radice)

- Simbolo: `.` (punto)
- **13 gruppi** di root server (A-M) distribuiti globalmente tramite anycast
- Gestiti da diverse organizzazioni (ICANN, Verisign, NASA, etc.)
- Rispondono con riferimenti ai TLD server

#### Root Server

```
a.root-servers.net    198.41.0.4        Verisign
b.root-servers.net    199.9.14.201      USC-ISI
c.root-servers.net    192.33.4.12       Cogent
d.root-servers.net    199.7.91.13       University of Maryland
e.root-servers.net    192.203.230.10    NASA
f.root-servers.net    192.5.5.241       ISC
g.root-servers.net    192.112.36.4      DISA
h.root-servers.net    198.97.190.53     ARL
i.root-servers.net    192.36.148.17     Netnod
j.root-servers.net    192.58.128.30     Verisign
k.root-servers.net    193.0.14.129      RIPE NCC
l.root-servers.net    199.7.83.42       ICANN
m.root-servers.net    202.12.27.33      WIDE
```

### TLD (Top-Level Domain)

#### Generic TLD (gTLD)
- `.com` - commerciale
- `.org` - organizzazioni
- `.net` - network
- `.edu` - educazione
- `.gov` - governo USA
- `.mil` - militare USA
- `.int` - organizzazioni internazionali
- Nuovi gTLD: `.app`, `.dev`, `.blog`, etc.

#### Country Code TLD (ccTLD)
- `.it` - Italia
- `.uk` - Regno Unito
- `.de` - Germania
- `.fr` - Francia
- `.jp` - Giappone
- `.cn` - Cina
- Oltre 250 ccTLD esistenti

#### Infrastructure TLD
- `.arpa` - Address and Routing Parameter Area

### Second-Level Domain (SLD)

Dominio registrato sotto un TLD:
- `example.com` (example è il SLD)
- `google.it` (google è il SLD)

### Subdomain (Sottodominio)

Domini sotto un SLD:
- `www.example.com`
- `mail.example.com`
- `blog.subdomain.example.com`

### FQDN (Fully Qualified Domain Name)

Nome di dominio completo che specifica la posizione esatta nell'albero DNS:
```
www.example.com.
|   |       |   |
|   |       |   +-- Root (implicito se omesso)
|   |       +------ TLD
|   +-------------- SLD
+------------------ Subdomain
```

---

## Server DNS

### Tipologie di Server

#### 1. Authoritative Name Server

Server che contiene i dati ufficiali per una o più zone DNS.

**Caratteristiche:**
- Risponde con dati autorevoli
- Non esegue recursion
- Ha il bit AA (Authoritative Answer) impostato nelle risposte

**Tipi:**
- **Primary (Master)**: Contiene la copia master della zona
- **Secondary (Slave)**: Contiene copie sincronizzate dalla primary

#### 2. Recursive Resolver

Server che esegue l'intero processo di risoluzione per conto dei client.

**Caratteristiche:**
- Accetta query ricorsive
- Interroga altri server
- Mantiene una cache
- Utilizzato dagli end user

**Provider Pubblici:**
- Google: `8.8.8.8`, `8.8.4.4`
- Cloudflare: `1.1.1.1`, `1.0.0.1`
- Quad9: `9.9.9.9`
- OpenDNS: `208.67.222.222`, `208.67.220.220`

#### 3. Forwarding Server

Server DNS che inoltra le query a un altro resolver.

**Utilizzo:**
- Reti aziendali
- Caching centralizzato
- Controllo del traffico

#### 4. Root Name Server

Server di livello più alto nella gerarchia DNS.

#### 5. TLD Name Server

Server che gestiscono i domini di primo livello.

### Software DNS Popolari

#### BIND (Berkeley Internet Name Domain)
- Il più diffuso
- Open source
- Piena compatibilità RFC
- Complesso da configurare

#### PowerDNS
- Open source
- Backend flessibile (MySQL, PostgreSQL, etc.)
- Alta performance

#### Unbound
- Validating, recursive, caching resolver
- Focus sulla sicurezza
- Leggero e veloce

#### dnsmasq
- Leggero
- Per reti piccole
- Integra DHCP e DNS

#### Microsoft DNS Server
- Integrato in Windows Server
- Active Directory integration
- GUI-based management

#### NSD (Name Server Daemon)
- Authoritative only
- Alta performance
- Sviluppato da NLnet Labs

---

## Processo di Risoluzione DNS

### Risoluzione Step-by-Step

Esempio: Risoluzione di `www.example.com`

```
Client                Recursive       Root          TLD           Authoritative
  |                    Resolver       Server       Server           Server
  |                       |              |            |                |
  |-- Query www.ex.com -->|              |            |                |
  |                       |              |            |                |
  |                       |-- Query ---> |            |                |
  |                       | <-- .com NS -|            |                |
  |                       |              |            |                |
  |                       |------- Query -----------> |                |
  |                       | <--- example.com NS ----- |                |
  |                       |              |            |                |
  |                       |----------------------- Query ------------> |
  |                       | <----------------- Answer ---------------- |
  |                       |              |            |                |
  | <-- Answer -----------|              |            |                |
  |                       |              |            |                |
```

### Descrizione Dettagliata

1. **Client Query**
   - L'utente digita `www.example.com` nel browser
   - Il browser controlla la cache locale
   - Se non trovato, invia query al resolver configurato

2. **Recursive Resolver Check**
   - Il resolver controlla la propria cache
   - Se non trovato, inizia la risoluzione ricorsiva

3. **Root Server Query**
   - Il resolver interroga un root server
   - Root server risponde con i name server per `.com`

4. **TLD Server Query**
   - Il resolver interroga il TLD server per `.com`
   - TLD server risponde con i name server per `example.com`

5. **Authoritative Server Query**
   - Il resolver interroga il name server autorevole per `example.com`
   - Authoritative server risponde con l'indirizzo IP di `www.example.com`

6. **Response to Client**
   - Il resolver memorizza la risposta in cache
   - Restituisce l'IP al client
   - Il client può ora connettersi al server web

### Tipi di Risposte

- **Authoritative Answer**: Risposta da un server autorevole
- **Non-Authoritative Answer**: Risposta da cache
- **NXDOMAIN**: Il dominio non esiste
- **SERVFAIL**: Errore del server
- **REFUSED**: Query rifiutata

---

## Cache DNS

### Cos'è la Cache DNS?

La cache DNS memorizza temporaneamente le risposte DNS per ridurre il traffico e migliorare le prestazioni.

### Livelli di Cache

1. **Browser Cache**
   - Cache interna del browser
   - TTL tipicamente breve (1-10 minuti)

2. **OS Cache**
   - Cache del sistema operativo
   - Servizio locale (systemd-resolved, nscd, etc.)

3. **Recursive Resolver Cache**
   - Cache del resolver DNS
   - Rispetta il TTL dei record

4. **ISP Cache**
   - Cache del provider Internet

### TTL (Time To Live)

Il TTL specifica per quanto tempo un record può essere memorizzato in cache:

```
example.com.    300    IN    A    192.0.2.1
                ^^^
                TTL in secondi (5 minuti)
```

**Valori Tipici:**
- Record stabili: 86400 (24 ore)
- Record normali: 3600 (1 ora)
- Record in modifica: 300 (5 minuti)
- Record dinamici: 60 (1 minuto)

### Gestione della Cache

#### Visualizzare la Cache

```bash
# Linux (systemd-resolved)
sudo systemd-resolve --statistics

# Windows
ipconfig /displaydns
```

#### Svuotare la Cache

```bash
# Linux (systemd-resolved)
sudo systemd-resolve --flush-caches

# Linux (nscd)
sudo /etc/init.d/nscd restart

# macOS
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Windows
ipconfig /flushdns
```

### Negative Caching

Anche le risposte negative (NXDOMAIN) vengono memorizzate in cache per evitare query ripetute:

```
# SOA record definisce il negative caching TTL
example.com.    IN    SOA    ns1.example.com. admin.example.com. (
                              2024012901
                              3600
                              1800
                              604800
                              300 )    ; <-- Negative cache TTL
```

---

## DNS e Sicurezza

### Minacce DNS

#### 1. DNS Spoofing (Cache Poisoning)

Attacco che inserisce dati falsi nella cache DNS:

```
Attacker  -->  [Fake Response]  -->  Resolver Cache
                                         |
User      <--  [Poisoned Data]   <-------+
```

**Mitigazioni:**
- DNSSEC
- Randomizzazione porta sorgente
- Query ID randomization
- 0x20 encoding

#### 2. DNS Hijacking

Reindirizzamento delle query DNS verso server malevoli:

- Modifica configurazione router
- Malware che modifica DNS settings
- Man-in-the-middle attacks

#### 3. DDoS Attacks

**DNS Amplification Attack:**
```
Attacker --> [Spoofed small query] --> Open Resolver
                                            |
Target   <-- [Large response] <-------------+
```

**Mitigazioni:**
- Rate limiting
- Response Rate Limiting (RRL)
- BCP 38 (ingress filtering)
- Anycast

#### 4. DNS Tunneling

Uso del DNS per esfiltrare dati o creare canali C&C:

```
data.encoded.in.subdomain.attacker.com
     ^^^^^^^^^^^^^^^^^^^^^
     Dati nascosti nel nome
```

**Rilevamento:**
- Analisi anomalie query
- Lunghezza nomi dominio
- Frequenza query

### DNSSEC (DNS Security Extensions)

#### Cos'è DNSSEC?

Estensione del DNS che aggiunge autenticazione e integrità mediante firma digitale:

- **Non cripta** i dati
- **Autentica** la fonte
- **Verifica l'integrità** dei dati

#### Come Funziona

1. **Firma dei Record**
   - Zone firmata con chiave privata (ZSK)
   - Genera record RRSIG

2. **Chain of Trust**
   - Ogni livello firma il successivo
   - Root → TLD → SLD → Subdomain

3. **Validazione**
   - Il resolver verifica le firme
   - Controlla la chain of trust

#### Record DNSSEC

- **DNSKEY**: Chiave pubblica per verificare firme
- **RRSIG**: Firma digitale dei record
- **DS**: Delegation Signer (hash della chiave del figlio)
- **NSEC/NSEC3**: Prova di non esistenza autenticata

#### Configurazione DNSSEC

```bash
# Generare chiavi
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com

# Firmare zona
dnssec-signzone -o example.com example.com.zone

# Verificare
dig +dnssec example.com
```

### DNS over HTTPS (DoH)

Incanala query DNS attraverso HTTPS per privacy e sicurezza:

**Vantaggi:**
- Crittografia end-to-end
- Previene intercettazione ISP
- Bypassa censura DNS

**Svantaggi:**
- Complica il filtraggio aziendale
- Centralizzazione verso pochi provider

**Provider DoH:**
```
Cloudflare: https://cloudflare-dns.com/dns-query
Google:     https://dns.google/dns-query
Quad9:      https://dns.quad9.net/dns-query
```

### DNS over TLS (DoT)

Simile a DoH ma usa TLS diretto sulla porta 853:

```bash
# Configurazione Unbound per DoT
forward-zone:
    name: "."
    forward-tls-upstream: yes
    forward-addr: 1.1.1.1@853
```

### Best Practices di Sicurezza

1. **Utilizzare DNSSEC** quando possibile
2. **Aggiornare software DNS** regolarmente
3. **Disabilitare recursion** sui server autorevoli
4. **Implementare rate limiting**
5. **Monitorare query anomale**
6. **Usare DNS sicuri** (DoH/DoT)
7. **Separare resolver da authoritative server**
8. **Implementare ACL** appropriate
9. **Log e audit** delle query
10. **Backup regolari** delle zone

---

## Configurazione DNS

### File di Zona DNS

Esempio di file di zona per `example.com`:

```dns
$TTL 3600
$ORIGIN example.com.

; SOA Record
@       IN      SOA     ns1.example.com. admin.example.com. (
                        2024012901  ; Serial (YYYYMMDDNN)
                        3600        ; Refresh (1 hour)
                        1800        ; Retry (30 minutes)
                        604800      ; Expire (1 week)
                        300 )       ; Negative Cache TTL (5 minutes)

; Name Servers
        IN      NS      ns1.example.com.
        IN      NS      ns2.example.com.

; Mail Servers
        IN      MX      10 mail1.example.com.
        IN      MX      20 mail2.example.com.

; A Records
@       IN      A       192.0.2.1
www     IN      A       192.0.2.1
mail1   IN      A       192.0.2.10
mail2   IN      A       192.0.2.11
ns1     IN      A       192.0.2.2
ns2     IN      A       192.0.2.3
ftp     IN      A       192.0.2.20

; AAAA Records (IPv6)
@       IN      AAAA    2001:db8::1
www     IN      AAAA    2001:db8::1

; CNAME Records
blog    IN      CNAME   www.example.com.
shop    IN      CNAME   www.example.com.

; TXT Records
@       IN      TXT     "v=spf1 mx ~all"
_dmarc  IN      TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

; SRV Records
_sip._tcp       IN      SRV     10 60 5060 sipserver.example.com.

; CAA Record
@       IN      CAA     0 issue "letsencrypt.org"
```

### Configurazione BIND

#### named.conf

```bind
options {
    directory "/var/named";
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    
    allow-query { any; };
    recursion no;  // Disabilitato per authoritative server
    
    dnssec-enable yes;
    dnssec-validation yes;
    
    version "not available";  // Security by obscurity
};

// Root hints
zone "." IN {
    type hint;
    file "named.ca";
};

// Localhost zones
zone "localhost" IN {
    type master;
    file "localhost.zone";
};

zone "0.0.127.in-addr.arpa" IN {
    type master;
    file "localhost.rev";
};

// Example zone
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-transfer { 192.0.2.3; };  // Secondary server
    notify yes;
};

// Reverse zone
zone "2.0.192.in-addr.arpa" IN {
    type master;
    file "192.0.2.rev";
};
```

### Configurazione Client

#### Linux - /etc/resolv.conf

```bash
# Static DNS servers
nameserver 8.8.8.8
nameserver 8.8.4.4
search example.com
options timeout:2 attempts:5
```

#### Linux - systemd-resolved

```bash
# /etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1
Domains=example.com
DNSSEC=yes
DNSOverTLS=yes
```

#### Windows

```powershell
# PowerShell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses ("8.8.8.8","8.8.4.4")

# CMD
netsh interface ip set dns "Ethernet" static 8.8.8.8
netsh interface ip add dns "Ethernet" 8.8.4.4 index=2
```

#### macOS

```bash
# /etc/resolver/example.com
nameserver 8.8.8.8
nameserver 8.8.4.4
domain example.com
search example.com
```

---

## Troubleshooting DNS

### Strumenti di Diagnosi

#### 1. nslookup

```bash
# Query base
nslookup www.example.com

# Specificare server DNS
nslookup www.example.com 8.8.8.8

# Query specifica tipo record
nslookup -type=MX example.com

# Query inversa
nslookup 192.0.2.1

# Modalità interattiva
nslookup
> server 8.8.8.8
> set type=ANY
> example.com
```

#### 2. dig (Domain Information Groper)

```bash
# Query base
dig www.example.com

# Query specifica
dig @8.8.8.8 www.example.com A

# Query tutti i record
dig example.com ANY

# Query inversa
dig -x 192.0.2.1

# Trace completo
dig +trace www.example.com

# Query breve
dig +short www.example.com

# DNSSEC validation
dig +dnssec example.com

# Query specifica record type
dig example.com MX
dig example.com NS
dig example.com TXT
dig example.com SOA
```

#### 3. host

```bash
# Query base
host www.example.com

# Server specifico
host www.example.com 8.8.8.8

# Tipo specifico
host -t MX example.com

# Verbose
host -v example.com
```

#### 4. drill

```bash
# Query base
drill www.example.com

# Trace
drill -T www.example.com

# DNSSEC
drill -D example.com
```

#### 5. whois

```bash
# Informazioni dominio
whois example.com

# Server specifico
whois -h whois.verisign-grs.com example.com
```

### Problemi Comuni e Soluzioni

#### 1. NXDOMAIN (Domain Not Found)

**Sintomi:**
```
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN
```

**Cause:**
- Dominio inesistente
- Errore di digitazione
- Dominio scaduto
- Propagazione DNS non completata

**Soluzioni:**
- Verificare spelling
- Controllare registrazione dominio
- Attendere propagazione (24-48 ore)

#### 2. SERVFAIL (Server Failure)

**Sintomi:**
```
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL
```

**Cause:**
- Misconfiguration del server DNS
- DNSSEC validation failure
- Network issues

**Soluzioni:**
```bash
# Testare server diverso
dig @8.8.8.8 example.com

# Disabilitare DNSSEC validation
dig +cd example.com

# Controllare logs server
tail -f /var/log/named/named.log
```

#### 3. Timeout

**Sintomi:**
```
;; connection timed out; no servers could be reached
```

**Cause:**
- Firewall blocca porta 53
- Server DNS non raggiungibile
- Network issues

**Soluzioni:**
```bash
# Testare connettività
ping 8.8.8.8
telnet 8.8.8.8 53

# Controllare firewall
sudo iptables -L -n | grep 53
sudo ufw status

# Traceroute
traceroute 8.8.8.8
```

#### 4. Slow DNS Resolution

**Sintomi:**
- Navigazione lenta
- Timeout intermittenti

**Cause:**
- Server DNS sovraccarico
- TTL troppo basso
- Network latency

**Soluzioni:**
```bash
# Misurare tempo di risposta
time dig example.com

# Testare server diversi
dig @1.1.1.1 example.com
dig @8.8.8.8 example.com

# Usare server più vicini
# Configurare caching locale (dnsmasq, unbound)
```

#### 5. Cache Poisoning/Stale Data

**Sintomi:**
- Record obsoleti
- IP errati

**Soluzioni:**
```bash
# Flush cache client
sudo systemd-resolve --flush-caches  # Linux
ipconfig /flushdns                     # Windows
sudo dscacheutil -flushcache          # macOS

# Query diretta al authoritative server
dig @ns1.example.com example.com

# Verificare TTL
dig example.com | grep "IN"
```

### Monitoraggio DNS

#### Script di Monitoraggio

```bash
#!/bin/bash
# dns_monitor.sh

DOMAIN="example.com"
EXPECTED_IP="192.0.2.1"
DNS_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9")

for DNS in "${DNS_SERVERS[@]}"; do
    RESULT=$(dig @${DNS} +short ${DOMAIN} | head -n1)
    
    if [ "$RESULT" == "$EXPECTED_IP" ]; then
        echo "[OK] ${DNS}: ${RESULT}"
    else
        echo "[FAIL] ${DNS}: Expected ${EXPECTED_IP}, got ${RESULT}"
    fi
done
```

#### Health Check

```bash
# Controllare status server
systemctl status named  # Linux
sc query DNS            # Windows

# Controllare logs
journalctl -u named -f
tail -f /var/log/named/named.log

# Statistiche
rndc stats
rndc status
```

---

## DNS Moderno e Tendenze Future

### Encrypted DNS

#### DNS over HTTPS (DoH) - RFC 8484

```bash
# Test DoH con curl
curl -H 'accept: application/dns-json' \
  'https://cloudflare-dns.com/dns-query?name=example.com&type=A'
```

#### DNS over TLS (DoT) - RFC 7858

```bash
# Test DoT con kdig
kdig -d @1.1.1.1 +tls-ca +tls-host=cloudflare-dns.com example.com
```

#### DNS over QUIC (DoQ) - RFC 9250

Nuovo protocollo basato su QUIC/HTTP3 per DNS.

### Split-Horizon DNS

DNS diverso per client interni ed esterni:

```
Internal Client  -->  Internal View  --> internal.example.com = 10.0.0.1
External Client  -->  External View  --> example.com = 192.0.2.1
```

### GeoDNS

Risposte DNS basate sulla posizione geografica del client:

```
US Client  --> CDN US     --> 192.0.2.1
EU Client  --> CDN Europe --> 198.51.100.1
AS Client  --> CDN Asia   --> 203.0.113.1
```

### Dynamic DNS (DDNS)

Aggiornamento automatico dei record DNS per IP dinamici:

- DynDNS
- No-IP
- Duck DNS
- Cloudflare API

```bash
# Esempio aggiornamento Cloudflare
curl -X PUT "https://api.cloudflare.com/client/v4/zones/ZONE_ID/dns_records/RECORD_ID" \
     -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"home.example.com","content":"NEW_IP"}'
```

### DNS Load Balancing

Distribuzione del traffico usando DNS:

```dns
www    IN    A    192.0.2.1
www    IN    A    192.0.2.2
www    IN    A    192.0.2.3
```

**Tecniche:**
- Round Robin DNS
- Weighted Round Robin
- Geographic Load Balancing
- Health-based routing

### Private DNS

DNS per reti private:

- **Consul**: Service discovery
- **CoreDNS**: Cloud-native DNS
- **etcd**: Distributed key-value store con DNS

### DNS in Cloud

Provider cloud con DNS gestito:

- **AWS Route 53**: Servizio DNS AWS
- **Google Cloud DNS**: DNS Google Cloud
- **Azure DNS**: DNS Microsoft Azure
- **Cloudflare DNS**: DNS e CDN

### Tendenze Future

1. **Maggiore Adozione Encrypted DNS**
   - DoH/DoT standard
   - Privacy-first approach

2. **AI/ML nel DNS**
   - Rilevamento anomalie
   - Previsione traffico
   - Auto-scaling

3. **Edge Computing**
   - DNS at the edge
   - Latenza ultra-bassa

4. **IPv6 Adoption**
   - Maggiore uso record AAAA
   - Transizione da IPv4

5. **Blockchain DNS**
   - DNS decentralizzato
   - Resistenza censura
   - Progetti: Handshake, ENS (Ethereum Name Service)

6. **Zero Trust DNS**
   - Integrazione sicurezza
   - Policy-based routing

---

## Performance e Ottimizzazione

### Metriche DNS

#### Tempo di Risposta

```bash
# Misurare latency
time dig example.com

# Con namebench (tool di Google)
namebench
```

#### Query Rate

- QPS (Queries Per Second)
- Capacità del server
- Monitoring con BIND statistics

### Ottimizzazioni

#### 1. TTL Appropriato

```dns
# Bilanciamento tra freshness e performance
; Record stabili - TTL alto
www        86400    IN    A    192.0.2.1

; Record dinamici - TTL basso
dynamic    300      IN    A    192.0.2.10
```

#### 2. Anycast DNS

Stessi IP in location diverse per routing ottimale.

#### 3. Prefetching

```html
<!-- DNS Prefetch in HTML -->
<link rel="dns-prefetch" href="//cdn.example.com">
```

#### 4. Keep-Alive

Riutilizzo connessioni TCP per query multiple.

#### 5. EDNS0 (Extension Mechanisms for DNS)

```bash
# Payload size maggiore
dig +bufsize=4096 example.com
```

---

## Esercitazioni Pratiche

### Esercizi Base

1. **[ES01 - Configurare un server DNS](ES01-Configurare-un-server-DNS.md)**
   - Installazione BIND
   - Configurazione zone
   - Testing

2. **[ES02 - Configurazione DNS con Service Provider](ES02-Configurazione_del_dns_sul_service_provider.md)**
   - Gestione DNS Aruba
   - Record A, CNAME, MX
   - Sottodomini

### Esercizi Avanzati

#### ES03 - Implementare DNSSEC

**Obiettivo:** Firmare una zona DNS con DNSSEC

**Passi:**
1. Generare chiavi ZSK e KSK
2. Firmare la zona
3. Configurare DS record nel parent
4. Testare validazione

#### ES04 - Configurare DNS Split-Horizon

**Obiettivo:** Configurare viste diverse per client interni/esterni

**Passi:**
1. Definire ACL per reti
2. Creare viste (views)
3. Configurare zone per vista
4. Testare risoluzione

#### ES05 - Implementare Dynamic DNS

**Obiettivo:** Configurare aggiornamenti dinamici DNS

**Passi:**
1. Generare chiavi TSIG
2. Configurare zone per update
3. Testare con nsupdate
4. Script automatico

#### ES06 - DNS Load Balancing

**Obiettivo:** Distribuire traffico tra server multipli

**Passi:**
1. Configurare record A multipli
2. Implementare health checks
3. Testare distribuzione
4. Monitorare bilanciamento

#### ES07 - DNS over HTTPS

**Obiettivo:** Configurare resolver DoH

**Passi:**
1. Installare cloudflared o dnscrypt-proxy
2. Configurare upstream DoH
3. Testare cifratura
4. Benchmark performance

#### ES08 - Monitoring e Logging DNS

**Obiettivo:** Implementare monitoring completo

**Passi:**
1. Configurare query logging
2. Setup Prometheus/Grafana
3. Alert configuration
4. Analisi query patterns

### Lab Pratici

#### Lab 1: DNS Troubleshooting Challenge

Scenari con problemi da risolvere:
- Misconfigured zones
- DNSSEC validation errors
- Propagation issues
- Performance problems

#### Lab 2: DNS Security Audit

Analizzare e migliorare sicurezza:
- Identificare vulnerabilità
- Implementare hardening
- Configurare DNSSEC
- Setup encrypted DNS

#### Lab 3: DNS Architecture Design

Progettare architettura DNS per azienda:
- Requisiti alta disponibilità
- Multi-region deployment
- Disaster recovery
- Monitoring e alerting

---

## Risorse e Riferimenti

### RFC Fondamentali

- **RFC 1034**: Domain Names - Concepts and Facilities
- **RFC 1035**: Domain Names - Implementation and Specification
- **RFC 1996**: DNS NOTIFY
- **RFC 2136**: Dynamic Updates in DNS
- **RFC 2181**: Clarifications to the DNS Specification
- **RFC 2308**: Negative Caching of DNS Queries
- **RFC 4033-4035**: DNSSEC
- **RFC 7858**: DNS over TLS
- **RFC 8484**: DNS over HTTPS
- **RFC 9250**: DNS over QUIC

### Documentazione

- [BIND Documentation](https://www.isc.org/bind/)
- [PowerDNS Documentation](https://doc.powerdns.com/)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [ICANN DNS Resources](https://www.icann.org/resources/pages/dns)
- [DNS-OARC](https://www.dns-oarc.net/)

### Tool Online

- [DNSChecker.org](https://dnschecker.org/) - Verifica propagazione globale
- [MXToolbox](https://mxtoolbox.com/) - DNS diagnostics
- [IntoDNS](https://intodns.com/) - Health check DNS
- [Zonemaster](https://zonemaster.net/) - DNS quality test
- [DNSViz](https://dnsviz.net/) - Visualizzazione DNSSEC
- [ViewDNS.info](https://viewdns.info/) - Vari tool DNS

### Libri Consigliati

- "DNS and BIND" - Cricket Liu & Paul Albitz (O'Reilly)
- "Pro DNS and BIND 10" - Ron Aitchison (Apress)
- "The DNS Security Handbook" - ICANN
- "Learning CoreDNS" - Cricket Liu & John Belamaric (O'Reilly)

### Community e Forum

- [NANOG Mailing List](https://www.nanog.org/)
- [DNS-Operations Mailing List](https://lists.dns-oarc.net/)
- [Stack Overflow - DNS Tag](https://stackoverflow.com/questions/tagged/dns)
- [Server Fault](https://serverfault.com/)

### Standard e Best Practices

- [BCP 16 (RFC 6895)](https://tools.ietf.org/html/rfc6895) - DNS IANA Considerations
- [BCP 140 (RFC 5855)](https://tools.ietf.org/html/rfc5855) - Nameservers for IPv6 Reverse Resolution
- [OWASP DNS Security](https://owasp.org/www-community/controls/Blocking_Brute_Force_Attacks)

---

## Glossario

- **Authoritative Server**: Server che contiene i dati ufficiali per una zona
- **CNAME**: Canonical Name, alias per un altro dominio
- **DNSSEC**: DNS Security Extensions
- **FQDN**: Fully Qualified Domain Name
- **Glue Record**: Record A per nameserver nella stessa zona
- **Iterative Query**: Query dove il server risponde con il miglior riferimento
- **NS Record**: Name Server record
- **Recursive Query**: Query dove il server esegue la risoluzione completa
- **Resolver**: Client DNS che esegue query
- **Root Server**: Server DNS di livello più alto
- **SOA**: Start of Authority record
- **TLD**: Top-Level Domain
- **TTL**: Time To Live
- **Zone**: Porzione di namespace DNS gestita come unità
- **Zone Transfer**: Sincronizzazione zona tra server (AXFR/IXFR)

---

## Conclusioni

Il DNS è un componente fondamentale di Internet, essenziale per la traduzione di nomi di dominio in indirizzi IP. Una comprensione approfondita del DNS è cruciale per:

- **Amministratori di sistema**: Configurazione e gestione server DNS
- **Network engineers**: Troubleshooting problemi di rete
- **Security professionals**: Protezione contro attacchi DNS
- **Sviluppatori**: Ottimizzazione performance applicazioni
- **DevOps**: Automazione e infrastructure as code

La tecnologia DNS continua ad evolversi con focus su:
- **Sicurezza** (DNSSEC, DoH, DoT)
- **Privacy** (encrypted DNS)
- **Performance** (anycast, edge computing)
- **Affidabilità** (alta disponibilità, disaster recovery)

Padroneggiare il DNS richiede sia conoscenza teorica che esperienza pratica. Utilizzare gli esercizi e i lab proposti per consolidare le competenze.

---

**Autore**: Filippo Bilardo  
**Corso**: Sistemi e Reti 3  
**Ultimo aggiornamento**: Ottobre 2025

---

## Esercitazioni Pratiche

- [ES01 - Configurare un server DNS](ES01-Configurare-un-server-DNS.md)
- [ES02 - Configurazione DNS con Aruba](ES02-Configurazione_del_dns_sul_service_provider.md)