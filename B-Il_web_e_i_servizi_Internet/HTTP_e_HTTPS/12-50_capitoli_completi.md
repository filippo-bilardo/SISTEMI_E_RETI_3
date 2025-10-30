# Guida Completa HTTP/HTTPS - Capitoli 12-50

## PARTE 4: VERSIONI DEL PROTOCOLLO

# 12. HTTP/2

## 12.1 Introduzione
- Multiplexing (stream multipli su stessa connessione)
- Server Push
- Header compression (HPACK)
- Binary protocol
- Stream prioritization

**Esempio Nginx HTTP/2:**
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
}
```

# 13. HTTP/3 e QUIC

## 13.1 Caratteristiche
- Basato su QUIC (UDP)
- 0-RTT connection establishment
- Migliore performance su connessioni instabili
- No head-of-line blocking

# 14. Confronto Versioni HTTP

| Feature | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---------|----------|--------|--------|
| Protocol | Text | Binary | Binary |
| Transport | TCP | TCP | QUIC/UDP |
| Multiplexing | No | Yes | Yes |
| Header Compression | No | HPACK | QPACK |
| Server Push | No | Yes | Yes |

---

## PARTE 5: HTTPS E SICUREZZA

# 15. Sicurezza HTTP (approfondimento)

## 15.1 Vulnerabilità Comuni
- XSS (Cross-Site Scripting)
- CSRF (Cross-Site Request Forgery)
- SQL Injection
- Man-in-the-Middle
- Session Hijacking

## 15.2 Protezioni
```javascript
// Security headers
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"]
    }
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true
  }
}));
```

# 16. Certificati e PKI

## 16.1 Public Key Infrastructure
- Root CA
- Intermediate CA
- End-entity certificates
- Certificate chain validation
- CRL e OCSP

---

## PARTE 6: REST E API

# 17. REST API Design

## 17.1 Principi REST
- Client-Server
- Stateless
- Cacheable
- Layered System
- Uniform Interface

## 17.2 Best Practices
```http
GET    /api/users          # List users
POST   /api/users          # Create user
GET    /api/users/123      # Get user 123
PUT    /api/users/123      # Update user 123
DELETE /api/users/123      # Delete user 123
PATCH  /api/users/123      # Partial update
```

## 17.3 Versioning
```http
# URL versioning
GET /api/v1/users

# Header versioning
GET /api/users
Accept: application/vnd.myapi.v1+json

# Query parameter
GET /api/users?version=1
```

# 18. GraphQL vs REST

## 18.1 Confronto
**REST:** Multiple endpoints, over-fetching/under-fetching
**GraphQL:** Single endpoint, precise data fetching

```graphql
query {
  user(id: 123) {
    name
    email
    posts {
      title
    }
  }
}
```

# 19. API Documentation (OpenAPI/Swagger)

## 19.1 OpenAPI Spec
```yaml
openapi: 3.0.0
info:
  title: My API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List users
      responses:
        '200':
          description: Success
```

# 20. Rate Limiting e Throttling

## 20.1 Implementazione
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 min
  max: 100, // max 100 requests per window
  standardHeaders: true,
  legacyHeaders: false
});

app.use('/api/', limiter);
```

---

## PARTE 7: PERFORMANCE

# 21. Compressione HTTP

## 21.1 Algoritmi
- gzip (~70% compression)
- Brotli (~75% compression)
- deflate

```nginx
gzip on;
gzip_comp_level 6;
gzip_types text/plain text/css application/json;
```

# 22. Connection Management

## 22.1 Keep-Alive
```http
Connection: keep-alive
Keep-Alive: timeout=5, max=100
```

## 22.2 Connection Pooling
```javascript
const http = require('http');
const agent = new http.Agent({
  keepAlive: true,
  maxSockets: 50
});
```

# 23. CDN e Edge Computing

## 23.1 Content Delivery Network
- Edge locations
- Cache distribuzione globale
- DDoS protection
- SSL/TLS termination

# 24. Lazy Loading e Pagination

## 24.1 Pagination
```http
GET /api/users?page=2&limit=20

Response:
{
  "data": [...],
  "page": 2,
  "limit": 20,
  "total": 1000,
  "totalPages": 50
}
```

# 25. WebSockets

## 25.1 Upgrade Connection
```http
GET /chat HTTP/1.1
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==

→ HTTP/1.1 101 Switching Protocols
  Upgrade: websocket
  Connection: Upgrade
```

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', ws => {
  ws.on('message', message => {
    console.log('received: %s', message);
  });
  
  ws.send('Hello!');
});
```

---

## PARTE 8: TESTING

# 26. Testing API HTTP

## 26.1 Tools
- curl
- Postman
- HTTPie
- Jest + Supertest

```javascript
const request = require('supertest');
const app = require('./app');

describe('GET /api/users', () => {
  it('responds with json', async () => {
    const response = await request(app)
      .get('/api/users')
      .expect('Content-Type', /json/)
      .expect(200);
    
    expect(response.body).toHaveLength(10);
  });
});
```

# 27. Load Testing

## 27.1 Tools
- Apache Bench (ab)
- wrk
- Artillery
- k6

```bash
# Apache Bench
ab -n 1000 -c 10 https://example.com/

# wrk
wrk -t12 -c400 -d30s https://example.com/
```

# 28. Monitoring e Logging

## 28.1 Logging
```javascript
const morgan = require('morgan');
app.use(morgan('combined'));

// Custom format
morgan(':method :url :status :response-time ms');
```

## 28.2 Metrics
- Response time
- Throughput (req/sec)
- Error rate
- Cache hit ratio

# 29. Debugging HTTP

## 29.1 Browser DevTools
- Network tab
- Headers inspection
- Timing waterfall
- WebSocket frames

## 29.2 Proxy Tools
- Charles Proxy
- Fiddler
- mitmproxy

# 30. Security Testing

## 30.1 Tools
- OWASP ZAP
- Burp Suite
- nmap
- SSL Labs

---

## PARTE 9: APPLICAZIONI AVANZATE

# 31. Server-Sent Events (SSE)

```javascript
app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  
  setInterval(() => {
    res.write(`data: ${JSON.stringify({ time: Date.now() })}\n\n`);
  }, 1000);
});
```

```javascript
// Client
const eventSource = new EventSource('/events');
eventSource.onmessage = (event) => {
  console.log(JSON.parse(event.data));
};
```

# 32. Long Polling

```javascript
app.get('/poll', async (req, res) => {
  const data = await waitForData(30000); // Wait max 30s
  res.json(data);
});
```

# 33. Microservices HTTP

## 33.1 Service Communication
- REST APIs
- Service discovery
- Load balancing
- Circuit breaker

# 34. API Gateway

## 33.1 Features
- Routing
- Authentication
- Rate limiting
- Request transformation
- Response caching

# 35. CORS Avanzato

```javascript
app.use(cors({
  origin: (origin, callback) => {
    const whitelist = ['https://example.com'];
    if (whitelist.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

# 36. Progressive Web Apps (PWA)

## 36.1 Service Worker
```javascript
// sw.js
self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

## 36.2 Manifest
```json
{
  "name": "My PWA",
  "short_name": "PWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000"
}
```

# 37. HTTP Streaming

## 37.1 Chunked Transfer
```javascript
app.get('/stream', (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/plain',
    'Transfer-Encoding': 'chunked'
  });
  
  let count = 0;
  const interval = setInterval(() => {
    res.write(`Chunk ${count++}\n`);
    if (count >= 10) {
      clearInterval(interval);
      res.end();
    }
  }, 100);
});
```

# 38. Content Negotiation

```http
GET /resource HTTP/1.1
Accept: application/json, application/xml;q=0.9

→ HTTP/1.1 200 OK
  Content-Type: application/json
```

```javascript
app.get('/data', (req, res) => {
  res.format({
    'application/json': () => res.json({ data: 'value' }),
    'application/xml': () => res.send('<data>value</data>'),
    'text/plain': () => res.send('value')
  });
});
```

# 39. Idempotency Keys

```javascript
const idempotencyStore = new Map();

app.post('/payment', (req, res) => {
  const idempotencyKey = req.get('Idempotency-Key');
  
  if (idempotencyStore.has(idempotencyKey)) {
    return res.json(idempotencyStore.get(idempotencyKey));
  }
  
  const result = processPayment(req.body);
  idempotencyStore.set(idempotencyKey, result);
  
  res.json(result);
});
```

# 40. Circuit Breaker Pattern

```javascript
const CircuitBreaker = require('opossum');

const options = {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000
};

const breaker = new CircuitBreaker(asyncFunction, options);

app.get('/api/external', async (req, res) => {
  try {
    const result = await breaker.fire();
    res.json(result);
  } catch (err) {
    res.status(503).json({ error: 'Service unavailable' });
  }
});
```

---

## PARTE 10: STANDARD E SPECIFICHE

# 41. RFC HTTP Standards

- RFC 7230: Message Syntax and Routing
- RFC 7231: Semantics and Content
- RFC 7232: Conditional Requests
- RFC 7233: Range Requests
- RFC 7234: Caching
- RFC 7235: Authentication

# 42. HTTP Headers Reference

Vedere capitolo 7 per riferimento completo.

# 43. MIME Types

```
text/plain
text/html
text/css
text/javascript
application/json
application/xml
application/pdf
image/jpeg
image/png
image/gif
image/svg+xml
video/mp4
audio/mpeg
```

# 44. Status Code Best Practices

**Success:**
- 200 OK: GET success
- 201 Created: POST success
- 204 No Content: DELETE success

**Client Error:**
- 400 Bad Request: Validation error
- 401 Unauthorized: Auth required
- 403 Forbidden: No permission
- 404 Not Found: Resource missing
- 409 Conflict: Duplicate/version conflict
- 422 Unprocessable Entity: Semantic error

**Server Error:**
- 500 Internal Server Error
- 503 Service Unavailable

# 45. API Naming Conventions

```
✅ Good:
GET /api/users
GET /api/users/123/posts
POST /api/users/123/posts

❌ Bad:
GET /api/getUsers
GET /api/user_posts/123
POST /api/createUserPost
```

---

## PARTE 11: CASI D'USO

# 46. E-commerce API

```javascript
// Products
GET    /api/products
GET    /api/products/:id
POST   /api/products (admin)

// Cart
POST   /api/cart/items
GET    /api/cart
DELETE /api/cart/items/:id

// Orders
POST   /api/orders
GET    /api/orders
GET    /api/orders/:id
```

# 47. Social Media API

```javascript
// Posts
GET    /api/posts
POST   /api/posts
GET    /api/users/:id/posts

// Likes
POST   /api/posts/:id/likes
DELETE /api/posts/:id/likes

// Comments
GET    /api/posts/:id/comments
POST   /api/posts/:id/comments
```

# 48. Real-time Chat

```javascript
// WebSocket + REST hybrid
POST   /api/channels (create)
GET    /api/channels (list)
WS     /ws/chat/:channelId (messages)
```

# 49. File Upload

```javascript
const multer = require('multer');
const upload = multer({ dest: 'uploads/' });

app.post('/upload', upload.single('file'), (req, res) => {
  res.json({ 
    filename: req.file.filename,
    size: req.file.size,
    mimetype: req.file.mimetype
  });
});

// Multipart form-data
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary
```

# 50. Webhook Implementation

```javascript
// Webhook sender
async function sendWebhook(url, event, data) {
  await axios.post(url, {
    event,
    data,
    timestamp: Date.now()
  }, {
    headers: {
      'X-Webhook-Signature': generateSignature(data)
    }
  });
}

// Webhook receiver
app.post('/webhook', (req, res) => {
  const signature = req.get('X-Webhook-Signature');
  
  if (!verifySignature(req.body, signature)) {
    return res.status(401).json({ error: 'Invalid signature' });
  }
  
  processWebhook(req.body);
  res.status(200).send('OK');
});
```

---

## APPENDICI

### A. Glossario Termini HTTP

**Cache:** Memorizzazione temporanea risposte  
**CDN:** Content Delivery Network  
**CORS:** Cross-Origin Resource Sharing  
**CSRF:** Cross-Site Request Forgery  
**ETag:** Entity Tag (cache validation)  
**HSTS:** HTTP Strict Transport Security  
**JWT:** JSON Web Token  
**MIME:** Multipurpose Internet Mail Extensions  
**OAuth:** Open Authorization  
**REST:** Representational State Transfer  
**TLS:** Transport Layer Security  
**XSS:** Cross-Site Scripting  

### B. Comandi Curl Utili

```bash
# GET request
curl https://api.example.com/users

# POST JSON
curl -X POST https://api.example.com/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Mario","email":"mario@example.com"}'

# With authentication
curl -H "Authorization: Bearer TOKEN" \
  https://api.example.com/protected

# Save response to file
curl -o output.json https://api.example.com/data

# Follow redirects
curl -L https://example.com

# Show headers
curl -I https://example.com

# Verbose
curl -v https://example.com
```

### C. Nginx Configuration Complete

```nginx
http {
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json;
    
    # SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        ssl_certificate /path/to/cert.pem;
        ssl_certificate_key /path/to/key.pem;
        
        # Security headers
        add_header Strict-Transport-Security "max-age=31536000";
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        
        # Reverse proxy
        location /api/ {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Static files
        location /static/ {
            root /var/www;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### D. Express.js App Complete

```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('combined'));
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});
app.use('/api/', limiter);

// Routes
app.get('/api/users', async (req, res) => {
  const users = await db.users.findAll();
  res.json(users);
});

app.post('/api/users', async (req, res) => {
  const user = await db.users.create(req.body);
  res.status(201).json(user);
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

### E. HTTP Status Codes Reference

**1xx Informational:**
- 100 Continue
- 101 Switching Protocols

**2xx Success:**
- 200 OK
- 201 Created
- 204 No Content
- 206 Partial Content

**3xx Redirection:**
- 301 Moved Permanently
- 302 Found
- 304 Not Modified
- 307 Temporary Redirect

**4xx Client Error:**
- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 404 Not Found
- 409 Conflict
- 429 Too Many Requests

**5xx Server Error:**
- 500 Internal Server Error
- 502 Bad Gateway
- 503 Service Unavailable
- 504 Gateway Timeout

### F. Risorse Aggiuntive

**Documentazione:**
- MDN Web Docs: https://developer.mozilla.org
- RFC HTTP: https://www.rfc-editor.org
- OWASP: https://owasp.org

**Tools:**
- Postman: https://www.postman.com
- curl: https://curl.se
- SSL Labs: https://www.ssllabs.com

**Libri:**
- "HTTP: The Definitive Guide" - O'Reilly
- "RESTful Web APIs" - O'Reilly
- "High Performance Browser Networking" - O'Reilly

---

**GUIDA COMPLETA HTTP/HTTPS - FINE**

**Autore:** Guida didattica per studenti  
**Data:** Ottobre 2025  
**Versione:** 1.0  
**Capitoli totali:** 50 + 6 appendici
