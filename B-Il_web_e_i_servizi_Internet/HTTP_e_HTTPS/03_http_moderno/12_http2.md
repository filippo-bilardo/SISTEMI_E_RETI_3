# 12. HTTP/2

## 12.1 Introduzione a HTTP/2

HTTP/2 è una major revision del protocollo HTTP, pubblicato nel 2015 (RFC 7540), che introduce miglioramenti significativi nelle performance.

### 12.1.1 - Motivazioni

**Problemi HTTP/1.1:**
- ❌ Head-of-line blocking
- ❌ Una richiesta per volta per connessione
- ❌ Header ridondanti (ripetuti in ogni richiesta)
- ❌ Necessità di workaround (domain sharding, sprite sheets)

**Obiettivi HTTP/2:**
- ✅ Ridurre latenza
- ✅ Minimizzare overhead protocollo
- ✅ Supporto multiplexing
- ✅ Header compression
- ✅ Server push
- ✅ Priorità richieste

### 12.1.2 - Differenze Chiave

| Feature | HTTP/1.1 | HTTP/2 |
|---------|----------|--------|
| Protocol | Text-based | Binary |
| Connections | Multiple | Single |
| Multiplexing | No | Yes |
| Header Compression | No | HPACK |
| Server Push | No | Yes |
| Stream Priority | No | Yes |
| Required | HTTP/HTTPS | HTTPS (de facto) |

## 12.2 Binary Framing Layer

HTTP/2 introduce un **binary framing layer** tra socket e HTTP API.

### 12.2.1 - Concetti Base

**Stream:** Flusso bidirezionale di frame tra client e server  
**Message:** Sequenza completa di frame che costituisce richiesta/risposta  
**Frame:** Unità minima di comunicazione (HEADERS, DATA, SETTINGS, etc.)  

```
Connection (TCP)
├── Stream 1
│   ├── HEADERS frame (request)
│   ├── DATA frame (request body)
│   ├── HEADERS frame (response)
│   └── DATA frame (response body)
├── Stream 3
│   ├── HEADERS frame
│   └── DATA frame
└── Stream 5
    └── HEADERS frame
```

### 12.2.2 - Frame Types

**HEADERS:** HTTP headers  
**DATA:** Payload  
**PRIORITY:** Stream priority  
**RST_STREAM:** Termina stream  
**SETTINGS:** Connection parameters  
**PUSH_PROMISE:** Server push notification  
**PING:** Connection liveness  
**GOAWAY:** Connection shutdown  
**WINDOW_UPDATE:** Flow control  
**CONTINUATION:** Continue headers  

## 12.3 Multiplexing

### 12.3.1 - Come Funziona

**HTTP/1.1 (6 connections):**
```
Connection 1: [====== Request 1 ======]
Connection 2: [====== Request 2 ======]
Connection 3: [====== Request 3 ======]
Connection 4: [====== Request 4 ======]
Connection 5: [====== Request 5 ======]
Connection 6: [====== Request 6 ======]
```

**HTTP/2 (1 connection, multiple streams):**
```
Connection 1: [R1][R2][R3][R1][R4][R2][R5][R1][R3][...]
              Stream interleaving
```

### 12.3.2 - Vantaggi

✅ **Elimina head-of-line blocking** (a livello applicazione)  
✅ **Riduce connessioni TCP** (meno overhead)  
✅ **Migliore utilizzo banda**  
✅ **Nessun domain sharding necessario**  

### 12.3.3 - Esempio

**Client invia multiple requests:**
```
Stream 1: GET /index.html
Stream 3: GET /style.css
Stream 5: GET /script.js
Stream 7: GET /image.png
```

**Server risponde interleaved:**
```
Stream 1: HEADERS + DATA (HTML)
Stream 3: HEADERS + DATA (CSS)
Stream 1: DATA (more HTML)
Stream 5: HEADERS + DATA (JS)
Stream 7: HEADERS + DATA (image)
Stream 1: DATA (final HTML chunk)
```

Tutti su **una singola connessione TCP**!

## 12.4 Header Compression (HPACK)

### 12.4.1 - Problema

HTTP/1.1 headers sono **ripetitivi** e **non compressi**:

```http
GET /page1.html HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0...
Accept: text/html...
Cookie: session=abc123...
[500+ bytes di headers]

GET /page2.html HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0...
Accept: text/html...
Cookie: session=abc123...
[500+ bytes RIPETUTI]
```

### 12.4.2 - Soluzione HPACK

**HPACK** (RFC 7541) comprime headers usando:
- **Static table:** Headers comuni predefiniti
- **Dynamic table:** Headers specifici della connessione
- **Huffman encoding:** Compressione ulteriore

**Esempio compressione:**
```
Prima richiesta:
Host: example.com → Indice 42 in static table
User-Agent: Mozilla... → Aggiunto a dynamic table come indice 62

Richieste successive:
Host: example.com → :42 (riferimento indice)
User-Agent: Mozilla... → :62 (riferimento indice)

Riduzione: 500 bytes → 50 bytes (~90% compressione!)
```

### 12.4.3 - Static Table (esempi)

| Index | Header Name | Header Value |
|-------|-------------|--------------|
| 1 | :authority | |
| 2 | :method | GET |
| 3 | :method | POST |
| 4 | :path | / |
| 8 | :status | 200 |
| 15 | accept-encoding | gzip, deflate |
| 42 | host | |

## 12.5 Server Push

### 12.5.1 - Concetto

Server può **inviare risorse al client** prima che vengano richieste.

**Scenario tipico:**
```
Client: GET /index.html

Server (sa che HTML referenzia CSS/JS):
→ PUSH_PROMISE per /style.css
→ PUSH_PROMISE per /script.js
→ Response /index.html
→ Response /style.css (pushed)
→ Response /script.js (pushed)

Client riceve tutto senza ulteriori richieste!
```

### 12.5.2 - Flow

```
1. Client → Server: HEADERS (GET /index.html)

2. Server → Client: PUSH_PROMISE
   Stream 1: Response headers for /index.html
   Stream 2: PUSH_PROMISE for /style.css
   Stream 4: PUSH_PROMISE for /script.js

3. Server → Client: DATA
   Stream 1: HTML content
   Stream 2: CSS content (pushed)
   Stream 4: JS content (pushed)
```

### 12.5.3 - Vantaggi e Svantaggi

**✅ Vantaggi:**
- Riduce round-trips
- Migliora perceived performance
- Ottimale per risorse critiche

**❌ Svantaggi:**
- Client potrebbe già avere risorsa in cache (spreco banda)
- Complessità server
- Client può rifiutare push (RST_STREAM)

### 12.5.4 - Configurazione

**Nginx:**
```nginx
server {
    listen 443 ssl http2;
    
    location / {
        # Push critical resources
        http2_push /css/style.css;
        http2_push /js/app.js;
        
        root /var/www/html;
    }
}
```

**Node.js (http2 module):**
```javascript
const http2 = require('http2');
const fs = require('fs');

const server = http2.createSecureServer({
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
});

server.on('stream', (stream, headers) => {
  if (headers[':path'] === '/') {
    // Push CSS
    stream.pushStream({ ':path': '/style.css' }, (err, pushStream) => {
      pushStream.respond({ ':status': 200 });
      pushStream.end(fs.readFileSync('style.css'));
    });
    
    // Send HTML
    stream.respond({ ':status': 200 });
    stream.end(fs.readFileSync('index.html'));
  }
});

server.listen(3000);
```

## 12.6 Stream Prioritization

### 12.6.1 - Dependency Tree

Client può indicare **priorità** tra stream:

```
Stream 1 (HTML) - Priority: 256 (highest)
├── Stream 3 (CSS) - Priority: 128
├── Stream 5 (JS) - Priority: 64
└── Stream 7 (Image) - Priority: 16 (lowest)
```

**Server dovrebbe processare:**
1. HTML completo
2. CSS (blocking render)
3. JS (blocking render)
4. Images (non-blocking)

### 12.6.2 - PRIORITY Frame

```
PRIORITY Frame:
├── Stream Dependency: 1 (depends on stream 1)
├── Weight: 16 (relative priority)
└── Exclusive: false
```

## 12.7 Flow Control

HTTP/2 implementa **flow control** per evitare che sender sovraccarichi receiver.

### 12.7.1 - WINDOW_UPDATE

```
Initial window size: 65535 bytes

Client → Server: DATA (10000 bytes)
Window size: 55535 bytes

Client ← Server: WINDOW_UPDATE (+10000)
Window size: 65535 bytes (restored)
```

## 12.8 Implementazione Pratica

### 12.8.1 - Nginx HTTP/2

```nginx
http {
    # HTTP/2 settings
    http2_max_field_size 16k;
    http2_max_header_size 32k;
    http2_max_requests 1000;
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        ssl_certificate /path/to/cert.pem;
        ssl_certificate_key /path/to/key.pem;
        
        # Push critical resources
        location = /index.html {
            http2_push /css/main.css;
            http2_push /js/app.js;
        }
        
        # Static files
        location /static/ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 12.8.2 - Node.js HTTP/2 Server

```javascript
const http2 = require('http2');
const fs = require('fs');

const server = http2.createSecureServer({
  key: fs.readFileSync('server-key.pem'),
  cert: fs.readFileSync('server-cert.pem')
});

server.on('error', (err) => console.error(err));

server.on('stream', (stream, headers) => {
  const path = headers[':path'];
  
  // Log request
  console.log(`${headers[':method']} ${path}`);
  
  // Route handling
  if (path === '/') {
    // Server push
    stream.pushStream({ ':path': '/style.css' }, (err, pushStream) => {
      if (err) throw err;
      
      pushStream.respond({
        'content-type': 'text/css',
        ':status': 200
      });
      pushStream.end(fs.readFileSync('public/style.css'));
    });
    
    // Send HTML
    stream.respond({
      'content-type': 'text/html',
      ':status': 200
    });
    stream.end(fs.readFileSync('public/index.html'));
    
  } else if (path === '/api/data') {
    // API endpoint
    stream.respond({
      'content-type': 'application/json',
      ':status': 200
    });
    stream.end(JSON.stringify({ message: 'Hello HTTP/2' }));
    
  } else {
    // 404
    stream.respond({ ':status': 404 });
    stream.end('Not found');
  }
});

server.listen(3000, () => {
  console.log('HTTP/2 server listening on port 3000');
});
```

### 12.8.3 - Express.js con HTTP/2

```javascript
const express = require('express');
const http2 = require('http2');
const http2Express = require('http2-express-bridge');
const fs = require('fs');

const app = http2Express(express);

app.use(express.json());

app.get('/', (req, res) => {
  // Server push
  res.push('/style.css', {
    request: { accept: '*/*' },
    response: { 'content-type': 'text/css' }
  }).end(fs.readFileSync('public/style.css'));
  
  res.sendFile(__dirname + '/public/index.html');
});

app.get('/api/users', (req, res) => {
  res.json([
    { id: 1, name: 'Mario' },
    { id: 2, name: 'Luigi' }
  ]);
});

const server = http2.createSecureServer({
  key: fs.readFileSync('server-key.pem'),
  cert: fs.readFileSync('server-cert.pem'),
  allowHTTP1: true // Fallback to HTTP/1.1
}, app);

server.listen(3000, () => {
  console.log('Server running on https://localhost:3000');
});
```

## 12.9 Client HTTP/2

### 12.9.1 - curl con HTTP/2

```bash
# Test HTTP/2
curl --http2 https://example.com

# Verbose (see HTTP/2 frames)
curl --http2 -v https://example.com

# Force HTTP/2 only
curl --http2-prior-knowledge https://example.com
```

### 12.9.2 - Fetch API (Browser)

```javascript
// Browser automatically uses HTTP/2 if available
fetch('https://example.com/api/data')
  .then(response => response.json())
  .then(data => console.log(data));

// Multiple parallel requests (multiplexed over single connection)
Promise.all([
  fetch('/api/users'),
  fetch('/api/posts'),
  fetch('/api/comments')
]).then(async ([users, posts, comments]) => {
  const userData = await users.json();
  const postData = await posts.json();
  const commentData = await comments.json();
  
  console.log({ userData, postData, commentData });
});
```

## 12.10 Performance Comparison

### 12.10.1 - Benchmark Example

**Scenario:** Load page with 1 HTML + 50 images

**HTTP/1.1 (6 connections):**
```
Time to load: 3.5 seconds
Connections: 6 TCP
Requests: 51 sequential (9 rounds)
```

**HTTP/2 (1 connection):**
```
Time to load: 1.2 seconds
Connections: 1 TCP
Requests: 51 multiplexed
Improvement: 66% faster!
```

### 12.10.2 - Best Practices

**✅ DO:**
- Enable HTTP/2 on server
- Use single domain (no sharding)
- Push critical resources
- Inline small CSS (< 1KB)
- Use resource hints (`<link rel="preload">`)

**❌ DON'T:**
- Domain sharding (hurts HTTP/2)
- Concatenate all CSS/JS (loses granular caching)
- Over-push (waste bandwidth)
- Sprite sheets (better individual images with HTTP/2)

## 12.11 Troubleshooting

### 12.11.1 - Verify HTTP/2

**Chrome DevTools:**
```
Network tab → Right-click column headers → Add "Protocol"
Look for "h2" (HTTP/2)
```

**curl:**
```bash
curl -I --http2 https://example.com | grep -i "HTTP"
# HTTP/2 200
```

**Online tools:**
```
https://tools.keycdn.com/http2-test
```

### 12.11.2 - Common Issues

**ALPN not supported:**
- Server needs ALPN (Application-Layer Protocol Negotiation)
- Requires TLS 1.2+

**Mixed Content:**
- HTTP/2 requires HTTPS
- Ensure all resources use HTTPS

**Browser compatibility:**
- HTTP/2 supported in all modern browsers
- IE 11 requires Windows 10

---

**Capitolo 12 completato!**

Prossimo: **Capitolo 13 - HTTP/3 e QUIC**
