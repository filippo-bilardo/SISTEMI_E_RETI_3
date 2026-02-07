# LAB 2.3 - DNS Server in DMZ (Split-Brain Configuration)

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 2.5 ore  
**File da creare:** `lab2.3-dns-split-brain.pkt`  
**Prerequisiti:** LAB 1.1, LAB 2.1

---

## Obiettivi del Laboratorio
- Comprendere DNS split-brain (split-horizon)
- Configurare DNS server pubblico in DMZ
- Implementare risoluzione interna vs esterna
- Configurare zone forward e reverse
- Testare DNS poisoning protection
- Implementare DNS security basics

---

## DNS Split-Brain: Concetto

### Problema da Risolvere

**Scenario:**
```
Cliente Interno  → www.example.com → quale IP?
Cliente Esterno  → www.example.com → quale IP?
```

**Risposta Diversa Necessaria:**
- **Interno:** 10.0.1.10 (IP privato, accesso diretto)
- **Esterno:** 198.51.100.254 (IP pubblico NAT)

### Split-Brain Architecture

```
                    [Internet]
                        |
                   [DNS Esterno]
                   (Autoritative)
                        |
                 [Router/Firewall]
                   /          \
         [DNS Interno]      [DNS DMZ]
         (Forwarding)       (Pubblico)
              |                  |
           [LAN]              [DMZ]
```

---

## Topologia Lab

```
                        [Router/Firewall]
                       /        |        \
                  G0/0 (WAN) G0/1 (DMZ) G0/2 (LAN)
                     |           |            |
              [Cloud Internet] [Switch]    [Switch]
              198.51.100.1       |            |
                            10.0.1.30      172.16.0.100
                            10.0.1.10         |
                                |             |
                          [DNS-DMZ]      [DNS-LAN]   172.16.0.100
                          [Web-Srv]      [PC-User1]  172.16.0.11
                                         [PC-User2]  172.16.0.12
```

---

## Parte 1: Piano IP e Setup Base

### Tabella IP

| Dispositivo | IP | Mask | Gateway | Ruolo |
|-------------|----|------|---------|-------|
| FW G0/0 | 198.51.100.254 | /24 | - | WAN |
| FW G0/1 | 10.0.1.1 | /24 | - | DMZ |
| FW G0/2 | 172.16.0.1 | /24 | - | LAN |
| DNS-DMZ | 10.0.1.30 | /24 | 10.0.1.1 | Pubblico |
| DNS-LAN | 172.16.0.100 | /24 | 172.16.0.1 | Interno |
| Web-Srv | 10.0.1.10 | /24 | 10.0.1.1 | Web server |
| PC-User1 | 172.16.0.11 | /24 | 172.16.0.1 | Client |
| PC-User2 | 172.16.0.12 | /24 | 172.16.0.1 | Client |
| Internet | 198.51.100.1 | /24 | - | External |

### Configurazione Router

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-DNS
FW-DNS(config)#

! WAN Interface
FW-DNS(config)# interface GigabitEthernet 0/0
FW-DNS(config-if)# description WAN-INTERNET
FW-DNS(config-if)# ip address 198.51.100.254 255.255.255.0
FW-DNS(config-if)# no shutdown
FW-DNS(config-if)# exit

! DMZ Interface
FW-DNS(config)# interface GigabitEthernet 0/1
FW-DNS(config-if)# description DMZ
FW-DNS(config-if)# ip address 10.0.1.1 255.255.255.0
FW-DNS(config-if)# no shutdown
FW-DNS(config-if)# exit

! LAN Interface
FW-DNS(config)# interface GigabitEthernet 0/2
FW-DNS(config-if)# description LAN
FW-DNS(config-if)# ip address 172.16.0.1 255.255.255.0
FW-DNS(config-if)# no shutdown
FW-DNS(config-if)# exit

! Default route
FW-DNS(config)# ip route 0.0.0.0 0.0.0.0 198.51.100.1
```

---

## Parte 2: NAT e Port Forwarding DNS

### NAT Configuration

```cisco
! Inside interfaces
FW-DNS(config)# interface GigabitEthernet 0/1
FW-DNS(config-if)# ip nat inside
FW-DNS(config-if)# exit

FW-DNS(config)# interface GigabitEthernet 0/2
FW-DNS(config-if)# ip nat inside
FW-DNS(config-if)# exit

! Outside interface
FW-DNS(config)# interface GigabitEthernet 0/0
FW-DNS(config-if)# ip nat outside
FW-DNS(config-if)# exit

! Port forwarding DNS (UDP e TCP porta 53)
FW-DNS(config)# ip nat inside source static udp 10.0.1.30 53 198.51.100.254 53
FW-DNS(config)# ip nat inside source static tcp 10.0.1.30 53 198.51.100.254 53

! Port forwarding Web Server
FW-DNS(config)# ip nat inside source static tcp 10.0.1.10 80 198.51.100.254 80
FW-DNS(config)# ip nat inside source static tcp 10.0.1.10 443 198.51.100.254 443

! PAT per LAN
FW-DNS(config)# ip nat inside source list LAN-NAT interface GigabitEthernet 0/0 overload
FW-DNS(config)# access-list 1 permit 172.16.0.0 0.0.0.255
```

---

## Parte 3: ACL DNS Security

### ACL Internet → DNS-DMZ

```cisco
FW-DNS(config)# ip access-list extended INTERNET-TO-DMZ

! DNS queries (UDP 53 - primario)
FW-DNS(config-ext-nacl)# remark === DNS Service ===
FW-DNS(config-ext-nacl)# permit udp any host 10.0.1.30 eq 53

! DNS zone transfer prevenzion (TCP 53 - limitato!)
FW-DNS(config-ext-nacl)# remark === DNS Zone Transfer - RESTRICTED ===
FW-DNS(config-ext-nacl)# deny tcp any host 10.0.1.30 eq 53 log
! (In produzione: permettere solo da DNS secondari autorizzati)

! Web server
FW-DNS(config-ext-nacl)# remark === Web Server ===
FW-DNS(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80
FW-DNS(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! Return traffic
FW-DNS(config-ext-nacl)# permit tcp any any established
FW-DNS(config-ext-nacl)# permit udp any any eq 53
FW-DNS(config-ext-nacl)# permit icmp any any echo-reply

! Deny all
FW-DNS(config-ext-nacl)# deny ip any any log

FW-DNS(config-ext-nacl)# exit

FW-DNS(config)# interface GigabitEthernet 0/0
FW-DNS(config-if)# ip access-group INTERNET-TO-DMZ in
FW-DNS(config-if)# exit
```

### ACL LAN → DMZ e Internet

```cisco
FW-DNS(config)# ip access-list extended LAN-TO-ALL

! LAN può interrogare DNS-DMZ
FW-DNS(config-ext-nacl)# remark === Internal DNS ===
FW-DNS(config-ext-nacl)# permit udp 172.16.0.0 0.0.0.255 host 10.0.1.30 eq 53
FW-DNS(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.30 eq 53

! LAN può accedere DNS-LAN
FW-DNS(config-ext-nacl)# permit udp 172.16.0.0 0.0.0.255 host 172.16.0.100 eq 53
FW-DNS(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 172.16.0.100 eq 53

! Web server access
FW-DNS(config-ext-nacl)# remark === Web Access ===
FW-DNS(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.10 eq 80
FW-DNS(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.10 eq 443

! Allow established
FW-DNS(config-ext-nacl)# permit tcp any any established
FW-DNS(config-ext-nacl)# permit udp any any

! Permit to Internet
FW-DNS(config-ext-nacl)# permit ip 172.16.0.0 0.0.0.255 any

FW-DNS(config-ext-nacl)# exit

FW-DNS(config)# interface GigabitEthernet 0/2
FW-DNS(config-if)# ip access-group LAN-TO-ALL in
FW-DNS(config-if)# exit
```

### ACL DMZ → Internet (DNS Forwarding)

```cisco
FW-DNS(config)# ip access-list extended DMZ-TO-INTERNET

! DNS-DMZ può fare forwarding a DNS pubblici
FW-DNS(config-ext-nacl)# remark === DNS Forwarding ===
FW-DNS(config-ext-nacl)# permit udp host 10.0.1.30 any eq 53
FW-DNS(config-ext-nacl)# permit tcp host 10.0.1.30 any eq 53

! Web server può aggiornamenti
FW-DNS(config-ext-nacl)# remark === Updates ===
FW-DNS(config-ext-nacl)# permit tcp host 10.0.1.10 any eq 80
FW-DNS(config-ext-nacl)# permit tcp host 10.0.1.10 any eq 443

! NTP
FW-DNS(config-ext-nacl)# permit udp 10.0.1.0 0.0.0.255 any eq 123

! Return traffic
FW-DNS(config-ext-nacl)# permit tcp any any established
FW-DNS(config-ext-nacl)# permit udp any any

! BLOCCARE DMZ → LAN (critico!)
FW-DNS(config-ext-nacl)# remark === DMZ Containment ===
FW-DNS(config-ext-nacl)# deny ip 10.0.1.0 0.0.0.255 172.16.0.0 0.0.0.255 log

! Rest to Internet OK
FW-DNS(config-ext-nacl)# permit ip any any

FW-DNS(config-ext-nacl)# exit

FW-DNS(config)# interface GigabitEthernet 0/1
FW-DNS(config-if)# ip access-group DMZ-TO-INTERNET out
FW-DNS(config-if)# exit
```

---

## Parte 4: Configurazione DNS-DMZ (Pubblico)

### Setup Server DNS-DMZ

1. Aggiungere **Server** in DMZ
2. Configurare networking:
   - IP: 10.0.1.30
   - Mask: 255.255.255.0
   - Gateway: 10.0.1.1

3. Cliccare **Services** → **DNS**
4. Attivare **DNS Service: ON**

### Zone Forward - example.com (Vista Pubblica)

**Aggiungere records DNS pubblici:**

```
Tipo  | Nome              | Indirizzo
------|-------------------|-------------------
A     | example.com       | 198.51.100.254  (IP pubblico)
A     | www.example.com   | 198.51.100.254  (IP pubblico)
A     | mail.example.com  | 198.51.100.254  (IP pubblico)
MX    | example.com       | mail.example.com (priority 10)
NS    | example.com       | ns1.example.com
A     | ns1.example.com   | 198.51.100.254
TXT   | example.com       | "v=spf1 mx ~all"
```

### Zone Reverse (PTR Records)

```
Zona: 100.51.198.in-addr.arpa
PTR: 254.100.51.198.in-addr.arpa → www.example.com
```

### DNS Forwarders (Per Query Non Autoritative)

```
Forwarder 1: 8.8.8.8 (Google DNS)
Forwarder 2: 1.1.1.1 (Cloudflare DNS)
```

---

## Parte 5: Configurazione DNS-LAN (Interno)

### Setup Server DNS-LAN

1. Aggiungere **Server** in LAN
2. Configurare networking:
   - IP: 172.16.0.100
   - Mask: 255.255.255.0
   - Gateway: 172.16.0.1

3. Abilitare **DNS Service**

### Zone Forward - example.com (Vista Interna)

**Records DNS interni (IP privati!):**

```
Tipo  | Nome              | Indirizzo
------|-------------------|-------------------
A     | example.com       | 10.0.1.10  (IP privato DMZ)
A     | www.example.com   | 10.0.1.10  (IP privato DMZ)
A     | mail.example.com  | 10.0.1.20  (IP privato mail)
A     | dns.example.com   | 10.0.1.30  (IP privato DNS-DMZ)
MX    | example.com       | mail.example.com
```

### Zone Interna - lan.example.com

```
Tipo  | Nome                  | Indirizzo
------|-----------------------|----------------
A     | dns-lan.lan.example.com  | 172.16.0.100
A     | pc1.lan.example.com      | 172.16.0.11
A     | pc2.lan.example.com      | 172.16.0.12
```

### DNS Forwarders

```
Forwarder 1: 10.0.1.30 (DNS-DMZ per query esterne)
Forwarder 2: 8.8.8.8 (Backup)
```

---

## Parte 6: Configuration PC Client

### PC-User1 DNS Settings

1. Cliccare **PC-User1** → **Desktop** → **IP Configuration**
2. Impostare:
   ```
   IP Address: 172.16.0.11
   Subnet Mask: 255.255.255.0
   Default Gateway: 172.16.0.1
   DNS Server: 172.16.0.100  ← DNS-LAN!
   ```

### PC-User2 DNS Settings

Configurare analogamente con DNS: 172.16.0.100

---

## Parte 7: Test Split-Brain

### Test 1: Query Interna per www.example.com

**Da PC-User1:**
```
PC> nslookup www.example.com
```

**Output atteso:**
```
Server: 172.16.0.100 (DNS-LAN)
Name: www.example.com
Address: 10.0.1.10  ← IP PRIVATO!
```

✅ **Risultato:** Client interno riceve IP privato della DMZ

### Test 2: Query Esterna per www.example.com

**Da PC in Internet (simulato):**
```
Internet-PC> nslookup www.example.com 198.51.100.254
```

**Output atteso:**
```
Server: 198.51.100.254 (DNS-DMZ)
Name: www.example.com
Address: 198.51.100.254  ← IP PUBBLICO!
```

✅ **Risultato:** Client esterno riceve IP pubblico NAT

### Test 3: Query per Dominio Esterno (google.com)

**Da PC-User1:**
```
PC> nslookup google.com
```

**Flow:**
1. PC → DNS-LAN (172.16.0.100)
2. DNS-LAN forward → DNS-DMZ (10.0.1.30)
3. DNS-DMZ forward → Google DNS (8.8.8.8)
4. Response back

✅ **Risultato:** Forwarding funziona, risolve domini esterni

### Test 4: Record MX (Mail Exchange)

```
PC> nslookup -type=MX example.com
```

**Output atteso:**
```
example.com mail exchanger = 10 mail.example.com
mail.example.com = 10.0.1.20
```

### Test 5: Reverse DNS (PTR)

```
PC> nslookup 10.0.1.10
```

**Output atteso:**
```
10.0.1.10 name = www.example.com
```

---

## Parte 8: Web Browser Test

### Test HTTP con Nome Dominio

**Da PC-User1:**
1. Aprire **Web Browser**
2. Andare a: `http://www.example.com`

**Cosa succede:**
1. Browser richiede risoluzione DNS
2. DNS-LAN risponde: 10.0.1.10
3. Browser connette direttamente a 10.0.1.10 (no NAT needed!)
4. Pagina caricata

✅ **Vantaggio Split-Brain:** Traffico interno resta interno, più veloce!

---

## Parte 9: Verifica e Debug

### Verificare DNS Server Status

```cisco
FW-DNS# show ip nat translations

! Vedere traduzioni DNS
tcp 198.51.100.254:53  10.0.1.30:53   ---                ---
udp 198.51.100.254:53  10.0.1.30:53   ---                ---
```

### Test Connettività DNS

```cisco
! Ping al DNS-DMZ
FW-DNS# ping 10.0.1.30

! Ping al DNS-LAN
FW-DNS# ping 172.16.0.100

! Test DNS query dal router
FW-DNS# nslookup www.example.com 10.0.1.30
```

### Verificare ACL

```cisco
! Vedere hit count su ACL DNS
FW-DNS# show ip access-lists INTERNET-TO-DMZ | include 53

! Log DNS access
FW-DNS# show logging | include 10.0.1.30
```

---

## Parte 10: DNS Security

### Threat 1: DNS Poisoning

**Attacco:** Inserire record falsi nella cache DNS

**Mitigazione:**
```
✅ DNSSEC (DNS Security Extensions) - firma crittografica
✅ Query randomization (source port randomization)
✅ Limitare zone transfer (solo DNS secondari autorizzati)
✅ Firewall blocca TCP/53 da Internet (eccetto server autorizzati)
```

### Threat 2: DNS Amplification Attack

**Attacco:** Query DNS con IP spoofato per DDoS

**Mitigazione ACL:**

```cisco
FW-DNS(config)# ip access-list extended DNS-RATE-LIMIT

! Rate limit query da singolo IP (simulazione)
FW-DNS(config-ext-nacl)# remark === Anti-Amplification ===
! In produzione: usare Zone-Based FW con rate-limiting
FW-DNS(config-ext-nacl)# permit udp any host 10.0.1.30 eq 53
```

### Threat 3: Zone Transfer Leak

**Problema:** Hacker scarica tutta la zona DNS → mappa rete

**Protezione già implementata:**
```cisco
! ACL blocca TCP/53 da Internet
deny tcp any host 10.0.1.30 eq 53 log
```

**In produzione:**
```
✅ TSIG (Transaction Signature) per zone transfer
✅ Whitelist IP DNS secondari
✅ VPN per AXFR (full zone transfer)
```

### Configurazione DNSSEC (Teoria)

```
# In ambiente reale (Bind9 example)
dnssec-enable yes;
dnssec-validation yes;
dnssec-lookaside auto;

# Generate keys
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com
dnssec-signzone -o example.com db.example.com
```

---

## Parte 11: Best Practices

### 1. Separazione DNS Interno/Esterno ✅
- DNS-DMZ → solo zone pubbliche
- DNS-LAN → zone interne + forwarding

### 2. Minimal Information Disclosure
```
✅ DNS esterno: SOLO servizi pubblici (www, mail)
❌ DNS esterno: NO server amministrativi, DB, interni
```

### 3. DNS Redundancy
```
✅ Almeno 2 DNS server (primary + secondary)
✅ Geographic distribution
✅ Different networks
```

### 4. Monitoring
```
✅ Log tutte le query
✅ Alert su query anomale (TXT, ANY)
✅ Monitor query rate (spike = possible attack)
```

### 5. Regular Updates
```
✅ Patch DNS software (BIND, PowerDNS, etc.)
✅ Update zone files
✅ Rotate DNSSEC keys
```

---

## Parte 12: Troubleshooting DNS

### Problema: nslookup Non Funziona

**Sintomi:**
```
PC> nslookup www.example.com
DNS request timed out
```

**Checklist:**
1. ✅ DNS server configurato su PC?
2. ✅ Ping al DNS server?
3. ✅ Firewall permette UDP/53?
4. ✅ DNS service attivo su server?

**Test:**
```cisco
! Da router
FW-DNS# ping 172.16.0.100
FW-DNS# telnet 172.16.0.100 53
```

### Problema: Split-Brain Non Funziona

**Sintomi:** Client interni ricevono IP pubblico invece di privato

**Causa:** Client usa DNS-DMZ invece di DNS-LAN

**Soluzione:**
```
PC → IP Configuration → DNS Server: 172.16.0.100
(non 10.0.1.30!)
```

### Problema: Forwarding Non Funziona

**Sintomi:** www.google.com non si risolve

**Causa:** DNS-DMZ non può uscire verso Internet

**Verifica:**
```cisco
FW-DNS# show ip access-lists DMZ-TO-INTERNET
! Verificare:
permit udp host 10.0.1.30 any eq 53
```

---

## Conclusioni

🎉 **Hai completato:**
- ✅ DNS split-brain architecture
- ✅ DNS-DMZ per query pubbliche
- ✅ DNS-LAN per query interne
- ✅ Zone forward e reverse
- ✅ DNS forwarding configuration
- ✅ ACL per DNS security
- ✅ Anti-poisoning e anti-DDoS basics
- ✅ Test complete di risoluzione

### Riepilogo Architettura

```
Query Interna:
PC → DNS-LAN → Risposta IP privato (10.0.1.x)

Query Esterna:
Internet → FW (NAT) → DNS-DMZ → Risposta IP pubblico (198.51.100.254)

Forwarding:
DNS-LAN → DNS-DMZ → Google DNS (8.8.8.8)
```

### Key Takeaways
- **Split-Brain:** Vista diversa interna/esterna
- **Performance:** Traffico interno non passa per NAT
- **Security:** DNS-DMZ = minimal disclosure
- **Resilienza:** Forwarding a più DNS pubblici
- **Monitoring:** Log e rate limiting

### Prossimi Passi
- **LAB 3.1:** ACL avanzate per DMZ
- **LAB 4.1:** Syslog per DNS monitoring
- **LAB Avanzato:** DNSSEC implementation

---

**Salvare:** File → Save As → `lab2.3-dns-split-brain.pkt`

**Fine Laboratorio 2.3**
