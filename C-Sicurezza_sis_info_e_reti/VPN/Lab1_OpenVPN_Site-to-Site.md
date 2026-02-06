# Lab 1: OpenVPN Site-to-Site

## Obiettivi
- Configurare VPN site-to-site tra due reti usando OpenVPN
- Implementare autenticazione con pre-shared key
- Verificare routing tra le reti

## Topology

```
Site A (HQ)                         Site B (Branch)
192.168.1.0/24                      192.168.2.0/24
       |                                   |
   VPN Gateway A                      VPN Gateway B
   eth0: 203.0.113.10                eth0: 198.51.100.20
   tun0: 10.8.0.1                    tun0: 10.8.0.2
       |                                   |
       +------- Internet (routed) ---------+
```

## Prerequisiti
- 2 VM Linux (Ubuntu 20.04+ o Debian 11+)
- Accesso root
- Connettività IP tra le VM

## Step 1: Installazione OpenVPN

**Su entrambi i gateway**:
```bash
apt-get update
apt-get install -y openvpn easy-rsa

# Verifica installazione
openvpn --version
```

## Step 2: Generazione Pre-Shared Key

**Su Gateway A**:
```bash
# Genera static key per autenticazione
openvpn --genkey secret /etc/openvpn/static.key

# Copia questo file su Gateway B
# Via SCP:
scp /etc/openvpn/static.key root@198.51.100.20:/etc/openvpn/
```

## Step 3: Configurazione Gateway A (Server)

```bash
cat > /etc/openvpn/site-a.conf <<EOF
# Site A Configuration
dev tun
ifconfig 10.8.0.1 10.8.0.2
secret /etc/openvpn/static.key

# Remote endpoint
remote 198.51.100.20
port 1194
proto udp

# Routing
route 192.168.2.0 255.255.255.0

# Persistence
persist-key
persist-tun
keepalive 10 60

# Logging
status /var/log/openvpn/status-a.log
log-append /var/log/openvpn/openvpn-a.log
verb 3
EOF

# Crea directory log
mkdir -p /var/log/openvpn

# Abilita IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Firewall (iptables)
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT

# Start OpenVPN
systemctl start openvpn@site-a
systemctl enable openvpn@site-a
```

## Step 4: Configurazione Gateway B (Client)

```bash
cat > /etc/openvpn/site-b.conf <<EOF
# Site B Configuration
dev tun
ifconfig 10.8.0.2 10.8.0.1
secret /etc/openvpn/static.key

# Remote endpoint
remote 203.0.113.10
port 1194
proto udp

# Routing
route 192.168.1.0 255.255.255.0

# Persistence
persist-key
persist-tun
keepalive 10 60

# Logging
status /var/log/openvpn/status-b.log
log-append /var/log/openvpn/openvpn-b.log
verb 3
EOF

mkdir -p /var/log/openvpn

# IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

# Firewall
iptables -A FORWARD -i tun0 -j ACCEPT
iptables -A FORWARD -o tun0 -j ACCEPT

# Start OpenVPN
systemctl start openvpn@site-b
systemctl enable openvpn@site-b
```

## Step 5: Verifica

**Su Gateway A**:
```bash
# Check tunnel interface
ip addr show tun0
# Dovrebbe mostrare: inet 10.8.0.1 peer 10.8.0.2/32

# Check routing
ip route | grep tun0
# Dovrebbe mostrare: 192.168.2.0/24 via 10.8.0.2 dev tun0

# Ping remote tunnel endpoint
ping -c 3 10.8.0.2

# Ping remote LAN
ping -c 3 192.168.2.1

# Check logs
tail -20 /var/log/openvpn/openvpn-a.log
```

**Su Gateway B** (verifiche analoghe):
```bash
ip addr show tun0
ping -c 3 10.8.0.1
ping -c 3 192.168.1.1
tail -20 /var/log/openvpn/openvpn-b.log
```

## Troubleshooting

**Problema**: Tunnel non si stabilisce
```bash
# Verifica connectivity
ping 198.51.100.20

# Verifica firewall
iptables -L -v -n | grep 1194

# Check logs per errori
journalctl -u openvpn@site-a -n 50
```

**Problema**: Tunnel UP ma ping non funziona
```bash
# Verifica IP forwarding
sysctl net.ipv4.ip_forward  # Deve essere 1

# Verifica routing
ip route show

# Verifica FORWARD chain
iptables -L FORWARD -v -n
```

## Esercizi Addizionali

1. **NAT**: Configura NAT su Gateway A per permettere a client Site A accedere a Site B
2. **Monitoring**: Setup script per monitorare uptime tunnel
3. **Failover**: Simula disconnessione e verifica recovery
4. **Performance**: Benchmark throughput con iperf3

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Prossimo Lab**: [Lab 2: OpenVPN Remote Access](Lab2_OpenVPN_Remote_Access.md)
