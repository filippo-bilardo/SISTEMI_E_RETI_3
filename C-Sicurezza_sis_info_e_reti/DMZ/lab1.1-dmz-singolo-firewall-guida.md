# LAB 1.1 - DMZ con Singolo Firewall

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐ Base  
**Durata:** 2 ore  
**File da creare:** `lab1.1-dmz-singolo-firewall.pkt`

---

## Obiettivi del Laboratorio
- Comprendere la topologia a tre zone (Internet - DMZ - LAN)
- Configurare un router come firewall con ACL
- Implementare NAT/PAT
- Testare la connettività e sicurezza

---

## Topologia da Implementare

```
     [INTERNET]
         |
    192.0.2.1/30
         |
[G0/0]  R1  [G0/1]           [G0/2]
         |                      |
    10.0.1.1/24            172.16.0.1/24
         |                      |
    [Switch-DMZ]          [Switch-LAN]
         |                      |
    10.0.1.10/24          172.16.0.10/24
         |                  172.16.0.11/24
    [Web Server]          172.16.0.12/24
                               |
                          [PC-1] [PC-2] [PC-3]
```

---

## Parte 1: Creazione Topologia Fisica

### Step 1.1 - Aggiungere Dispositivi

1. **Apri Packet Tracer**
2. Aggiungi i seguenti dispositivi dalla barra in basso:
   
   **Router:**
   - 1x Router 2911 (R1)
   
   **Switch:**
   - 2x Switch 2960 (Switch-DMZ, Switch-LAN)
   
   **Server:**
   - 1x Server-PT (Web-Server)
   
   **PC:**
   - 3x PC-PT (PC-1, PC-2, PC-3)
   
   **Cloud (Simula Internet):**
   - 1x Cloud-PT (Internet)

3. **Rinomina i dispositivi** cliccando su ogni dispositivo e modificando il nome nel tab "Config"

### Step 1.2 - Collegare i Dispositivi

Usa cavi **Copper Straight-Through** per i seguenti collegamenti:

1. **Internet** → **R1 G0/0**
2. **R1 G0/1** → **Switch-DMZ FastEthernet 0/1**
3. **R1 G0/2** → **Switch-LAN FastEthernet 0/1**
4. **Switch-DMZ Fa0/2** → **Web-Server FastEthernet0**
5. **Switch-LAN Fa0/2** → **PC-1 FastEthernet0**
6. **Switch-LAN Fa0/3** → **PC-2 FastEthernet0**
7. **Switch-LAN Fa0/4** → **PC-3 FastEthernet0**

**Attendere che le interfacce diventino verdi** (potrebbero essere inizialmente arancioni).

---

## Parte 2: Configurazione Router R1

### Step 2.1 - Configurazione Interfacce

Clicca su **R1** → Tab **CLI** → Inserisci i seguenti comandi:

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname R1
R1(config)#

! Interfaccia verso Internet (WAN)
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# description *** WAN - Internet ***
R1(config-if)# ip address 192.0.2.1 255.255.255.252
R1(config-if)# no shutdown
R1(config-if)# exit

! Interfaccia verso DMZ
R1(config)# interface GigabitEthernet 0/1
R1(config-if)# description *** DMZ Network ***
R1(config-if)# ip address 10.0.1.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit

! Interfaccia verso LAN Interna
R1(config)# interface GigabitEthernet 0/2
R1(config-if)# description *** Internal LAN ***
R1(config-if)# ip address 172.16.0.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# exit
```

### Step 2.2 - Verifica Interfacce

```cisco
R1# show ip interface brief
```

**Output atteso:**
```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.0.2.1       YES manual up                    up
GigabitEthernet0/1     10.0.1.1        YES manual up                    up
GigabitEthernet0/2     172.16.0.1      YES manual up                    up
```

---

## Parte 3: Configurazione Web Server (DMZ)

### Step 3.1 - Configurazione IP

1. Clicca su **Web-Server**
2. Tab **Desktop** → **IP Configuration**
3. Configura:
   - **IP Address:** `10.0.1.10`
   - **Subnet Mask:** `255.255.255.0`
   - **Default Gateway:** `10.0.1.1`
   - **DNS Server:** `10.0.1.10` (stesso server per semplicità)

### Step 3.2 - Abilitare Servizi Web

1. Resta su **Web-Server**
2. Tab **Services** → **HTTP**
   - Verifica che sia **ON**
3. Tab **Services** → **HTTPS**
   - Verifica che sia **ON**
4. (Opzionale) Modifica la pagina HTML:
   - Clicca su **index.html**
   - Modifica il contenuto:
   ```html
   <html>
   <head><title>DMZ Web Server</title></head>
   <body>
   <h1>Benvenuto nel Web Server DMZ!</h1>
   <p>Questo server è posizionato nella DMZ (10.0.1.10)</p>
   <p>LAB 1.1 - DMZ con Singolo Firewall</p>
   </body>
   </html>
   ```

---

## Parte 4: Configurazione PC (LAN)

Configura ogni PC nella LAN interna:

### PC-1
- **IP Address:** `172.16.0.10`
- **Subnet Mask:** `255.255.255.0`
- **Default Gateway:** `172.16.0.1`
- **DNS Server:** `10.0.1.10`

### PC-2
- **IP Address:** `172.16.0.11`
- **Subnet Mask:** `255.255.255.0`
- **Default Gateway:** `172.16.0.1`
- **DNS Server:** `10.0.1.10`

### PC-3
- **IP Address:** `172.16.0.12`
- **Subnet Mask:** `255.255.255.0`
- **Default Gateway:** `172.16.0.1`
- **DNS Server:** `10.0.1.10`

---

## Parte 5: Configurazione Cloud Internet

1. Clicca su **Internet (Cloud)**
2. Tab **Config**
3. **FastEthernet 0**:
   - **IP Address:** `192.0.2.2`
   - **Subnet Mask:** `255.255.255.252`

---

## Parte 6: Test Connettività Base (Prima del Firewall)

Prima di configurare le ACL, verifica la connettività:

### Test 1: Da PC-1 a Web Server
1. Clicca su **PC-1** → **Desktop** → **Command Prompt**
```
C:\> ping 10.0.1.10
```
**Risultato atteso:** ✅ Successo (Reply from 10.0.1.10)

### Test 2: Da PC-1 a Internet
```
C:\> ping 192.0.2.2
```
**Risultato atteso:** ✅ Successo

### Test 3: Accesso Web da PC-1
1. Su **PC-1** → **Desktop** → **Web Browser**
2. URL: `http://10.0.1.10`
**Risultato atteso:** ✅ Pagina web visualizzata

---

## Parte 7: Configurazione NAT/PAT

Ora configuriamo NAT per permettere alla LAN di accedere a Internet con un singolo IP pubblico.

```cisco
R1# configure terminal

! Definire interfacce inside/outside per NAT
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip nat outside
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/1
R1(config-if)# ip nat inside
R1(config-if)# exit

R1(config)# interface GigabitEthernet 0/2
R1(config-if)# ip nat inside
R1(config-if)# exit

! Creare ACL per identificare traffico da tradurre
R1(config)# access-list 1 permit 172.16.0.0 0.0.0.255
R1(config)# access-list 1 permit 10.0.1.0 0.0.0.255

! Configurare NAT overload (PAT)
R1(config)# ip nat inside source list 1 interface GigabitEthernet 0/0 overload

! Salvare configurazione
R1(config)# exit
R1# write memory
```

### Verifica NAT

```cisco
R1# show ip nat translations
R1# show ip nat statistics
```

---

## Parte 8: Configurazione ACL Firewall

Ora implementiamo le regole di sicurezza con Access Control Lists.

### Step 8.1 - ACL per Traffico da Internet verso DMZ

**Policy:** Permettere solo HTTP(80) e HTTPS(443) da Internet verso Web Server DMZ.

```cisco
R1# configure terminal

! ACL Extended per filtrare traffico Internet → DMZ
R1(config)# ip access-list extended INTERNET-TO-DMZ

! Permettere HTTP verso Web Server
R1(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80

! Permettere HTTPS verso Web Server
R1(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! Permettere traffico di ritorno (established connections)
R1(config-ext-nacl)# permit tcp any any established

! Permettere ICMP echo-reply (risposta ping)
R1(config-ext-nacl)# permit icmp any any echo-reply

! Bloccare tutto il resto (implicito, ma esplicitiamolo)
R1(config-ext-nacl)# deny ip any any

R1(config-ext-nacl)# exit

! Applicare ACL in ingresso su interfaccia WAN
R1(config)# interface GigabitEthernet 0/0
R1(config-if)# ip access-group INTERNET-TO-DMZ in
R1(config-if)# exit
```

### Step 8.2 - ACL per Traffico da DMZ verso LAN

**Policy:** Bloccare tutto il traffico dalla DMZ verso la LAN interna (contenimento).

```cisco
! ACL per bloccare DMZ → LAN
R1(config)# ip access-list extended DMZ-TO-LAN

! Bloccare tutto dalla DMZ verso LAN
R1(config-ext-nacl)# deny ip 10.0.1.0 0.0.0.255 172.16.0.0 0.0.0.255

! Permettere al Web Server di rispondere a connessioni originate dalla LAN
R1(config-ext-nacl)# permit tcp any any established

! Permettere tutto il resto (traffico non verso LAN)
R1(config-ext-nacl)# permit ip any any

R1(config-ext-nacl)# exit

! Applicare ACL in uscita su interfaccia DMZ
R1(config)# interface GigabitEthernet 0/1
R1(config-if)# ip access-group DMZ-TO-LAN out
R1(config-if)# exit
```

### Step 8.3 - ACL per Traffico da LAN

**Policy:** Permettere alla LAN di accedere a Internet e alla DMZ.

```cisco
! ACL per LAN (più permissiva)
R1(config)# ip access-list extended LAN-TO-ANY

! Permettere LAN verso Internet
R1(config-ext-nacl)# permit ip 172.16.0.0 0.0.0.255 any

R1(config-ext-nacl)# exit

! Applicare ACL in ingresso su interfaccia LAN
R1(config)# interface GigabitEthernet 0/2
R1(config-if)# ip access-group LAN-TO-ANY in
R1(config-if)# exit

! Salvare configurazione
R1(config)# exit
R1# write memory
```

---

## Parte 9: Test di Sicurezza

### Test 1: Da Internet verso Web Server (DEVE FUNZIONARE)

1. Clicca su **Internet** → **Desktop** → **Web Browser**
2. URL: `http://10.0.1.10`
**Risultato atteso:** ✅ **SUCCESSO** - Pagina web visualizzata

### Test 2: Da Internet verso LAN (DEVE ESSERE BLOCCATO)

1. Da **Internet** → **Desktop** → **Command Prompt**
```
C:\> ping 172.16.0.10
```
**Risultato atteso:** ❌ **FALLIMENTO** - Request timed out
*Motivo: ACL blocca traffico da Internet diretto alla LAN*

### Test 3: Da LAN verso Web Server DMZ (DEVE FUNZIONARE)

1. Da **PC-1** → **Desktop** → **Web Browser**
2. URL: `http://10.0.1.10`
**Risultato atteso:** ✅ **SUCCESSO**

### Test 4: Da LAN verso Internet (DEVE FUNZIONARE)

1. Da **PC-1** → **Command Prompt**
```
C:\> ping 192.0.2.2
```
**Risultato atteso:** ✅ **SUCCESSO**

### Test 5: Da Web Server verso LAN (DEVE ESSERE BLOCCATO)

*Nota: Questo test verifica il contenimento della DMZ*

1. **Web-Server** → **Desktop** → **Command Prompt**
```
C:\> ping 172.16.0.10
```
**Risultato atteso:** ❌ **FALLIMENTO**
*Motivo: ACL blocca traffico iniziato dalla DMZ verso LAN*

### Test 6: Risposta da DMZ a connessioni LAN (DEVE FUNZIONARE)

1. Da **PC-1** apri browser e visita `http://10.0.1.10`
2. Questo stabilisce una connessione
3. Il Web Server può rispondere perché la connessione è "established"
**Risultato atteso:** ✅ **SUCCESSO**

---

## Parte 10: Verifica e Debug

### Comandi Utili per Troubleshooting

```cisco
! Visualizzare configurazione ACL
R1# show access-lists

! Visualizzare ACL applicate alle interfacce
R1# show ip interface GigabitEthernet 0/0

! Vedere statistiche NAT
R1# show ip nat translations
R1# show ip nat statistics

! Vedere tabella di routing
R1# show ip route

! Debug ACL (attivare con cautela)
R1# debug ip packet detail
R1# undebug all  (per disattivare)

! Visualizzare hit count delle ACL
R1# show access-lists
```

---

## Parte 11: Documentazione Finale

### Tabella Indirizzi IP

| Dispositivo | Interfaccia | IP Address | Subnet Mask | Default Gateway |
|-------------|-------------|------------|-------------|-----------------|
| R1 | G0/0 (WAN) | 192.0.2.1 | 255.255.255.252 | - |
| R1 | G0/1 (DMZ) | 10.0.1.1 | 255.255.255.0 | - |
| R1 | G0/2 (LAN) | 172.16.0.1 | 255.255.255.0 | - |
| Web-Server | Fa0 | 10.0.1.10 | 255.255.255.0 | 10.0.1.1 |
| PC-1 | Fa0 | 172.16.0.10 | 255.255.255.0 | 172.16.0.1 |
| PC-2 | Fa0 | 172.16.0.11 | 255.255.255.0 | 172.16.0.1 |
| PC-3 | Fa0 | 172.16.0.12 | 255.255.255.0 | 172.16.0.1 |
| Internet | Fa0 | 192.0.2.2 | 255.255.255.252 | - |

### Policy di Sicurezza Implementate

| Origine | Destinazione | Azione | Protocollo/Porta |
|---------|--------------|--------|------------------|
| Internet | Web Server DMZ | PERMIT | TCP/80, TCP/443 |
| Internet | LAN | DENY | All |
| LAN | Internet | PERMIT | All |
| LAN | DMZ | PERMIT | All |
| DMZ | LAN | DENY | All (solo established OK) |

---

## Parte 12: Sfide Aggiuntive (Opzionali)

### Challenge 1: Aggiungere DNS Server
1. Aggiungi un server DNS in DMZ (10.0.1.53)
2. Modifica ACL per permettere query DNS (UDP/53) da Internet e LAN

### Challenge 2: Logging
1. Aggiungi keyword `log` alle ACL critiche
2. Visualizza i log con `show logging`

### Challenge 3: SSH Management
1. Configura SSH su R1
2. Crea ACL per permettere SSH solo da IP specifico in LAN

### Challenge 4: VLAN
1. Dividi lo Switch-LAN in due VLAN
2. Configura inter-VLAN routing su R1

---

## Salvare il Progetto

1. **File** → **Save As**
2. Nome file: `lab1.1-dmz-singolo-firewall.pkt`
3. Salva nella cartella laboratori

---

## Conclusioni

🎉 **Congratulazioni!** Hai completato:
- ✅ Topologia DMZ a tre zone
- ✅ Configurazione router multi-interfaccia
- ✅ NAT/PAT per mascheramento IP
- ✅ ACL per segmentazione e sicurezza
- ✅ Test di connettività e sicurezza

### Concetti Appresi
- Architettura DMZ con singolo firewall
- Zone di sicurezza (Internet, DMZ, LAN)
- Access Control Lists (ACL)
- Network Address Translation (NAT/PAT)
- Defense in Depth
- Contenimento laterale (DMZ → LAN bloccata)

### Prossimi Passi
Procedi con **LAB 1.2 - DMZ a Doppio Firewall** per apprendere architetture più sicure con doppia protezione.

---

**Fine Laboratorio 1.1**
