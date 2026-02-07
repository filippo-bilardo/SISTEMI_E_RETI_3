# LAB 2.2 - Mail Server in DMZ (SMTP/IMAP/POP3)

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**File da creare:** `lab2.2-mail-server-dmz.pkt`  
**Prerequisiti:** LAB 1.1, LAB 2.1

---

## Obiettivi del Laboratorio
- Configurare mail server con protocolli SMTP, IMAP, POP3
- Implementare port forwarding per servizi mail multipli
- Configurare mail client su LAN
- Implementare relay controlli e sicurezza
- Testare invio/ricezione email interne ed esterne
- Configurare split DNS per mail interno/esterno

---

## Protocolli Mail Essenziali

### SMTP (Simple Mail Transfer Protocol)
- **Porta:** 25 (standard), 587 (submission), 465 (SMTPS deprecated)
- **Scopo:** Invio mail (client → server, server → server)
- **Direzione:** Outbound e inter-server

### IMAP (Internet Message Access Protocol)
- **Porta:** 143 (plain), 993 (IMAPS/TLS)
- **Scopo:** Lettura mail con sync multi-device
- **Feature:** Mail rimangono sul server

### POP3 (Post Office Protocol v3)
- **Porta:** 110 (plain), 995 (POP3S/TLS)
- **Scopo:** Download mail (legacy)
- **Feature:** Mail scaricate e cancellate dal server

---

## Topologia

```
                        [Router/Firewall]
                       /        |        \
                  G0/0 (WAN) G0/1 (DMZ) G0/2 (LAN)
                     |           |            |
              [Cloud Internet] [Switch]    [Switch]
              198.51.100.1        |            |
                            10.0.1.20      172.16.0.0/24
                                  |             |
                          [Mail-Server]    [PC-User1]  172.16.0.11
                                          [PC-User2]  172.16.0.12
                                          [PC-Admin]  172.16.0.10
```

---

## Parte 1: Configurazione Router Base

### Piano IP

| Dispositivo | IP | Mask | Gateway | Servizi |
|-------------|----|------|---------|---------|
| FW G0/0 | 198.51.100.254 | /24 | - | WAN |
| FW G0/1 | 10.0.1.1 | /24 | - | DMZ |
| FW G0/2 | 172.16.0.1 | /24 | - | LAN |
| Mail-Srv | 10.0.1.20 | /24 | 10.0.1.1 | SMTP/IMAP/POP3 |
| PC-User1 | 172.16.0.11 | /24 | 172.16.0.1 | Mail client |
| PC-User2 | 172.16.0.12 | /24 | 172.16.0.1 | Mail client |
| PC-Admin | 172.16.0.10 | /24 | 172.16.0.1 | Admin |
| Internet | 198.51.100.1 | /24 | - | External mail |

### Configurazione Interfacce

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-MAIL
FW-MAIL(config)#

! WAN Interface
FW-MAIL(config)# interface GigabitEthernet 0/0
FW-MAIL(config-if)# description WAN-INTERNET
FW-MAIL(config-if)# ip address 198.51.100.254 255.255.255.0
FW-MAIL(config-if)# no shutdown
FW-MAIL(config-if)# exit

! DMZ Interface
FW-MAIL(config)# interface GigabitEthernet 0/1
FW-MAIL(config-if)# description DMZ-MAIL
FW-MAIL(config-if)# ip address 10.0.1.1 255.255.255.0
FW-MAIL(config-if)# no shutdown
FW-MAIL(config-if)# exit

! LAN Interface
FW-MAIL(config)# interface GigabitEthernet 0/2
FW-MAIL(config-if)# description LAN
FW-MAIL(config-if)# ip address 172.16.0.1 255.255.255.0
FW-MAIL(config-if)# no shutdown
FW-MAIL(config-if)# exit

! Default route
FW-MAIL(config)# ip route 0.0.0.0 0.0.0.0 198.51.100.1
```

---

## Parte 2: Port Forwarding per Mail Server

### NAT Configuration

```cisco
! Inside interfaces
FW-MAIL(config)# interface GigabitEthernet 0/1
FW-MAIL(config-if)# ip nat inside
FW-MAIL(config-if)# exit

FW-MAIL(config)# interface GigabitEthernet 0/2
FW-MAIL(config-if)# ip nat inside
FW-MAIL(config-if)# exit

! Outside interface
FW-MAIL(config)# interface GigabitEthernet 0/0
FW-MAIL(config-if)# ip nat outside
FW-MAIL(config-if)# exit

! Static NAT per SMTP (porta 25)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 25 198.51.100.254 25

! Static NAT per SMTP Submission (porta 587)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 587 198.51.100.254 587

! Static NAT per IMAP (porta 143)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 143 198.51.100.254 143

! Static NAT per IMAPS (porta 993 - secure)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 993 198.51.100.254 993

! Static NAT per POP3 (porta 110)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 110 198.51.100.254 110

! Static NAT per POP3S (porta 995 - secure)
FW-MAIL(config)# ip nat inside source static tcp 10.0.1.20 995 198.51.100.254 995

! PAT per traffico LAN
FW-MAIL(config)# ip nat inside source list LAN-NAT interface GigabitEthernet 0/0 overload

FW-MAIL(config)# access-list 1 remark LAN-NAT
FW-MAIL(config)# access-list 1 permit 172.16.0.0 0.0.0.255
```

---

## Parte 3: ACL per Sicurezza Mail

### ACL Internet → DMZ (Inbound Mail)

```cisco
FW-MAIL(config)# ip access-list extended INTERNET-TO-MAIL

! Permettere SMTP in ingresso (ricezione mail)
FW-MAIL(config-ext-nacl)# remark === Inbound Mail ===
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25

! Permettere SMTP submission (client autenticati)
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 587

! Permettere IMAP/IMAPS per accesso webmail esterno
FW-MAIL(config-ext-nacl)# remark === Remote Mail Access ===
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 143
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 993

! Permettere POP3/POP3S
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 110
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 995

! Return traffic
FW-MAIL(config-ext-nacl)# permit tcp any any established
FW-MAIL(config-ext-nacl)# permit icmp any any echo-reply

! Deny e log
FW-MAIL(config-ext-nacl)# deny ip any any log

FW-MAIL(config-ext-nacl)# exit

! Applicare ACL
FW-MAIL(config)# interface GigabitEthernet 0/0
FW-MAIL(config-if)# ip access-group INTERNET-TO-MAIL in
FW-MAIL(config-if)# exit
```

### ACL LAN → DMZ (Mail Client Access)

```cisco
FW-MAIL(config)# ip access-list extended LAN-TO-MAIL

! Users possono accedere IMAP/POP3
FW-MAIL(config-ext-nacl)# remark === User Mail Access ===
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 143
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 993
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 110
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 995

! Users possono inviare via SMTP
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 25
FW-MAIL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 587

! Admin può SSH
FW-MAIL(config-ext-nacl)# remark === Admin Access ===
FW-MAIL(config-ext-nacl)# permit tcp host 172.16.0.10 host 10.0.1.20 eq 22

! Return traffic e Internet access
FW-MAIL(config-ext-nacl)# permit tcp any any established
FW-MAIL(config-ext-nacl)# permit ip 172.16.0.0 0.0.0.255 any

FW-MAIL(config-ext-nacl)# exit

FW-MAIL(config)# interface GigabitEthernet 0/2
FW-MAIL(config-if)# ip access-group LAN-TO-MAIL in
FW-MAIL(config-if)# exit
```

### ACL DMZ → Internet (Outbound Mail)

```cisco
FW-MAIL(config)# ip access-list extended DMZ-TO-INTERNET

! Mail server può inviare mail (SMTP relay)
FW-MAIL(config-ext-nacl)# remark === Outbound Mail ===
FW-MAIL(config-ext-nacl)# permit tcp host 10.0.1.20 any eq 25

! DNS queries
FW-MAIL(config-ext-nacl)# remark === DNS ===
FW-MAIL(config-ext-nacl)# permit udp host 10.0.1.20 any eq 53

! NTP per time sync (importante per mail!)
FW-MAIL(config-ext-nacl)# remark === NTP ===
FW-MAIL(config-ext-nacl)# permit udp host 10.0.1.20 any eq 123

! Return traffic
FW-MAIL(config-ext-nacl)# permit tcp any any established
FW-MAIL(config-ext-nacl)# permit icmp any any echo-reply

! Bloccare DMZ → LAN (contenimento!)
FW-MAIL(config-ext-nacl)# remark === DMZ Containment ===
FW-MAIL(config-ext-nacl)# deny ip 10.0.1.0 0.0.0.255 172.16.0.0 0.0.0.255 log

! Rest to Internet OK
FW-MAIL(config-ext-nacl)# permit ip any any

FW-MAIL(config-ext-nacl)# exit

FW-MAIL(config)# interface GigabitEthernet 0/1
FW-MAIL(config-if)# ip access-group DMZ-TO-INTERNET out
FW-MAIL(config-if)# exit
```

---

## Parte 4: Configurazione Mail Server (Packet Tracer)

### Setup Base Server

1. Aggiungere **Server** nella DMZ
2. Configurare networking:
   - IP: 10.0.1.20
   - Mask: 255.255.255.0
   - Gateway: 10.0.1.1

### Abilitare Servizi Mail

3. Cliccare sul server → **Services**
4. Abilitare **EMAIL** service:
   - Domain Name: `example.com`
   - Server Type: `Mail Server`

### Creare Mailbox Utenti

```
User: admin
Domain: example.com
Email: admin@example.com
Password: Admin123!

User: user1
Domain: example.com
Email: user1@example.com
Password: User1Pass

User: user2
Domain: example.com
Email: user2@example.com
Password: User2Pass
```

---

## Parte 5: Configurazione Mail Client (PC)

### PC-User1 Configuration

1. Cliccare **PC-User1** → **Desktop** → **Email**

**SMTP Settings (Invio):**
```
Outgoing Mail Server: 10.0.1.20
Port: 25 (o 587)
Email Address: user1@example.com
Username: user1
Password: User1Pass
```

**POP3 Settings (Ricezione - opzione 1):**
```
Incoming Mail Server: 10.0.1.20
Port: 110
Protocol: POP3
Username: user1
Password: User1Pass
```

**IMAP Settings (Ricezione - opzione 2, preferita):**
```
Incoming Mail Server: 10.0.1.20
Port: 143
Protocol: IMAP
Username: user1
Password: User1Pass
```

### PC-User2 Configuration

Ripetere configurazione per user2@example.com

---

## Parte 6: Test Scenario

### Test 1: Mail Interna (User1 → User2)

**Da PC-User1:**
1. Aprire Email client
2. Click **Compose**
3. Compilare:
   ```
   To: user2@example.com
   Subject: Test Mail Interna
   Body: Questo è un test di mail interna nella LAN
   ```
4. Click **Send**

**Verifica da PC-User2:**
1. Click **Receive**
2. Verificare arrivo mail

✅ **Atteso:** Mail consegnata istantaneamente

### Test 2: Mail Esterna (Simulazione Internet → Mail Server)

**Simula mail da cloud Internet:**
1. Configurare PC in cloud Internet
2. Configurare mail client:
   ```
   SMTP: 198.51.100.254 (IP pubblico FW)
   Port: 25
   ```
3. Inviare mail a: `user1@example.com`

✅ **Atteso:** Mail arriva a User1 via port forwarding

### Test 3: Verifica IMAP Multi-Device

1. Configurare sia PC-User1 che PC-Admin con stesso account (user1)
2. Leggere mail da PC-User1 → lasciare segno "letta"
3. Accedere da PC-Admin
4. Verificare che mail sia già segnata come letta

✅ **Atteso:** Stato sincronizzato tra dispositivi (IMAP feature)

### Test 4: POP3 Download

1. Configurare PC-User2 con POP3
2. Ricevere mail
3. Verificare che mail sia scaricata localmente
4. Provare ad accedere da altro PC

✅ **Atteso:** Mail non più sul server (POP3 behavior)

---

## Parte 7: Verifica NAT e Port Forwarding

### Comandi Verifica

```cisco
! Visualizzare traduzioni NAT attive
FW-MAIL# show ip nat translations

! Output atteso:
Pro Inside global      Inside local       Outside local      Outside global
tcp 198.51.100.254:25  10.0.1.20:25       ---                ---
tcp 198.51.100.254:587 10.0.1.20:587      ---                ---
tcp 198.51.100.254:143 10.0.1.20:143      ---                ---
tcp 198.51.100.254:993 10.0.1.20:993      ---                ---
tcp 198.51.100.254:110 10.0.1.20:110      ---                ---
tcp 198.51.100.254:995 10.0.1.20:995      ---                ---

! Statistiche NAT
FW-MAIL# show ip nat statistics

! Verificare ACL hits
FW-MAIL# show ip access-lists INTERNET-TO-MAIL
```

---

## Parte 8: Troubleshooting Mail

### Problema 1: Mail Non Arriva

**Sintomi:** User1 non riceve mail da User2

**Checklist:**
```cisco
! 1. Verificare connectivity
FW-MAIL# ping 10.0.1.20

! 2. Telnet alla porta SMTP
PC> telnet 10.0.1.20 25

! Atteso: Banner SMTP
220 example.com SMTP Ready

! 3. Verificare firewall
FW-MAIL# show ip access-lists | include 10.0.1.20

! 4. Controllare mailbox server
Server → Services → Email → Users
```

### Problema 2: Authentication Failed

**Causa:** Username/Password errati

**Soluzione:**
1. Verificare credenziali su server
2. Case-sensitive: `User1` ≠ `user1`
3. Domain corretto: `example.com`

### Problema 3: Port Forwarding Non Funziona

```cisco
! Verificare NAT configuration
FW-MAIL# show running-config | include nat

! Verificare interfacce inside/outside
FW-MAIL# show ip interface brief

! Test da fuori
Internet-PC> telnet 198.51.100.254 25
```

### Problema 4: IMAP Non Sincronizza

**Causa:** Usato POP3 invece di IMAP

**Soluzione:**
- Cambiare protocollo da POP3 a IMAP
- Porta: 143 (plain) o 993 (secure)

---

## Parte 9: Hardening Mail Server

### Relay Controls

**Problema:** Open relay = server invia mail per chiunque = SPAM!

**Best Practice:**
```
✅ Accettare mail SOLO per domini locali (example.com)
✅ Richiedere autenticazione per invio (porta 587)
✅ Limitare rate (es. 100 mail/ora per user)
❌ MAI permettere relay anonimo
```

### ACL Anti-Spam

```cisco
FW-MAIL(config)# ip access-list extended SMTP-RATE-LIMIT

! Rate limit SMTP connections (simulazione)
FW-MAIL(config-ext-nacl)# remark === Rate Limiting ===
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25
! (In produzione: usare Zone-Based Firewall o IPS)
```

### Blacklist Integration (Teoria)

In ambiente reale:
```
- DNS Blacklist (DNSBL): Spamhaus, Barracuda
- SPF (Sender Policy Framework): Valida mittente
- DKIM (DomainKeys Identified Mail): Firma digitale
- DMARC (Domain-based Message Auth): Policy enforcement
```

---

## Parte 10: Split DNS per Mail (Avanzato)

### Concetto

**Problema:** Client interni ed esterni usano IP diversi
- **Interni:** Accedono a 10.0.1.20 (IP privato)
- **Esterni:** Accedono a 198.51.100.254 (IP pubblico)

**Soluzione:** DNS split-brain

### Configurazione DNS Interno (Simplified)

```
Internal DNS Server (LAN):
mail.example.com → 10.0.1.20

External DNS Server (Internet):
mail.example.com → 198.51.100.254
```

### MX Record Example

```dns
; External DNS Zone example.com
example.com.    IN  MX  10 mail.example.com.
mail            IN  A      198.51.100.254

; Internal DNS Zone example.com
example.com.    IN  MX  10 mail.example.com.
mail            IN  A      10.0.1.20
```

---

## Parte 11: Monitoring e Logging

### Enable Logging

```cisco
! Abilitare logging
FW-MAIL(config)# logging buffered 100000 informational
FW-MAIL(config)# logging console warnings

! Log mail access
FW-MAIL(config)# ip access-list extended MAIL-LOG
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25 log
FW-MAIL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 587 log
```

### Visualizzare Log Mail

```cisco
! Vedere tutti i log
FW-MAIL# show logging

! Filtrare per porta 25 (SMTP)
FW-MAIL# show logging | include 25

! Filtrare per IP specifico
FW-MAIL# show logging | include 198.51.100
```

---

## Conclusioni

🎉 **Hai completato:**
- ✅ Mail server con SMTP/IMAP/POP3
- ✅ Port forwarding multi-porta
- ✅ ACL per sicurezza mail
- ✅ Mail client configuration
- ✅ Test mail interne/esterne
- ✅ Troubleshooting mail issues
- ✅ Hardening e anti-spam basics
- ✅ Split DNS concepts

### Riepilogo Porte Mail

| Protocollo | Porta | Secure Port | Scopo |
|------------|-------|-------------|-------|
| SMTP | 25 | 465 (deprecated) | Transfer mail |
| SMTP Submission | 587 | - | Client send (auth) |
| POP3 | 110 | 995 (POP3S) | Download mail |
| IMAP | 143 | 993 (IMAPS) | Sync mail |

### Security Best Practices
- ✅ **TLS/SSL:** Usa sempre porte secure (993, 995, 587)
- ✅ **Authentication:** Richiedi auth per submission
- ✅ **Relay Control:** NO open relay
- ✅ **Rate Limiting:** Limita connessioni/mail
- ✅ **SPF/DKIM:** Implementa in produzione
- ✅ **Logging:** Log tutti gli accessi SMTP

### Prossimi Passi
- **LAB 2.3:** DNS Server in DMZ
- **LAB 3.1:** ACL granulari per mail
- **LAB 4.x:** Mail monitoring con Syslog

---

**Salvare:** File → Save As → `lab2.2-mail-server-dmz.pkt`

**Fine Laboratorio 2.2**
