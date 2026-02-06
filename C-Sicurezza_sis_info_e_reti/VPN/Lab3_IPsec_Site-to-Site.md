# Lab 3: IPsec Site-to-Site con strongSwan

## Obiettivi
- Configurare IPsec site-to-site con IKEv2
- Implementare autenticazione PSK
- Configurare routing automatico

## Topology

```
Site A                              Site B
192.168.10.0/24                     192.168.20.0/24
      |                                   |
 Gateway A                           Gateway B
 203.0.113.100                       198.51.100.200
      |                                   |
      +-------- IPsec Tunnel -------------+
```

## Step 1: Installazione strongSwan

**Su entrambi i gateway**:
```bash
apt-get update
apt-get install -y strongswan strongswan-pki

# Verifica
ipsec version
```

## Step 2: Configurazione Site A

```bash
# /etc/ipsec.conf
cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="ike 2, knl 2, cfg 2"
    uniqueids=never

conn site-to-site
    left=%any
    leftid=@site-a.company.local
    leftsubnet=192.168.10.0/24
    
    right=198.51.100.200
    rightid=@site-b.company.local
    rightsubnet=192.168.20.0/24
    
    authby=secret
    
    ike=aes256-sha2_256-modp2048!
    esp=aes256-sha2_256!
    
    keyexchange=ikev2
    ikelifetime=28800s
    lifetime=3600s
    
    dpdaction=restart
    dpddelay=30s
    dpdtimeout=120s
    
    auto=start
EOF

# /etc/ipsec.secrets
cat > /etc/ipsec.secrets <<EOF
@site-a.company.local @site-b.company.local : PSK "MyVerySecurePreSharedKey12345"
EOF

chmod 600 /etc/ipsec.secrets

# IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# Disable ICMP redirects (important for IPsec)
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
```

## Step 3: Configurazione Site B

```bash
# /etc/ipsec.conf
cat > /etc/ipsec.conf <<EOF
config setup
    charondebug="ike 2, knl 2, cfg 2"
    uniqueids=never

conn site-to-site
    left=%any
    leftid=@site-b.company.local
    leftsubnet=192.168.20.0/24
    
    right=203.0.113.100
    rightid=@site-a.company.local
    rightsubnet=192.168.10.0/24
    
    authby=secret
    
    ike=aes256-sha2_256-modp2048!
    esp=aes256-sha2_256!
    
    keyexchange=ikev2
    ikelifetime=28800s
    lifetime=3600s
    
    dpdaction=restart
    dpddelay=30s
    dpdtimeout=120s
    
    auto=start
EOF

# /etc/ipsec.secrets
cat > /etc/ipsec.secrets <<EOF
@site-b.company.local @site-a.company.local : PSK "MyVerySecurePreSharedKey12345"
EOF

chmod 600 /etc/ipsec.secrets

# Sysctl settings
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
```

## Step 4: Firewall Configuration

**Su entrambi i gateway**:
```bash
# Allow IKE
iptables -A INPUT -p udp --dport 500 -j ACCEPT

# Allow NAT-T
iptables -A INPUT -p udp --dport 4500 -j ACCEPT

# Allow ESP
iptables -A INPUT -p esp -j ACCEPT

# Allow forwarding IPsec traffic
iptables -A FORWARD -s 192.168.10.0/24 -d 192.168.20.0/24 -j ACCEPT
iptables -A FORWARD -s 192.168.20.0/24 -d 192.168.10.0/24 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

## Step 5: Start strongSwan

```bash
# Start service
systemctl start strongswan-starter
systemctl enable strongswan-starter

# Reload config
ipsec reload

# Start connection
ipsec up site-to-site
```

## Step 6: Verifica

```bash
# Check status
ipsec status
ipsec statusall

# Dovrebbe mostrare:
# Security Associations (1 up, 0 connecting):
# site-to-site[1]: ESTABLISHED

# Check installed SAs
ip xfrm state
ip xfrm policy

# Test connectivity
ping 192.168.20.1  # From Site A to Site B

# Packet capture per vedere ESP
tcpdump -i eth0 -n esp
```

## Troubleshooting

```bash
# Enable detailed logging
ipsec stop
ipsec start --nofork --debug-all

# Check logs
journalctl -u strongswan -f

# Common issues:
# - "no proposal chosen" → cipher mismatch
# - "authentication failed" → PSK mismatch o ID wrong
# - "TS unacceptable" → subnet mismatch
```

## Esercizi

1. **Certificati**: Sostituisci PSK con autenticazione certificati X.509
2. **Multiple subnets**: Aggiungi ulteriori subnet per site
3. **Redundancy**: Configura backup tunnel
4. **Monitoring**: Script per check tunnel health

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 2: OpenVPN Remote Access](Lab2_OpenVPN_Remote_Access.md)  
**Prossimo Lab**: [Lab 4: WireGuard VPN](Lab4_WireGuard_VPN.md)
