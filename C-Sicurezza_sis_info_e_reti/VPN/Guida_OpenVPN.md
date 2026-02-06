# Guida Completa OpenVPN

## Indice

1. [Introduzione](#introduzione)
2. [Installazione](#installazione)
3. [Architettura e Componenti](#architettura-e-componenti)
4. [PKI e Gestione Certificati](#pki-e-gestione-certificati)
5. [Configurazione Server Remote Access](#configurazione-server-remote-access)
6. [Configurazione Client](#configurazione-client)
7. [Site-to-Site VPN](#site-to-site-vpn)
8. [Sicurezza Avanzata](#sicurezza-avanzata)
9. [Ottimizzazione Performance](#ottimizzazione-performance)
10. [Troubleshooting](#troubleshooting)
11. [Script e Automazione](#script-e-automazione)

---

## Introduzione

OpenVPN è una soluzione VPN SSL/TLS open source estremamente flessibile e sicura. Supporta autenticazione con certificati X.509, pre-shared keys, e integrazione con sistemi di autenticazione esterni (LDAP, RADIUS).

### Caratteristiche Principali

- **Protocollo**: SSL/TLS per key exchange
- **Trasporto**: UDP (default) o TCP
- **Encryption**: AES-256-GCM (raccomandato), AES-256-CBC, ChaCha20-Poly1305
- **Authentication**: SHA256, SHA512
- **Porte**: 1194/UDP (default), configurabile
- **Piattaforme**: Linux, Windows, macOS, iOS, Android, FreeBSD

### Vantaggi

✅ **Flessibilità**: Configurabile per quasi ogni scenario  
✅ **Firewall-friendly**: Usa UDP/TCP standard, facile da far passare  
✅ **Maturità**: 20+ anni di sviluppo, battle-tested  
✅ **Cross-platform**: Client per tutti i sistemi operativi  
✅ **Community**: Vasta community e documentazione  

### Svantaggi

❌ **Complessità**: Setup iniziale più complesso di WireGuard  
❌ **Performance**: Più lento di WireGuard (ma ancora molto performante)  
❌ **Codebase**: ~70,000 linee vs ~4,000 di WireGuard  

---

## Installazione

### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install OpenVPN and Easy-RSA (for PKI)
sudo apt install -y openvpn easy-rsa

# Verify installation
openvpn --version
# Output: OpenVPN 2.6.x x86_64-pc-linux-gnu
```

### CentOS/RHEL/Rocky Linux

```bash
# Install EPEL repository (Extra Packages for Enterprise Linux)
sudo dnf install -y epel-release

# Install OpenVPN
sudo dnf install -y openvpn easy-rsa

# Verify
openvpn --version
```

### Windows

1. Download installer: https://openvpn.net/community-downloads/
2. Esegui installer (richiede privilegi amministratore)
3. Install location: `C:\Program Files\OpenVPN`
4. OpenVPN GUI incluso

### macOS

```bash
# Using Homebrew
brew install openvpn

# Or download Tunnelblick (GUI client)
# https://tunnelblick.net/
```

### Compilazione da Sorgente (opzionale)

```bash
# Install dependencies
sudo apt install -y build-essential libssl-dev liblzo2-dev \
    libpam0g-dev libpkcs11-helper1-dev libsystemd-dev

# Download latest source
wget https://swupdate.openvpn.org/community/releases/openvpn-2.6.8.tar.gz
tar xzf openvpn-2.6.8.tar.gz
cd openvpn-2.6.8

# Configure and compile
./configure --enable-systemd --enable-pkcs11
make
sudo make install

# Verify
openvpn --version
```

---

## Architettura e Componenti

### Architettura OpenVPN

```
┌─────────────────────────────────────────────────────────┐
│                    OpenVPN Client                       │
│  ┌──────────────┐         ┌─────────────┐               │
│  │ Application  │ ←─────→ │  TUN/TAP    │               │
│  │   (Browser)  │         │  Interface  │               │
│  └──────────────┘         └──────┬──────┘               │
│                                   │                     │
│                           ┌───────▼────────┐            │
│                           │  OpenVPN Core  │            │
│                           │  (SSL/TLS)     │            │
│                           └───────┬────────┘            │
│                                   │                     │
│                           ┌───────▼────────┐            │
│                           │   UDP/TCP      │            │
│                           │   Socket       │            │
└───────────────────────────┴────────┬───────┴────────────┘
                                     │
                              Internet/WAN
                                     │
┌────────────────────────────────────▼────────────────────┐
│                    OpenVPN Server                       │
│                           ┌────────────┐                │
│                           │  UDP/TCP   │                │
│                           │  Socket    │                │
│                           └──────┬─────┘                │
│                                  │                      │
│                           ┌──────▼──────┐               │
│                           │ OpenVPN Core│               │
│                           │ (SSL/TLS)   │               │
│                           └──────┬──────┘               │
│                                  │                      │
│  ┌──────────────┐         ┌─────▼──────┐                │
│  │ Internal LAN │ ←─────→ │  TUN/TAP   │                │
│  │  Resources   │         │  Interface │                │
│  └──────────────┘         └────────────┘                │
└─────────────────────────────────────────────────────────┘
```

### Componenti Chiave

#### 1. TUN/TAP Devices

**TUN (Layer 3 - IP tunnel)**:
- Opera a livello network (IP packets)
- Più efficiente per routing IP standard
- Default per la maggior parte delle configurazioni

```bash
# Verifica TUN device
ip link show tun0
# Output: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP>
```

**TAP (Layer 2 - Ethernet tunnel)**:
- Opera a livello data link (Ethernet frames)
- Supporta broadcast, DHCP bridging
- Necessario per bridging completo

```bash
# TAP device
ip link show tap0
# Output: tap0: <BROADCAST,MULTICAST,UP,LOWER_UP>
```

#### 2. OpenVPN Process

```bash
# Check running process
ps aux | grep openvpn
# root  1234  openvpn --config server.conf --daemon

# Check listening ports
ss -tulnp | grep openvpn
# udp  UNCONN  0  0  *:1194  *:*  users:(("openvpn",pid=1234))
```

#### 3. Configuration Files

**Struttura directory standard**:
```
/etc/openvpn/
├── server/
│   ├── server.conf          # Server configuration
│   ├── ca.crt               # Certificate Authority
│   ├── server.crt           # Server certificate
│   ├── server.key           # Server private key
│   ├── dh.pem               # Diffie-Hellman parameters
│   ├── ta.key               # TLS-Auth/TLS-Crypt key
│   └── ccd/                 # Client Config Directory
│       └── client1          # Per-client settings
├── client/
│   └── client.conf          # Client configuration
├── easy-rsa/                # PKI management
└── scripts/                 # Custom scripts
```

---

## PKI e Gestione Certificati

### Setup Easy-RSA

```bash
# Copy Easy-RSA template
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Customize vars file
cat > vars <<'EOF'
# Easy-RSA Variables
set_var EASYRSA_REQ_COUNTRY    "IT"
set_var EASYRSA_REQ_PROVINCE   "Lombardia"
set_var EASYRSA_REQ_CITY       "Milano"
set_var EASYRSA_REQ_ORG        "MyCompany S.r.l."
set_var EASYRSA_REQ_EMAIL      "vpn-admin@mycompany.com"
set_var EASYRSA_REQ_OU         "IT Security"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_ALGO           rsa
set_var EASYRSA_CA_EXPIRE      3650   # 10 years
set_var EASYRSA_CERT_EXPIRE    825    # ~2 years (Apple requirement)
set_var EASYRSA_DIGEST         "sha256"
EOF

# Initialize PKI
./easyrsa init-pki
# Output: init-pki complete; you may now create a CA or requests.
```

### Creazione Certificate Authority (CA)

```bash
# Build CA (senza password per automazione - opzionale)
./easyrsa build-ca nopass

# Output:
# Using Easy-RSA configuration from: ./vars
# Using SSL: openssl OpenSSL 3.0.2
# 
# Enter New CA Key Passphrase: [ENTER for nopass]
# Re-Enter New CA Key Passphrase: [ENTER]
# Common Name (eg: your user, host, or server name) [Easy-RSA CA]: MyCompany VPN CA
# 
# CA creation complete and you may now import and sign cert requests.
# Your new CA certificate file for publishing is at:
# /home/user/openvpn-ca/pki/ca.crt

# Backup CA key (IMPORTANTE!)
sudo cp pki/private/ca.key /secure/backup/location/
sudo chmod 400 /secure/backup/location/ca.key
```

### Generazione Server Certificate

```bash
# Generate server certificate request
./easyrsa gen-req server nopass

# Common Name: vpn.mycompany.com

# Sign server certificate
./easyrsa sign-req server server

# Confirm: yes
# Output: Certificate created at: /home/user/openvpn-ca/pki/issued/server.crt

# Generate Diffie-Hellman parameters (può richiedere diversi minuti)
./easyrsa gen-dh

# Output: DH parameters of size 2048 created at /home/user/openvpn-ca/pki/dh.pem

# Generate TLS-Crypt key (extra security layer)
openvpn --genkey secret pki/ta.key
```

### Generazione Client Certificates

```bash
# Client 1
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Client 2
./easyrsa gen-req client2 nopass
./easyrsa sign-req client client2

# Client 3 (con password - more secure)
./easyrsa gen-req client3
# Enter PEM pass phrase: ********
./easyrsa sign-req client client3

# List all certificates
./easyrsa show-cert client1
```

### Revoca Certificati

```bash
# Revoke compromised certificate
./easyrsa revoke client1

# Reason: keyCompromise

# Generate Certificate Revocation List (CRL)
./easyrsa gen-crl

# Output: CRL file: /home/user/openvpn-ca/pki/crl.pem

# Copy CRL to OpenVPN server
sudo cp pki/crl.pem /etc/openvpn/server/

# Add to server.conf:
# crl-verify /etc/openvpn/server/crl.pem

# Reload OpenVPN to apply
sudo systemctl reload openvpn-server@server
```

### Rinnovo Certificati

```bash
# Renew certificate (prima della scadenza)
./easyrsa renew client1 nopass

# Batch renewal (per tutti i cert che scadono entro 30 giorni)
for cert in pki/issued/*.crt; do
    cn=$(basename "$cert" .crt)
    if ./easyrsa show-cert "$cn" | grep -q "Not After.*$(date -d '+30 days' +%Y)"; then
        echo "Renewing $cn"
        ./easyrsa renew "$cn" nopass
    fi
done
```

### Copy Certificates to Server

```bash
# Copy to OpenVPN server directory
sudo cp pki/ca.crt /etc/openvpn/server/
sudo cp pki/issued/server.crt /etc/openvpn/server/
sudo cp pki/private/server.key /etc/openvpn/server/
sudo cp pki/dh.pem /etc/openvpn/server/
sudo cp pki/ta.key /etc/openvpn/server/

# Set permissions
sudo chmod 600 /etc/openvpn/server/server.key
sudo chmod 600 /etc/openvpn/server/ta.key
sudo chown root:root /etc/openvpn/server/*
```

---

## Configurazione Server Remote Access

### Server Configuration (Production-Ready)

```bash
# /etc/openvpn/server/server.conf
cat > /etc/openvpn/server/server.conf <<'EOF'
#######################################
# OpenVPN Server Configuration
# Remote Access VPN
#######################################

# Network Settings
port 1194
proto udp                    # UDP per performance, TCP per firewall restrictive
dev tun
topology subnet

# Certificates and Keys
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-crypt ta.key            # Migliore di tls-auth (encrypts control channel)

# VPN Network
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Push Routes to Clients
push "route 192.168.1.0 255.255.255.0"    # Internal LAN
push "route 192.168.10.0 255.255.255.0"   # Additional subnet

# DNS Configuration
push "dhcp-option DNS 192.168.1.1"        # Internal DNS
push "dhcp-option DNS 8.8.8.8"            # Fallback DNS
push "dhcp-option DOMAIN mycompany.local"

# Redirect Gateway (all traffic through VPN - optional)
# push "redirect-gateway def1 bypass-dhcp"

# Client-to-Client Communication (optional)
# client-to-client

# Keepalive
keepalive 10 120

# Cryptographic Settings
cipher AES-256-GCM          # Modern AEAD cipher
auth SHA256                 # HMAC authentication
tls-version-min 1.2         # Minimum TLS 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384:TLS-ECDHE-RSA-WITH-AES-256-CBC-SHA384

# Performance Tuning
sndbuf 393216               # 384 KB
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"
fast-io                     # Optimize I/O

# Compression (disable - security risk)
comp-lzo no
push "comp-lzo no"

# Maximum Clients
max-clients 100

# User/Group Privileges (security)
user nobody
group nogroup

# Persistence
persist-key
persist-tun

# Client Configuration Directory
client-config-dir /etc/openvpn/ccd

# Logging
status /var/log/openvpn/openvpn-status.log
log-append /var/log/openvpn/openvpn.log
verb 3                      # 0=silent, 9=verbose
mute 20                     # Mute repeated messages

# Explicit Exit Notify
explicit-exit-notify 1

# Management Interface (for monitoring)
management localhost 7505

# Security: Revocation List
crl-verify /etc/openvpn/server/crl.pem

# Scripts (optional)
script-security 2
# client-connect /etc/openvpn/scripts/client-connect.sh
# client-disconnect /etc/openvpn/scripts/client-disconnect.sh
# auth-user-pass-verify /etc/openvpn/scripts/auth-ldap.sh via-file

EOF
```

### System Configuration

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf

# Disable ICMP redirects (security)
sudo sysctl -w net.ipv4.conf.all.send_redirects=0
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0

# Apply sysctl changes
sudo sysctl -p

# Firewall rules (iptables)
# Allow OpenVPN port
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Allow TUN interface
sudo iptables -A INPUT -i tun0 -j ACCEPT
sudo iptables -A FORWARD -i tun0 -j ACCEPT
sudo iptables -A FORWARD -o tun0 -j ACCEPT

# NAT for VPN clients to access Internet/LAN
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Save iptables rules (Ubuntu/Debian)
sudo apt install iptables-persistent
sudo netfilter-persistent save

# Or manually save
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Start OpenVPN Server

```bash
# Create log directory
sudo mkdir -p /var/log/openvpn

# Test configuration
sudo openvpn --config /etc/openvpn/server/server.conf

# If OK, stop with Ctrl+C and start as service

# Enable and start service
sudo systemctl enable openvpn-server@server
sudo systemctl start openvpn-server@server

# Check status
sudo systemctl status openvpn-server@server

# Check logs
sudo tail -f /var/log/openvpn/openvpn.log

# Verify TUN interface
ip addr show tun0
```

---

## Configurazione Client

### Linux Client Configuration

```bash
# /etc/openvpn/client/client.conf
cat > ~/client.ovpn <<'EOF'
client
dev tun
proto udp

# Server address (use multiple for redundancy)
remote vpn.mycompany.com 1194
remote vpn2.mycompany.com 1194

resolv-retry infinite
nobind
persist-key
persist-tun

# Certificates (inline - convenient for distribution)
<ca>
-----BEGIN CERTIFICATE-----
[PASTE ca.crt CONTENT HERE]
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
[PASTE client.crt CONTENT HERE]
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
[PASTE client.key CONTENT HERE]
-----END PRIVATE KEY-----
</key>

<tls-crypt>
-----BEGIN OpenVPN Static key V1-----
[PASTE ta.key CONTENT HERE]
-----END OpenVPN Static key V1-----
</tls-crypt>

# Cryptographic settings
cipher AES-256-GCM
auth SHA256
remote-cert-tls server      # Verify server certificate
tls-version-min 1.2

# Compression
comp-lzo no

# Logging
verb 3

# Additional security
pull                         # Accept pushed options from server
auth-retry interact          # Ask for credentials again if auth fails

# Windows specific (uncomment if on Windows)
# block-outside-dns          # Prevent DNS leaks
# route-method exe
# route-delay 2

# Linux specific DNS update (uncomment if needed)
# script-security 2
# up /etc/openvpn/update-resolv-conf
# down /etc/openvpn/update-resolv-conf

EOF
```

### Generare File .ovpn con Script

```bash
#!/bin/bash
# make-client-config.sh

CLIENT_NAME="$1"
SERVER_ADDRESS="vpn.mycompany.com"
CA_DIR="/home/user/openvpn-ca/pki"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name>"
    exit 1
fi

cat > "${CLIENT_NAME}.ovpn" <<EOF
client
dev tun
proto udp
remote ${SERVER_ADDRESS} 1194
resolv-retry infinite
nobind
persist-key
persist-tun

<ca>
$(cat "${CA_DIR}/ca.crt")
</ca>

<cert>
$(cat "${CA_DIR}/issued/${CLIENT_NAME}.crt")
</cert>

<key>
$(cat "${CA_DIR}/private/${CLIENT_NAME}.key")
</key>

<tls-crypt>
$(cat "${CA_DIR}/ta.key")
</tls-crypt>

cipher AES-256-GCM
auth SHA256
remote-cert-tls server
tls-version-min 1.2
comp-lzo no
verb 3
pull
auth-retry interact
EOF

echo "Configuration file created: ${CLIENT_NAME}.ovpn"
```

### Utilizzo Script

```bash
chmod +x make-client-config.sh
./make-client-config.sh client1
# Output: Configuration file created: client1.ovpn

# Trasferisci client1.ovpn al client (SCP, email cifrata, USB)
```

### Connessione Client Linux

```bash
# Connect (foreground - for testing)
sudo openvpn --config client.ovpn

# Connect as daemon
sudo openvpn --config client.ovpn --daemon

# Using systemd
sudo cp client.ovpn /etc/openvpn/client/mycompany.conf
sudo systemctl start openvpn-client@mycompany
sudo systemctl enable openvpn-client@mycompany

# Check connection
ip addr show tun0
ping 10.8.0.1        # VPN gateway
ping 192.168.1.1     # Internal resource
```

### Windows Client

1. **Installare OpenVPN GUI**
2. **Copiare `client.ovpn`** in `C:\Program Files\OpenVPN\config\`
3. **Right-click OpenVPN icon** in system tray
4. **Select "Connect"**

### macOS Client (Tunnelblick)

1. **Download Tunnelblick**: https://tunnelblick.net/
2. **Install**
3. **Double-click `client.ovpn`** file
4. **Tunnelblick imports** configuration
5. **Click "Connect"** from menu bar

### Mobile Clients

**Android/iOS**:
1. Install **OpenVPN Connect** app
2. Transfer `.ovpn` file via email/cloud/QR code
3. Import in app
4. Connect

**QR Code Generation (per mobile)**:
```bash
# Install qrencode
sudo apt install qrencode

# Generate QR code from .ovpn
qrencode -t ANSIUTF8 < client.ovpn
# Scan con OpenVPN Connect app
```

---

## Site-to-Site VPN

### Topology

```
Site A (HQ)                          Site B (Branch)
192.168.1.0/24                       192.168.2.0/24
       |                                    |
   Gateway A                            Gateway B
   eth0: 203.0.113.100                 eth0: 198.51.100.200
   tun0: 10.8.0.1                      tun0: 10.8.0.2
       |                                    |
       +-------------- Internet -------------+
```

### Site A Configuration (Server Mode)

```bash
# /etc/openvpn/server/site-b.conf
port 1194
proto udp
dev tun

# Topology
topology subnet
ifconfig 10.8.0.1 255.255.255.0

# Authentication (PSK per semplicità, certificati per produzione)
secret /etc/openvpn/server/site-b-key.txt

# Remote endpoint
float                        # Allow remote IP to change

# Routing
route 192.168.2.0 255.255.255.0

# Keepalive
keepalive 10 60

# Cipher
cipher AES-256-GCM

# Persistence
persist-key
persist-tun

# Logging
log-append /var/log/openvpn/site-b.log
verb 3
```

### Site B Configuration (Client Mode)

```bash
# /etc/openvpn/client/site-a.conf
remote 203.0.113.100 1194
proto udp
dev tun

# Topology
topology subnet
ifconfig 10.8.0.2 255.255.255.0

# Authentication
secret /etc/openvpn/client/site-a-key.txt

# Routing
route 192.168.1.0 255.255.255.0

# Keepalive
keepalive 10 60

# Cipher
cipher AES-256-GCM

# Persistence
persist-key
persist-tun

# Logging
log-append /var/log/openvpn/site-a.log
verb 3
```

### Generate Shared Secret

```bash
# Su Site A
openvpn --genkey secret /etc/openvpn/server/site-b-key.txt

# Copy a Site B (via SCP sicuro)
scp /etc/openvpn/server/site-b-key.txt root@198.51.100.200:/etc/openvpn/client/site-a-key.txt
```

### Start Site-to-Site VPN

```bash
# Site A
sudo systemctl start openvpn-server@site-b
sudo systemctl enable openvpn-server@site-b

# Site B
sudo systemctl start openvpn-client@site-a
sudo systemctl enable openvpn-client@site-a

# Verify
ping -I tun0 10.8.0.2    # From Site A to Site B tunnel IP
ping 192.168.2.1         # From Site A to Site B LAN
```

---

## Sicurezza Avanzata

### TLS-Crypt vs TLS-Auth

**TLS-Crypt** (raccomandato):
- Encrypts AND authenticates control channel
- Previene packet inspection
- Nasconde OpenVPN fingerprint

**TLS-Auth** (legacy):
- Solo authenticates (HMAC)
- Control channel visibile

```bash
# Generate TLS-Crypt key
openvpn --genkey secret ta.key

# In server.conf
tls-crypt ta.key

# In client.conf
tls-crypt ta.key    # Same key
```

### Certificate Pinning

Verifica che il server certificate non cambi:

```bash
# Extract fingerprint da server cert
openssl x509 -in server.crt -noout -fingerprint -sha256
# SHA256 Fingerprint=AB:CD:EF:...

# In client.conf
verify-x509-name "vpn.mycompany.com" name
# oppure
verify-x509-name "AB:CD:EF:..." fingerprint
```

### Auth-User-Pass (Two-Factor)

Certificato + username/password:

```bash
# Server configuration
# /etc/openvpn/server/server.conf
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login

# Client configuration
auth-user-pass
# Or with file (insicuro, solo per testing)
# auth-user-pass /etc/openvpn/credentials.txt

# credentials.txt format:
# username
# password
```

### LDAP/Active Directory Integration

```bash
# Install auth-ldap plugin
sudo apt install openvpn-auth-ldap

# /etc/openvpn/auth-ldap.conf
<LDAP>
    URL             ldap://dc.mycompany.com
    BindDN          "cn=vpnauth,ou=ServiceAccounts,dc=mycompany,dc=com"
    Password        "SecurePassword"
    Timeout         15
    TLSEnable       yes
    FollowReferrals yes
</LDAP>

<Authorization>
    BaseDN          "ou=Users,dc=mycompany,dc=com"
    SearchFilter    "(&(objectClass=user)(sAMAccountName=%u)(memberOf=CN=VPN-Users,OU=Groups,DC=mycompany,DC=com))"
    RequireGroup    true
</Authorization>

# In server.conf
plugin /usr/lib/openvpn/openvpn-auth-ldap.so /etc/openvpn/auth-ldap.conf
client-cert-not-required    # Only if using LDAP for auth (less secure)
username-as-common-name
```

### Fail2Ban Protection

```bash
# Install fail2ban
sudo apt install fail2ban

# /etc/fail2ban/jail.d/openvpn.conf
[openvpn]
enabled = true
port = 1194
protocol = udp
filter = openvpn
logpath = /var/log/openvpn/openvpn.log
maxretry = 3
bantime = 3600
findtime = 600

# /etc/fail2ban/filter.d/openvpn.conf
[Definition]
failregex = ^.*TLS Error: TLS handshake failed.*<HOST>
            ^.*VERIFY ERROR.*<HOST>
            ^.*TLS Auth Error.*<HOST>
            ^.*authentication failed.*<HOST>
ignoreregex =

# Restart fail2ban
sudo systemctl restart fail2ban

# Check banned IPs
sudo fail2ban-client status openvpn
```

---

## Ottimizzazione Performance

### Buffer Tuning

```bash
# In server.conf e client.conf
sndbuf 393216    # Send buffer 384 KB
rcvbuf 393216    # Receive buffer 384 KB
push "sndbuf 393216"
push "rcvbuf 393216"

# System-wide (sysctl)
sudo sysctl -w net.core.rmem_max=16777216
sudo sysctl -w net.core.wmem_max=16777216
sudo sysctl -w net.core.rmem_default=262144
sudo sysctl -w net.core.wmem_default=262144
```

### Cipher Selection

```bash
# AES-NI hardware acceleration check
grep -o 'aes' /proc/cpuinfo

# If AES-NI available, use AES-256-GCM (fastest)
cipher AES-256-GCM

# If no AES-NI, consider ChaCha20-Poly1305
# cipher CHACHA20-POLY1305

# Verify cipher in use
# In logs: "Data Channel: using cipher 'AES-256-GCM'"
```

### MTU Optimization

```bash
# Test optimal MTU
ping -M do -s 1472 vpn.mycompany.com
# If successful, MTU = 1472 + 28 = 1500 OK
# If fails, reduce until successful

# In server.conf
mssfix 1400           # Clamp TCP MSS
tun-mtu 1500

# Or dynamic fragment
fragment 1300         # Fragment UDP packets
```

### Multi-Threading

```bash
# OpenVPN 2.5+ supports DCO (Data Channel Offload)
# Moves data plane to kernel space

# In server.conf (Linux kernel 5.4+)
# Compile with --enable-dco
# Currently experimental
```

---

## Troubleshooting

### Common Issues

#### 1. Connection Timeout

**Sintomi**: Client non riesce a connettersi

**Diagnosi**:
```bash
# Test connectivity to server
telnet vpn.mycompany.com 1194
nc -vzu vpn.mycompany.com 1194    # UDP test

# Check firewall
sudo iptables -L INPUT -v -n | grep 1194
sudo ufw status | grep 1194

# Check OpenVPN service
sudo systemctl status openvpn-server@server
```

**Soluzioni**:
- Verify firewall allows UDP 1194
- Check server is running: `systemctl status openvpn-server@server`
- Verify correct server IP in client config
- Try TCP if UDP blocked: `proto tcp` in configs

#### 2. Authentication Failed

**Sintomi**: `TLS Error: TLS handshake failed` o `VERIFY ERROR`

**Diagnosi**:
```bash
# Check certificate validity
openssl x509 -in client.crt -noout -dates

# Check CA matches
openssl verify -CAfile ca.crt client.crt

# Check logs
sudo tail -50 /var/log/openvpn/openvpn.log | grep -i error
```

**Soluzioni**:
- Renew expired certificates
- Ensure client has correct ca.crt
- Check TLS-Crypt key matches on both sides
- Verify certificate not revoked (CRL)

#### 3. Connected but No Traffic

**Sintomi**: Tunnel UP ma ping non funziona

**Diagnosi**:
```bash
# Check tunnel interface
ip addr show tun0

# Check routing
ip route | grep tun0

# Check IP forwarding
sysctl net.ipv4.ip_forward    # Must be 1

# Check firewall FORWARD chain
sudo iptables -L FORWARD -v -n
```

**Soluzioni**:
```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Allow FORWARD
sudo iptables -A FORWARD -i tun0 -j ACCEPT
sudo iptables -A FORWARD -o tun0 -j ACCEPT

# Add NAT
sudo iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
```

#### 4. DNS Not Working

**Sintomi**: Ping IP funziona, ma hostname no

**Diagnosi**:
```bash
# Check pushed DNS
# In client log: "PUSH: Received... dhcp-option DNS 192.168.1.1"

# Check /etc/resolv.conf
cat /etc/resolv.conf

# Test DNS manually
dig @192.168.1.1 internal.mycompany.com
```

**Soluzioni**:
```bash
# Linux: Use update-resolv-conf script
# In client.conf:
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf

# Or use systemd-resolved
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved

# Download script:
wget -O /etc/openvpn/update-systemd-resolved \
    https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/master/update-systemd-resolved
chmod +x /etc/openvpn/update-systemd-resolved
```

### Debug Logging

```bash
# Increase verbosity
verb 6              # In config file

# Real-time logs
sudo tail -f /var/log/openvpn/openvpn.log

# Journalctl
sudo journalctl -u openvpn-server@server -f

# Packet capture
sudo tcpdump -i eth0 -n udp port 1194 -vv
sudo tcpdump -i tun0 -n
```

---

## Script e Automazione

### Client Connection Script con Logging

```bash
#!/bin/bash
# vpn-connect.sh

CONFIG="/etc/openvpn/client/mycompany.conf"
LOGFILE="/var/log/openvpn/client-connect.log"

echo "[$(date)] Attempting VPN connection..." | tee -a "$LOGFILE"

# Kill existing connection
sudo killall openvpn 2>/dev/null

# Connect
sudo openvpn --config "$CONFIG" --daemon --log "$LOGFILE"

# Wait for connection
sleep 5

# Check if connected
if ip link show tun0 &>/dev/null; then
    echo "[$(date)] VPN connected successfully" | tee -a "$LOGFILE"
    ip addr show tun0 | grep inet | tee -a "$LOGFILE"
else
    echo "[$(date)] VPN connection FAILED" | tee -a "$LOGFILE"
    exit 1
fi
```

### Auto-Reconnect Script

```bash
#!/bin/bash
# vpn-keepalive.sh

VPN_SERVER="10.8.0.1"
MAX_RETRIES=3
RETRY_COUNT=0

while true; do
    if ! ping -c 1 -W 2 "$VPN_SERVER" &>/dev/null; then
        echo "[$(date)] VPN down, attempting reconnect..."
        
        # Disconnect
        sudo killall openvpn
        sleep 2
        
        # Reconnect
        /usr/local/bin/vpn-connect.sh
        
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "[$(date)] Max retries reached, sending alert"
            echo "VPN down after $MAX_RETRIES attempts" | \
                mail -s "VPN Alert" admin@mycompany.com
            RETRY_COUNT=0
        fi
    else
        RETRY_COUNT=0
    fi
    
    sleep 60
done
```

### User Management Script

```bash
#!/bin/bash
# add-vpn-user.sh

set -e

USERNAME="$1"
EMAIL="$2"

if [ -z "$USERNAME" ] || [ -z "$EMAIL" ]; then
    echo "Usage: $0 <username> <email>"
    exit 1
fi

CA_DIR="/root/openvpn-ca"
CLIENT_DIR="/root/vpn-clients"

cd "$CA_DIR"

# Generate certificate
./easyrsa gen-req "$USERNAME" nopass
./easyrsa sign-req client "$USERNAME"

# Create client directory
mkdir -p "$CLIENT_DIR/$USERNAME"

# Copy files
cp pki/ca.crt "$CLIENT_DIR/$USERNAME/"
cp pki/issued/"$USERNAME".crt "$CLIENT_DIR/$USERNAME/"
cp pki/private/"$USERNAME".key "$CLIENT_DIR/$USERNAME/"
cp pki/ta.key "$CLIENT_DIR/$USERNAME/"

# Generate .ovpn file
cat > "$CLIENT_DIR/$USERNAME/$USERNAME.ovpn" <<EOF
client
dev tun
proto udp
remote vpn.mycompany.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun

<ca>
$(cat "$CLIENT_DIR/$USERNAME/ca.crt")
</ca>

<cert>
$(cat "$CLIENT_DIR/$USERNAME/$USERNAME.crt")
</cert>

<key>
$(cat "$CLIENT_DIR/$USERNAME/$USERNAME.key")
</key>

<tls-crypt>
$(cat "$CLIENT_DIR/$USERNAME/ta.key")
</tls-crypt>

cipher AES-256-GCM
auth SHA256
remote-cert-tls server
tls-version-min 1.2
comp-lzo no
verb 3
EOF

# Send via email (requires mailx/sendmail configured)
echo "Your VPN configuration is attached." | \
    mail -s "VPN Access for $USERNAME" \
    -A "$CLIENT_DIR/$USERNAME/$USERNAME.ovpn" \
    "$EMAIL"

echo "User $USERNAME created and configuration sent to $EMAIL"
```

### Monitoring Dashboard (via Management Interface)

```bash
#!/bin/bash
# vpn-monitor.sh

# Connect to management interface
{
    echo "status"
    sleep 1
} | nc localhost 7505 | awk '
BEGIN { print "=== OpenVPN Server Status ===" }
/CLIENT_LIST/ {
    split($0, a, ",")
    printf "User: %-15s IP: %-15s Bytes RX: %10s Bytes TX: %10s\n", 
        a[2], a[4], a[7], a[8]
}
'
```

### Prometheus Exporter (per Grafana)

```bash
#!/bin/bash
# openvpn-exporter.sh

OUTPUT="/var/lib/node_exporter/textfile_collector/openvpn.prom"

{
    echo "status"
    sleep 1
} | nc localhost 7505 | awk '
BEGIN {
    print "# HELP openvpn_connected_clients Number of connected clients"
    print "# TYPE openvpn_connected_clients gauge"
    clients = 0
    bytes_rx = 0
    bytes_tx = 0
}
/CLIENT_LIST/ {
    clients++
    split($0, a, ",")
    bytes_rx += a[7]
    bytes_tx += a[8]
}
END {
    print "openvpn_connected_clients " clients
    print "# HELP openvpn_bytes_received Total bytes received"
    print "# TYPE openvpn_bytes_received counter"
    print "openvpn_bytes_received " bytes_rx
    print "# HELP openvpn_bytes_sent Total bytes sent"
    print "# TYPE openvpn_bytes_sent counter"
    print "openvpn_bytes_sent " bytes_tx
}
' > "$OUTPUT"
```

---

## Best Practices

### Security Checklist

- ✅ Use AES-256-GCM cipher
- ✅ Use TLS 1.2+ minimum
- ✅ Enable TLS-Crypt (not TLS-Auth)
- ✅ Use certificates (not PSK for production)
- ✅ Implement CRL for revocation
- ✅ Drop privileges (user nobody, group nogroup)
- ✅ Enable fail2ban
- ✅ Regular certificate rotation
- ✅ Monitor logs for suspicious activity
- ✅ Disable compression (comp-lzo no)

### Performance Checklist

- ✅ Use UDP (not TCP unless necessary)
- ✅ Tune buffers (sndbuf/rcvbuf)
- ✅ Optimize MTU/MSS
- ✅ Use hardware acceleration (AES-NI)
- ✅ Consider WireGuard for new deployments

### Maintenance Checklist

- ✅ Backup CA key securely
- ✅ Document all configurations
- ✅ Monitor certificate expiry (automated alerts)
- ✅ Regular security updates
- ✅ Log rotation configured
- ✅ Disaster recovery plan tested

---

## Risorse Aggiuntive

- **Documentazione Ufficiale**: https://openvpn.net/community-resources/
- **Forum Community**: https://forums.openvpn.net/
- **GitHub**: https://github.com/OpenVPN/openvpn
- **Security Advisories**: https://community.openvpn.net/openvpn/wiki/SecurityAnnouncements

---

**Fine Guida OpenVPN**  
**Torna a**: [README](README.md)
