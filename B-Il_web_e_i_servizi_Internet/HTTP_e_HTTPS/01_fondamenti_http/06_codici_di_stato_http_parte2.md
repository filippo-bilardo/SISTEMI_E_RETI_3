# 6. Codici di Stato HTTP (Parte 2)

## 6.6 Altri Codici 4xx - Client Error

### 6.6.1 - 406 Not Acceptable

**Significato:** Il server non può produrre una risposta nel formato richiesto.

**Uso:** Content negotiation fallita.

**Esempio:**
```http
GET /api/users/123 HTTP/1.1
Accept: application/xml

→ HTTP/1.1 406 Not Acceptable
  Content-Type: application/json
  
  {
    "error": "NOT_ACCEPTABLE",
    "message": "Server cannot produce response in requested format",
    "requested": "application/xml",
    "available": ["application/json"]
  }
```

**Linguaggio non disponibile:**
```http
GET /page.html HTTP/1.1
Accept-Language: ja

→ HTTP/1.1 406 Not Acceptable
  
  {
    "error": "LANGUAGE_NOT_AVAILABLE",
    "message": "Content not available in Japanese",
    "available_languages": ["en", "it", "es"]
  }
```

### 6.6.2 - 408 Request Timeout

**Significato:** Client ha impiegato troppo tempo per inviare la richiesta.

**Uso:** Client lento, connessione instabile.

**Esempio:**
```http
GET /api/data HTTP/1.1
Host: api.example.com
[client smette di inviare dati...]

→ HTTP/1.1 408 Request Timeout
  Connection: close
  
  {
    "error": "REQUEST_TIMEOUT",
    "message": "Client took too long to send the request"
  }
```

**Configurazione server timeout:**

**Nginx:**
```nginx
http {
    client_header_timeout 60s;  # Timeout header
    client_body_timeout 60s;    # Timeout body
}
```

**Apache:**
```apache
Timeout 60
RequestReadTimeout header=60 body=60
```

### 6.6.3 - 410 Gone

**Significato:** Risorsa esisteva ma è stata rimossa permanentemente.

**Differenza con 404:**
- **404**: Non trovata (potrebbe non essere mai esistita)
- **410**: Era presente, ora rimossa definitivamente

**Esempio:**
```http
GET /api/users/123 HTTP/1.1

→ HTTP/1.1 410 Gone
  Content-Type: application/json
  
  {
    "error": "RESOURCE_GONE",
    "message": "User account was deleted on 2025-10-15",
    "deleted_at": "2025-10-15T10:30:00Z",
    "reason": "User requested account deletion"
  }
```

**Caso d'uso: API deprecata**
```http
GET /api/v1/old-endpoint HTTP/1.1

→ HTTP/1.1 410 Gone
  
  {
    "error": "ENDPOINT_DEPRECATED",
    "message": "This endpoint was removed in API v2",
    "deprecated_since": "2025-01-01",
    "removed_on": "2025-06-01",
    "migration_guide": "https://api.example.com/docs/migration-v2"
  }
```

### 6.6.4 - 411 Length Required

**Significato:** Server richiede header `Content-Length`.

**Esempio:**
```http
POST /api/upload HTTP/1.1
Content-Type: application/octet-stream

[binary data without Content-Length]

→ HTTP/1.1 411 Length Required
  
  {
    "error": "LENGTH_REQUIRED",
    "message": "Content-Length header is required for this request"
  }
```

**Soluzione:**
```http
POST /api/upload HTTP/1.1
Content-Type: application/octet-stream
Content-Length: 1024

[1024 bytes of data]

→ HTTP/1.1 201 Created
```

### 6.6.5 - 412 Precondition Failed

**Significato:** Precondizione nella richiesta non soddisfatta.

**Uso:** Conditional requests con `If-Match`, `If-Unmodified-Since`, etc.

**Esempio: If-Match fallito**
```http
PUT /api/documents/123 HTTP/1.1
If-Match: "old-etag-xyz"
Content-Type: application/json

{"title": "Updated"}

→ HTTP/1.1 412 Precondition Failed
  ETag: "current-etag-abc"
  
  {
    "error": "PRECONDITION_FAILED",
    "message": "Resource has been modified since you retrieved it",
    "current_etag": "current-etag-abc",
    "provided_etag": "old-etag-xyz"
  }
```

**Esempio: If-Unmodified-Since**
```http
DELETE /api/files/456 HTTP/1.1
If-Unmodified-Since: Mon, 01 Oct 2025 12:00:00 GMT

→ HTTP/1.1 412 Precondition Failed
  Last-Modified: Wed, 30 Oct 2025 10:00:00 GMT
  
  {
    "error": "FILE_MODIFIED",
    "message": "File was modified after the specified date"
  }
```

### 6.6.6 - 413 Payload Too Large

**Significato:** Body della richiesta troppo grande.

**Esempio:**
```http
POST /api/upload HTTP/1.1
Content-Length: 52428800

[50MB file...]

→ HTTP/1.1 413 Payload Too Large
  Retry-After: 3600
  
  {
    "error": "PAYLOAD_TOO_LARGE",
    "message": "Request body exceeds maximum allowed size",
    "max_size": 10485760,
    "your_size": 52428800,
    "max_size_readable": "10 MB",
    "your_size_readable": "50 MB"
  }
```

**Configurazione limiti:**

**Nginx:**
```nginx
http {
    client_max_body_size 10M;
}

location /api/upload {
    client_max_body_size 100M;  # Override per endpoint specifico
}
```

**Express.js:**
```javascript
const express = require('express');
const app = express();

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
```

### 6.6.7 - 414 URI Too Long

**Significato:** URL troppo lungo.

**Esempio:**
```http
GET /api/search?keywords=word1+word2+word3+...+word1000&filters=... HTTP/1.1

→ HTTP/1.1 414 URI Too Long
  
  {
    "error": "URI_TOO_LONG",
    "message": "Request URI exceeds maximum allowed length",
    "max_length": 2048,
    "your_length": 5120,
    "suggestion": "Use POST with request body for complex queries"
  }
```

**Soluzione: Usa POST**
```http
POST /api/search HTTP/1.1
Content-Type: application/json

{
  "keywords": ["word1", "word2", ..., "word1000"],
  "filters": {...}
}

→ HTTP/1.1 200 OK
```

### 6.6.8 - 415 Unsupported Media Type

**Significato:** Formato del body non supportato.

**Esempio:**
```http
POST /api/users HTTP/1.1
Content-Type: application/xml

<?xml version="1.0"?>
<user>
  <name>Mario</name>
</user>

→ HTTP/1.1 415 Unsupported Media Type
  
  {
    "error": "UNSUPPORTED_MEDIA_TYPE",
    "message": "Server does not support the provided media type",
    "provided": "application/xml",
    "supported": ["application/json", "application/x-www-form-urlencoded"]
  }
```

**Missing Content-Type:**
```http
POST /api/users HTTP/1.1

{"name": "Mario"}

→ HTTP/1.1 415 Unsupported Media Type
  
  {
    "error": "MISSING_CONTENT_TYPE",
    "message": "Content-Type header is required"
  }
```

### 6.6.9 - 416 Range Not Satisfiable

**Significato:** Range richiesto non valido.

**Esempio:**
```http
GET /video.mp4 HTTP/1.1
Range: bytes=10000000-20000000

→ HTTP/1.1 416 Range Not Satisfiable
  Content-Range: bytes */5242880
  
  {
    "error": "RANGE_NOT_SATISFIABLE",
    "message": "Requested range is outside file boundaries",
    "file_size": 5242880,
    "requested_range": "10000000-20000000"
  }
```

**Range syntax error:**
```http
GET /file.zip HTTP/1.1
Range: bytes=invalid

→ HTTP/1.1 416 Range Not Satisfiable
  Content-Range: bytes */10485760
```

### 6.6.10 - 422 Unprocessable Entity

**Significato:** Richiesta sintatticamente corretta ma semanticamente errata.

**Uso:** Validazione business logic fallita.

**Differenza con 400:**
- **400**: Sintassi errata (JSON malformato)
- **422**: Sintassi OK, ma dati non validi semanticamente

**Esempio:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{
  "name": "Mario Rossi",
  "email": "mario@example.com",
  "age": -5,
  "birthdate": "2030-12-31"
}

→ HTTP/1.1 422 Unprocessable Entity
  Content-Type: application/json
  
  {
    "error": "VALIDATION_ERROR",
    "message": "Request contains invalid data",
    "errors": [
      {
        "field": "age",
        "message": "Age cannot be negative",
        "value": -5
      },
      {
        "field": "birthdate",
        "message": "Birthdate cannot be in the future",
        "value": "2030-12-31"
      }
    ]
  }
```

**Esempio 2: Business rule violated**
```http
POST /api/orders HTTP/1.1
Content-Type: application/json

{
  "product_id": 123,
  "quantity": 1000
}

→ HTTP/1.1 422 Unprocessable Entity
  
  {
    "error": "INSUFFICIENT_STOCK",
    "message": "Cannot create order: insufficient stock",
    "requested_quantity": 1000,
    "available_quantity": 50
  }
```

### 6.6.11 - 423 Locked (WebDAV)

**Significato:** Risorsa bloccata (lock attivo).

**Esempio:**
```http
PUT /documents/report.docx HTTP/1.1
Content-Type: application/vnd.openxmlformats

[document data]

→ HTTP/1.1 423 Locked
  
  {
    "error": "RESOURCE_LOCKED",
    "message": "Resource is currently locked by another user",
    "locked_by": "user@example.com",
    "locked_until": "2025-10-30T13:00:00Z"
  }
```

### 6.6.12 - 429 Too Many Requests (approfondimento)

**Rate Limiting Strategies:**

**1. Fixed Window**
```
0:00-0:59 → 100 richieste permesse
1:00-1:59 → 100 richieste permesse (reset)
...
```

**2. Sliding Window**
```
Ultimi 60 secondi → max 100 richieste
Calcolo continuo, non reset fisso
```

**3. Token Bucket**
```
Bucket: 100 tokens
Ogni richiesta: -1 token
Refill: +10 tokens/secondo
```

**Implementazione (Express.js + redis):**
```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');

const limiter = rateLimit({
  store: new RedisStore({
    client: redisClient
  }),
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 100, // 100 requests per hour
  message: {
    error: 'RATE_LIMIT_EXCEEDED',
    message: 'Too many requests from this IP'
  },
  standardHeaders: true, // X-RateLimit-* headers
  legacyHeaders: false
});

app.use('/api/', limiter);
```

**Headers standard:**
```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1698667200

# Dopo limite superato:
HTTP/1.1 429 Too Many Requests
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1698667200
Retry-After: 3600
```

## 6.7 Codici 5xx - Server Error

I codici **5xx** indicano che il server ha riscontrato un errore o è incapace di eseguire la richiesta.

### 6.7.1 - 500 Internal Server Error

**Significato:** Errore generico del server.

**Uso:** Eccezioni non gestite, errori imprevisti.

**Esempio:**
```http
GET /api/users/123 HTTP/1.1

→ HTTP/1.1 500 Internal Server Error
  Content-Type: application/json
  
  {
    "error": "INTERNAL_SERVER_ERROR",
    "message": "An unexpected error occurred",
    "request_id": "abc-123-xyz"
  }
```

**⚠️ NON esporre dettagli in produzione:**

```http
# ❌ SBAGLIATO (environment: production)
HTTP/1.1 500 Internal Server Error

{
  "error": "Database connection failed",
  "stack_trace": "Error at /home/app/db.js:42...",
  "sql_query": "SELECT * FROM users WHERE password='...'",
  "database_host": "db.internal.company.com"
}

# ✅ CORRETTO (environment: production)
HTTP/1.1 500 Internal Server Error

{
  "error": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "request_id": "abc-123-xyz",
  "support": "contact support@example.com with request_id"
}

# ✅ Log interno (non inviato al client):
[2025-10-30 12:00:00] ERROR: Database connection failed
  Request ID: abc-123-xyz
  User: user@example.com
  Endpoint: GET /api/users/123
  Error: Connection timeout to db.internal.company.com:5432
  Stack: Error at /home/app/db.js:42...
```

**Best practice:**
```javascript
app.get('/api/users/:id', async (req, res) => {
  try {
    const user = await db.users.findById(req.params.id);
    res.json(user);
  } catch (error) {
    // Log dettagliato (server-side)
    logger.error('Error fetching user', {
      userId: req.params.id,
      error: error.message,
      stack: error.stack,
      requestId: req.id
    });
    
    // Risposta generica (client-side)
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected error occurred',
      request_id: req.id
    });
  }
});
```

### 6.7.2 - 501 Not Implemented

**Significato:** Server non supporta la funzionalità richiesta.

**Uso:** Metodo HTTP non implementato, feature non ancora disponibile.

**Esempio:**
```http
TRACE /api/users HTTP/1.1

→ HTTP/1.1 501 Not Implemented
  
  {
    "error": "METHOD_NOT_IMPLEMENTED",
    "message": "TRACE method is not implemented on this server"
  }
```

**Feature non disponibile:**
```http
POST /api/v2/advanced-feature HTTP/1.1

→ HTTP/1.1 501 Not Implemented
  
  {
    "error": "FEATURE_NOT_IMPLEMENTED",
    "message": "This feature is not yet available",
    "planned_release": "2025-12-01"
  }
```

### 6.7.3 - 502 Bad Gateway

**Significato:** Server (come gateway/proxy) ha ricevuto risposta non valida da upstream.

**Uso:** Proxy/load balancer non riesce a comunicare con backend.

**Scenario:**
```
Client → Nginx (reverse proxy) → Backend Server
                                      ↓
                                   (crashed)
                                      
Client ← HTTP/1.1 502 Bad Gateway ← Nginx
```

**Esempio:**
```http
GET /api/users HTTP/1.1

→ HTTP/1.1 502 Bad Gateway
  Content-Type: application/json
  
  {
    "error": "BAD_GATEWAY",
    "message": "Unable to reach backend server",
    "proxy": "nginx-01",
    "upstream": "backend-server-03"
  }
```

**Nginx error page:**
```http
HTTP/1.1 502 Bad Gateway
Server: nginx/1.24.0

<html>
<head><title>502 Bad Gateway</title></head>
<body>
<h1>502 Bad Gateway</h1>
<p>nginx/1.24.0</p>
</body>
</html>
```

**Cause comuni:**
- Backend server down
- Backend server troppo lento (timeout)
- Risposta malformata da backend
- Errore di configurazione proxy

**Configurazione Nginx timeout:**
```nginx
location /api/ {
    proxy_pass http://backend;
    proxy_connect_timeout 5s;
    proxy_send_timeout 60s;
    proxy_read_timeout 60s;
}
```

### 6.7.4 - 503 Service Unavailable

**Significato:** Server temporaneamente non disponibile.

**Uso:** Manutenzione, sovraccarico, deployment.

**Headers importanti:**
- `Retry-After`: Quando riprovare

**Esempio: Manutenzione**
```http
GET /api/users HTTP/1.1

→ HTTP/1.1 503 Service Unavailable
  Retry-After: 3600
  Content-Type: application/json
  
  {
    "error": "SERVICE_UNAVAILABLE",
    "message": "Server is under maintenance",
    "retry_after": 3600,
    "retry_after_readable": "1 hour",
    "estimated_completion": "2025-10-30T13:00:00Z"
  }
```

**Esempio: Sovraccarico**
```http
GET /api/data HTTP/1.1

→ HTTP/1.1 503 Service Unavailable
  Retry-After: 120
  
  {
    "error": "SERVER_OVERLOADED",
    "message": "Server is temporarily overloaded",
    "retry_after": 120
  }
```

**Circuit Breaker Pattern:**
```javascript
const CircuitBreaker = require('opossum');

const options = {
  timeout: 3000,
  errorThresholdPercentage: 50,
  resetTimeout: 30000
};

const breaker = new CircuitBreaker(callExternalService, options);

breaker.fallback(() => ({
  status: 503,
  error: 'SERVICE_UNAVAILABLE',
  message: 'External service is temporarily unavailable'
}));

app.get('/api/external', async (req, res) => {
  try {
    const result = await breaker.fire(req.params);
    res.json(result);
  } catch (error) {
    res.status(503).json({
      error: 'SERVICE_UNAVAILABLE',
      message: 'Service temporarily unavailable'
    });
  }
});
```

**Nginx maintenance mode:**
```nginx
server {
    listen 80;
    server_name example.com;
    
    # Maintenance mode flag
    set $maintenance 0;
    
    if (-f /var/www/maintenance.flag) {
        set $maintenance 1;
    }
    
    if ($maintenance = 1) {
        return 503;
    }
    
    # Normal handling
    location / {
        proxy_pass http://backend;
    }
    
    # Custom 503 page
    error_page 503 /maintenance.html;
    location = /maintenance.html {
        root /var/www/html;
        internal;
    }
}
```

### 6.7.5 - 504 Gateway Timeout

**Significato:** Gateway/proxy non ha ricevuto risposta in tempo da upstream.

**Differenza con 502:**
- **502**: Risposta non valida/errore di comunicazione
- **504**: Nessuna risposta (timeout)

**Esempio:**
```http
GET /api/slow-operation HTTP/1.1

→ HTTP/1.1 504 Gateway Timeout
  Content-Type: application/json
  
  {
    "error": "GATEWAY_TIMEOUT",
    "message": "Upstream server did not respond in time",
    "timeout": 60,
    "proxy": "nginx-01"
  }
```

**Scenario:**
```
Client → Nginx → Backend (operazione lenta: 65 secondi)
         ↓
    timeout 60s
         ↓
Client ← 504 Gateway Timeout
```

**Configurazione timeout:**

**Nginx:**
```nginx
location /api/ {
    proxy_pass http://backend;
    proxy_read_timeout 60s;  # Timeout per leggere risposta
    proxy_connect_timeout 5s; # Timeout per connessione
}

location /api/slow/ {
    proxy_pass http://backend;
    proxy_read_timeout 300s;  # 5 minuti per operazioni lente
}
```

**Apache:**
```apache
<Proxy *>
    ProxyTimeout 60
</Proxy>

<Location /api/slow>
    ProxyTimeout 300
</Location>
```

### 6.7.6 - 505 HTTP Version Not Supported

**Significato:** Server non supporta la versione HTTP della richiesta.

**Esempio:**
```http
GET /api/users HTTP/3.0
Host: api.example.com

→ HTTP/1.1 505 HTTP Version Not Supported
  
  {
    "error": "HTTP_VERSION_NOT_SUPPORTED",
    "message": "HTTP/3.0 is not supported",
    "supported_versions": ["HTTP/1.0", "HTTP/1.1", "HTTP/2"]
  }
```

### 6.7.7 - 507 Insufficient Storage (WebDAV)

**Significato:** Server non ha spazio sufficiente per completare la richiesta.

**Esempio:**
```http
PUT /uploads/large-file.zip HTTP/1.1
Content-Length: 10737418240

→ HTTP/1.1 507 Insufficient Storage
  
  {
    "error": "INSUFFICIENT_STORAGE",
    "message": "Server does not have enough space",
    "available_space": 1073741824,
    "required_space": 10737418240
  }
```

### 6.7.8 - 511 Network Authentication Required

**Significato:** Client deve autenticarsi per accedere alla rete.

**Uso:** Captive portal (WiFi pubblico, hotel, aeroporto).

**Esempio:**
```http
GET http://www.example.com/ HTTP/1.1

→ HTTP/1.1 511 Network Authentication Required
  Content-Type: text/html
  
  <!DOCTYPE html>
  <html>
    <head><title>WiFi Login Required</title></head>
    <body>
      <h1>Please Log In</h1>
      <p>You need to log in to access the network.</p>
      <form action="/login" method="POST">
        <input type="text" name="username" placeholder="Username">
        <input type="password" name="password" placeholder="Password">
        <button type="submit">Log In</button>
      </form>
    </body>
  </html>
```

## 6.8 Best Practices per Status Codes

### 6.8.1 Scegliere il Codice Giusto

**✅ Do:**

```http
# Creazione riuscita
POST /api/users → 201 Created (non 200)

# Aggiornamento senza body
PUT /api/users/123 → 204 No Content (non 200 con body vuoto)

# Risorsa eliminata
DELETE /api/users/123 → 204 No Content (non 200)

# Autenticazione fallita
POST /api/login → 401 Unauthorized (non 403, non 400)

# Validazione fallita
POST /api/users → 422 Unprocessable Entity (non 400 generico)

# Rate limit
GET /api/data (troppi requests) → 429 Too Many Requests (non 403)

# Errore temporaneo server
GET /api/data → 503 Service Unavailable (non 500)
```

**❌ Don't:**

```http
# ❌ Usare 200 per errori
POST /api/login
→ HTTP/1.1 200 OK
  {"success": false, "error": "Invalid credentials"}
# ✅ Dovrebbe essere 401

# ❌ Usare 404 per errori business logic
POST /api/transfer (saldo insufficiente)
→ HTTP/1.1 404 Not Found
# ✅ Dovrebbe essere 422 o 409

# ❌ Usare 500 per errori del client
POST /api/users (email duplicata)
→ HTTP/1.1 500 Internal Server Error
# ✅ Dovrebbe essere 409 Conflict

# ❌ Non restituire status code
POST /api/data
→ (nessuna risposta o connessione chiusa)
# ✅ Sempre inviare status code appropriato
```

### 6.8.2 Consistenza nelle Risposte di Errore

**Formato standard JSON:**
```json
{
  "error": "ERROR_CODE",
  "message": "Human readable message",
  "details": {},
  "timestamp": "2025-10-30T12:00:00Z",
  "path": "/api/users",
  "request_id": "abc-123-xyz"
}
```

**Esempi:**

```http
# 400 Bad Request
{
  "error": "VALIDATION_ERROR",
  "message": "Request validation failed",
  "details": {
    "fields": {
      "email": "Invalid email format",
      "age": "Must be positive number"
    }
  },
  "timestamp": "2025-10-30T12:00:00Z",
  "path": "/api/users",
  "request_id": "abc-123"
}

# 401 Unauthorized
{
  "error": "INVALID_TOKEN",
  "message": "Authentication token is invalid or expired",
  "timestamp": "2025-10-30T12:00:00Z",
  "path": "/api/private",
  "request_id": "xyz-789"
}

# 404 Not Found
{
  "error": "RESOURCE_NOT_FOUND",
  "message": "User with ID 999 not found",
  "details": {
    "resource": "user",
    "id": 999
  },
  "timestamp": "2025-10-30T12:00:00Z",
  "path": "/api/users/999",
  "request_id": "def-456"
}

# 500 Internal Server Error
{
  "error": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred",
  "request_id": "ghi-789",
  "support": "Contact support@example.com with request_id"
}
```

### 6.8.3 Headers Importanti

**Location (201, 3xx):**
```http
HTTP/1.1 201 Created
Location: /api/users/123
```

**Retry-After (429, 503):**
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60

# O con data
Retry-After: Wed, 30 Oct 2025 13:00:00 GMT
```

**WWW-Authenticate (401):**
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Bearer realm="API", error="invalid_token"
```

**Allow (405):**
```http
HTTP/1.1 405 Method Not Allowed
Allow: GET, POST, PUT
```

**Content-Range (206, 416):**
```http
HTTP/1.1 206 Partial Content
Content-Range: bytes 0-1023/5242880
```

### 6.8.4 Logging e Monitoring

**Log status codes per debugging:**

```javascript
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const log = {
      timestamp: new Date().toISOString(),
      method: req.method,
      path: req.path,
      status: res.statusCode,
      duration: duration,
      ip: req.ip,
      user_agent: req.get('user-agent'),
      request_id: req.id
    };
    
    // Log diverso per livello
    if (res.statusCode >= 500) {
      logger.error('Server Error', log);
    } else if (res.statusCode >= 400) {
      logger.warn('Client Error', log);
    } else {
      logger.info('Request', log);
    }
  });
  
  next();
});
```

**Metrics monitoring:**
```javascript
const prometheus = require('prom-client');

const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'path', 'status_code']
});

const httpRequestsTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'path', 'status_code']
});

app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    
    httpRequestDuration.labels(
      req.method,
      req.route?.path || req.path,
      res.statusCode
    ).observe(duration);
    
    httpRequestsTotal.labels(
      req.method,
      req.route?.path || req.path,
      res.statusCode
    ).inc();
  });
  
  next();
});
```

## 6.9 Tabella Completa Codici di Stato

### Status Codes Reference

| Code | Name | Category | Common Use |
|------|------|----------|------------|
| 100 | Continue | Info | Upload grandi file |
| 101 | Switching Protocols | Info | WebSocket upgrade |
| 200 | OK | Success | Richiesta riuscita |
| 201 | Created | Success | Risorsa creata |
| 202 | Accepted | Success | Job asincrono |
| 204 | No Content | Success | Successo senza body |
| 206 | Partial Content | Success | Range request |
| 301 | Moved Permanently | Redirect | Migrazione permanente |
| 302 | Found | Redirect | Redirect temporaneo |
| 303 | See Other | Redirect | POST-Redirect-GET |
| 304 | Not Modified | Redirect | Cache valida |
| 307 | Temporary Redirect | Redirect | Redirect temp (preserva metodo) |
| 308 | Permanent Redirect | Redirect | Redirect perm (preserva metodo) |
| 400 | Bad Request | Client Error | Richiesta malformata |
| 401 | Unauthorized | Client Error | Autenticazione richiesta |
| 403 | Forbidden | Client Error | Accesso negato |
| 404 | Not Found | Client Error | Risorsa non trovata |
| 405 | Method Not Allowed | Client Error | Metodo non permesso |
| 406 | Not Acceptable | Client Error | Formato non disponibile |
| 408 | Request Timeout | Client Error | Client troppo lento |
| 409 | Conflict | Client Error | Conflitto di stato |
| 410 | Gone | Client Error | Risorsa eliminata definitivamente |
| 411 | Length Required | Client Error | Content-Length mancante |
| 412 | Precondition Failed | Client Error | Conditional request fallita |
| 413 | Payload Too Large | Client Error | Body troppo grande |
| 414 | URI Too Long | Client Error | URL troppo lungo |
| 415 | Unsupported Media Type | Client Error | Content-Type non supportato |
| 416 | Range Not Satisfiable | Client Error | Range non valido |
| 422 | Unprocessable Entity | Client Error | Validazione fallita |
| 429 | Too Many Requests | Client Error | Rate limit |
| 500 | Internal Server Error | Server Error | Errore generico server |
| 501 | Not Implemented | Server Error | Funzionalità non implementata |
| 502 | Bad Gateway | Server Error | Proxy error |
| 503 | Service Unavailable | Server Error | Server temporaneamente offline |
| 504 | Gateway Timeout | Server Error | Proxy timeout |
| 505 | HTTP Version Not Supported | Server Error | Versione HTTP non supportata |

---

**Capitolo 6 completato!**

Prossimi capitoli:
- **Capitolo 7**: Header HTTP
- **Capitolo 8**: Caching HTTP
- **Capitolo 9**: Autenticazione e Autorizzazione
- E molti altri...

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
