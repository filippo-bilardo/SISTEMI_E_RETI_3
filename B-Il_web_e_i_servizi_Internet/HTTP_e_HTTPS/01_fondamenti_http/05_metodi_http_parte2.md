# 5. Metodi HTTP (Parte 2)

## 5.8 PATCH - Modifiche Parziali

Il metodo **PATCH** è usato per applicare modifiche parziali a una risorsa esistente.

### Caratteristiche

- ❌ **NON sicuro**: modifica il server
- ⚠️ **NON idempotente**: dipende dall'implementazione
- ❌ **NON cacheable**
- ✅ **Body**: contiene solo le modifiche da applicare

### 5.8.1 Sintassi e Utilizzo

```http
PATCH /path/to/resource HTTP/1.1
Host: example.com
Content-Type: media-type

[partial resource representation]
```

**Esempio: Aggiornamento parziale**
```http
PATCH /api/users/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{
  "email": "mario.nuovo@example.com"
}

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.nuovo@example.com",
  "role": "developer",
  "updated_at": "2025-10-30T12:30:00Z"
}
```

### 5.8.2 PATCH vs PUT

| Aspetto | PUT | PATCH |
|---------|-----|-------|
| **Payload** | Risorsa completa | Solo modifiche |
| **Semantica** | Sostituisce risorsa | Modifica risorsa |
| **Idempotente** | ✅ Sì | ⚠️ Dipende |
| **Campi omessi** | Impostati a null/default | Rimangono invariati |
| **Dimensione** | Più grande | Più piccola |
| **Complessità** | Semplice | Può essere complessa |

**Esempio comparativo:**

**Risorsa originale:**
```json
{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario@example.com",
  "role": "developer",
  "active": true
}
```

**PUT (risorsa completa):**
```http
PUT /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.nuovo@example.com",
  "role": "developer",
  "active": true
}
# Devo inviare TUTTI i campi
# Se ometto "role", potrebbe essere rimosso/nullificato
```

**PATCH (solo modifiche):**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "email": "mario.nuovo@example.com"
}
# Invio solo il campo modificato
# Gli altri campi rimangono invariati
```

### 5.8.3 Formati di PATCH

#### 1. JSON Merge Patch (RFC 7396)

**Formato semplice:** sostituisce valori, null elimina campi.

```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/merge-patch+json

{
  "email": "nuovo@example.com",
  "role": null
}

# Risultato:
# - email → "nuovo@example.com" (aggiornato)
# - role → eliminato (null)
# - altri campi → invariati
```

**Esempio complesso:**
```http
# Risorsa originale:
{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario@example.com",
  "address": {
    "city": "Roma",
    "zip": "00100",
    "country": "IT"
  },
  "tags": ["developer", "senior"]
}

# PATCH:
PATCH /api/users/123 HTTP/1.1
Content-Type: application/merge-patch+json

{
  "email": "mario.new@example.com",
  "address": {
    "city": "Milano",
    "zip": "20100"
  }
}

# Risultato:
{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.new@example.com",
  "address": {
    "city": "Milano",
    "zip": "20100"
    # ⚠️ "country" è stato eliminato! (non presente in PATCH)
  },
  "tags": ["developer", "senior"]
}
```

**Limitazione:** non può aggiornare parzialmente oggetti nidificati senza rimuovere campi.

#### 2. JSON Patch (RFC 6902)

**Formato avanzato:** operazioni precise (add, remove, replace, move, copy, test).

**Operazioni disponibili:**

| Operazione | Descrizione | Esempio |
|------------|-------------|---------|
| **add** | Aggiunge valore | `{"op": "add", "path": "/email", "value": "new@example.com"}` |
| **remove** | Rimuove valore | `{"op": "remove", "path": "/role"}` |
| **replace** | Sostituisce valore | `{"op": "replace", "path": "/active", "value": false}` |
| **move** | Sposta valore | `{"op": "move", "from": "/old_field", "path": "/new_field"}` |
| **copy** | Copia valore | `{"op": "copy", "from": "/name", "path": "/display_name"}` |
| **test** | Verifica valore | `{"op": "test", "path": "/version", "value": 1}` |

**Esempio: Operazioni multiple**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json-patch+json

[
  {"op": "replace", "path": "/email", "value": "mario.new@example.com"},
  {"op": "add", "path": "/phone", "value": "+39 123 456 7890"},
  {"op": "remove", "path": "/temporary_token"},
  {"op": "replace", "path": "/address/city", "value": "Milano"}
]

# Risultato:
# - email aggiornato
# - phone aggiunto
# - temporary_token rimosso
# - address.city aggiornato (altri campi di address invariati!)
```

**Esempio: Test condizionale**
```http
PATCH /api/documents/456 HTTP/1.1
Content-Type: application/json-patch+json

[
  {"op": "test", "path": "/version", "value": 3},
  {"op": "replace", "path": "/title", "value": "Nuovo Titolo"},
  {"op": "replace", "path": "/version", "value": 4}
]

# Se version != 3, PATCH fallisce (conflitto)
# Utile per evitare race conditions
```

**Esempio: Array manipulation**
```http
# Risorsa:
{
  "id": 123,
  "tags": ["javascript", "react", "nodejs"]
}

# PATCH:
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json-patch+json

[
  {"op": "add", "path": "/tags/-", "value": "typescript"},
  {"op": "remove", "path": "/tags/1"}
]

# Risultato:
{
  "id": 123,
  "tags": ["javascript", "nodejs", "typescript"]
}
# - aggiunto "typescript" alla fine (path: /tags/-)
# - rimosso elemento all'indice 1 ("react")
```

#### 3. Custom PATCH (implementazioni specifiche)

Alcune API usano formati custom:

**Esempio: Increment operation**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "increment_login_count": 1
}

# Incrementa login_count di 1
# ⚠️ NON idempotente!
```

**Esempio: Array operations**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{
  "tags": {
    "$push": ["typescript"],
    "$pull": ["javascript"]
  }
}

# Aggiunge "typescript" e rimuove "javascript" dall'array tags
```

### 5.8.4 Idempotenza di PATCH

PATCH **può essere** idempotente o meno, dipende dall'implementazione.

**✅ Idempotente (set value):**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{"email": "nuovo@example.com"}

# Prima chiamata: email → "nuovo@example.com"
# Seconda chiamata: email → "nuovo@example.com" (invariato)
# Idempotente ✅
```

**❌ NON idempotente (increment):**
```http
PATCH /api/counters/123 HTTP/1.1
Content-Type: application/json

{"increment": 1}

# Prima chiamata: counter = 100 + 1 = 101
# Seconda chiamata: counter = 101 + 1 = 102
# Terza chiamata: counter = 102 + 1 = 103
# NON idempotente ❌
```

**✅ Idempotente (JSON Patch con test):**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json-patch+json

[
  {"op": "test", "path": "/email", "value": "old@example.com"},
  {"op": "replace", "path": "/email", "value": "new@example.com"}
]

# Prima chiamata: test passa, email aggiornato
# Seconda chiamata: test fallisce (email già "new@example.com")
# Idempotente (in pratica) ✅
```

## 5.9 HEAD - Recuperare Metadati

Il metodo **HEAD** è identico a GET, ma il server **non invia il body** nella risposta.

### Caratteristiche

- ✅ **Sicuro**: non modifica il server
- ✅ **Idempotente**: stesso risultato ogni volta
- ✅ **Cacheable**: può essere cachato
- ❌ **NO body**: né in richiesta né in risposta

### 5.9.1 Sintassi e Utilizzo

```http
HEAD /path/to/resource HTTP/1.1
Host: example.com
```

**Esempio:**
```http
HEAD /api/users/123 HTTP/1.1
Host: api.example.com

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 256
Last-Modified: Wed, 30 Oct 2025 12:00:00 GMT
ETag: "abc123xyz"

[NO BODY]
```

**Comparazione GET vs HEAD:**

**GET:**
```http
GET /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: application/json
  Content-Length: 256
  
  {"id": 123, "name": "Mario Rossi", ...}
```

**HEAD:**
```http
HEAD /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: application/json
  Content-Length: 256
  
  [NO BODY - solo headers]
```

### 5.9.2 Casi d'Uso

**1. Verificare esistenza risorsa**
```http
HEAD /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK (esiste)
# oppure
→ HTTP/1.1 404 Not Found (non esiste)

# Più efficiente di GET perché non trasferisce dati
```

**2. Verificare modifiche (cache validation)**
```http
# Cache ha: ETag "abc123"
HEAD /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK
  ETag: "abc123"
  
# ETag uguale → nessun cambiamento, usa cache
# ETag diverso → risorsa modificata, scarica con GET
```

**3. Verificare dimensione file prima del download**
```http
HEAD /downloads/large-file.zip HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Length: 1073741824
  Content-Type: application/zip
  
# 1GB file, decido se scaricare o meno
```

**4. Check link availability**
```http
HEAD /old-page.html HTTP/1.1

→ HTTP/1.1 404 Not Found
# Link rotto

HEAD /new-page.html HTTP/1.1

→ HTTP/1.1 200 OK
# Link funzionante
```

**5. Verificare supporto Range requests**
```http
HEAD /video.mp4 HTTP/1.1

→ HTTP/1.1 200 OK
  Accept-Ranges: bytes
  Content-Length: 524288000
  
# Supporta range requests → posso fare download parziale/resume
```

**Esempio pratico: Link Checker**
```javascript
async function checkLink(url) {
  const response = await fetch(url, { method: 'HEAD' });
  
  return {
    url: url,
    status: response.status,
    ok: response.ok,
    contentType: response.headers.get('content-type'),
    contentLength: response.headers.get('content-length'),
    lastModified: response.headers.get('last-modified')
  };
}

// Verifica multipli link senza scaricare contenuto
const links = [
  'https://example.com/page1',
  'https://example.com/page2',
  'https://example.com/page3'
];

const results = await Promise.all(links.map(checkLink));
// Molto più veloce di GET perché non scarica body
```

## 5.10 OPTIONS - Opzioni di Comunicazione

Il metodo **OPTIONS** richiede informazioni sulle opzioni di comunicazione disponibili per una risorsa.

### Caratteristiche

- ✅ **Sicuro**: non modifica il server
- ✅ **Idempotente**: stesso risultato ogni volta
- ❌ **NON cacheable**
- ✅ **Body**: opzionale

### 5.10.1 Sintassi e Utilizzo

```http
OPTIONS /path/to/resource HTTP/1.1
Host: example.com
```

**Esempio: Opzioni per risorsa specifica**
```http
OPTIONS /api/users/123 HTTP/1.1
Host: api.example.com

→ Risposta:
HTTP/1.1 200 OK
Allow: GET, PUT, PATCH, DELETE, HEAD, OPTIONS
Content-Length: 0
```

**Esempio: Opzioni per server**
```http
OPTIONS * HTTP/1.1
Host: api.example.com

→ Risposta:
HTTP/1.1 200 OK
Allow: GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
```

### 5.10.2 CORS Preflight Requests

**OPTIONS** è fondamentale per **CORS** (Cross-Origin Resource Sharing).

**Scenario:** Browser esegue richiesta cross-origin con metodo custom o headers.

**Preflight Request (automatico):**
```http
OPTIONS /api/users HTTP/1.1
Host: api.example.com
Origin: https://www.myapp.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

**Preflight Response:**
```http
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://www.myapp.com
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 3600
```

**Interpretazione:**
- ✅ Origine `https://www.myapp.com` è permessa
- ✅ Metodi permessi: GET, POST, PUT, DELETE, OPTIONS
- ✅ Headers permessi: Content-Type, Authorization
- ✅ Cache preflight per 3600 secondi (1 ora)

**Actual Request (dopo preflight OK):**
```http
POST /api/users HTTP/1.1
Host: api.example.com
Origin: https://www.myapp.com
Content-Type: application/json
Authorization: Bearer token123

{"name": "Mario Rossi"}

→ HTTP/1.1 201 Created
  Access-Control-Allow-Origin: https://www.myapp.com
```

**Esempio completo: CORS flow**

```javascript
// Browser (JavaScript su https://www.myapp.com)
fetch('https://api.example.com/api/users', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer token123'
  },
  body: JSON.stringify({name: 'Mario Rossi'})
});

// Browser automaticamente invia preflight:
// OPTIONS /api/users
// Origin: https://www.myapp.com
// Access-Control-Request-Method: POST
// Access-Control-Request-Headers: content-type, authorization

// Server risponde:
// HTTP/1.1 204 No Content
// Access-Control-Allow-Origin: https://www.myapp.com
// Access-Control-Allow-Methods: GET, POST, PUT, DELETE
// Access-Control-Allow-Headers: content-type, authorization
// Access-Control-Max-Age: 3600

// Se preflight OK, browser invia actual request:
// POST /api/users
// [headers e body come specificato]
```

**Quando viene inviato preflight:**

✅ **Preflight necessario:**
- Metodi: PUT, DELETE, PATCH, CONNECT, TRACE
- Headers custom: `Authorization`, `X-Custom-Header`
- Content-Type: `application/json`, `text/xml`, etc. (non simple)

❌ **Preflight NON necessario (simple request):**
- Metodi: GET, HEAD, POST
- Headers: `Accept`, `Accept-Language`, `Content-Language`
- Content-Type: `application/x-www-form-urlencoded`, `multipart/form-data`, `text/plain`

### 5.10.3 Server Configuration per OPTIONS

**Nginx:**
```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location /api/ {
        # CORS headers
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '$http_origin' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Requested-With' always;
            add_header 'Access-Control-Max-Age' 3600 always;
            add_header 'Content-Length' 0;
            add_header 'Content-Type' 'text/plain';
            return 204;
        }
        
        # Actual request headers
        add_header 'Access-Control-Allow-Origin' '$http_origin' always;
        
        proxy_pass http://backend;
    }
}
```

**Apache:**
```apache
<VirtualHost *:80>
    ServerName api.example.com
    
    <Location /api/>
        # Handle preflight
        Header always set Access-Control-Allow-Origin "*"
        Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, PATCH, OPTIONS"
        Header always set Access-Control-Allow-Headers "Content-Type, Authorization"
        Header always set Access-Control-Max-Age "3600"
        
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} OPTIONS
        RewriteRule ^(.*)$ $1 [R=204,L]
    </Location>
</VirtualHost>
```

**Express.js (Node.js):**
```javascript
const express = require('express');
const cors = require('cors');
const app = express();

// Automatic CORS handling
app.use(cors({
  origin: 'https://www.myapp.com',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  maxAge: 3600
}));

// Manual OPTIONS handling (alternative)
app.options('/api/*', (req, res) => {
  res.header('Access-Control-Allow-Origin', 'https://www.myapp.com');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.header('Access-Control-Max-Age', '3600');
  res.sendStatus(204);
});

app.listen(3000);
```

## 5.11 CONNECT - Stabilire Tunnel

Il metodo **CONNECT** stabilisce un tunnel verso il server identificato dalla risorsa target.

### Caratteristiche

- ❌ **NON sicuro**: stabilisce connessione
- ❌ **NON idempotente**: ogni chiamata crea nuovo tunnel
- ❌ **NON cacheable**
- ❌ **NO body**: generalmente

### 5.11.1 Sintassi e Utilizzo

```http
CONNECT server:port HTTP/1.1
Host: proxy.example.com
```

**Esempio: HTTPS attraverso proxy**
```http
CONNECT www.example.com:443 HTTP/1.1
Host: proxy.example.com
Proxy-Authorization: Basic dXNlcjpwYXNz

→ Risposta:
HTTP/1.1 200 Connection Established

[tunnel aperto, traffico TLS passa attraverso]
```

### 5.11.2 Uso Principale: HTTPS Proxy

**Scenario:** Client vuole accedere a HTTPS tramite proxy HTTP.

**Flusso:**

```
1. Client → Proxy: CONNECT www.example.com:443
   
2. Proxy → Server HTTPS: apre connessione TCP
   
3. Proxy → Client: HTTP/1.1 200 Connection Established
   
4. Client ↔ Server: TLS handshake attraverso tunnel
   
5. Client ↔ Server: traffico HTTPS crittografato
   (proxy non può leggere, è end-to-end encrypted)
```

**Esempio dettagliato:**

```http
# Step 1: Client richiede tunnel
CONNECT www.secure-bank.com:443 HTTP/1.1
Host: proxy.company.com
Proxy-Authorization: Basic dXNlcjpwYXNz

# Step 2: Proxy stabilisce connessione con server
# [proxy apre socket TCP verso www.secure-bank.com:443]

# Step 3: Proxy conferma tunnel
HTTP/1.1 200 Connection Established

# Step 4: Client invia TLS ClientHello attraverso tunnel
[binary TLS data]

# Step 5: Server risponde con TLS ServerHello
[binary TLS data]

# Step 6+: Comunicazione HTTPS end-to-end crittografata
# Proxy non può leggere/modificare (solo inoltra byte)
```

**Errori comuni:**

```http
# Proxy non autorizzato
CONNECT www.example.com:443 HTTP/1.1

→ HTTP/1.1 407 Proxy Authentication Required
  Proxy-Authenticate: Basic realm="Proxy"

# Destinazione non permessa
CONNECT malicious-site.com:443 HTTP/1.1
Proxy-Authorization: Basic dXNlcjpwYXNz

→ HTTP/1.1 403 Forbidden
  
# Proxy non può raggiungere destinazione
CONNECT unreachable.com:443 HTTP/1.1

→ HTTP/1.1 502 Bad Gateway
```

### 5.11.3 Sicurezza e Limitazioni

**Rischi:**
- ❌ Tunneling arbitrario (bypass firewall)
- ❌ Port scanning attraverso proxy
- ❌ Tunneling di protocolli non-HTTP

**Mitigazioni:**

**1. Limitare porte permesse**
```
Solo HTTPS (443):
CONNECT example.com:443  →  ✅ Permesso
CONNECT example.com:22   →  ❌ Negato (SSH)
CONNECT example.com:25   →  ❌ Negato (SMTP)
```

**2. Whitelist di domini**
```
CONNECT www.allowed-domain.com:443  →  ✅ Permesso
CONNECT www.blocked-domain.com:443  →  ❌ Negato
```

**3. Autenticazione proxy**
```http
CONNECT example.com:443 HTTP/1.1
# ⚠️ NO autenticazione

→ HTTP/1.1 407 Proxy Authentication Required
  Proxy-Authenticate: Basic realm="Company Proxy"
```

**4. Logging**
```
Log:
- Timestamp
- Client IP
- Destination (host:port)
- Autenticazione user
- Bytes trasferiti
- Durata connessione
```

**Configurazione Proxy (Squid):**
```squid
# Permetti solo HTTPS
acl SSL_ports port 443
acl CONNECT method CONNECT
http_access deny CONNECT !SSL_ports

# Whitelist domini
acl allowed_domains dstdomain .allowed-site.com
http_access allow CONNECT allowed_domains SSL_ports
http_access deny CONNECT

# Richiedi autenticazione
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
```

## 5.12 TRACE - Debugging Richieste

Il metodo **TRACE** esegue un loop-back test lungo il percorso alla risorsa target.

### Caratteristiche

- ✅ **Sicuro**: non modifica il server
- ✅ **Idempotente**: stesso risultato ogni volta
- ❌ **NON cacheable**
- ❌ **NO body** in richiesta

### 5.12.1 Sintassi e Utilizzo

```http
TRACE /path HTTP/1.1
Host: example.com
User-Agent: curl/7.68.0
X-Custom-Header: test-value
```

**Risposta:**
```http
HTTP/1.1 200 OK
Content-Type: message/http

TRACE /path HTTP/1.1
Host: example.com
User-Agent: curl/7.68.0
X-Custom-Header: test-value
```

**Scopo:** Vedere esattamente cosa il server riceve (debug proxy, header manipulation).

### 5.12.2 Casi d'Uso

**1. Verificare header manipulation**
```http
# Client invia:
TRACE /test HTTP/1.1
Host: api.example.com
Authorization: Bearer token123

# Server risponde con esattamente quello che ha ricevuto:
HTTP/1.1 200 OK
Content-Type: message/http

TRACE /test HTTP/1.1
Host: api.example.com
Authorization: Bearer token123
X-Forwarded-For: 192.168.1.100  ← aggiunto da proxy
Via: 1.1 proxy.example.com      ← aggiunto da proxy
```

**2. Debug proxy chain**
```http
TRACE / HTTP/1.1
Host: www.example.com

→ Risposta mostra tutti gli header aggiunti da proxy intermedi
```

### 5.12.3 Problemi di Sicurezza

**⚠️ TRACE è quasi sempre DISABILITATO per motivi di sicurezza.**

**Vulnerabilità: Cross-Site Tracing (XST)**

```http
# Attacker inietta JavaScript che invia:
TRACE / HTTP/1.1
Host: victim.com
Cookie: session=abc123; auth_token=xyz789

# Server risponde con:
HTTP/1.1 200 OK
Content-Type: message/http

TRACE / HTTP/1.1
Cookie: session=abc123; auth_token=xyz789

# ⚠️ JavaScript può leggere cookie (bypassa HttpOnly!)
```

**Mitigazione: Disabilitare TRACE**

**Apache:**
```apache
TraceEnable Off
```

**Nginx:**
```nginx
# TRACE non supportato di default in Nginx
# Se abilitato tramite modulo, disabilitare:
if ($request_method = TRACE) {
    return 405;
}
```

**IIS:**
```xml
<configuration>
  <system.webServer>
    <security>
      <requestFiltering>
        <verbs>
          <add verb="TRACE" allowed="false" />
        </verbs>
      </requestFiltering>
    </security>
  </system.webServer>
</configuration>
```

**Test se TRACE è abilitato:**
```bash
curl -X TRACE https://example.com/

# Se risponde 200 con body → ⚠️ TRACE abilitato (vulnerabile)
# Se risponde 405 Method Not Allowed → ✅ TRACE disabilitato (sicuro)
```

## 5.13 Riepilogo Metodi HTTP

### Tabella Completa

| Metodo | Sicuro | Idempotente | Cacheable | Body Req | Body Res | Uso Principale |
|--------|--------|-------------|-----------|----------|----------|----------------|
| **GET** | ✅ | ✅ | ✅ | ❌ | ✅ | Recuperare risorse |
| **POST** | ❌ | ❌ | ⚠️ | ✅ | ✅ | Creare risorse |
| **PUT** | ❌ | ✅ | ❌ | ✅ | ✅ | Sostituire risorse |
| **PATCH** | ❌ | ⚠️ | ❌ | ✅ | ✅ | Modificare parzialmente |
| **DELETE** | ❌ | ✅ | ❌ | ⚠️ | ✅ | Eliminare risorse |
| **HEAD** | ✅ | ✅ | ✅ | ❌ | ❌ | Recuperare metadati |
| **OPTIONS** | ✅ | ✅ | ❌ | ⚠️ | ✅ | Opzioni comunicazione |
| **CONNECT** | ❌ | ❌ | ❌ | ❌ | ✅ | Stabilire tunnel |
| **TRACE** | ✅ | ❌ | ❌ | ❌ | ✅ | Loop-back test |

### Quando Usare Quale Metodo

```
Creare risorsa:
→ POST /api/users

Leggere risorsa:
→ GET /api/users/123

Aggiornare risorsa (completa):
→ PUT /api/users/123

Aggiornare risorsa (parziale):
→ PATCH /api/users/123

Eliminare risorsa:
→ DELETE /api/users/123

Verificare esistenza/metadati:
→ HEAD /api/users/123

Verificare metodi permessi:
→ OPTIONS /api/users/123

HTTPS attraverso proxy:
→ CONNECT secure-site.com:443

Debug (disabilitato generalmente):
→ TRACE /
```

### Best Practices Generali

**✅ Do:**

1. **Usa metodi semanticamente corretti**
   ```
   GET per leggere
   POST per creare
   PUT per aggiornare (completo)
   PATCH per aggiornare (parziale)
   DELETE per eliminare
   ```

2. **Rispetta idempotenza**
   ```
   GET, PUT, DELETE, HEAD: ripetibili in sicurezza
   POST, PATCH: attenzione ai retry
   ```

3. **Ritorna status code appropriati**
   ```
   GET: 200 OK, 404 Not Found
   POST: 201 Created, 400 Bad Request
   PUT: 200 OK, 204 No Content
   PATCH: 200 OK, 204 No Content
   DELETE: 204 No Content, 404 Not Found
   ```

4. **Implementa caching correttamente**
   ```
   GET, HEAD: cacheable
   POST, PUT, PATCH, DELETE: non cacheare senza headers espliciti
   ```

**❌ Don't:**

1. **Non usare GET per modifiche**
   ```
   ❌ GET /api/users/delete/123
   ✅ DELETE /api/users/123
   ```

2. **Non usare POST per tutto**
   ```
   ❌ POST /api/users/get/123
   ✅ GET /api/users/123
   ```

3. **Non ignorare sicurezza**
   ```
   ❌ Permettere operazioni senza autenticazione
   ❌ Abilitare TRACE in produzione
   ✅ Richiedere autenticazione per operazioni sensibili
   ```

4. **Non violare RESTful principles**
   ```
   ❌ GET /api/createUser?name=Mario
   ✅ POST /api/users {"name": "Mario"}
   ```

---

**Capitolo 5 completato!**

Prossimi capitoli:
- **Capitolo 6**: Codici di Stato HTTP (1xx, 2xx, 3xx, 4xx, 5xx)
- **Capitolo 7**: Header HTTP (Request, Response, Entity, Custom)
- **Capitolo 8**: Caching HTTP
- E molti altri...

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
