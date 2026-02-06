# Lab 5: VPN Failover e Load Balancing

## Obiettivi
- Configurare multiple VPN tunnel
- Implementare failover automatico
- Load balancing traffico

## Topology

```
              Branch Office
                    |
        +-----------+-----------+
        |                       |
    Tunnel 1 (primary)     Tunnel 2 (backup)
     IPsec/strongSwan      OpenVPN
        |                       |
        +-----------+-----------+
                    |
                 Headquarters
```

## Step 1: Primary Tunnel (IPsec)

```bash
# /etc/ipsec.conf
conn primary-tunnel
    left=%any
    leftsubnet=192.168.10.0/24
    right=203.0.113.100
    rightsubnet=192.168.1.0/24
    authby=secret
    ike=aes256-sha2_256-modp2048!
    esp=aes256-sha2_256!
    keyexchange=ikev2
    dpdaction=restart
    dpddelay=10s
    auto=start
    # Metric 100 (preferred)
    mark=100
```

## Step 2: Backup Tunnel (OpenVPN)

```bash
# /etc/openvpn/backup.conf
remote 203.0.113.101
port 1194
proto udp
dev tun1
# Metric 200 (backup)
route-metric 200
```

## Step 3: Health Check Script

```bash
#!/bin/bash
# /usr/local/bin/vpn-failover.sh

PRIMARY_GW="10.0.1.1"  # IPsec gateway
BACKUP_GW="10.0.2.1"   # OpenVPN gateway
CHECK_HOST="192.168.1.1"  # HQ resource

while true; do
    # Check primary
    if ping -c 3 -W 2 -I $PRIMARY_GW $CHECK_HOST &>/dev/null; then
        echo "$(date): Primary UP"
        # Ensure primary route has priority
        ip route change 192.168.1.0/24 via $PRIMARY_GW metric 100
    else
        echo "$(date): Primary DOWN, using backup"
        # Promote backup route
        ip route change 192.168.1.0/24 via $BACKUP_GW metric 50
        # Alert
        echo "VPN failover activated" | mail -s "VPN Alert" admin@company.com
    fi
    
    sleep 30
done
```

## Step 4: Systemd Service

```bash
# /etc/systemd/system/vpn-failover.service
[Unit]
Description=VPN Failover Monitor
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vpn-failover.sh
Restart=always

[Install]
WantedBy=multi-user.target

# Enable
systemctl enable vpn-failover
systemctl start vpn-failover
```

## Step 5: Load Balancing (ECMP)

```bash
# Equal-Cost Multi-Path routing
# Traffico distribuito tra 2 tunnel

# Add both routes with same metric
ip route add 192.168.1.0/24 \
    nexthop via 10.0.1.1 weight 1 \
    nexthop via 10.0.2.1 weight 1

# Verify
ip route show 192.168.1.0/24
```

## Esercizi

1. **Simulate failure**: Disconnetti primary e verifica automatic failover
2. **Weighted load balancing**: Configura 70/30 split tra tunnel
3. **BGP**: Implementa BGP per dynamic routing
4. **Monitoring**: Grafana dashboard per tunnel health

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 4: WireGuard VPN](Lab4_WireGuard_VPN.md)  
**Prossimo Lab**: [Lab 6: WireGuard con Container Docker](Lab6_WireGuard_Docker_Windows.md)
