# 1. Introduzione al Protocollo HTTP

## 1.1 Cos'è HTTP (HyperText Transfer Protocol)

**HTTP** (HyperText Transfer Protocol) è il protocollo fondamentale per la comunicazione sul World Wide Web. Si tratta di un **protocollo di livello applicativo** che definisce come i messaggi vengono formattati e trasmessi, e quali azioni i server web e i browser devono intraprendere in risposta a vari comandi.

### Definizione Tecnica

HTTP è un protocollo:
- **Stateless** (senza stato): ogni richiesta è indipendente dalle precedenti
- **Client-Server**: basato su un modello richiesta-risposta
- **Testuale**: i comandi sono in formato testo leggibile (fino a HTTP/1.1)
- **Request-Response**: ogni interazione consiste in una richiesta seguita da una risposta

### Scopo Principale

HTTP è stato progettato per trasferire ipertesti (documenti HTML), ma oggi viene utilizzato per:
- Trasferimento di pagine web (HTML, CSS, JavaScript)
- Download e upload di file
- API RESTful per comunicazione tra applicazioni
- Streaming di contenuti multimediali
- Comunicazione tra microservizi
- IoT (Internet of Things) e comunicazione machine-to-machine

### Caratteristiche Chiave

```
Client (Browser)                    Server Web
     |                                  |
     |  1. HTTP Request                 |
     |--------------------------------->|
     |                                  |
     |  2. HTTP Response                |
     |<---------------------------------|
     |                                  |
```

**Esempio di richiesta HTTP:**
```http
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0
Accept: text/html
```

**Esempio di risposta HTTP:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1234

<!DOCTYPE html>
<html>
<head><title>Example</title></head>
<body><h1>Hello World!</h1></body>
</html>
```

## 1.2 Storia ed Evoluzione

### 1.2.1 HTTP/0.9 (1991) - "Il Protocollo One-Line"

**Anno**: 1991  
**Creatore**: Tim Berners-Lee al CERN

HTTP/0.9 era estremamente semplice:

**Caratteristiche:**
- Una sola riga per la richiesta
- Nessun header
- Solo metodo GET
- Solo documenti HTML
- Connessione chiusa dopo ogni richiesta

**Esempio di comunicazione HTTP/0.9:**
```http
GET /index.html
```

**Risposta:**
```html
<html>
  Un semplice documento HTML
</html>
```

**Limitazioni:**
- Nessuna informazione sui metadati
- Nessun codice di stato
- Nessuna gestione errori
- Solo contenuto HTML

### 1.2.2 HTTP/1.0 (1996)

**Anno**: 1996  
**RFC**: RFC 1945

HTTP/1.0 introdusse molte funzionalità essenziali:

**Novità principali:**
- **Headers**: sia nelle richieste che nelle risposte
- **Status codes**: per indicare successo o fallimento
- **Versione del protocollo** nella richiesta
- **Metodi aggiuntivi**: POST, HEAD
- **Content-Type**: supporto per diversi tipi di contenuto (immagini, video, etc.)
- **Autorizzazione**: meccanismi di autenticazione base

**Esempio HTTP/1.0:**
```http
GET /images/logo.png HTTP/1.0
Host: www.example.com
User-Agent: Mozilla/5.0
Accept: image/png

```

**Risposta:**
```http
HTTP/1.0 200 OK
Content-Type: image/png
Content-Length: 12345
Date: Thu, 30 Oct 2025 10:00:00 GMT

[dati binari dell'immagine]
```

**Limitazioni:**
- Ogni richiesta richiedeva una nuova connessione TCP
- Overhead significativo per connessioni multiple
- Nessuna compressione dei dati

### 1.2.3 HTTP/1.1 (1997)

**Anno**: 1997 (rivisto nel 1999)  
**RFC**: RFC 2068, poi RFC 2616, poi RFC 7230-7237

HTTP/1.1 divenne lo standard dominante per oltre 15 anni.

**Miglioramenti principali:**

1. **Connessioni Persistenti (Keep-Alive)**
   ```http
   Connection: keep-alive
   ```
   Una singola connessione TCP può gestire multiple richieste/risposte.

2. **Pipelining**
   Il client può inviare multiple richieste senza attendere le risposte.

3. **Host Header Obbligatorio**
   ```http
   Host: www.example.com
   ```
   Permette hosting virtuale (più siti sullo stesso IP).

4. **Chunked Transfer Encoding**
   ```http
   Transfer-Encoding: chunked
   ```
   Trasmissione di dati senza conoscere la dimensione totale.

5. **Range Requests**
   ```http
   Range: bytes=0-1023
   ```
   Download parziale di risorse.

6. **Nuovi metodi**: PUT, DELETE, OPTIONS, TRACE, CONNECT

7. **Cache avanzata**: meccanismi sofisticati di caching

8. **Content negotiation**: negoziazione di lingua, encoding, tipo di contenuto

**Esempio completo HTTP/1.1:**
```http
GET /api/users/123 HTTP/1.1
Host: api.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Accept: application/json
Accept-Language: it-IT,it;q=0.9,en;q=0.8
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cache-Control: no-cache
```

**Risposta:**
```http
HTTP/1.1 200 OK
Date: Thu, 30 Oct 2025 10:00:00 GMT
Server: Apache/2.4.41
Content-Type: application/json; charset=utf-8
Content-Length: 187
Cache-Control: max-age=3600
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
Connection: keep-alive

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Problemi di HTTP/1.1:**
- **Head-of-Line Blocking**: una richiesta lenta blocca le successive
- **Overhead degli header**: header ripetuti in ogni richiesta
- **Limite di connessioni parallele**: i browser limitano a 6-8 connessioni per dominio

### 1.2.4 HTTP/2 (2015)

**Anno**: 2015  
**RFC**: RFC 7540

HTTP/2 rivoluziona il protocollo mantenendo la semantica di HTTP/1.1.

**Caratteristiche rivoluzionarie:**

1. **Protocollo Binario**
   - Non più testuale, ma binario
   - Più efficiente da parsare
   - Meno errori di implementazione

2. **Multiplexing**
   ```
   Una singola connessione TCP
   
   Stream 1: GET /style.css
   Stream 3: GET /script.js
   Stream 5: GET /image.png
   Stream 7: GET /data.json
   
   Tutte in parallelo sulla stessa connessione!
   ```

3. **Server Push**
   Il server può inviare risorse prima che il client le richieda:
   ```
   Client richiede: /index.html
   Server invia:
     - /index.html (richiesto)
     - /style.css (push)
     - /script.js (push)
   ```

4. **Header Compression (HPACK)**
   Gli header vengono compressi riducendo l'overhead.

5. **Stream Prioritization**
   Il client può indicare quali risorse sono più importanti.

**Benefici:**
- Riduzione drastica della latenza
- Miglior utilizzo della banda
- Eliminazione del head-of-line blocking a livello HTTP
- Meno connessioni TCP necessarie

**Esempio concettuale:**
```
HTTP/1.1: 6 connessioni TCP per 6 risorse
HTTP/2:   1 connessione TCP per 6 risorse (multiplexing)
```

**Adozione:**
- Oltre il 50% dei siti web al 2025
- Supportato da tutti i browser moderni
- Richiede HTTPS nella maggior parte dei casi

### 1.2.5 HTTP/3 (2022)

**Anno**: 2022  
**RFC**: RFC 9114

HTTP/3 rappresenta un cambio ancora più radicale: passa da TCP a UDP.

**La Rivoluzione: QUIC**

HTTP/3 è basato su **QUIC** (Quick UDP Internet Connections), sviluppato originariamente da Google.

**Perché UDP invece di TCP?**

TCP ha problemi intrinseci:
- Head-of-line blocking a livello di trasporto
- Handshake lento (3-way)
- Difficoltà con connessioni mobili (cambio di rete)

**Caratteristiche di HTTP/3:**

1. **Zero RTT (Round Trip Time)**
   ```
   HTTP/1.1 + TLS 1.2: 3 RTT per iniziare
   HTTP/2 + TLS 1.3:   2 RTT per iniziare
   HTTP/3:             0-1 RTT per iniziare
   ```

2. **Connection Migration**
   La connessione sopravvive ai cambi di rete:
   ```
   WiFi casa -> Rete 4G -> WiFi ufficio
   (stessa connessione HTTP/3!)
   ```

3. **Multiplexing Migliorato**
   Eliminato il head-of-line blocking anche a livello di trasporto.

4. **Encryption Built-in**
   QUIC include TLS 1.3 nativamente.

**Architettura:**
```
HTTP/1.1:  HTTP -> TCP -> IP
HTTP/2:    HTTP/2 -> TCP -> IP
HTTP/3:    HTTP/3 -> QUIC -> UDP -> IP
```

**Vantaggi:**
- Connessioni più veloci (specialmente su reti mobili)
- Migliore gestione della perdita di pacchetti
- Handshake più rapido
- Migliore esperienza su reti instabili

**Sfide:**
- Alcuni firewall bloccano UDP
- Maggiore utilizzo CPU
- Adozione ancora in corso

**Adozione al 2025:**
- ~35% dei siti web
- Supportato da Chrome, Firefox, Safari, Edge
- Principalmente grandi CDN e servizi (Google, Facebook, Cloudflare)

## 1.3 Caratteristiche Principali

### 1.3.1 Protocollo Stateless

**Definizione**: HTTP è un protocollo **senza stato**, il che significa che ogni richiesta è completamente indipendente dalle precedenti.

**Implicazioni:**

```
Richiesta 1: GET /login -> Risposta: 200 OK
Richiesta 2: GET /dashboard
              ^
              |
Il server NON ricorda la richiesta precedente!
```

**Vantaggi:**
- ✅ **Semplicità**: il server non deve mantenere stato tra richieste
- ✅ **Scalabilità**: facile distribuire il carico su più server
- ✅ **Affidabilità**: nessun problema se una richiesta fallisce
- ✅ **Caching**: più facile cachare risposte indipendenti

**Svantaggi:**
- ❌ Necessità di meccanismi esterni per mantenere lo stato (cookies, sessioni)
- ❌ Overhead per trasmettere informazioni di contesto in ogni richiesta

**Soluzioni per Gestire lo Stato:**

1. **Cookies**
   ```http
   # Prima richiesta - Login
   POST /login HTTP/1.1
   Content-Type: application/json
   
   {"username": "mario", "password": "secret"}
   
   # Risposta
   HTTP/1.1 200 OK
   Set-Cookie: sessionid=abc123; Path=/; HttpOnly
   
   # Richieste successive
   GET /dashboard HTTP/1.1
   Cookie: sessionid=abc123
   ```

2. **Tokens (JWT)**
   ```http
   # Risposta del login
   {
     "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
   }
   
   # Richieste successive
   GET /api/data HTTP/1.1
   Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   ```

3. **URL Parameters**
   ```http
   GET /dashboard?session=abc123 HTTP/1.1
   ```

### 1.3.2 Architettura Client-Server

HTTP implementa il modello **client-server**, dove:

**Client (User Agent):**
- Inizia la comunicazione
- Invia richieste HTTP
- Attende risposte
- Esempi: browser web, app mobile, script, tool come curl

**Server:**
- Rimane in ascolto di richieste
- Elabora le richieste
- Invia risposte
- Esempi: Apache, Nginx, IIS, Node.js server

```
┌─────────────┐                ┌─────────────┐
│   CLIENT    │                │   SERVER    │
│             │                │             │
│  - Browser  │   REQUEST      │  - Apache   │
│  - Mobile   │───────────────>│  - Nginx    │
│  - Script   │                │  - Node.js  │
│             │   RESPONSE     │             │
│             │<───────────────│             │
└─────────────┘                └─────────────┘
```

**Responsabilità del Client:**
- Costruire richieste HTTP valide
- Gestire le risposte
- Interpretare i codici di stato
- Gestire redirect, errori, timeout
- Implementare retry logic
- Gestire cookies e autenticazione

**Responsabilità del Server:**
- Ascoltare su una porta (tipicamente 80 per HTTP, 443 per HTTPS)
- Parsare richieste HTTP
- Validare richieste
- Eseguire la logica applicativa
- Costruire risposte HTTP valide
- Gestire errori
- Implementare sicurezza e autenticazione

**Vantaggi dell'Architettura Client-Server:**
- ✅ **Separazione delle responsabilità**
- ✅ **Centralizzazione della logica** sul server
- ✅ **Sicurezza**: il server controlla l'accesso ai dati
- ✅ **Aggiornamenti**: modifiche al server senza aggiornare i client
- ✅ **Scalabilità**: possibile scalare server indipendentemente

### 1.3.3 Request/Response Model

HTTP si basa su un modello **richiesta-risposta sincrono**:

```
Timeline:

Client                          Server
  |                               |
  |  1. Apre connessione TCP      |
  |------------------------------>|
  |                               |
  |  2. Invia HTTP Request        |
  |------------------------------>|
  |                               |
  |     3. Elabora richiesta      |
  |                               |
  |  4. Riceve HTTP Response      |
  |<------------------------------|
  |                               |
  |  5. Chiude connessione        |
  |   (o la mantiene aperta)      |
```

**Struttura di una Richiesta:**
```http
[METODO] [URI] [VERSIONE]        <- Request Line
[Header-Name]: [Header-Value]    <- Headers
[Header-Name]: [Header-Value]
                                 <- Linea vuota
[Body opzionale]                 <- Body
```

**Struttura di una Risposta:**
```http
[VERSIONE] [STATUS-CODE] [REASON] <- Status Line
[Header-Name]: [Header-Value]     <- Headers
[Header-Name]: [Header-Value]
                                  <- Linea vuota
[Body opzionale]                  <- Body
```

**Esempio Completo:**

```http
# RICHIESTA
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 45
User-Agent: MyApp/1.0

{"name":"Mario","email":"mario@example.com"}

# RISPOSTA
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/users/123
Content-Length: 78
Date: Thu, 30 Oct 2025 10:00:00 GMT

{"id":123,"name":"Mario","email":"mario@example.com","created_at":"2025-10-30T10:00:00Z"}
```

**Caratteristiche del Modello:**
- **Sincrono**: il client attende la risposta prima di procedere
- **Uno-a-uno**: una richiesta produce una risposta
- **Completo**: la risposta contiene tutto il necessario
- **Finale**: dopo la risposta, la transazione è completa

## 1.4 Il Ruolo di HTTP nel Web Moderno

HTTP è diventato molto più del semplice protocollo per trasferire pagine HTML:

### Applicazioni Moderne di HTTP

1. **Web Applications (SPA - Single Page Applications)**
   ```
   Browser -> API REST (HTTP/JSON) -> Server
   ```

2. **Mobile Apps**
   ```
   App iOS/Android -> HTTP API -> Backend
   ```

3. **Microservizi**
   ```
   Service A -> HTTP -> Service B -> HTTP -> Service C
   ```

4. **IoT (Internet of Things)**
   ```
   Sensore -> HTTP -> Cloud Platform
   ```

5. **API Pubbliche**
   ```
   Applicazioni Third-party -> HTTP API -> Provider (Google, Twitter, etc.)
   ```

6. **Content Delivery**
   ```
   User -> CDN (HTTP) -> Origin Server
   ```

### Ecosistema HTTP

```
┌─────────────────────────────────────────────┐
│         Applicazioni Web Moderne            │
├─────────────────────────────────────────────┤
│  REST APIs  │  GraphQL  │  gRPC (HTTP/2)   │
├─────────────────────────────────────────────┤
│         HTTP/1.1, HTTP/2, HTTP/3            │
├─────────────────────────────────────────────┤
│              TLS/SSL (HTTPS)                │
├─────────────────────────────────────────────┤
│         TCP (HTTP/1-2) o UDP (HTTP/3)       │
├─────────────────────────────────────────────┤
│                     IP                       │
└─────────────────────────────────────────────┘
```

## 1.5 HTTP vs HTTPS: Differenze Fondamentali

### HTTP (HyperText Transfer Protocol)

**Porta**: 80  
**Schema URL**: `http://`

**Caratteristiche:**
- ✅ Semplice da implementare
- ✅ Nessun overhead crittografico
- ✅ Debugging facile (traffico leggibile)
- ❌ **NON sicuro**: dati in chiaro
- ❌ **NON privato**: chiunque può intercettare
- ❌ **NON integro**: i dati possono essere modificati
- ❌ Penalizzato da browser e motori di ricerca

**Flusso HTTP:**
```
Client                    Internet                    Server
  |                          |                          |
  |  GET /data (CHIARO)      |                          |
  |------------------------->|------------------------->|
  |    CHIUNQUE PUÒ LEGGERE! |                          |
  |                          |                          |
  |  Response (CHIARO)       |                          |
  |<-------------------------|<-------------------------|
```

### HTTPS (HTTP Secure)

**Porta**: 443  
**Schema URL**: `https://`

**Caratteristiche:**
- ✅ **Crittografia**: i dati sono cifrati
- ✅ **Autenticazione**: verifica l'identità del server
- ✅ **Integrità**: i dati non possono essere modificati
- ✅ Richiesto per molte API moderne (geolocalizzazione, webcam, etc.)
- ✅ Migliore ranking SEO
- ✅ Fiducia degli utenti (lucchetto nel browser)
- ❌ Leggero overhead computazionale
- ❌ Richiede certificati SSL/TLS
- ❌ Debugging più complesso

**Flusso HTTPS:**
```
Client                    Internet                    Server
  |                          |                          |
  | 1. TLS Handshake         |                          |
  |<========================================SECURE======>|
  |                          |                          |
  | 2. GET /data (CIFRATO)   |                          |
  |------------------------->|------------------------->|
  |    ??????????????????? (Non leggibile)               |
  |                          |                          |
  | 3. Response (CIFRATO)    |                          |
  |<-------------------------|<-------------------------|
```

### Confronto Diretto

| Aspetto | HTTP | HTTPS |
|---------|------|-------|
| Sicurezza | ❌ Nessuna | ✅ Crittografia TLS/SSL |
| Porta | 80 | 443 |
| Certificato | ❌ Non richiesto | ✅ Richiesto |
| Velocità | Leggermente più veloce | Overhead minimo (HTTP/2 compensa) |
| SEO | Penalizzato | Favorito |
| Dati sensibili | ❌ MAI usare | ✅ Obbligatorio |
| API moderne | ❌ Non supportate | ✅ Richiesto |
| Costo | Gratuito | Certificato (può essere gratuito con Let's Encrypt) |

### Quando Usare HTTP vs HTTPS

**HTTP (casi limitati):**
- ⚠️ Sviluppo locale (localhost)
- ⚠️ Reti interne isolate
- ⚠️ Contenuti pubblici non sensibili (rare eccezioni)

**HTTPS (sempre!):**
- ✅ **Qualsiasi sito in produzione**
- ✅ Login e autenticazione
- ✅ Dati personali
- ✅ E-commerce e pagamenti
- ✅ API pubbliche
- ✅ Qualsiasi comunicazione importante

### Migrazione da HTTP a HTTPS

**Best Practices:**

1. **Ottieni un certificato SSL/TLS**
   - Let's Encrypt (gratuito)
   - Commercial CA (a pagamento)

2. **Configura il server**
   ```nginx
   # Nginx
   server {
       listen 443 ssl http2;
       server_name example.com;
       
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       # ... resto della configurazione
   }
   ```

3. **Redirect da HTTP a HTTPS**
   ```nginx
   server {
       listen 80;
       server_name example.com;
       return 301 https://$server_name$request_uri;
   }
   ```

4. **Usa HSTS (HTTP Strict Transport Security)**
   ```http
   Strict-Transport-Security: max-age=31536000; includeSubDomains
   ```

5. **Aggiorna tutti i link interni**

6. **Aggiorna sitemap e robots.txt**

### Visualizzazione nel Browser

**HTTP:**
```
⚠️ Non sicuro | http://example.com
```

**HTTPS:**
```
🔒 Sicuro | https://example.com
```

---

## Riepilogo

HTTP è il protocollo fondamentale del web che ha attraversato un'evoluzione straordinaria:

- **HTTP/0.9 (1991)**: Protocollo minimale, solo GET
- **HTTP/1.0 (1996)**: Headers, status codes, metodi multipli
- **HTTP/1.1 (1997)**: Connessioni persistenti, caching, standard dominante
- **HTTP/2 (2015)**: Binario, multiplexing, server push
- **HTTP/3 (2022)**: QUIC, UDP, zero RTT

Le caratteristiche chiave di HTTP sono:
1. **Stateless**: ogni richiesta è indipendente
2. **Client-Server**: architettura separata
3. **Request-Response**: modello sincrono di comunicazione

Nel web moderno, **HTTPS è obbligatorio** per garantire sicurezza, privacy e integrità dei dati.

### Prossimi Passi

Nei prossimi capitoli approfondiremo:
- Architettura dettagliata del modello client-server
- Struttura completa di richieste e risposte HTTP
- Metodi HTTP e loro utilizzo appropriato
- Codici di stato e gestione degli errori
- Headers HTTP e loro funzioni

---

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0

--- 
[Torna all'indice](README.md)
[Capitolo successivo: Architettura e Modello di Comunicazione](02_architettura_e_modello_di_comunicazione.md)