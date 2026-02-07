# LAB 4.1 - Monitoring DMZ con Syslog

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**File da creare:** `lab4.1-syslog-monitoring.pkt`  
**Prerequisiti:** LAB 1.1, LAB 2.1

---

## Obiettivi del Laboratorio
- Configurare Syslog server centralizzato
- Abilitare logging su router/firewall
- Configurare livelli di severity appropriati
- Analizzare log per security events
- Implementare log rotation e retention
- Correlare eventi da dispositivi multipli

---

## Syslog: Fondamenti

### Cos'è Syslog?

**Syslog** = Standard protocol per logging e message transmission
- **RFC 5424** - Standard protocol
- **UDP port 514** (default), TCP 514 (reliable)
- **Centralizzato:** Tutti i dispositivi → 1 server

### Syslog Severity Levels

| Level | Nome | Descrizione | Esempio |
|-------|------|-------------|---------|
| 0 | Emergency | System unusable | Router crash |
| 1 | Alert | Immediate action needed | Memory critical |
| 2 | Critical | Critical condition | Interface down |
| 3 | Error | Error condition | ACL deny |
| 4 | Warning | Warning condition | High CPU |
| 5 | Notice | Normal but significant | Line protocol up |
| 6 | Informational | Informational | Config changed |
| 7 | Debug | Debug messages | Packet details |

**Best Practice:** Log level 4-6 per produzione (non Debug!)

---

## Topologia

```
                        [Router/Firewall]
                       /        |        \
                  G0/0 (WAN) G0/1 (DMZ) G0/2 (LAN)
                     |           |            |
              [Internet]    [Switch-DMZ]  [Switch-LAN]
              198.51.100.1       |              |
                            10.0.1.10      172.16.0.50
                            10.0.1.20         |
                                |             |
                          [Web-Server]   [Syslog-Srv]  172.16.0.50
                          [Mail-Server]  [PC-Admin]    172.16.0.10
                                         [PC-User1]    172.16.0.11
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
| Syslog-Srv | 172.16.0.50 | /24 | Log Server |
| PC-Admin | 172.16.0.10 | /24 | Admin |
| PC-User1 | 172.16.0.11 | /24 | User |

### Configurazione Router Base

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-SYSLOG
FW-SYSLOG(config)#

! Interfacce
FW-SYSLOG(config)# interface GigabitEthernet 0/0
FW-SYSLOG(config-if)# description WAN
FW-SYSLOG(config-if)# ip address 198.51.100.254 255.255.255.0
FW-SYSLOG(config-if)# no shutdown
FW-SYSLOG(config-if)# exit

FW-SYSLOG(config)# interface GigabitEthernet 0/1
FW-SYSLOG(config-if)# description DMZ
FW-SYSLOG(config-if)# ip address 10.0.1.1 255.255.255.0
FW-SYSLOG(config-if)# no shutdown
FW-SYSLOG(config-if)# exit

FW-SYSLOG(config)# interface GigabitEthernet 0/2
FW-SYSLOG(config-if)# description LAN
FW-SYSLOG(config-if)# ip address 172.16.0.1 255.255.255.0
FW-SYSLOG(config-if)# no shutdown
FW-SYSLOG(config-if)# exit

! Routing
FW-SYSLOG(config)# ip route 0.0.0.0 0.0.0.0 198.51.100.1
```

---

## Parte 2: Configurazione Syslog Server

### Setup Syslog Server (Packet Tracer)

1. Aggiungere **Server** in LAN
2. Configurare networking:
   ```
   IP: 172.16.0.50
   Mask: 255.255.255.0
   Gateway: 172.16.0.1
   ```

3. Cliccare **Services** → **Syslog**
4. Abilitare **Syslog Service: ON**

**Syslog Server ora in ascolto su UDP 514!**

---

## Parte 3: Configurazione Logging su Router

### Enable Syslog Logging

```cisco
! Abilitare logging
FW-SYSLOG(config)# logging on

! Configurare Syslog server
FW-SYSLOG(config)# logging host 172.16.0.50

! Configurare trap level (severity)
FW-SYSLOG(config)# logging trap informational
! (informational = level 6, invia da 0 a 6)

! Configurare facility (opzionale)
FW-SYSLOG(config)# logging facility local0

! Source interface per pacchetti syslog
FW-SYSLOG(config)# logging source-interface GigabitEthernet 0/2
```

### Enable Buffer Logging (Local)

```cisco
! Buffer locale (backup se syslog server down)
FW-SYSLOG(config)# logging buffered 100000 informational
! (100000 bytes, level 6)

! Disabilitare console logging (troppo verbose!)
FW-SYSLOG(config)# no logging console

! Abilitare timestamps
FW-SYSLOG(config)# service timestamps log datetime msec
FW-SYSLOG(config)# service timestamps debug datetime msec
```

### Configure Logging Details

```cisco
! Includere sequence numbers nei log
FW-SYSLOG(config)# service sequence-numbers

! Log di configurazione changes
FW-SYSLOG(config)# archive
FW-SYSLOG(config-archive)# log config
FW-SYSLOG(config-archive-log-cfg)# logging enable
FW-SYSLOG(config-archive-log-cfg)# logging size 500
FW-SYSLOG(config-archive-log-cfg)# notify syslog
FW-SYSLOG(config-archive-log-cfg)# exit
FW-SYSLOG(config-archive)# exit
```

---

## Parte 4: Log ACL Events

### ACL con Logging

```cisco
! ACL per Internet → DMZ con logging
FW-SYSLOG(config)# ip access-list extended INTERNET-TO-DMZ

! Permettere servizi con log
FW-SYSLOG(config-ext-nacl)# remark === Web Server ===
FW-SYSLOG(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80
FW-SYSLOG(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! Log accessi mail
FW-SYSLOG(config-ext-nacl)# remark === Mail Server ===
FW-SYSLOG(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25 log
FW-SYSLOG(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 587 log

! Return traffic
FW-SYSLOG(config-ext-nacl)# permit tcp any any established

! BLOCCARE e LOGGARE tentativi sospetti
FW-SYSLOG(config-ext-nacl)# remark === Security Logging ===
FW-SYSLOG(config-ext-nacl)# deny tcp any any eq 23 log
! (Telnet blocked)
FW-SYSLOG(config-ext-nacl)# deny tcp any any range 135 139 log
! (NetBIOS blocked)
FW-SYSLOG(config-ext-nacl)# deny tcp any any eq 445 log
! (SMB blocked)

! Default deny con log
FW-SYSLOG(config-ext-nacl)# deny ip any any log

FW-SYSLOG(config-ext-nacl)# exit

! Applicare ACL
FW-SYSLOG(config)# interface GigabitEthernet 0/0
FW-SYSLOG(config-if)# ip access-group INTERNET-TO-DMZ in
FW-SYSLOG(config-if)# exit
```

### Rate Limiting Log (Evitare Flood)

```cisco
! Limitare log rate per evitare flooding
FW-SYSLOG(config)# logging rate-limit 10
! (Max 10 messaggi/secondo a syslog)

! Per ACL specifiche
FW-SYSLOG(config)# ip access-list log-update threshold 100
! (Log ACL ogni 100 match, non ogni singolo)
```

---

## Parte 5: Log Authentication Events

### Enable AAA Logging (Authentication)

```cisco
! Abilitare AAA
FW-SYSLOG(config)# aaa new-model

! Log authentication attempts
FW-SYSLOG(config)# aaa authentication login default local
FW-SYSLOG(config)# aaa authentication enable default enable

! Creare utente admin
FW-SYSLOG(config)# username admin privilege 15 secret Admin123!

! Enable login logging
FW-SYSLOG(config)# login on-failure log
FW-SYSLOG(config)# login on-success log
```

### SSH Configuration con Logging

```cisco
! Generare chiavi RSA
FW-SYSLOG(config)# crypto key generate rsa modulus 2048

! Configurare SSH
FW-SYSLOG(config)# ip ssh version 2
FW-SYSLOG(config)# ip ssh time-out 60
FW-SYSLOG(config)# ip ssh authentication-retries 3

! VTY lines con logging
FW-SYSLOG(config)# line vty 0 4
FW-SYSLOG(config-line)# transport input ssh
FW-SYSLOG(config-line)# login local
FW-SYSLOG(config-line)# logging synchronous
FW-SYSLOG(config-line)# exit
```

---

## Parte 6: Log Interface Status Changes

### Enable Interface Logging

```cisco
! Log link up/down events
FW-SYSLOG(config)# interface GigabitEthernet 0/0
FW-SYSLOG(config-if)# logging event link-status
FW-SYSLOG(config-if)# exit

FW-SYSLOG(config)# interface GigabitEthernet 0/1
FW-SYSLOG(config-if)# logging event link-status
FW-SYSLOG(config-if)# exit

FW-SYSLOG(config)# interface GigabitEthernet 0/2
FW-SYSLOG(config-if)# logging event link-status
FW-SYSLOG(config-if)# exit
```

---

## Parte 7: Test e Verifica

### Test 1: Generare Eventi Log

**Generare vari eventi per popolare syslog:**

```cisco
! 1. Config change
FW-SYSLOG(config)# interface loopback 99
FW-SYSLOG(config-if)# ip address 1.1.1.1 255.255.255.255
FW-SYSLOG(config-if)# exit

! 2. SSH login fallito
! Da PC-Admin provare SSH con password errata

! 3. ACL deny log
! Da Internet provare Telnet a DMZ (bloccato)

! 4. Interface down
FW-SYSLOG(config)# interface loopback 99
FW-SYSLOG(config-if)# shutdown
```

### Visualizzare Log su Syslog Server

1. Cliccare **Syslog-Srv** → **Services** → **Syslog**
2. Vedere messaggi in arrivo

**Esempio messaggi:**
```
%SYS-5-CONFIG_I: Configured from console by admin
%LINK-5-CHANGED: Interface Loopback99, changed state to down
%SEC_LOGIN-4-LOGIN_FAILED: Login failed from 172.16.0.10
%SEC-6-IPACCESSLOGDP: list INTERNET-TO-DMZ denied tcp ...
```

### Test 2: Correlazione Multi-Device

**Scenario:** Attacco port scan

1. Da Internet, provare connessioni a porte varie:
   ```
   telnet 198.51.100.254 23
   telnet 198.51.100.254 135
   telnet 198.51.100.254 445
   ```

2. Verificare log su Syslog server

**Log atteso:**
```
[timestamp] FW-SYSLOG: %SEC-6-IPACCESSLOGDP: list INTERNET-TO-DMZ denied tcp 198.51.100.1(1234) -> 10.0.1.10(23)
[timestamp] FW-SYSLOG: %SEC-6-IPACCESSLOGDP: list INTERNET-TO-DMZ denied tcp 198.51.100.1(1235) -> 10.0.1.10(135)
[timestamp] FW-SYSLOG: %SEC-6-IPACCESSLOGDP: list INTERNET-TO-DMZ denied tcp 198.51.100.1(1236) -> 10.0.1.10(445)
```

✅ **Security Insight:** Multiple deny da stesso IP = Port scan attack!

---

## Parte 8: Verifica Configurazione

### Show Commands

```cisco
! Vedere configurazione logging
FW-SYSLOG# show logging

! Output esempio:
Syslog logging: enabled (0 messages dropped, 3 messages rate-limited)
    Console logging: disabled
    Monitor logging: level debugging, 0 messages logged
    Buffer logging:  level informational, 150 messages logged
    Logging to: 172.16.0.50 (UDP port 514, audit disabled)
          0 message lines logged

Trap logging: level informational, 245 message lines logged
    Logging Source-Interface:       GigabitEthernet0/2
```

### Verificare Connettività Syslog

```cisco
! Test reach syslog server
FW-SYSLOG# ping 172.16.0.50

! Test UDP 514 (telnet not work for UDP!)
! Generare evento per verificare log arriva
FW-SYSLOG# reload in 10
! (poi cancel con: reload cancel)
```

### Debug Syslog (Troubleshooting)

```cisco
! Vedere pacchetti syslog inviati
FW-SYSLOG# debug logging

! ATTENZIONE: Può causare loop! Usare con cautela
! Disabilitare dopo test:
FW-SYSLOG# no debug logging
FW-SYSLOG# undebug all
```

---

## Parte 9: Analisi Log e Pattern Recognition

### Security Events da Monitorare

#### 1. Failed Login Attempts
```
%SEC_LOGIN-4-LOGIN_FAILED: Login failed
```
**Action:** Dopo 3 tentativi da stesso IP → bloccare IP

#### 2. ACL Deny Patterns
```
%SEC-6-IPACCESSLOGDP: list XYZ denied tcp ...
```
**Pattern:** Multiple deny da stesso IP = Scan/Attack

#### 3. Interface Flapping
```
%LINK-3-UPDOWN: Interface Gi0/0, changed state to down
%LINK-3-UPDOWN: Interface Gi0/0, changed state to up
```
**Pattern:** Up/down rapidi = Cavo problema o DoS

#### 4. Configuration Changes
```
%SYS-5-CONFIG_I: Configured from console by user
```
**Action:** Audit chi ha fatto modifiche

#### 5. High CPU/Memory
```
%SYS-2-MALLOCFAIL: Memory allocation failure
```
**Action:** Possibile memory exhaustion attack

### Log Correlation Examples

**Scenario Attack:**
```
10:15:01 - Multiple ACL deny da 203.0.113.50 (port scan)
10:15:30 - Failed login da 203.0.113.50 (brute force)
10:16:00 - High CPU alert (resource exhaustion)
```

**Correla eventi → Attacco coordinato!**

---

## Parte 10: Syslog Advanced Configuration

### Logging per Diverse Facility

```cisco
! Usare facility diverse per categorizzare
FW-SYSLOG(config)# logging host 172.16.0.50
FW-SYSLOG(config)# logging facility local0

! Altro firewall potrebbe usare local1
! Switch potrebbe usare local2
! Etc. per separare log per tipo dispositivo
```

### Logging con TCP (Reliable)

```cisco
! TCP invece di UDP (no packet loss)
FW-SYSLOG(config)# logging host 172.16.0.50 transport tcp port 514
```

**Pro:** No log persi
**Contro:** Overhead, possibile blocking se server down

### Multiple Syslog Servers

```cisco
! Redundancy - 2 syslog server
FW-SYSLOG(config)# logging host 172.16.0.50
FW-SYSLOG(config)# logging host 172.16.0.51
```

---

## Parte 11: Log Retention e Rotation

### Buffer Size Configuration

```cisco
! Aumentare buffer locale
FW-SYSLOG(config)# logging buffered 500000
! (500KB invece di 100KB default)

! Clear old logs
FW-SYSLOG# clear logging
```

### Syslog Server Storage (Teoria)

In ambiente reale (Linux syslog-ng):
```bash
# /etc/syslog-ng/syslog-ng.conf
destination d_network {
    file("/var/log/network/$YEAR-$MONTH-$DAY/$HOST.log"
         create_dirs(yes)
         owner(root)
         group(root)
         perm(0640));
};

# Rotation (logrotate)
/var/log/network/*/*.log {
    daily
    rotate 90
    compress
    delaycompress
    notifempty
}
```

**Retention Policy:**
- Daily logs → 90 giorni
- Compressed after 1 day
- Archived logs → 1 anno

---

## Parte 12: Best Practices

### 1. Set Appropriate Severity ✅
```
Production: informational (6)
Troubleshooting: debugging (7) - temporaneo!
```

### 2. Use ACL Logging Strategically ✅
```
✅ Log: deny rules, security events
❌ Non log: permit rules comuni (troppo verbose!)
```

### 3. Secure Syslog Server ✅
```
✅ Syslog server in LAN (non DMZ!)
✅ Firewall permette solo 514/udp da dispositivi autorizzati
✅ Storage encryption
✅ Access control (solo admin)
```

### 4. Time Synchronization ✅
```
! NTP per timestamp corretti
FW-SYSLOG(config)# ntp server 132.163.96.1
FW-SYSLOG(config)# clock timezone CET 1
```

### 5. Regular Log Review ✅
```
✅ Daily: Review critical/alert
✅ Weekly: Analyze patterns
✅ Monthly: Audit compliance
```

### 6. Alerting e SIEM Integration
```
Syslog → SIEM (Splunk, ELK) → Alert automatici
```

---

## Parte 13: Troubleshooting

### Problema 1: Log Non Arrivano al Server

**Checklist:**
```cisco
! 1. Verificare logging abilitato
FW-SYSLOG# show logging | include enabled

! 2. Ping syslog server
FW-SYSLOG# ping 172.16.0.50

! 3. Verificare firewall permette 514/udp
FW-SYSLOG# show ip access-lists

! 4. Controllare syslog service attivo su server
! (Services → Syslog → ON)

! 5. Verificare trap level
FW-SYSLOG# show logging | include Trap
! Trap logging: level informational
```

### Problema 2: Troppi Log (Flooding)

**Causa:** Debug abilitato o ACL troppo verbose

**Soluzione:**
```cisco
! Disabilitare debug
FW-SYSLOG# no debug all

! Abbassare trap level
FW-SYSLOG(config)# logging trap warnings
! (Solo warning e + grave)

! Rate limiting
FW-SYSLOG(config)# logging rate-limit 10
```

### Problema 3: Timestamp Errati

**Causa:** Clock non sincronizzato

**Soluzione:**
```cisco
! Set manual clock
FW-SYSLOG# clock set 14:30:00 25 March 2024

! O configurare NTP
FW-SYSLOG(config)# ntp server 132.163.96.1
```

---

## Conclusioni

🎉 **Hai completato:**
- ✅ Syslog server centralizzato
- ✅ Logging configurato su router/firewall
- ✅ ACL logging per security events
- ✅ Authentication logging
- ✅ Interface status logging
- ✅ Log analysis e pattern recognition
- ✅ Best practices logging

### Riepilogo Severity Levels

| Level | When to Use |
|-------|-------------|
| 0-1 | System failures |
| 2-3 | Errors, ACL deny |
| 4-5 | Warnings, interface changes |
| 6 | Info, config changes |
| 7 | Debug (solo troubleshooting!) |

### Key Takeaways
- **Centralizzazione:** Tutti log in 1 posto
- **Correlation:** Eventi multipli = Attack pattern
- **Retention:** Log storici per forensics
- **Time Sync:** NTP essential per correlation
- **Security:** Syslog server in LAN, non DMZ

### Logging Workflow
```
1. Event accade (ACL deny, login fail, etc.)
2. Router genera log message
3. Inviato a syslog server (UDP 514)
4. Syslog server archivia
5. Admin analizza periodicamente
6. SIEM genera alert se pattern sospetto
```

### Prossimi Passi
- **LAB 4.2:** SNMP monitoring
- **LAB Avanzato:** SIEM integration (Splunk/ELK)
- **LAB Avanzato:** NetFlow per traffic analysis

---

**Salvare:** File → Save As → `lab4.1-syslog-monitoring.pkt`

**Fine Laboratorio 4.1**
