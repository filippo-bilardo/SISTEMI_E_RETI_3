# 14. Confronto HTTP/1.1, HTTP/2, HTTP/3

## 14.1 Tabella Comparativa Completa

| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---------|----------|--------|--------|
| **Anno** | 1997 | 2015 | 2022 |
| **RFC** | 7230-7235 | 7540 | 9114 |
| **Protocollo** | Text-based | Binary | Binary |
| **Transport** | TCP | TCP | QUIC/UDP |
| **Encryption** | Optional (TLS) | De facto TLS | Mandatory TLS 1.3 |
| **Multiplexing** | No | Yes | Yes |
| **Streams** | No | Yes | Yes (independent) |
| **Header Compression** | No | HPACK | QPACK |
| **Server Push** | No | Yes | Yes |
| **Prioritization** | No | Yes | Yes |
| **HOL Blocking** | Yes (HTTP) | Yes (TCP) | No |
| **Connection Setup** | 3 RTT | 3 RTT | 1 RTT (0-RTT) |
| **Connection Migration** | No | No | Yes |
| **Max Requests/Conn** | 1 (or pipelining) | Unlimited | Unlimited |

## 14.2 Performance Metrics

### 14.2.1 - Page Load Time

**Test setup:**
- 1 HTML (10 KB)
- 50 images (100 KB each)
- RTT: 100ms
- Bandwidth: 10 Mbps

```
HTTP/1.1 (6 connections):
├─ Connection setup: 6 × 100ms = 600ms
├─ Sequential rounds: 9 rounds × 100ms = 900ms
├─ Data transfer: 5000 KB / 10 Mbps = 4000ms
└─ Total: 5.5 seconds

HTTP/2 (1 connection, multiplexed):
├─ Connection setup: 100ms
├─ Multiplexed streams: 100ms
├─ Data transfer: 5000 KB / 10 Mbps = 4000ms
└─ Total: 4.2 seconds (24% faster)

HTTP/3 (1 connection, 0-RTT):
├─ Connection setup: 0ms (0-RTT)
├─ Multiplexed streams: 100ms
├─ Data transfer: 5000 KB / 10 Mbps = 4000ms
└─ Total: 4.1 seconds (25% faster)

With 1% packet loss:
HTTP/1.1: 6.0 seconds
HTTP/2: 6.5 seconds (TCP HOL!)
HTTP/3: 4.5 seconds (no HOL!)
```

### 14.2.2 - Connection Overhead

```
HTTP/1.1: 6 TCP connections = 6 × 3-way handshake
HTTP/2: 1 TCP connection = 1 × 3-way handshake
HTTP/3: 1 QUIC connection = 0-1 RTT

Bandwidth saved:
HTTP/2 vs HTTP/1.1: ~5 TCP handshakes
HTTP/3 vs HTTP/2: ~2 RTTs
```

## 14.3 Quando Usare Quale Versione

### 14.3.1 - HTTP/1.1

**✅ Usa quando:**
- Legacy systems
- Debugging (text-based readable)
- Proxy/middleware non compatibili HTTP/2
- Risorse molto grandi (singolo stream full-speed)

**Esempio:**
```bash
# Debugging semplice
curl -v http://example.com

# Proxy HTTP/1.1
export http_proxy=http://proxy.company.com:8080
curl http://api.example.com
```

### 14.3.2 - HTTP/2

**✅ Usa quando:**
- Molte risorse piccole (images, CSS, JS)
- Server push utile
- Compatibilità universale richiesta
- Firewall permette solo TCP/443

**Esempio - Nginx:**
```nginx
server {
    listen 443 ssl http2;
    
    # Optimize for many small resources
    http2_max_concurrent_streams 128;
    http2_push /css/main.css;
    http2_push /js/app.js;
}
```

### 14.3.3 - HTTP/3

**✅ Usa quando:**
- Mobile users (connection migration)
- High latency networks
- Packet loss networks
- Real-time applications
- Modern infrastructure

**Esempio - Nginx:**
```nginx
server {
    listen 443 quic reuseport;
    listen 443 ssl http2;  # Fallback
    
    add_header Alt-Svc 'h3=":443"; ma=86400';
    
    # Optimize for mobile
    ssl_early_data on;
    quic_retry on;
}
```

## 14.4 Header Comparison

### 14.4.1 - Request Headers

**HTTP/1.1:**
```http
GET /index.html HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0...
Accept: text/html,application/xhtml+xml
Accept-Language: en-US,en;q=0.9
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cookie: session=abc123; user=john
Cache-Control: no-cache
```
**Size:** ~500 bytes (uncompressed, text)

**HTTP/2:**
```
:method: GET
:path: /index.html
:scheme: https
:authority: example.com
user-agent: Mozilla/5.0...
accept: text/html,application/xhtml+xml
accept-language: en-US,en;q=0.9
accept-encoding: gzip, deflate, br
cookie: session=abc123; user=john
cache-control: no-cache
```
**Size:** ~50 bytes (HPACK compressed, binary)

**HTTP/3:**
```
:method: GET
:path: /index.html
:scheme: https
:authority: example.com
[Other headers QPACK compressed]
```
**Size:** ~40 bytes (QPACK compressed, binary)

**Compression ratio:** HTTP/2 & HTTP/3 ~90% smaller!

## 14.5 Connection Management

### 14.5.1 - HTTP/1.1

```
Client                    Server
  │                         │
  ├──── Connection 1 ───────┤
  │  GET /page.html         │
  │  Response               │
  │                         │
  ├──── Connection 2 ───────┤
  │  GET /style.css         │
  │  Response               │
  │                         │
  ├──── Connection 3 ───────┤
  │  GET /script.js         │
  │  Response               │
  │                         │
  └─────────────────────────┘
  
Max: 6 concurrent connections per domain
```

### 14.5.2 - HTTP/2

```
Client                    Server
  │                         │
  ├──── Single Connection ──┤
  │                         │
  │  Stream 1: GET /page    │
  │  Stream 3: GET /css     │
  │  Stream 5: GET /js      │
  │                         │
  │  Interleaved responses  │
  │  on same connection     │
  │                         │
  └─────────────────────────┘

Unlimited streams over 1 connection
```

### 14.5.3 - HTTP/3

```
Client                    Server
  │                         │
  ├──── QUIC Connection ────┤
  │  (Connection ID: xyz)   │
  │                         │
  │  Stream 1, 3, 5, 7...   │
  │  Independent streams    │
  │  (no TCP HOL)           │
  │                         │
WiFi disconnects, reconnects 4G
  │                         │
  ├──── Same Connection ────┤
  │  (Connection ID: xyz)   │
  │  Streams continue!      │
  │                         │
  └─────────────────────────┘

Connection survives network changes
```

## 14.6 Server Push Comparison

### 14.6.1 - HTTP/1.1 (No Push)

```html
<!-- Client requests -->
GET /index.html

<!-- Server responds -->
<html>
  <link rel="stylesheet" href="/style.css">
  <script src="/app.js"></script>
</html>

<!-- Client parses HTML, then requests -->
GET /style.css
GET /app.js

Total: 3 round-trips
```

### 14.6.2 - HTTP/2 (Server Push)

```
Client: GET /index.html

Server:
  PUSH_PROMISE /style.css
  PUSH_PROMISE /app.js
  Response /index.html
  Response /style.css (pushed)
  Response /app.js (pushed)

Total: 1 round-trip (3x faster!)
```

**Nginx config:**
```nginx
location = /index.html {
    http2_push /style.css;
    http2_push /app.js;
}
```

### 14.6.3 - HTTP/3 (Early Hints + Push)

```
Client: GET /index.html

Server (immediately):
  103 Early Hints
  Link: </style.css>; rel=preload; as=style
  Link: </app.js>; rel=preload; as=script

Client: Starts downloading in parallel

Server:
  200 OK
  Response /index.html

Total: Parallel downloads (fastest!)
```

## 14.7 Migration Strategy

### 14.7.1 - Gradual Rollout

```
Phase 1: HTTP/1.1 only
└─ All users on HTTP/1.1

Phase 2: HTTP/1.1 + HTTP/2
├─ Modern browsers: HTTP/2
└─ Legacy clients: HTTP/1.1

Phase 3: HTTP/1.1 + HTTP/2 + HTTP/3
├─ Modern browsers: HTTP/3
├─ Medium browsers: HTTP/2
└─ Legacy clients: HTTP/1.1
```

### 14.7.2 - Nginx Configuration

```nginx
http {
    server {
        listen 80;
        listen 443 ssl http2;       # HTTP/2
        listen 443 quic reuseport;  # HTTP/3
        
        server_name example.com;
        
        # SSL/TLS
        ssl_certificate /path/to/cert.pem;
        ssl_certificate_key /path/to/key.pem;
        ssl_protocols TLSv1.2 TLSv1.3;
        
        # HTTP/3 discovery
        add_header Alt-Svc 'h3=":443"; ma=86400';
        
        # Redirect HTTP to HTTPS
        if ($scheme = http) {
            return 301 https://$server_name$request_uri;
        }
        
        location / {
            root /var/www/html;
            
            # HTTP/2 push
            http2_push /css/main.css;
            http2_push /js/app.js;
        }
    }
}
```

## 14.8 Debugging Comparison

### 14.8.1 - HTTP/1.1 (Easy)

```bash
# Readable text protocol
telnet example.com 80

GET /index.html HTTP/1.1
Host: example.com

HTTP/1.1 200 OK
Content-Type: text/html
...
```

### 14.8.2 - HTTP/2 (Medium)

```bash
# Binary protocol, need special tools
curl --http2 -v https://example.com

# Chrome DevTools
Network → Protocol column → "h2"

# Wireshark filter
http2
```

### 14.8.3 - HTTP/3 (Hard)

```bash
# QUIC encrypted, complex debugging
curl --http3 -v https://example.com

# Chrome DevTools
chrome://webrtc-internals/
chrome://net-internals/#quic

# Wireshark (limited, encryption)
quic
```

## 14.9 Real-World Examples

### 14.9.1 - E-commerce Site

**Requirements:**
- 100+ product images
- Real-time inventory updates
- Mobile users
- Global CDN

**Best choice: HTTP/3**
```nginx
server {
    listen 443 quic reuseport;
    listen 443 ssl http2;
    
    # Product images (multiplexed)
    location /images/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API (low latency)
    location /api/ {
        proxy_pass http://backend;
        add_header Alt-Svc 'h3=":443"; ma=86400';
    }
}
```

### 14.9.2 - API Server

**Requirements:**
- JSON responses
- Webhook delivery
- High throughput

**Best choice: HTTP/2 (wide compatibility)**
```javascript
// Express.js HTTP/2
const express = require('express');
const http2 = require('http2');

const app = express();

app.get('/api/data', (req, res) => {
  res.json({ message: 'Hello HTTP/2' });
});

http2.createSecureServer(options, app).listen(443);
```

### 14.9.3 - Static Site

**Requirements:**
- Blog posts (Markdown)
- Few images
- Simple hosting

**Choice: HTTP/1.1 sufficient**
```nginx
server {
    listen 80;
    server_name blog.example.com;
    
    location / {
        root /var/www/blog;
        index index.html;
    }
}
```

## 14.10 Performance Tuning

### 14.10.1 - HTTP/1.1 Optimization

```nginx
# Multiple connections
keepalive_timeout 65;
keepalive_requests 100;

# Compression
gzip on;
gzip_types text/plain text/css application/json;

# Caching
location ~* \.(jpg|png|css|js)$ {
    expires 1y;
}
```

### 14.10.2 - HTTP/2 Optimization

```nginx
# Stream settings
http2_max_concurrent_streams 128;
http2_max_field_size 16k;

# Push critical resources
http2_push_preload on;

# Single domain (no sharding)
server_name example.com;  # Not www.example.com
```

### 14.10.3 - HTTP/3 Optimization

```nginx
# QUIC settings
quic_gso on;
quic_retry on;

# 0-RTT
ssl_early_data on;

# Connection migration
# (automatic in QUIC)
```

---

**Capitolo 14 completato!**

Prossimo: **Capitolo 15 - Vulnerabilità HTTP**
