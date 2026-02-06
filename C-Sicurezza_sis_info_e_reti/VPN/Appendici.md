# Appendici

## Appendice A: Glossario dei termini

**AES (Advanced Encryption Standard)**  
Algoritmo di cifratura simmetrica a blocchi, standard de facto per la crittografia VPN.

**AH (Authentication Header)**  
Protocollo IPsec che fornisce autenticazione e integrità ma non confidenzialità.

**CA (Certificate Authority)**  
Entità che emette e firma certificati digitali nell'ambito di una PKI.

**Cipher Suite**  
Insieme di algoritmi crittografici usati per negoziare una connessione sicura (encryption, authentication, key exchange).

**DH (Diffie-Hellman)**  
Algoritmo di scambio chiavi che permette a due parti di stabilire un segreto condiviso su canale insicuro.

**DMZ (Demilitarized Zone)**  
Segmento di rete posizionato tra rete interna e Internet per ospitare servizi pubblicamente accessibili.

**DPD (Dead Peer Detection)**  
Meccanismo per rilevare se un peer VPN è ancora raggiungibile.

**ESP (Encapsulating Security Payload)**  
Protocollo IPsec che fornisce confidenzialità, autenticazione e integrità.

**Full Tunneling**  
Configurazione VPN dove tutto il traffico di rete passa attraverso il tunnel VPN.

**HMAC (Hash-based Message Authentication Code)**  
Metodo per verificare integrità e autenticità di un messaggio usando funzione hash e chiave segreta.

**HSM (Hardware Security Module)**  
Dispositivo fisico dedicato alla gestione sicura di chiavi crittografiche.

**ICV (Integrity Check Value)**  
Hash crittografico usato per verificare integrità dei dati.

**IKE (Internet Key Exchange)**  
Protocollo per negoziare Security Associations in IPsec.

**IPsec (Internet Protocol Security)**  
Suite di protocolli per la sicurezza delle comunicazioni IP.

**IV (Initialization Vector)**  
Valore random usato insieme alla chiave per inizializzare algoritmi di cifratura.

**MTU (Maximum Transmission Unit)**  
Dimensione massima di un pacchetto che può essere trasmesso su una rete.

**MSS (Maximum Segment Size)**  
Dimensione massima del payload di un segmento TCP.

**NAT (Network Address Translation)**  
Tecnica per rimappare indirizzi IP modificando header dei pacchetti.

**NAT-T (NAT Traversal)**  
Metodo per far passare IPsec attraverso dispositivi NAT incapsulando in UDP.

**OCSP (Online Certificate Status Protocol)**  
Protocollo per verificare stato di revoca dei certificati in tempo reale.

**Perfect Forward Secrecy (PFS)**  
Proprietà che garantisce che compromissione di chiave non comprometta sessioni passate.

**PKI (Public Key Infrastructure)**  
Framework per gestire certificati digitali e crittografia a chiave pubblica.

**PMTUD (Path MTU Discovery)**  
Meccanismo per determinare MTU ottimale lungo un path di rete.

**PSK (Pre-Shared Key)**  
Chiave condivisa manualmente tra due endpoint per autenticazione.

**QoS (Quality of Service)**  
Tecniche per garantire performance di rete per specifici tipi di traffico.

**RADIUS (Remote Authentication Dial-In User Service)**  
Protocollo per autenticazione, autorizzazione e accounting centralizzati.

**SA (Security Association)**  
Insieme di parametri per una connessione IPsec sicura.

**SPI (Security Parameter Index)**  
Identificatore univoco per una Security Association.

**Split Tunneling**  
Configurazione VPN dove solo traffico specifico passa attraverso il tunnel.

**TLS (Transport Layer Security)**  
Protocollo crittografico per comunicazioni sicure su Internet (successore di SSL).

**Tunnel Mode**  
Modalità IPsec dove l'intero pacchetto IP viene crittografato e incapsulato.

**Transport Mode**  
Modalità IPsec dove solo il payload IP viene crittografato, header IP rimane visibile.

**VPN Concentrator**  
Dispositivo ottimizzato per gestire alto numero di connessioni VPN simultanee.

**VPN Gateway**  
Punto di ingresso/uscita per connessioni VPN.

## Appendice B: Comandi principali

### OpenVPN

```bash
# Server
systemctl start openvpn-server@server
systemctl stop openvpn-server@server
systemctl restart openvpn-server@server
systemctl status openvpn-server@server

# Client
openvpn --config client.ovpn
openvpn --config client.ovpn --daemon
killall openvpn

# Monitoring
tail -f /var/log/openvpn/openvpn.log
cat /var/log/openvpn/openvpn-status.log

# Certificate management
easyrsa init-pki
easyrsa build-ca
easyrsa gen-req server nopass
easyrsa sign-req server server
easyrsa build-client-full client1 nopass
easyrsa revoke client1
easyrsa gen-crl
```

### strongSwan (IPsec)

```bash
# Service
systemctl start strongswan-starter
systemctl stop strongswan-starter
systemctl restart strongswan-starter

# IPsec commands
ipsec start
ipsec stop
ipsec restart
ipsec status
ipsec statusall
ipsec up <connection-name>
ipsec down <connection-name>

# List connections
ipsec listcerts
ipsec listcacerts
ipsec listcrls
ipsec listall

# Generate certificates
ipsec pki --gen --type rsa --size 4096 > ca-key.pem
ipsec pki --self --ca --lifetime 3650 --in ca-key.pem \
    --dn "CN=VPN CA" > ca-cert.pem
```

### WireGuard

```bash
# Interface management
wg-quick up wg0
wg-quick down wg0
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Status
wg show
wg show wg0

# Key generation
wg genkey | tee private.key | wg pubkey > public.key

# Add peer
wg set wg0 peer <PUBLIC_KEY> allowed-ips 10.0.0.2/32 endpoint vpn.example.com:51820
```

### Diagnostics

```bash
# Connectivity
ping -I tun0 8.8.8.8
traceroute -i tun0 8.8.8.8
mtr -i tun0 target.com

# Interface status
ip addr show tun0
ifconfig tun0
ip link show tun0

# Routing
ip route show
route -n
ip route get 192.168.1.1

# Packet capture
tcpdump -i tun0
tcpdump -i eth0 esp
tcpdump -i eth0 udp port 1194
wireshark  # GUI

# Firewall
iptables -L -v -n
ufw status verbose

# Network statistics
ss -tuln | grep 1194
netstat -tuln | grep 1194
lsof -i :1194

# Process monitoring
ps aux | grep openvpn
ps aux | grep charon  # strongSwan
htop -p $(pgrep openvpn)

# System logs
journalctl -u openvpn-server@server -f
journalctl -u strongswan-starter -f
dmesg | grep -i vpn
```

## Appendice C: Checklist configurazione VPN

### Pre-deployment

- [ ] Requirements gathering completo
- [ ] Network design documentato (IP addressing, routing)
- [ ] Overlap check subnet completato
- [ ] Hardware/software specifications definite
- [ ] Budget approvato
- [ ] Compliance requirements verificati (GDPR, PCI-DSS, etc.)
- [ ] Disaster recovery plan definito

### Security

- [ ] Protocollo scelto (IPsec/OpenVPN/WireGuard)
- [ ] Cipher suite forte selezionata (AES-256-GCM)
- [ ] Autenticazione method scelta (certificates preferred)
- [ ] PKI setup completato (se usando certificati)
- [ ] MFA abilitato
- [ ] Certificate expiry monitoring configurato
- [ ] Firewall rules configurate
- [ ] IDS/IPS integration pianificata
- [ ] Security audit schedulato

### Network

- [ ] IP forwarding abilitato
- [ ] NAT/Firewall configurato correttamente
- [ ] MTU ottimizzato e testato
- [ ] DNS configuration corretta
- [ ] Split vs Full tunneling deciso e configurato
- [ ] Routing (static/dynamic) configurato
- [ ] QoS policies implementate (se necessario)
- [ ] Bandwidth capacity verificata

### High Availability

- [ ] Redundancy pianificata (Active/Passive o Active/Active)
- [ ] Load balancing configurato
- [ ] Failover testing completato
- [ ] Geographic redundancy (se richiesto)
- [ ] Backup e restore procedure documentate

### Monitoring & Logging

- [ ] Logging abilitato e centralizzato
- [ ] Monitoring dashboard configurato (Grafana/Prometheus)
- [ ] Alert configurati (connection failures, high CPU, etc.)
- [ ] SIEM integration (se applicabile)
- [ ] Retention policy definita
- [ ] Regular log review process stabilito

### Client Deployment

- [ ] Client software selezionato
- [ ] Configuration files preparati
- [ ] Deployment method definito (GPO, MDM, manual)
- [ ] User documentation creata
- [ ] Training sessions pianificate
- [ ] Helpdesk preparato per support requests

### Testing

- [ ] Connectivity test completati
- [ ] Performance benchmark eseguiti (throughput, latency)
- [ ] Failover test eseguiti
- [ ] Security test (penetration test, vulnerability scan)
- [ ] User acceptance testing (UAT)
- [ ] Load testing con utenti simulati
- [ ] Multi-platform testing (Windows, macOS, Linux, mobile)

### Post-deployment

- [ ] Documentation completa e aggiornata
- [ ] Runbook operativo creato
- [ ] Incident response procedure documentate
- [ ] Change management process definito
- [ ] Regular maintenance scheduled
- [ ] Capacity planning review quarterly
- [ ] Security patches monitoring attivo
- [ ] User feedback collection mechanism
- [ ] Performance reports regolari generati

## Appendice D: Esempi di file di configurazione

### OpenVPN Server (Production-ready)

```bash
# /etc/openvpn/server/production.conf

# Network settings
port 1194
proto udp
dev tun
topology subnet

# Certificates and keys
ca /etc/openvpn/pki/ca.crt
cert /etc/openvpn/pki/issued/server.crt
key /etc/openvpn/pki/private/server.key
dh /etc/openvpn/pki/dh.pem
tls-crypt /etc/openvpn/pki/ta.key

# Network configuration
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt

# Routes to push to clients
push "route 192.168.0.0 255.255.0.0"
push "route 10.10.0.0 255.255.0.0"

# DNS configuration
push "dhcp-option DNS 192.168.1.10"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DOMAIN company.local"

# Client-to-client communication
client-to-client

# Keepalive
keepalive 10 120

# Cryptographic settings
cipher AES-256-GCM
auth SHA256
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384

# Compression
comp-lzo no
push "comp-lzo no"

# Performance tuning
sndbuf 393216
rcvbuf 393216
push "sndbuf 393216"
push "rcvbuf 393216"
fast-io

# Maximum clients
max-clients 250

# User/group privileges
user nobody
group nogroup

# Persistence
persist-key
persist-tun

# Client config directory
client-config-dir /etc/openvpn/ccd

# Logging
status /var/log/openvpn/status.log 10
log-append /var/log/openvpn/openvpn.log
verb 3
mute 20

# Explicit exit notification
explicit-exit-notify 1

# Management interface
management localhost 7505

# Scripts
script-security 2
client-connect /etc/openvpn/scripts/client-connect.sh
client-disconnect /etc/openvpn/scripts/client-disconnect.sh
```

### OpenVPN Client (Multi-OS)

```bash
# client-company.ovpn

client
dev tun
proto udp

# Server address (can specify multiple for redundancy)
remote vpn1.company.com 1194
remote vpn2.company.com 1194
remote vpn3.company.com 1194

# Connection retry
resolv-retry infinite
nobind

# Persistence
persist-key
persist-tun

# Certificates (embedded)
<ca>
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
</ca>

<cert>
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
</key>

<tls-crypt>
-----BEGIN OpenVPN Static key V1-----
...
-----END OpenVPN Static key V1-----
</tls-crypt>

# Verify server certificate
remote-cert-tls server

# Cryptographic settings
cipher AES-256-GCM
auth SHA256

# Compression
comp-lzo no

# Logging
verb 3

# Connection options
pull
auth-retry interact

# Windows-specific
; block-outside-dns

# Script security
; up /etc/openvpn/update-resolv-conf
; down /etc/openvpn/update-resolv-conf
; script-security 2
```

### strongSwan Site-to-Site

```bash
# /etc/ipsec.conf

config setup
    charondebug="ike 2, knl 2, cfg 2"
    uniqueids=never

conn %default
    keyexchange=ikev2
    ike=aes256gcm16-prfsha384-ecp384!
    esp=aes256gcm16-ecp384!
    dpdaction=restart
    dpddelay=30s
    dpdtimeout=120s
    rekeymargin=3m
    keyingtries=%forever

conn site-to-site-branch1
    left=%any
    leftid=@hq.company.com
    leftsubnet=192.168.1.0/24
    leftcert=hq-cert.pem
    right=203.0.113.100
    rightid=@branch1.company.com
    rightsubnet=192.168.10.0/24
    auto=start

conn site-to-site-branch2
    left=%any
    leftid=@hq.company.com
    leftsubnet=192.168.1.0/24
    leftcert=hq-cert.pem
    right=198.51.100.200
    rightid=@branch2.company.com
    rightsubnet=192.168.20.0/24
    auto=start

# /etc/ipsec.secrets
: RSA hq-key.pem
```

### WireGuard Server

```ini
# /etc/wireguard/wg0.conf

[Interface]
Address = 10.99.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY_HERE

# Firewall rules
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# SaveConfig = true  # Auto-save when adding peers dynamically

# Peer: alice
[Peer]
PublicKey = ALICE_PUBLIC_KEY_HERE
AllowedIPs = 10.99.0.10/32

# Peer: bob
[Peer]
PublicKey = BOB_PUBLIC_KEY_HERE
AllowedIPs = 10.99.0.11/32

# Peer: mobile-device
[Peer]
PublicKey = MOBILE_PUBLIC_KEY_HERE
AllowedIPs = 10.99.0.20/32
PersistentKeepalive = 25  # For mobile devices behind NAT
```

### WireGuard Client

```ini
# alice.conf

[Interface]
Address = 10.99.0.10/24
PrivateKey = ALICE_PRIVATE_KEY_HERE
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = vpn.company.com:51820
AllowedIPs = 0.0.0.0/0, ::/0  # Route all traffic (full tunnel)
# AllowedIPs = 10.99.0.0/24, 192.168.0.0/16  # Split tunnel
PersistentKeepalive = 25
```

### Firewall Script (iptables)

```bash
#!/bin/bash
# /etc/openvpn/firewall.sh

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (from specific network)
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT

# Allow OpenVPN
iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# Allow forwarding from VPN to LAN
iptables -A FORWARD -i tun0 -o eth1 -j ACCEPT
iptables -A FORWARD -i eth1 -o tun0 -j ACCEPT

# NAT for VPN clients
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Allow ICMP (ping)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Log dropped packets (rate limited)
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables-INPUT-dropped: " --log-level 4
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables-FORWARD-dropped: " --log-level 4

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### Monitoring Script (Bash + Prometheus)

```bash
#!/bin/bash
# /opt/vpn-exporter.sh

METRICS_FILE="/var/lib/node_exporter/vpn_metrics.prom"

# Parse OpenVPN status
parse_openvpn() {
    local status_file="/var/log/openvpn/status.log"
    local connected=$(grep -c "^CLIENT_LIST" "$status_file")
    
    echo "# HELP openvpn_connected_clients Number of connected clients"
    echo "# TYPE openvpn_connected_clients gauge"
    echo "openvpn_connected_clients $connected"
    
    # Bytes transferred
    local bytes_rx=$(grep "^CLIENT_LIST" "$status_file" | awk -F',' '{sum+=$6} END {print sum}')
    local bytes_tx=$(grep "^CLIENT_LIST" "$status_file" | awk -F',' '{sum+=$7} END {print sum}')
    
    echo "# HELP openvpn_bytes_received Total bytes received"
    echo "# TYPE openvpn_bytes_received counter"
    echo "openvpn_bytes_received $bytes_rx"
    
    echo "# HELP openvpn_bytes_sent Total bytes sent"
    echo "# TYPE openvpn_bytes_sent counter"
    echo "openvpn_bytes_sent $bytes_tx"
}

# Parse WireGuard status
parse_wireguard() {
    while read -r line; do
        if [[ $line =~ peer:\ ([a-zA-Z0-9+/=]+) ]]; then
            peer="${BASH_REMATCH[1]}"
        elif [[ $line =~ transfer:\ ([0-9]+)\ [a-zA-Z]+\ received,\ ([0-9]+)\ [a-zA-Z]+\ sent ]]; then
            rx="${BASH_REMATCH[1]}"
            tx="${BASH_REMATCH[2]}"
            echo "wireguard_bytes_received{peer=\"$peer\"} $rx"
            echo "wireguard_bytes_sent{peer=\"$peer\"} $tx"
        fi
    done < <(wg show all transfer)
}

# Main
{
    parse_openvpn
    parse_wireguard
} > "$METRICS_FILE.$$"

mv "$METRICS_FILE.$$" "$METRICS_FILE"
```

---

**Fine Appendici**  
**Torna a**: [README](README.md)
