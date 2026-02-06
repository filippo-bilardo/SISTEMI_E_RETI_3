# Lab 2: OpenVPN Remote Access con Certificati

## Obiettivi
- Setup OpenVPN server per remote access
- Implementare autenticazione con certificati X.509
- Configurare client Windows/Linux

## Topology

```
Remote Users                    OpenVPN Server              Internal Network
(anywhere)                      Public IP: 203.0.113.50     192.168.100.0/24
                                    |                             |
Client1 → Internet → OpenVPN (tun0: 10.8.0.1) → eth1: 192.168.100.1
                                    |                             |
Client2 ↗                      VPN Pool:                    Resources:
                                10.8.0.0/24                 - File Server
                                                            - Internal Wiki
```

## Step 1: Setup PKI con Easy-RSA

```bash
# Installazione
apt-get install -y openvpn easy-rsa

# Setup Easy-RSA
make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# Edit vars
cat > vars <<EOF
set_var EASYRSA_REQ_COUNTRY    "IT"
set_var EASYRSA_REQ_PROVINCE   "Lombardia"
set_var EASYRSA_REQ_CITY       "Milano"
set_var EASYRSA_REQ_ORG        "Company Lab"
set_var EASYRSA_REQ_EMAIL      "admin@company.local"
set_var EASYRSA_REQ_OU         "IT Department"
set_var EASYRSA_KEY_SIZE       2048
set_var EASYRSA_CA_EXPIRE      3650
set_var EASYRSA_CERT_EXPIRE    365
EOF

# Initialize PKI
./easyrsa init-pki

# Build CA
./easyrsa build-ca nopass
# Enter CN: Company VPN CA

# Generate server certificate
./easyrsa gen-req server nopass
./easyrsa sign-req server server

# Generate DH parameters (potrebbe richiedere alcuni minuti)
./easyrsa gen-dh

# Generate TLS-Crypt key (additional security)
openvpn --genkey secret /etc/openvpn/ta.key

# Copy files to OpenVPN directory
cp pki/ca.crt /etc/openvpn/server/
cp pki/issued/server.crt /etc/openvpn/server/
cp pki/private/server.key /etc/openvpn/server/
cp pki/dh.pem /etc/openvpn/server/
cp /etc/openvpn/ta.key /etc/openvpn/server/
```

## Step 2: Configurazione Server

```bash
cat > /etc/openvpn/server/server.conf <<EOF
# Network settings
port 1194
proto udp
dev tun
topology subnet

# Certificates
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-crypt ta.key

# VPN subnet
server 10.8.0.0 255.255.255.0

# Push routes to clients
push "route 192.168.100.0 255.255.255.0"

# DNS for clients
push "dhcp-option DNS 192.168.100.1"
push "dhcp-option DNS 8.8.8.8"

# Client-to-client communication (opzionale)
# client-to-client

# Keepalive
keepalive 10 120

# Cryptographic settings
cipher AES-256-GCM
auth SHA256
tls-version-min 1.2

# User/group downgrade
user nobody
group nogroup

# Persistence
persist-key
persist-tun

# Logging
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3

# Maximum clients
max-clients 100
EOF

# IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Firewall + NAT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Save iptables rules
iptables-save > /etc/iptables/rules.v4

# Start server
systemctl start openvpn-server@server
systemctl enable openvpn-server@server
```

## Step 3: Generazione Certificati Client

```bash
cd /etc/openvpn/easy-rsa

# Client 1
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

# Client 2
./easyrsa gen-req client2 nopass
./easyrsa sign-req client client2

# Organizza file per client
mkdir -p /root/vpn-clients/client1
cd /root/vpn-clients/client1

# Copy necessary files
cp /etc/openvpn/easy-rsa/pki/ca.crt .
cp /etc/openvpn/easy-rsa/pki/issued/client1.crt .
cp /etc/openvpn/easy-rsa/pki/private/client1.key .
cp /etc/openvpn/ta.key .
```

## Step 4: Configurazione Client (Linux)

```bash
cat > client1.ovpn <<EOF
client
dev tun
proto udp
remote 203.0.113.50 1194
resolv-retry infinite
nobind
persist-key
persist-tun

# Certificates (inline)
<ca>
$(cat ca.crt)
</ca>

<cert>
$(cat client1.crt)
</cert>

<key>
$(cat client1.key)
</key>

<tls-crypt>
$(cat ta.key)
</tls-crypt>

# Cryptographic settings
cipher AES-256-GCM
auth SHA256
remote-cert-tls server

# Logging
verb 3
EOF
```

## Step 5: Test Connessione

```bash
# Su client
openvpn --config client1.ovpn

# In altra finestra, verifica:
ip addr show tun0
ping 10.8.0.1  # VPN gateway
ping 192.168.100.1  # Internal network
```

## Step 6: Client Windows

1. Download OpenVPN GUI: https://openvpn.net/community-downloads/
2. Install
3. Copy `client1.ovpn` to `C:\Program Files\OpenVPN\config\`
4. Right-click OpenVPN icon in tray → Connect

## Verifica e Monitoring

```bash
# Su server
# Check connected clients
cat /var/log/openvpn/status.log

# Real-time logs
tail -f /var/log/openvpn/openvpn.log

# Client list con statistiche
echo "status" | nc localhost 7505  # Se management interface abilitata
```

## Esercizi Avanzati

1. **Revoca certificato**: Revoca client1 e verifica che non possa più connettersi
2. **MFA**: Integra Google Authenticator per 2FA
3. **Client-specific config**: Assegna IP statico a client specifico
4. **Monitoring**: Setup Grafana dashboard per VPN metrics

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 1: OpenVPN Site-to-Site](Lab1_OpenVPN_Site-to-Site.md)  
**Prossimo Lab**: [Lab 3: IPsec Site-to-Site](Lab3_IPsec_Site-to-Site.md)
