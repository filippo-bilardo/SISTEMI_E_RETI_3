# Esercitazione — Configurazione Web Server HTTP/HTTPS in Cisco Packet Tracer

**Tempo stimato:** 3–4 ore  
**Difficoltà:** ⭐⭐ (Base–Intermedia)  
**Modalità:** Individuale o coppie

---

## Obiettivo

Configurare un'infrastruttura web aziendale completa in Cisco Packet Tracer: un web server principale, un web server secondario (intranet) e un server FTP, il tutto raggiungibile tramite nomi DNS. Al termine, si analizzerà il traffico HTTP in Simulation Mode per osservare il meccanismo reale di richiesta e risposta.

---

## 📋 Documentazione richiesta — Riepilogo screenshot

| # | Screenshot | STEP |
|---|-----------|------|
| 📸 1 | Topologia — dispositivi posizionati (senza cavi) | STEP 2 |
| 📸 2 | Topologia — cavi collegati, tutti i link verdi | STEP 2 |
| 📸 3 | IP Configuration di almeno 2 PC e del Server principale | STEP 3 |
| 📸 4 | GUI DNS Server — Services → DNS con tutti i record configurati | STEP 4 |
| 📸 5 | GUI Server principale — Services → HTTP, pagina index.html personalizzata | STEP 5 |
| 📸 6 | GUI Server secondario — Services → HTTP, pagina intranet personalizzata | STEP 6 |
| 📸 7 | Browser PT aperto su `http://www.azienda.local` E su `http://intranet.azienda.local` (2 schermate) | STEP 7 |
| 📸 8 | Simulation Mode — pacchetto HTTP GET in transito (dettaglio PDU) | STEP 8 |
| 📸 9 | Simulation Mode — risposta HTTP 200 OK (dettaglio PDU) | STEP 8 |
| 📸 10 | Salvataggio file `es04a_http.pkt` | STEP 9 |

---

## Architettura

### Dispositivi

| Dispositivo | Modello | Ruolo |
|-------------|---------|-------|
| Router0 | Cisco 2901 | Gateway rete `192.168.1.0/24` |
| Switch0 | Cisco 2960-24TT | Switch di accesso unico |
| Server-Web | Generic Server | Web server principale + DNS (`192.168.1.10`) |
| Server-Intranet | Generic Server | Web server secondario intranet (`192.168.1.11`) |
| Server-FTP | Generic Server | Server FTP aziendale (`192.168.1.12`) |
| PC0 | PC | Client utente 1 |
| PC1 | PC | Client utente 2 |
| PC2 | PC | Client utente 3 |

### Topologia

```
                         [Router0]
                        Gi0/0: 192.168.1.1
                              |
                         [Switch0]
           ___________________|____________________
          /          |          |        |    |    \
    [Server-Web] [Server-    [Server-  [PC0][PC1][PC2]
     .10 (DNS+   Intranet]    FTP]     .100 .101 .102
      HTTP)       .11         .12
```

---

## STEP 1: Piano di Indirizzamento

**Rete:** `192.168.1.0/24` — Subnet Mask: `255.255.255.0`  
**Gateway:** `192.168.1.1` (Router0 — Gi0/0)  
**DNS Server:** `192.168.1.10` (Server-Web svolge anche il ruolo di DNS)

| Dispositivo | Interfaccia | Indirizzo IP | Subnet Mask | Default Gateway | DNS Server | Nome Host |
|-------------|-------------|--------------|-------------|-----------------|------------|-----------|
| **Router0** | GigabitEthernet0/0 | 192.168.1.1 | 255.255.255.0 | — | — | — |
| **Server-Web** | FastEthernet0 | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | `www.azienda.local` |
| **Server-Intranet** | FastEthernet0 | 192.168.1.11 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | `intranet.azienda.local` |
| **Server-FTP** | FastEthernet0 | 192.168.1.12 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | `ftp.azienda.local` |
| **PC0** | FastEthernet0 | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | — |
| **PC1** | FastEthernet0 | 192.168.1.101 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | — |
| **PC2** | FastEthernet0 | 192.168.1.102 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 | — |

### Record DNS da configurare su Server-Web

| Nome | Tipo | Valore (IP) |
|------|------|-------------|
| `www.azienda.local` | A | `192.168.1.10` |
| `intranet.azienda.local` | A | `192.168.1.11` |
| `ftp.azienda.local` | A | `192.168.1.12` |

---

## STEP 2: Creazione Topologia in Packet Tracer

### 2.1 Posizionamento dispositivi

1. Apri **Cisco Packet Tracer** e crea un nuovo file.
2. Dalla barra in basso → **Network Devices → Routers** → trascina un `Cisco 2901`.
3. **Network Devices → Switches** → trascina un `Cisco 2960-24TT`.
4. **End Devices → Servers** → trascina **3 Generic Server** (rinominali: `Server-Web`, `Server-Intranet`, `Server-FTP`).
5. **End Devices → End Devices** → trascina **3 PC** (rinominali: `PC0`, `PC1`, `PC2`).
6. Disponi i dispositivi in modo ordinato (router in alto, switch al centro, server e PC in basso).

> 📸 **Screenshot 1** — Dispositivi posizionati, senza cavi

### 2.2 Collegamento con i cavi

Usa **cavi dritti (Copper Straight-Through)** per tutti i collegamenti:

| Da | Porta | A | Porta |
|----|-------|---|-------|
| Router0 | GigabitEthernet0/0 | Switch0 | FastEthernet0/1 |
| Server-Web | FastEthernet0 | Switch0 | FastEthernet0/2 |
| Server-Intranet | FastEthernet0 | Switch0 | FastEthernet0/3 |
| Server-FTP | FastEthernet0 | Switch0 | FastEthernet0/4 |
| PC0 | FastEthernet0 | Switch0 | FastEthernet0/5 |
| PC1 | FastEthernet0 | Switch0 | FastEthernet0/6 |
| PC2 | FastEthernet0 | Switch0 | FastEthernet0/7 |

Attendi che tutti i pallini diventino **verdi** (può richiedere 30–60 secondi in PT).

> 📸 **Screenshot 2** — Topologia completa con tutti i cavi, link verdi

---

## STEP 3: Configurazione IP dei Dispositivi

### 3.1 Configurazione Router0

Clicca su **Router0** → tab **CLI** → premi `Enter` e digita:

```
Router> enable
Router# configure terminal
Router(config)# interface GigabitEthernet0/0
Router(config-if)# ip address 192.168.1.1 255.255.255.0
Router(config-if)# no shutdown
Router(config-if)# exit
Router(config)# end
Router# write memory
```

### 3.2 Configurazione Server-Web (IP)

Clicca su **Server-Web** → tab **Desktop** → **IP Configuration**:

```
IPv4 Address   : 192.168.1.10
Subnet Mask    : 255.255.255.0
Default Gateway: 192.168.1.1
DNS Server     : 192.168.1.10
```

### 3.3 Configurazione Server-Intranet

```
IPv4 Address   : 192.168.1.11
Subnet Mask    : 255.255.255.0
Default Gateway: 192.168.1.1
DNS Server     : 192.168.1.10
```

### 3.4 Configurazione Server-FTP

```
IPv4 Address   : 192.168.1.12
Subnet Mask    : 255.255.255.0
Default Gateway: 192.168.1.1
DNS Server     : 192.168.1.10
```

### 3.5 Configurazione PC0, PC1, PC2

Per ogni PC → **Desktop** → **IP Configuration**:

| PC | IP Address | Subnet Mask | Gateway | DNS |
|----|-----------|-------------|---------|-----|
| PC0 | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| PC1 | 192.168.1.101 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| PC2 | 192.168.1.102 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |

> 📸 **Screenshot 3** — Finestre IP Configuration di almeno 2 PC e di Server-Web

---

## STEP 4: Configurazione DNS su Server-Web

Il server `192.168.1.10` (Server-Web) fungerà anche da **DNS server interno**.

1. Clicca su **Server-Web** → tab **Services** → **DNS**
2. Imposta **DNS Service: ON**
3. Aggiungi i seguenti record (campo *Name* → *Address* → tasto **Add**):

| Name | Type | Address |
|------|------|---------|
| `www.azienda.local` | A Record | `192.168.1.10` |
| `intranet.azienda.local` | A Record | `192.168.1.11` |
| `ftp.azienda.local` | A Record | `192.168.1.12` |

4. Clicca **Save** per confermare ogni record.

> ⚠️ Assicurati che tutti i PC abbiano `192.168.1.10` come DNS Server nel loro IP Configuration.

> 📸 **Screenshot 4** — GUI DNS con i 3 record A configurati e servizio ON

---

## STEP 5: Configurazione Web Server Principale

### 5.1 Attivazione servizio HTTP/HTTPS

1. Clicca su **Server-Web** → **Services** → **HTTP**
2. Verifica che **HTTP: On** e **HTTPS: On** siano abilitati.

### 5.2 Personalizzazione pagina index.html

Nell'editor della pagina `index.html` presente nella GUI, clicca su `index.html` → **Edit** e sostituisci il contenuto con:

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <title>Azienda S.p.A. — Sito Ufficiale</title>
</head>
<body>
  <h1>Benvenuti in Azienda S.p.A.</h1>
  <pre>
   ___  ___ ___ ___ _  _ ___  _
  / _ \/ __|_ _| __| \| |   \/_\
 | (_) \__ \| || _|| .` | |) / _ \
  \___/|___/___|___|_|\_|___/_/ \_\
  </pre>
  <h2>Sito Web Aziendale</h2>
  <p>Questo server web e' raggiungibile tramite DNS con il nome:</p>
  <p><strong>http://www.azienda.local</strong></p>
  <hr>
  <p>Servizi disponibili:</p>
  <ul>
    <li>Sito pubblico: www.azienda.local</li>
    <li>Intranet: intranet.azienda.local</li>
    <li>FTP: ftp.azienda.local</li>
  </ul>
  <hr>
  <p><em>Server configurato con Cisco Packet Tracer — Esercitazione ES04</em></p>
</body>
</html>
```

3. Clicca **Save** per salvare la pagina.

> 📸 **Screenshot 5** — GUI Services → HTTP del Server-Web con HTTP/HTTPS attivi e pagina index.html visibile

---

## STEP 6: Configurazione Web Server Secondario (Intranet)

### 6.1 Attivazione HTTP

1. Clicca su **Server-Intranet** → **Services** → **HTTP**
2. Abilita **HTTP: On** (HTTPS opzionale).

### 6.2 Personalizzazione pagina intranet

Edita `index.html` con:

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <title>Intranet Aziendale — Accesso Riservato</title>
</head>
<body>
  <h1>🔒 Portale Intranet — Azienda S.p.A.</h1>
  <p><strong>Accesso RISERVATO al personale interno.</strong></p>
  <hr>
  <h2>Area Dipendenti</h2>
  <ul>
    <li>📋 Comunicazioni interne</li>
    <li>📅 Calendario aziendale</li>
    <li>📂 Documentazione tecnica</li>
    <li>🖨️ Stampanti di rete</li>
  </ul>
  <hr>
  <p>Server: <strong>intranet.azienda.local</strong> (192.168.1.11)</p>
  <p><em>Questa pagina e' visibile SOLO dalla rete interna 192.168.1.0/24</em></p>
</body>
</html>
```

3. Clicca **Save**.

> 📸 **Screenshot 6** — GUI HTTP di Server-Intranet con la pagina intranet personalizzata

---

## STEP 7: Test di Navigazione dai PC Client

### 7.1 Test dal browser di Packet Tracer

1. Clicca su **PC0** → **Desktop** → **Web Browser**
2. Nella barra degli indirizzi digita: `http://www.azienda.local` → premi **Go**
3. Verifica che appaia la pagina con il titolo "Benvenuti in Azienda S.p.A."
4. Cambia URL in: `http://intranet.azienda.local` → premi **Go**
5. Verifica che appaia la pagina "Portale Intranet" (contenuto **diverso** dalla prima)

### 7.2 Verifica dalla CLI

Dal **Command Prompt** di PC1:

```
C:\> ping www.azienda.local
C:\> ping intranet.azienda.local
C:\> ping ftp.azienda.local
```

Tutti i ping devono ricevere risposta. Se il ping risponde con l'IP corretto, la risoluzione DNS funziona.

> 📸 **Screenshot 7** — Browser PT su `www.azienda.local` (pagina aziendale) E su `intranet.azienda.local` (pagina intranet) — mostrare chiaramente le due pagine diverse

---

## STEP 8: Analisi della Comunicazione HTTP in Simulation Mode

### 8.1 Attivazione Simulation Mode

1. In basso a destra di PT, passa da **Realtime** a **Simulation** (icona orologio).
2. Nel pannello **Simulation Panel** → clicca **Edit Filters**
3. Lascia attivi solo i protocolli: **HTTP**, **DNS**, **TCP** (deseleziona il resto)
4. Clicca **OK**

### 8.2 Generazione traffico HTTP

1. Clicca su **PC2** → **Desktop** → **Web Browser**
2. Digita `http://www.azienda.local` ma **NON premere Go ancora**
3. Torna nella finestra principale di PT
4. Premi **Go** nel browser di PC2
5. Nel pannello Simulation, premi **Capture/Forward** (▶) ripetutamente
6. Osserva i pacchetti DNS prima (risoluzione nome) poi HTTP

### 8.3 Ispezione del pacchetto HTTP GET

Quando appare un evento **HTTP** nella Event List:
1. Clicca sull'evento per aprire il **PDU Information**
2. Vai alla tab **Outbound PDU Details** → scorri fino a vedere:
   ```
   HTTP
   Method: GET
   URL: /
   HTTP Version: HTTP/1.1
   Host: www.azienda.local
   ```

> 📸 **Screenshot 8** — Simulation Mode con pacchetto HTTP GET selezionato e dettagli PDU visibili

### 8.4 Ispezione della risposta HTTP 200 OK

1. Continua a premere **Capture/Forward** finché il pacchetto arriva al PC2
2. Clicca sull'evento HTTP di risposta dal Server-Web
3. Nei dettagli PDU dovresti vedere:
   ```
   HTTP
   Version: HTTP/1.1
   Status Code: 200
   Phrase: OK
   ```

> 📸 **Screenshot 9** — Risposta HTTP 200 OK dal server, dettaglio PDU nel Simulation Mode

---

## STEP 9: Salvataggio del File

1. Torna in **Realtime Mode** (clicca l'icona orologio in basso)
2. Menu **File** → **Save As...**
3. Salva il file con il nome: **`es04a_http.pkt`**
4. Verifica il salvataggio aprendo la cartella di destinazione

> 📸 **Screenshot 10** — Dialogo di salvataggio o file manager con `es04a_http.pkt` visibile

---

## 🛠️ Troubleshooting

| Problema | Causa probabile | Soluzione |
|----------|----------------|-----------|
| Browser mostra "Request Timeout" | DNS non risponde | Verifica che il server DNS sia `192.168.1.10` su tutti i PC e che il servizio DNS sia **ON** |
| Browser mostra pagina di default PT | HTML non salvato correttamente | Rientra in Services → HTTP → clicca `index.html` → verifica e risalva |
| Ping all'IP funziona ma non al nome | Record DNS mancante o errato | Controlla i record A nel DNS server: nome esatto e IP corretto |
| I link non diventano verdi | Cavo sbagliato o porta occupata | Usa cavo Copper Straight-Through; verifica che le porte dello switch non siano già usate |
| HTTPS non funziona in PT | Limitazione del simulatore | HTTPS in PT è simulato parzialmente — per l'analisi usa HTTP su porta 80 |
| Simulation Mode: nessun evento HTTP | Filtri impostati male | Controlla Edit Filters: HTTP deve essere spuntato |
| Le due pagine web sono identiche | index.html non differenziato | Assicurati di aver editato e salvato `index.html` su **entrambi** i server separatamente |

---

## 📝 Note Tecniche

### Porta 80 vs 443
- **HTTP** utilizza la porta TCP **80** per impostazione predefinita
- **HTTPS** utilizza la porta TCP **443**
- In Packet Tracer, entrambe le porte possono essere abilitate dalla GUI del server (Services → HTTP)

### Virtual Hosting in Packet Tracer
In un server reale, il virtual hosting permette di ospitare più siti sullo stesso IP usando l'header `Host:`. **Packet Tracer non supporta il virtual hosting nativo**: per simulare siti diversi è necessario usare IP diversi (come in questa esercitazione — un IP per `www`, uno per `intranet`).

### Limitazioni della Simulazione
- PT non mostra il vero header HTTP raw in tutti i dettagli
- L'handshake TLS/SSL non è completamente simulato
- I metodi POST non sono facilmente testabili dal browser PT
- Per analisi HTTP complete si consiglia Wireshark su una rete reale

### Come leggere i PDU in Simulation Mode
Nel pannello PDU di PT, ogni livello del modello OSI è rappresentato:
- **Layer 7 (HTTP)**: metodo, URL, status code
- **Layer 4 (TCP)**: porte sorgente e destinazione, numeri di sequenza
- **Layer 3 (IP)**: indirizzi IP sorgente e destinazione
- **Layer 2 (Ethernet)**: indirizzi MAC
