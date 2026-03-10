# 01 — Il Protocollo HTTP

## Cos'è HTTP?

**HTTP** (*HyperText Transfer Protocol*) è il protocollo applicativo che definisce le regole per la comunicazione tra client web (browser) e server web. È il protocollo fondamentale del World Wide Web: ogni volta che un browser carica una pagina, scarica un'immagine o invia un form, utilizza HTTP.

HTTP opera al **Livello 7 (Applicazione)** del modello OSI e si appoggia su **TCP** al livello 4 (Transport), tipicamente sulla porta **80** (HTTP) o **443** (HTTPS).

---

## Storia e Versioni di HTTP

### HTTP/0.9 (1991)
La versione originale, estremamente semplice. Supportava solo il metodo `GET` e restituiva direttamente il corpo HTML senza header. Nessuna negoziazione di contenuto, nessun codice di stato.

```
GET /pagina.html
```

### HTTP/1.0 (1996 — RFC 1945)
Introduce:
- Header HTTP (sia di richiesta che di risposta)
- Codici di stato (200, 404, 500…)
- Il metodo `POST`
- `Content-Type` per specificare il tipo di risorsa
- **Connessioni non persistenti**: una nuova connessione TCP per ogni richiesta/risposta

Limitazione: overhead elevato per pagine con molte risorse (immagini, CSS, JS).

### HTTP/1.1 (1997 — RFC 2616, aggiornato RFC 7230-7235)
Standard dominante per oltre 15 anni. Principali novità:
- **Connessioni persistenti** (`keep-alive`): la connessione TCP rimane aperta per più richieste
- **Pipelining**: invio di più richieste senza attendere le risposte (limitato nella pratica)
- **Chunked Transfer Encoding**: invio di risposta in blocchi (body di dimensione non nota)
- **Virtual hosting** obbligatorio con header `Host:`
- Nuovi metodi: `PUT`, `DELETE`, `OPTIONS`, `HEAD`, `TRACE`
- **Range requests**: download parziale di file (es. `Range: bytes=0-1023`)

### HTTP/2 (2015 — RFC 7540)
Rivoluziona le prestazioni mantenendo la semantica di HTTP/1.1:
- **Multiplexing**: più richieste/risposte simultanee sulla stessa connessione TCP (elimina il *head-of-line blocking* a livello applicativo)
- **Header compression** (HPACK): riduce l'overhead degli header ripetuti
- **Server push**: il server può inviare risorse al client prima che le richieda
- **Formato binario** (non più testuale): più efficiente da parsare
- Richiede praticamente sempre HTTPS nella realtà

### HTTP/3 (2022 — RFC 9114)
Sostituisce TCP con **QUIC** (UDP + affidabilità + cifratura integrata):
- Elimina il *head-of-line blocking* anche a livello di trasporto
- Connessioni più veloci (0-RTT o 1-RTT handshake)
- Migliore gestione della perdita di pacchetti
- Cifratura integrata (TLS 1.3 obbligatorio)

---

## Modello Client-Server e Statelessness

HTTP segue il modello **client-server** dove:
- Il **client** (tipicamente un browser) **avvia sempre** la comunicazione inviando una richiesta
- Il **server** attende richieste e risponde con la risorsa richiesta o un messaggio di errore
- Ogni richiesta è **indipendente** dalla precedente: HTTP è **stateless** (senza stato)

### Cosa significa stateless?
Il server non "ricorda" le richieste precedenti. Ogni richiesta viene trattata come nuova. Per mantenere lo stato (es. login utente, carrello acquisti) si usano meccanismi aggiuntivi: **cookie**, **sessioni**, **token**.

```
Client                          Server
  |                               |
  |  --- HTTP GET /index.html --> |  (Richiesta 1)
  |  <-- HTTP 200 OK + HTML ----- |  (Risposta 1)
  |                               |
  |  --- HTTP GET /style.css ---> |  (Richiesta 2 — il server non "ricorda" la 1)
  |  <-- HTTP 200 OK + CSS -----  |  (Risposta 2)
  |                               |
```

---

## Struttura di una Richiesta HTTP

Una richiesta HTTP è composta da 4 parti:

```
┌─────────────────────────────────────────────────────────────┐
│  RIGA DI RICHIESTA (Request Line)                           │
│  METODO  SPAZIO  URL  SPAZIO  VERSIONE  CRLF                │
├─────────────────────────────────────────────────────────────┤
│  HEADER                                                     │
│  NomeHeader: Valore  CRLF                                   │
│  NomeHeader: Valore  CRLF                                   │
│  ...                                                        │
├─────────────────────────────────────────────────────────────┤
│  RIGA VUOTA (CRLF obbligatoria — separa header da body)     │
├─────────────────────────────────────────────────────────────┤
│  BODY (opzionale — presente in POST, PUT, PATCH)            │
│  username=mario&password=secret123                          │
└─────────────────────────────────────────────────────────────┘
```

### Esempio reale: GET di una pagina

```http
GET /prodotti/laptop.html HTTP/1.1
Host: www.negozio.it
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: it-IT,it;q=0.9,en;q=0.8
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cookie: session_id=abc123def456; preferenza_lingua=it

```
*(riga vuota finale obbligatoria)*

### Esempio reale: POST di un form di login

```http
POST /login HTTP/1.1
Host: www.portale.it
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0
Content-Type: application/x-www-form-urlencoded
Content-Length: 35
Connection: keep-alive

username=mario&password=secret123
```

---

## Struttura di una Risposta HTTP

```
┌─────────────────────────────────────────────────────────────┐
│  RIGA DI STATO (Status Line)                                │
│  VERSIONE  SPAZIO  CODICE  SPAZIO  FRASE  CRLF              │
├─────────────────────────────────────────────────────────────┤
│  HEADER DI RISPOSTA                                         │
│  NomeHeader: Valore  CRLF                                   │
│  NomeHeader: Valore  CRLF                                   │
│  ...                                                        │
├─────────────────────────────────────────────────────────────┤
│  RIGA VUOTA (CRLF obbligatoria)                             │
├─────────────────────────────────────────────────────────────┤
│  BODY (HTML, JSON, immagine, ecc.)                          │
│  <!DOCTYPE html><html>...                                   │
└─────────────────────────────────────────────────────────────┘
```

### Esempio reale: risposta 200 OK con pagina HTML

```http
HTTP/1.1 200 OK
Date: Mon, 15 Jan 2024 10:30:00 GMT
Server: Apache/2.4.54 (Ubuntu)
Content-Type: text/html; charset=UTF-8
Content-Length: 1542
Cache-Control: max-age=300
Last-Modified: Sun, 14 Jan 2024 08:00:00 GMT
Connection: keep-alive

<!DOCTYPE html>
<html lang="it">
<head><title>Laptop Gaming</title></head>
<body>
  <h1>Laptop Gaming Pro X500</h1>
  ...
</body>
</html>
```

### Esempio: risposta 404 Not Found

```http
HTTP/1.1 404 Not Found
Date: Mon, 15 Jan 2024 10:30:05 GMT
Server: Apache/2.4.54 (Ubuntu)
Content-Type: text/html; charset=UTF-8
Content-Length: 245

<!DOCTYPE html>
<html><body><h1>404 - Pagina non trovata</h1></body></html>
```

---

## Metodi HTTP

| Metodo | Descrizione | Body richiesta | Idempotente | Sicuro |
|--------|-------------|---------------|-------------|--------|
| **GET** | Recupera una risorsa | No | ✅ Sì | ✅ Sì |
| **POST** | Invia dati / crea risorsa | ✅ Sì | ❌ No | ❌ No |
| **PUT** | Crea o sostituisce risorsa | ✅ Sì | ✅ Sì | ❌ No |
| **DELETE** | Elimina una risorsa | No | ✅ Sì | ❌ No |
| **HEAD** | Come GET ma solo header | No | ✅ Sì | ✅ Sì |
| **OPTIONS** | Metodi supportati dal server | No | ✅ Sì | ✅ Sì |
| **PATCH** | Modifica parziale risorsa | ✅ Sì | ❌ No | ❌ No |

> 💡 **Idempotente** = ripetere la stessa richiesta N volte produce sempre lo stesso risultato (es. GET della stessa pagina, DELETE della stessa risorsa). **Sicuro** = la richiesta non modifica lo stato del server.

### Dettaglio metodi principali

#### GET
Il metodo più usato. Recupera una risorsa identificata dall'URL. I parametri passati sono visibili nell'URL (query string).
```http
GET /ricerca?q=laptop+gaming&ordine=prezzo HTTP/1.1
```
> ⚠️ Non usare GET per inviare password o dati sensibili: sono visibili nella URL e nei log del server.

#### POST
Invia dati al server per elaborarli (es. form di login, upload file, creazione record). I dati sono nel body della richiesta, non nell'URL.
```http
POST /api/ordini HTTP/1.1
Content-Type: application/json

{"prodotto": "laptop", "quantita": 2, "cliente_id": 42}
```

#### PUT
Crea o sostituisce completamente una risorsa specifica. Se la risorsa esiste, viene sovrascritta.
```http
PUT /api/utenti/42 HTTP/1.1
Content-Type: application/json

{"nome": "Mario", "email": "mario@esempio.it", "ruolo": "admin"}
```

#### DELETE
Elimina la risorsa identificata dall'URL.
```http
DELETE /api/prodotti/123 HTTP/1.1
```

#### HEAD
Identico a GET ma il server restituisce solo gli header, senza body. Utile per verificare se una risorsa esiste o per controllare la data di modifica senza scaricarla.

---

## Struttura di un URL

```
https://www.esempio.it:8080/percorso/pagina.html?chiave=valore&foo=bar#sezione
│       │              │    │                   │                    │
│       │              │    │                   │                    └── Fragment (ancora)
│       │              │    │                   └── Query string (parametri)
│       │              │    └── Path (percorso della risorsa)
│       │              └── Porta (opzionale — default: 80 HTTP, 443 HTTPS)
│       └── Host (dominio o IP)
└── Schema (protocollo)
```

| Componente | Esempio | Note |
|------------|---------|------|
| Schema | `https` | Protocollo da usare |
| Host | `www.esempio.it` | Dominio o indirizzo IP |
| Porta | `:8080` | Opzionale (default 80/443) |
| Path | `/percorso/pagina.html` | Percorso della risorsa sul server |
| Query string | `?chiave=valore&foo=bar` | Parametri chiave=valore separati da `&` |
| Fragment | `#sezione` | Ancora nel documento (gestita dal browser, non inviata al server) |

---

## Connessioni HTTP: Evoluzione

### HTTP/1.0 — Una connessione per richiesta
```
Client      Server
  |-- TCP SYN -->|          (apertura connessione)
  |<- TCP SYN/ACK -|
  |-- TCP ACK -->|
  |-- GET /index.html -->|  (richiesta 1)
  |<-- 200 OK + HTML ----|  (risposta 1)
  |-- TCP FIN -->|          (chiusura)
  |-- TCP SYN -->|          (NUOVA connessione per la richiesta 2!)
  ...
```
**Problema**: 3-way handshake TCP per ogni risorsa (lento con pagine complesse).

### HTTP/1.1 — Connessioni persistenti (keep-alive)
```
Client      Server
  |-- TCP SYN -->|          (apertura connessione — UNA SOLA VOLTA)
  |-- GET /index.html -->|  (richiesta 1)
  |<-- 200 OK + HTML ----|  (risposta 1)
  |-- GET /style.css --->|  (richiesta 2 — stessa connessione!)
  |<-- 200 OK + CSS -----|  (risposta 2)
  |-- GET /logo.png ---->|  (richiesta 3)
  |<-- 200 OK + PNG -----|  (risposta 3)
  |-- TCP FIN -->|          (chiusura solo alla fine)
```

### HTTP/2 — Multiplexing
```
Client          Server
  |==[stream 1: GET /index.html ]==>|
  |==[stream 2: GET /style.css  ]==>|  ← richieste simultanee
  |==[stream 3: GET /logo.png   ]==>|  ← sulla stessa connessione TCP
  |
  |<=[stream 1: 200 OK + HTML  ]==|
  |<=[stream 3: 200 OK + PNG   ]==|  ← risposte in qualsiasi ordine
  |<=[stream 2: 200 OK + CSS   ]==|
```

---

## Configurazione Web Server in Cisco Packet Tracer

### Passo 1 — Aggiungere il server
1. Dal menu in basso: **End Devices** → **Servers** → trascina un **Generic Server**

### Passo 2 — Configurare l'IP
1. Clicca sul server → **Desktop** → **IP Configuration**
2. Inserisci IP, subnet mask, gateway e DNS server

### Passo 3 — Attivare il servizio HTTP
1. Clicca sul server → **Services** → **HTTP**
2. Imposta **HTTP: On** (porta 80)
3. Imposta **HTTPS: On** (porta 443) se richiesto

### Passo 4 — Modificare la pagina web
1. Nella sezione HTTP, nella lista file, clicca su `index.html`
2. Clicca **Edit** per aprire l'editor HTML
3. Modifica il contenuto HTML a piacere
4. Clicca **Save**

### Passo 5 — Aggiungere altre pagine
1. Nel campo **File Name** digita il nome della nuova pagina (es. `prodotti.html`)
2. Clicca **New File** oppure inserisci il contenuto e clicca **Save**

### Passo 6 — Test dal browser
1. Vai su un PC client → **Desktop** → **Web Browser**
2. Digita l'URL: `http://192.168.1.10` oppure `http://www.azienda.local` (se DNS configurato)
3. Premi **Go**

---

## Strumenti per Testare HTTP (Uso Reale)

> ⚠️ Questi strumenti non sono disponibili in Cisco Packet Tracer, ma sono fondamentali nella pratica reale.

### curl (command line)
```bash
# GET semplice
curl http://www.esempio.it

# Mostra anche gli header della risposta
curl -I http://www.esempio.it        # Solo header (HEAD request)
curl -v http://www.esempio.it        # Verbose: tutto il dialogo HTTP

# POST con dati
curl -X POST -d "user=mario&pass=secret" http://www.esempio.it/login

# POST con JSON
curl -X POST -H "Content-Type: application/json" \
     -d '{"nome":"Mario"}' http://api.esempio.it/utenti
```

### wget
```bash
# Scarica una pagina
wget http://www.esempio.it/pagina.html

# Scarica e mostra gli header
wget --server-response http://www.esempio.it/pagina.html
```

### Browser DevTools (F12)
- Tab **Network**: mostra ogni richiesta HTTP, status code, header, timing
- Tab **Console**: errori JavaScript che impattano le richieste
- Filtri: XHR/Fetch per vedere solo le chiamate API, Doc per documenti HTML

---

> 📖 Continua con: [02_Codici_Stato_Header.md](02_Codici_Stato_Header.md) — Tutti i codici di stato e gli header HTTP
