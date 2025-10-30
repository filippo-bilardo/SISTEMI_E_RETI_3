# 13. HTTP/3 e QUIC

## 13.1 Introduzione a HTTP/3

HTTP/3 è la terza major version del protocollo HTTP, standardizzato nel 2022 (RFC 9114). Rappresenta un cambio radicale: **abbandona TCP** in favore di **QUIC** (Quick UDP Internet Connections).

### 13.1.1 - Perché HTTP/3?

**Problemi HTTP/2 (su TCP):**
- ❌ **TCP Head-of-Line Blocking:** Un pacchetto perso blocca tutti gli stream
- ❌ **Slow Start:** Ogni connessione riparte da zero
- ❌ **Handshake latency:** TCP + TLS = 2 round-trips
- ❌ **Connection migration:** IP change = nuova connessione

**Soluzioni HTTP/3 (su QUIC/UDP):**
- ✅ **No HOL blocking:** Stream indipendenti
- ✅ **0-RTT connection:** Riprende connessioni precedenti
- ✅ **Connection migration:** Sopravvive a cambio IP
- ✅ **Built-in encryption:** TLS 1.3 integrato

### 13.1.2 - Stack Comparison

```
HTTP/1.1          HTTP/2           HTTP/3
┌──────────┐      ┌──────────┐     ┌──────────┐
│  HTTP/1.1│      │  HTTP/2  │     │  HTTP/3  │
├──────────┤      ├──────────┤     ├──────────┤
│   TLS    │      │   TLS    │     │          │
├──────────┤      ├──────────┤     │   QUIC   │
│   TCP    │      │   TCP    │     │ (TLS 1.3)│
├──────────┤      ├──────────┤     ├──────────┤
│    IP    │      │    IP    │     │   UDP    │
└──────────┘      └──────────┘     ├──────────┤
                                   │    IP    │
                                   └──────────┘
```

## 13.2 QUIC Protocol

### 13.2.1 - Caratteristiche Chiave

**Transport Layer su UDP:**
- Implementa affidabilità sopra UDP
- Multiplexing nativo
- Flow control per stream
- Congestion control

**Encryption Built-in:**
- TLS 1.3 integrato (sempre criptato)
- Header protection (anti-middlebox interference)
- Forward secrecy

**Connection ID:**
- Identificatore connessione indipendente da IP/porta
- Sopravvive a network change (WiFi → 4G)

### 13.2.2 - QUIC Packet

```
QUIC Packet:
┌─────────────────────────────────────────┐
│ Header                                  │
│ ├─ Header Form (1 bit)                  │
│ ├─ Connection ID (variable)             │
│ ├─ Packet Number (variable)             │
│ └─ Version (32 bits)                    │
├─────────────────────────────────────────┤
│ Payload (encrypted)                     │
│ ├─ STREAM frames                        │
│ ├─ ACK frames                           │
│ └─ CRYPTO frames                        │
└─────────────────────────────────────────┘
```

## 13.3 Zero Round-Trip Time (0-RTT)

### 13.3.1 - Connection Establishment

**HTTP/2 over TCP+TLS (3 RTTs):**
```
Client                          Server
  │                               │
  ├─── TCP SYN ──────────────────>│  RTT 1
  │<──── TCP SYN-ACK ─────────────┤
  ├─── TCP ACK ──────────────────>│
  │                               │
  ├─── TLS ClientHello ──────────>│  RTT 2
  │<──── TLS ServerHello ─────────┤
  ├─── TLS Finished ─────────────>│  RTT 3
  │<──── TLS Finished ────────────┤
  │                               │
  ├─── HTTP Request ─────────────>│  RTT 4
  │<──── HTTP Response ───────────┤
```

**HTTP/3 over QUIC (1 RTT, or 0-RTT):**
```
Client                          Server
  │                               │
  ├─── QUIC Initial ─────────────>│  RTT 1
  │    (ClientHello + HTTP req)   │
  │<──── QUIC Handshake ──────────┤
  │     (ServerHello + HTTP res)  │
  │                               │
  ├─── QUIC 1-RTT ───────────────>│
  │<──── Data ────────────────────┤

With 0-RTT resumption:
  │                               │
  ├─── Early Data ───────────────>│  0-RTT!
  │    (HTTP request immediately) │
  │<──── Response ────────────────┤
```

### 13.3.2 - 0-RTT Risks

**⚠️ Replay Attacks:**
```javascript
// 0-RTT request can be replayed by attacker
POST /api/transfer HTTP/3
Content-Type: application/json

{
  "from": "account1",
  "to": "account2",
  "amount": 1000
}

// Attacker intercepts and replays → multiple transfers!
```

**✅ Mitigation:**
- Use 0-RTT only for **idempotent** operations (GET, HEAD, OPTIONS)
- Implement **replay protection** server-side
- Use **nonce** or **timestamp** validation

## 13.4 No Head-of-Line Blocking

### 13.4.1 - TCP HOL Problem

**HTTP/2 over TCP:**
```
Stream 1: [Data1][Data2][LOST][Data4]
Stream 3: [Data1][Data2][Data3][Data4]
                   ↑
          Packet loss blocks ALL streams
          until retransmission completes
```

**HTTP/3 over QUIC:**
```
Stream 1: [Data1][Data2][LOST][Data4]
                         ↑
Stream 3: [Data1][Data2][Data3][Data4]
          ↑ Stream 3 continues independently!
```

### 13.4.2 - Impact

**High packet loss scenario (1% loss):**
```
HTTP/2 over TCP: 50% throughput reduction
HTTP/3 over QUIC: 10% throughput reduction

Improvement: 5x better!
```

## 13.5 Connection Migration

### 13.5.1 - Problem

**TCP connections tied to 4-tuple:**
```
(Source IP, Source Port, Dest IP, Dest Port)

WiFi:     192.168.1.10:54321 → 1.2.3.4:443
↓ Switch to 4G
4G:       10.0.0.5:54321 → 1.2.3.4:443
          ↑ New connection required! :(
```

### 13.5.2 - QUIC Solution

**Connection ID persists:**
```
WiFi:     Connection ID: abc123
          192.168.1.10:54321 → 1.2.3.4:443
↓ Switch to 4G
4G:       Connection ID: abc123 (same!)
          10.0.0.5:12345 → 1.2.3.4:443
          ↑ Connection continues! :)
```

**Use cases:**
- Mobile users switching WiFi ↔ 4G/5G
- NAT rebinding
- Load balancer changes

## 13.6 Implementazione Server

### 13.6.1 - Nginx HTTP/3

**Nginx 1.25+ con QUIC support:**
```nginx
http {
    # HTTP/3 settings
    quic_gso on;
    quic_retry on;
    
    # Connection ID
    ssl_early_data on;
    
    server {
        listen 443 quic reuseport;
        listen 443 ssl;  # Fallback HTTP/2
        
        server_name example.com;
        
        ssl_certificate /path/to/cert.pem;
        ssl_certificate_key /path/to/key.pem;
        
        ssl_protocols TLSv1.3;
        
        # Add Alt-Svc header for HTTP/3 discovery
        add_header Alt-Svc 'h3=":443"; ma=86400';
        
        location / {
            root /var/www/html;
        }
    }
}
```

### 13.6.2 - Node.js con HTTP/3

**Using @fails-components/webtransport:**
```javascript
const { Http3Server } = require('@fails-components/webtransport');
const fs = require('fs');

const server = new Http3Server({
  port: 443,
  host: '0.0.0.0',
  secret: 'mysecret',
  cert: fs.readFileSync('cert.pem'),
  privKey: fs.readFileSync('key.pem')
});

server.startServer();

server.sessionStream('/echo').then(stream => {
  stream.on('data', data => {
    console.log('Received:', data.toString());
    stream.write(data);  // Echo back
  });
});

console.log('HTTP/3 server running on port 443');
```

### 13.6.3 - Cloudflare Workers (HTTP/3)

Cloudflare enables HTTP/3 automatically:

```javascript
// worker.js
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  // HTTP/3 automatically used if client supports it
  
  const protocol = request.cf?.httpProtocol || 'unknown';
  
  return new Response(JSON.stringify({
    message: 'Hello from Cloudflare',
    protocol: protocol,  // "HTTP/3" if client uses it
    country: request.cf?.country,
    colo: request.cf?.colo
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Alt-Svc': 'h3=":443"; ma=86400'
    }
  });
}
```

## 13.7 HTTP/3 Discovery

Client deve **scoprire** che server supporta HTTP/3.

### 13.7.1 - Alt-Svc Header

```http
HTTP/2 200 OK
Alt-Svc: h3=":443"; ma=86400
Content-Type: text/html

<!DOCTYPE html>...
```

**Significato:**
- `h3`: HTTP/3 available
- `:443`: Same port
- `ma=86400`: Max age 24 hours

### 13.7.2 - DNS HTTPS Record

```
example.com.  IN HTTPS 1 . alpn=h3,h2 ipv4hint=1.2.3.4
```

Client può scoprire HTTP/3 via DNS prima di connessione!

### 13.7.3 - Connection Flow

```
1. Client → Server (HTTP/1.1 or HTTP/2 over TCP)
   GET /index.html

2. Server → Client
   Alt-Svc: h3=":443"
   
3. Client → Server (HTTP/3 over QUIC/UDP)
   Subsequent requests use HTTP/3
```

## 13.8 Client HTTP/3

### 13.8.1 - curl HTTP/3

```bash
# Build curl with HTTP/3 support
# (requires ngtcp2 or quiche)

curl --http3 https://cloudflare.com

# Verbose
curl --http3 -v https://example.com

# Only HTTP/3
curl --http3-only https://example.com
```

### 13.8.2 - Chrome DevTools

**Enable HTTP/3:**
```
chrome://flags/#enable-quic
Enable QUIC protocol
Restart Chrome
```

**Verify:**
```
Network tab → Protocol column → "h3"
```

### 13.8.3 - Fetch API (JavaScript)

```javascript
// Browser automatically uses HTTP/3 if available
fetch('https://example.com/api/data')
  .then(response => {
    console.log('Protocol:', response.headers.get('cf-h3'));
    return response.json();
  })
  .then(data => console.log(data));
```

## 13.9 Performance Comparison

### 13.9.1 - Latency Comparison

**Page load time (50 resources, 100ms RTT, 1% packet loss):**

```
HTTP/1.1:   5.2 seconds
HTTP/2:     2.8 seconds (46% faster)
HTTP/3:     1.9 seconds (63% faster than HTTP/1.1)
                        (32% faster than HTTP/2)
```

### 13.9.2 - Mobile Performance

**WiFi → 4G handoff:**

```
HTTP/2: Connection drops → Reconnect (3 RTTs) → Resume
        Interruption: ~500ms

HTTP/3: Connection migrates → No interruption
        Interruption: ~0ms
```

### 13.9.3 - Real-World Results

**Cloudflare benchmarks:**
- **Desktop:** 3-5% faster than HTTP/2
- **Mobile:** 10-15% faster (connection migration)
- **High packet loss:** 30-50% faster

## 13.10 Challenges & Limitations

### 13.10.1 - UDP Blocking

**Problem:** Some networks/firewalls block UDP

**Solution:**
```nginx
# Nginx config with fallback
server {
    listen 443 quic;      # HTTP/3
    listen 443 ssl http2; # HTTP/2 fallback
    
    add_header Alt-Svc 'h3=":443"; ma=86400';
}
```

### 13.10.2 - CPU Usage

**QUIC overhead:**
- UDP + TLS + loss recovery in userspace
- Higher CPU than kernel TCP
- Improving with hardware offload

### 13.10.3 - Middlebox Issues

**NAT/Firewall:** May not understand QUIC
**Load Balancers:** Need Connection ID support
**DPI:** Deep packet inspection blocked by encryption

## 13.11 Future of HTTP/3

### 13.11.1 - Adoption

**Current (2024):**
- ✅ Cloudflare, Google, Facebook, Akamai
- ✅ Chrome, Firefox, Safari, Edge
- ✅ Nginx 1.25+, LiteSpeed, Caddy
- ⚠️  Apache (experimental)

**Percentage:**
- ~30% of websites support HTTP/3
- ~50% of Chrome traffic uses HTTP/3

### 13.11.2 - WebTransport

**Next evolution:** WebTransport API over HTTP/3

```javascript
// WebTransport (bidirectional streams over HTTP/3)
const transport = new WebTransport('https://example.com/wt');

await transport.ready;

// Send data
const stream = await transport.createBidirectionalStream();
const writer = stream.writable.getWriter();
await writer.write(new Uint8Array([1, 2, 3]));

// Receive data
const reader = stream.readable.getReader();
const { value, done } = await reader.read();
console.log('Received:', value);
```

**Use cases:**
- Real-time gaming
- Video conferencing
- Live streaming
- IoT

---

**Capitolo 13 completato!**

Prossimo: **Capitolo 14 - Confronto HTTP/1.1, HTTP/2, HTTP/3**
