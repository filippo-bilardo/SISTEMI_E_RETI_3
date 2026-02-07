# Capitolo 4 - Componenti della DMZ

## 4.1 Firewall perimetrali

### Tipi di firewall

#### Packet Filtering Firewall
- Filtra basandosi su IP sorgente/destinazione, porte, protocollo
- Stateless (senza stato) o stateful (con stato)
- Veloce ma limitato nelle funzionalità

#### Application-Level Gateway (Proxy Firewall)
- Opera a livello 7 (Application)
- Ispezione profonda del contenuto applicativo
- Più lento ma più sicuro

#### Next-Generation Firewall (NGFW)
- Funzionalità integrate:
  - Traditional firewall
  - IPS (Intrusion Prevention System)
  - Application awareness and control
  - SSL/TLS inspection
  - Threat intelligence
- Soluzione moderna consigliata

### Configurazione best practices

**1. Default Deny Policy**
```
# Regola finale: nega tutto ciò che non è esplicitamente permesso
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP
```

**2. Logging**
```
# Regola per loggare pacchetti droppati
iptables -A INPUT -j LOG --log-prefix "IPTables-Dropped: "
```

**3. Protezione contro attacchi comuni**
```
# Protezione SYN flood
iptables -A INPUT -p tcp --syn -m limit --limit 1/s -j ACCEPT

# Blocca port scanning
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
```

### Placement nel DMZ
- **Firewall esterno**: tra Internet e DMZ
- **Firewall interno**: tra DMZ e LAN
- **Segmenting firewall**: tra diverse DMZ

## 4.2 Web server e application server

### Web Server

#### Software comuni
- **Apache HTTP Server**: open source, molto diffuso
- **Nginx**: alta performance, reverse proxy
- **Microsoft IIS**: integrato con stack Microsoft
- **LiteSpeed**: ottimizzato per performance

#### Configurazione sicura

**Apache - hardening base:**
```apache
# Nascondere versione server
ServerTokens Prod
ServerSignature Off

# Disabilitare directory listing
Options -Indexes

# Protezione clickjacking
Header always set X-Frame-Options "SAMEORIGIN"

# XSS Protection
Header always set X-XSS-Protection "1; mode=block"

# Content Security Policy
Header always set Content-Security-Policy "default-src 'self'"

# Limitare metodi HTTP
<LimitExcept GET POST HEAD>
    Deny from all
</LimitExcept>

# Timeout
Timeout 60
```

**Nginx - configurazione base sicura:**
```nginx
# Nascondere versione
server_tokens off;

# Protezione headers
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;

# Limitare dimensione upload
client_max_body_size 10M;

# Timeout
client_body_timeout 12;
client_header_timeout 12;
keepalive_timeout 15;
send_timeout 10;

# Limitare metodi HTTP
if ($request_method !~ ^(GET|HEAD|POST)$ ) {
    return 444;
}
```

### Application Server

#### Piattaforme comuni
- **Tomcat**: Java applications
- **JBoss/WildFly**: Java EE
- **Node.js**: JavaScript runtime
- **PHP-FPM**: PHP applications
- **.NET Kestrel**: ASP.NET Core

#### Separazione Web/App tier

**Architettura consigliata:**
```
Internet
    ↓
Web Server (DMZ esterna)
    - Reverse proxy
    - TLS termination
    - Static content
    ↓
Application Server (DMZ interna o LAN)
    - Business logic
    - API
    - Session management
    ↓
Database Server (LAN interna)
```

**Vantaggi:**
- Maggiore sicurezza (app server non esposto direttamente)
- Scalabilità (scale-out di web/app tier indipendentemente)
- Performance (caching a livello web server)

## 4.3 Mail server (SMTP, POP3, IMAP)

### Architettura mail sicura

```
Internet
    ↓
[MX Record → IP pubblico DMZ]
    ↓
Mail Gateway (DMZ)
    - SMTP inbound (port 25)
    - Antispam
    - Antivirus
    - SPF/DKIM/DMARC check
    ↓
Internal Mail Server (LAN)
    - Mailbox storage
    - POP3/IMAP (per client interni)
    - Webmail
```

### Componenti

#### SMTP Gateway (in DMZ)
Software: Postfix, Exim, Exchange Edge Transport

**Postfix - configurazione base sicura:**
```conf
# main.cf

# Network
inet_interfaces = all
inet_protocols = ipv4

# SMTP restrictions
smtpd_helo_required = yes
smtpd_relay_restrictions = 
    permit_mynetworks
    permit_sasl_authenticated
    reject_unauth_destination

# Anti-spam basics
smtpd_recipient_restrictions =
    reject_non_fqdn_recipient
    reject_unknown_recipient_domain
    reject_unverified_recipient

# Connection limits
smtpd_client_connection_count_limit = 10
smtpd_client_connection_rate_limit = 30

# TLS
smtpd_tls_security_level = may
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_ciphers = high
```

#### Antispam/Antivirus
- **SpamAssassin**: content-based spam filter
- **ClamAV**: antivirus open source
- **Amavis**: interface tra MTA e antivirus/antispam

#### Webmail (in DMZ)
- **Roundcube**: webmail PHP
- **SOGo**: groupware con webmail
- **OWA (Outlook Web Access)**: per Exchange

### Protezione contro minacce email

**SPF (Sender Policy Framework)**
```
v=spf1 ip4:203.0.113.0/24 -all
```

**DKIM (DomainKeys Identified Mail)**
```
# Generazione chiave
opendkim-genkey -s default -d example.com

# DNS Record
default._domainkey.example.com TXT "v=DKIM1; k=rsa; p=MIGfMA0..."
```

**DMARC (Domain-based Message Authentication)**
```
_dmarc.example.com TXT "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"
```

## 4.4 DNS server

### Architettura split DNS

**Concetto**: separare DNS pubblici (in DMZ) da DNS interni (in LAN)

```
Internet queries
    ↓
DNS Pubblico (DMZ)
    - Risolve solo nomi pubblici
    - example.com → IP pubblico web server
    - mail.example.com → IP pubblico mail gateway
    
Internal queries
    ↓
DNS Interno (LAN)
    - Risolve nomi interni
    - server01.internal.example.com → IP privato
    - Forward queries esterne a DNS pubblico o forwarder
```

### Software

#### BIND (Berkeley Internet Name Domain)
Configurazione base sicura:
```conf
options {
    directory "/var/named";
    
    # Limitare query ricorsive
    recursion no;  # DNS pubblico in DMZ: NO recursion
    
    # Limitare zone transfer
    allow-transfer { none; };
    
    # Nascondi versione
    version "Not disclosed";
    
    # Rate limiting (protezione DDoS)
    rate-limit {
        responses-per-second 10;
        window 5;
    };
    
    # DNSSEC
    dnssec-validation auto;
};

# Zona example.com
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-query { any; };
    allow-transfer { 203.0.113.50; };  # Secondary DNS
};
```

#### PowerDNS
Alternativa moderna con backend database

#### Unbound
DNS resolver sicuro e performante

### Protezione DNS

**Minacce comuni:**
- DNS amplification attacks
- Cache poisoning
- Zone transfer non autorizzati
- DDoS

**Contromisure:**
1. **Separare resolver e autoritativo**
2. **Limitare zone transfer**: solo a secondary autorizzati
3. **DNSSEC**: firma crittografica delle zone
4. **Rate limiting**: prevenire abusi
5. **Monitoring**: monitorare query anomale

## 4.5 Proxy e reverse proxy

### Forward Proxy

Utilizzato per controllare l'accesso uscente da LAN verso Internet.

**Posizionamento**: tipicamente in LAN o DMZ interna

**Funzionalità:**
- Content filtering
- URL blacklist/whitelist
- Caching
- Authentication
- Logging

**Software**: Squid, Privoxy, CCProxy

### Reverse Proxy

Posto davanti ai web server in DMZ per:
- **Terminazione SSL/TLS**
- **Load balancing**
- **Caching** di contenuti statici
- **Protezione** (nasconde architettura backend)
- **WAF** (Web Application Firewall)

**Software:**
- **Nginx**: alta performance
- **HAProxy**: L7 load balancer
- **Apache mod_proxy**: modulo Apache
- **Traefik**: cloud-native, integrazione container

**Nginx come reverse proxy:**
```nginx
upstream backend_servers {
    least_conn;  # Load balancing method
    server 10.0.1.10:8080;
    server 10.0.1.11:8080;
    server 10.0.1.12:8080;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;
    
    # TLS configuration
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://backend_servers;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeout
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }
    
    # Caching per static content
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        proxy_pass http://backend_servers;
        proxy_cache my_cache;
        proxy_cache_valid 200 1h;
        expires 1h;
    }
}
```

## 4.6 Load balancer

### Tipi

#### Layer 4 Load Balancer (Transport Layer)
- Decisioni basate su IP e porta
- Più veloce, meno intelligent
- **Esempio**: HAProxy in TCP mode, NGINX stream module

#### Layer 7 Load Balancer (Application Layer)
- Decisioni basate su contenuto HTTP (URL, headers, cookies)
- Session persistence (sticky sessions)
- Content-based routing
- **Esempio**: HAProxy HTTP mode, NGINX, AWS ALB

### Algoritmi di load balancing

1. **Round Robin**: distribuisce a rotazione
2. **Least Connections**: verso server con meno connessioni
3. **IP Hash**: stesso client va sempre allo stesso server
4. **Weighted**: distribuzione basata su capacità server

### Alta disponibilità (HA)

**Configurazione master-standby con keepalived:**
```conf
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    
    authentication {
        auth_type PASS
        auth_pass secret123
    }
    
    virtual_ipaddress {
        192.168.100.10/24  # VIP
    }
}
```

### Health checks

```nginx
upstream backend {
    server 10.0.1.10:80 max_fails=3 fail_timeout=30s;
    server 10.0.1.11:80 max_fails=3 fail_timeout=30s;
}
```

## 4.7 VPN gateway

Gateway VPN in DMZ permette accesso sicuro da remoto alla rete aziendale.

### Tipi di VPN

#### Site-to-Site VPN
Connette due reti (es. sede centrale ↔ filiale)

**Protocolli:**
- **IPsec**: standard de facto
- **OpenVPN**: flessibile, attraversa facilmente NAT
- **WireGuard**: moderno, performante

#### Remote Access VPN
Connette singoli utenti remoti alla rete aziendale

**Protocolli:**
- **OpenVPN**: open source, multipiattaforma
- **L2TP/IPsec**: supporto nativo in molti OS
- **IKEv2/IPsec**: ottimo per mobile
- **SSL VPN**: basato su browser

### Placement in DMZ

```
Internet
    ↓
[Firewall esterno]
    ↓
DMZ - VPN Gateway
    - OpenVPN server o IPsec gateway
    - Autenticazione (RADIUS, LDAP, MFA)
    ↓
[Firewall interno]
    ↓
LAN Interna
```

**Vantaggio**: se VPN gateway compromesso, attaccante è ancora in DMZ, non in LAN

### OpenVPN - configurazione server

```conf
# Server config
port 1194
proto udp
dev tun

ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh2048.pem

# Network
server 10.8.0.0 255.255.255.0
push "route 10.0.0.0 255.255.255.0"  # LAN interna
push "redirect-gateway def1 bypass-dhcp"

# DNS
push "dhcp-option DNS 10.0.0.1"

# Security
cipher AES-256-GCM
auth SHA256
tls-auth /etc/openvpn/ta.key 0

# Compression
compress lz4-v2

# Logs
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Connection
keepalive 10 120
persist-key
persist-tun

# User/Group
user nobody
group nogroup
```

## 4.8 IDS/IPS (Intrusion Detection/Prevention Systems)

### Differenza IDS vs IPS

#### IDS (Intrusion Detection System)
- **Modalità passiva**: monitora traffico, genera alert
- Non blocca traffico
- **Placement**: span port o network tap

#### IPS (Intrusion Prevention System)
- **Modalità attiva**: inline nel flusso di traffico
- Può bloccare traffico malevolo
- **Placement**: inline tra firewall e rete

### Software

#### Snort
Open source IDS/IPS

**Modalità operative:**
- **Sniffer**: cattura e visualizza pacchetti
- **Packet Logger**: log dei pacchetti
- **NIDS**: Network Intrusion Detection

**Regola esempio:**
```
alert tcp any any -> 192.168.100.0/24 80 (msg:"SQL Injection Attempt"; \
content:"SELECT"; nocase; content:"FROM"; nocase; sid:1000001; rev:1;)
```

#### Suricata
Moderno IDS/IPS multi-threaded

**Vantaggi su Snort:**
- Performance superiore (multi-thread)
- IPv6 support nativo
- Scripting con Lua

#### Zeek (ex Bro)
Network security monitor, focus su analisi traffico

### Placement in DMZ

**Opzione 1: IDS passivo**
```
Internet → Firewall → [TAP] → IDS sensor
                         ↓
                       DMZ
```

**Opzione 2: IPS inline**
```
Internet → Firewall → IPS → DMZ
```

**Opzione 3: Hybrid**
- IPS inline per traffico critico
- IDS passivo per visibilità completa

## 4.9 Esempi di configurazione

### Scenario completo: Web application in DMZ

**Componenti:**
1. Firewall esterno (pfSense)
2. Web Application Firewall / Reverse Proxy (Nginx)
3. Web server (Apache/Nginx)
4. Application server (Tomcat)
5. IDS (Suricata)

**Flusso del traffico:**
```
Internet (client HTTPS request)
    ↓ 443
[Firewall - NAT/port forwarding]
    ↓ 443
[Nginx reverse proxy + WAF]
    - TLS termination
    - Request filtering
    - Load balancing
    ↓ 8080 (HTTP interno)
[Apache/Nginx web server]
    - Serve static content
    ↓ 8080 (per dynamic content)
[Tomcat application server]
    - Business logic
    ↓ 3306 (attraverso firewall interno)
[MySQL database] (in LAN interna)
```

**Regole firewall esterno:**
```
# Internet → DMZ
ALLOW TCP 443 from ANY to Nginx-WAF-IP

# DMZ → LAN (solo per DB query)
ALLOW TCP 3306 from Tomcat-IP to MySQL-IP

# LAN → DMZ (amministrazione)
ALLOW TCP 22 from Admin-IP to DMZ-Servers

# DENY all else
DENY ALL
```

## 4.10 Autovalutazione

### Domande

**1. Qual è la differenza tra un IDS e un IPS?**

**2. Perché è consigliabile separare il DNS pubblico dal DNS interno?**

**3. In uno scenario con reverse proxy, dove dovrebbe terminare la connessione SSL/TLS?**

**4. Quale vantaggio offre posizionare il VPN gateway in DMZ invece che direttamente nella LAN?**

**5. Descrivi i tre layer di un'applicazione web (web tier, app tier, data tier) e dove dovrebbe risiedere ciascuno in un'architettura DMZ.**

### Esercizio pratico

Progetta una DMZ per un'azienda che offre:
- Sito web pubblico (WordPress)
- Webmail per dipendenti
- VPN per accesso remoto
- FTP per upload file da partner esterni

Specifica:
- Quali componenti/server servono
- Dove posizionarli (DMZ vs LAN interna)
- Schema del flusso di traffico
- Porte da aprire su firewall
- Software consigliato per ogni componente

---
*[Continua nel prossimo capitolo con le Regole di Firewall]*
