# LAB 3.1 - ACL Standard e Extended per DMZ

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**File da creare:** `lab3.1-acl-dmz.pkt`  
**Prerequisiti:** LAB 1.1

---

## Obiettivi del Laboratorio
- Comprendere differenza tra ACL standard e extended
- Creare ACL per controllo base e granulare
- Applicare ACL alle interfacce corrette (in/out)
- Implementare policy di sicurezza complesse
- Debuggare e troubleshoot ACL

---

## Concetti: ACL Standard vs Extended

### ACL Standard (1-99, 1300-1999)
- Filtrano solo su **IP sorgente**
- Posizionare **vicino alla destinazione**
- Sintassi: `access-list [numero] [permit|deny] [source] [wildcard]`

### ACL Extended (100-199, 2000-2699)
- Filtrano su: **IP sorgente, IP destinazione, protocollo, porta**
- Posizionare **vicino alla sorgente**
- Sintassi: `access-list [numero] [permit|deny] [protocol] [source] [dest] [ports]`

---

## Topologia

```
                    [Router/Firewall]
                   /        |        \
              G0/0 (WAN)  G0/1 (DMZ)  G0/2 (LAN)
                 |           |            |
            [Internet]   [Switch-DMZ]  [Switch-LAN]
            192.0.2.2         |              |
                        10.0.1.10      172.16.0.0/24
                        10.0.1.20         |
                        10.0.1.30         |
                            |             |
                    [Web-Srv]         [PC-Admin]     172.16.0.10
                    [Mail-Srv]        [PC-User1]     172.16.0.11
                    [DNS-Srv]         [PC-User2]     172.16.0.12
```

---

## Parte 1: Setup Topologia Base

### Piano IP Completo

| Dispositivo | IP | Mask | Gateway | Ruolo |
|-------------|----|------|---------|-------|
| FW G0/0 | 192.0.2.1 | /30 | - | WAN |
| FW G0/1 | 10.0.1.1 | /24 | - | DMZ |
| FW G0/2 | 172.16.0.1 | /24 | - | LAN |
| Internet | 192.0.2.2 | /30 | - | Simula Internet |
| Web-Srv | 10.0.1.10 | /24 | 10.0.1.1 | HTTP/HTTPS |
| Mail-Srv | 10.0.1.20 | /24 | 10.0.1.1 | SMTP/IMAP |
| DNS-Srv | 10.0.1.30 | /24 | 10.0.1.1 | DNS |
| PC-Admin | 172.16.0.10 | /24 | 172.16.0.1 | Administrator |
| PC-User1 | 172.16.0.11 | /24 | 172.16.0.1 | Normal User |
| PC-User2 | 172.16.0.12 | /24 | 172.16.0.1 | Normal User |

### Configurazione Router Base

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-ACL
FW-ACL(config)#

! Interfacce
FW-ACL(config)# interface GigabitEthernet 0/0
FW-ACL(config-if)# description WAN
FW-ACL(config-if)# ip address 192.0.2.1 255.255.255.252
FW-ACL(config-if)# no shutdown
FW-ACL(config-if)# exit

FW-ACL(config)# interface GigabitEthernet 0/1
FW-ACL(config-if)# description DMZ
FW-ACL(config-if)# ip address 10.0.1.1 255.255.255.0
FW-ACL(config-if)# no shutdown
FW-ACL(config-if)# exit

FW-ACL(config)# interface GigabitEthernet 0/2
FW-ACL(config-if)# description LAN
FW-ACL(config-if)# ip address 172.16.0.1 255.255.255.0
FW-ACL(config-if)# no shutdown
FW-ACL(config-if)# exit

! Routing
FW-ACL(config)# ip route 0.0.0.0 0.0.0.0 192.0.2.2
```

---

## Parte 2: ACL Standard - Esempi Base

### Scenario 1: Permettere Solo PC-Admin alla DMZ

**Requisito:** Solo il PC amministratore (172.16.0.10) può gestire server DMZ via SSH.

```cisco
! ACL Standard (filtra solo source)
FW-ACL(config)# access-list 10 remark *** Allow Admin Only ***
FW-ACL(config)# access-list 10 permit host 172.16.0.10
FW-ACL(config)# access-list 10 deny any log

! Applicare in ingresso su interfaccia LAN
FW-ACL(config)# interface GigabitEthernet 0/2
FW-ACL(config-if)# ip access-group 10 in
FW-ACL(config-if)# exit
```

**Problema con questo approccio:** Blocca TUTTO il traffico da User1 e User2, anche verso Internet!

### Scenario 2: Filtrare Solo Traffico LAN → DMZ

**Soluzione migliore: ACL Extended**

```cisco
! Rimuovere ACL standard
FW-ACL(config)# interface GigabitEthernet 0/2
FW-ACL(config-if)# no ip access-group 10 in
FW-ACL(config-if)# exit

! Usare Extended ACL
FW-ACL(config)# ip access-list extended ADMIN-SSH-DMZ

! Permettere SSH da Admin a DMZ
FW-ACL(config-ext-nacl)# permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq 22

! Permettere altri traffico LAN
FW-ACL(config-ext-nacl)# permit ip 172.16.0.0 0.0.0.255 any

FW-ACL(config-ext-nacl)# exit

! Applicare
FW-ACL(config)# interface GigabitEthernet 0/2
FW-ACL(config-if)# ip access-group ADMIN-SSH-DMZ in
```

---

## Parte 3: ACL Extended - Policy Complesse

### Scenario 3: Internet → DMZ (Servizi Pubblici)

**Policy:**
- ✅ HTTP/HTTPS → Web Server (10.0.1.10)
- ✅ SMTP → Mail Server (10.0.1.20)
- ✅ DNS queries → DNS Server (10.0.1.30)
- ❌ Bloccare tutto il resto

```cisco
FW-ACL(config)# ip access-list extended INTERNET-TO-DMZ

! HTTP al web server
FW-ACL(config-ext-nacl)# remark === Web Server Rules ===
FW-ACL(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80
FW-ACL(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! SMTP al mail server
FW-ACL(config-ext-nacl)# remark === Mail Server Rules ===
FW-ACL(config-ext-nacl)# permit tcp any host 10.0.1.20 eq 25

! DNS al DNS server
FW-ACL(config-ext-nacl)# remark === DNS Server Rules ===
FW-ACL(config-ext-nacl)# permit udp any host 10.0.1.30 eq 53
FW-ACL(config-ext-nacl)# permit tcp any host 10.0.1.30 eq 53

! Permettere traffico established (risposte)
FW-ACL(config-ext-nacl)# remark === Return Traffic ===
FW-ACL(config-ext-nacl)# permit tcp any any established

! Permettere ICMP echo-reply (risposta ping)
FW-ACL(config-ext-nacl)# permit icmp any any echo-reply

! Bloccare e loggare tutto il resto
FW-ACL(config-ext-nacl)# remark === Deny All ===
FW-ACL(config-ext-nacl)# deny ip any any log

FW-ACL(config-ext-nacl)# exit

! Applicare in ingresso su WAN
FW-ACL(config)# interface GigabitEthernet 0/0
FW-ACL(config-if)# ip access-group INTERNET-TO-DMZ in
FW-ACL(config-if)# exit
```

### Scenario 4: LAN → DMZ (Accesso Selettivo)

**Policy:**
- ✅ Admin può SSH a tutti i server DMZ
- ✅ Users possono HTTP/HTTPS al Web Server
- ✅ Users possono IMAP/POP3 al Mail Server
- ✅ Users possono DNS al DNS Server
- ❌ Users NON possono SSH, FTP, Telnet

```cisco
FW-ACL(config)# ip access-list extended LAN-TO-DMZ

! === ADMIN RIGHTS ===
FW-ACL(config-ext-nacl)# remark === Admin Full Access ===
FW-ACL(config-ext-nacl)# permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq 22
FW-ACL(config-ext-nacl)# permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq telnet
FW-ACL(config-ext-nacl)# permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq ftp
FW-ACL(config-ext-nacl)# permit icmp host 172.16.0.10 10.0.1.0 0.0.0.255

! === USER RIGHTS ===
FW-ACL(config-ext-nacl)# remark === Users Web Access ===
FW-ACL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.10 eq 80
FW-ACL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.10 eq 443

FW-ACL(config-ext-nacl)# remark === Users Mail Access ===
FW-ACL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 110
FW-ACL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 143
FW-ACL(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.20 eq 25

FW-ACL(config-ext-nacl)# remark === Users DNS Access ===
FW-ACL(config-ext-nacl)# permit udp 172.16.0.0 0.0.0.255 host 10.0.1.30 eq 53

! Permettere return traffic
FW-ACL(config-ext-nacl)# permit tcp any any established
FW-ACL(config-ext-nacl)# permit icmp any any echo-reply

! Bloccare accessi amministrativi da Users
FW-ACL(config-ext-nacl)# remark === Block Admin Protocols ===
FW-ACL(config-ext-nacl)# deny tcp 172.16.0.11 0.0.0.0 10.0.1.0 0.0.0.255 eq 22 log
FW-ACL(config-ext-nacl)# deny tcp 172.16.0.12 0.0.0.0 10.0.1.0 0.0.0.255 eq 22 log

! Default permit to Internet
FW-ACL(config-ext-nacl)# permit ip 172.16.0.0 0.0.0.255 any

FW-ACL(config-ext-nacl)# exit

! Applicare
FW-ACL(config)# interface GigabitEthernet 0/2
FW-ACL(config-if)# ip access-group LAN-TO-DMZ in
FW-ACL(config-if)# exit
```

### Scenario 5: DMZ → LAN (Contenimento)

**Policy:** BLOCCARE tutto il traffico dalla DMZ verso LAN (critical!)

```cisco
FW-ACL(config)# ip access-list extended DMZ-TO-LAN-BLOCK

! Bloccare tutto dalla DMZ verso LAN
FW-ACL(config-ext-nacl)# remark === DMZ Containment ===
FW-ACL(config-ext-nacl)# deny ip 10.0.1.0 0.0.0.255 172.16.0.0 0.0.0.255 log

! Permettere established (risposte a connessioni LAN)
FW-ACL(config-ext-nacl)# permit tcp any any established

! Permettere resto (DMZ → Internet OK)
FW-ACL(config-ext-nacl)# permit ip any any

FW-ACL(config-ext-nacl)# exit

! Applicare in uscita su DMZ
FW-ACL(config)# interface GigabitEthernet 0/1
FW-ACL(config-if)# ip access-group DMZ-TO-LAN-BLOCK out
FW-ACL(config-if)# exit
```

---

## Parte 4: ACL con Time-Based (Opzionale)

### Scenario 6: Limitare Accesso SSH negli Orari Lavorativi

```cisco
! Creare time-range
FW-ACL(config)# time-range BUSINESS-HOURS
FW-ACL(config-time-range)# periodic weekdays 08:00 to 18:00
FW-ACL(config-time-range)# exit

! ACL con time-range
FW-ACL(config)# ip access-list extended SSH-TIME-RESTRICT

! SSH permesso solo in orario lavorativo
FW-ACL(config-ext-nacl)# permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq 22 time-range BUSINESS-HOURS

! Fuori orario: deny
FW-ACL(config-ext-nacl)# deny tcp any 10.0.1.0 0.0.0.255 eq 22 log

FW-ACL(config-ext-nacl)# permit ip any any

FW-ACL(config-ext-nacl)# exit
```

---

## Parte 5: Named ACL (Best Practice)

### Vantaggi Named ACL
- **Nome descrittivo** invece di numero
- Possibilità di **inserire/rimuovere** entry specifiche
- Più facile da **documentare e mantenere**

### Esempio Named ACL

```cisco
FW-ACL(config)# ip access-list extended WEB-SERVER-PROTECTION

! Entry con sequence number (per editing)
FW-ACL(config-ext-nacl)# 10 permit tcp any host 10.0.1.10 eq 80
FW-ACL(config-ext-nacl)# 20 permit tcp any host 10.0.1.10 eq 443
FW-ACL(config-ext-nacl)# 30 deny tcp any host 10.0.1.10 range 1 1023 log
FW-ACL(config-ext-nacl)# 40 permit tcp any any established
FW-ACL(config-ext-nacl)# 50 deny ip any any log

FW-ACL(config-ext-nacl)# exit

! Modificare entry esistente
FW-ACL(config)# ip access-list extended WEB-SERVER-PROTECTION

! Inserire nuova entry tra 20 e 30
FW-ACL(config-ext-nacl)# 25 permit tcp any host 10.0.1.10 eq 8080

! Rimuovere entry specifica
FW-ACL(config-ext-nacl)# no 30

! Visualizzare con sequence numbers
FW-ACL# show ip access-lists WEB-SERVER-PROTECTION
```

---

## Parte 6: Test e Verifica

### Test 1: Admin SSH a Web Server ✅

```
PC-Admin > ssh 10.0.1.10
```
**Risultato atteso:** ✅ Connessione permessa

### Test 2: User1 SSH a Web Server ❌

```
PC-User1 > ssh 10.0.1.10
```
**Risultato atteso:** ❌ Bloccato (logged)

### Test 3: User1 HTTP a Web Server ✅

```
PC-User1 > Web Browser → http://10.0.1.10
```
**Risultato atteso:** ✅ Permesso

### Test 4: DMZ → LAN Ping ❌

```
Web-Srv > ping 172.16.0.10
```
**Risultato atteso:** ❌ Bloccato (contenimento DMZ)

### Test 5: LAN → Internet ✅

```
PC-User1 > ping 192.0.2.2
```
**Risultato atteso:** ✅ Permesso (default permit)

---

## Parte 7: Verifica e Debug ACL

### Comandi Verifica

```cisco
! Visualizzare tutte le ACL
FW-ACL# show access-lists

! Visualizzare ACL specifica
FW-ACL# show access-lists INTERNET-TO-DMZ

! Vedere hit count (quante volte regola applicata)
FW-ACL# show access-lists | include matches

! ACL applicate a interfacce
FW-ACL# show ip interface GigabitEthernet 0/0
FW-ACL# show ip interface GigabitEthernet 0/1

! Vedere tutte le applicazioni ACL
FW-ACL# show ip interface | include access list
```

### Debug ACL (Use with Caution!)

```cisco
! Abilitare debug
FW-ACL# debug ip packet detail
FW-ACL# debug ip packet [ACL-number]

! Disabilitare debug
FW-ACL# no debug all
FW-ACL# undebug all
```

### Visualizzare Log

```cisco
! Vedere log buffer
FW-ACL# show logging

! Filtrare log per IP specifico
FW-ACL# show logging | include 172.16.0.11
```

---

## Parte 8: Best Practices ACL

### Regole d'Oro

1. **Ordine Matters!** ACL elaborate top-down, prima match vince
2. **Implicit Deny:** Alla fine c'è sempre `deny ip any any`
3. **Più specifico prima:** Entry specifiche prima di generiche
4. **Near destination** per Standard ACL
5. **Near source** per Extended ACL
6. **Use Named ACL:** Più facile da gestire
7. **Document with remarks:** Commenta ogni sezione
8. **Test incrementalmente:** Applica e testa una regola alla volta

### Esempio ACL Ben Strutturata

```cisco
ip access-list extended BEST-PRACTICE-ACL
 !
 remark ========================================
 remark  Section 1: Critical Services
 remark ========================================
 !
 remark Allow HTTPS to Web Server
 10 permit tcp any host 10.0.1.10 eq 443
 !
 remark Allow SMTP to Mail Server
 20 permit tcp any host 10.0.1.20 eq 25
 !
 remark ========================================
 remark  Section 2: Administrative Access
 remark ========================================
 !
 remark Admin SSH to DMZ
 30 permit tcp host 172.16.0.10 10.0.1.0 0.0.0.255 eq 22
 !
 remark ========================================
 remark  Section 3: Return Traffic
 remark ========================================
 !
 40 permit tcp any any established
 50 permit icmp any any echo-reply
 !
 remark ========================================
 remark  Section 4: Deny and Log
 remark ========================================
 !
 remark Block and log suspicious ports
 60 deny tcp any any range 135 139 log
 70 deny tcp any any eq 445 log
 !
 remark Default deny all
 80 deny ip any any log
```

---

## Parte 9: Common Mistakes

### Errore 1: ACL Applicata Direzione Sbagliata

```cisco
! SBAGLIATO
interface GigabitEthernet 0/0
 ip access-group INTERNET-TO-DMZ out  ❌

! CORRETTO
interface GigabitEthernet 0/0
 ip access-group INTERNET-TO-DMZ in   ✅
```

### Errore 2: Permit Troppo Permissivo

```cisco
! SBAGLIATO - Troppo ampio
permit ip any any  ❌

! CORRETTO - Specifico
permit tcp 172.16.0.0 0.0.0.255 10.0.1.10 0.0.0.0 eq 80  ✅
```

### Errore 3: Dimenticare Established

```cisco
! SBAGLIATO - Blocca risposte
deny ip any any  ❌

! CORRETTO - Permetti return traffic
permit tcp any any established
deny ip any any  ✅
```

### Errore 4: Wildcard Mask Errata

```cisco
! SBAGLIATO
permit ip 172.16.0.0 255.255.255.0  ❌ (subnet mask!)

! CORRETTO
permit ip 172.16.0.0 0.0.0.255      ✅ (wildcard mask!)
```

---

## Parte 10: ACL Performance Tips

### Ottimizzazione

1. **Regole più usate in cima:** Riduci CPU overhead
2. **Evita log eccessivo:** Log solo eventi critici
3. **Usa hardware ACL quando possibile:** TCAM
4. **Consolida regole:** Meno entry = più veloce

### Esempio Ottimizzato

```cisco
! BEFORE (3 entry)
permit tcp any host 10.0.1.10 eq 80
permit tcp any host 10.0.1.10 eq 443
permit tcp any host 10.0.1.10 eq 8080

! AFTER (1 entry con range)
permit tcp any host 10.0.1.10 range 80 8080
```

---

## Conclusioni

🎉 **Congratulazioni!** Hai completato:
- ✅ ACL Standard per filtering sorgente
- ✅ ACL Extended per controllo granulare
- ✅ Named ACL per gestione migliore
- ✅ Time-based ACL
- ✅ Policy complesse multi-layer
- ✅ Best practices e troubleshooting

### Riepilogo ACL Create

| ACL Name | Tipo | Scopo | Interfaccia |
|----------|------|-------|-------------|
| INTERNET-TO-DMZ | Extended | Filtrare Internet | G0/0 in |
| LAN-TO-DMZ | Extended | Controllo accessi LAN | G0/2 in |
| DMZ-TO-LAN-BLOCK | Extended | Contenimento DMZ | G0/1 out |
| ADMIN-SSH-DMZ | Extended | SSH admin only | G0/2 in |

### Key Takeaways
- **Standard ACL:** Solo source, near destination
- **Extended ACL:** Source+Dest+Protocol+Port, near source
- **Named ACL:** Best practice per gestione
- **Order Matters:** Top-down processing
- **Document:** Sempre usare `remark`
- **Test:** Incrementale, non tutto insieme

### Prossimi Passi
- **LAB 3.2:** Zone-Based Firewall (ZBPF)
- **LAB 3.3:** Reflexive ACL
- **LAB 4.x:** IDS/IPS integration

---

**Salvare:** File → Save As → `lab3.1-acl-dmz.pkt`

**Fine Laboratorio 3.1**
