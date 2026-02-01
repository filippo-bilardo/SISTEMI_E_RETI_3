# SOLUZIONE PROVA A038_STR24 - SISTEMI E RETI

## Informazioni Generali
- **Prova**: A038_STR24
- **Materia**: Sistemi e Reti (Classe di Concorso A038)
- **Tipologia**: Prova di Esame di Maturità 2024

---

## ANALISI DEL TESTO DELLA PROVA

### 📋 Traccia della Prova d'Esame

**PROVA SCRITTA DI SISTEMI E RETI - Classe A038**

La prova richiede la progettazione e implementazione di un'infrastruttura di rete aziendale completa che soddisfi i seguenti requisiti:

#### Requisiti della Prova:

1. **Progettazione Architettura di Rete**
   - Progettare l'architettura di rete di un'azienda con almeno 3 sottoreti distinte
   - Prevedere una zona DMZ per i servizi pubblici
   - Implementare segmentazione della rete per sicurezza

2. **Piano di Indirizzamento IP**
   - Definire un piano di indirizzamento IP con subnetting appropriato
   - Utilizzare indirizzi privati secondo RFC 1918
   - Documentare il calcolo delle sottoreti

3. **Configurazione Dispositivi di Rete**
   - Configurare router per connessione Internet e routing interno
   - Configurare switch con VLAN e inter-VLAN routing
   - Implementare NAT/PAT per l'accesso a Internet

4. **Servizi di Rete**
   - Configurare servizio DNS per la risoluzione nomi interni
   - Configurare servizio DHCP per assegnazione automatica IP
   - Implementare server Web accessibile dall'esterno
   - Implementare server Mail per la gestione email

5. **Sicurezza**
   - Configurare firewall con regole appropriate
   - Implementare DMZ isolata dalla rete interna
   - Configurare accesso VPN per utenti remoti
   - Applicare principi di sicurezza multi-livello

6. **Gestione e Manutenzione**
   - Implementare procedure di backup
   - Definire procedure di disaster recovery
   - Implementare monitoring della rete

### Scenario
La prova riguarda la progettazione e implementazione di una rete aziendale per un'azienda con diverse esigenze di networking, sicurezza e servizi, secondo i requisiti specificati nella traccia d'esame.

---

## PARTE 1: PROGETTAZIONE DELLA RETE

> **📌 Riferimento Prova**: *Requisito 1 - Progettazione Architettura di Rete*  
> "Progettare l'architettura di rete di un'azienda con almeno 3 sottoreti distinte e una zona DMZ per i servizi pubblici"

### 1.1 Analisi dei Requisiti

**Requisiti tipici per una rete aziendale:**

1. **Connettività**
   - Collegamento tra diverse sedi/uffici
   - Accesso a Internet
   - Comunicazione interna efficiente

2. **Sicurezza**
   - Firewall
   - VPN per connessioni remote
   - Segmentazione della rete
   - Sistema di autenticazione

3. **Servizi**
   - Server Web
   - Server Email
   - File Server
   - Database Server
   - DNS e DHCP

4. **Prestazioni**
   - Banda adeguata
   - Bassa latenza
   - Ridondanza

### 1.2 Schema di Rete Proposto

```
                           INTERNET
                               |
                           [ROUTER]
                               |
                    [FIREWALL/UTM]
                               |
                    +-----------+-----------+
                    |                       |
              [SWITCH CORE]           [DMZ SWITCH]
                    |                       |
         +----------+----------+      +-----+-----+
         |          |          |      |           |
    [SWITCH]   [SWITCH]   [SWITCH]  [WEB]    [MAIL]
     LAN 1      LAN 2      LAN 3   SERVER   SERVER
         |          |          |
    PC/Client  Servers   Admin/IT
```

### 1.3 Subnetting e Indirizzamento IP

> **📌 Riferimento Prova**: *Requisito 2 - Piano di Indirizzamento IP*  
> "Definire un piano di indirizzamento IP con subnetting appropriato utilizzando indirizzi privati secondo RFC 1918"

**Piano di Indirizzamento - Rete Privata Classe B: 172.16.0.0/16**

📄 **Documentazione Completa**: Vedi [Piano di Indirizzamento](documentazione/piano-indirizzamento.md)

| Sottorete | Indirizzo di Rete | Subnet Mask | Range IP Utilizzabili | Gateway | Broadcast | Host Max |
|-----------|-------------------|-------------|----------------------|---------|-----------|----------|
| LAN 1 (Utenti) | 172.16.1.0 | /24 (255.255.255.0) | 172.16.1.1 - 172.16.1.254 | 172.16.1.1 | 172.16.1.255 | 254 |
| LAN 2 (Server) | 172.16.2.0 | /24 (255.255.255.0) | 172.16.2.1 - 172.16.2.254 | 172.16.2.1 | 172.16.2.255 | 254 |
| LAN 3 (Admin) | 172.16.3.0 | /24 (255.255.255.0) | 172.16.3.1 - 172.16.3.254 | 172.16.3.1 | 172.16.3.255 | 254 |
| DMZ | 172.16.10.0 | /26 (255.255.255.192) | 172.16.10.1 - 172.16.10.62 | 172.16.10.1 | 172.16.10.63 | 62 |
| VPN | 172.16.20.0 | /26 (255.255.255.192) | 172.16.20.1 - 172.16.20.62 | 172.16.20.1 | 172.16.20.63 | 62 |
| Management | 172.16.30.0 | /28 (255.255.255.240) | 172.16.30.1 - 172.16.30.14 | 172.16.30.1 | 172.16.30.15 | 14 |

**Assegnazione IP Statici per Server:**

- **Web Server (DMZ)**: 172.16.10.10
- **Mail Server (DMZ)**: 172.16.10.11
- **DNS Server**: 172.16.2.10
- **DHCP Server**: 172.16.2.11
- **File Server**: 172.16.2.12
- **Database Server**: 172.16.2.13
- **Firewall (interno)**: 172.16.1.1, 172.16.2.1, 172.16.3.1, 172.16.10.1
- **Firewall (esterno)**: IP Pubblico assegnato dall'ISP
> **📌 Riferimento Prova**: *Requisito 3 - Configurazione Dispositivi di Rete*  
> "Configurare router per connessione Internet e routing interno, switch con VLAN, implementare NAT/PAT"

### 2.1 Configurazione Router Cisco

**📁 File Configurazione**: [router-config.txt](configurazioni/router-config.txt)

**Spiegazione della configurazione:**

La configurazione del router Cisco comprende:

1. **Interfacce di Rete**
   - **GigabitEthernet0/0** (WAN): Interfaccia verso Internet con IP dinamico da ISP
   - **GigabitEthernet0/1** (LAN): Interfaccia verso rete interna con IP 172.16.0.1/16

2. **Routing**
   - Route di default verso Internet tramite interfaccia WAN
   - Route statiche verso le sottoreti interne tramite firewall

3. **NAT/PAT**
   - NAT Overload (PAT) per permettere a tutte le reti interne di accedere a Internet
   - Port Forwarding per i servizi in DMZ (HTTP, HTTPS, SMTP, etc.)

4. **Sicurezza**
   - ACL per limitare accesso SSH alla sola rete admin
   - Anti-spoofing per bloccare pacchetti con IP privati da WAN
   - Password encryption e autenticazione SSH

**Snippet chiave della configurazione:**

```cisco
! NAT Overload per accesso Internet
ip nat inside source list NAT_ACL interface GigabitEthernet0/0 overload

! Port Forwarding HTTP -> Web Server DMZ
ip nat inside source static tcp 172.16.10.10 80 interface GigabitEthernet0/0 80
```

**Comandi di verifica:**
```cisco
show running-config
show ip interface brief
show ip route
show ip nat translations
```

---

### 2.2 Configurazione Switch Core

**📁 File Configurazione**: [switch-config.txt](configurazioni/switch-config.txt)

**Spiegazione della configurazione:**

La configurazione dello switch core Layer 3 include:

1. **VLAN Configuration**
   - VLAN 10: LAN1 - Utenti
   - VLAN 20: LAN2 - Server
   - VLAN 30: LAN3 - Admin
   - VLAN 40: DMZ
   - VLAN 50: Management

2. **Inter-VLAN Routing**
   - SVI (Switch Virtual Interface) per ogni VLAN come gateway
   - Routing IP abilitato per permettere comunicazione tra VLAN

3. **Port Security e DHCP Snooping**
   - Port security su porte di accesso per limitare MAC address
   - DHCP Snooping per prevenire rogue DHCP server
   - Dynamic ARP Inspection per protezione ARP spoofing

4. **Spanning Tree**
   - Rapid PVST+ per convergenza veloce
   - Questo switch configurato come root bridge (priority 4096)

**Snippet chiave della configurazione:**

```cisco
! VLAN e Inter-VLAN Routing
interface vlan 10
 ip address 172.16.1.1 255.255.255.0
 ip address 172.16.30.2 255.255.255.240
 no shutdown
!
ip default-gateway 172.16.30.1
!
! Porte di accesso per VLAN
interface range FastEthernet0/1-10
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast
!
interface range FastEthernet0/11-20
 switchport mode access
 switchport access vlan 20
!
interface range FastEthernet0/21-24
 switchport mode access
 switchport access vlan 30
!
! Porta trunk verso router/firewall
interface GigabitEthernet0/1
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50
!
! Spanning Tree
spanning-tree mode rapid-pvst
spanning-tree vlan 10,20,30,40,50 priority 4096
!
! Port Security (esempio)
interface FastEthernet0/1
 switchport port-security
 switchport port-security maximum 2
 switchport port-security violation restrict
 switchport port-security mac-address sticky
!
! Salvataggio
end
write memory
```

### 2.3 Configurazione DHCP Server (Linux)

**File: /etc/dhcp/dhcpd.conf**

```bash
# Configurazione DHCP Server

# Parametri globali
option domain-name "azienda.local";
option domain-name-servers 172.16.2.10, 8.8.8.8;
default-lease-time 86400;
max-lease-time 604800;
authoritative;

# Subnet LAN1 - Utenti
subnet 172.16.1.0 netmask 255.255.255.0 {
    range 172.16.1.50 172.16.1.250;
    option routers 172.16.1.1;
    option broadcast-address 172.16.1.255;
}

# Subnet LAN3 - Admin
subnet 172.16.3.0 netmask 255.255.255.0 {
    range 172.16.3.50 172.16.3.200;
    option routers 172.16.3.1;
    option broadcast-address 172.16.3.255;
}

# Reservation per stampante
host printer-sala1 {
    hardware ethernet 00:11:22:33:44:55;
    fixed-address 172.16.1.10;
}
```

**Comandi di gestione:**

```bash
# Avvio servizio
sudo systemctl start isc-dhcp-server
sudo systemctl enable isc-dhcp-server

# Verifica stato
sudo systemctl status isc-dhcp-server

# Verifica lease attivi
sudo dhcp-lease-list

# Log
sudo tail -f /var/log/syslog | grep dhcp
```

### 2.4 Configurazione DNS Server (BIND9)

**File: /etc/bind/named.conf.local**

```bash
zone "azienda.local" {
    type master;
    file "/etc/bind/db.azienda.local";
};

zone "16.172.in-addr.arpa" {
    type master;
    file "/etc/bind/db.172.16";
};
```

**File: /etc/bind/db.azienda.local**

```bash
$TTL    604800
@       IN      SOA     ns1.azienda.local. admin.azienda.local. (
                              2024013001         ; Serial
                              604800             ; Refresh
                              86400              ; Retry
                              2419200            ; Expire
                              604800 )           ; Negative Cache TTL
;
@       IN      NS      ns1.azienda.local.
@       IN      A       172.16.2.10

; Name servers
ns1     IN      A       172.16.2.10

; Server records
web     IN      A       172.16.10.10
mail    IN      A       172.16.10.11
ftp     IN      A       172.16.2.12
db      IN      A       172.16.2.13

; Mail server
@       IN      MX      10 mail.azienda.local.

; Alias
www     IN      CNAME   web
```

**File: /etc/bind/db.172.16**

```bash
$TTL    604800
@       IN      SOA     ns1.azienda.local. admin.azienda.local. (
                              2024013001
                              604800
                              86400
                              2419200
                              604800 )
;
@       IN      NS      ns1.azienda.local.

; PTR Records
10.2    IN      PTR     ns1.azienda.local.
10.10   IN      PTR     web.azienda.local.
11.10   IN      PTR     mail.azienda.local.
12.2    IN      PTR     ftp.azienda.local.
13.2    IN      PTR     db.azienda.local.
```

**Comandi:**

```bash
# Verifica sintassi configurazione
sudo named-checkconf
sudo named-checkzone azienda.local /etc/bind/db.azienda.local
sudo named-checkzone 16.172.in-addr.arpa /etc/bind/db.172.16

# Riavvio servizio
sudo systemctl restart bind9

# Test DNS
nslookup web.azienda.local 172.16.2.10
dig @172.16.2.10 azienda.local
```

---

## PARTE 3: CONFIGURAZIONE FIREWALL E SICUREZZA

### 3.1 Regole Firewall (iptables Linux)

**Script: /etc/iptables/rules.sh**

```bash
#!/bin/bash

# Pulizia regole esistenti
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Policy di default
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Connessioni stabilite
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# SSH (limitato)
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# ICMP (ping) limitato
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT

# Servizi DMZ accessibili da Internet
iptables -A FORWARD -p tcp -d 172.16.10.10 --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -d 172.16.10.10 --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp -d 172.16.10.11 --dport 25 -j ACCEPT
iptables -A FORWARD -p tcp -d 172.16.10.11 --dport 587 -j ACCEPT
iptables -A FORWARD -p tcp -d 172.16.10.11 --dport 993 -j ACCEPT

# LAN verso Internet
iptables -A FORWARD -s 172.16.1.0/24 -j ACCEPT
iptables -A FORWARD -s 172.16.3.0/24 -j ACCEPT

# LAN verso Server
iptables -A FORWARD -s 172.16.1.0/24 -d 172.16.2.0/24 -j ACCEPT
iptables -A FORWARD -s 172.16.3.0/24 -d 172.16.2.0/24 -j ACCEPT

# Blocco traffico da DMZ verso LAN
iptables -A FORWARD -s 172.16.10.0/26 -d 172.16.0.0/16 -j DROP

# NAT
iptables -t nat -A POSTROUTING -s 172.16.0.0/16 -o eth0 -j MASQUERADE

# Port Forwarding per DMZ
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 172.16.10.10:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 172.16.10.10:443
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 25 -j DNAT --to-destination 172.16.10.11:25

# Logging (traffico droppato)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-DROP: " --log-level 7
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables-FORWARD-DROP: " --log-level 7

# Salvataggio regole
iptables-save > /etc/iptables/rules.v4

echo "Firewall configurato correttamente"
```

**Rendere persistente:**

```bash
# Installazione pacchetto
sudo apt-get install iptables-persistent

# Rendere eseguibile lo script
sudo chmod +x /etc/iptables/rules.sh

# Esecuzione all'avvio
echo "/etc/iptables/rules.sh" | sudo tee -a /etc/rc.local
```

### 3.2 Configurazione VPN (OpenVPN)

**Server Configuration: /etc/openvpn/server.conf**

```bash
# Porta e protocollo
port 1194
proto udp

# Device
dev tun

# Certificati e chiavi
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
tls-auth ta.key 0

# Rete VPN
server 172.16.20.0 255.255.255.192
topology subnet

# Route per LAN interna
push "route 172.16.0.0 255.255.0.0"
push "dhcp-option DNS 172.16.2.10"
push "dhcp-option DOMAIN azienda.local"

# Parametri di sicurezza
cipher AES-256-CBC
auth SHA256
tls-version-min 1.2

# Compressione
compress lz4-v2
push "compress lz4-v2"

# Utente non privilegiato
user nobody
group nogroup

# Persistenza
persist-key
persist-tun

# Log
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log
verb 3

# Keepalive
keepalive 10 120

# Numero massimo client
max-clients 50
```

**Creazione certificati:**

```bash
# Installazione EasyRSA
sudo apt-get install easy-rsa

# Inizializzazione PKI
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Modifica vars
nano vars
# Impostare:
# set_var EASYRSA_REQ_COUNTRY    "IT"
# set_var EASYRSA_REQ_PROVINCE   "Milan"
# set_var EASYRSA_REQ_CITY       "Milan"
# set_var EASYRSA_REQ_ORG        "Azienda"
# set_var EASYRSA_REQ_EMAIL      "admin@azienda.local"
# set_var EASYRSA_REQ_OU         "IT"

# Generazione CA
./easyrsa init-pki
./easyrsa build-ca nopass

# Generazione certificato server
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generazione parametri DH
./easyrsa gen-dh

# Generazione chiave TLS
openvpn --genkey --secret ta.key

# Copia file in /etc/openvpn/
sudo cp pki/ca.crt /etc/openvpn/
sudo cp pki/issued/server.crt /etc/openvpn/
sudo cp pki/private/server.key /etc/openvpn/
sudo cp pki/dh.pem /etc/openvpn/dh2048.pem
sudo cp ta.key /etc/openvpn/

# Generazione certificato client
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

**Client Configuration: client.ovpn**

```bash
client
dev tun
proto udp

remote vpn.azienda.com 1194
resolv-retry infinite

nobind
persist-key
persist-tun

remote-cert-tls server
cipher AES-256-CBC
auth SHA256

compress lz4-v2
verb 3

<ca>
# Inserire contenuto ca.crt
</ca>

<cert>
# Inserire contenuto client1.crt
</cert>

<key>
# Inserire contenuto client1.key
</key>

<tls-auth>
# Inserire contenuto ta.key
</tls-auth>
key-direction 1
```

---

## PARTE 4: CONFIGURAZIONE WEB SERVER

### 4.1 Installazione e Configurazione Apache

**Installazione:**

```bash
sudo apt-get update
sudo apt-get install apache2 php libapache2-mod-php mysql-server php-mysql
```

**Virtual Host: /etc/apache2/sites-available/azienda.conf**

```apache
<VirtualHost *:80>
    ServerName www.azienda.com
    ServerAlias azienda.com
    ServerAdmin admin@azienda.com
    
    DocumentRoot /var/www/azienda
    
    <Directory /var/www/azienda>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/azienda-error.log
    CustomLog ${APACHE_LOG_DIR}/azienda-access.log combined
    
    # Redirect HTTP to HTTPS
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName www.azienda.com
    ServerAlias azienda.com
    ServerAdmin admin@azienda.com
    
    DocumentRoot /var/www/azienda
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/azienda.crt
    SSLCertificateKeyFile /etc/ssl/private/azienda.key
    SSLCertificateChainFile /etc/ssl/certs/azienda-chain.crt
    
    # Sicurezza SSL
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder on
    
    # HSTS
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # Security Headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    
    <Directory /var/www/azienda>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/azienda-ssl-error.log
    CustomLog ${APACHE_LOG_DIR}/azienda-ssl-access.log combined
</VirtualHost>
```

**Attivazione:**

```bash
# Creazione directory
sudo mkdir -p /var/www/azienda
sudo chown -R www-data:www-data /var/www/azienda

# Abilitazione moduli
sudo a2enmod ssl
sudo a2enmod rewrite
sudo a2enmod headers

# Abilitazione sito
sudo a2ensite azienda.conf
sudo a2dissite 000-default.conf

# Riavvio Apache
sudo systemctl restart apache2
```

### 4.2 Hardening Apache

**File: /etc/apache2/conf-available/security.conf**

```apache
# Nascondere versione Apache
ServerTokens Prod
ServerSignature Off

# Timeout
Timeout 60

# Limiti di sicurezza
LimitRequestBody 10485760
LimitRequestFields 100
LimitRequestFieldSize 8190
LimitRequestLine 8190

# Disabilitare TRACE
TraceEnable Off
```

### 4.3 File di Test

**File: /var/www/azienda/index.html**

```html
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azienda - Benvenuto</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            max-width: 600px;
            text-align: center;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        p {
            color: #666;
            line-height: 1.6;
        }
        .info-box {
            background: #f5f5f5;
            padding: 20px;
            border-radius: 5px;
            margin-top: 20px;
            text-align: left;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌐 Benvenuti sul Sito Aziendale</h1>
        <p>Questo è il server web aziendale configurato nella DMZ.</p>
        
        <div class="info-box">
            <h3>Informazioni Server:</h3>
            <p><strong>IP Server:</strong> 172.16.10.10</p>
            <p><strong>Zona:</strong> DMZ</p>
            <p><strong>Protocolli:</strong> HTTP/HTTPS</p>
            <p><strong>Stato:</strong> <span style="color: green;">✓ Online</span></p>
        </div>
    </div>
</body>
</html>
```

**File: /var/www/azienda/info.php**

```php
<?php
// Informazioni PHP
phpinfo();
?>
```

---

## PARTE 5: CONFIGURAZIONE MAIL SERVER

### 5.1 Postfix (SMTP)

**Installazione:**

```bash
sudo apt-get install postfix dovecot-imapd dovecot-pop3d
```

**File: /etc/postfix/main.cf**

```bash
# Hostname
myhostname = mail.azienda.local
mydomain = azienda.local
myorigin = $mydomain

# Network
inet_interfaces = all
inet_protocols = ipv4
mynetworks = 127.0.0.0/8, 172.16.0.0/16

# Mail delivery
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain
home_mailbox = Maildir/

# SMTP Authentication
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname

# TLS
smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
smtpd_tls_key_file = /etc/ssl/private/mail.key
smtpd_use_tls = yes
smtpd_tls_security_level = may

smtp_tls_security_level = may
smtp_tls_loglevel = 1

# Restrictions
smtpd_recipient_restrictions = 
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination

smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unknown_sender_domain

# Anti-spam
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname

# Message size
message_size_limit = 20971520
```

### 5.2 Dovecot (IMAP/POP3)

**File: /etc/dovecot/dovecot.conf**

```bash
# Protocols
protocols = imap pop3 lmtp

# Listen
listen = *, ::
```

**File: /etc/dovecot/conf.d/10-mail.conf**

```bash
mail_location = maildir:~/Maildir
mail_privileged_group = mail
```

**File: /etc/dovecot/conf.d/10-auth.conf**

```bash
disable_plaintext_auth = no
auth_mechanisms = plain login
```

**File: /etc/dovecot/conf.d/10-master.conf**

```bash
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}
```

**File: /etc/dovecot/conf.d/10-ssl.conf**

```bash
ssl = yes
ssl_cert = </etc/ssl/certs/mail.crt
ssl_key = </etc/ssl/private/mail.key
```

**Comandi:**

```bash
# Riavvio servizi
sudo systemctl restart postfix
sudo systemctl restart dovecot

# Test SMTP
telnet localhost 25
EHLO localhost
QUIT

# Test IMAP
telnet localhost 143
```

---

## PARTE 6: MONITORING E TROUBLESHOOTING

### 6.1 Script di Monitoring

**File: /usr/local/bin/network-monitor.sh**

```bash
#!/bin/bash

LOG_FILE="/var/log/network-monitor.log"
ALERT_EMAIL="admin@azienda.local"

# Funzione per logging
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check connettività Internet
check_internet() {
    if ping -c 3 8.8.8.8 &> /dev/null; then
        log_message "✓ Connessione Internet OK"
        return 0
    else
        log_message "✗ ALERT: Connessione Internet DOWN"
        return 1
    fi
}

# Check DNS
check_dns() {
    if nslookup www.google.com &> /dev/null; then
        log_message "✓ DNS OK"
        return 0
    else
        log_message "✗ ALERT: DNS non funzionante"
        return 1
    fi
}

# Check servizi locali
check_service() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        log_message "✓ Servizio $service attivo"
        return 0
    else
        log_message "✗ ALERT: Servizio $service non attivo"
        return 1
    fi
}

# Check porte
check_port() {
    local host=$1
    local port=$2
    local name=$3
    
    if nc -z -w3 "$host" "$port" &> /dev/null; then
        log_message "✓ $name ($host:$port) raggiungibile"
        return 0
    else
        log_message "✗ ALERT: $name ($host:$port) non raggiungibile"
        return 1
    fi
}

# Check utilizzo CPU
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    log_message "CPU Usage: ${cpu_usage}%"
    
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        log_message "✗ ALERT: Utilizzo CPU elevato (${cpu_usage}%)"
        return 1
    fi
    return 0
}

# Check utilizzo RAM
check_memory() {
    local mem_usage=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
    log_message "Memory Usage: ${mem_usage}%"
    
    if (( $(echo "$mem_usage > 80" | bc -l) )); then
        log_message "✗ ALERT: Utilizzo RAM elevato (${mem_usage}%)"
        return 1
    fi
    return 0
}

# Check spazio disco
check_disk() {
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    log_message "Disk Usage: ${disk_usage}%"
    
    if [ "$disk_usage" -gt 80 ]; then
        log_message "✗ ALERT: Spazio disco basso (${disk_usage}%)"
        return 1
    fi
    return 0
}

# Main
main() {
    log_message "=== Avvio controlli di rete ==="
    
    check_internet
    check_dns
    check_service "apache2"
    check_service "postfix"
    check_service "dovecot"
    check_service "bind9"
    check_service "isc-dhcp-server"
    
    check_port "172.16.10.10" "80" "Web Server HTTP"
    check_port "172.16.10.10" "443" "Web Server HTTPS"
    check_port "172.16.10.11" "25" "Mail Server SMTP"
    check_port "172.16.10.11" "993" "Mail Server IMAPS"
    
    check_cpu
    check_memory
    check_disk
    
    log_message "=== Controlli completati ==="
}

# Esecuzione
main
```

**Crontab per esecuzione automatica:**

```bash
# Esegui ogni 5 minuti
*/5 * * * * /usr/local/bin/network-monitor.sh

# Report giornaliero alle 8:00
0 8 * * * /usr/local/bin/network-monitor.sh | mail -s "Network Status Report" admin@azienda.local
```

### 6.2 Comandi di Troubleshooting

**Verifica connettività:**

```bash
# Ping
ping -c 4 8.8.8.8
ping -c 4 www.google.com

# Traceroute
traceroute www.google.com
mtr www.google.com

# DNS lookup
nslookup www.google.com
dig www.google.com
host www.google.com

# Verifica route
ip route show
route -n

# Verifica ARP
arp -a
ip neigh show
```

**Verifica porte e connessioni:**

```bash
# Porte in ascolto
netstat -tulpn
ss -tulpn

# Connessioni attive
netstat -an
ss -tan

# Verifica porta specifica
nc -zv 172.16.10.10 80
telnet 172.16.10.10 80
```

**Verifica interfacce di rete:**

```bash
# Stato interfacce
ip link show
ip addr show
ifconfig -a

# Statistiche interfacce
ip -s link
ifconfig -a

# Verifica errori
ethtool eth0
```

**Analisi traffico:**

```bash
# tcpdump
sudo tcpdump -i eth0
sudo tcpdump -i eth0 port 80
sudo tcpdump -i eth0 host 172.16.10.10
sudo tcpdump -i eth0 -w capture.pcap

# ngrep
sudo ngrep -q -W byline port 80

# Wireshark (GUI)
sudo wireshark
```

**Log analysis:**

```bash
# Apache logs
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/error.log

# Mail logs
sudo tail -f /var/log/mail.log

# System logs
sudo tail -f /var/log/syslog
sudo journalctl -f

# Firewall logs
sudo tail -f /var/log/kern.log | grep iptables
```

---

## PARTE 7: DOCUMENTAZIONE DI RETE

### 7.1 Documentazione Dispositivi

| Dispositivo | Hostname | IP Address | Subnet Mask | Gateway | Funzione |
|-------------|----------|------------|-------------|---------|----------|
| Router | Router-Gateway | 172.16.0.1 | 255.255.0.0 | ISP | Gateway principale |
| Firewall | Firewall-Main | 172.16.0.2 | 255.255.0.0 | 172.16.0.1 | Firewall/UTM |
| Switch Core | Switch-Core | 172.16.30.2 | 255.255.255.240 | 172.16.30.1 | Switch principale |
| Switch LAN1 | Switch-LAN1 | 172.16.30.3 | 255.255.255.240 | 172.16.30.1 | Switch utenti |
| Switch LAN2 | Switch-LAN2 | 172.16.30.4 | 255.255.255.240 | 172.16.30.1 | Switch server |
| Switch DMZ | Switch-DMZ | 172.16.30.5 | 255.255.255.240 | 172.16.30.1 | Switch DMZ |
| DNS Server | srv-dns | 172.16.2.10 | 255.255.255.0 | 172.16.2.1 | DNS primario |
| DHCP Server | srv-dhcp | 172.16.2.11 | 255.255.255.0 | 172.16.2.1 | DHCP server |
| File Server | srv-file | 172.16.2.12 | 255.255.255.0 | 172.16.2.1 | Storage condiviso |
| DB Server | srv-db | 172.16.2.13 | 255.255.255.0 | 172.16.2.1 | Database |
| Web Server | srv-web | 172.16.10.10 | 255.255.255.192 | 172.16.10.1 | Web pubblico |
| Mail Server | srv-mail | 172.16.10.11 | 255.255.255.192 | 172.16.10.1 | Email server |

### 7.2 Porte e Protocolli

| Servizio | Porta | Protocollo | Descrizione |
|----------|-------|------------|-------------|
| HTTP | 80 | TCP | Web non crittografato |
| HTTPS | 443 | TCP | Web crittografato |
| SSH | 22 | TCP | Amministrazione remota |
| FTP | 21 | TCP | Trasferimento file |
| SFTP | 22 | TCP | FTP sicuro |
| SMTP | 25 | TCP | Invio email |
| SMTPS | 465 | TCP | SMTP sicuro |
| Submission | 587 | TCP | Invio email autenticato |
| POP3 | 110 | TCP | Ricezione email |
| POP3S | 995 | TCP | POP3 sicuro |
| IMAP | 143 | TCP | Accesso email |
| IMAPS | 993 | TCP | IMAP sicuro |
| DNS | 53 | TCP/UDP | Risoluzione nomi |
| DHCP | 67-68 | UDP | Assegnazione IP |
| NTP | 123 | UDP | Sincronizzazione ora |
| SNMP | 161-162 | UDP | Monitoring |
| OpenVPN | 1194 | UDP | VPN |
| RDP | 3389 | TCP | Desktop remoto |
| MySQL | 3306 | TCP | Database |
| PostgreSQL | 5432 | TCP | Database |

### 7.3 Credenziali (Template)

**IMPORTANTE: Questo è un template. Le credenziali reali devono essere custodite in modo sicuro.**

```
=== CREDENZIALI DI RETE ===

ROUTER
------
Device: Router-Gateway
IP: 172.16.0.1
Username: admin
Password: [STORED IN PASSWORD MANAGER]
Enable Secret: [STORED IN PASSWORD MANAGER]

SWITCH CORE
-----------
Device: Switch-Core
IP: 172.16.30.2
Username: admin
Password: [STORED IN PASSWORD MANAGER]

WEB SERVER
----------
Server: srv-web (172.16.10.10)
SSH User: sysadmin
SSH Password: [STORED IN PASSWORD MANAGER]
MySQL Root: [STORED IN PASSWORD MANAGER]

MAIL SERVER
-----------
Server: srv-mail (172.16.10.11)
SSH User: sysadmin
SSH Password: [STORED IN PASSWORD MANAGER]
Postfix Admin: [STORED IN PASSWORD MANAGER]

VPN SERVER
----------
Server: vpn.azienda.com
Admin User: vpnadmin
Admin Password: [STORED IN PASSWORD MANAGER]
Certificate Password: [STORED IN PASSWORD MANAGER]

FIREWALL
--------
Device: Firewall-Main
IP: 172.16.0.2
WebUI: https://172.16.0.2:8443
Username: admin
Password: [STORED IN PASSWORD MANAGER]
```

---

## PARTE 8: PROCEDURE DI BACKUP E DISASTER RECOVERY

### 8.1 Script di Backup

**File: /usr/local/bin/backup-network.sh**

```bash
#!/bin/bash

BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Creazione directory backup
mkdir -p "$BACKUP_DIR"/{configs,databases,files}

# Backup configurazioni router/switch (via TFTP o SSH)
backup_configs() {
    echo "Backup configurazioni dispositivi di rete..."
    
    # Router
    sshpass -p 'password' ssh admin@172.16.0.1 "show running-config" > \
        "$BACKUP_DIR/configs/router-$DATE.conf"
    
    # Switch Core
    sshpass -p 'password' ssh admin@172.16.30.2 "show running-config" > \
        "$BACKUP_DIR/configs/switch-core-$DATE.conf"
}

# Backup configurazioni server
backup_server_configs() {
    echo "Backup configurazioni server..."
    
    tar -czf "$BACKUP_DIR/configs/apache-$DATE.tar.gz" \
        /etc/apache2/ 2>/dev/null
    
    tar -czf "$BACKUP_DIR/configs/postfix-$DATE.tar.gz" \
        /etc/postfix/ /etc/dovecot/ 2>/dev/null
    
    tar -czf "$BACKUP_DIR/configs/bind-$DATE.tar.gz" \
        /etc/bind/ 2>/dev/null
    
    tar -czf "$BACKUP_DIR/configs/iptables-$DATE.tar.gz" \
        /etc/iptables/ 2>/dev/null
    
    tar -czf "$BACKUP_DIR/configs/openvpn-$DATE.tar.gz" \
        /etc/openvpn/ 2>/dev/null
}

# Backup database
backup_databases() {
    echo "Backup database..."
    
    # MySQL
    mysqldump -u root -p'password' --all-databases | \
        gzip > "$BACKUP_DIR/databases/mysql-all-$DATE.sql.gz"
}

# Backup siti web
backup_websites() {
    echo "Backup siti web..."
    
    tar -czf "$BACKUP_DIR/files/www-$DATE.tar.gz" \
        /var/www/ 2>/dev/null
}

# Backup email
backup_mail() {
    echo "Backup email..."
    
    tar -czf "$BACKUP_DIR/files/mail-$DATE.tar.gz" \
        /var/mail/ /home/*/Maildir/ 2>/dev/null
}

# Pulizia backup vecchi
cleanup_old_backups() {
    echo "Pulizia backup più vecchi di $RETENTION_DAYS giorni..."
    
    find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -delete
}

# Verifica integrità backup
verify_backup() {
    echo "Verifica integrità backup..."
    
    for file in "$BACKUP_DIR"/*/*.tar.gz; do
        if [ -f "$file" ]; then
            if tar -tzf "$file" &>/dev/null; then
                echo "✓ $file OK"
            else
                echo "✗ $file CORROTTO"
            fi
        fi
    done
}

# Main
main() {
    echo "=== Avvio backup $(date) ==="
    
    backup_configs
    backup_server_configs
    backup_databases
    backup_websites
    backup_mail
    cleanup_old_backups
    verify_backup
    
    echo "=== Backup completato $(date) ==="
}

# Esecuzione
main 2>&1 | tee -a /var/log/backup.log
```

**Crontab:**

```bash
# Backup completo giornaliero alle 2:00
0 2 * * * /usr/local/bin/backup-network.sh

# Backup incrementale ogni 6 ore
0 */6 * * * /usr/local/bin/backup-incremental.sh
```

### 8.2 Piano di Disaster Recovery

**Procedura di ripristino:**

1. **Ripristino Router**
   ```bash
   # Via console
   enable
   copy tftp://172.16.2.12/router-backup.conf running-config
   write memory
   ```

2. **Ripristino Switch**
   ```bash
   enable
   copy tftp://172.16.2.12/switch-backup.conf running-config
   write memory
   ```

3. **Ripristino Server Web**
   ```bash
   # Ripristino configurazione Apache
   tar -xzf /backup/configs/apache-YYYYMMDD.tar.gz -C /
   
   # Ripristino sito
   tar -xzf /backup/files/www-YYYYMMDD.tar.gz -C /
   
   systemctl restart apache2
   ```

4. **Ripristino Database**
   ```bash
   gunzip < /backup/databases/mysql-all-YYYYMMDD.sql.gz | \
       mysql -u root -p
   ```

5. **Ripristino Mail Server**
   ```bash
   tar -xzf /backup/configs/postfix-YYYYMMDD.tar.gz -C /
   tar -xzf /backup/files/mail-YYYYMMDD.tar.gz -C /
   
   systemctl restart postfix dovecot
   ```

---

## PARTE 9: TESTING E VALIDAZIONE

### 9.1 Test di Connettività

**Script: /usr/local/bin/test-network.sh**

```bash
#!/bin/bash

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_ping() {
    local host=$1
    local name=$2
    
    if ping -c 3 -W 2 "$host" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $name ($host) raggiungibile"
        return 0
    else
        echo -e "${RED}✗${NC} $name ($host) NON raggiungibile"
        return 1
    fi
}

test_http() {
    local url=$1
    local expected_code=${2:-200}
    
    local code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$code" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓${NC} HTTP $url -> $code"
        return 0
    else
        echo -e "${RED}✗${NC} HTTP $url -> $code (atteso: $expected_code)"
        return 1
    fi
}

test_smtp() {
    local host=$1
    local port=25
    
    if echo "QUIT" | nc -w 3 "$host" "$port" 2>/dev/null | grep -q "220"; then
        echo -e "${GREEN}✓${NC} SMTP $host:$port funzionante"
        return 0
    else
        echo -e "${RED}✗${NC} SMTP $host:$port NON funzionante"
        return 1
    fi
}

test_dns() {
    local domain=$1
    
    if nslookup "$domain" 172.16.2.10 &>/dev/null; then
        local ip=$(nslookup "$domain" 172.16.2.10 | grep "Address:" | tail -1 | awk '{print $2}')
        echo -e "${GREEN}✓${NC} DNS: $domain -> $ip"
        return 0
    else
        echo -e "${RED}✗${NC} DNS: $domain non risolvibile"
        return 1
    fi
}

# Test suite completo
echo "=== Test di Rete ==="
echo

echo "--- Test Connettività Interna ---"
test_ping "172.16.1.1" "Gateway LAN1"
test_ping "172.16.2.1" "Gateway LAN2"
test_ping "172.16.10.10" "Web Server"
test_ping "172.16.10.11" "Mail Server"
echo

echo "--- Test Connettività Esterna ---"
test_ping "8.8.8.8" "Google DNS"
test_ping "www.google.com" "Google Web"
echo

echo "--- Test DNS ---"
test_dns "web.azienda.local"
test_dns "mail.azienda.local"
test_dns "www.google.com"
echo

echo "--- Test HTTP/HTTPS ---"
test_http "http://172.16.10.10"
test_http "https://172.16.10.10"
echo

echo "--- Test Mail ---"
test_smtp "172.16.10.11"
echo

echo "=== Test Completati ==="
```

### 9.2 Test di Sicurezza

**Port Scanning:**

```bash
# Scan porte Web Server
nmap -sV -p 1-65535 172.16.10.10

# Scan vulnerabilità
nmap --script vuln 172.16.10.10

# Verifica firewall
nmap -sA -P0 172.16.10.10
```

**Verifica SSL/TLS:**

```bash
# Test SSL con OpenSSL
openssl s_client -connect 172.16.10.10:443

# Test con nmap
nmap --script ssl-enum-ciphers -p 443 172.16.10.10

# Test con testssl.sh
./testssl.sh https://172.16.10.10
```

### 9.3 Test di Carico

**Apache Benchmark:**

```bash
# Test 1000 richieste, 10 concurrent
ab -n 1000 -c 10 http://172.16.10.10/

# Test con keep-alive
ab -n 1000 -c 10 -k http://172.16.10.10/

# Test POST
ab -n 100 -c 10 -p post.txt -T "application/x-www-form-urlencoded" \
    http://172.16.10.10/form.php
```

---

## CONCLUSIONI

Questa soluzione fornisce:

1. **Architettura di rete completa** con separazione logica tra zone (LAN, Server, DMZ)
2. **Piano di indirizzamento dettagliato** con subnetting appropriato
3. **Configurazioni complete** di tutti i dispositivi di rete (router, switch, firewall)
4. **Servizi essenziali** configurati (DNS, DHCP, Web, Mail, VPN)
5. **Sicurezza a livelli** con firewall, regole iptables, VPN, SSL/TLS
6. **Monitoring e troubleshooting** con script automatizzati
7. **Backup e disaster recovery** con procedure documentate
8. **Testing completo** della soluzione

La rete progettata è:
- **Scalabile**: può crescere facilmente
- **Sicura**: con multiple barriere di protezione
- **Affidabile**: con ridondanza e backup
- **Monitorabile**: con strumenti di controllo
- **Documentata**: con tutta la configurazione tracciata

---

## ALLEGATI

### A. Comandi Quick Reference

```bash
# Verifica IP
ip addr show

# Verifica route
ip route show

# Test connettività
ping -c 4 [IP]

# Test DNS
nslookup [domain]

# Test porta
nc -zv [IP] [PORT]

# Verifica servizi
systemctl status [service]

# Log in tempo reale
tail -f /var/log/syslog

# Backup rapido
tar -czf backup.tar.gz [directory]
```

### B. Riferimenti

- RFC 1918: Address Allocation for Private Internets
- RFC 2131: Dynamic Host Configuration Protocol
- RFC 5321: Simple Mail Transfer Protocol
- RFC 6749: OAuth 2.0 Authorization Framework
- NIST Cybersecurity Framework
- OWASP Top 10

---

**Data**: 30 Gennaio 2026  
**Autore**: Soluzione Esame A038_STR24  
**Versione**: 1.0
