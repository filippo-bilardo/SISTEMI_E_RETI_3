# Lab 4: WireGuard VPN

## Obiettivi
- Configurare WireGuard server e client
- Implementare peer-to-peer VPN
- Testare performance

## Step 1: Installazione WireGuard

```bash
# Ubuntu 20.04+
apt-get update
apt-get install -y wireguard

# Verifica
wg --version
```

## Step 2: Generazione Chiavi

**Su server**:
```bash
cd /etc/wireguard
umask 077

# Generate server keys
wg genkey | tee server-private.key | wg pubkey > server-public.key

# Generate client keys
wg genkey | tee client1-private.key | wg pubkey > client1-public.key
wg genkey | tee client2-private.key | wg pubkey > client2-public.key
```

## Step 3: Configurazione Server

```bash
# /etc/wireguard/wg0.conf
cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
Address = 10.99.0.1/24
ListenPort = 51820
PrivateKey = $(cat server-private.key)

# Firewall rules
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client 1
[Peer]
PublicKey = $(cat client1-public.key)
AllowedIPs = 10.99.0.10/32

# Client 2
[Peer]
PublicKey = $(cat client2-public.key)
AllowedIPs = 10.99.0.11/32
EOF

# IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Firewall allow WireGuard
ufw allow 51820/udp

# Start WireGuard
wg-quick up wg0
systemctl enable wg-quick@wg0
```

## Step 4: Configurazione Client

```bash
# client1.conf
[Interface]
Address = 10.99.0.10/24
PrivateKey = <CLIENT1_PRIVATE_KEY>
DNS = 8.8.8.8

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0, ::/0  # Route all traffic
PersistentKeepalive = 25

# Connetti
wg-quick up client1
```

## Step 5: Verifica

```bash
# Server
wg show

# Output example:
# interface: wg0
#   public key: ...
#   private key: (hidden)
#   listening port: 51820
#
# peer: <client1-pubkey>
#   endpoint: 198.51.100.10:38472
#   allowed ips: 10.99.0.10/32
#   latest handshake: 45 seconds ago
#   transfer: 12.34 KiB received, 56.78 KiB sent

# Client
ping 10.99.0.1
curl ifconfig.me  # Should show server IP
```

## Step 6: Performance Test

```bash
# Server install iperf3
apt-get install -y iperf3

# Server mode
iperf3 -s

# Client
iperf3 -c 10.99.0.1

# Compare with OpenVPN/IPsec throughput
```

## Esercizi

1. **Mobile client**: Genera QR code per import su mobile
2. **Split tunnel**: Modifica AllowedIPs per split tunneling
3. **Site-to-site**: Setup WireGuard site-to-site
4. **Monitoring**: Dashboard per visualizzare transfer stats

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 3: IPsec Site-to-Site](Lab3_IPsec_Site-to-Site.md)  
**Prossimo Lab**: [Lab 5: VPN Failover](Lab5_VPN_Failover.md)
