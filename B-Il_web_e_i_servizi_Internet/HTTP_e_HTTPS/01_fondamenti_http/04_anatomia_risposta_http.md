# 4. Anatomia di una Risposta HTTP

## 4.1 Struttura Generale di una Risposta

Una risposta HTTP è composta da **tre parti principali**:

```
┌─────────────────────────────────────────┐
│  STATUS LINE                            │  ← Obbligatoria
│  [Versione HTTP] [Status Code] [Reason] │
├─────────────────────────────────────────┤
│  HEADERS                                │  ← Opzionali
│  Header-Name: Header-Value              │
│  Header-Name: Header-Value              │
│  ...                                    │
├─────────────────────────────────────────┤
│  BLANK LINE                             │  ← Obbligatoria (separatore)
├─────────────────────────────────────────┤
│  BODY                                   │  ← Opzionale
│  [Dati della risposta]                  │
└─────────────────────────────────────────┘
```

### Esempio Completo

```http
HTTP/1.1 200 OK
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: Apache/2.4.41 (Ubuntu)
Content-Type: application/json; charset=utf-8
Content-Length: 187
Cache-Control: public, max-age=3600
ETag: "686897696a7c876b7e"
Connection: keep-alive
Access-Control-Allow-Origin: *

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "role": "developer",
  "created_at": "2025-01-15T10:30:00Z",
  "active": true
}
```

**Analisi:**
1. **Status Line**: `HTTP/1.1 200 OK`
2. **Headers**: 8 headers che forniscono metadati
3. **Blank Line**: linea vuota che separa headers dal body
4. **Body**: dati JSON dell'utente

### Esempio Risposta HTML

```http
HTTP/1.1 200 OK
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: text/html; charset=utf-8
Content-Length: 324
Last-Modified: Wed, 29 Oct 2025 18:30:00 GMT
ETag: "abc123"
Cache-Control: max-age=86400

<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>Benvenuto</title>
    <link rel="stylesheet" href="/style.css">
</head>
<body>
    <h1>Benvenuto su Example.com</h1>
    <p>Questa è la home page.</p>
    <script src="/script.js"></script>
</body>
</html>
```

## 4.2 Status Line

La **Status Line** è la prima riga della risposta HTTP e contiene tre elementi:

```
[VERSIONE HTTP] [STATUS CODE] [REASON PHRASE]
```

### 4.2.1 Versione del Protocollo

Indica la versione HTTP usata dal server nella risposta.

```http
HTTP/1.1 200 OK
└──┬──┘
Versione
```

**Versioni possibili:**
```
HTTP/0.9  →  Obsoleta
HTTP/1.0  →  Ancora in uso (rara)
HTTP/1.1  →  Più comune
HTTP/2    →  Binaria (non ha status line testuale)
HTTP/3    →  Binaria su QUIC
```

**Note:**
- Il server può rispondere con versione diversa da quella richiesta
- Se client richiede HTTP/1.1, server può rispondere HTTP/1.0
- HTTP/2 e HTTP/3 hanno formato binario, non testuale

### 4.2.2 Status Code

Il **codice di stato** indica il risultato della richiesta.

#### Categorie dei Status Code

```
1xx  →  Informational (Informativo)
2xx  →  Success (Successo)
3xx  →  Redirection (Reindirizzamento)
4xx  →  Client Error (Errore del client)
5xx  →  Server Error (Errore del server)
```

#### Status Code più Comuni

| Code | Significato | Uso |
|------|-------------|-----|
| **200** | OK | Richiesta riuscita |
| **201** | Created | Risorsa creata con successo |
| **204** | No Content | Successo, nessun body |
| **301** | Moved Permanently | Redirect permanente |
| **302** | Found | Redirect temporaneo |
| **304** | Not Modified | Risorsa non modificata (cache) |
| **400** | Bad Request | Richiesta malformata |
| **401** | Unauthorized | Autenticazione richiesta |
| **403** | Forbidden | Accesso negato |
| **404** | Not Found | Risorsa non trovata |
| **429** | Too Many Requests | Rate limit superato |
| **500** | Internal Server Error | Errore generico del server |
| **502** | Bad Gateway | Gateway/proxy error |
| **503** | Service Unavailable | Servizio temporaneamente non disponibile |

Approfondiremo tutti i codici nel capitolo 6.

### 4.2.3 Reason Phrase

La **reason phrase** è una breve descrizione testuale dello status code.

```http
HTTP/1.1 200 OK
             └┬┘
         Reason Phrase
```

**Esempi:**
```http
HTTP/1.1 200 OK
HTTP/1.1 404 Not Found
HTTP/1.1 500 Internal Server Error
HTTP/1.1 301 Moved Permanently
```

**Importante:**
- ⚠️ La reason phrase è **opzionale** e **ignorata** dai client moderni
- I client si basano solo sul codice numerico (200, 404, etc.)
- I server possono personalizzare la reason phrase

**Reason phrase personalizzate (valide ma rare):**
```http
HTTP/1.1 404 Nessun Risultato Trovato
HTTP/1.1 200 Tutto Apposto
HTTP/1.1 500 Ops, Qualcosa È Andato Storto
```

**HTTP/2 e HTTP/3:**
- Non hanno reason phrase (formato binario)
- Solo il codice numerico è presente

## 4.3 Response Headers

Gli **headers** forniscono metadati sulla risposta.

### 4.3.1 Headers Generali

Headers applicabili sia a richieste che risposte.

#### Connection

```http
Connection: keep-alive    # Mantieni connessione aperta
Connection: close         # Chiudi dopo questa risposta
```

**Esempio:**
```http
HTTP/1.1 200 OK
Connection: keep-alive
Keep-Alive: timeout=5, max=100

[body]
```

**Keep-Alive parameters:**
- `timeout`: secondi prima della chiusura automatica
- `max`: numero massimo di richieste su questa connessione

#### Cache-Control

Direttive per la cache (fondamentale per performance).

```http
Cache-Control: public              # Può essere cachato da chiunque
Cache-Control: private             # Solo cache del browser
Cache-Control: no-cache            # Revalidare sempre
Cache-Control: no-store            # Non cachare mai
Cache-Control: max-age=3600        # Cache per 1 ora (3600 secondi)
Cache-Control: must-revalidate     # Deve revalidare se stale
Cache-Control: public, max-age=86400, immutable  # Combinazione
```

**Esempi pratici:**

**Asset statico (immagine, CSS, JS):**
```http
HTTP/1.1 200 OK
Content-Type: image/png
Cache-Control: public, max-age=31536000, immutable
# Cachabile per 1 anno, non cambia mai
```

**API dati dinamici:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: private, max-age=300
# Cache privata (browser), rivalidare dopo 5 minuti
```

**Dati sensibili:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
Cache-Control: private, no-cache, no-store, must-revalidate
Pragma: no-cache
Expires: 0
# Non cachare assolutamente
```

#### Date

Data e ora della risposta (formato RFC 7231, sempre GMT).

```http
Date: Thu, 30 Oct 2025 12:00:00 GMT
```

**Formato:**
```
[Day], [DD] [Month] [YYYY] [HH]:[MM]:[SS] GMT

Esempio: Thu, 30 Oct 2025 12:00:00 GMT
```

**Sempre in GMT (UTC)**, mai in timezone locale!

### 4.3.2 Headers di Risposta

Headers specifici per le risposte.

#### Server

Identifica il software del server.

```http
Server: Apache/2.4.41 (Ubuntu)
Server: nginx/1.18.0
Server: Microsoft-IIS/10.0
Server: cloudflare
```

**Esempi dettagliati:**
```http
# Apache
Server: Apache/2.4.41 (Ubuntu) OpenSSL/1.1.1f

# Nginx
Server: nginx/1.18.0

# Node.js
Server: Node.js

# Cloudflare (nasconde server reale)
Server: cloudflare

# Custom
Server: MyCustomServer/1.0
```

**Security Note:**
⚠️ Per sicurezza, molti siti nascondono o modificano questo header:
```http
Server: Server  # Vago
# oppure rimosso completamente
```

#### Location

Indica dove la risorsa è stata spostata o creata.

**Uso 1: Redirect (3xx)**
```http
HTTP/1.1 301 Moved Permanently
Location: https://www.example.com/new-page
Content-Length: 0
```

**Uso 2: Risorsa creata (201)**
```http
HTTP/1.1 201 Created
Location: /api/users/456
Content-Type: application/json

{"id": 456, "name": "Mario Rossi"}
```

**Tipi di Location:**
```http
# URL assoluto
Location: https://www.example.com/page

# URL relativo (path assoluto)
Location: /new/path

# URL relativo (path relativo)
Location: ../other/page

# Altro dominio
Location: https://www.altro-sito.com/page
```

#### Retry-After

Indica quando riprovare una richiesta (con 503 o 429).

```http
# Secondi
Retry-After: 120

# Data specifica
Retry-After: Fri, 31 Oct 2025 08:00:00 GMT
```

**Esempio con 503 Service Unavailable:**
```http
HTTP/1.1 503 Service Unavailable
Retry-After: 3600
Content-Type: text/plain

Il servizio è in manutenzione. Riprovare tra 1 ora.
```

**Esempio con 429 Too Many Requests:**
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1730289660

Rate limit superato. Riprovare tra 60 secondi.
```

### 4.3.3 Headers di Entità

Headers che descrivono il body della risposta.

#### Content-Type

Specifica il tipo di media del body.

```http
Content-Type: media-type [; charset=encoding] [; boundary=string]
```

**Tipi comuni:**

**HTML:**
```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8

<!DOCTYPE html>
<html>...
```

**JSON:**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{"id": 123, "name": "Mario"}
```

**JavaScript:**
```http
HTTP/1.1 200 OK
Content-Type: application/javascript

function hello() { alert('Hi'); }
```

**CSS:**
```http
HTTP/1.1 200 OK
Content-Type: text/css

body { background: #fff; }
```

**Immagini:**
```http
HTTP/1.1 200 OK
Content-Type: image/png

[binary PNG data]
```

**PDF:**
```http
HTTP/1.1 200 OK
Content-Type: application/pdf

[binary PDF data]
```

**Download generico:**
```http
HTTP/1.1 200 OK
Content-Type: application/octet-stream
Content-Disposition: attachment; filename="document.zip"

[binary data]
```

#### Content-Length

Dimensione del body in byte.

```http
Content-Length: 1234
```

**Esempio:**
```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 58

{"id":123,"name":"Mario Rossi","email":"m@example.com"}
```

**Quando è omesso:**
- Con `Transfer-Encoding: chunked`
- Connessione chiusa dopo il body
- HTTP/2 (usa frames, non Content-Length)

#### Content-Encoding

Indica la compressione applicata al body.

```http
Content-Encoding: gzip
Content-Encoding: deflate
Content-Encoding: br          # Brotli
Content-Encoding: compress
```

**Esempio con gzip:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Encoding: gzip
Content-Length: 4567

[HTML compresso con gzip]
```

**Flusso:**
```
1. Server genera HTML (es. 20KB)
2. Server comprime con gzip (→ 4KB)
3. Server invia con Content-Encoding: gzip
4. Client decomprime (→ 20KB)
5. Client usa HTML
```

**Benefici:**
- ✅ Riduzione banda: 70-90% per testo
- ✅ Caricamento più veloce
- ✅ Costi ridotti

**Note:**
- Già compresso (PNG, JPEG, ZIP): non comprimere ulteriormente
- Gzip più compatibile
- Brotli più efficiente (ma più lento da comprimere)

#### Content-Language

Specifica la lingua del contenuto.

```http
Content-Language: it-IT
Content-Language: en-US
Content-Language: fr
Content-Language: de, fr  # Multipli
```

**Esempio:**
```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Language: it-IT

<!DOCTYPE html>
<html lang="it">
<head><title>Benvenuto</title></head>
...
```

#### Content-Disposition

Indica come il contenuto dovrebbe essere presentato.

**Inline (default):**
```http
Content-Disposition: inline
# Browser mostra il contenuto (es. PDF nel browser)
```

**Attachment (download):**
```http
Content-Disposition: attachment; filename="report.pdf"
# Browser scarica il file
```

**Esempi:**

**Download file:**
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="invoice-2025-10.pdf"
Content-Length: 45678

[PDF data]
```

**File con caratteri speciali:**
```http
Content-Disposition: attachment; filename*=UTF-8''R%C3%A9sum%C3%A9.pdf
# filename*= supporta UTF-8 encoding
```

**Visualizza immagine:**
```http
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Disposition: inline

[JPEG data]
```

#### Content-Range

Usato con risposte parziali (206 Partial Content).

```http
Content-Range: bytes start-end/total
```

**Esempio:**
```http
HTTP/1.1 206 Partial Content
Content-Type: video/mp4
Content-Range: bytes 0-1048575/10485760
Content-Length: 1048576

[primi 1MB di un video da 10MB]
```

**Formato:**
```
Content-Range: bytes 0-499/1000      # Primi 500 byte di 1000
Content-Range: bytes 500-999/1000    # Ultimi 500 byte di 1000
Content-Range: bytes */1000          # Dimensione totale (senza range)
```

### Tabella Riassuntiva Headers Comuni

| Header | Tipo | Scopo | Esempio |
|--------|------|-------|---------|
| Date | Generale | Data/ora risposta | `Date: Thu, 30 Oct 2025 12:00:00 GMT` |
| Server | Risposta | Identifica server | `Server: nginx/1.18.0` |
| Content-Type | Entità | Tipo di media | `Content-Type: application/json` |
| Content-Length | Entità | Dimensione body | `Content-Length: 1234` |
| Content-Encoding | Entità | Compressione | `Content-Encoding: gzip` |
| Cache-Control | Generale | Direttive cache | `Cache-Control: max-age=3600` |
| Location | Risposta | URL redirect/risorsa | `Location: /new-page` |
| ETag | Risposta | Identificatore versione | `ETag: "abc123"` |
| Last-Modified | Entità | Data modifica | `Last-Modified: Wed, 29 Oct 2025 10:00:00 GMT` |
| Expires | Entità | Data scadenza cache | `Expires: Fri, 31 Oct 2025 23:59:59 GMT` |
| Set-Cookie | Risposta | Imposta cookie | `Set-Cookie: sessionid=abc; HttpOnly` |
| Access-Control-Allow-Origin | Risposta | CORS | `Access-Control-Allow-Origin: *` |

## 4.4 Response Body

Il **body** contiene i dati effettivi della risposta.

### Tipi di Response Body

#### 1. JSON (application/json)

**Il più comune per API moderne.**

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 287

{
  "status": "success",
  "data": {
    "user": {
      "id": 123,
      "username": "mario_rossi",
      "email": "mario.rossi@example.com",
      "profile": {
        "full_name": "Mario Rossi",
        "avatar": "https://cdn.example.com/avatars/123.jpg",
        "bio": "Software Developer"
      }
    }
  },
  "timestamp": "2025-10-30T12:00:00Z"
}
```

**JSON Error Response:**
```http
HTTP/1.1 404 Not Found
Content-Type: application/json
Content-Length: 98

{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "L'utente richiesto non esiste",
    "details": "User ID 999 does not exist"
  }
}
```

#### 2. HTML (text/html)

**Pagine web tradizionali.**

```http
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Content-Length: 542

<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Benvenuto | Example.com</title>
    <link rel="stylesheet" href="/css/style.css">
    <script src="/js/app.js" defer></script>
</head>
<body>
    <header>
        <h1>Benvenuto su Example.com</h1>
        <nav>
            <a href="/">Home</a>
            <a href="/about">Chi Siamo</a>
            <a href="/contact">Contatti</a>
        </nav>
    </header>
    <main>
        <article>
            <h2>Articolo Principale</h2>
            <p>Questo è il contenuto della pagina...</p>
        </article>
    </main>
    <footer>
        <p>&copy; 2025 Example.com</p>
    </footer>
</body>
</html>
```

#### 3. XML (application/xml)

**Ancora usato in alcuni contesti (SOAP, RSS, etc.).**

```http
HTTP/1.1 200 OK
Content-Type: application/xml
Content-Length: 345

<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>success</status>
  <data>
    <user id="123">
      <username>mario_rossi</username>
      <email>mario.rossi@example.com</email>
      <profile>
        <fullName>Mario Rossi</fullName>
        <avatar>https://cdn.example.com/avatars/123.jpg</avatar>
        <bio>Software Developer</bio>
      </profile>
    </user>
  </data>
  <timestamp>2025-10-30T12:00:00Z</timestamp>
</response>
```

#### 4. Plain Text (text/plain)

**Testo semplice.**

```http
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 87

Questo è un file di testo semplice.
Può contenere più righe.
Nessuna formattazione speciale.
```

#### 5. CSS (text/css)

**Fogli di stile.**

```http
HTTP/1.1 200 OK
Content-Type: text/css
Cache-Control: public, max-age=31536000
Content-Length: 234

/* Reset */
* { margin: 0; padding: 0; box-sizing: border-box; }

/* Body */
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
    line-height: 1.6;
    color: #333;
    background: #f4f4f4;
}

/* Header */
header {
    background: #2c3e50;
    color: white;
    padding: 1rem 0;
}
```

#### 6. JavaScript (application/javascript)

**Codice JavaScript.**

```http
HTTP/1.1 200 OK
Content-Type: application/javascript
Cache-Control: public, max-age=86400
Content-Length: 178

// Main application
(function() {
    'use strict';
    
    function init() {
        console.log('App initialized');
        attachEventListeners();
        loadData();
    }
    
    function attachEventListeners() {
        document.querySelector('#btn').addEventListener('click', handleClick);
    }
    
    function handleClick(e) {
        e.preventDefault();
        console.log('Button clicked');
    }
    
    function loadData() {
        fetch('/api/data')
            .then(response => response.json())
            .then(data => console.log(data))
            .catch(error => console.error(error));
    }
    
    document.addEventListener('DOMContentLoaded', init);
})();
```

#### 7. Binary Data (immagini, video, PDF, etc.)

**PNG:**
```http
HTTP/1.1 200 OK
Content-Type: image/png
Cache-Control: public, max-age=31536000
Content-Length: 45678
ETag: "abc123"

[binary PNG data]
```

**PDF:**
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="report-2025.pdf"
Content-Length: 234567

[binary PDF data]
```

**Video:**
```http
HTTP/1.1 200 OK
Content-Type: video/mp4
Accept-Ranges: bytes
Content-Length: 10485760

[binary video data]
```

#### 8. Chunked Transfer Encoding

**Quando la dimensione non è nota in anticipo.**

```http
HTTP/1.1 200 OK
Content-Type: text/plain
Transfer-Encoding: chunked

1a
Questo è il primo chunk.

19
Questo è il secondo.

0

```

**Formato:**
```
[hex size]\r\n
[data]\r\n
[hex size]\r\n
[data]\r\n
0\r\n
\r\n
```

**Uso pratico:**
- Server-Sent Events
- Streaming
- Risposte generate dinamicamente

#### 9. Empty Body (204, 304, etc.)

**Alcune risposte non hanno body.**

```http
HTTP/1.1 204 No Content
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0

[no body]
```

```http
HTTP/1.1 304 Not Modified
Date: Thu, 30 Oct 2025 12:00:00 GMT
ETag: "abc123"
Cache-Control: max-age=3600

[no body]
```

## 4.5 Esempi Pratici di Risposte HTTP

### Esempio 1: Successo GET

```http
HTTP/1.1 200 OK
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: application/json; charset=utf-8
Content-Length: 187
Cache-Control: private, max-age=300
ETag: "v1-abc123"
X-Request-ID: 7f2a1b3c-9d8e-4f5a-b6c7-d8e9f0a1b2c3

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "role": "developer",
  "created_at": "2025-01-15T10:30:00Z",
  "last_login": "2025-10-30T11:45:00Z",
  "active": true
}
```

### Esempio 2: Risorsa Creata (201)

```http
HTTP/1.1 201 Created
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: Apache/2.4.41
Content-Type: application/json
Location: /api/v1/users/456
Content-Length: 98

{
  "id": 456,
  "name": "Luigi Verdi",
  "email": "luigi.verdi@example.com",
  "created_at": "2025-10-30T12:00:00Z"
}
```

### Esempio 3: No Content (204)

```http
HTTP/1.1 204 No Content
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0

```

### Esempio 4: Redirect Permanente (301)

```http
HTTP/1.1 301 Moved Permanently
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: Apache/2.4.41
Location: https://www.example.com/new-page
Content-Type: text/html
Content-Length: 185

<!DOCTYPE html>
<html>
<head>
    <title>Moved</title>
</head>
<body>
    <h1>Page Moved</h1>
    <p>This page has moved to <a href="https://www.example.com/new-page">new location</a>.</p>
</body>
</html>
```

### Esempio 5: Not Modified (304)

```http
HTTP/1.1 304 Not Modified
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
ETag: "abc123"
Cache-Control: max-age=3600
Last-Modified: Wed, 29 Oct 2025 10:00:00 GMT

```

### Esempio 6: Bad Request (400)

```http
HTTP/1.1 400 Bad Request
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: application/json
Content-Length: 156

{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Richiesta non valida",
    "details": [
      {
        "field": "email",
        "message": "Formato email non valido"
      }
    ]
  }
}
```

### Esempio 7: Unauthorized (401)

```http
HTTP/1.1 401 Unauthorized
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: Apache/2.4.41
WWW-Authenticate: Bearer realm="API", charset="UTF-8"
Content-Type: application/json
Content-Length: 87

{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Token di autenticazione mancante o non valido"
  }
}
```

### Esempio 8: Not Found (404)

```http
HTTP/1.1 404 Not Found
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: application/json
Content-Length: 98

{
  "error": {
    "code": "NOT_FOUND",
    "message": "La risorsa richiesta non esiste",
    "path": "/api/users/999"
  }
}
```

### Esempio 9: Rate Limit (429)

```http
HTTP/1.1 429 Too Many Requests
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: cloudflare
Content-Type: application/json
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1730289660
Content-Length: 123

{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Hai superato il limite di richieste. Riprova tra 60 secondi.",
    "retry_after": 60
  }
}
```

### Esempio 10: Server Error (500)

```http
HTTP/1.1 500 Internal Server Error
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: Apache/2.4.41
Content-Type: application/json
Content-Length: 145

{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Si è verificato un errore interno del server",
    "request_id": "7f2a1b3c-9d8e-4f5a-b6c7-d8e9f0a1b2c3"
  }
}
```

### Esempio 11: Partial Content (206)

```http
HTTP/1.1 206 Partial Content
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: video/mp4
Content-Range: bytes 0-1048575/10485760
Content-Length: 1048576
Accept-Ranges: bytes

[primi 1MB del video]
```

### Esempio 12: Service Unavailable (503)

```http
HTTP/1.1 503 Service Unavailable
Date: Thu, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.18.0
Content-Type: text/html
Retry-After: 3600
Content-Length: 234

<!DOCTYPE html>
<html>
<head>
    <title>Manutenzione</title>
</head>
<body>
    <h1>Servizio in Manutenzione</h1>
    <p>Il servizio è temporaneamente non disponibile per manutenzione programmata.</p>
    <p>Riprova tra 1 ora.</p>
</body>
</html>
```

---

## Riepilogo

Una risposta HTTP è strutturata in:

1. **Status Line**
   - Versione HTTP (HTTP/1.1, HTTP/2, HTTP/3)
   - Status Code (200, 404, 500, etc.)
   - Reason Phrase (OK, Not Found, etc.)

2. **Headers**
   - **Generali**: Date, Connection, Cache-Control
   - **Risposta**: Server, Location, Retry-After
   - **Entità**: Content-Type, Content-Length, Content-Encoding

3. **Blank Line**
   - Separa headers da body

4. **Body** (opzionale)
   - JSON, HTML, XML, CSS, JavaScript, Binary, Text
   - Dipende dal Content-Type
   - Può essere assente (204, 304)

**Best Practices:**
- ✅ Usa status code appropriati (semantica corretta)
- ✅ Specifica sempre Content-Type quando c'è un body
- ✅ Implementa caching appropriato (Cache-Control, ETag)
- ✅ Includi headers di sicurezza (CORS, CSP, etc.)
- ✅ Gestisci errori con messaggi chiari e strutturati
- ✅ Usa compressione (gzip, brotli) per risposte testuali
- ✅ Imposta Date header
- ✅ Documenta API responses

Nel prossimo capitolo approfondiremo i **metodi HTTP** in dettaglio.

---

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0

--- 
[Torna all'indice](README.md)