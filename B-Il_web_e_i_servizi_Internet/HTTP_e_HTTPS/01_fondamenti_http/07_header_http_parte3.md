# 7. Header HTTP (Parte 3)

## 7.5 Entity Headers

Header che descrivono il corpo (body) del messaggio HTTP.

### 7.5.1 - Content-Type

**Scopo:** Tipo MIME del contenuto nel body.

**Sintassi:**
```http
Content-Type: <media-type>[; charset=<charset>]
```

**Media Types comuni:**

| Media Type | Descrizione | Uso |
|------------|-------------|-----|
| `text/html` | HTML | Pagine web |
| `text/plain` | Testo semplice | File di testo |
| `text/css` | CSS | Fogli di stile |
| `text/javascript` | JavaScript | Script |
| `application/json` | JSON | API, dati strutturati |
| `application/xml` | XML | Dati strutturati |
| `application/pdf` | PDF | Documenti |
| `application/zip` | ZIP | Archivi compressi |
| `application/octet-stream` | Binario generico | Download file |
| `image/jpeg` | JPEG | Immagini |
| `image/png` | PNG | Immagini |
| `image/gif` | GIF | Immagini animate |
| `image/webp` | WebP | Immagini moderne |
| `image/svg+xml` | SVG | Vettoriali |
| `audio/mpeg` | MP3 | Audio |
| `video/mp4` | MP4 | Video |
| `multipart/form-data` | Form con file | Upload file |

**Esempi:**

**JSON API:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario Rossi", "email": "mario@example.com"}

→ HTTP/1.1 201 Created
  Content-Type: application/json; charset=utf-8
  
  {"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}
```

**HTML:**
```http
GET /page.html HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: text/html; charset=utf-8
  
  <!DOCTYPE html>
  <html>...</html>
```

**Form submission:**
```http
POST /submit HTTP/1.1
Content-Type: application/x-www-form-urlencoded

name=Mario&email=mario@example.com
```

**File upload:**
```http
POST /upload HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="photo.jpg"
Content-Type: image/jpeg

[binary data]
------WebKitFormBoundary--
```

**Binary file:**
```http
GET /download/file.zip HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: application/zip
  Content-Disposition: attachment; filename="archive.zip"
  
  [binary data]
```

**Charset:**
```http
Content-Type: text/html; charset=utf-8
Content-Type: text/plain; charset=iso-8859-1
Content-Type: application/json; charset=utf-8
```

**Express.js:**
```javascript
// Automatic Content-Type
app.get('/api/data', (req, res) => {
  res.json({ data: 'value' });
  // Content-Type: application/json automatico
});

app.get('/page', (req, res) => {
  res.send('<h1>Hello</h1>');
  // Content-Type: text/html automatico
});

// Manual Content-Type
app.get('/custom', (req, res) => {
  res.type('text/plain');
  res.send('Plain text response');
});

app.get('/download', (req, res) => {
  res.type('application/pdf');
  res.sendFile('/path/to/document.pdf');
});
```

**Nginx:**
```nginx
http {
    # Default MIME types
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    # Override per specifici file
    location ~ \.json$ {
        add_header Content-Type application/json;
    }
    
    location ~ \.webmanifest$ {
        add_header Content-Type application/manifest+json;
    }
}
```

### 7.5.2 - Content-Length

**Scopo:** Dimensione del body in byte.

**Sintassi:**
```http
Content-Length: <size-in-bytes>
```

**Esempi:**

```http
POST /api/data HTTP/1.1
Content-Type: application/json
Content-Length: 45

{"name": "Mario", "email": "mario@example.com"}
```

```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1234

<!DOCTYPE html>...
```

**Importante:**
- ✅ Obbligatorio per richieste con body (POST, PUT, PATCH)
- ✅ Utile per progress bar (download)
- ⚠️ Non usato con `Transfer-Encoding: chunked`

**Progress tracking (client):**
```javascript
async function downloadWithProgress(url) {
  const response = await fetch(url);
  const contentLength = response.headers.get('Content-Length');
  const total = parseInt(contentLength, 10);
  
  let loaded = 0;
  const reader = response.body.getReader();
  
  while (true) {
    const { done, value } = await reader.read();
    
    if (done) break;
    
    loaded += value.length;
    const progress = (loaded / total) * 100;
    console.log(`Progress: ${progress.toFixed(2)}%`);
  }
}
```

**Automatic calculation (Express.js):**
```javascript
app.get('/api/data', (req, res) => {
  const data = { message: 'Hello World' };
  const json = JSON.stringify(data);
  
  // Express calcola automaticamente Content-Length
  res.json(data);
  // Content-Length: 27 (lunghezza JSON)
});
```

### 7.5.3 - Content-Encoding

**Scopo:** Algoritmo di compressione applicato al body.

**Sintassi:**
```http
Content-Encoding: <algorithm>[, <algorithm>...]
```

**Algoritmi:**
- `gzip`: Compressione GNU zip
- `deflate`: Compressione zlib
- `br`: Brotli (più efficiente)
- `compress`: UNIX compress (deprecato)
- `identity`: Nessuna compressione

**Esempi:**

```http
GET /large-file.json HTTP/1.1
Accept-Encoding: gzip, br

→ HTTP/1.1 200 OK
  Content-Type: application/json
  Content-Encoding: br
  Content-Length: 1234
  
  [dati compressi con Brotli]
```

**Multipli encoding:**
```http
Content-Encoding: gzip, deflate
# Applicati in ordine: prima deflate, poi gzip
# Client deve decomprimere in ordine inverso
```

**Performance comparison:**
```
File originale: 100 KB JSON

No compression:
Content-Length: 102400
Transfer time: 2.0s @ 50 KB/s

gzip (level 6):
Content-Encoding: gzip
Content-Length: 20480 (~80% riduzione)
Transfer time: 0.4s @ 50 KB/s

Brotli (quality 6):
Content-Encoding: br
Content-Length: 15360 (~85% riduzione)
Transfer time: 0.3s @ 50 KB/s
```

**Server config (Nginx):**
```nginx
http {
    # Gzip
    gzip on;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types 
        text/plain 
        text/css 
        text/javascript 
        application/json 
        application/javascript 
        application/xml;
    gzip_vary on;
    
    # Brotli (richiede modulo)
    brotli on;
    brotli_comp_level 6;
    brotli_types 
        text/plain 
        text/css 
        application/json 
        application/javascript;
}
```

**Express.js:**
```javascript
const compression = require('compression');

app.use(compression({
  level: 6,
  threshold: 1024, // Comprimi solo se > 1KB
  filter: (req, res) => {
    // Comprimi solo text/JSON
    const type = res.getHeader('Content-Type');
    return /json|text|javascript|css/.test(type);
  }
}));
```

### 7.5.4 - Content-Language

**Scopo:** Lingua del contenuto.

**Sintassi:**
```http
Content-Language: <language>[, <language>...]
```

**Esempi:**

```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Language: it-IT

<!DOCTYPE html>
<html lang="it">
  <h1>Benvenuto</h1>
</html>
```

**Multipli lingue:**
```http
Content-Language: en, it, es
```

**Express.js:**
```javascript
app.get('/page', (req, res) => {
  const lang = req.acceptsLanguages(['en', 'it', 'es']) || 'en';
  
  res.set('Content-Language', lang);
  
  const content = {
    'en': '<h1>Welcome</h1>',
    'it': '<h1>Benvenuto</h1>',
    'es': '<h1>Bienvenido</h1>'
  };
  
  res.send(content[lang]);
});
```

### 7.5.5 - Content-Disposition

**Scopo:** Indica se contenuto deve essere visualizzato inline o scaricato.

**Sintassi:**
```http
Content-Disposition: <disposition-type>[; <parameters>]
```

**Disposition types:**
- `inline`: Visualizza nel browser
- `attachment`: Scarica come file

**Esempi:**

**Download file:**
```http
HTTP/1.1 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="document.pdf"

[PDF data]
```

**Visualizza inline:**
```http
HTTP/1.1 200 OK
Content-Type: image/jpeg
Content-Disposition: inline

[image data]
```

**Filename con caratteri speciali:**
```http
Content-Disposition: attachment; filename="report.pdf"; filename*=UTF-8''report%20%E2%80%93%202025.pdf
```

**Express.js:**
```javascript
// Download
app.get('/download/:file', (req, res) => {
  const filename = req.params.file;
  res.download(`/path/to/${filename}`);
  // Imposta automaticamente Content-Disposition: attachment
});

// Inline
app.get('/view/:file', (req, res) => {
  res.sendFile(`/path/to/${req.params.file}`, {
    headers: {
      'Content-Disposition': 'inline'
    }
  });
});

// Custom filename
app.get('/export', (req, res) => {
  res.set('Content-Disposition', 'attachment; filename="export-2025.csv"');
  res.type('text/csv');
  res.send('name,email\nMario,mario@example.com');
});
```

### 7.5.6 - Content-Range

**Scopo:** Indica quale parte del documento viene inviata (partial content).

**Sintassi:**
```http
Content-Range: <unit> <range-start>-<range-end>/<total-size>
```

**Esempi:**

**Partial download:**
```http
GET /video.mp4 HTTP/1.1
Range: bytes=0-1023

→ HTTP/1.1 206 Partial Content
  Content-Type: video/mp4
  Content-Range: bytes 0-1023/524288000
  Content-Length: 1024
  
  [primi 1024 byte]
```

**Resume download:**
```http
GET /file.zip HTTP/1.1
Range: bytes=10485760-

→ HTTP/1.1 206 Partial Content
  Content-Range: bytes 10485760-104857599/104857600
  Content-Length: 94371840
  
  [byte da 10MB fino alla fine]
```

**Unsatisfiable range:**
```http
GET /file.zip HTTP/1.1
Range: bytes=200000000-

→ HTTP/1.1 416 Range Not Satisfiable
  Content-Range: bytes */104857600
  
  # File è solo 100MB, richiesta oltre limite
```

**Express.js (basic range support):**
```javascript
app.get('/video/:id', (req, res) => {
  const videoPath = `/path/to/video-${req.params.id}.mp4`;
  const stat = fs.statSync(videoPath);
  const fileSize = stat.size;
  const range = req.headers.range;
  
  if (range) {
    const parts = range.replace(/bytes=/, '').split('-');
    const start = parseInt(parts[0], 10);
    const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
    const chunkSize = (end - start) + 1;
    const file = fs.createReadStream(videoPath, { start, end });
    
    res.writeHead(206, {
      'Content-Range': `bytes ${start}-${end}/${fileSize}`,
      'Accept-Ranges': 'bytes',
      'Content-Length': chunkSize,
      'Content-Type': 'video/mp4'
    });
    
    file.pipe(res);
  } else {
    res.writeHead(200, {
      'Content-Length': fileSize,
      'Content-Type': 'video/mp4'
    });
    
    fs.createReadStream(videoPath).pipe(res);
  }
});
```

### 7.5.7 - Transfer-Encoding

**Scopo:** Codifica applicata per trasferire il body in modo sicuro.

**Sintassi:**
```http
Transfer-Encoding: <encoding>[, <encoding>...]
```

**Encoding più comune: chunked**

```http
HTTP/1.1 200 OK
Content-Type: text/plain
Transfer-Encoding: chunked

7\r\n
Mozilla\r\n
9\r\n
Developer\r\n
7\r\n
Network\r\n
0\r\n
\r\n
```

**Chunk format:**
```
<size-in-hex>\r\n
<data>\r\n
...
0\r\n
\r\n
```

**Uso:**
- ✅ Streaming di dati (dimensione sconosciuta)
- ✅ Server-Sent Events (SSE)
- ✅ Generazione dinamica contenuto
- ⚠️ Non usare con Content-Length (mutually exclusive)

**Express.js streaming:**
```javascript
app.get('/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/plain');
  res.setHeader('Transfer-Encoding', 'chunked');
  
  let count = 0;
  const interval = setInterval(() => {
    res.write(`Chunk ${count}\n`);
    count++;
    
    if (count >= 10) {
      clearInterval(interval);
      res.end();
    }
  }, 1000);
});
```

**Server-Sent Events:**
```javascript
app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  
  const sendEvent = (data) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };
  
  const interval = setInterval(() => {
    sendEvent({ time: new Date().toISOString() });
  }, 1000);
  
  req.on('close', () => {
    clearInterval(interval);
  });
});
```

## 7.6 CORS Headers

Header per Cross-Origin Resource Sharing.

### 7.6.1 - Access-Control-Allow-Origin

**Scopo:** Specifica origine permessa per cross-origin requests.

**Sintassi:**
```http
Access-Control-Allow-Origin: <origin> | *
```

**Esempi:**

**Singola origine:**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://www.example.com
```

**Wildcard (tutti):**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: *
```

**⚠️ Con credenziali, NO wildcard:**
```http
# ❌ Non funziona
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true

# ✅ Corretto
Access-Control-Allow-Origin: https://www.example.com
Access-Control-Allow-Credentials: true
```

**Dynamic origin (Express.js):**
```javascript
const allowedOrigins = [
  'https://www.example.com',
  'https://app.example.com',
  'https://mobile.example.com'
];

app.use((req, res, next) => {
  const origin = req.get('Origin');
  
  if (allowedOrigins.includes(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  
  next();
});
```

### 7.6.2 - Access-Control-Allow-Methods

**Scopo:** Metodi HTTP permessi per cross-origin.

**Sintassi:**
```http
Access-Control-Allow-Methods: <method>[, <method>...]
```

**Esempio:**
```http
HTTP/1.1 204 No Content
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

### 7.6.3 - Access-Control-Allow-Headers

**Scopo:** Header permessi in cross-origin requests.

**Sintassi:**
```http
Access-Control-Allow-Headers: <header>[, <header>...]
```

**Esempio:**
```http
HTTP/1.1 204 No Content
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With
```

### 7.6.4 - Access-Control-Max-Age

**Scopo:** Quanto tempo cachare preflight response.

**Sintassi:**
```http
Access-Control-Max-Age: <seconds>
```

**Esempio:**
```http
HTTP/1.1 204 No Content
Access-Control-Max-Age: 3600
# Cache preflight per 1 ora
```

### 7.6.5 - Access-Control-Allow-Credentials

**Scopo:** Permetti invio di credenziali (cookie, auth headers).

**Sintassi:**
```http
Access-Control-Allow-Credentials: true
```

**Esempio:**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://www.example.com
Access-Control-Allow-Credentials: true
```

### 7.6.6 - CORS Complete Example

**Preflight request:**
```http
OPTIONS /api/data HTTP/1.1
Host: api.example.com
Origin: https://www.myapp.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization

→ HTTP/1.1 204 No Content
  Access-Control-Allow-Origin: https://www.myapp.com
  Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
  Access-Control-Allow-Headers: Content-Type, Authorization
  Access-Control-Max-Age: 86400
  Access-Control-Allow-Credentials: true
```

**Actual request:**
```http
POST /api/data HTTP/1.1
Host: api.example.com
Origin: https://www.myapp.com
Content-Type: application/json
Authorization: Bearer token123

{"data": "value"}

→ HTTP/1.1 200 OK
  Access-Control-Allow-Origin: https://www.myapp.com
  Access-Control-Allow-Credentials: true
  Content-Type: application/json
  
  {"result": "success"}
```

**Express.js CORS middleware:**
```javascript
const cors = require('cors');

// Simple (allow all)
app.use(cors());

// Custom
app.use(cors({
  origin: ['https://www.example.com', 'https://app.example.com'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
  maxAge: 86400
}));

// Dynamic
app.use(cors({
  origin: (origin, callback) => {
    const allowedOrigins = ['https://www.example.com'];
    
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  }
}));

// Per-route
app.get('/public', cors(), (req, res) => {
  res.json({ data: 'public' });
});

app.get('/private', cors({
  origin: 'https://www.example.com',
  credentials: true
}), (req, res) => {
  res.json({ data: 'private' });
});
```

**Nginx CORS:**
```nginx
location /api/ {
    if ($request_method = 'OPTIONS') {
        add_header 'Access-Control-Allow-Origin' '$http_origin' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization' always;
        add_header 'Access-Control-Max-Age' 86400 always;
        add_header 'Access-Control-Allow-Credentials' 'true' always;
        add_header 'Content-Length' 0;
        return 204;
    }
    
    add_header 'Access-Control-Allow-Origin' '$http_origin' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    
    proxy_pass http://backend;
}
```

## 7.7 Security Headers

Header per migliorare la sicurezza web.

### 7.7.1 - Strict-Transport-Security (HSTS)

**Scopo:** Forza uso di HTTPS.

**Sintassi:**
```http
Strict-Transport-Security: max-age=<seconds>[; includeSubDomains][; preload]
```

**Esempi:**

```http
Strict-Transport-Security: max-age=31536000
# HTTPS obbligatorio per 1 anno
```

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
# HTTPS per dominio e sottodomini, preload list
```

**Comportamento:**
```
User: http://example.com
Browser: Automaticamente → https://example.com (no request HTTP)
```

**Express.js:**
```javascript
const helmet = require('helmet');

app.use(helmet.hsts({
  maxAge: 31536000,
  includeSubDomains: true,
  preload: true
}));
```

**Nginx:**
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

### 7.7.2 - Content-Security-Policy (CSP)

**Scopo:** Previene XSS, injection attacks.

**Sintassi:**
```http
Content-Security-Policy: <directive> <source>[; <directive> <source>...]
```

**Direttive comuni:**
- `default-src`: Default per tutte le risorse
- `script-src`: JavaScript
- `style-src`: CSS
- `img-src`: Immagini
- `font-src`: Font
- `connect-src`: Fetch, XHR, WebSocket
- `frame-src`: iframe
- `media-src`: Audio, video

**Sources:**
- `'self'`: Stesso origin
- `'none'`: Nessuno
- `'unsafe-inline'`: Inline scripts/styles (⚠️ non sicuro)
- `'unsafe-eval'`: eval() (⚠️ non sicuro)
- `https:`: Solo HTTPS
- `*.example.com`: Dominio specifico

**Esempi:**

**Strict (raccomandato):**
```http
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-src 'none'; object-src 'none'
```

**Con CDN:**
```http
Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.example.com; style-src 'self' https://cdn.example.com; img-src 'self' https://cdn.example.com data:
```

**Report-only (testing):**
```http
Content-Security-Policy-Report-Only: default-src 'self'; report-uri /csp-report
```

**Express.js:**
```javascript
app.use(helmet.contentSecurityPolicy({
  directives: {
    defaultSrc: ["'self'"],
    scriptSrc: ["'self'", "https://cdn.example.com"],
    styleSrc: ["'self'", "https://cdn.example.com"],
    imgSrc: ["'self'", "data:", "https://cdn.example.com"],
    connectSrc: ["'self'"],
    fontSrc: ["'self'"],
    objectSrc: ["'none'"],
    mediaSrc: ["'self'"],
    frameSrc: ["'none'"]
  }
}));
```

### 7.7.3 - X-Content-Type-Options

**Scopo:** Previene MIME sniffing.

**Sintassi:**
```http
X-Content-Type-Options: nosniff
```

**Esempio:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
X-Content-Type-Options: nosniff
```

**Perché importante:**
```
# Senza header:
Content-Type: text/plain
<script>alert('XSS')</script>
# Browser potrebbe interpretare come HTML ed eseguire script!

# Con nosniff:
Content-Type: text/plain
X-Content-Type-Options: nosniff
<script>alert('XSS')</script>
# Browser rispetta Content-Type, tratta come text/plain
```

### 7.7.4 - X-Frame-Options

**Scopo:** Previene clickjacking (framing non autorizzato).

**Sintassi:**
```http
X-Frame-Options: DENY | SAMEORIGIN | ALLOW-FROM <uri>
```

**Valori:**
- `DENY`: Non può essere in iframe
- `SAMEORIGIN`: Solo da stesso origin
- `ALLOW-FROM uri`: Solo da URI specificato (deprecato, usare CSP)

**Esempi:**
```http
X-Frame-Options: DENY
X-Frame-Options: SAMEORIGIN
```

**Express.js:**
```javascript
app.use(helmet.frameguard({ action: 'deny' }));
app.use(helmet.frameguard({ action: 'sameorigin' }));
```

### 7.7.5 - X-XSS-Protection

**Scopo:** Abilita filtro XSS browser (legacy).

**⚠️ Deprecato:** Usare CSP invece.

**Sintassi:**
```http
X-XSS-Protection: 0 | 1 | 1; mode=block
```

**Esempio:**
```http
X-XSS-Protection: 1; mode=block
```

### 7.7.6 - Permissions-Policy (Feature-Policy)

**Scopo:** Controlla feature browser disponibili.

**Sintassi:**
```http
Permissions-Policy: <feature>=(<allowlist>)
```

**Esempio:**
```http
Permissions-Policy: geolocation=(self), microphone=(), camera=()
# Geolocation solo same-origin
# Microphone e camera disabilitati
```

**Features:**
- `geolocation`
- `microphone`
- `camera`
- `payment`
- `usb`
- `fullscreen`
- `accelerometer`
- `gyroscope`

### 7.7.7 - Complete Security Headers Example

**Express.js (Helmet):**
```javascript
const helmet = require('helmet');

app.use(helmet({
  // HSTS
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  
  // CSP
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
      styleSrc: ["'self'"],
      imgSrc: ["'self'", "data:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      frameSrc: ["'none'"]
    }
  },
  
  // Other headers
  noSniff: true,                    // X-Content-Type-Options
  frameguard: { action: 'deny' },  // X-Frame-Options
  xssFilter: true,                 // X-XSS-Protection
  hidePoweredBy: true              // Remove X-Powered-By
}));
```

**Nginx:**
```nginx
# HSTS
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# CSP
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:" always;

# X-Content-Type-Options
add_header X-Content-Type-Options "nosniff" always;

# X-Frame-Options
add_header X-Frame-Options "DENY" always;

# X-XSS-Protection
add_header X-XSS-Protection "1; mode=block" always;

# Referrer-Policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Permissions-Policy
add_header Permissions-Policy "geolocation=(self), microphone=(), camera=()" always;
```

---

**Capitolo 7 completato!**

Prossimi capitoli:
- **Capitolo 8**: Caching HTTP
- **Capitolo 9**: Autenticazione e Autorizzazione
- **Capitolo 10**: Cookies e Sessioni
- E molti altri...

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
