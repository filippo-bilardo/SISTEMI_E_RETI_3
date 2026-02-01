# ARCHITETTURA DI RETE
## Prova A038_ORD24

---

## Diagramma Topologia Fisica

```
                                INTERNET
                                    |
                                    | (IP Pubblico)
                                    |
                           +--------+--------+
                           |  ROUTER GATEWAY |
                           |  10.50.0.1      |
                           +--------+--------+
                                    |
                                    | GigabitEthernet
                                    |
                           +--------+--------+
                           |  FIREWALL/UTM   |
                           |  10.50.0.2      |
                           +--------+--------+
                                    |
                    +---------------+---------------+
                    |                               |
            +-------+-------+               +-------+-------+
            | SWITCH CORE L3|               |   DMZ SWITCH  |
            | 10.50.1.2     |               |  10.50.100.1  |
            +-------+-------+               +-------+-------+
                    |                               |
         +----------+----------+              +-----+-----+
         |          |          |              |           |
    +----+---+ +----+---+ +----+---+    +-----+----+ +----+----+
    |SW LAN1 | |SW LAN2 | |SW LAN3 |    |  WEB     | | MAIL    |
    |10.50.10| |10.50.20| |10.50.30|    |  10.50.  | | 10.50.  |
    +--------+ +--------+ +--------+    |  100.10  | | 100.11  |
         |          |          |        +----------+ +---------+
    PC Utenti   Server    Admin IT
```

---

## Diagramma Topologia Logica (VLAN)

```
┌──────────────────────────────────────────────────────────────┐
│                     SWITCH CORE LAYER 3                      │
│                      (Inter-VLAN Routing)                     │
├────────────┬────────────┬────────────┬────────────┬──────────┤
│  VLAN 10   │  VLAN 20   │  VLAN 30   │  VLAN 100  │ VLAN 200 │
│  LAN1      │  LAN2      │  LAN3      │  DMZ       │ VPN      │
│  Utenti    │  Server    │  Admin     │  Pubblici  │ Remote   │
│            │            │            │            │          │
│ 10.50.10.  │ 10.50.20.  │ 10.50.30.  │ 10.50.100. │10.50.200.│
│  /24       │  /24       │  /24       │   /26      │  /26     │
└────────────┴────────────┴────────────┴────────────┴──────────┘
```

---

## Schema VLAN e Porte

| VLAN ID | Nome | Network | Porte Assegnate | Dispositivi |
|---------|------|---------|-----------------|-------------|
| 10 | LAN1-Utenti | 10.50.10.0/24 | Gi1/0/2 (trunk) | PC, Stampanti, AP WiFi |
| 20 | LAN2-Server | 10.50.20.0/24 | Gi1/0/10-15 (access) | DNS, DHCP, File, DB, VPN |
| 30 | LAN3-Admin | 10.50.30.0/24 | Gi1/0/3 (trunk) | Workstation Admin |
| 100 | DMZ | 10.50.100.0/26 | Gi1/0/4 (trunk) | Web, Mail Server |
| 200 | VPN | 10.50.200.0/26 | Software | Client VPN remoti |
| 1 | Management | 10.50.1.0/24 | - | Management dispositivi |
| 999 | Blackhole | - | Native VLAN | Security (drop) |

---

## Flussi di Traffico e Matrice di Comunicazione

| Sorgente | Destinazione | Permesso | Firewall Rule | Note |
|----------|--------------|----------|---------------|------|
| Internet | DMZ (80, 443, 25, 587, 993) | ✓ | DNAT + FORWARD | Port forwarding |
| Internet | LAN | ✗ | DROP | Bloccato |
| DMZ | LAN | ✗ | DROP | Isolamento completo |
| DMZ | Internet | ✓ | FORWARD + SNAT | Aggiornamenti |
| LAN1 | Internet | ✓ | FORWARD + NAT | Navigazione |
| LAN1 | LAN2 | ✓ | FORWARD | Accesso server |
| LAN1 | DMZ | ✗ | DROP | No accesso diretto |
| LAN3 (Admin) | DMZ | ✓ | FORWARD | Gestione server |
| LAN3 (Admin) | LAN2 | ✓ | FORWARD | Gestione server |
| LAN3 (Admin) | Internet | ✓ | FORWARD + NAT | Navigazione |
| VPN | LAN1/2/3 | ✓ | FORWARD | Accesso remoto |
| VPN | DMZ | ✓ | FORWARD | Amministrazione |

---

## Diagramma Sicurezza Multi-Livello

```
┌─────────────────────────────────────────────────────┐
│ LIVELLO 1: Perimetro                                │
│ - Router con ACL anti-spoofing                      │
│ - Firewall con policy DROP-ALL                      │
│ - NAT/PAT per nascondere rete interna              │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ LIVELLO 2: Segmentazione                            │
│ - VLAN separate (10, 20, 30, 100, 200)            │
│ - DMZ isolata da LAN                                │
│ - Inter-VLAN routing controllato                    │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ LIVELLO 3: Switch Security                          │
│ - Port Security (MAC sticky)                        │
│ - DHCP Snooping                                      │
│ - Dynamic ARP Inspection                             │
│ - IP Source Guard                                    │
└─────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────┐
│ LIVELLO 4: Servizi                                   │
│ - TLS/SSL su tutti i servizi pubblici              │
│ - Autenticazione SASL (mail)                        │
│ - VPN con crittografia AES-256                      │
│ - SSH (no telnet)                                    │
└─────────────────────────────────────────────────────┘
```

---

## Punti di Ingresso/Uscita

### Ingresso (Inbound)
1. **Porta 80/443** → Web Server DMZ (10.50.100.10)
2. **Porta 25/587/993** → Mail Server DMZ (10.50.100.11)
3. **Porta 1194** → VPN Server (10.50.20.15)

### Uscita (Outbound)
1. **LAN → Internet**: NAT Masquerading tramite Router
2. **DMZ → Internet**: FORWARD consentito per aggiornamenti
3. **VPN → LAN**: Routing diretto via tunnel

---

## Ridondanza e Failover (Opzionale)

```
Router Principale (10.50.0.1)
        ↓
    HSRP/VRRP (VIP)
        ↓
Router Secondario (10.50.0.3)
```

**Protocollo**: HSRP (Cisco) o VRRP (standard)  
**Virtual IP**: 10.50.0.254  
**Priorità**: Router1=110, Router2=100  
**Preempt**: Enabled

---

## QoS (Quality of Service) - Schema

| Classe | Priorità | Bandwidth | Applicazione |
|--------|----------|-----------|--------------|
| Voice | Highest | 30% | VoIP (RTP 16384-32767) |
| Video | High | 20% | Video conferencing |
| Business | Medium | 30% | HTTP/HTTPS, Mail |
| Default | Low | 20% | Resto traffico |

---

## Monitoring Points

1. **Router**: SNMP trap, syslog → 10.50.20.12
2. **Switch**: SNMP trap, syslog → 10.50.20.12
3. **Firewall**: iptables log → /var/log/iptables.log
4. **Servizi**: Application logs → Syslog centralizzato

---

## Backup e DR

### Backup Giornaliero
- **Device Config**: Router, Switch (TFTP/SCP)
- **Server Config**: /etc/* (rsync)
- **Database**: mysqldump
- **File**: /var/www, /var/mail

### Storage Backup
- **Primario**: File Server 10.50.20.12
- **Secondario**: Storage esterno/NAS
- **Offsite**: Cloud backup (opzionale)

---

## Scalabilità Futura

**Possibili Espansioni:**
- Aggiunta VLAN 40, 50, 60 per nuovi reparti
- Load balancer per Web Server
- Server cluster (HA)
- IDS/IPS (Snort/Suricata)
- SIEM per log correlation
- WiFi Controller per gestione AP
