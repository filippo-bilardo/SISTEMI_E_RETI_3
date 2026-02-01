# Diagramma Topologia di Rete - A038_STR24

## Topologia Fisica

```
                                INTERNET
                                   |
                    [ISP Router/Modem]
                                   |
                                   | WAN
                    +---------------------------+
                    |   ROUTER/GATEWAY          |
                    |   172.16.0.1              |
                    +---------------------------+
                                   | LAN
                    +---------------------------+
                    |   FIREWALL                |
                    |   172.16.0.2              |
                    +---------------------------+
                           |       |       |
              +------------+       |       +------------+
              |                    |                    |
    +---------+-------+   +--------+--------+   +-------+--------+
    | Switch Core L3  |   |  Switch DMZ     |   | Switch LAN2    |
    | 172.16.30.2     |   |  172.16.30.5    |   | 172.16.30.4    |
    +-----------------+   +-----------------+   +----------------+
         |        |              |                      |
    +----+        +----+    +----+----+            +---+---+
    |                  |    |         |            |       |
+---+---+         +----+----+    +----+----+   +---+---+  |
|Switch |         |Switch   |    |Web Srv  |   |DNS    |  |
|LAN1   |         |LAN3     |    |.10.10   |   |.2.10  |  |
|.30.3  |         |.30.6    |    +---------+   +-------+  |
+-------+         +---------+    |Mail Srv |   |DHCP   |  |
   |                  |          |.10.11   |   |.2.11  |  |
   |                  |          +---------+   +-------+  |
+--+--+            +--+--+                     |File   |  |
|PC 1 |            |Admin|                     |.2.12  |  |
+-----+            +-----+                     +-------+  |
|PC 2 |            |Admin|                     |DB Srv |  |
+-----+            +-----+                     |.2.13  |  |
  ...                ...                       +-------+  |
                                                  ...      |
                                                          
```

## Topologia Logica - VLAN

```
                    +---------------------------+
                    |    SWITCH CORE L3         |
                    |    Inter-VLAN Routing     |
                    +---------------------------+
                    /      |       |      \      \
                   /       |       |       \      \
           VLAN 10/   VLAN 20  VLAN 30  VLAN 40  VLAN 50
              |           |       |           |         |
         +---------+ +---------+ +------+ +-------+ +------+
         | LAN1    | | LAN2    | | LAN3 | | DMZ   | | MGMT |
         | Utenti  | | Server  | |Admin | |Public | | Net  |
         +---------+ +---------+ +------+ +-------+ +------+
         172.16.1.0  172.16.2.0  172.3.0  172.10.0  172.30.0
           /24         /24        /24      /26       /28
```

## Schema DMZ Dettagliato

```
                    INTERNET
                        |
                        v
               [Firewall WAN]
                        |
            +-----------+-----------+
            |                       |
    [Port Forwarding]       [NAT/Masquerade]
            |                       |
     +------+------+                |
     |             |                |
 [DMZ VLAN 40]     |                |
     |             |                |
  +--+--+      +---+---+            |
  |Web  |      |Mail   |            |
  |.10  |      |.11    |            |
  +-----+      +-------+            |
                                    |
                            +-------+--------+
                            |                |
                        [LAN Interna]    [Server]
                        172.16.1.0       172.16.2.0
```

## Flusso Traffico

### 1. Utente Internet → Web Server DMZ
```
Internet → Router WAN → Firewall → Port Fwd → DMZ Switch → Web Server
                                    (NAT 80→.10.10:80)
```

### 2. Utente LAN1 → Internet
```
PC LAN1 → Switch LAN1 → Switch Core → Firewall → Router → Internet
                         (VLAN 10)     (NAT PAT)   (WAN)
```

### 3. Utente LAN1 → File Server LAN2
```
PC LAN1 → Switch LAN1 → Switch Core → Switch LAN2 → File Server
           (VLAN 10)    (Routing)      (VLAN 20)    (172.16.2.12)
                        (ACL Check)
```

### 4. Admin LAN3 → DMZ Server
```
Admin → Switch LAN3 → Switch Core → DMZ Switch → Web/Mail Server
        (VLAN 30)     (Routing)     (VLAN 40)     (172.16.10.x)
                      (ACL: Allow)
```

### 5. Client VPN → LAN Interna
```
Remote Client → Internet → Router → VPN Server → Tunnel → LAN
                           (1194)   (172.16.10.13) (tun0)  (172.16.x.x)
```

## Matrice di Comunicazione

| Da \ Verso | Internet | LAN1 | LAN2 | LAN3 | DMZ | VPN |
|------------|----------|------|------|------|-----|-----|
| Internet   | -        | ❌   | ❌   | ❌   | ✅  | ✅  |
| LAN1       | ✅       | ✅   | ✅   | ❌   | ❌  | ❌  |
| LAN2       | ✅       | ✅   | ✅   | ✅   | ❌  | ❌  |
| LAN3       | ✅       | ✅   | ✅   | ✅   | ✅  | ✅  |
| DMZ        | ✅       | ❌   | ❌   | ❌   | ✅  | ❌  |
| VPN        | ✅       | ✅   | ✅   | ✅   | ❌  | ✅  |

Legenda:
- ✅ Traffico permesso
- ❌ Traffico bloccato

## Schema Cablaggio

```
Rack 1 - Core Network
+------------------------+
| Patch Panel 24 porte   |
+------------------------+
| Switch Core L3         | <- Uplink a Router
| 24 porte + 2 SFP       |
+------------------------+
| Firewall 1U            |
+------------------------+
| Router/Gateway 1U      |
+------------------------+

Rack 2 - Servers
+------------------------+
| Patch Panel 24 porte   |
+------------------------+
| Switch Server          |
| 24 porte               |
+------------------------+
| Server DNS/DHCP        | <- 172.16.2.10-11
+------------------------+
| Server File/DB         | <- 172.16.2.12-13
+------------------------+
| NAS Storage            | <- 172.16.2.30
+------------------------+

Rack 3 - DMZ
+------------------------+
| Patch Panel 12 porte   |
+------------------------+
| Switch DMZ             |
| 12 porte               |
+------------------------+
| Web Server             | <- 172.16.10.10
+------------------------+
| Mail Server            | <- 172.16.10.11
+------------------------+
```

## Schema Logico Sicurezza

```
+----------------+
|   Internet     |
+----------------+
        |
    [Firewall L1: Border]
        |
    +---+---+
    |       |
  [DMZ]   [Firewall L2: Internal]
    |       |
    |   +---+---+
    |   |       |
    | [LAN] [Server]
    |
[Isolato dalla LAN]
```

### Livelli di Sicurezza
1. **Perimetro**: Firewall esterno + NAT
2. **DMZ**: Isolamento server pubblici
3. **Interno**: Segmentazione VLAN
4. **Server**: ACL dedicate
5. **Management**: VLAN separata

---

**Documento**: Architettura di Rete  
**Progetto**: A038_STR24  
**Data**: 30 Gennaio 2026
