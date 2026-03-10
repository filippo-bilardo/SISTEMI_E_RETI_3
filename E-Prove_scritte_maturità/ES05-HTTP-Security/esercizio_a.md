# Esercizio A — Laboratorio Guidato
## Simulazione Attacchi HTTP e Configurazione Difese in Packet Tracer

**Tipo**: Laboratorio pratico guidato  
**Durata stimata**: 3–4 ore  
**Strumento**: Cisco Packet Tracer 8.x  
**File da salvare**: `es05a_http_security.pkt`

---

## 📸 Riepilogo Screenshot Richiesti

| # | Descrizione | Step |
|---|-------------|------|
| 📸1 | Layout topologia completa (dispositivi posizionati, nessun cavo) | STEP 2 |
| 📸2 | Topologia con cavi collegati, LED verdi | STEP 2 |
| 📸3 | Configurazione IP di almeno 3 dispositivi (PC0, Server HTTP, Router) | STEP 3 |
| 📸4 | Pagina web del server HTTP vulnerabile con form login visibile | STEP 4 |
| 📸5 | Simulation Mode — PDU HTTP con credenziali in chiaro visibili | STEP 5 |
| 📸6 | Confronto: PDU HTTPS — payload cifrato/non leggibile | STEP 5 |
| 📸7 | Server `secure.corp.local` con HTTPS attivo — browser mostra connessione sicura | STEP 6 |
| 📸8 | Spiegazione HSTS — header `Strict-Transport-Security` mostrato nella risposta | STEP 7 |
| 📸9 | Verifica finale — Simulation Mode con entrambi i server attivi | STEP 8 |
| 📸10 | File `es05a_http_security.pkt` salvato (schermata con nome file visibile) | STEP 9 |

---

## 🗺️ Scenario

Una **rete aziendale** `192.168.2.0/24` ospita due web server:
- Un server **HTTP non sicuro** (`www.corp.local`) — usato per dimostrare le vulnerabilità
- Un server **HTTPS sicuro** (`secure.corp.local`) — usato per mostrare le contromisure

Un PC "attaccante" simula l'intercettazione del traffico usando la **Simulation Mode** di Packet Tracer.

---

## STEP 1 — Piano di Indirizzamento

### Tabella IP

| Dispositivo | Interfaccia | Indirizzo IP | Subnet Mask | Gateway | Servizio | Note sicurezza |
|-------------|-------------|--------------|-------------|---------|----------|----------------|
| Router 2901 | Gi0/0 | `192.168.2.1` | `255.255.255.0` | — | Default GW | Unico punto d'uscita |
| Web Server HTTP | NIC | `192.168.2.10` | `255.255.255.0` | `192.168.2.1` | HTTP (porta 80) | ⚠️ INSICURO — traffico in chiaro |
| Web Server HTTPS | NIC | `192.168.2.11` | `255.255.255.0` | `192.168.2.1` | HTTPS (porta 443) | ✅ SICURO — traffico cifrato |
| PC Attaccante | NIC | `192.168.2.200` | `255.255.255.0` | `192.168.2.1` | — | Simula intercettazione |
| PC Client 0 | NIC | `192.168.2.100` | `255.255.255.0` | `192.168.2.1` | Browser | Vittima simulata |
| PC Client 1 | NIC | `192.168.2.101` | `255.255.255.0` | `192.168.2.1` | Browser | Client normale |
| PC Client 2 | NIC | `192.168.2.102` | `255.255.255.0` | `192.168.2.1` | Browser | Client normale |
| Switch 2960 | — | — | — | — | Switching L2 | Nessuna config richiesta |

> 💡 **Nota**: In una rete reale, il server HTTP e il server HTTPS sarebbero spesso lo **stesso server** (configurato per rispondere sia su porta 80 che su 443, con redirect). In questo laboratorio usiamo due server separati per visualizzare meglio il contrasto sicuro/insicuro.

---

## STEP 2 — Creazione Topologia in Packet Tracer

### 2.1 Dispositivi da aggiungere

Nella barra inferiore di PT, seleziona e posiziona:

| Dispositivo | Categoria PT | Modello | Quantità |
|-------------|-------------|---------|----------|
| Router | Routers | Cisco 2901 | 1 |
| Switch | Switches | Cisco 2960 | 1 |
| Web Server (HTTP) | End Devices | Server-PT | 1 |
| Web Server (HTTPS) | End Devices | Server-PT | 1 |
| PC Attaccante | End Devices | PC-PT | 1 |
| PC Client | End Devices | PC-PT | 3 |

### 2.2 Posizionamento consigliato

```
[Router 2901]
      |
[Switch 2960]
  /  |  \  \  \  \
PC0 PC1 PC2 ATK WS-HTTP WS-HTTPS
```

Rinomina i dispositivi con un doppio clic sull'etichetta:
- Router → `R1`
- Switch → `SW1`
- Server 1 → `WS-HTTP` (web server insicuro)
- Server 2 → `WS-HTTPS` (web server sicuro)
- PC-PT attaccante → `PC-ATK`
- PC-PT client → `PC0`, `PC1`, `PC2`

📸 **Screenshot 1** — Scatta la topologia con tutti i dispositivi posizionati prima di aggiungere i cavi.

### 2.3 Collegamento cavi

Usa cavi **Copper Straight-Through** per collegare:
- Ogni PC → Switch (porta qualsiasi)
- WS-HTTP → Switch
- WS-HTTPS → Switch
- Switch → Router (Gi0/0)

Verifica che tutti i LED diventino **verdi** (⚠️ il router richiede di attivare l'interfaccia — vedere STEP 3).

📸 **Screenshot 2** — Topologia completa con cavi e LED verdi.

---

## STEP 3 — Configurazione IP dei Dispositivi

### 3.1 Router R1

Apri il terminale del router (scheda **CLI**):

```
Router> enable
Router# configure terminal
Router(config)# hostname R1
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip address 192.168.2.1 255.255.255.0
R1(config-if)# no shutdown
R1(config-if)# description "LAN aziendale"
R1(config-if)# exit
R1(config)# end
R1# write memory
```

### 3.2 PC Client e PC Attaccante

Per ogni PC: **clic sul dispositivo → Desktop → IP Configuration**

| Dispositivo | IP Address | Subnet Mask | Default Gateway |
|-------------|------------|-------------|-----------------|
| PC0 | `192.168.2.100` | `255.255.255.0` | `192.168.2.1` |
| PC1 | `192.168.2.101` | `255.255.255.0` | `192.168.2.1` |
| PC2 | `192.168.2.102` | `255.255.255.0` | `192.168.2.1` |
| PC-ATK | `192.168.2.200` | `255.255.255.0` | `192.168.2.1` |

### 3.3 Server WS-HTTP e WS-HTTPS

Per ogni server: **clic → Desktop → IP Configuration**

| Server | IP | Mask | GW |
|--------|----|------|----|
| WS-HTTP | `192.168.2.10` | `255.255.255.0` | `192.168.2.1` |
| WS-HTTPS | `192.168.2.11` | `255.255.255.0` | `192.168.2.1` |

### 3.4 Verifica connettività

Da **PC0 → Desktop → Command Prompt**:
```
C:\> ping 192.168.2.10
C:\> ping 192.168.2.11
C:\> ping 192.168.2.1
```
Tutti i ping devono rispondere con successo.

📸 **Screenshot 3** — Schede IP Configuration di PC0, WS-HTTP e Router R1 affiancate, o finestra Command Prompt con ping riusciti.

---

## STEP 4 — Configurazione Web Server HTTP (Insicuro)

### 4.1 Attivare il servizio HTTP

Apri **WS-HTTP → Services → HTTP**:
- Verifica che **HTTP** sia impostato su **ON**
- Verifica che **HTTPS** sia impostato su **OFF** ← importante per questa simulazione

### 4.2 Creare la pagina web con form di login simulato

Nella scheda **Services → HTTP**, clicca su `index.html` nell'elenco dei file, poi su **Edit**. Sostituisci il contenuto con:

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <title>www.corp.local — Portale Aziendale</title>
  <style>
    body { font-family: Arial, sans-serif; background: #f0f0f0; }
    .login-box { background: white; padding: 30px; max-width: 350px;
                 margin: 80px auto; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,.2); }
    h2 { color: #c0392b; }
    input { width: 100%; padding: 8px; margin: 8px 0; box-sizing: border-box; }
    button { background: #c0392b; color: white; padding: 10px 20px; border: none; cursor: pointer; }
    .warning { color: #c0392b; font-size: 12px; margin-top: 10px; }
  </style>
</head>
<body>
  <div class="login-box">
    <h2>⚠️ Portale Corp — HTTP</h2>
    <p>Accesso area riservata dipendenti</p>
    <form method="GET" action="/login">
      <label>Username:</label>
      <input type="text" name="username" placeholder="mario.rossi">
      <label>Password:</label>
      <input type="password" name="password" placeholder="••••••••">
      <button type="submit">Accedi</button>
    </form>
    <p class="warning">⚠️ ATTENZIONE: questa pagina usa HTTP.<br>
    Le credenziali viaggiano in CHIARO sulla rete!</p>
  </div>
</body>
</html>
```

> ⚠️ **Nota didattica**: Il form usa `method="GET"` intenzionalmente — questo fa sì che username e password compaiano **in chiaro nell'URL** (es. `/login?username=mario.rossi&password=password123`), rendendo l'intercettazione ancora più evidente in Simulation Mode.

Salva il file e verifica aprendo un browser su **PC0 → Desktop → Web Browser**, digitando: `http://192.168.2.10`

📸 **Screenshot 4** — Browser di PC0 mostra la pagina di login del server HTTP insicuro.

---

## STEP 5 — Simulazione MITM/Sniffing (Simulation Mode)

> 🎯 **Obiettivo**: mostrare che con HTTP le credenziali sono visibili in chiaro, mentre con HTTPS il payload è cifrato.

### 5.1 Attivare la Simulation Mode

Nella barra inferiore di PT: clicca sul pulsante **Simulation** (orologio) oppure premi `Shift+S`.

Nel pannello Simulation a destra:
- Clicca su **Edit Filters**
- Spunta solo **HTTP** e **TCP** (deseleziona tutto il resto)
- Clicca **OK**

### 5.2 Inviare le credenziali sul server HTTP

Con la Simulation Mode attiva:
1. Apri il browser su **PC0** → `http://192.168.2.10`
2. Compila il form: username = `mario.rossi`, password = `Password123`
3. Clicca **Accedi**
4. Torna al pannello Simulation e clicca **Capture/Forward** più volte per avanzare il pacchetto

### 5.3 Analizzare il pacchetto HTTP

Clicca su una delle PDU HTTP nel pannello eventi.  
Nella finestra **PDU Information**, vai alla scheda **Inbound PDU Details** o **Outbound PDU Details**:

Dovresti vedere qualcosa simile a:
```
GET /login?username=mario.rossi&password=Password123 HTTP/1.1
Host: 192.168.2.10
User-Agent: Mozilla/4.0
Connection: keep-alive
```

> 🔴 **Osservazione**: le credenziali `mario.rossi` e `Password123` sono **completamente visibili** nel payload HTTP. Un attaccante sulla stessa rete (o un qualsiasi nodo intermedio) può leggerle senza alcun strumento speciale.

📸 **Screenshot 5** — Finestra PDU Information con le credenziali in chiaro visibili nel payload GET.

### 5.4 Confronto con HTTPS

1. Assicurati che WS-HTTPS abbia **HTTPS attivo** (vedi STEP 6)
2. Nei filtri Simulation, aggiungi **SSL/TLS** oltre a TCP
3. Apri il browser su **PC1** → `https://192.168.2.11`
4. Avanza i pacchetti in Simulation Mode

Osserva che i PDU HTTPS/TLS mostrano il payload **cifrato** — non è possibile leggere username e password.

> ✅ **Osservazione**: Con HTTPS, anche se l'attaccante intercetta il pacchetto, vede solo dati cifrati privi di significato senza la chiave privata del server.

📸 **Screenshot 6** — PDU HTTPS in Simulation Mode: payload non leggibile (dati cifrati).

---

## STEP 6 — Contromisura 1: Attivare HTTPS sul Server Sicuro

### 6.1 Configurazione WS-HTTPS

Apri **WS-HTTPS → Services → HTTP**:
- **HTTP** → **OFF**
- **HTTPS** → **ON**

### 6.2 Creare la pagina HTTPS

Nella scheda HTTP di WS-HTTPS, clicca su `index.html` → **Edit**:

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <title>secure.corp.local — Portale Sicuro</title>
  <style>
    body { font-family: Arial, sans-serif; background: #e8f5e9; }
    .login-box { background: white; padding: 30px; max-width: 350px;
                 margin: 80px auto; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,.2); }
    h2 { color: #27ae60; }
    input { width: 100%; padding: 8px; margin: 8px 0; box-sizing: border-box; }
    button { background: #27ae60; color: white; padding: 10px 20px; border: none; cursor: pointer; }
    .secure { color: #27ae60; font-size: 12px; margin-top: 10px; }
  </style>
</head>
<body>
  <div class="login-box">
    <h2>🔒 Portale Corp — HTTPS</h2>
    <p>Accesso sicuro area riservata dipendenti</p>
    <form method="POST" action="/login">
      <label>Username:</label>
      <input type="text" name="username" placeholder="mario.rossi">
      <label>Password:</label>
      <input type="password" name="password" placeholder="••••••••">
      <button type="submit">Accedi</button>
    </form>
    <p class="secure">✅ Connessione protetta da TLS.<br>
    Le credenziali sono cifrate end-to-end.</p>
  </div>
</body>
</html>
```

### 6.3 Test dal browser

Da **PC1 → Desktop → Web Browser**: `https://192.168.2.11`

La pagina deve caricarsi con la schermata del portale sicuro (PT mostra la connessione HTTPS).

> 💡 **Nota PT**: Cisco Packet Tracer implementa una versione semplificata di HTTPS. Non è possibile installare certificati personalizzati, ma il servizio cifra le comunicazioni e lo si può osservare in Simulation Mode.

📸 **Screenshot 7** — Browser di PC1 mostra il portale sicuro `secure.corp.local` via HTTPS.

---

## STEP 7 — Contromisura 2: HSTS e Redirect HTTP → HTTPS

> ⚠️ **Nota PT**: Cisco Packet Tracer non permette di configurare redirect HTTP→HTTPS lato server né header HTTP personalizzati. Questo step è **concettuale**: configura l'ACL sul router per bloccare il traffico HTTP non cifrato, e studia la teoria degli header HSTS.

### 7.1 ACL sul Router — Blocco HTTP (porta 80)

Apri la CLI di **R1**:

```
R1# configure terminal
R1(config)# ip access-list extended BLOCK_HTTP
R1(config-ext-nacl)# deny tcp any host 192.168.2.10 eq 80
R1(config-ext-nacl)# remark Blocca accesso al server HTTP non sicuro dall'esterno
R1(config-ext-nacl)# permit ip any any
R1(config-ext-nacl)# exit
R1(config)# interface GigabitEthernet0/0
R1(config-if)# ip access-group BLOCK_HTTP in
R1(config-if)# exit
R1(config)# end
R1# write memory
```

> ⚠️ In questa topologia l'ACL ha effetto limitato (router e client sono sulla stessa LAN), ma in un'architettura con router perimetrale bloccherebbe il traffico proveniente dall'esterno.

### 7.2 Teoria: Header HSTS

In una configurazione reale (Apache/Nginx), il server HTTPS risponde con:

```http
HTTP/1.1 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Type: text/html; charset=utf-8
```

**Cosa fa questo header**:
- `max-age=31536000` — il browser ricorderà per **1 anno** di usare solo HTTPS per questo dominio
- `includeSubDomains` — la politica si applica anche a tutti i sottodomini (`mail.corp.local`, `api.corp.local`, ecc.)
- `preload` — il dominio può essere incluso nella **HSTS Preload List** del browser (già noto come HTTPS anche alla primissima visita)

**Scenario SSL Stripping senza HSTS**:
1. Utente digita `corp.local` nel browser (HTTP per default)
2. Attaccante intercetta la richiesta HTTP
3. Attaccante parla HTTPS con il server ma HTTP con la vittima
4. Le credenziali della vittima viaggiano in chiaro verso l'attaccante

**Con HSTS**: il browser rifiuta direttamente connessioni HTTP, rendendo l'attacco impossibile.

📸 **Screenshot 8** — Schermata con la configurazione ACL sul router (`show access-lists`) oppure un documento/slide che mostra l'header HSTS spiegato.

---

## STEP 8 — Verifica Finale

### 8.1 Test comparativo HTTP vs HTTPS

| Test | Comando/Azione | Risultato atteso |
|------|---------------|------------------|
| Ping verso WS-HTTP | `ping 192.168.2.10` da PC0 | ✅ Risposta OK |
| Ping verso WS-HTTPS | `ping 192.168.2.11` da PC0 | ✅ Risposta OK |
| Browser HTTP | `http://192.168.2.10` da PC0 | ✅ Pagina login insicura |
| Browser HTTPS | `https://192.168.2.11` da PC1 | ✅ Pagina login sicura |
| Simulation HTTP | PDU GET con credenziali | 🔴 Credenziali visibili in chiaro |
| Simulation HTTPS | PDU TLS | ✅ Payload cifrato |
| ACL verifica | `show access-lists` su R1 | ✅ ACL configurata |

### 8.2 Confronto Simulation Mode

Attiva Simulation Mode con filtri HTTP+HTTPS+TCP e fai accedere contemporaneamente:
- PC0 → `http://192.168.2.10` (server HTTP)
- PC1 → `https://192.168.2.11` (server HTTPS)

Osserva i pacchetti: quelli HTTP mostrano i dati in chiaro, quelli HTTPS no.

📸 **Screenshot 9** — Simulation Mode con due flussi attivi: HTTP (leggibile) e HTTPS (cifrato) affiancati.

---

## STEP 9 — Salvataggio

1. **File → Save** oppure `Ctrl+S`
2. Nome file: `es05a_http_security.pkt`
3. Salva nella cartella del progetto

📸 **Screenshot 10** — Schermata con il file salvato visibile (titolo della finestra PT o finestra Esplora File con il file `.pkt`).

---

## 🔧 Troubleshooting

| Problema | Causa probabile | Soluzione |
|----------|----------------|-----------|
| Ping non funziona | Interfaccia router spenta | `interface Gi0/0` → `no shutdown` |
| Browser non carica HTTP | Servizio HTTP disattivato sul server | Services → HTTP → ON |
| Browser non carica HTTPS | Servizio HTTPS disattivato | Services → HTTP → HTTPS ON |
| Simulation Mode non mostra PDU | Filtri non configurati | Edit Filters → spunta HTTP e TCP |
| Payload PDU non visibile | Click sulla PDU sbagliata | Clicca sulla busta colorata nel canvas |
| ACL blocca tutto | Manca `permit ip any any` | Aggiungere la regola permissiva in fondo |
| LED del cavo rosso | Cavo sbagliato o porta shutdown | Usare Straight-Through, verificare shutdown |

---

## 📝 Note Tecniche — Limitazioni di Packet Tracer

Cisco Packet Tracer è uno strumento didattico con alcune **limitazioni** per la simulazione della sicurezza web:

| Funzionalità | In PT | Nella realtà |
|---|---|---|
| Cifratura HTTPS | ✅ Simulata (payload non leggibile in Simulation Mode) | ✅ TLS reale |
| Certificati personalizzati | ❌ Non configurabili | ✅ Certificati X.509 con CA |
| Header HTTP personalizzati | ❌ Non supportati nella GUI | ✅ Configurabili in Apache/Nginx |
| HSTS runtime | ❌ Non simulabile | ✅ Header inviato dal server |
| XSS / SQL Injection | ❌ Non simulabili | ✅ Testabili con DVWA, OWASP WebGoat |
| WAF | ❌ Non presente | ✅ ModSecurity, Cloudflare WAF, ecc. |
| Sniffing reale | ❌ Solo Simulation Mode | ✅ Wireshark su rete reale |

> 💡 Per approfondire la simulazione di attacchi web, strumenti come **OWASP WebGoat**, **DVWA** (Damn Vulnerable Web Application) o **TryHackMe** (piattaforma online) offrono ambienti sicuri e legali per fare pratica. Questi sono adatti a studenti avanzati con supervisione del docente.
