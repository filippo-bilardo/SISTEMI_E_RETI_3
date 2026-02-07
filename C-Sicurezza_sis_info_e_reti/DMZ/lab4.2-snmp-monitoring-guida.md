# LAB 4.2 - Monitoring DMZ con SNMP

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 2.5 ore  
**File da creare:** `lab4.2-snmp-monitoring.pkt`  
**Prerequisiti:** LAB 1.1, LAB 4.1

---

## Obiettivi del Laboratorio
- Comprendere protocollo SNMP (v1, v2c, v3)
- Configurare SNMP agent su router/firewall
- Implementare SNMP community strings
- Configurare SNMP traps e informs
- Monitorare CPU, memory, interfaces
- Implementare SNMPv3 security
- Analizzare SNMP MIB structure

---

## SNMP: Fondamenti

### Cos'è SNMP?

**SNMP** = Simple Network Management Protocol
- **Scopo:** Monitor e manage dispositivi di rete
- **Protocollo:** UDP-based (161 queries, 162 traps)
- **Architettura:** Manager ↔ Agent

### SNMP Versions

| Version | Security | Pro | Contro |
|---------|----------|-----|--------|
| SNMPv1 | Community string (plaintext) | Semplice | Insicuro |
| SNMPv2c | Community string (plaintext) | Bulk transfer | Insicuro |
| SNMPv3 | Authentication + Encryption | Sicuro | Complesso |

**Best Practice:** Usare **SNMPv3** in produzione!

### SNMP Components

```
[NMS - Network Management Station]
        |
        | SNMP Query (UDP 161)
        ↓
[SNMP Agent] (router, switch)
        |
        | SNMP Trap (UDP 162)
        ↓
[NMS Trap Receiver]
```

### MIB (Management Information Base)

**MIB** = Database of managed objects
- **OID** = Object Identifier (es. 1.3.6.1.2.1.1.3.0 = sysUpTime)
- Struttura gerarchica

```
iso(1)
  └─ org(3)
       └─ dod(6)
            └─ internet(1)
                 └─ mgmt(2)
                      └─ mib-2(1)
                           ├─ system(1)
                           ├─ interfaces(2)
                           ├─ ip(4)
                           └─ tcp(6)
```

---

## Topologia

```
                        [Router/Firewall]
                       /        |        \
                  G0/0 (WAN) G0/1 (DMZ) G0/2 (LAN)
                     |           |            |
              [Internet]    [Switch-DMZ]  [Switch-LAN]
              198.51.100.1       |              |
                            10.0.1.10      172.16.0.60
                            10.0.1.20         |
                                |             |
                          [Web-Server]   [SNMP-NMS]     172.16.0.60
                          [Mail-Server]  [Syslog-Srv]   172.16.0.50
                                         [PC-Admin]     172.16.0.10
```

---

## Parte 1: Setup Base

### Piano IP

| Dispositivo | IP | Mask | Ruolo |
|-------------|----|------|-------|
| FW G0/0 | 198.51.100.254 | /24 | WAN |
| FW G0/1 | 10.0.1.1 | /24 | DMZ |
| FW G0/2 | 172.16.0.1 | /24 | LAN |
| Web-Srv | 10.0.1.10 | /24 | DMZ Web |
| Mail-Srv | 10.0.1.20 | /24 | DMZ Mail |
| SNMP-NMS | 172.16.0.60 | /24 | SNMP Manager |
| Syslog-Srv | 172.16.0.50 | /24 | Log Server |
| PC-Admin | 172.16.0.10 | /24 | Admin |

### Configurazione Router Base

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-SNMP
FW-SNMP(config)#

! Interfacce (come lab precedenti)
FW-SNMP(config)# interface GigabitEthernet 0/0
FW-SNMP(config-if)# description WAN
FW-SNMP(config-if)# ip address 198.51.100.254 255.255.255.0
FW-SNMP(config-if)# no shutdown
FW-SNMP(config-if)# exit

FW-SNMP(config)# interface GigabitEthernet 0/1
FW-SNMP(config-if)# description DMZ
FW-SNMP(config-if)# ip address 10.0.1.1 255.255.255.0
FW-SNMP(config-if)# no shutdown
FW-SNMP(config-if)# exit

FW-SNMP(config)# interface GigabitEthernet 0/2
FW-SNMP(config-if)# description LAN
FW-SNMP(config-if)# ip address 172.16.0.1 255.255.255.0
FW-SNMP(config-if)# no shutdown
FW-SNMP(config-if)# exit

! Routing
FW-SNMP(config)# ip route 0.0.0.0 0.0.0.0 198.51.100.1
```

---

## Parte 2: Configurazione SNMPv2c (Basic)

### Enable SNMP Agent

```cisco
! Abilitare SNMP
FW-SNMP(config)# snmp-server community public RO
FW-SNMP(config)# snmp-server community private RW

! RO = Read-Only (query)
! RW = Read-Write (set values) - PERICOLOSO!
```

**⚠️ ATTENZIONE:** "public" e "private" = username/password default!
**MAI usare in produzione!**

### Community String Sicure (Better)

```cisco
! Community custom con ACL
FW-SNMP(config)# access-list 10 remark SNMP-ALLOWED-HOSTS
FW-SNMP(config)# access-list 10 permit host 172.16.0.60
! (Solo SNMP-NMS può query)

! Community name complessa + ACL
FW-SNMP(config)# snmp-server community MyS3cur3SNMP! RO 10
FW-SNMP(config)# snmp-server community MyW!t3SNMP! RW 10
```

### SNMP System Information

```cisco
! Configurare info sistema
FW-SNMP(config)# snmp-server location "DMZ Firewall - DataCenter Room 101"
FW-SNMP(config)# snmp-server contact "admin@example.com"
FW-SNMP(config)# snmp-server chassis-id "FW-PRIMARY-001"
```

---

## Parte 3: Configurazione SNMP Traps

### Enable SNMP Traps

```cisco
! Configurare trap receiver (NMS)
FW-SNMP(config)# snmp-server host 172.16.0.60 version 2c MyS3cur3SNMP!

! Abilitare trap types
FW-SNMP(config)# snmp-server enable traps snmp authentication linkdown linkup

! Trap per config changes
FW-SNMP(config)# snmp-server enable traps config

! Trap per CPU threshold
FW-SNMP(config)# snmp-server enable traps cpu threshold

! Trap per memory
FW-SNMP(config)# snmp-server enable traps memory

! Trap per BGP (se usato)
FW-SNMP(config)# snmp-server enable traps bgp

! Trap per HSRP (se usato)
FW-SNMP(config)# snmp-server enable traps hsrp
```

### Trap Categories

| Trap Type | Quando Inviato |
|-----------|----------------|
| linkdown | Interfaccia down |
| linkup | Interfaccia up |
| authentication | SNMP auth failure |
| config | Config modificata |
| cpu | CPU sopra threshold |
| memory | Memory sopra threshold |
| bgp | BGP peer down/up |

---

## Parte 4: Configurazione SNMPv3 (Secure)

### SNMPv3 User e Group

```cisco
! Creare SNMP view (cosa può vedere)
FW-SNMP(config)# snmp-server view FULL-VIEW iso included

! Creare group con security level
FW-SNMP(config)# snmp-server group ADMIN-GROUP v3 priv read FULL-VIEW

! Creare SNMPv3 user
FW-SNMP(config)# snmp-server user snmpadmin ADMIN-GROUP v3 auth sha AuthPass123! priv aes 128 PrivPass123!
```

**Parametri SNMPv3:**
- **auth sha:** Authentication con SHA
- **priv aes 128:** Encryption AES 128-bit
- **AuthPass123!:** Password authentication
- **PrivPass123!:** Password encryption

### SNMPv3 Security Levels

| Level | Auth | Encryption | Sicurezza |
|-------|------|------------|-----------|
| noAuthNoPriv | ❌ | ❌ | Bassa (come v1) |
| authNoPriv | ✅ | ❌ | Media |
| authPriv | ✅ | ✅ | Alta (USARE QUESTO!) |

### Disable SNMPv1/v2c (Security Hardening)

```cisco
! Rimuovere community strings insicure
FW-SNMP(config)# no snmp-server community public
FW-SNMP(config)# no snmp-server community private

! Mantenere solo SNMPv3
! (comandi user sopra)
```

---

## Parte 5: Setup SNMP Manager (NMS)

### Configurazione SNMP-NMS Server

1. Aggiungere **Server** in LAN
2. Configurare networking:
   ```
   IP: 172.16.0.60
   Mask: 255.255.255.0
   Gateway: 172.16.0.1
   ```

3. **(Nota Packet Tracer: SNMP Manager limitato, simula con PC)**

In ambiente reale, NMS software:
- **Open Source:** Nagios, Zabbix, LibreNMS, Cacti
- **Commercial:** SolarWinds, PRTG, ManageEngine

---

## Parte 6: SNMP Queries (Monitoring)

### Query SNMP con snmpget

**Da PC-Admin (con SNMP tools installed):**

```bash
# System uptime
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 1.3.6.1.2.1.1.3.0

# System description
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 sysDescr.0

# Interface status (Gi0/0)
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 ifOperStatus.1

# CPU usage (1 minute average)
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 1.3.6.1.4.1.9.2.1.56.0
```

### Query SNMPv3 (Secure)

```bash
# Con autenticazione e encryption
snmpget -v3 \
  -l authPriv \
  -u snmpadmin \
  -a SHA -A AuthPass123! \
  -x AES -X PrivPass123! \
  172.16.0.1 sysUpTime.0
```

### Walk MIB (Get All Values)

```bash
# Walk entire system tree
snmpwalk -v2c -c MyS3cur3SNMP! 172.16.0.1 system

# Walk interfaces
snmpwalk -v2c -c MyS3cur3SNMP! 172.16.0.1 interfaces

# Walk IP routing table
snmpwalk -v2c -c MyS3cur3SNMP! 172.16.0.1 ipRouteTable
```

---

## Parte 7: Monitoring Metriche Critiche

### CPU Monitoring

**OID:** 1.3.6.1.4.1.9.2.1.56.0 (cpmCPUTotal5min)

```cisco
! Set CPU threshold trap
FW-SNMP(config)# process cpu threshold type total rising 75 interval 5

! Verificare CPU
FW-SNMP# show processes cpu
```

**SNMP Query:**
```bash
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 1.3.6.1.4.1.9.2.1.56.0
```

### Memory Monitoring

**OID:** 1.3.6.1.4.1.9.9.48.1.1.1.5.1 (ciscoMemoryPoolUsed)

```cisco
! Verificare memory
FW-SNMP# show memory statistics

! Abilitare memory trap
FW-SNMP(config)# snmp-server enable traps memory bufferpeak
```

**SNMP Query:**
```bash
# Memory used
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 1.3.6.1.4.1.9.9.48.1.1.1.5.1

# Memory free
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 1.3.6.1.4.1.9.9.48.1.1.1.6.1
```

### Interface Statistics

```cisco
! Vedere statistiche interfacce
FW-SNMP# show interfaces GigabitEthernet 0/0 | include packets
```

**SNMP Query Interface:**
```bash
# Interface operational status (1=up, 2=down)
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 ifOperStatus.1

# Bytes in (received)
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 ifInOctets.1

# Bytes out (transmitted)
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 ifOutOctets.1

# Errors
snmpget -v2c -c MyS3cur3SNMP! 172.16.0.1 ifInErrors.1
```

### Interface Index Mapping

```cisco
! Trovare interface index
FW-SNMP# show snmp mib ifmib ifindex

! Output esempio:
GigabitEthernet0/0: Ifindex = 1
GigabitEthernet0/1: Ifindex = 2
GigabitEthernet0/2: Ifindex = 3
```

---

## Parte 8: Test e Simulazione Eventi

### Test 1: Interface Down Trap

```cisco
! Simulare interface down
FW-SNMP(config)# interface GigabitEthernet 0/1
FW-SNMP(config-if)# shutdown
```

**SNMP Trap Inviato:**
```
Trap: linkDown
OID: 1.3.6.1.6.3.1.1.5.3
ifIndex: 2 (Gi0/1)
ifDescr: GigabitEthernet0/1
ifAdminStatus: down
```

**Ripristinare:**
```cisco
FW-SNMP(config-if)# no shutdown
FW-SNMP(config-if)# exit
```

### Test 2: Authentication Failure Trap

```bash
# Da PC-Admin, provare community errata
snmpget -v2c -c WRONG_COMMUNITY 172.16.0.1 sysUpTime.0
```

**SNMP Trap Inviato:**
```
Trap: authenticationFailure
Source: 172.16.0.10
Community: WRONG_COMMUNITY
```

### Test 3: Config Change Trap

```cisco
! Fare una modifica configurazione
FW-SNMP(config)# interface loopback 100
FW-SNMP(config-if)# ip address 10.100.100.1 255.255.255.255
FW-SNMP(config-if)# exit
```

**SNMP Trap Inviato:**
```
Trap: ccmCLIRunningConfigChanged
```

---

## Parte 9: Verifica Configurazione SNMP

### Show SNMP Configuration

```cisco
! Vedere config SNMP completa
FW-SNMP# show snmp

! Output include:
! - Community strings
! - Contact/Location
! - Trap configuration
! - Statistics

! Vedere SNMP communities
FW-SNMP# show snmp community

! Vedere SNMP users (v3)
FW-SNMP# show snmp user

! Vedere SNMP groups
FW-SNMP# show snmp group

! Vedere SNMP engineID
FW-SNMP# show snmp engineID
```

### SNMP Statistics

```cisco
! Vedere statistiche SNMP
FW-SNMP# show snmp stats

! Output:
! - Packets input: 125
! - Packets output: 130
! - Get-request: 50
! - Get-next: 30
! - Set-request: 5
! - Traps sent: 10
```

### Debugging SNMP (Troubleshooting)

```cisco
! Abilitare debug SNMP packets
FW-SNMP# debug snmp packets

! Fare query snmpget da NMS
! Vedere output debug

! Disabilitare debug
FW-SNMP# no debug snmp packets
FW-SNMP# undebug all
```

---

## Parte 10: ACL per SNMP Security

### Proteggere SNMP con ACL

```cisco
! ACL per limitare SNMP access
FW-SNMP(config)# access-list 20 remark SNMP-ALLOWED
FW-SNMP(config)# access-list 20 permit host 172.16.0.60
FW-SNMP(config)# access-list 20 deny any log

! Applicare a community
FW-SNMP(config)# snmp-server community MyS3cur3SNMP! RO 20

! Applicare a SNMPv3 group
FW-SNMP(config)# snmp-server group ADMIN-GROUP v3 priv read FULL-VIEW access 20
```

### Bloccare SNMP da Internet

```cisco
! ACL WAN in ingresso
FW-SNMP(config)# ip access-list extended INTERNET-IN

! Bloccare SNMP da Internet
FW-SNMP(config-ext-nacl)# remark === Block SNMP ===
FW-SNMP(config-ext-nacl)# deny udp any any eq 161 log
FW-SNMP(config-ext-nacl)# deny udp any any eq 162 log

! Rest of ACL...
FW-SNMP(config-ext-nacl)# permit ip any any

FW-SNMP(config-ext-nacl)# exit

FW-SNMP(config)# interface GigabitEthernet 0/0
FW-SNMP(config-if)# ip access-group INTERNET-IN in
```

---

## Parte 11: SNMP MIB Explorer (Teoria)

### Common OID Structure

```
System Group (1.3.6.1.2.1.1):
├─ sysDescr.0       (.1)  - System description
├─ sysObjectID.0    (.2)  - Vendor OID
├─ sysUpTime.0      (.3)  - Uptime (timeticks)
├─ sysContact.0     (.4)  - Contact person
├─ sysName.0        (.5)  - Hostname
└─ sysLocation.0    (.6)  - Location

Interfaces Group (1.3.6.1.2.1.2):
├─ ifNumber.0       (.1)  - Number of interfaces
└─ ifTable          (.2)
    ├─ ifIndex            - Interface index
    ├─ ifDescr            - Description
    ├─ ifType             - Type (ethernet, etc)
    ├─ ifMtu              - MTU
    ├─ ifSpeed            - Speed (bps)
    ├─ ifPhysAddress      - MAC address
    ├─ ifAdminStatus      - Admin status (up/down)
    ├─ ifOperStatus       - Operational status
    ├─ ifInOctets         - Bytes in
    ├─ ifOutOctets        - Bytes out
    ├─ ifInErrors         - Input errors
    └─ ifOutErrors        - Output errors

IP Group (1.3.6.1.2.1.4):
├─ ipForwarding      (.1)  - IP forwarding enabled
├─ ipInReceives      (.3)  - Total packets received
├─ ipRouteTable      (.21) - Routing table
└─ ipNetToMediaTable (.22) - ARP table

Cisco Private (1.3.6.1.4.1.9):
├─ ciscoMemoryPool   (.9.48) - Memory statistics
├─ cpmCPU            (.9.109) - CPU statistics
└─ ciscoEnvMonObjects (.9.13) - Environment (temp, fan)
```

### MIB Tools

**MIB Browser Software:**
- iReasoning MIB Browser (Free)
- ManageEngine MIB Browser
- Paessler MIB Importer

---

## Parte 12: Monitoring Dashboard (Teoria)

### Grafana + Telegraf (SNMP Collector)

**Architecture:**
```
[Router SNMP] ← Poll → [Telegraf SNMP Input]
                              ↓
                        [InfluxDB Time-Series DB]
                              ↓
                        [Grafana Dashboard]
```

**Example Telegraf Config:**
```toml
[[inputs.snmp]]
  agents = ["172.16.0.1:161"]
  version = 3
  sec_level = "authPriv"
  auth_protocol = "SHA"
  auth_password = "AuthPass123!"
  priv_protocol = "AES"
  priv_password = "PrivPass123!"
  sec_name = "snmpadmin"

  [[inputs.snmp.field]]
    name = "uptime"
    oid = "1.3.6.1.2.1.1.3.0"

  [[inputs.snmp.field]]
    name = "cpu_5min"
    oid = "1.3.6.1.4.1.9.2.1.56.0"

  [[inputs.snmp.table]]
    name = "interface"
    oid = "1.3.6.1.2.1.2.2"

    [[inputs.snmp.table.field]]
      name = "ifDescr"
      oid = "1.3.6.1.2.1.2.2.1.2"
```

---

## Parte 13: Best Practices

### 1. Use SNMPv3 Always ✅
```
✅ SNMPv3 con authPriv
❌ SNMPv1/v2c (plaintext community!)
```

### 2. Strong Community Strings (se v2c necessario)
```
✅ MyC0mpl3x!SNMP#2024
❌ public, private
```

### 3. ACL Restrictive ✅
```
✅ Permit solo NMS IP
❌ Permit any
```

### 4. Read-Only Preferenza ✅
```
✅ RO community per monitoring
❌ RW community (danger!)
```

### 5. Disable SNMP se Non Usato ✅
```
no snmp-server
```

### 6. Monitor SNMP Access ✅
```
✅ Log authentication failures
✅ Alert su anomalie
```

### 7. Secure NMS Server ✅
```
✅ NMS in LAN (non DMZ!)
✅ Firewall davanti a NMS
✅ Strong credentials
```

---

## Parte 14: Troubleshooting

### Problema 1: SNMP Query Timeout

**Sintomi:**
```bash
snmpget: Timeout
```

**Checklist:**
1. ✅ Ping al dispositivo?
2. ✅ SNMP abilitato? (`show snmp`)
3. ✅ Community corretta?
4. ✅ Firewall permette UDP 161?
5. ✅ ACL SNMP permette source IP?

**Test:**
```cisco
! Abilitare debug
FW-SNMP# debug snmp packets

! Fare query
! Vedere se pacchetto arriva
```

### Problema 2: Access Denied

**Sintomi:**
```
authorizationError
```

**Causa:** Community o ACL incorretti

**Soluzione:**
```cisco
! Verificare community
FW-SNMP# show snmp community

! Verificare ACL
FW-SNMP# show access-lists 20

! Verificare IP source permesso
FW-SNMP(config)# access-list 20 permit host 172.16.0.60
```

### Problema 3: Traps Non Arrivano

**Checklist:**
1. ✅ Trap abilitati? (`show snmp`)
2. ✅ Trap host configurato?
3. ✅ Firewall permette UDP 162 out?
4. ✅ NMS in ascolto su porta 162?

**Verifica:**
```cisco
! Vedere trap configuration
FW-SNMP# show snmp host

! Test: simulare trap
FW-SNMP(config-if)# shutdown
FW-SNMP(config-if)# no shutdown
```

---

## Conclusioni

🎉 **Hai completato:**
- ✅ SNMP agent configuration
- ✅ SNMPv2c e SNMPv3 setup
- ✅ Community strings e ACL security
- ✅ SNMP traps configuration
- ✅ Monitoring CPU, memory, interfaces
- ✅ SNMP queries e MIB exploration
- ✅ Best practices SNMPv3

### Riepilogo SNMP Versions

| Version | Auth | Encryption | Use Case |
|---------|------|------------|----------|
| v1 | ❌ | ❌ | Legacy only |
| v2c | ❌ | ❌ | Lab/interno |
| v3 | ✅ | ✅ | **PRODUZIONE** |

### Key Takeaways
- **SNMPv3:** SEMPRE usare in produzione
- **Read-Only:** Usare RO, non RW
- **ACL:** Limitare access a NMS only
- **Traps:** Alert proattivi su eventi critici
- **MIB:** Struttura gerarchica oggetti monitorabili
- **UDP 161:** Query (manager → agent)
- **UDP 162:** Traps (agent → manager)

### SNMP vs Syslog

| Feature | SNMP | Syslog |
|---------|------|--------|
| Type | Pull + Push (traps) | Push only |
| Port | UDP 161/162 | UDP 514 |
| Data | Structured (MIB) | Unstructured text |
| Query | Yes (GET) | No |
| Real-time | Polling interval | Immediate |
| Use Case | Performance metrics | Log events |

**Best Practice:** Usare **entrambi**!
- **SNMP:** CPU, memory, throughput
- **Syslog:** ACL deny, login, config changes

### Prossimi Passi
- **LAB Avanzato:** NetFlow per traffic analysis
- **LAB Avanzato:** SNMP + Grafana dashboard
- **LAB Avanzato:** Automated alerting

---

**Salvare:** File → Save As → `lab4.2-snmp-monitoring.pkt`

**Fine Laboratorio 4.2**
