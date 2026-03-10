# Troubleshooting DNS — Risoluzione dei Problemi

## Introduzione

I problemi DNS sono tra i più comuni in qualsiasi rete, aziendale o domestica. Un malfunzionamento DNS si manifesta spesso con messaggi come "impossibile trovare il server" o "host non trovato", anche quando la connessione di rete fisica funziona perfettamente.

Questa guida illustra i problemi più comuni, i comandi diagnostici disponibili (in particolare in Cisco Packet Tracer) e le procedure di risoluzione.

---

## Strumenti Diagnostici

### `nslookup` — Il principale strumento di debug DNS

`nslookup` (Name Server Lookup) è il comando fondamentale per testare il DNS. Disponibile su Windows, Linux, macOS e simulato in Cisco Packet Tracer.

#### Utilizzo base

```
C:\> nslookup www.azienda.local
```

Output tipico:
```
Server:  dns.azienda.local
Address: 192.168.1.10

Name:    www.azienda.local
Address: 192.168.1.20
```

| Riga | Significato |
|------|-------------|
| `Server: dns.azienda.local` | Nome del server DNS usato per la query |
| `Address: 192.168.1.10` | IP del server DNS usato |
| `Name: www.azienda.local` | Nome risolto (confermato) |
| `Address: 192.168.1.20` | Indirizzo IP corrispondente |

#### Interrogare un server DNS specifico

```
C:\> nslookup www.azienda.local 192.168.1.11
```

Questo comando interroga il server `192.168.1.11` invece del DNS di default. Utile per testare il DNS secondario.

#### Modalità interattiva (sistemi reali, non PT)

```
C:\> nslookup
> server 192.168.1.10
Default server: dns.azienda.local
Address: 192.168.1.10

> www.azienda.local
Name:    www.azienda.local
Address: 192.168.1.20

> set type=MX
> azienda.local
azienda.local  MX preference = 10, mail exchanger = mail.azienda.local

> exit
```

---

### `ipconfig` — Verifica configurazione IP

```
C:\> ipconfig /all
```

Output rilevante da controllare:
```
Ethernet adapter Ethernet0:
   IPv4 Address. . . . . . . . : 192.168.1.100
   Subnet Mask . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . : 192.168.1.1
   DNS Servers . . . . . . . . : 192.168.1.10
```

> ⚠️ Il campo **DNS Servers** deve contenere l'IP del server DNS interno. Se è vuoto o errato, nessuna risoluzione per nome funzionerà.

---

### `ping` — Test risoluzione + raggiungibilità

```
C:\> ping www.azienda.local
```

**Caso 1 — DNS funziona, host raggiungibile:**
```
Pinging www.azienda.local [192.168.1.20] with 32 bytes of data:
Reply from 192.168.1.20: bytes=32 time<1ms TTL=128
```
✅ Il nome tra parentesi quadre indica che il DNS ha risolto correttamente.

**Caso 2 — DNS non funziona:**
```
Ping request could not find host www.azienda.local.
Please check the name and try again.
```
❌ Il DNS non ha risolto il nome. Il problema è nel DNS, non nella rete.

**Caso 3 — DNS funziona ma host non raggiungibile:**
```
Pinging www.azienda.local [192.168.1.20] with 32 bytes of data:
Request timed out.
Request timed out.
```
⚠️ Il DNS ha risolto il nome (c'è l'IP tra parentesi), ma il server non risponde. Problema di rete o host down.

---

### `ping` per IP — Verifica connettività di base

```
C:\> ping 192.168.1.20
```

Se funziona ma il ping per nome no → il problema è **solo nel DNS**, non nella rete.  
Se non funziona nemmeno il ping per IP → il problema è nella **connettività di rete** (cavo, IP, gateway).

---

### `tracert` (traceroute) — Percorso dei pacchetti

```
C:\> tracert www.azienda.local
```

In PT utile per verificare il percorso verso host su subnet diverse o attraverso il router.

---

## Problemi Comuni e Soluzioni

---

### ❌ Problema 1: "Ping request could not find host"

**Sintomi:** Il ping per nome fallisce, ma il ping per IP funziona.

**Diagnosi:**
```
C:\> ping 192.168.1.20          → OK (rete funziona)
C:\> ping www.azienda.local     → FAIL (DNS non funziona)
C:\> ipconfig /all              → controlla DNS Servers
```

**Cause possibili e soluzioni:**

| Causa | Soluzione |
|-------|-----------|
| DNS Server non configurato nel client | IP Configuration del PC → impostare DNS Server a `192.168.1.10` |
| IP del DNS Server errato nel client | Correggere l'IP nel campo DNS Server |
| Servizio DNS sul server spento | Server-DNS → Services → DNS → impostare su **ON** |
| Record DNS mancante | Server-DNS → Services → DNS → aggiungere il record mancante |
| Record DNS con nome errato (typo) | Controllare l'ortografia del record DNS (es. `www.azienda.local` vs `wwww.azienda.local`) |

---

### ❌ Problema 2: nslookup risponde "DNS request timed out"

**Sintomi:**
```
C:\> nslookup www.azienda.local

DNS request timed out.
    timeout was 2 seconds.
```

**Cause possibili e soluzioni:**

| Causa | Soluzione |
|-------|-----------|
| Server DNS non raggiungibile (rete) | `ping 192.168.1.10` — se fallisce, problema di rete verso il DNS server |
| Servizio DNS sul server disabilitato | Server-DNS → Services → DNS → **ON** |
| Firewall blocca porta 53 UDP | In PT non ci sono firewall di default; in ambienti reali verificare le ACL |
| IP del DNS server errato nel client | Correggere in IP Configuration |

---

### ❌ Problema 3: nslookup risponde IP sbagliato

**Sintomi:**
```
C:\> nslookup www.azienda.local
Name:    www.azienda.local
Address: 192.168.1.99     ← IP errato!
```

**Cause possibili e soluzioni:**

| Causa | Soluzione |
|-------|-----------|
| Record DNS configurato con IP errato | Server-DNS → Services → DNS → trovare il record, eliminarlo con **Remove**, ricrearlo correttamente |
| Record duplicato | Verificare che non ci siano due record con lo stesso nome ma IP diversi |
| Cache DNS obsoleta | In ambienti reali: `ipconfig /flushdns` (Windows) oppure aspettare scadenza TTL |

---

### ❌ Problema 4: Il browser non apre il sito per nome

**Sintomi:** `nslookup` funziona ma il browser mostra "Impossibile raggiungere il sito".

**Diagnosi step-by-step:**

1. **Verifica DNS:**
```
C:\> nslookup www.azienda.local
```
Se non funziona → risolvi prima il DNS.

2. **Verifica raggiungibilità con ping:**
```
C:\> ping www.azienda.local
```

3. **Verifica servizio HTTP sul server:**
   - Apri Server-Web → Services → HTTP
   - Il toggle HTTP deve essere su **ON**

4. **Verifica che esista il file `index.html`:**
   - In Services → HTTP deve esserci almeno un file `index.html`

---

### ❌ Problema 5: Solo alcuni nomi vengono risolti

**Sintomi:** `ping www.azienda.local` funziona, ma `ping mail.azienda.local` fallisce.

**Causa:** Il record per `mail.azienda.local` non è stato creato.

**Soluzione:**
1. Apri Server-DNS → Services → DNS
2. Verifica la lista dei record
3. Aggiungi il record mancante: `mail.azienda.local` → A → `192.168.1.30`

---

### ❌ Problema 6: I PC in una subnet non risolvono, quelli in un'altra sì

**Sintomi:** PC0 (192.168.1.100) risolve i nomi, PC3 (192.168.2.100) no.

**Cause possibili:**

| Causa | Soluzione |
|-------|-----------|
| PC3 ha un DNS Server diverso configurato | Correggere in IP Configuration di PC3 |
| PC3 non raggiunge il server DNS (routing mancante) | Verificare che il router abbia route verso la subnet del DNS |
| Firewall/ACL blocca porta 53 dalla subnet di PC3 | Verificare configurazione ACL sul router |

**Verifica routing:**
```
C:\> ping 192.168.1.10      (dal PC3 nella subnet 192.168.2.x)
```
Se fallisce il ping per IP al server DNS → problema di routing, non DNS.

---

### ❌ Problema 7: Cavi e link (PT specifico)

**Sintomi:** Tutto sembra configurato correttamente ma nulla funziona.

**Cose da verificare in Packet Tracer:**

| Verifica | Come fare |
|---------|-----------|
| Cavi collegati correttamente | Controlla visivamente i link; devono essere **verdi** |
| Tipo di cavo corretto | Straight-Through per host-switch; Cross-Over per switch-switch |
| Interfaccia router attiva | CLI Router: `show ip interface brief` → deve essere `up/up` |
| IP assegnato all'interfaccia corretta | CLI Router: `show running-config` → controlla quale interfaccia ha l'IP |

**Comando utile sul Router:**
```
Router# show ip interface brief
```

Output atteso:
```
Interface              IP-Address      OK? Method Status   Protocol
GigabitEthernet0/0    192.168.1.1     YES manual up       up
GigabitEthernet0/1    unassigned      YES unset  down     down
```

---

## Procedura Sistematica di Troubleshooting

Quando un client non riesce a risolvere un nome, segui sempre questa sequenza:

```
STEP 1: Verifica connettività fisica
   └─> I cavi sono collegati? I link sono verdi?

STEP 2: Verifica configurazione IP del client
   └─> ipconfig /all
   └─> IP, mask, gateway, DNS Server corretti?

STEP 3: Testa connettività verso il gateway
   └─> ping 192.168.1.1
   └─> Se fallisce → problema IP/fisico sul client

STEP 4: Testa connettività verso il server DNS (per IP)
   └─> ping 192.168.1.10
   └─> Se fallisce → problema di routing o IP del DNS server

STEP 5: Testa il servizio DNS
   └─> nslookup www.azienda.local
   └─> Se fallisce → DNS service OFF o record mancante

STEP 6: Verifica il record DNS sul server
   └─> Apri Server-DNS → Services → DNS
   └─> Controlla che il record esista e sia corretto

STEP 7: Testa il servizio di destinazione
   └─> ping www.azienda.local (per IP)
   └─> Browser: http://www.azienda.local
   └─> Se DNS risolve ma sito non si apre → HTTP spento sul Web Server
```

---

## Tabella Diagnostica Rapida

| Sintomo | Test da fare | Probabile causa |
|---------|-------------|----------------|
| `ping nome` → "cannot find host" | `ipconfig /all` (controlla DNS field) | DNS Server non configurato nel client |
| `nslookup` → timeout | `ping IP-del-DNS` | DNS server irraggiungibile o servizio OFF |
| `nslookup` → IP sbagliato | Controlla record su Server-DNS | Record DNS con IP errato |
| `ping nome` OK ma browser no | Server-Web → HTTP → ON? | Servizio HTTP spento |
| `ping IP` OK ma `ping nome` no | `nslookup nome` | DNS Server non configurato o record mancante |
| Nulla funziona | Link verdi? Cavi giusti? | Problema fisico/cablaggio in PT |

---

## Comandi Veloci di Riferimento (Packet Tracer)

```bash
# Verifica configurazione IP del client
ipconfig /all

# Test DNS per nome
nslookup www.azienda.local

# Test DNS con server specifico
nslookup www.azienda.local 192.168.1.10

# Ping per nome (DNS + raggiungibilità)
ping www.azienda.local

# Ping per IP (solo raggiungibilità)
ping 192.168.1.20

# Traceroute
tracert www.azienda.local

# Verifica interfacce del router (dalla CLI del router)
show ip interface brief

# Verifica tabella routing (dalla CLI del router)
show ip route
```
