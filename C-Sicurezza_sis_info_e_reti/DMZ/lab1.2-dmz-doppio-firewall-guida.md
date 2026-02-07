# LAB 1.2 - DMZ a Doppio Firewall (Back-to-Back)

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 3 ore  
**File da creare:** `lab1.2-dmz-doppio-firewall.pkt`  
**Prerequisiti:** Completamento LAB 1.1

---

## Obiettivi del Laboratorio
- Implementare architettura a doppio firewall (back-to-back)
- Configurare regole su firewall perimetrale ed interno
- Applicare il principio di defense in depth (difesa a più strati)
- Comprendere la separazione delle responsabilità tra firewall
- Testare il contenimento in caso di compromissione DMZ

---

## Topologia da Implementare

```
    [INTERNET]
         |
    192.0.2.1/30
         |
[G0/0]  FW-ESTERNO  [G0/1]
         |
    10.0.0.0/30
         |
    [Switch-DMZ]
    |           |
10.0.1.10   10.0.1.20
    |           |
[Web-Server] [Mail-Server]
         |
    10.0.0.4/30
         |
[G0/0]  FW-INTERNO  [G0/1]
         |
    172.16.0.1/24
         |
    [Switch-LAN]
         |
    172.16.0.10-12
         |
    [PC-1] [PC-2] [PC-3]
```

---

## Architettura di Sicurezza

### Firewall Esterno (Perimetrale)
**Responsabilità:**
- Prima linea di difesa contro Internet
- Filtrare traffico in ingresso verso DMZ
- Bloccare attacchi evidenti e scansioni
- Permettere solo servizi pubblici (HTTP, HTTPS, SMTP)

### Firewall Interno (Core)
**Responsabilità:**
- Proteggere la LAN da minacce DMZ e Internet
- Implementare controlli più granulari
- Gestire NAT per LAN
- Segmentare traffico LAN → DMZ
- Last line of defense

### DMZ (Zona Demilitarizzata)
**Contenuto:**
- Web Server (HTTP/HTTPS)
- Mail Server (SMTP/IMAP)
- **Isolata da entrambi i lati**

---

## Parte 1: Creazione Topologia Fisica

### Step 1.1 - Aggiungere Dispositivi

**Router/Firewall:**
- 2x Router 2911:
  - **FW-ESTERNO** (Firewall perimetrale)
  - **FW-INTERNO** (Firewall interno)

**Switch:**
- 2x Switch 2960:
  - **Switch-DMZ** (connette firewall e server DMZ)
  - **Switch-LAN** (connette FW-INTERNO e PC)

**Server:**
- 1x Server-PT: **Web-Server**
- 1x Server-PT: **Mail-Server**

**PC:**
- 3x PC-PT: **PC-1**, **PC-2**, **PC-3**

**Cloud:**
- 1x Cloud-PT: **Internet**

### Step 1.2 - Collegare i Dispositivi

**Collegamenti cablati (Copper Straight-Through):**

1. **Internet Fa0** → **FW-ESTERNO G0/0**
2. **FW-ESTERNO G0/1** → **Switch-DMZ Fa0/1**
3. **Switch-DMZ Fa0/2** → **Web-Server Fa0**
4. **Switch-DMZ Fa0/3** → **Mail-Server Fa0**
5. **Switch-DMZ Fa0/4** → **FW-INTERNO G0/0**
6. **FW-INTERNO G0/1** → **Switch-LAN Fa0/1**
7. **Switch-LAN Fa0/2** → **PC-1 Fa0**
8. **Switch-LAN Fa0/3** → **PC-2 Fa0**
9. **Switch-LAN Fa0/4** → **PC-3 Fa0**

---

## Parte 2: Piano di Indirizzamento

### Tabella IP

| Dispositivo | Interfaccia | IP Address | Subnet Mask | Gateway |
|-------------|-------------|------------|-------------|---------|
| **Internet** | Fa0 | 192.0.2.2 | 255.255.255.252 | - |
| **FW-ESTERNO** | G0/0 (WAN) | 192.0.2.1 | 255.255.255.252 | - |
| **FW-ESTERNO** | G0/1 (to DMZ) | 10.0.0.1 | 255.255.255.252 | - |
| **Switch-DMZ** | VLAN 1 | 10.0.1.1 | 255.255.255.0 | 10.0.1.1 |
| **Web-Server** | Fa0 | 10.0.1.10 | 255.255.255.0 | 10.0.0.1 |
| **Mail-Server** | Fa0 | 10.0.1.20 | 255.255.255.0 | 10.0.0.1 |
| **FW-INTERNO** | G0/0 (to DMZ) | 10.0.0.5 | 255.255.255.252 | - |
| **FW-INTERNO** | G0/1 (LAN) | 172.16.0.1 | 255.255.255.0 | - |
| **PC-1** | Fa0 | 172.16.0.10 | 255.255.255.0 | 172.16.0.1 |
| **PC-2** | Fa0 | 172.16.0.11 | 255.255.255.0 | 172.16.0.1 |
| **PC-3** | Fa0 | 172.16.0.12 | 255.255.255.0 | 172.16.0.1 |

**Note:**
- Rete WAN: 192.0.2.0/30
- Collegamento FW-ESTERNO → Switch-DMZ: 10.0.0.0/30
- Rete DMZ: 10.0.1.0/24
- Collegamento Switch-DMZ → FW-INTERNO: 10.0.0.4/30
- Rete LAN: 172.16.0.0/24

---

## Parte 3: Configurazione FW-ESTERNO (Firewall Perimetrale)

### Step 3.1 - Configurazione Base e Interfacce

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-ESTERNO
FW-ESTERNO(config)#

! Interfaccia WAN (verso Internet)
FW-ESTERNO(config)# interface GigabitEthernet 0/0
FW-ESTERNO(config-if)# description *** WAN - Internet ***
FW-ESTERNO(config-if)# ip address 192.0.2.1 255.255.255.252
FW-ESTERNO(config-if)# no shutdown
FW-ESTERNO(config-if)# exit

! Interfaccia verso Switch-DMZ
FW-ESTERNO(config)# interface GigabitEthernet 0/1
FW-ESTERNO(config-if)# description *** To Switch-DMZ ***
FW-ESTERNO(config-if)# ip address 10.0.0.1 255.255.255.252
FW-ESTERNO(config-if)# no shutdown
FW-ESTERNO(config-if)# exit
```

### Step 3.2 - Routing Statico su FW-ESTERNO

```cisco
! Route verso rete DMZ
FW-ESTERNO(config)# ip route 10.0.1.0 255.255.255.0 10.0.0.2

! Route verso rete LAN (attraverso FW-INTERNO)
FW-ESTERNO(config)# ip route 172.16.0.0 255.255.255.0 10.0.0.2

! Default route verso Internet
FW-ESTERNO(config)# ip route 0.0.0.0 0.0.0.0 192.0.2.2
```

### Step 3.3 - ACL Firewall Esterno

**Policy del Firewall Esterno:**
1. ✅ Permettere HTTP/HTTPS da Internet → Web Server
2. ✅ Permettere SMTP da Internet → Mail Server
3. ✅ Permettere traffico established di ritorno
4. ❌ Bloccare tutto il resto

```cisco
! ACL per traffico da Internet
FW-ESTERNO(config)# ip access-list extended INTERNET-TO-DMZ

! HTTP verso Web Server
FW-ESTERNO(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80
! HTTPS verso Web Server
FW-ESTERNO(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! SMTP verso Mail Server
FW-ESTERNO(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25

! Permettere connessioni established (risposte)
FW-ESTERNO(config-ext-nacl)# permit tcp any any established

! Permettere ICMP echo-reply
FW-ESTERNO(config-ext-nacl)# permit icmp any any echo-reply

! Log e blocca tutto il resto
FW-ESTERNO(config-ext-nacl)# deny ip any any log

FW-ESTERNO(config-ext-nacl)# exit

! Applicare ACL
FW-ESTERNO(config)# interface GigabitEthernet 0/0
FW-ESTERNO(config-if)# ip access-group INTERNET-TO-DMZ in
FW-ESTERNO(config-if)# exit
```

### Step 3.4 - NAT su FW-ESTERNO (Port Forwarding)

```cisco
! Definire inside/outside
FW-ESTERNO(config)# interface GigabitEthernet 0/0
FW-ESTERNO(config-if)# ip nat outside
FW-ESTERNO(config-if)# exit

FW-ESTERNO(config)# interface GigabitEthernet 0/1
FW-ESTERNO(config-if)# ip nat inside
FW-ESTERNO(config-if)# exit

! Static NAT per Web Server (HTTP)
FW-ESTERNO(config)# ip nat inside source static tcp 10.0.1.10 80 192.0.2.1 80

! Static NAT per Web Server (HTTPS)
FW-ESTERNO(config)# ip nat inside source static tcp 10.0.1.10 443 192.0.2.1 443

! Static NAT per Mail Server (SMTP)
FW-ESTERNO(config)# ip nat inside source static tcp 10.0.1.20 25 192.0.2.1 25

! Salvare
FW-ESTERNO(config)# exit
FW-ESTERNO# write memory
```

---

## Parte 4: Configurazione Switch-DMZ

### Step 4.1 - Configurazione IP Switch (Opzionale per Management)

```cisco
Switch> enable
Switch# configure terminal
Switch(config)# hostname Switch-DMZ
Switch-DMZ(config)#

! Configurare IP management
Switch-DMZ(config)# interface vlan 1
Switch-DMZ(config-if)# ip address 10.0.1.1 255.255.255.0
Switch-DMZ(config-if)# no shutdown
Switch-DMZ(config-if)# exit

Switch-DMZ(config)# ip default-gateway 10.0.0.1
Switch-DMZ(config)# exit
Switch-DMZ# write memory
```

**Note:** In Packet Tracer basic switch non richiede configurazione specifica, ma in ambiente reale configureresti port-security, VLAN, ecc.

---

## Parte 5: Configurazione Server DMZ

### Step 5.1 - Web Server

**Configurazione IP** (Desktop → IP Configuration):
- IP: `10.0.1.10`
- Mask: `255.255.255.0`
- Gateway: `10.0.0.1` (FW-ESTERNO)
- DNS: `10.0.1.20` (o 8.8.8.8)

**Servizi** (Services):
1. **HTTP**: ON
2. **HTTPS**: ON
3. Modifica **index.html**:
```html
<html>
<head><title>DMZ Web Server - LAB 1.2</title></head>
<body>
<h1>Web Server in DMZ - Dual Firewall Architecture</h1>
<p>IP: 10.0.1.10</p>
<p>Protected by FW-ESTERNO and FW-INTERNO</p>
</body>
</html>
```

### Step 5.2 - Mail Server

**Configurazione IP**:
- IP: `10.0.1.20`
- Mask: `255.255.255.0`
- Gateway: `10.0.0.1`
- DNS: `10.0.1.20` (self)

**Servizi**:
1. **SMTP**: ON
2. **POP3**: ON (porta 110)
3. **IMAP**: ON (porta 143)
4. **DNS**: ON (opzionale)

**Creare utente email** (Services → EMAIL):
- User: `admin@dmz.local`
- Password: `Password1`

---

## Parte 6: Configurazione FW-INTERNO (Firewall Core)

### Step 6.1 - Configurazione Base e Interfacce

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-INTERNO
FW-INTERNO(config)#

! Interfaccia verso Switch-DMZ
FW-INTERNO(config)# interface GigabitEthernet 0/0
FW-INTERNO(config-if)# description *** To Switch-DMZ ***
FW-INTERNO(config-if)# ip address 10.0.0.5 255.255.255.252
FW-INTERNO(config-if)# no shutdown
FW-INTERNO(config-if)# exit

! Interfaccia verso LAN Interna
FW-INTERNO(config)# interface GigabitEthernet 0/1
FW-INTERNO(config-if)# description *** Internal LAN ***
FW-INTERNO(config-if)# ip address 172.16.0.1 255.255.255.0
FW-INTERNO(config-if)# no shutdown
FW-INTERNO(config-if)# exit
```

### Step 6.2 - Routing su FW-INTERNO

```cisco
! Route verso DMZ
FW-INTERNO(config)# ip route 10.0.1.0 255.255.255.0 10.0.0.1

! Default route verso FW-ESTERNO (poi Internet)
FW-INTERNO(config)# ip route 0.0.0.0 0.0.0.0 10.0.0.1
```

### Step 6.3 - NAT su FW-INTERNO (per LAN → Internet)

```cisco
! Definire inside/outside
FW-INTERNO(config)# interface GigabitEthernet 0/0
FW-INTERNO(config-if)# ip nat outside
FW-INTERNO(config-if)# exit

FW-INTERNO(config)# interface GigabitEthernet 0/1
FW-INTERNO(config-if)# ip nat inside
FW-INTERNO(config-if)# exit

! ACL per identificare LAN
FW-INTERNO(config)# access-list 10 permit 172.16.0.0 0.0.0.255

! NAT overload (PAT) usando interfaccia G0/0
FW-INTERNO(config)# ip nat inside source list 10 interface GigabitEthernet 0/0 overload
```

### Step 6.4 - ACL Firewall Interno (Policy Principali)

**Policy del Firewall Interno:**
1. ✅ Permettere LAN → Internet (HTTP, HTTPS, DNS)
2. ✅ Permettere LAN → Web Server DMZ (solo HTTP/HTTPS)
3. ✅ Permettere LAN → Mail Server DMZ (solo IMAP/POP3)
4. ❌ **BLOCCARE DMZ → LAN** (contenimento critico!)
5. ✅ Permettere risposte established

#### ACL 1: Da LAN verso esterno

```cisco
FW-INTERNO(config)# ip access-list extended LAN-OUTBOUND

! Permettere DNS
FW-INTERNO(config-ext-nacl)# permit udp 172.16.0.0 0.0.0.255 any eq 53

! Permettere HTTP/HTTPS
FW-INTERNO(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 any eq 80
FW-INTERNO(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 any eq 443

! Permettere accesso a Mail Server DMZ
FW-INTERNO(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 110
FW-INTERNO(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 143
FW-INTERNO(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 25

! Permettere ICMP (ping)
FW-INTERNO(config-ext-nacl)# permit icmp 172.16.0.0 0.0.0.255 any

! Blocca resto
FW-INTERNO(config-ext-nacl)# deny ip any any log

FW-INTERNO(config-ext-nacl)# exit

! Applicare in ingresso su interfaccia LAN
FW-INTERNO(config)# interface GigabitEthernet 0/1
FW-INTERNO(config-if)# ip access-group LAN-OUTBOUND in
FW-INTERNO(config-if)# exit
```

#### ACL 2: Da DMZ verso LAN (BLOCCO CRITICO)

```cisco
! ACL per BLOCCARE DMZ → LAN (contenimento)
FW-INTERNO(config)# ip access-list extended DMZ-TO-LAN-BLOCK

! **NEGA** tutto il traffico iniziato dalla DMZ verso LAN
FW-INTERNO(config-ext-nacl)# deny ip 10.0.1.0 0.0.0.255 172.16.0.0 0.0.0.255 log

! Permettere traffico established (risposte a connessioni LAN)
FW-INTERNO(config-ext-nacl)# permit tcp any any established

! Permettere tutto il resto (DMZ verso Internet OK)
FW-INTERNO(config-ext-nacl)# permit ip any any

FW-INTERNO(config-ext-nacl)# exit

! Applicare in ingresso su interfaccia DMZ
FW-INTERNO(config)# interface GigabitEthernet 0/0
FW-INTERNO(config-if)# ip access-group DMZ-TO-LAN-BLOCK in
FW-INTERNO(config-if)# exit

! Salvare
FW-INTERNO(config)# exit
FW-INTERNO# write memory
```

---

## Parte 7: Configurazione PC LAN

### PC-1
- IP: `172.16.0.10`
- Mask: `255.255.255.0`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8` (o 10.0.1.20)

### PC-2
- IP: `172.16.0.11`
- Mask: `255.255.255.0`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

### PC-3
- IP: `172.16.0.12`
- Mask: `255.255.255.0`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

---

## Parte 8: Configurazione Internet Cloud

**Cloud Internet**:
- IP: `192.0.2.2`
- Mask: `255.255.255.252`

---

## Parte 9: Test di Connettività

### Test 1: Internet → Web Server (attraverso NAT)

1. Da **Internet** → Desktop → Web Browser
2. URL: `http://192.0.2.1` (IP pubblico del FW-ESTERNO)
**Risultato atteso:** ✅ Pagina web visualizzata (port forward funziona)

### Test 2: PC-1 → Web Server DMZ

1. Da **PC-1** → Web Browser
2. URL: `http://10.0.1.10`
**Risultato atteso:** ✅ Successo

### Test 3: PC-1 → Internet

1. Da **PC-1** → Command Prompt
```
C:\> ping 192.0.2.2
```
**Risultato atteso:** ✅ Successo (NAT sul FW-INTERNO funziona)

### Test 4: Web Server → PC-1 (DEVE FALLIRE - Contenimento DMZ)

1. Da **Web-Server** → Command Prompt
```
C:\> ping 172.16.0.10
```
**Risultato atteso:** ❌ **FALLIMENTO** - Request timed out
*Motivo: ACL DMZ-TO-LAN-BLOCK blocca traffico iniziato da DMZ*

### Test 5: PC accesso Mail Server

1. Da **PC-1** → Desktop → Email
2. Configura:
   - Username: `admin@dmz.local`
   - Mail Server: `10.0.1.20`
3. Invia email a te stesso
**Risultato atteso:** ✅ Successo

---

## Parte 10: Test di Sicurezza Avanzati

### Scenario 1: Simulazione Compromissione Web Server

**Ipotesi:** Un attaccante ha compromesso il Web Server (10.0.1.10) tramite vulnerabilità web.

**Test A - Attaccante cerca di raggiungere LAN:**
1. Da **Web-Server** → Command Prompt
```
C:\> ping 172.16.0.10
C:\> ping 172.16.0.1
```
**Risultato:** ❌ Bloccato da FW-INTERNO (ACL DMZ-TO-LAN-BLOCK)

**Test B - Attaccante può raggiungere altri server DMZ:**
```
C:\> ping 10.0.1.20
```
**Risultato:** ✅ Probabilmente permesso (lateral movement in DMZ)
*Nota per hardening futuro: Segmentare anche all'interno della DMZ*

**Test C - Attaccante tenta connessione Internet (C&C):**
```
C:\> ping 192.0.2.2
```
**Risultato:** Dipende dalle policy FW-ESTERNO uscita
*Best practice: Limitare DMZ → Internet a solo traffico necessario*

### Scenario 2: Verifica Doppia Protezione

**Test: Internet → LAN diretta (bypassando DMZ)**
1. Da **Internet** → Command Prompt
```
C:\> ping 172.16.0.10
```
**Risultato:** ❌ **BLOCCATO** da FW-ESTERNO
*Doppia protezione: anche se FW-ESTERNO fallisse, FW-INTERNO blocca*

---

## Parte 11: Monitoring e Verifica

### Comandi Verifica FW-ESTERNO

```cisco
FW-ESTERNO# show ip interface brief
FW-ESTERNO# show access-lists INTERNET-TO-DMZ
FW-ESTERNO# show ip nat translations
FW-ESTERNO# show ip route
```

### Comandi Verifica FW-INTERNO

```cisco
FW-INTERNO# show ip interface brief
FW-INTERNO# show access-lists
FW-INTERNO# show ip nat translations
FW-INTERNO# show ip route
FW-INTERNO# show access-lists DMZ-TO-LAN-BLOCK
```

### Visualizzare Hit Count ACL

```cisco
! Su entrambi i firewall
show access-lists
```
Le entry con `(X matches)` mostrano quante volte quella regola è stata applicata.

---

## Parte 12: Documentazione Architettura

### Matrice Flussi di Traffico

| Origine | Destinazione | Attraversa | Policy | Risultato |
|---------|--------------|------------|--------|-----------|
| Internet | Web Server | FW-ESTERNO | PERMIT 80,443 | ✅ OK |
| Internet | Mail Server | FW-ESTERNO | PERMIT 25 | ✅ OK |
| Internet | LAN | FW-ESTERNO | DENY all | ❌ Bloccato |
| LAN | Internet | FW-INTERNO, FW-ESTERNO | PERMIT | ✅ OK |
| LAN | Web Server | FW-INTERNO | PERMIT 80,443 | ✅ OK |
| LAN | Mail Server | FW-INTERNO | PERMIT 110,143 | ✅ OK |
| DMZ | LAN | FW-INTERNO | DENY all | ❌ Bloccato |
| DMZ | Internet | FW-ESTERNO | Dipende policy | ? |
| DMZ | DMZ | Switch-DMZ | Nessun FW | ⚠️ Permesso |

### Vantaggi Architettura Doppio Firewall

1. **Defense in Depth**: Due layer di protezione
2. **Contenimento**: DMZ isolata da entrambi i lati
3. **Separazione responsabilità**: 
   - FW-ESTERNO: protegge da Internet
   - FW-INTERNO: protegge LAN
4. **Ridondanza**: Failure di un firewall non espone direttamente LAN
5. **Audit separato**: Log indipendenti per compliance

### Svantaggi

1. **Complessità**: Più dispositivi da configurare e mantenere
2. **Costo**: Hardware aggiuntivo
3. **Latenza**: Due hop di firewall
4. **Troubleshooting**: Più difficile diagnosticare problemi

---

## Parte 13: Hardening Aggiuntivo

### Raccomandazioni

```cisco
! Su ENTRAMBI i firewall:

! 1. Disabilitare servizi non necessari
FW-ESTERNO(config)# no ip http server
FW-ESTERNO(config)# no ip http secure-server
FW-ESTERNO(config)# no cdp run

! 2. Configurare SSH per management remoto
FW-ESTERNO(config)# hostname FW-ESTERNO
FW-ESTERNO(config)# ip domain-name dmzlab.local
FW-ESTERNO(config)# crypto key generate rsa modulus 2048
FW-ESTERNO(config)# ip ssh version 2
FW-ESTERNO(config)# line vty 0 4
FW-ESTERNO(config-line)# transport input ssh
FW-ESTERNO(config-line)# login local
FW-ESTERNO(config-line)# exit

! 3. Creare utente admin
FW-ESTERNO(config)# username admin privilege 15 secret Cisco123!

! 4. Banner di avviso
FW-ESTERNO(config)# banner motd #
***********************************************
*  UNAUTHORIZED ACCESS PROHIBITED             *
*  This system is for authorized use only     *
***********************************************
#

! 5. Logging centralizzato
FW-ESTERNO(config)# logging buffered 51200 informational
FW-ESTERNO(config)# logging console critical
FW-ESTERNO(config)# service timestamps log datetime msec
```

---

## Parte 14: Sfide Avanzate

### Challenge 1: Segmentazione Intra-DMZ
Modifica l'architettura per impedire comunicazione diretta Web Server ↔ Mail Server.
**Suggerimento:** Usa VLAN separate o micro-segmentation.

### Challenge 2: Egress Filtering
Implementa ACL su FW-ESTERNO per limitare DMZ → Internet a solo:
- DNS (UDP/53)
- NTP (UDP/123)
- HTTPS (TCP/443) verso IP specifici (aggiornamenti)

### Challenge 3: IPS Simulation
Aggiungi regole che simulano rilevamento IPS:
- Blocca connessioni da IP noti malevoli (blacklist)
- Rate limiting (simulato con ACL)

### Challenge 4: DMZ Management Network
Crea terza interfaccia su entrambi i firewall per rete di management separata.

---

## Parte 15: Troubleshooting Comune

### Problema 1: Internet non raggiunge Web Server

**Debug:**
```cisco
FW-ESTERNO# show ip nat translations
FW-ESTERNO# show access-lists INTERNET-TO-DMZ
FW-ESTERNO# debug ip nat
```
**Verificare:**
- NAT static configurato correttamente
- ACL permette traffico
- Routing corretto su FW-ESTERNO

### Problema 2: LAN non accede a Internet

**Debug:**
```cisco
FW-INTERNO# show ip nat translations
FW-INTERNO# show ip route
FW-INTERNO# show access-lists LAN-OUTBOUND
```
**Verificare:**
- NAT overload configurato
- Default route verso FW-ESTERNO
- ACL LAN-OUTBOUND permette traffico

### Problema 3: DMZ → LAN funziona (NON DOVREBBE)

**Debug:**
```cisco
FW-INTERNO# show access-lists DMZ-TO-LAN-BLOCK
```
**Verificare:**
- ACL applicata in direzione corretta (inbound su G0/0)
- Ordine regole ACL (deny prima di permit)

---

## Conclusioni

🎉 **Congratulazioni!** Hai implementato:
- ✅ Architettura DMZ dual-firewall
- ✅ Defense in depth a due layer
- ✅ Contenimento DMZ (isolata da LAN)
- ✅ NAT/PAT su entrambi i firewall
- ✅ ACL granulari per segmentazione
- ✅ Test di sicurezza e penetration scenario

### Concetti Chiave Appresi
- **Back-to-back firewall architecture**
- **Separation of duties** tra firewall
- **DMZ containment** (critico per security)
- **Multi-layer security policy**
- **Stateful inspection** con established connections
- **Port forwarding** per servizi pubblici

### Confronto con LAB 1.1

| Aspetto | LAB 1.1 (Singolo FW) | LAB 1.2 (Doppio FW) |
|---------|---------------------|---------------------|
| Firewall | 1 | 2 |
| Layer di protezione | 1 | 2 |
| Complessità | Bassa | Media |
| Sicurezza | Buona | Ottima |
| Costo | Basso | Medio |
| Manutenzione | Semplice | Complessa |
| Use case | PMI, low-risk | Enterprise, high-security |

### Prossimi Passi
- **LAB 1.3**: DMZ a tre interfacce con Cisco ASA
- **LAB 2.x**: Configurazione servizi avanzati
- **LAB 3.x**: ACL avanzate e Zone-Based Firewall

---

**Salvare il Progetto:**
File → Save As → `lab1.2-dmz-doppio-firewall.pkt`

---

**Fine Laboratorio 1.2**

📚 Per domande o supporto, consultare il docente o il forum e-learning.
