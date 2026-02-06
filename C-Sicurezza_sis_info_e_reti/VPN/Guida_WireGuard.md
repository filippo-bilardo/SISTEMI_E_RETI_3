# Guida Completa WireGuard

## Indice

1. [Introduzione](#introduzione)
2. [Installazione](#installazione)
3. [Concetti Fondamentali](#concetti-fondamentali)
4. [Configurazione Base](#configurazione-base)
5. [Remote Access VPN](#remote-access-vpn)
6. [Site-to-Site VPN](#site-to-site-vpn)
7. [Configurazioni Avanzate](#configurazioni-avanzate)
8. [Sicurezza](#sicurezza)
9. [Troubleshooting](#troubleshooting)
10. [Script e Automazione](#script-e-automazione)

---

## Introduzione

WireGuard è un protocollo VPN moderno progettato per essere estremamente semplice, veloce e sicuro. Utilizza crittografia state-of-the-art e ha un codebase di sole ~4,000 righe (vs ~70,000 di OpenVPN).

### Caratteristiche Principali

- **Semplicità**: Configurazione minimale, facile da capire
- **Performance**: 3-4x più veloce di OpenVPN/IPsec
- **Sicurezza**: Curve25519, ChaCha20, Poly1305, BLAKE2s
- **Stealth**: Nessuna risposta a pacchetti non autenticati
- **Cross-platform**: Linux, Windows, macOS, iOS, Android, FreeBSD
- **Kernel integration**: Parte del Linux kernel dal 5.6

### Vantaggi

✅ **Velocità**: Throughput superiore, latenza ridotta  
✅ **Semplicità**: Configurazione minimale (~10 righe)  
✅ **Sicurezza**: Crypto moderna, peer-reviewed  
✅ **Roaming**: Cambia IP senza disconnettere  
✅ **Battery-friendly**: Consuma meno energia (mobile)  

### Svantaggi

❌ **Maturità**: Relativamente nuovo (2016 vs 2001 OpenVPN)  
❌ **Features**: Meno opzioni avanzate di OpenVPN  
❌ **User auth**: Basato su chiavi pubbliche, no username/password nativo  
❌ **Dynamic IP**: Ogni peer ha IP statico configurato  

---

## Installazione

### Ubuntu/Debian (20.04+)

```bash
# Update repositories
sudo apt update

# Install WireGuard
sudo apt install -y wireguard

# Verify installation
wg --version
wg-quick --version
```

### CentOS/RHEL 8+ / Rocky Linux

```bash
# Install EPEL
sudo dnf install -y epel-release elrepo-release

# Install kernel modules (if not built-in)
sudo dnf install -y kmod-wireguard

# Install tools
sudo dnf install -y wireguard-tools

# Verify
wg --version
```

### Fedora

```bash
sudo dnf install -y wireguard-tools
```

### Arch Linux

```bash
sudo pacman -S wireguard-tools
```

### Windows

1. Download installer: https://www.wireguard.com/install/
2. Esegui `wireguard-installer.exe`
3. Install location: `C:\Program Files\WireGuard`
4. GUI application included

### macOS

```bash
# Using Homebrew
brew install wireguard-tools

# Or download GUI app from Mac App Store
# "WireGuard" by WireGuard Development Team
```

### Android/iOS

- **Android**: Google Play Store - "WireGuard"
- **iOS**: App Store - "WireGuard"

### From Source (Advanced)

```bash
# Clone repository
git clone https://git.zx2c4.com/wireguard-tools
cd wireguard-tools/src

# Build and install
make
sudo make install

# Verify
wg version
```

---

## Concetti Fondamentali

### Architettura WireGuard

```
┌────────────────────────────────────────────────────────┐
│                   WireGuard Peer A                     │
│                                                        │
│  Application ←→ Network Stack ←→ wg0 (WireGuard IF)    │
│                                      ↓                 │
│                              Encryption Engine         │
│                              (ChaCha20-Poly1305)       │
│                                      ↓                 │
│                              UDP Socket (51820)        │
└──────────────────────────────┬─────────────────────────┘
                               │
                         Internet/WAN
                               │
┌──────────────────────────────▼─────────────────────────┐
│                   WireGuard Peer B                     │
│                              UDP Socket (51820)        │
│                                      ↑                 │
│                              Encryption Engine         │
│                              (ChaCha20-Poly1305)       │
│                                      ↑                 │
│  Application ←→ Network Stack ←→ wg0 (WireGuard IF)    │
│                                                        │
└────────────────────────────────────────────────────────┘
```

### Cryptographic Primitives

WireGuard usa una suite crittografica fissa (no negotiation):

| Component | Algorithm |
|-----------|-----------|
| **Key Exchange** | Curve25519 (ECDH) |
| **Encryption** | ChaCha20 |
| **Authentication** | Poly1305 |
| **Hashing** | BLAKE2s |
| **Key Derivation** | HKDF |

**Perché nessuna negoziazione?**
- Riduce attack surface
- Semplifica implementazione
- Previene downgrade attacks
- Algoritmi scelti sono best-in-class

### Peer Model

WireGuard non ha concetto di "client" e "server" - solo **peers**.

```
Peer = Public Key + Endpoint + Allowed IPs

Peer A  ←──────────→  Peer B
```

Ogni peer ha:
- **Private Key**: Segreto, mai condiviso
- **Public Key**: Derivato da private key, condiviso
- **Endpoint** (optional): IP:port dove raggiungere il peer
- **Allowed IPs**: Quali IP possono passare attraverso il tunnel da/verso questo peer

### Key Generation

```bash
# Generate private key
wg genkey > private.key

# Set restrictive permissions
chmod 600 private.key

# Derive public key from private key
wg pubkey < private.key > public.key

# View keys
cat private.key
# Output: gI6EdDXNhNn6LhNAhR7J7slQtQi0fFYxOvMDi0jy3XE=

cat public.key
# Output: HIgo9xNzJMWLKASShiTqIybxZ0U3wGLiUeJ1PKf8ykw=
```

### Configuration File Format

```ini
[Interface]
# Local configuration
PrivateKey = <base64-encoded-private-key>
Address = 10.0.0.1/24                    # VPN IP address
ListenPort = 51820                       # UDP port (optional)
PostUp = iptables ...                    # Run after interface up
PostDown = iptables ...                  # Run after interface down

[Peer]
# Remote peer configuration
PublicKey = <base64-encoded-public-key>
Endpoint = 203.0.113.1:51820            # Remote IP:port
AllowedIPs = 10.0.0.2/32                # IPs allowed from this peer
PersistentKeepalive = 25                # Keepalive seconds (for NAT)
```

---

## Configurazione Base

### Scenario: Two-Peer VPN

```
Peer A (Laptop)              Peer B (Server)
Private: aaaa...             Private: bbbb...
Public:  AAAA...             Public:  BBBB...
VPN IP:  10.0.0.2/24         VPN IP:  10.0.0.1/24
                             Public IP: 203.0.113.50
```

### Setup Peer B (Server)

```bash
# Generate keys
cd /etc/wireguard
umask 077
wg genkey | tee server-private.key | wg pubkey > server-public.key

# Create configuration
cat > /etc/wireguard/wg0.conf <<'EOF'
[Interface]
# Server configuration
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY_HERE

# Enable IP forwarding (if routing traffic)
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Peer A (Laptop)
[Peer]
PublicKey = PEER_A_PUBLIC_KEY_HERE
AllowedIPs = 10.0.0.2/32
EOF

# Insert actual private key
PRIVATE_KEY=$(cat server-private.key)
sed -i "s|SERVER_PRIVATE_KEY_HERE|$PRIVATE_KEY|" /etc/wireguard/wg0.conf

# Note: Peer A public key will be added after generating it
```

### Setup Peer A (Client/Laptop)

```bash
# Generate keys
cd /etc/wireguard
umask 077
wg genkey | tee client-private.key | wg pubkey > client-public.key

# Create configuration
cat > /etc/wireguard/wg0.conf <<'EOF'
[Interface]
# Client configuration
Address = 10.0.0.2/24
PrivateKey = CLIENT_PRIVATE_KEY_HERE
DNS = 8.8.8.8, 1.1.1.1

[Peer]
# Server (Peer B)
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0, ::/0              # Route all traffic
PersistentKeepalive = 25                  # Keepalive for NAT
EOF

# Insert actual keys
PRIVATE_KEY=$(cat client-private.key)
sed -i "s|CLIENT_PRIVATE_KEY_HERE|$PRIVATE_KEY|" /etc/wireguard/wg0.conf

# Get server public key and add
SERVER_PUBLIC_KEY=$(ssh root@203.0.113.50 "cat /etc/wireguard/server-public.key")
sed -i "s|SERVER_PUBLIC_KEY_HERE|$SERVER_PUBLIC_KEY|" /etc/wireguard/wg0.conf
```

### Add Client Public Key to Server

```bash
# On server, get client public key
CLIENT_PUBLIC_KEY="paste_here"

# Add to server config (or append)
cat >> /etc/wireguard/wg0.conf <<EOF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF
```

### Start WireGuard

**Server**:
```bash
# Start interface
sudo wg-quick up wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0

# Check status
sudo wg show
# Output:
# interface: wg0
#   public key: BBBB...
#   private key: (hidden)
#   listening port: 51820
#
# peer: AAAA...
#   allowed ips: 10.0.0.2/32
```

**Client**:
```bash
# Start interface
sudo wg-quick up wg0

# Check status
sudo wg show
# Output:
# interface: wg0
#   public key: AAAA...
#   private key: (hidden)
#   listening port: random
#
# peer: BBBB...
#   endpoint: 203.0.113.50:51820
#   allowed ips: 0.0.0.0/0, ::/0
#   latest handshake: 15 seconds ago
#   transfer: 1.25 KiB received, 892 B sent
```

### Verify Connection

```bash
# Ping server VPN IP
ping -c 3 10.0.0.1

# Check your public IP (should be server IP if routing all traffic)
curl ifconfig.me
# Output: 203.0.113.50 (server public IP)

# Traceroute
traceroute -I 8.8.8.8
# Should show server IP as first hop
```

### Stop WireGuard

```bash
# Stop interface
sudo wg-quick down wg0

# Disable at boot
sudo systemctl disable wg-quick@wg0
```

---

## Remote Access VPN

### Scenario: Multiple Clients + Server

```
Server (203.0.113.50)
    VPN IP: 10.99.0.1/24
    ├─ Client 1 (10.99.0.10/32) - alice-laptop
    ├─ Client 2 (10.99.0.11/32) - bob-phone
    └─ Client 3 (10.99.0.12/32) - charlie-desktop
```

### Server Configuration

```bash
# /etc/wireguard/wg0.conf

[Interface]
Address = 10.99.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY

# Firewall rules
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1 - Alice
[Peer]
PublicKey = ALICE_PUBLIC_KEY
AllowedIPs = 10.99.0.10/32

# Client 2 - Bob
[Peer]
PublicKey = BOB_PUBLIC_KEY
AllowedIPs = 10.99.0.11/32
# PersistentKeepalive = 25  # Uncomment if client behind NAT

# Client 3 - Charlie
[Peer]
PublicKey = CHARLIE_PUBLIC_KEY
AllowedIPs = 10.99.0.12/32
```

### Client Configuration Template

```bash
# alice-laptop.conf

[Interface]
Address = 10.99.0.10/24
PrivateKey = ALICE_PRIVATE_KEY
DNS = 8.8.8.8, 1.1.1.1

# Kill switch (optional - block non-VPN traffic)
# PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
# PostDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Automated Client Setup Script

```bash
#!/bin/bash
# add-wg-client.sh

set -e

CLIENT_NAME="$1"
SERVER_PUBLIC_KEY="your_server_public_key_here"
SERVER_ENDPOINT="203.0.113.50:51820"
VPN_SUBNET="10.99.0"
CONFIG_DIR="/etc/wireguard"

if [ -z "$CLIENT_NAME" ]; then
    echo "Usage: $0 <client-name>"
    exit 1
fi

# Find next available IP
LAST_IP=$(grep -oP "$VPN_SUBNET\.\K[0-9]+" "$CONFIG_DIR/wg0.conf" | sort -n | tail -1)
NEXT_IP=$((LAST_IP + 1))
CLIENT_IP="$VPN_SUBNET.$NEXT_IP"

echo "Assigning IP: $CLIENT_IP to $CLIENT_NAME"

# Generate client keys
umask 077
wg genkey | tee "$CONFIG_DIR/$CLIENT_NAME-private.key" | wg pubkey > "$CONFIG_DIR/$CLIENT_NAME-public.key"

PRIVATE_KEY=$(cat "$CONFIG_DIR/$CLIENT_NAME-private.key")
PUBLIC_KEY=$(cat "$CONFIG_DIR/$CLIENT_NAME-public.key")

# Create client config file
cat > "$CONFIG_DIR/$CLIENT_NAME.conf" <<EOF
[Interface]
Address = $CLIENT_IP/24
PrivateKey = $PRIVATE_KEY
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Add peer to server config
echo "" >> "$CONFIG_DIR/wg0.conf"
echo "# $CLIENT_NAME" >> "$CONFIG_DIR/wg0.conf"
echo "[Peer]" >> "$CONFIG_DIR/wg0.conf"
echo "PublicKey = $PUBLIC_KEY" >> "$CONFIG_DIR/wg0.conf"
echo "AllowedIPs = $CLIENT_IP/32" >> "$CONFIG_DIR/wg0.conf"

# Reload WireGuard
wg syncconf wg0 <(wg-quick strip wg0)

echo "Client $CLIENT_NAME created:"
echo "  IP: $CLIENT_IP"
echo "  Config: $CONFIG_DIR/$CLIENT_NAME.conf"
echo "  Public Key: $PUBLIC_KEY"
```

### Generate QR Code (per Mobile)

```bash
# Install qrencode
sudo apt install qrencode

# Generate QR code
qrencode -t ansiutf8 < /etc/wireguard/alice-laptop.conf

# Or save as PNG
qrencode -t png -o alice-laptop-qr.png < /etc/wireguard/alice-laptop.conf

# On mobile device:
# 1. Open WireGuard app
# 2. Tap "+" → "Create from QR code"
# 3. Scan QR code
```

---

## Site-to-Site VPN

### Topology

```
Site A (HQ)                          Site B (Branch)
LAN: 192.168.1.0/24                  LAN: 192.168.2.0/24
Gateway: 203.0.113.100               Gateway: 198.51.100.200
VPN: 10.10.0.1/30                    VPN: 10.10.0.2/30
```

### Site A Configuration

```bash
# /etc/wireguard/wg-siteb.conf

[Interface]
# VPN tunnel IP (point-to-point)
Address = 10.10.0.1/30
ListenPort = 51820
PrivateKey = SITE_A_PRIVATE_KEY

# Routing
PostUp = ip route add 192.168.2.0/24 dev %i
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT
PostDown = ip route del 192.168.2.0/24 dev %i
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT

# Site B peer
[Peer]
PublicKey = SITE_B_PUBLIC_KEY
Endpoint = 198.51.100.200:51820
AllowedIPs = 10.10.0.2/32, 192.168.2.0/24
PersistentKeepalive = 25
```

### Site B Configuration

```bash
# /etc/wireguard/wg-sitea.conf

[Interface]
Address = 10.10.0.2/30
ListenPort = 51820
PrivateKey = SITE_B_PRIVATE_KEY

# Routing
PostUp = ip route add 192.168.1.0/24 dev %i
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT
PostDown = ip route del 192.168.1.0/24 dev %i
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT

# Site A peer
[Peer]
PublicKey = SITE_A_PUBLIC_KEY
Endpoint = 203.0.113.100:51820
AllowedIPs = 10.10.0.1/32, 192.168.1.0/24
PersistentKeepalive = 25
```

### Enable IP Forwarding

```bash
# On both sites
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
```

### Start Tunnel

```bash
# Site A
sudo wg-quick up wg-siteb
sudo systemctl enable wg-quick@wg-siteb

# Site B
sudo wg-quick up wg-sitea
sudo systemctl enable wg-quick@wg-sitea
```

### Verify

```bash
# From Site A, ping Site B LAN
ping 192.168.2.1

# From Site B, ping Site A LAN
ping 192.168.1.1

# Check tunnel
sudo wg show
```

---

## Configurazioni Avanzate

### Split Tunneling

Route solo traffico specifico attraverso VPN:

```bash
# Client config
[Interface]
Address = 10.99.0.10/24
PrivateKey = CLIENT_PRIVATE_KEY
DNS = 8.8.8.8

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 203.0.113.50:51820
# AllowedIPs = solo le reti da routare via VPN
AllowedIPs = 10.99.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

Traffico per `10.99.0.0/24` e `192.168.1.0/24` passa per VPN, resto va diretto.

### Multiple Peers (Hub-and-Spoke)

```
          Server (Hub)
         /      |      \
    Client1  Client2  Client3
```

```bash
# Server - allow client-to-client communication
[Interface]
Address = 10.99.0.1/24
ListenPort = 51820
PrivateKey = SERVER_PRIVATE_KEY

PostUp = iptables -A FORWARD -i %i -o %i -j ACCEPT
PostDown = iptables -D FORWARD -i %i -o %i -j ACCEPT

[Peer]
PublicKey = CLIENT1_PUBLIC_KEY
AllowedIPs = 10.99.0.10/32

[Peer]
PublicKey = CLIENT2_PUBLIC_KEY
AllowedIPs = 10.99.0.11/32

[Peer]
PublicKey = CLIENT3_PUBLIC_KEY
AllowedIPs = 10.99.0.12/32
```

Client possono comunicare tra loro via server.

### Full Mesh (Peer-to-Peer)

Ogni peer connesso direttamente a tutti gli altri:

```
  Peer A ←→ Peer B
    ↕         ↕
  Peer C ←→ Peer D
```

```bash
# Peer A config
[Interface]
Address = 10.99.0.1/24
PrivateKey = PEER_A_PRIVATE_KEY

[Peer]  # Peer B
PublicKey = PEER_B_PUBLIC_KEY
Endpoint = peer-b.example.com:51820
AllowedIPs = 10.99.0.2/32

[Peer]  # Peer C
PublicKey = PEER_C_PUBLIC_KEY
Endpoint = peer-c.example.com:51820
AllowedIPs = 10.99.0.3/32

[Peer]  # Peer D
PublicKey = PEER_D_PUBLIC_KEY
Endpoint = peer-d.example.com:51820
AllowedIPs = 10.99.0.4/32
```

Repeat per tutti i peer (configurazione complessa per >5 peer).

### Dynamic Endpoint Update

Se server IP cambia (DDNS):

```bash
# Client config
[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = vpn.mydomain.com:51820  # Usa hostname DDNS
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

WireGuard risolve DNS solo all'inizio. Per re-resolve:

```bash
# Script to update endpoint
#!/bin/bash
NEW_IP=$(dig +short vpn.mydomain.com)
wg set wg0 peer SERVER_PUBLIC_KEY endpoint $NEW_IP:51820
```

### IPv6 Support

```bash
[Interface]
Address = 10.99.0.1/24, fd00::1/64  # Dual stack

[Peer]
PublicKey = PEER_PUBLIC_KEY
AllowedIPs = 10.99.0.2/32, fd00::2/128  # IPv4 + IPv6
```

### WireGuard su Porta Non-Standard

```bash
# Server - usa porta 443 (appare come HTTPS)
[Interface]
ListenPort = 443

# Firewall
sudo iptables -A INPUT -p udp --dport 443 -j ACCEPT
```

### Kill Switch (Linux)

Blocca tutto il traffico se VPN disconnette:

```bash
[Interface]
Address = 10.99.0.10/24
PrivateKey = PRIVATE_KEY

PostUp = iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT
PostDown = iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -m addrtype ! --dst-type LOCAL -j REJECT

[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### DNS Leak Prevention

```bash
[Interface]
Address = 10.99.0.10/24
PrivateKey = PRIVATE_KEY
DNS = 10.99.0.1  # VPN DNS server

# Block DNS to external servers
PostUp = iptables -A OUTPUT -p udp --dport 53 ! -o %i -j DROP
PostUp = iptables -A OUTPUT -p tcp --dport 53 ! -o %i -j DROP
PostDown = iptables -D OUTPUT -p udp --dport 53 ! -o %i -j DROP
PostDown = iptables -D OUTPUT -p tcp --dport 53 ! -o %i -j DROP
```

---

## Sicurezza

### Best Practices

✅ **Key Management**:
- Generate keys on local device (never transmit private keys)
- Use restrictive permissions: `chmod 600 private.key`
- Rotate keys periodically (manual process)
- Backup keys securely

✅ **Network Segmentation**:
- Use AllowedIPs to limit traffic per peer
- Separate VPN subnet from internal LAN

✅ **Firewall Rules**:
- Only allow necessary ports (51820 UDP)
- Use PostUp/PostDown for dynamic rules
- Implement fail2ban if needed

✅ **Monitoring**:
- Log connections
- Monitor bandwidth per peer
- Alert on suspicious activity

### Key Rotation

```bash
# Generate new keypair
wg genkey | tee new-private.key | wg pubkey > new-public.key

# Update config with new private key
sed -i "s/PrivateKey = .*/PrivateKey = $(cat new-private.key)/" /etc/wireguard/wg0.conf

# Distribute new public key to peers
# Each peer updates their [Peer] section with new PublicKey

# Restart WireGuard
wg-quick down wg0
wg-quick up wg0
```

### Firewall (ufw)

```bash
# Allow WireGuard port
sudo ufw allow 51820/udp

# Allow forwarding
sudo ufw route allow in on wg0 out on eth0
sudo ufw route allow in on eth0 out on wg0

# Enable ufw
sudo ufw enable
```

### Fail2Ban (Optional)

```bash
# /etc/fail2ban/jail.d/wireguard.conf
[wireguard]
enabled = true
filter = wireguard
logpath = /var/log/syslog
maxretry = 5
bantime = 3600

# /etc/fail2ban/filter.d/wireguard.conf
[Definition]
failregex = wireguard.*Invalid handshake.*<HOST>
ignoreregex =

sudo systemctl restart fail2ban
```

### Pre-Shared Keys (Extra Security Layer)

Aggiunge symmetric key per quantum resistance:

```bash
# Generate PSK
wg genpsk > psk.key

# On both peers, add to [Peer] section:
[Peer]
PublicKey = PEER_PUBLIC_KEY
PresharedKey = PSK_CONTENT_HERE
Endpoint = ...
AllowedIPs = ...
```

---

## Troubleshooting

### Common Issues

#### 1. No Handshake

**Sintomi**: `wg show` non mostra "latest handshake"

**Diagnosi**:
```bash
sudo wg show
# Peer section should show:
# latest handshake: 1 minute, 23 seconds ago

# If missing or "never", check:

# 1. Firewall
sudo iptables -L INPUT -v -n | grep 51820
sudo ufw status | grep 51820

# 2. Endpoint reachable
nc -vzu 203.0.113.50 51820

# 3. Logs
sudo journalctl -u wg-quick@wg0 -f
sudo dmesg | grep wireguard
```

**Soluzioni**:
- Open UDP port 51820 in firewall
- Verify endpoint IP/port correct
- Check NAT/port forwarding if behind router
- Try PersistentKeepalive = 25 on client

#### 2. Connected but No Traffic

**Sintomi**: Handshake OK ma ping fallisce

**Diagnosi**:
```bash
# Check interface is UP
ip link show wg0

# Check AllowedIPs
sudo wg show wg0 allowed-ips

# Check routing
ip route | grep wg0

# Check IP forwarding (on gateway)
sysctl net.ipv4.ip_forward  # Must be 1
```

**Soluzioni**:
```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Check firewall FORWARD chain
sudo iptables -L FORWARD -v -n

# Allow forwarding
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
```

#### 3. Slow Performance

**Diagnosi**:
```bash
# Benchmark throughput
iperf3 -c 10.99.0.1

# Check MTU
ip link show wg0

# Packet loss
ping -c 100 10.99.0.1 | grep loss
```

**Soluzioni**:
```bash
# Optimize MTU
sudo ip link set wg0 mtu 1420

# In config:
[Interface]
MTU = 1420

# Check CPU (WireGuard is CPU-bound)
top | grep wireguard

# If high CPU, consider server upgrade
```

#### 4. Connection Drops (NAT Timeout)

**Sintomi**: Connection works, then stops after inactivity

**Soluzione**:
```bash
# Add PersistentKeepalive to client config
[Peer]
PublicKey = SERVER_PUBLIC_KEY
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25  # Send packet every 25 seconds
```

### Debug Commands

```bash
# Show WireGuard configuration
sudo wg show wg0

# Detailed statistics
sudo wg show wg0 dump

# Interface status
ip addr show wg0
ip -s link show wg0

# Routing table
ip route show table all | grep wg0

# Packet capture
sudo tcpdump -i eth0 -n udp port 51820
sudo tcpdump -i wg0 -n

# System logs
sudo journalctl -u wg-quick@wg0 -f
sudo dmesg | grep wireguard
```

---

## Script e Automazione

### Status Monitoring Script

```bash
#!/bin/bash
# wg-status.sh

echo "=== WireGuard Status ==="
echo ""

for iface in /etc/wireguard/*.conf; do
    iface=$(basename "$iface" .conf)
    
    if wg show "$iface" &>/dev/null; then
        echo "Interface: $iface [UP]"
        
        # Show peers
        wg show "$iface" | awk '
        /peer:/ { peer=substr($0, index($0, ":")+2) }
        /endpoint:/ { endpoint=substr($0, index($0, ":")+2) }
        /latest handshake:/ { 
            handshake=substr($0, index($0, ":")+2)
            printf "  Peer: %s\n", peer
            printf "    Endpoint: %s\n", endpoint
            printf "    Handshake: %s\n", handshake
        }
        /transfer:/ {
            transfer=substr($0, index($0, ":")+2)
            printf "    Transfer: %s\n\n", transfer
        }
        '
    else
        echo "Interface: $iface [DOWN]"
    fi
done
```

### Auto-Reconnect Script

```bash
#!/bin/bash
# wg-keepalive.sh

INTERFACE="wg0"
REMOTE_IP="10.99.0.1"
MAX_FAILURES=3
FAILURE_COUNT=0

while true; do
    if ! ping -c 1 -W 2 "$REMOTE_IP" &>/dev/null; then
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        echo "[$(date)] Ping failed ($FAILURE_COUNT/$MAX_FAILURES)"
        
        if [ $FAILURE_COUNT -ge $MAX_FAILURES ]; then
            echo "[$(date)] Restarting WireGuard..."
            wg-quick down "$INTERFACE"
            sleep 2
            wg-quick up "$INTERFACE"
            FAILURE_COUNT=0
        fi
    else
        FAILURE_COUNT=0
    fi
    
    sleep 30
done
```

### Bandwidth Monitor

```bash
#!/bin/bash
# wg-bandwidth.sh

INTERFACE="wg0"
INTERVAL=5

echo "Monitoring $INTERFACE bandwidth (Ctrl+C to stop)"
echo ""

while true; do
    # Get current stats
    RX1=$(ip -s link show "$INTERFACE" | awk '/RX:/{getline; print $1}')
    TX1=$(ip -s link show "$INTERFACE" | awk '/TX:/{getline; print $1}')
    
    sleep "$INTERVAL"
    
    # Get new stats
    RX2=$(ip -s link show "$INTERFACE" | awk '/RX:/{getline; print $1}')
    TX2=$(ip -s link show "$INTERFACE" | awk '/TX:/{getline; print $1}')
    
    # Calculate rates
    RX_RATE=$(( (RX2 - RX1) / INTERVAL / 1024 ))
    TX_RATE=$(( (TX2 - TX1) / INTERVAL / 1024 ))
    
    echo "[$(date +%H:%M:%S)] RX: ${RX_RATE} KB/s | TX: ${TX_RATE} KB/s"
done
```

### Prometheus Exporter

```bash
#!/bin/bash
# wg-exporter.sh

OUTPUT="/var/lib/node_exporter/textfile_collector/wireguard.prom"

{
    echo "# HELP wireguard_peers Number of configured peers"
    echo "# TYPE wireguard_peers gauge"
    PEERS=$(wg show wg0 peers | wc -l)
    echo "wireguard_peers $PEERS"
    
    echo "# HELP wireguard_latest_handshake Latest handshake timestamp"
    echo "# TYPE wireguard_latest_handshake gauge"
    
    wg show wg0 latest-handshakes | while read -r pubkey timestamp; do
        echo "wireguard_latest_handshake{pubkey=\"$pubkey\"} $timestamp"
    done
    
    echo "# HELP wireguard_transfer_rx Bytes received"
    echo "# TYPE wireguard_transfer_rx counter"
    echo "# HELP wireguard_transfer_tx Bytes sent"
    echo "# TYPE wireguard_transfer_tx counter"
    
    wg show wg0 transfer | while read -r pubkey rx tx; do
        echo "wireguard_transfer_rx{pubkey=\"$pubkey\"} $rx"
        echo "wireguard_transfer_tx{pubkey=\"$pubkey\"} $tx"
    done
} > "$OUTPUT"
```

### Config Generator GUI (Python)

```python
#!/usr/bin/env python3
# wg-config-generator.py

import subprocess
import sys

def generate_keypair():
    private = subprocess.check_output(["wg", "genkey"]).decode().strip()
    public = subprocess.check_output(["wg", "pubkey"], input=private.encode()).decode().strip()
    return private, public

def generate_server_config(server_ip, listen_port, subnet):
    private_key, public_key = generate_keypair()
    
    config = f"""[Interface]
# Server configuration
Address = {subnet}.1/24
ListenPort = {listen_port}
PrivateKey = {private_key}

PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Add peers below
"""
    
    print("Server Configuration:")
    print(config)
    print(f"\nServer Public Key: {public_key}")
    print("\n" + "="*50 + "\n")
    
    return public_key

def generate_client_config(client_name, client_ip, server_public_key, server_endpoint):
    private_key, public_key = generate_keypair()
    
    config = f"""[Interface]
# Client: {client_name}
Address = {client_ip}/24
PrivateKey = {private_key}
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = {server_public_key}
Endpoint = {server_endpoint}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
"""
    
    print(f"Client Configuration ({client_name}):")
    print(config)
    print(f"\nClient Public Key (add to server): {public_key}")
    print(f"\n[Peer]")
    print(f"PublicKey = {public_key}")
    print(f"AllowedIPs = {client_ip}/32")
    print("\n" + "="*50 + "\n")

if __name__ == "__main__":
    print("WireGuard Configuration Generator")
    print("="*50)
    
    server_ip = input("Server public IP: ")
    listen_port = input("Listen port (default 51820): ") or "51820"
    subnet = input("VPN subnet (e.g., 10.99.0): ")
    
    server_pubkey = generate_server_config(server_ip, listen_port, subnet)
    
    while True:
        add_client = input("\nAdd client? (y/n): ")
        if add_client.lower() != 'y':
            break
        
        client_name = input("Client name: ")
        client_num = input(f"Client IP (e.g., for {subnet}.10 enter 10): ")
        client_ip = f"{subnet}.{client_num}"
        
        generate_client_config(client_name, client_ip, server_pubkey, f"{server_ip}:{listen_port}")
```

---

## Best Practices

### Configuration Management

✅ Use descriptive comments in configs  
✅ Version control configurations (git)  
✅ Backup private keys securely  
✅ Document IP assignments  
✅ Use consistent naming (client1.conf, client2.conf)  

### Performance Tuning

✅ Use MTU 1420 for most cases  
✅ PersistentKeepalive only when needed (NAT)  
✅ Monitor CPU usage  
✅ Consider hardware with AES-NI for encryption offload  

### Security Hardening

✅ Minimize AllowedIPs per peer  
✅ Use firewall rules (PostUp/PostDown)  
✅ Regular key rotation schedule  
✅ Enable kernel lockdown if available  
✅ Disable IPv6 if not used  
✅ Use PresharedKey for quantum resistance  

### Deployment Checklist

- [ ] Generate unique keys per peer
- [ ] Document IP addressing scheme
- [ ] Configure firewall rules
- [ ] Test connectivity before production
- [ ] Setup monitoring/alerts
- [ ] Create runbook for common issues
- [ ] Backup all configurations
- [ ] Plan key rotation procedure

---

## Comparison: WireGuard vs OpenVPN

| Feature | WireGuard | OpenVPN |
|---------|-----------|---------|
| **Codebase** | ~4,000 lines | ~70,000 lines |
| **Performance** | ★★★★★ (3-4x faster) | ★★★☆☆ |
| **Setup** | ★★★★★ (simple) | ★★☆☆☆ (complex) |
| **Crypto** | Modern (fixed suite) | Configurable (good & bad) |
| **Protocols** | UDP only | UDP/TCP |
| **Authentication** | Public keys | Certs/PSK/User-Pass |
| **Mobile Battery** | ★★★★★ (efficient) | ★★★☆☆ |
| **Roaming** | ★★★★★ (seamless) | ★★★☆☆ |
| **NAT Traversal** | ★★★★★ | ★★★★☆ |
| **Audit** | ★★★★★ (easy) | ★★★☆☆ |
| **Enterprise** | ★★★☆☆ (growing) | ★★★★★ (mature) |

**Quando usare WireGuard**:
- Nuovi deployment
- Performance critiche
- Mobile users
- Site-to-site con IP statici

**Quando usare OpenVPN**:
- Enterprise con user auth requirements
- Need TCP mode
- Legacy systems compatibility
- Audited compliance requirements

---

## Risorse

- **Sito Ufficiale**: https://www.wireguard.com/
- **Whitepaper**: https://www.wireguard.com/papers/wireguard.pdf
- **Quick Start**: https://www.wireguard.com/quickstart/
- **Installation**: https://www.wireguard.com/install/
- **Mailing List**: https://lists.zx2c4.com/mailman/listinfo/wireguard
- **GitHub**: https://github.com/WireGuard

---

**Fine Guida WireGuard**  
**Torna a**: [README](README.md)
