# Capitolo 5 - Regole di Firewall per DMZ

## 5.1 Principi di configurazione firewall

### Policy di base: Default Deny

La regola fondamentale è **negare tutto ciò che non è esplicitamente permesso**.

```
# Concetto base
1. Negare tutto il traffico (implicit deny)
2. Permettere solo ciò che è strettamente necessario (explicit allow)
3. Loggare tutto ciò che viene bloccato (logging)
```

### Ordine delle regole

Le regole firewall vengono processate **dall'alto verso il basso** (first match wins nella maggior parte dei firewall).

**Struttura consigliata:**
```
1. Drop traffico palesemente malevolo (spoofed, malformed)
2. Allow traffico legittimo specifico
3. Log e drop tutto il resto (catch-all rule)
```

### Principi di least privilege

- **Non aprire porte non necessarie**
- **Limitare indirizzi IP sorgente quando possibile**
- **Usare range di IP invece di "any" dove applicabile**
- **Implementare time-based rules se applicabile**

## 5.2 Regole in ingresso dalla rete pubblica

### Traffico verso web server

**Scenario**: Web server pubblico in DMZ

```bash
# iptables
# Permettere HTTP
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p tcp --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.10 -p tcp --sport 80 -m state --state ESTABLISHED -j ACCEPT

# Permettere HTTPS
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p tcp --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.10 -p tcp --sport 443 -m state --state ESTABLISHED -j ACCEPT
```

**pfSense / firewall commerciale - formato concettuale:**
```
Action: PASS
Interface: WAN
Protocol: TCP
Source: any
Destination: DMZ-Web-Server (192.168.100.10)
Dest Port: 80, 443
Description: Allow HTTP/HTTPS to public web server
```

### Traffico verso mail server

```bash
# SMTP in ingresso (ricezione email)
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.20 -p tcp --dport 25 -m state --state NEW,ESTABLISHED -j ACCEPT

# SMTP submission (autenticato, per client esterni)
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.20 -p tcp --dport 587 -m state --state NEW,ESTABLISHED -j ACCEPT

# IMAP SSL (per webmail o client)
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.20 -p tcp --dport 993 -m state --state NEW,ESTABLISHED -j ACCEPT

# POP3 SSL (se utilizzato)
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.20 -p tcp --dport 995 -m state --state NEW,ESTABLISHED -j ACCEPT
```

### Limitazione rate (protezione DDoS)

```bash
# Limitare connessioni HTTP per IP
iptables -A FORWARD -p tcp --dport 80 -m connlimit --connlimit-above 20 --connlimit-mask 32 -j REJECT

# Limitare SYN packets (protezione SYN flood)
iptables -A FORWARD -p tcp --syn -m limit --limit 1/s --limit-burst 3 -j ACCEPT

# Protezione port scanning
iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP
iptables -A FORWARD -p tcp --tcp-flags ALL ALL -j DROP
```

### Geographic blocking (GeoIP)

```bash
# Bloccare traffico da Paesi specifici (esempio: bloccare CN, RU)
# Richiede xtables-addons e database GeoIP

iptables -A FORWARD -m geoip --src-cc CN,RU -j DROP
```

## 5.3 Regole in uscita verso Internet

### Permettere DNS

```bash
# Web server deve poter risolvere DNS
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.10 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p udp --sport 53 -j ACCEPT
```

### Permettere aggiornamenti

```bash
# HTTP/HTTPS per aggiornamenti software (es. apt, yum)
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -p tcp --dport 443 -j ACCEPT

# NTP per sincronizzazione oraria
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -p udp --dport 123 -j ACCEPT
```

### Limitare destinazioni

**Best practice**: limitare dove i server DMZ possono connettersi

```bash
# Esempio: web server può accedere solo a specifico repository
# INVECE DI: allow any destination
# MEGLIO: allow only to specific IPs/networks

# Permettere solo verso repository Ubuntu ufficiali
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.10 -d 91.189.88.0/21 -p tcp --dport 80 -j ACCEPT
```

### Bloccare connessioni outbound non necessarie

```bash
# Negare tutto il resto in uscita da DMZ
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -j LOG --log-prefix "DMZ-Outbound-Blocked: "
iptables -A FORWARD -i eth1 -o eth0 -s 192.168.100.0/24 -j DROP
```

## 5.4 Regole tra DMZ e rete interna

### Principio fondamentale
Il traffico da DMZ verso LAN interna deve essere **estremamente limitato**.

### Web application con database backend

```bash
# Web server in DMZ può accedere SOLO al database server
# Su porta 3306 (MySQL) o 5432 (PostgreSQL)

# MySQL
iptables -A FORWARD -i eth1 -o eth2 -s 192.168.100.10 -d 10.0.0.50 -p tcp --dport 3306 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth1 -s 10.0.0.50 -d 192.168.100.10 -p tcp --sport 3306 -m state --state ESTABLISHED -j ACCEPT

# IMPORTANTE: Negare tutto il resto da DMZ a LAN
iptables -A FORWARD -i eth1 -o eth2 -j LOG --log-prefix "DMZ-to-LAN-Blocked: "
iptables -A FORWARD -i eth1 -o eth2 -j DROP
```

### Mail relay

```bash
# Mail gateway DMZ -> Mail server LAN
iptables -A FORWARD -i eth1 -o eth2 -s 192.168.100.20 -d 10.0.0.30 -p tcp --dport 25 -j ACCEPT
```

### Amministrazione da LAN a DMZ

```bash
# Admin workstation può SSH verso server DMZ
iptables -A FORWARD -i eth2 -o eth1 -s 10.0.0.100 -d 192.168.100.0/24 -p tcp --dport 22 -j ACCEPT

# Oppure: tramite bastion host/jump server
iptables -A FORWARD -i eth2 -o eth1 -s 10.0.0.100 -d 192.168.100.5 -p tcp --dport 22 -j ACCEPT  # Solo a jump host
```

### Logging server (Syslog)

```bash
# Server DMZ inviano log a syslog server in LAN
iptables -A FORWARD -i eth1 -o eth2 -s 192.168.100.0/24 -d 10.0.0.200 -p udp --dport 514 -j ACCEPT
# oppure su TCP
iptables -A FORWARD -i eth1 -o eth2 -s 192.168.100.0/24 -d 10.0.0.200 -p tcp --dport 514 -j ACCEPT
```

## 5.5 Gestione del traffico ICMP

### ICMP necessario vs pericoloso

**ICMP utili:**
- Echo Request/Reply (ping) - utile per diagnostica, ma può essere abusato
- Destination Unreachable - importante per path MTU discovery
- Time Exceeded - necessario per traceroute

**ICMP pericolosi:**
- Redirect - possono alterare routing
- Source Quench - obsoleto, può essere usato per DoS

### Configurazione consigliata

```bash
# Permettere ping verso DMZ (per monitoring), ma con rate limit
iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# Permettere ICMP destination unreachable (Path MTU Discovery)
iptables -A FORWARD -p icmp --icmp-type destination-unreachable -j ACCEPT

# Permettere ICMP time-exceeded (per traceroute)
iptables -A FORWARD -p icmp --icmp-type time-exceeded -j ACCEPT

# Bloccare ICMP redirect
iptables -A FORWARD -p icmp --icmp-type redirect -j DROP

# Bloccare tutti gli altri ICMP
iptables -A FORWARD -p icmp -j DROP
```

### Alternative: bloccare tutto ICMP dall'esterno

Per massima sicurezza, si può bloccare completamente ICMP da Internet:

```bash
# Blocca tutti ICMP da Internet verso DMZ
iptables -A FORWARD -i eth0 -o eth1 -p icmp -j DROP

# Ma permetti da LAN interna per diagnostica
iptables -A FORWARD -i eth2 -o eth1 -p icmp -j ACCEPT
```

## 5.6 Logging e monitoring

### Strategie di logging

#### 1. Log delle negazioni (dropped packets)

```bash
# Logging con prefix per identificare facilmente
iptables -A FORWARD -i eth0 -m limit --limit 5/min -j LOG --log-prefix "FW-DROP-WAN: " --log-level 4

# Chain separata per logging
iptables -N LOG_DROP
iptables -A LOG_DROP -j LOG --log-prefix "FW-DROP: " --log-level 4
iptables -A LOG_DROP -j DROP

# Usare la chain
iptables -A FORWARD -i eth0 -j LOG_DROP
```

#### 2. Log delle accettazioni critiche

```bash
# Log accessi SSH a DMZ
iptables -A FORWARD -p tcp --dport 22 -d 192.168.100.0/24 -j LOG --log-prefix "SSH-Access-DMZ: "
iptables -A FORWARD -p tcp --dport 22 -d 192.168.100.0/24 -j ACCEPT
```

#### 3. Connection tracking

```bash
# Abilitare tracking delle connessioni
iptables -A FORWARD -m state --state INVALID -j LOG --log-prefix "INVALID-STATE: "
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
```

### Centralizzazione log

**Syslog forwarding:**
```bash
# /etc/rsyslog.conf
# Inoltrare log firewall a server centrale
:msg, contains, "FW-DROP" @@10.0.0.200:514  # @@ = TCP, @ = UDP
```

### Analisi log

**Tool utili:**
- **grep/awk**: analisi base da command line
- **logwatch**: report automatici
- **SIEM**: Splunk, ELK Stack, Graylog
- **Fail2ban**: ban automatico IP con troppi tentativi falliti

**Esempio grep:**
```bash
# Top 10 IP sorgente bloccati
grep "FW-DROP" /var/log/syslog | awk '{print $12}' | cut -d= -f2 | sort | uniq -c | sort -rn | head -10

# Tentativi SSH falliti
grep "SSH-Access-DMZ" /var/log/syslog | grep "DPT=22"
```

## 5.7 Esempi di ruleset completi

### Esempio 1: DMZ semplice con web server

```bash
#!/bin/bash
# Script configurazione firewall DMZ semplice

# Variabili
WAN_IF="eth0"
DMZ_IF="eth1"
LAN_IF="eth2"
DMZ_WEB="192.168.100.10"
LAN_NET="10.0.0.0/24"
ADMIN_IP="10.0.0.100"

# Reset
iptables -F
iptables -X
iptables -t nat -F

# Policy di default: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Connessioni stabilite
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Internet -> DMZ: HTTP/HTTPS al web server
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_WEB -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

# DMZ -> Internet: aggiornamenti e DNS
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p udp --dport 123 -j ACCEPT

# LAN -> DMZ: amministrazione SSH
iptables -A FORWARD -i $LAN_IF -o $DMZ_IF -s $ADMIN_IP -p tcp --dport 22 -m state --state NEW -j ACCEPT

# DMZ -> LAN: NEGATO (nessuna regola = dropped by policy)

# Logging dropped packets (con rate limit)
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "

# NAT per uscita DMZ verso Internet
iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE

# Port forwarding da WAN a DMZ web server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp -m multiport --dports 80,443 -j DNAT --to-destination $DMZ_WEB

echo "Firewall configurato"
```

### Esempio 2: DMZ con web, mail, VPN

```bash
#!/bin/bash
# DMZ complessa con multiple servizi

# Variabili
WAN_IF="eth0"
DMZ_IF="eth1"
LAN_IF="eth2"

DMZ_WEB="192.168.100.10"
DMZ_MAIL="192.168.100.20"
DMZ_VPN="192.168.100.30"

LAN_NET="10.0.0.0/24"
LAN_DB="10.0.0.50"
ADMIN_IP="10.0.0.100"

# Reset
iptables -F
iptables -X
iptables -t nat -F

# Policy default: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT

# Connessioni stabilite
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

### Internet -> DMZ ###

# Web server: HTTP/HTTPS
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_WEB -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

# Mail server: SMTP, Submission, IMAPS
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_MAIL -p tcp --dport 25 -m state --state NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_MAIL -p tcp --dport 587 -m state --state NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_MAIL -p tcp --dport 993 -m state --state NEW -j ACCEPT

# VPN server: OpenVPN
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $DMZ_VPN -p udp --dport 1194 -m state --state NEW -j ACCEPT

### DMZ -> Internet ###

# Aggiornamenti, DNS, NTP
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -p udp --dport 123 -j ACCEPT

# Mail relay verso altri mail server
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -s $DMZ_MAIL -p tcp --dport 25 -m state --state NEW -j ACCEPT

### DMZ -> LAN ###

# Web server -> Database
iptables -A FORWARD -i $DMZ_IF -o $LAN_IF -s $DMZ_WEB -d $LAN_DB -p tcp --dport 3306 -m state --state NEW -j ACCEPT

# Mail relay -> Internal mail server
iptables -A FORWARD -i $DMZ_IF -o $LAN_IF -s $DMZ_MAIL -d 10.0.0.60 -p tcp --dport 25 -m state --state NEW -j ACCEPT

# IMPORTANTE: Blocca tutto il resto da DMZ a LAN
iptables -A FORWARD -i $DMZ_IF -o $LAN_IF -j LOG --log-prefix "DMZ-to-LAN-BLOCK: "
iptables -A FORWARD -i $DMZ_IF -o $LAN_IF -j DROP

### LAN -> DMZ ###

# Amministrazione SSH
iptables -A FORWARD -i $LAN_IF -o $DMZ_IF -s $ADMIN_IP -p tcp --dport 22 -m state --state NEW -j ACCEPT

# Accesso web interno (per test)
iptables -A FORWARD -i $LAN_IF -o $DMZ_IF -s $LAN_NET -d $DMZ_WEB -p tcp -m multiport --dports 80,443 -m state --state NEW -j ACCEPT

### Protezioni ###

# Anti-spoofing: blocca IP privati da WAN
iptables -A FORWARD -i $WAN_IF -s 10.0.0.0/8 -j DROP
iptables -A FORWARD -i $WAN_IF -s 172.16.0.0/12 -j DROP
iptables -A FORWARD -i $WAN_IF -s 192.168.0.0/16 -j DROP

# SYN flood protection
iptables -A FORWARD -p tcp --syn -m limit --limit 1/s -j ACCEPT

# Port scan protection
iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP
iptables -A FORWARD -p tcp --tcp-flags ALL ALL -j DROP

### NAT ###

# SNAT per uscita (oppure MASQUERADE)
iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE

# DNAT per servizi pubblici
WAN_IP="203.0.113.10"
iptables -t nat -A PREROUTING -i $WAN_IF -d $WAN_IP -p tcp -m multiport --dports 80,443 -j DNAT --to-destination $DMZ_WEB
iptables -t nat -A PREROUTING -i $WAN_IF -d $WAN_IP -p tcp -m multiport --dports 25,587,993 -j DNAT --to-destination $DMZ_MAIL
iptables -t nat -A PREROUTING -i $WAN_IF -d $WAN_IP -p udp --dport 1194 -j DNAT --to-destination $DMZ_VPN

### Logging ###

# Log dropped packets
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: " --log-level 4

echo "Firewall DMZ configurato con successo"
```

## 5.8 Best practice e errori comuni

### Best Practice

#### 1. Documentare tutto
```bash
# ✅ BUONO: Commenti chiari
# Allow HTTP/HTTPS from Internet to DMZ web server
# Ticket: #12345, Approved by: John Doe, Date: 2024-01-15
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p tcp -m multiport --dports 80,443 -j ACCEPT

# ❌ CATTIVO: Nessuna documentazione
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p tcp -m multiport --dports 80,443 -j ACCEPT
```

#### 2. Usare oggetti/alias (firewall commerciali)
```
# Invece di IP hardcoded, usare alias significativi
DMZ-WEB-SERVER = 192.168.100.10
DMZ-MAIL-SERVER = 192.168.100.20

RULE: ALLOW from Internet to DMZ-WEB-SERVER port 80, 443
```

#### 3. Testare prima in staging
- Non applicare direttamente in produzione
- Testare in ambiente di lab
- Avere sempre un piano di rollback

#### 4. Version control
- Salvare configurazioni firewall in Git
- Tenere storico delle modifiche
- Peer review prima di deployment

#### 5. Audit periodici
- Rivedere le regole ogni 3-6 mesi
- Rimuovere regole obsolete
- Verificare che documentazione sia aggiornata

### Errori comuni

#### ❌ Errore 1: Regole troppo permissive
```bash
# SBAGLIATO: troppo ampio
iptables -A FORWARD -i eth0 -o eth1 -j ACCEPT  # Permette TUTTO!

# CORRETTO: specifico
iptables -A FORWARD -i eth0 -o eth1 -d 192.168.100.10 -p tcp --dport 443 -j ACCEPT
```

#### ❌ Errore 2: Dimenticare traffico di ritorno (stateless firewall)
```bash
# INCOMPLETO (firewall stateless):
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 -j ACCEPT
# Manca regola per traffico di ritorno!

# COMPLETO:
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -p tcp --sport 80 -j ACCEPT

# MEGLIO: Usare connection tracking (stateful)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -p tcp --dport 80 -m state --state NEW -j ACCEPT
```

#### ❌ Errore 3: Ordine delle regole sbagliato
```bash
# SBAGLIATO: deny-all prima delle regole specifiche
iptables -A FORWARD -j DROP           # Blocca tutto subito!
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT  # Non sarà mai valutata

# CORRETTO: deny-all alla fine
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -j DROP           # Catch-all alla fine
```

#### ❌ Errore 4: Non implementare limiti di rate
```bash
# Vulnerabile a DDoS
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT

# Protetto con rate limiting
iptables -A FORWARD -p tcp --dport 80 -m connlimit --connlimit-above 50 -j REJECT
iptables -A FORWARD -p tcp --dport 80 -m limit --limit 100/sec -j ACCEPT
```

#### ❌ Errore 5: Logging eccessivo
```bash
# SBAGLIATO: logga troppo, riempie disco
iptables -A FORWARD -j LOG  # Logga OGNI pacchetto!

# CORRETTO: logging con rate limit
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW: "
```

## 5.9 Esercizi di configurazione

### Esercizio 1: Web application base

**Scenario:**
- Web server in DMZ: 192.168.100.10
- Database in LAN: 10.0.0.50
- Internet: eth0
- DMZ: eth1
- LAN: eth2

**Compiti:**
1. Scrivi le regole per permettere HTTP/HTTPS da Internet al web server
2. Permetti al web server di accedere al database (MySQL port 3306)
3. Permetti admin SSH da 10.0.0.100 verso DMZ
4. Nega tutto il resto da DMZ verso LAN
5. Implementa logging appropriato

### Esercizio 2: Mail server

**Scenario:**
- Mail gateway in DMZ: 192.168.100.20
- Internal mail server in LAN: 10.0.0.60
- Webmail: accessibile da Internet

**Compiti:**
1. SMTP in ingresso (port 25) da Internet
2. SMTP submission (port 587) per client mobili
3. HTTPS (port 443) per webmail
4. Mail relay da DMZ a LAN internal mail server
5. Blocca SMTP diretto da DMZ verso Internet (solo verso mail server legittimi)

### Esercizio 3: Debugging 

**Data la seguente configurazione, identifica i problemi:**

```bash
iptables -P FORWARD ACCEPT  # Policy di default
iptables -A FORWARD -s 192.168.100.0/24 -j ACCEPT  # DMZ può andare ovunque
iptables -A FORWARD -p tcp --dport 22 -j ACCEPT  # SSH aperto a tutti
iptables -A FORWARD -i eth0 -j ACCEPT  # Tutto da Internet
```

**Problemi da trovare:**
- Quali principi di sicurezza sono violati?
- Quale è il rischio di ciascuna regola?
- Come correggeresti la configurazione?

## 5.10 Autovalutazione

### Domande

**1. Perché la policy "default deny" è preferibile a "default allow"?**

**2. Qual è la differenza tra connessioni NEW, ESTABLISHED, e RELATED nel connection tracking?**

**3. Perché è importante limitare il traffico da DMZ verso LAN interna?**

**4. Come proteggeresti un web server da attacchi DDoS usando regole firewall?**

**5. Spiega l'importanza dell'ordine delle regole in un firewall.**

### Risposta a scenario

Una web application in DMZ deve:
- Ricevere traffico HTTPS (443) da Internet
- Connettersi a database in LAN (MySQL 3306)
- Ricevere connessioni SSH solo da admin network (10.0.0.0/24)
- Poter fare aggiornamenti via HTTP/HTTPS

Scrivi il ruleset completo iptables commentato.

---

*[Le risposte si trovano nell'appendice del manuale]*
