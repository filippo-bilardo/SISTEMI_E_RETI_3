# 7. Header HTTP

## 7.1 Introduzione agli Header HTTP

Gli **header HTTP** sono coppie chiave-valore che forniscono metadati sulla richiesta o sulla risposta.

### 7.1.1 Struttura

```http
Header-Name: header-value
```

**Caratteristiche:**
- **Case-insensitive**: `Content-Type` = `content-type` = `CONTENT-TYPE`
- **Multipli valori**: separati da virgola o più header con stesso nome
- **Ordine**: generalmente non importante (eccetto alcuni casi)

**Esempio richiesta:**
```http
GET /api/users HTTP/1.1
Host: api.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Accept: application/json
Accept-Language: it-IT,it;q=0.9,en;q=0.8
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Esempio risposta:**
```http
HTTP/1.1 200 OK
Date: Wed, 30 Oct 2025 12:00:00 GMT
Server: nginx/1.24.0
Content-Type: application/json; charset=utf-8
Content-Length: 256
Cache-Control: max-age=3600, public
ETag: "abc123xyz"
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95

{"id": 123, "name": "Mario Rossi"}
```

### 7.1.2 Categorie di Header

Gli header sono classificati in base al loro uso:

| Categoria | Descrizione | Esempi |
|-----------|-------------|---------|
| **General Headers** | Applicabili a richiesta e risposta | `Date`, `Connection`, `Cache-Control` |
| **Request Headers** | Specifici della richiesta | `Host`, `User-Agent`, `Accept`, `Authorization` |
| **Response Headers** | Specifici della risposta | `Server`, `Location`, `Retry-After` |
| **Entity Headers** | Descrivono il body | `Content-Type`, `Content-Length`, `Content-Encoding` |
| **Custom Headers** | Definiti dall'utente | `X-Custom-Header`, `X-Request-ID` |

### 7.1.3 Header Standard vs Custom

**Standard (definiti in RFC):**
```http
Host: example.com
Content-Type: application/json
Authorization: Bearer token123
```

**Custom (prefix `X-` tradizionale, ora deprecato):**
```http
X-Request-ID: abc-123-xyz
X-API-Version: 2.0
X-Custom-Auth: custom-token

# Modern (senza X-)
Request-ID: abc-123-xyz
API-Version: 2.0
```

**⚠️ Nota:** Il prefix `X-` è deprecato (RFC 6648), ma ancora molto usato.

## 7.2 General Headers

Header applicabili sia a richieste che risposte.

### 7.2.1 - Date

**Scopo:** Data e ora del messaggio.

**Formato:** RFC 7231 (HTTP-date)

**Sintassi:**
```http
Date: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
```

**Esempi:**
```http
Date: Wed, 30 Oct 2025 12:00:00 GMT
Date: Mon, 01 Jan 2024 00:00:00 GMT
```

**Uso in richiesta (raro):**
```http
POST /api/data HTTP/1.1
Date: Wed, 30 Oct 2025 12:00:00 GMT
```

**Uso in risposta (comune):**
```http
HTTP/1.1 200 OK
Date: Wed, 30 Oct 2025 12:00:00 GMT
```

**Generazione server (Express.js):**
```javascript
app.use((req, res, next) => {
  // Express aggiunge Date automaticamente
  // Ma puoi override:
  res.setHeader('Date', new Date().toUTCString());
  next();
});
```

### 7.2.2 - Connection

**Scopo:** Controllo della connessione HTTP.

**Valori:**
- `keep-alive`: Mantiene connessione aperta
- `close`: Chiude connessione dopo risposta
- `upgrade`: Richiede upgrade protocollo

**HTTP/1.0 (default: close):**
```http
GET / HTTP/1.0
Connection: keep-alive

→ HTTP/1.0 200 OK
  Connection: keep-alive
```

**HTTP/1.1 (default: keep-alive):**
```http
GET / HTTP/1.1
Connection: keep-alive

→ HTTP/1.1 200 OK
  Connection: keep-alive
```

**Chiusura esplicita:**
```http
GET / HTTP/1.1
Connection: close

→ HTTP/1.1 200 OK
  Connection: close
  
[connessione chiusa dopo risposta]
```

**Upgrade (WebSocket):**
```http
GET /chat HTTP/1.1
Connection: Upgrade
Upgrade: websocket

→ HTTP/1.1 101 Switching Protocols
  Connection: Upgrade
  Upgrade: websocket
```

### 7.2.3 - Cache-Control

**Scopo:** Direttive per meccanismi di caching.

**Direttive comuni:**

| Direttiva | Significato | Uso |
|-----------|-------------|-----|
| `no-cache` | Richiedi validazione prima di usare cache | Request/Response |
| `no-store` | Non cachare mai | Request/Response |
| `max-age=<seconds>` | Tempo massimo di cache | Response |
| `s-maxage=<seconds>` | Max-age per cache condivise (CDN) | Response |
| `public` | Cachabile da tutti (anche proxy) | Response |
| `private` | Cachabile solo da browser (non proxy) | Response |
| `must-revalidate` | Rivalidare quando stale | Response |
| `no-transform` | Non modificare contenuto | Request/Response |

**Esempi:**

**Non cachare:**
```http
HTTP/1.1 200 OK
Cache-Control: no-store

# Contenuto sensibile, non salvare in cache
```

**Cache per 1 ora:**
```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600, public

# Cachabile per 1 ora da tutti (browser, proxy, CDN)
```

**Cache privata (solo browser):**
```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600, private

# Dati personali, cache solo locale
```

**Cache CDN diversa da browser:**
```http
HTTP/1.1 200 OK
Cache-Control: max-age=60, s-maxage=3600, public

# Browser: cache 1 minuto
# CDN: cache 1 ora
```

**Rivalidazione obbligatoria:**
```http
HTTP/1.1 200 OK
Cache-Control: max-age=3600, must-revalidate

# Dopo 1 ora, DEVE rivalidare (non può usare cache stale)
```

**Combinazioni comuni:**

```http
# Statico (CSS, JS, immagini con hash nel nome)
Cache-Control: max-age=31536000, public, immutable

# API (dati che cambiano)
Cache-Control: max-age=60, private, must-revalidate

# Dati sensibili
Cache-Control: no-store, no-cache, must-revalidate, private

# HTML (rivalidare sempre)
Cache-Control: no-cache, must-revalidate
```

**Implementazione (Express.js):**
```javascript
// Middleware per cache statica
app.use('/static', express.static('public', {
  maxAge: '1y', // 1 anno
  immutable: true
}));

// API con cache breve
app.get('/api/data', (req, res) => {
  res.set('Cache-Control', 'max-age=60, private, must-revalidate');
  res.json({ data: 'value' });
});

// Dati sensibili (no cache)
app.get('/api/private', (req, res) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
  res.json({ sensitive: 'data' });
});
```

**Nginx:**
```nginx
location /static/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

location /api/ {
    add_header Cache-Control "max-age=60, private, must-revalidate";
}

location /private/ {
    add_header Cache-Control "no-store, no-cache, must-revalidate, private";
}
```

### 7.2.4 - Via

**Scopo:** Traccia proxy/gateway intermedi.

**Sintassi:**
```http
Via: <protocol-version> <proxy-name> [<comment>]
```

**Esempio:**
```http
# Client → Proxy1 → Proxy2 → Server

GET /page HTTP/1.1
Host: www.example.com

# Request attraversa proxy
Via: 1.1 proxy1.example.com, 1.1 proxy2.example.com

→ HTTP/1.1 200 OK
  Via: 1.1 proxy2.example.com, 1.1 proxy1.example.com
```

**Con commenti:**
```http
Via: 1.1 proxy.example.com (nginx/1.24.0)
Via: 1.0 cache.cdn.com (CloudFront)
```

### 7.2.5 - Pragma (legacy)

**Scopo:** Direttive backward-compatible (HTTP/1.0).

**⚠️ Deprecato:** Usare `Cache-Control` invece.

**Esempio:**
```http
# HTTP/1.0
Pragma: no-cache

# Equivalente HTTP/1.1
Cache-Control: no-cache
```

## 7.3 Request Headers

Header specifici delle richieste HTTP.

### 7.3.1 - Host

**Scopo:** Specifica host e porta del server.

**⚠️ OBBLIGATORIO in HTTP/1.1**

**Sintassi:**
```http
Host: <hostname>[:<port>]
```

**Esempi:**
```http
Host: www.example.com
Host: api.example.com:8080
Host: localhost:3000
Host: 192.168.1.100
Host: [2001:db8::1]:8080
```

**Perché è obbligatorio:**
```
Virtual Hosting (più siti su stesso IP):

IP: 93.184.216.34

GET / HTTP/1.1
Host: site1.example.com
→ Serve site1

GET / HTTP/1.1
Host: site2.example.com
→ Serve site2

Stesso IP, siti diversi grazie a Host header!
```

**Mancante in HTTP/1.1:**
```http
GET / HTTP/1.1

→ HTTP/1.1 400 Bad Request
  
  {
    "error": "HOST_HEADER_REQUIRED",
    "message": "Host header is required in HTTP/1.1"
  }
```

**Nginx virtual host:**
```nginx
server {
    listen 80;
    server_name site1.example.com;
    root /var/www/site1;
}

server {
    listen 80;
    server_name site2.example.com;
    root /var/www/site2;
}

# Stesso IP, routing basato su Host header
```

### 7.3.2 - User-Agent

**Scopo:** Identifica client (browser, bot, app).

**Sintassi:**
```http
User-Agent: <product>/<version> <comment>
```

**Esempi:**

**Browser desktop:**
```http
# Chrome (Windows)
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36

# Firefox (Linux)
User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0

# Safari (macOS)
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15
```

**Browser mobile:**
```http
# Chrome Mobile (Android)
User-Agent: Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.6045.66 Mobile Safari/537.36

# Safari Mobile (iOS)
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1
```

**Tools e bot:**
```http
# curl
User-Agent: curl/7.68.0

# wget
User-Agent: Wget/1.20.3 (linux-gnu)

# Googlebot
User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)

# Postman
User-Agent: PostmanRuntime/7.32.3
```

**Custom app:**
```http
User-Agent: MyApp/1.0 (iOS 17.0; iPhone14)
User-Agent: MyBackend/2.5.0 (Node.js/18.17.0)
```

**Parsing User-Agent (Express.js):**
```javascript
const useragent = require('express-useragent');

app.use(useragent.express());

app.get('/api/data', (req, res) => {
  console.log('Browser:', req.useragent.browser);
  console.log('Version:', req.useragent.version);
  console.log('OS:', req.useragent.os);
  console.log('Platform:', req.useragent.platform);
  console.log('Mobile:', req.useragent.isMobile);
  console.log('Bot:', req.useragent.isBot);
  
  if (req.useragent.isMobile) {
    res.json({ view: 'mobile' });
  } else {
    res.json({ view: 'desktop' });
  }
});
```

**Server response basata su User-Agent:**
```javascript
app.get('/download', (req, res) => {
  const ua = req.get('User-Agent');
  
  if (ua.includes('Windows')) {
    res.download('/files/app-windows.exe');
  } else if (ua.includes('Mac')) {
    res.download('/files/app-macos.dmg');
  } else if (ua.includes('Linux')) {
    res.download('/files/app-linux.deb');
  } else {
    res.status(400).json({ error: 'Platform not supported' });
  }
});
```

### 7.3.3 - Accept

**Scopo:** Tipi di contenuto accettati dal client (content negotiation).

**Sintassi:**
```http
Accept: <media-type>[; q=<quality>][, <media-type>...]
```

**Quality factor (q):** 0.0 (minimo) - 1.0 (massimo, default)

**Esempi:**

**Singolo tipo:**
```http
Accept: application/json
```

**Multipli tipi:**
```http
Accept: application/json, text/html, application/xml
```

**Con quality factor:**
```http
Accept: text/html, application/json;q=0.9, */*;q=0.8

# Preferenze:
# 1. text/html (q=1.0, default)
# 2. application/json (q=0.9)
# 3. qualsiasi altro (q=0.8)
```

**Wildcard:**
```http
# Qualsiasi tipo
Accept: */*

# Qualsiasi sottotipo JSON
Accept: application/*+json

# Qualsiasi immagine
Accept: image/*
```

**Browser tipico:**
```http
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8
```

**API client:**
```http
Accept: application/json
```

**Server response (content negotiation):**
```javascript
app.get('/api/users/123', (req, res) => {
  const user = { id: 123, name: 'Mario' };
  
  res.format({
    'application/json': () => {
      res.json(user);
    },
    'application/xml': () => {
      res.type('application/xml');
      res.send(`
        <?xml version="1.0"?>
        <user>
          <id>123</id>
          <name>Mario</name>
        </user>
      `);
    },
    'text/plain': () => {
      res.send(`User: ${user.name} (ID: ${user.id})`);
    },
    'default': () => {
      res.status(406).json({
        error: 'NOT_ACCEPTABLE',
        message: 'Cannot produce response in requested format'
      });
    }
  });
});
```

**Esempi pratici:**

```http
# Client richiede JSON
GET /api/users/123 HTTP/1.1
Accept: application/json

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"id": 123, "name": "Mario"}

# Client richiede XML
GET /api/users/123 HTTP/1.1
Accept: application/xml

→ HTTP/1.1 200 OK
  Content-Type: application/xml
  
  <?xml version="1.0"?>
  <user>
    <id>123</id>
    <name>Mario</name>
  </user>

# Client richiede formato non supportato
GET /api/users/123 HTTP/1.1
Accept: application/yaml

→ HTTP/1.1 406 Not Acceptable
  
  {
    "error": "NOT_ACCEPTABLE",
    "supported_formats": ["application/json", "application/xml", "text/plain"]
  }
```

### 7.3.4 - Accept-Encoding

**Scopo:** Algoritmi di compressione accettati.

**Sintassi:**
```http
Accept-Encoding: <algorithm>[; q=<quality>][, <algorithm>...]
```

**Algoritmi comuni:**
- `gzip`: Compressione GNU zip (più comune)
- `deflate`: Compressione zlib
- `br`: Brotli (più efficiente, moderno)
- `compress`: Compressione UNIX (deprecato)
- `identity`: Nessuna compressione (default)
- `*`: Qualsiasi algoritmo

**Esempi:**

**Browser moderno:**
```http
Accept-Encoding: gzip, deflate, br
```

**Con quality:**
```http
Accept-Encoding: br;q=1.0, gzip;q=0.8, *;q=0.1

# Preferenze:
# 1. Brotli (q=1.0)
# 2. gzip (q=0.8)
# 3. altri (q=0.1)
```

**Solo gzip:**
```http
Accept-Encoding: gzip
```

**Nessuna compressione:**
```http
Accept-Encoding: identity
```

**Server response:**
```http
GET /large-file.json HTTP/1.1
Accept-Encoding: gzip, br

→ HTTP/1.1 200 OK
  Content-Type: application/json
  Content-Encoding: br
  Content-Length: 1234
  
  [dati compressi con Brotli]
```

**Benefici:**
```
File originale: 100 KB

# Senza compressione
Content-Length: 102400
Transfer time: ~2 sec (50 KB/s)

# Con gzip (~70% compressione)
Content-Encoding: gzip
Content-Length: 30720
Transfer time: ~0.6 sec (50 KB/s)

# Con Brotli (~75% compressione)
Content-Encoding: br
Content-Length: 25600
Transfer time: ~0.5 sec (50 KB/s)
```

**Configurazione server:**

**Nginx:**
```nginx
http {
    # Gzip
    gzip on;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;
    
    # Brotli (richiede modulo)
    brotli on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

**Express.js:**
```javascript
const compression = require('compression');

app.use(compression({
  level: 6, // Compression level (0-9)
  threshold: 1024, // Minimum size to compress (bytes)
  filter: (req, res) => {
    // Comprimi solo text e JSON
    const type = res.getHeader('Content-Type');
    return /json|text|javascript|css/.test(type);
  }
}));
```

### 7.3.5 - Accept-Language

**Scopo:** Lingue preferite dal client.

**Sintassi:**
```http
Accept-Language: <language>[; q=<quality>][, <language>...]
```

**Esempi:**

**Singola lingua:**
```http
Accept-Language: it-IT
```

**Multipli lingue:**
```http
Accept-Language: it-IT, it, en-US, en
```

**Con quality:**
```http
Accept-Language: it-IT;q=1.0, it;q=0.9, en-US;q=0.8, en;q=0.7

# Preferenze:
# 1. Italiano (Italia) - q=1.0
# 2. Italiano generico - q=0.9
# 3. Inglese (US) - q=0.8
# 4. Inglese generico - q=0.7
```

**Browser italiano:**
```http
Accept-Language: it-IT,it;q=0.9,en-US;q=0.8,en;q=0.7
```

**Server response:**
```javascript
app.get('/page', (req, res) => {
  const acceptLang = req.get('Accept-Language');
  
  // Parse lingua preferita
  const preferredLang = acceptLang.split(',')[0].split(';')[0].trim();
  
  if (preferredLang.startsWith('it')) {
    res.send('<h1>Benvenuto!</h1>');
  } else if (preferredLang.startsWith('en')) {
    res.send('<h1>Welcome!</h1>');
  } else if (preferredLang.startsWith('es')) {
    res.send('<h1>¡Bienvenido!</h1>');
  } else {
    res.send('<h1>Hello!</h1>'); // Default
  }
});
```

**i18n (Express.js):**
```javascript
const i18n = require('i18n');

i18n.configure({
  locales: ['en', 'it', 'es', 'fr'],
  defaultLocale: 'en',
  directory: __dirname + '/locales',
  cookie: 'language'
});

app.use(i18n.init);

app.get('/api/data', (req, res) => {
  res.json({
    message: req.__('welcome_message'),
    // welcome_message tradotto in base a Accept-Language
  });
});
```

### 7.3.6 - Authorization

**Scopo:** Credenziali di autenticazione.

**Sintassi:**
```http
Authorization: <auth-scheme> <credentials>
```

**Schemi comuni:**

**1. Basic Authentication:**
```http
Authorization: Basic dXNlcjpwYXNz

# Base64 encode di "user:pass"
# ⚠️ NON sicuro senza HTTPS!
```

**Esempio:**
```bash
# Generare Basic auth
echo -n "mario:secret123" | base64
# Output: bWFyaW86c2VjcmV0MTIz

# Richiesta
curl -H "Authorization: Basic bWFyaW86c2VjcmV0MTIz" \
  https://api.example.com/data
```

**Server (Express.js):**
```javascript
app.get('/api/private', (req, res) => {
  const auth = req.get('Authorization');
  
  if (!auth || !auth.startsWith('Basic ')) {
    res.set('WWW-Authenticate', 'Basic realm="API"');
    return res.status(401).json({ error: 'Authentication required' });
  }
  
  const base64Credentials = auth.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('utf-8');
  const [username, password] = credentials.split(':');
  
  if (username === 'mario' && password === 'secret123') {
    res.json({ message: 'Authenticated!', user: username });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});
```

**2. Bearer Token (JWT):**
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ik1hcmlvIFJvc3NpIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Esempio:**
```javascript
const jwt = require('jsonwebtoken');

// Login endpoint
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  
  // Verifica credenziali
  if (username === 'mario' && password === 'secret123') {
    // Genera JWT
    const token = jwt.sign(
      { userId: 123, username: 'mario', role: 'admin' },
      'secret-key',
      { expiresIn: '1h' }
    );
    
    res.json({ token });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Protected endpoint
app.get('/api/private', (req, res) => {
  const auth = req.get('Authorization');
  
  if (!auth || !auth.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token required' });
  }
  
  const token = auth.split(' ')[1];
  
  try {
    const decoded = jwt.verify(token, 'secret-key');
    res.json({ message: 'Authenticated!', user: decoded });
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});
```

**3. Digest Authentication:**
```http
Authorization: Digest username="mario", realm="API", nonce="dcd98b7102dd2f0e8b11d0f600bfb0c093", uri="/api/data", response="6629fae49393a05397450978507c4ef1"
```

**4. OAuth 2.0:**
```http
Authorization: Bearer ya29.a0AfH6SMBx...
```

**5. API Key (custom):**
```http
Authorization: ApiKey sk_live_51H...
```

---

**Continua nella Parte 2...**

Prossimi argomenti:
- 7.3.7 Referer
- 7.3.8 Cookie
- 7.3.9 If-* (Conditional headers)
- 7.4 Response Headers
- 7.5 Entity Headers
- 7.6 Custom Headers
- 7.7 CORS Headers
- 7.8 Security Headers

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
