# Esercizio A — Simulazione Attacco DNS e Configurazione Difese in Packet Tracer

**Tipo**: Laboratorio guidato  
**Difficoltà**: ★★★☆☆  
**Tempo stimato**: 90–120 minuti  
**File da consegnare**: `es03a_dns_security.pkt` + cartella con 10 screenshot

---

## 📸 Screenshot richiesti

| # | Momento | Contenuto atteso |
|---|---------|-----------------|
| 📸1 | Dopo STEP 2 | Topologia completa in PT (tutti i dispositivi posizionati e collegati) |
| 📸2 | Dopo STEP 2 | Cablaggio e label dei dispositivi visibili |
| 📸3 | Dopo STEP 3 | Configurazione IP su almeno un PC e sul server DNS |
| 📸4 | Dopo STEP 4 | Pannello DNS del server legittimo con i record configurati |
| 📸5 | Dopo STEP 5 | Simulazione DNS spoofing: PC0 raggiunge il sito sbagliato (IP .200) |
| 📸6 | Dopo STEP 6 | ACL configurata sul router (output `show access-lists`) |
| 📸7 | Dopo STEP 7 | DNS secondario configurato e impostato sui client |
| 📸8 | Dopo STEP 8 | Output `nslookup www.corp.local` su un PC — risposta corretta |
| 📸9 | Dopo STEP 8 | Ping per nome riuscito (`ping www.corp.local`) |
| 📸10 | Dopo STEP 9 | File `.pkt` salvato visibile nel titolo della finestra PT |

---

## 🎯 Obiettivi

Al termine di questo laboratorio lo studente sarà in grado di:
- Riconoscere come avviene un attacco DNS spoofing in una LAN
- Configurare record DNS su un server in Cisco Packet Tracer
- Applicare ACL Cisco per bloccare query DNS non autorizzate
- Implementare la ridondanza DNS con server primario e secondario
- Verificare la corretta risoluzione dei nomi con `ping` e `nslookup`

---

## 🌐 Scenario

L'azienda **Corp Local** gestisce una piccola rete interna. Recentemente il responsabile IT ha ricevuto segnalazioni di utenti che vengono reindirizzati verso un sito web sconosciuto invece di quello aziendale. Si sospetta un attacco di **DNS spoofing**: un dispositivo sulla rete risponde alle query DNS in modo fraudolento, sostituendo l'IP legittimo con quello di un server malevolo.

Il tuo compito è:
1. Ricreare la rete in Cisco Packet Tracer
2. Simulare l'attacco (modificando manualmente il DNS su un client)
3. Applicare le contromisure appropriate
4. Verificare che le difese funzionino

---

## STEP 1 — Piano di Indirizzamento

### Rete: `192.168.1.0/24` — Gateway: `192.168.1.1`

| Dispositivo | Tipo | Interfaccia | Indirizzo IP | Subnet Mask | Gateway | Note |
|------------|------|-------------|--------------|-------------|---------|------|
| Router-GW | Cisco 2901 | Fa0/0 | 192.168.1.1 | 255.255.255.0 | — | Gateway LAN |
| SW-MAIN | Cisco 2960 | — | — | — | — | Switch L2 |
| DNS-Legittimo | Server PT | Fa0 | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 | `dns.corp.local` |
| Web-Legittimo | Server PT | Fa0 | 192.168.1.20 | 255.255.255.0 | 192.168.1.1 | `www.corp.local` |
| Web-Malevolo | Server PT | Fa0 | 192.168.1.200 | 255.255.255.0 | 192.168.1.1 | Simulazione attaccante |
| PC0 | PC PT | Fa0 | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | Client |
| PC1 | PC PT | Fa0 | 192.168.1.101 | 255.255.255.0 | 192.168.1.1 | Client |
| PC2 | PC PT | Fa0 | 192.168.1.102 | 255.255.255.0 | 192.168.1.1 | Client |

> 💡 **Nota**: in un attacco reale il DNS malevolo sarebbe su una rete esterna o compromesso dall'interno. Qui lo simuliamo sostituendo manualmente il server DNS configurato su PC0.

---

## STEP 2 — Creazione Topologia in Packet Tracer

### 2.1 Posizionamento dispositivi

1. Apri **Cisco Packet Tracer** → nuovo progetto vuoto
2. Aggiungi i seguenti dispositivi dalla barra in basso:
   - **Router**: Cisco 2901 (categoria *Routers*) → rinomina `Router-GW`
   - **Switch**: Cisco 2960 (categoria *Switches*) → rinomina `SW-MAIN`
   - **Server** ×3 (categoria *End Devices → Servers*) → rinomina: `DNS-Legittimo`, `Web-Legittimo`, `Web-Malevolo`
   - **PC** ×3 (categoria *End Devices*) → rinomina: `PC0`, `PC1`, `PC2`

3. Posiziona i dispositivi in modo ordinato:
   ```
   [Router-GW]
        |
   [SW-MAIN]
   /  |  |  \  \  \
  DNS Web Web PC0 PC1 PC2
  Leg Leg Mal
   ```

### 2.2 Cablaggio

Usa cavi **Copper Straight-Through** per tutti i collegamenti:

| Da | Interfaccia | A | Interfaccia |
|----|-------------|---|-------------|
| Router-GW | Fa0/0 | SW-MAIN | Fa0/1 |
| DNS-Legittimo | Fa0 | SW-MAIN | Fa0/2 |
| Web-Legittimo | Fa0 | SW-MAIN | Fa0/3 |
| Web-Malevolo | Fa0 | SW-MAIN | Fa0/4 |
| PC0 | Fa0 | SW-MAIN | Fa0/5 |
| PC1 | Fa0 | SW-MAIN | Fa0/6 |
| PC2 | Fa0 | SW-MAIN | Fa0/7 |

> 📸 **SCREENSHOT 1**: Topologia completa con tutti i dispositivi posizionati e cablati.  
> 📸 **SCREENSHOT 2**: Zoom su label e interfacce visibili.

---

## STEP 3 — Configurazione IP Dispositivi

### 3.1 Router-GW

Clicca sul router → tab **CLI**:

```ios
Router> enable
Router# configure terminal
Router(config)# hostname Router-GW
Router-GW(config)# interface FastEthernet0/0
Router-GW(config-if)# ip address 192.168.1.1 255.255.255.0
Router-GW(config-if)# no shutdown
Router-GW(config-if)# description "LAN Corp Local"
Router-GW(config-if)# exit
Router-GW(config)# end
Router-GW# write memory
```

### 3.2 Server DNS-Legittimo

Clicca su `DNS-Legittimo` → tab **Desktop** → **IP Configuration**:
- IP Address: `192.168.1.10`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.1.1`
- DNS Server: `192.168.1.10` (punta a se stesso)

### 3.3 Server Web-Legittimo

- IP Address: `192.168.1.20`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.1.1`
- DNS Server: `192.168.1.10`

### 3.4 Server Web-Malevolo

- IP Address: `192.168.1.200`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.1.1`
- DNS Server: `192.168.1.10`

### 3.5 PC Client (PC0, PC1, PC2)

Per ciascun PC → **Desktop** → **IP Configuration**:

| PC | IP | Gateway | DNS |
|----|----|---------|-----|
| PC0 | 192.168.1.100 | 192.168.1.1 | 192.168.1.10 |
| PC1 | 192.168.1.101 | 192.168.1.1 | 192.168.1.10 |
| PC2 | 192.168.1.102 | 192.168.1.1 | 192.168.1.10 |

### 3.6 Verifica connettività base

Da PC0 → **Desktop** → **Command Prompt**:
```
ping 192.168.1.1
ping 192.168.1.10
ping 192.168.1.20
```
Tutti e tre devono rispondere con successo prima di continuare.

> 📸 **SCREENSHOT 3**: Configurazione IP di PC0 e del server DNS-Legittimo visibili.

---

## STEP 4 — Configurazione DNS Legittimo

### 4.1 Attivare il servizio DNS

Clicca su `DNS-Legittimo` → tab **Services** → **DNS**:
- Imposta **DNS Service**: `ON`

### 4.2 Creare i record DNS

Aggiungi i seguenti record cliccando su **Add** per ciascuno:

| Nome | Tipo | Indirizzo |
|------|------|-----------|
| `www.corp.local` | A Record | `192.168.1.20` |
| `dns.corp.local` | A Record | `192.168.1.10` |
| `mail.corp.local` | A Record | `192.168.1.21` |
| `ftp.corp.local` | A Record | `192.168.1.22` |

> 💡 I record per mail e ftp puntano a IP non ancora assegnati: vanno bene per testare la risoluzione dei nomi, anche se quei server non esistono in questa topologia.

### 4.3 Configurare il Web-Legittimo

Clicca su `Web-Legittimo` → **Services** → **HTTP**:
- Verifica che **HTTP Service** sia `ON`
- Modifica la pagina index.html (opzionale): sostituisci il testo con `SITO LEGITTIMO - Corp Local`

### 4.4 Configurare il Web-Malevolo

Clicca su `Web-Malevolo` → **Services** → **HTTP**:
- Verifica che **HTTP Service** sia `ON`
- Modifica la pagina index.html: sostituisci il testo con `⚠️ SITO MALEVOLO - Sei stato reindirizzato!`

> 📸 **SCREENSHOT 4**: Pannello DNS di DNS-Legittimo con tutti i record configurati e servizio ON.

---

## STEP 5 — Simulazione DNS Spoofing

### 5.1 Scenario dell'attacco

In questo step simuliamo il comportamento di un **DNS spoofing**: il PC0 viene ingannato e usa il server DNS malevolo (`192.168.1.200`) invece di quello legittimo (`192.168.1.10`). In un attacco reale questo avviene tramite:
- Compromissione del router (cambio DNS nel DHCP)
- Malware sul client che modifica le impostazioni DNS
- Avvelenamento della cache DNS (cache poisoning)

Noi lo simuliamo manualmente cambiando il DNS sul PC0.

### 5.2 Configurare un finto DNS sul Web-Malevolo

Per far funzionare la simulazione, dobbiamo attivare anche il servizio DNS sul server malevolo e fargli rispondere con l'IP sbagliato:

Clicca su `Web-Malevolo` → **Services** → **DNS**:
- DNS Service: `ON`
- Aggiungi record:

| Nome | Tipo | Indirizzo |
|------|------|-----------|
| `www.corp.local` | A Record | `192.168.1.200` |

### 5.3 Modificare DNS su PC0 (simulazione attacco)

Clicca su `PC0` → **Desktop** → **IP Configuration**:
- **DNS Server**: cambia da `192.168.1.10` a `192.168.1.200`

### 5.4 Verificare il reindirizzamento

Da `PC0` → **Desktop** → **Web Browser**:
- Digita `http://www.corp.local`

**Risultato atteso**: il browser mostra la pagina del sito malevolo ("⚠️ SITO MALEVOLO - Sei stato reindirizzato!")

Da `PC0` → **Desktop** → **Command Prompt**:
```
nslookup www.corp.local
```
**Output atteso**:
```
Server: [192.168.1.200]
Address: 192.168.1.200

Name: www.corp.local
Address: 192.168.1.200   ← IP SBAGLIATO! (dovrebbe essere .20)
```

Da `PC1` (non modificato) → lo stesso comando restituisce `192.168.1.20` ← corretto.

> ⚠️ **Questa è la dimostrazione dell'attacco**: il DNS è il "libro delle traduzioni" di Internet. Se qualcuno lo manomette, può controllare dove vengono mandati gli utenti senza che se ne accorgano.

> 📸 **SCREENSHOT 5**: Browser di PC0 che mostra il sito malevolo, con URL `http://www.corp.local` visibile.

---

## STEP 6 — Contromisura 1: Ripristino DNS e ACL sul Router

### 6.1 Ripristinare il DNS corretto su PC0

Clicca su `PC0` → **Desktop** → **IP Configuration**:
- **DNS Server**: riporta a `192.168.1.10`

Verifica:
```
nslookup www.corp.local
```
Ora deve rispondere con `192.168.1.20`.

### 6.2 Configurare ACL sul Router per bloccare query DNS non autorizzate

L'obiettivo è: **solo il server DNS interno (`192.168.1.10`) può effettuare query DNS verso l'esterno**. Tutti gli altri host non devono poter usare DNS server alternativi (porta UDP/TCP 53).

Vai su `Router-GW` → **CLI**:

```ios
Router-GW# configure terminal

! ACL estesa 101: blocca query DNS (porta 53) da tutti TRANNE il DNS legittimo
Router-GW(config)# ip access-list extended DNS-SECURITY
Router-GW(config-ext-nacl)# remark Permetti DNS solo dal server legittimo
Router-GW(config-ext-nacl)# permit udp host 192.168.1.10 any eq 53
Router-GW(config-ext-nacl)# permit tcp host 192.168.1.10 any eq 53
Router-GW(config-ext-nacl)# remark Blocca DNS da tutti gli altri host interni
Router-GW(config-ext-nacl)# deny udp 192.168.1.0 0.0.0.255 any eq 53
Router-GW(config-ext-nacl)# deny tcp 192.168.1.0 0.0.0.255 any eq 53
Router-GW(config-ext-nacl)# remark Permetti tutto il traffico restante
Router-GW(config-ext-nacl)# permit ip any any
Router-GW(config-ext-nacl)# exit

! Applica l'ACL all'interfaccia LAN in uscita verso Internet (se presente)
! In questa topologia la applichiamo in entrata su Fa0/0
Router-GW(config)# interface FastEthernet0/0
Router-GW(config-if)# ip access-group DNS-SECURITY in
Router-GW(config-if)# exit
Router-GW(config)# end
Router-GW# write memory
```

### 6.3 Verificare l'ACL

```ios
Router-GW# show access-lists
Router-GW# show ip interface FastEthernet0/0
```

**Effetto**: PC0 non può più usare `192.168.1.200` come DNS server per raggiungere host esterni, perché le query DNS vengono bloccate se non provengono da `192.168.1.10`.

> 📸 **SCREENSHOT 6**: Output del comando `show access-lists` sul router con l'ACL DNS-SECURITY configurata.

---

## STEP 7 — Contromisura 2: DNS Ridondante

### 7.1 Aggiungere un secondo server DNS

La ridondanza protegge dalla **disponibilità**: se il DNS primario va offline (o è sotto attacco), il client può interrogare il secondario.

1. Aggiungi un nuovo Server in PT → rinomina `DNS-Secondario`
2. Collegalo allo switch: `DNS-Secondario Fa0` → `SW-MAIN Fa0/8`
3. Configura l'IP: `192.168.1.11`, mask `255.255.255.0`, gateway `192.168.1.1`

### 7.2 Configurare il DNS Secondario

Clicca su `DNS-Secondario` → **Services** → **DNS**:
- DNS Service: `ON`
- Aggiungi **gli stessi record** del DNS primario:

| Nome | Tipo | Indirizzo |
|------|------|-----------|
| `www.corp.local` | A Record | `192.168.1.20` |
| `dns.corp.local` | A Record | `192.168.1.10` |
| `mail.corp.local` | A Record | `192.168.1.21` |
| `ftp.corp.local` | A Record | `192.168.1.22` |

> 💡 In un ambiente reale il DNS secondario riceverebbe i record tramite **trasferimento di zona (AXFR)** dal primario. In Packet Tracer questa funzione non è disponibile, quindi si inseriscono manualmente.

### 7.3 Configurare entrambi i DNS sui client

In Packet Tracer è possibile configurare solo un DNS server per client tramite GUI. Per simulare il failover, imposta:
- **PC0**: DNS `192.168.1.10` (primario)
- **PC1**: DNS `192.168.1.11` (secondario — simula failover)
- **PC2**: DNS `192.168.1.10` (primario)

### 7.4 Test di ridondanza

1. Spegni temporaneamente `DNS-Legittimo` (clicca sul server → tab *Physical* → spegni)
2. Da `PC1` (che usa il secondario):
   ```
   nslookup www.corp.local
   ```
   Deve rispondere correttamente usando `192.168.1.11`
3. Da `PC0` (che usa il primario):
   ```
   nslookup www.corp.local
   ```
   Fallirà (DNS primario offline) — questo motiva la doppia configurazione
4. Riaccendi `DNS-Legittimo`

> 📸 **SCREENSHOT 7**: DNS secondario configurato con i record + impostazione DNS sui client.

---

## STEP 8 — Verifica Finale

### 8.1 Test ping per nome

Da ciascun PC → **Command Prompt**:
```
ping www.corp.local
ping dns.corp.local
ping ftp.corp.local
```

Risultati attesi:
| Comando | Risposta da |
|---------|-------------|
| `ping www.corp.local` | `192.168.1.20` |
| `ping dns.corp.local` | `192.168.1.10` |
| `ping ftp.corp.local` | `192.168.1.22` (timeout, ma risolve) |

### 8.2 Test nslookup

```
nslookup www.corp.local
nslookup mail.corp.local
nslookup dns.corp.local
```

**Output atteso per `nslookup www.corp.local`**:
```
Server: [192.168.1.10]
Address: 192.168.1.10

Name: www.corp.local
Address: 192.168.1.20
```

### 8.3 Confronto prima/dopo

| Stato | DNS usato da PC0 | `nslookup www.corp.local` | Sito raggiunto |
|-------|-----------------|--------------------------|----------------|
| Prima (attacco) | 192.168.1.200 | → 192.168.1.200 | ⚠️ Sito malevolo |
| Dopo (difesa) | 192.168.1.10 | → 192.168.1.20 | ✅ Sito legittimo |

### 8.4 Verifica ACL in azione

Da PC2 → prova a impostare manualmente DNS a `192.168.1.200` e verifica:
```
nslookup www.corp.local
```
Con l'ACL attiva, la query DNS verso `.200` viene bloccata dal router e non ottiene risposta (timeout).

> 📸 **SCREENSHOT 8**: Output `nslookup www.corp.local` con risposta corretta (IP `.20`).  
> 📸 **SCREENSHOT 9**: Output `ping www.corp.local` riuscito con IP `.20`.

---

## STEP 9 — Salvataggio

1. In Packet Tracer: **File** → **Save As**
2. Nome file: `es03a_dns_security.pkt`
3. Salva nella cartella del progetto

> 📸 **SCREENSHOT 10**: Finestra PT con il titolo `es03a_dns_security.pkt` visibile nella barra del titolo.

---

## 🔧 Troubleshooting

| Problema | Causa probabile | Soluzione |
|----------|----------------|-----------|
| `nslookup` non funziona | DNS service OFF sul server | Clicca server → Services → DNS → ON |
| Ping per nome fallisce ma ping per IP funziona | IP del DNS non configurato sul PC | Controlla IP Configuration del PC |
| ACL blocca tutto il traffico | Manca il `permit ip any any` finale | Aggiorna ACL con la permit finale |
| DNS secondario non risponde | Record non inseriti o servizio OFF | Verifica configurazione del DNS-Secondario |
| Browser mostra "Request Timeout" | Web server HTTP non attivo | Clicca server → Services → HTTP → ON |
| PC non raggiunge il gateway | IP/mask errati | Ricontrolla configurazione IP del PC |

---

## 📝 Note Tecniche

### Perché UDP porta 53?
Il DNS usa **UDP porta 53** per la maggior parte delle query (veloci, piccole). Usa **TCP porta 53** quando le risposte superano 512 byte (es. trasferimenti di zona, risposte DNSSEC). L'ACL deve bloccare entrambi i protocolli.

### Limiti della simulazione in Packet Tracer
Packet Tracer **non** supporta:
- DNSSEC (firme digitali sui record)
- DNS over HTTPS/TLS
- Trasferimento di zona automatico (AXFR)
- Monitoraggio query DNS in tempo reale

Questi aspetti vengono trattati teoricamente nelle guide in `docs/`.

### ACL e posizionamento
L'ACL `DNS-SECURITY` in questo esercizio è applicata **in ingresso su Fa0/0** (interfaccia LAN del router). In un ambiente reale andrebbe applicata sull'interfaccia verso Internet (WAN) per bloccare l'uscita di query DNS non autorizzate verso resolver esterni.
