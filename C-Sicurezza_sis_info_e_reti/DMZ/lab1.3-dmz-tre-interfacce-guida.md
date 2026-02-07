# LAB 1.3 - DMZ a Tre Interfacce

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2.5 ore  
**File da creare:** `lab1.3-dmz-tre-interfacce.pkt`  
**Prerequisiti:** LAB 1.1, LAB 1.2

---

## Obiettivi del Laboratorio
- Configurare firewall con tre interfacce (Outside, DMZ, Inside)
- Implementare security levels (concetto ASA)
- Comprendere il traffico inter-zone
- Ottimizzare il routing tra le zone
- Implementare policy granulari per ogni interfaccia

---

## Topologia da Implementare

```
                    [ASA/Router Firewall]
                   /        |         \
              Outside      DMZ       Inside
           (Security=0) (Security=50) (Security=100)
                /          |            \
               |           |             |
           Internet   [Switch-DMZ]   [Switch-LAN]
        (192.0.2.2)    |        |         |
                   10.0.1.10  10.0.1.20   |
                       |        |      172.16.0.10-12
                  [Web-Srv] [Mail-Srv]    |
                                      [PC-1][PC-2][PC-3]
```

---

## Concetto: Security Levels

In architetture con tre interfacce, ogni zona ha un **security level**:

| Interfaccia | Security Level | Descrizione |
|-------------|----------------|-------------|
| **Outside** | 0 | Internet (non fidato) |
| **DMZ** | 50 | Server pubblici (media fiducia) |
| **Inside** | 100 | LAN interna (alta fiducia) |

**Regole di Default:**
- Traffico da **higher → lower** security: PERMESSO (Inside → DMZ → Outside)
- Traffico da **lower → higher** security: BLOCCATO (Outside → DMZ → Inside)
- Traffico da **equal → equal** security: BLOCCATO (DMZ ↔ DMZ)

---

## Parte 1: Creazione Topologia

### Step 1.1 - Dispositivi Necessari

**Router:**
- 1x Router 2911 o ISR 4321 (Firewall centrale)

**Switch:**
- 2x Switch 2960 (Switch-DMZ, Switch-LAN)

**Server DMZ:**
- 1x Server-PT (Web-Server)
- 1x Server-PT (Mail-Server)

**PC LAN:**
- 3x PC-PT (PC-1, PC-2, PC-3)

**Internet:**
- 1x Cloud-PT (Internet)

### Step 1.2 - Collegamenti

1. **Internet Fa0** → **Firewall G0/0** (Outside)
2. **Firewall G0/1** → **Switch-DMZ Fa0/1** (DMZ)
3. **Firewall G0/2** → **Switch-LAN Fa0/1** (Inside)
4. **Switch-DMZ Fa0/2** → **Web-Server Fa0**
5. **Switch-DMZ Fa0/3** → **Mail-Server Fa0**
6. **Switch-LAN Fa0/2-4** → **PC-1, PC-2, PC-3**

---

## Parte 2: Piano di Indirizzamento

### Tabella IP Completa

| Dispositivo | Interfaccia | IP | Mask | Gateway | Security Level |
|-------------|-------------|----|----|---------|----------------|
| **Firewall** | G0/0 (Outside) | 192.0.2.1 | /30 | - | 0 |
| **Firewall** | G0/1 (DMZ) | 10.0.1.1 | /24 | - | 50 |
| **Firewall** | G0/2 (Inside) | 172.16.0.1 | /24 | - | 100 |
| **Internet** | Fa0 | 192.0.2.2 | /30 | - | - |
| **Web-Srv** | Fa0 | 10.0.1.10 | /24 | 10.0.1.1 | - |
| **Mail-Srv** | Fa0 | 10.0.1.20 | /24 | 10.0.1.1 | - |
| **PC-1** | Fa0 | 172.16.0.10 | /24 | 172.16.0.1 | - |
| **PC-2** | Fa0 | 172.16.0.11 | /24 | 172.16.0.1 | - |
| **PC-3** | Fa0 | 172.16.0.12 | /24 | 172.16.0.1 | - |

---

## Parte 3: Configurazione Firewall (Router con Zone-Based Policy)

### Step 3.1 - Configurazione Base Interfacce

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-3ZONE
FW-3ZONE(config)#

! Banner di sicurezza
FW-3ZONE(config)# banner motd #
*****************************************************
*  Three-Zone Firewall - Unauthorized Access Denied *
*****************************************************
#

! Interfaccia OUTSIDE (Internet) - Security Level 0
FW-3ZONE(config)# interface GigabitEthernet 0/0
FW-3ZONE(config-if)# description *** OUTSIDE - Internet (Security=0) ***
FW-3ZONE(config-if)# ip address 192.0.2.1 255.255.255.252
FW-3ZONE(config-if)# no shutdown
FW-3ZONE(config-if)# exit

! Interfaccia DMZ - Security Level 50
FW-3ZONE(config)# interface GigabitEthernet 0/1
FW-3ZONE(config-if)# description *** DMZ Zone (Security=50) ***
FW-3ZONE(config-if)# ip address 10.0.1.1 255.255.255.0
FW-3ZONE(config-if)# no shutdown
FW-3ZONE(config-if)# exit

! Interfaccia INSIDE (LAN) - Security Level 100
FW-3ZONE(config)# interface GigabitEthernet 0/2
FW-3ZONE(config-if)# description *** INSIDE - Trusted LAN (Security=100) ***
FW-3ZONE(config-if)# ip address 172.16.0.1 255.255.255.0
FW-3ZONE(config-if)# no shutdown
FW-3ZONE(config-if)# exit
```

### Step 3.2 - Configurazione Routing

```cisco
! Default route verso Internet
FW-3ZONE(config)# ip route 0.0.0.0 0.0.0.0 192.0.2.2

! Verifica routing
FW-3ZONE# show ip route
```

---

## Parte 4: Zone-Based Policy Firewall (ZBPF)

### Step 4.1 - Definizione Security Zones

```cisco
FW-3ZONE# configure terminal

! Definire le tre zone di sicurezza
FW-3ZONE(config)# zone security OUTSIDE
FW-3ZONE(config-sec-zone)# description Internet - Untrusted
FW-3ZONE(config-sec-zone)# exit

FW-3ZONE(config)# zone security DMZ
FW-3ZONE(config-sec-zone)# description Public Servers - Medium Trust
FW-3ZONE(config-sec-zone)# exit

FW-3ZONE(config)# zone security INSIDE
FW-3ZONE(config-sec-zone)# description Internal LAN - Trusted
FW-3ZONE(config-sec-zone)# exit
```

### Step 4.2 - Assegnare Interfacce alle Zone

```cisco
! Assegnare G0/0 alla zona OUTSIDE
FW-3ZONE(config)# interface GigabitEthernet 0/0
FW-3ZONE(config-if)# zone-member security OUTSIDE
FW-3ZONE(config-if)# exit

! Assegnare G0/1 alla zona DMZ
FW-3ZONE(config)# interface GigabitEthernet 0/1
FW-3ZONE(config-if)# zone-member security DMZ
FW-3ZONE(config-if)# exit

! Assegnare G0/2 alla zona INSIDE
FW-3ZONE(config)# interface GigabitEthernet 0/2
FW-3ZONE(config-if)# zone-member security INSIDE
FW-3ZONE(config-if)# exit
```

### Step 4.3 - Creare Class-Maps (Classificazione Traffico)

```cisco
! Class-map per traffico HTTP/HTTPS
FW-3ZONE(config)# class-map type inspect match-any WEB-TRAFFIC
FW-3ZONE(config-cmap)# match protocol http
FW-3ZONE(config-cmap)# match protocol https
FW-3ZONE(config-cmap)# exit

! Class-map per traffico email
FW-3ZONE(config)# class-map type inspect match-any MAIL-TRAFFIC
FW-3ZONE(config-cmap)# match protocol smtp
FW-3ZONE(config-cmap)# match protocol pop3
FW-3ZONE(config-cmap)# match protocol imap
FW-3ZONE(config-cmap)# exit

! Class-map per DNS
FW-3ZONE(config)# class-map type inspect match-any DNS-TRAFFIC
FW-3ZONE(config-cmap)# match protocol dns
FW-3ZONE(config-cmap)# exit

! Class-map per ICMP
FW-3ZONE(config)# class-map type inspect match-any ICMP-TRAFFIC
FW-3ZONE(config-cmap)# match protocol icmp
FW-3ZONE(config-cmap)# exit

! Class-map per tutto il resto
FW-3ZONE(config)# class-map type inspect match-any ALL-TRAFFIC
FW-3ZONE(config-cmap)# match protocol tcp
FW-3ZONE(config-cmap)# match protocol udp
FW-3ZONE(config-cmap)# match protocol icmp
FW-3ZONE(config-cmap)# exit
```

### Step 4.4 - Creare Policy-Maps (Azioni)

#### Policy 1: INSIDE → DMZ (Permetti tutto con inspection)

```cisco
FW-3ZONE(config)# policy-map type inspect INSIDE-TO-DMZ-POLICY
FW-3ZONE(config-pmap)# class type inspect ALL-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# exit
```

#### Policy 2: INSIDE → OUTSIDE (Permetti tutto)

```cisco
FW-3ZONE(config)# policy-map type inspect INSIDE-TO-OUTSIDE-POLICY
FW-3ZONE(config-pmap)# class type inspect ALL-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# exit
```

#### Policy 3: OUTSIDE → DMZ (Solo servizi pubblici)

```cisco
FW-3ZONE(config)# policy-map type inspect OUTSIDE-TO-DMZ-POLICY
FW-3ZONE(config-pmap)# class type inspect WEB-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# class type inspect MAIL-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# class class-default
FW-3ZONE(config-pmap-c)# drop log
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# exit
```

#### Policy 4: DMZ → OUTSIDE (Permetti limitato)

```cisco
FW-3ZONE(config)# policy-map type inspect DMZ-TO-OUTSIDE-POLICY
FW-3ZONE(config-pmap)# class type inspect DNS-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# class type inspect WEB-TRAFFIC
FW-3ZONE(config-pmap-c)# inspect
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# class class-default
FW-3ZONE(config-pmap-c)# drop log
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# exit
```

### Step 4.5 - Creare Zone-Pairs e Applicare Policy

```cisco
! Zone-pair: INSIDE → DMZ
FW-3ZONE(config)# zone-pair security INSIDE-DMZ source INSIDE destination DMZ
FW-3ZONE(config-sec-zone-pair)# service-policy type inspect INSIDE-TO-DMZ-POLICY
FW-3ZONE(config-sec-zone-pair)# exit

! Zone-pair: INSIDE → OUTSIDE
FW-3ZONE(config)# zone-pair security INSIDE-OUTSIDE source INSIDE destination OUTSIDE
FW-3ZONE(config-sec-zone-pair)# service-policy type inspect INSIDE-TO-OUTSIDE-POLICY
FW-3ZONE(config-sec-zone-pair)# exit

! Zone-pair: OUTSIDE → DMZ
FW-3ZONE(config)# zone-pair security OUTSIDE-DMZ source OUTSIDE destination DMZ
FW-3ZONE(config-sec-zone-pair)# service-policy type inspect OUTSIDE-TO-DMZ-POLICY
FW-3ZONE(config-sec-zone-pair)# exit

! Zone-pair: DMZ → OUTSIDE
FW-3ZONE(config)# zone-pair security DMZ-OUTSIDE source DMZ destination OUTSIDE
FW-3ZONE(config-sec-zone-pair)# service-policy type inspect DMZ-TO-OUTSIDE-POLICY
FW-3ZONE(config-sec-zone-pair)# exit

! Nota: NON creiamo zone-pair OUTSIDE → INSIDE (bloccato di default)
!       NON creiamo zone-pair DMZ → INSIDE (contenimento DMZ)
```

---

## Parte 5: Configurazione NAT

### Step 5.1 - NAT per LAN (Inside Source NAT)

```cisco
! Definire inside/outside
FW-3ZONE(config)# interface GigabitEthernet 0/0
FW-3ZONE(config-if)# ip nat outside
FW-3ZONE(config-if)# exit

FW-3ZONE(config)# interface GigabitEthernet 0/1
FW-3ZONE(config-if)# ip nat inside
FW-3ZONE(config-if)# exit

FW-3ZONE(config)# interface GigabitEthernet 0/2
FW-3ZONE(config-if)# ip nat inside
FW-3ZONE(config-if)# exit

! ACL per identificare traffico LAN
FW-3ZONE(config)# access-list 1 permit 172.16.0.0 0.0.0.255

! NAT overload per LAN
FW-3ZONE(config)# ip nat inside source list 1 interface GigabitEthernet 0/0 overload
```

### Step 5.2 - Static NAT per Server DMZ

```cisco
! Web Server - port forwarding HTTP
FW-3ZONE(config)# ip nat inside source static tcp 10.0.1.10 80 interface GigabitEthernet 0/0 80

! Web Server - port forwarding HTTPS
FW-3ZONE(config)# ip nat inside source static tcp 10.0.1.10 443 interface GigabitEthernet 0/0 443

! Mail Server - port forwarding SMTP
FW-3ZONE(config)# ip nat inside source static tcp 10.0.1.20 25 interface GigabitEthernet 0/0 25
```

---

## Parte 6: Configurazione Server DMZ

### Step 6.1 - Web Server (10.0.1.10)

**IP Configuration:**
- IP: `10.0.1.10`
- Mask: `255.255.255.0`
- Gateway: `10.0.1.1`
- DNS: `8.8.8.8`

**Services:**
- HTTP: ON
- HTTPS: ON

**Pagina index.html:**
```html
<html>
<head><title>Three-Zone DMZ Web Server</title></head>
<body style="font-family: Arial; margin: 40px;">
<h1>🔒 Three-Zone Firewall Architecture</h1>
<h2>Web Server in DMZ</h2>
<p><strong>IP Address:</strong> 10.0.1.10</p>
<p><strong>Security Level:</strong> 50 (Medium Trust)</p>
<p><strong>Protected by:</strong> Zone-Based Policy Firewall</p>
<hr>
<p>✅ This server can be accessed from Internet and LAN</p>
<p>❌ This server CANNOT access Internal LAN</p>
</body>
</html>
```

### Step 6.2 - Mail Server (10.0.1.20)

**IP Configuration:**
- IP: `10.0.1.20`
- Mask: `255.255.255.0`
- Gateway: `10.0.1.1`
- DNS: `8.8.8.8`

**Services:**
- SMTP: ON (port 25)
- POP3: ON (port 110)
- IMAP: ON (port 143)

**Create Email Users:**
- User: `admin@dmz.local` / Password: `Admin123!`
- User: `user1@dmz.local` / Password: `User123!`

---

## Parte 7: Configurazione PC LAN

**PC-1:**
- IP: `172.16.0.10/24`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

**PC-2:**
- IP: `172.16.0.11/24`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

**PC-3:**
- IP: `172.16.0.12/24`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

---

## Parte 8: Configurazione Internet Cloud

**Internet Cloud:**
- IP: `192.0.2.2`
- Mask: `255.255.255.252`

---

## Parte 9: Test di Connettività e Sicurezza

### Test 1: INSIDE → DMZ (Security 100 → 50) ✅ PERMESSO

```
PC-1 > ping 10.0.1.10
PC-1 > Web Browser → http://10.0.1.10
```
**Risultato atteso:** ✅ Successo (higher → lower security)

### Test 2: INSIDE → OUTSIDE (Security 100 → 0) ✅ PERMESSO

```
PC-1 > ping 192.0.2.2
```
**Risultato atteso:** ✅ Successo

### Test 3: OUTSIDE → DMZ (Security 0 → 50) ⚠️ SOLO SERVIZI SPECIFICI

```
Internet > Web Browser → http://192.0.2.1 (NAT to 10.0.1.10)
```
**Risultato atteso:** ✅ HTTP/HTTPS permessi, resto bloccato

### Test 4: OUTSIDE → INSIDE (Security 0 → 100) ❌ BLOCCATO

```
Internet > ping 172.16.0.10
```
**Risultato atteso:** ❌ Timeout (no zone-pair definito)

### Test 5: DMZ → INSIDE (Security 50 → 100) ❌ BLOCCATO

```
Web-Server > ping 172.16.0.10
```
**Risultato atteso:** ❌ Timeout (contenimento DMZ, no zone-pair)

### Test 6: DMZ → OUTSIDE (Security 50 → 0) ⚠️ LIMITATO

```
Web-Server > ping 8.8.8.8
Web-Server > Web Browser → http://google.com
```
**Risultato atteso:** ✅ DNS e HTTP permessi (per aggiornamenti)

### Test 7: DMZ ↔ DMZ (Security 50 ↔ 50) ✅ PERMESSO

```
Web-Server > ping 10.0.1.20
```
**Risultato atteso:** ✅ Permesso (stesso switch, stessa zona)

---

## Parte 10: Verifica Configurazione

### Comandi di Verifica

```cisco
! Visualizzare zone configurate
FW-3ZONE# show zone security

! Visualizzare zone-pair
FW-3ZONE# show zone-pair security

! Visualizzare policy-map
FW-3ZONE# show policy-map type inspect zone-pair

! Statistiche sessioni
FW-3ZONE# show policy-map type inspect zone-pair sessions

! NAT translations
FW-3ZONE# show ip nat translations

! Interfacce e zone
FW-3ZONE# show ip interface brief
```

### Output Atteso - Show Zone Security

```
zone self
  Description: System defined zone

zone OUTSIDE
  Member Interfaces:
    GigabitEthernet0/0

zone DMZ
  Member Interfaces:
    GigabitEthernet0/1

zone INSIDE
  Member Interfaces:
    GigabitEthernet0/2
```

---

## Parte 11: Matrice Traffico

### Tabella Flussi Permessi

| Origine → Destinazione | Security Level | Policy | Protocolli | Risultato |
|------------------------|----------------|--------|------------|-----------|
| INSIDE → DMZ | 100 → 50 | INSIDE-TO-DMZ | ALL | ✅ Inspect |
| INSIDE → OUTSIDE | 100 → 0 | INSIDE-TO-OUTSIDE | ALL | ✅ Inspect |
| OUTSIDE → DMZ | 0 → 50 | OUTSIDE-TO-DMZ | HTTP, HTTPS, SMTP | ✅ Inspect |
| OUTSIDE → INSIDE | 0 → 100 | NONE | NONE | ❌ DENIED |
| DMZ → OUTSIDE | 50 → 0 | DMZ-TO-OUTSIDE | DNS, HTTP, HTTPS | ✅ Inspect |
| DMZ → INSIDE | 50 → 100 | NONE | NONE | ❌ DENIED |
| DMZ ↔ DMZ | 50 ↔ 50 | N/A (same zone) | ALL | ✅ Allowed |

---

## Parte 12: Logging e Monitoring

### Step 12.1 - Abilitare Logging

```cisco
FW-3ZONE# configure terminal

! Logging su buffer interno
FW-3ZONE(config)# logging buffered 51200 informational

! Logging console
FW-3ZONE(config)# logging console warnings

! Timestamp sui log
FW-3ZONE(config)# service timestamps log datetime msec

! Logging per denied packets
FW-3ZONE(config)# logging trap debugging
```

### Step 12.2 - Visualizzare Log

```cisco
! Visualizzare log buffer
FW-3ZONE# show logging

! Vedere drop log delle policy
FW-3ZONE# show policy-map type inspect zone-pair sessions
```

---

## Parte 13: Hardening Aggiuntivo

### Step 13.1 - Limitare Management Access

```cisco
! Creare ACL per management
FW-3ZONE(config)# access-list 99 permit 172.16.0.0 0.0.0.255

! Applicare a VTY (SSH/Telnet)
FW-3ZONE(config)# line vty 0 4
FW-3ZONE(config-line)# access-class 99 in
FW-3ZONE(config-line)# transport input ssh
FW-3ZONE(config-line)# exit

! Disabilitare servizi non necessari
FW-3ZONE(config)# no ip http server
FW-3ZONE(config)# no ip http secure-server
FW-3ZONE(config)# no cdp run
```

### Step 13.2 - TCP Intercept (SYN Flood Protection)

```cisco
FW-3ZONE(config)# ip tcp intercept list 101
FW-3ZONE(config)# ip tcp intercept mode watch
FW-3ZONE(config)# ip tcp intercept watch-timeout 30

FW-3ZONE(config)# access-list 101 permit tcp any 10.0.1.0 0.0.0.255
```

### Step 13.3 - Rate Limiting per ICMP

```cisco
! Class-map per ICMP
FW-3ZONE(config)# class-map match-all ICMP-CLASS
FW-3ZONE(config-cmap)# match protocol icmp
FW-3ZONE(config-cmap)# exit

! Policy-map per rate limit
FW-3ZONE(config)# policy-map ICMP-RATE-LIMIT
FW-3ZONE(config-pmap)# class ICMP-CLASS
FW-3ZONE(config-pmap-c)# police 8000 1500 1500 conform-action transmit exceed-action drop
FW-3ZONE(config-pmap-c)# exit
FW-3ZONE(config-pmap)# exit

! Applicare su interfaccia OUTSIDE
FW-3ZONE(config)# interface GigabitEthernet 0/0
FW-3ZONE(config-if)# service-policy input ICMP-RATE-LIMIT
```

---

## Parte 14: Troubleshooting

### Problema 1: Traffico INSIDE → DMZ non funziona

**Verifica:**
```cisco
FW-3ZONE# show zone-pair security INSIDE-DMZ
FW-3ZONE# show policy-map type inspect zone-pair INSIDE-DMZ sessions
```

**Cause comuni:**
- Zone-pair non creato
- Interfacce non assegnate a zone
- Policy-map non contiene il protocollo richiesto

### Problema 2: Internet non raggiunge server DMZ

**Verifica:**
```cisco
FW-3ZONE# show ip nat translations
FW-3ZONE# show zone-pair security OUTSIDE-DMZ
FW-3ZONE# debug ip nat
```

**Cause:**
- Static NAT non configurato
- Zone-pair OUTSIDE-DMZ manca o policy errata
- Class-map non include protocollo necessario

### Problema 3: DMZ riesce ad accedere LAN (NON DOVREBBE)

**Verifica:**
```cisco
FW-3ZONE# show zone-pair security
```

**Soluzione:**
- Assicurarsi che NON esista zone-pair DMZ-INSIDE
- Verificare che interfacce siano correttamente assegnate

---

## Parte 15: Confronto Architetture

### Tabella Comparativa

| Caratteristica | Singolo FW | Doppio FW | Tre Interfacce |
|----------------|------------|-----------|----------------|
| **Firewall** | 1 | 2 | 1 |
| **Interfacce** | 3 | 4+ | 3 |
| **Complessità Config** | Media | Alta | Media-Alta |
| **Costo Hardware** | Basso | Alto | Medio |
| **Prestazioni** | Buone | Più latenza | Ottime |
| **Granularità Policy** | Media | Alta | Alta |
| **Single Point of Failure** | Sì | No | Sì |
| **Use Case** | PMI | Enterprise Critical | PMI-Enterprise |

---

## Parte 16: Sfide Avanzate

### Challenge 1: Aggiungere quarta zona (GUEST)

Crea una quarta interfaccia per rete ospiti (Security=25):
- Permetti solo Internet
- Blocca DMZ e INSIDE

### Challenge 2: Application Level Gateway (ALG)

Configura inspection per protocolli complessi:
```cisco
FW-3ZONE(config)# ip inspect name FIREWALL ftp
FW-3ZONE(config)# ip inspect name FIREWALL h323
```

### Challenge 3: VPN Integration

Aggiungi interfaccia virtuale per VPN users con security level 75.

### Challenge 4: IPS Integration

Integra con Cisco IOS IPS per deep packet inspection:
```cisco
FW-3ZONE(config)# ip ips name IPS-POLICY
FW-3ZONE(config)# interface GigabitEthernet 0/0
FW-3ZONE(config-if)# ip ips IPS-POLICY in
```

---

## Conclusioni

🎉 **Congratulazioni!** Hai completato:
- ✅ Configurazione firewall a tre interfacce
- ✅ Zone-Based Policy Firewall (ZBPF)
- ✅ Security levels e inter-zone traffic
- ✅ Policy maps granulari per zona
- ✅ NAT dinamico e statico
- ✅ Contenimento DMZ efficace
- ✅ Logging e monitoring

### Concetti Chiave
- **Three-zone architecture** (Outside/DMZ/Inside)
- **Security levels** (0/50/100)
- **Zone-Based Policy Firewall (ZBPF)**
- **Class-maps e Policy-maps**
- **Zone-pairs** per controllo inter-zone
- **Stateful inspection** automatica

### Vantaggi Architettura
1. **Singolo dispositivo**: Meno costo hardware vs dual-firewall
2. **Policy granulari**: Controllo preciso per ogni zone-pair
3. **Scalabilità**: Facile aggiungere nuove zone
4. **Prestazioni**: Meno latenza vs dual-firewall
5. **Management centralizzato**: Una sola configurazione

### Prossimi Passi
- **LAB 2.x**: Servizi avanzati in DMZ
- **LAB 3.x**: ACL avanzate e filtering
- **LAB 4.x**: IDS/IPS integration

---

**Salvare:** File → Save As → `lab1.3-dmz-tre-interfacce.pkt`

**Fine Laboratorio 1.3**
