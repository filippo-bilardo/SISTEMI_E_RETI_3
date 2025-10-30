# 6. Codici di Stato HTTP

## 6.1 Introduzione ai Codici di Stato

I **codici di stato HTTP** (Status Codes) sono numeri di tre cifre che il server invia nella risposta per indicare il risultato della richiesta.

### 6.1.1 Struttura

```http
HTTP/1.1 [Status-Code] [Reason-Phrase]
```

**Esempio:**
```http
HTTP/1.1 200 OK
HTTP/1.1 404 Not Found
HTTP/1.1 500 Internal Server Error
```

### 6.1.2 Categorie (Classi)

I codici di stato sono divisi in **5 classi**, identificate dalla prima cifra:

| Classe | Range | Significato | Categoria |
|--------|-------|-------------|-----------|
| **1xx** | 100-199 | **Informational** | Richiesta ricevuta, processo in corso |
| **2xx** | 200-299 | **Success** | Richiesta completata con successo |
| **3xx** | 300-399 | **Redirection** | Ulteriori azioni necessarie |
| **4xx** | 400-499 | **Client Error** | Errore da parte del client |
| **5xx** | 500-599 | **Server Error** | Errore da parte del server |

### 6.1.3 Tabella Riassuntiva dei Codici Comuni

| Codice | Nome | Uso Comune |
|--------|------|------------|
| **100** | Continue | Continue con il body |
| **101** | Switching Protocols | WebSocket upgrade |
| **200** | OK | Richiesta riuscita |
| **201** | Created | Risorsa creata |
| **204** | No Content | Successo senza body |
| **301** | Moved Permanently | Redirect permanente |
| **302** | Found | Redirect temporaneo |
| **304** | Not Modified | Cache valida |
| **400** | Bad Request | Richiesta malformata |
| **401** | Unauthorized | Autenticazione richiesta |
| **403** | Forbidden | Accesso negato |
| **404** | Not Found | Risorsa non trovata |
| **405** | Method Not Allowed | Metodo non permesso |
| **409** | Conflict | Conflitto di stato |
| **429** | Too Many Requests | Rate limit superato |
| **500** | Internal Server Error | Errore generico server |
| **502** | Bad Gateway | Gateway/proxy error |
| **503** | Service Unavailable | Server sovraccarico |
| **504** | Gateway Timeout | Gateway timeout |

## 6.2 Codici 1xx - Informational

I codici **1xx** indicano che la richiesta è stata ricevuta e il processo è in corso.

### 6.2.1 - 100 Continue

**Significato:** Il client può continuare con la richiesta.

**Uso:** Con header `Expect: 100-continue` per verificare prima di inviare body grande.

**Flusso:**
```http
# Step 1: Client chiede conferma prima di inviare body
POST /api/upload HTTP/1.1
Host: api.example.com
Content-Type: application/octet-stream
Content-Length: 1073741824
Expect: 100-continue

# Step 2: Server risponde che può procedere
HTTP/1.1 100 Continue

# Step 3: Client invia body
[1GB di dati binari...]

# Step 4: Server risponde con risultato finale
HTTP/1.1 201 Created
Location: /api/files/12345
```

**Perché usarlo:**
```http
# ❌ Senza 100 Continue:
POST /api/upload HTTP/1.1
Content-Length: 1073741824

[Client invia 1GB...]

HTTP/1.1 401 Unauthorized
# ⚠️ Spreco di banda! 1GB inviato inutilmente

# ✅ Con 100 Continue:
POST /api/upload HTTP/1.1
Content-Length: 1073741824
Expect: 100-continue

HTTP/1.1 401 Unauthorized
# ✅ Nessun dato inviato, banda risparmiata!
```

**Implementazione client (curl):**
```bash
curl -X POST \
  -H "Content-Type: application/octet-stream" \
  -H "Expect: 100-continue" \
  --data-binary @large-file.bin \
  https://api.example.com/upload
```

### 6.2.2 - 101 Switching Protocols

**Significato:** Il server accetta di cambiare protocollo.

**Uso principale:** WebSocket upgrade.

**Esempio: WebSocket Handshake**
```http
# Client richiede upgrade a WebSocket
GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13

→ Server accetta upgrade
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=

[Connessione passa a protocollo WebSocket]
```

**Esempio: HTTP/2 upgrade (raro)**
```http
GET / HTTP/1.1
Host: example.com
Connection: Upgrade, HTTP2-Settings
Upgrade: h2c
HTTP2-Settings: AAMAAABkAARAAAAAAAIAAAAA

→ HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Upgrade: h2c

[Connessione passa a HTTP/2]
```

### 6.2.3 - 102 Processing (WebDAV)

**Significato:** Richiesta ricevuta, elaborazione in corso (può richiedere tempo).

**Uso:** WebDAV per operazioni lunghe.

```http
COPY /large-folder HTTP/1.1
Host: webdav.example.com

→ HTTP/1.1 102 Processing

[dopo qualche secondo...]

→ HTTP/1.1 201 Created
```

### 6.2.4 - 103 Early Hints

**Significato:** Invia header prima della risposta finale (performance optimization).

**Uso:** Preload di risorse mentre server prepara risposta.

```http
GET /page.html HTTP/1.1
Host: www.example.com

→ HTTP/1.1 103 Early Hints
Link: </style.css>; rel=preload; as=style
Link: </script.js>; rel=preload; as=script

[Browser inizia a scaricare CSS e JS]

→ HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
  <link rel="stylesheet" href="/style.css">
  <script src="/script.js"></script>
  ...
</html>
```

**Beneficio:** Riduce latenza, browser scarica risorse in parallelo.

## 6.3 Codici 2xx - Success

I codici **2xx** indicano che la richiesta è stata ricevuta, compresa e accettata con successo.

### 6.3.1 - 200 OK

**Significato:** Richiesta completata con successo.

**Uso:** Risposta standard per GET, POST, PUT, PATCH con successo.

**Esempi:**

**GET riuscito:**
```http
GET /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"id": 123, "name": "Mario Rossi"}
```

**POST riuscito (con contenuto):**
```http
POST /api/search HTTP/1.1
Content-Type: application/json

{"query": "laptop"}

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"results": [...], "total": 42}
```

**PUT riuscito:**
```http
PUT /api/users/123 HTTP/1.1
Content-Type: application/json

{"name": "Mario Rossi Updated"}

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"id": 123, "name": "Mario Rossi Updated", "updated_at": "2025-10-30T12:00:00Z"}
```

### 6.3.2 - 201 Created

**Significato:** Nuova risorsa creata con successo.

**Uso:** POST che crea nuova risorsa.

**Headers importanti:**
- `Location`: URI della nuova risorsa

**Esempio:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Nuovo Utente", "email": "nuovo@example.com"}

→ HTTP/1.1 201 Created
  Location: /api/users/456
  Content-Type: application/json
  
  {
    "id": 456,
    "name": "Nuovo Utente",
    "email": "nuovo@example.com",
    "created_at": "2025-10-30T12:00:00Z"
  }
```

**Client può usare Location per accedere alla risorsa:**
```http
GET /api/users/456 HTTP/1.1

→ HTTP/1.1 200 OK
  {"id": 456, "name": "Nuovo Utente", ...}
```

### 6.3.3 - 202 Accepted

**Significato:** Richiesta accettata ma non ancora completata.

**Uso:** Operazioni asincrone, job in background.

**Esempio: Background job**
```http
POST /api/reports/generate HTTP/1.1
Content-Type: application/json

{"type": "annual", "year": 2025}

→ HTTP/1.1 202 Accepted
  Location: /api/jobs/789
  Content-Type: application/json
  
  {
    "job_id": "789",
    "status": "pending",
    "message": "Report generation started",
    "check_status_url": "/api/jobs/789"
  }
```

**Client verifica stato:**
```http
GET /api/jobs/789 HTTP/1.1

→ HTTP/1.1 200 OK
  {
    "job_id": "789",
    "status": "processing",
    "progress": 45,
    "estimated_completion": "2025-10-30T12:05:00Z"
  }

[dopo qualche minuto...]

GET /api/jobs/789 HTTP/1.1

→ HTTP/1.1 200 OK
  {
    "job_id": "789",
    "status": "completed",
    "result_url": "/api/reports/annual-2025.pdf"
  }
```

### 6.3.4 - 204 No Content

**Significato:** Richiesta completata con successo, nessun contenuto da restituire.

**Uso:** DELETE, PUT, PATCH senza body nella risposta.

**Esempi:**

**DELETE riuscito:**
```http
DELETE /api/users/123 HTTP/1.1

→ HTTP/1.1 204 No Content
  
  [nessun body]
```

**PUT riuscito senza dati da restituire:**
```http
PUT /api/settings HTTP/1.1
Content-Type: application/json

{"theme": "dark", "language": "it"}

→ HTTP/1.1 204 No Content
  
  [nessun body]
```

**PATCH riuscito:**
```http
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{"active": false}

→ HTTP/1.1 204 No Content
```

### 6.3.5 - 206 Partial Content

**Significato:** Risposta parziale (range request).

**Uso:** Download di porzioni di file, resume download, streaming.

**Headers importanti:**
- `Content-Range`: Byte range restituito
- `Content-Length`: Dimensione della porzione

**Esempio: Download parziale**
```http
GET /video.mp4 HTTP/1.1
Range: bytes=0-1023

→ HTTP/1.1 206 Partial Content
  Content-Range: bytes 0-1023/524288000
  Content-Length: 1024
  Content-Type: video/mp4
  
  [primi 1024 byte del video]
```

**Esempio: Resume download**
```http
# Client ha scaricato fino al byte 10485759 (10MB)
GET /large-file.zip HTTP/1.1
Range: bytes=10485760-

→ HTTP/1.1 206 Partial Content
  Content-Range: bytes 10485760-104857599/104857600
  Content-Length: 94371840
  
  [byte da 10485760 fino alla fine]
```

**Esempio: Multiple ranges**
```http
GET /document.pdf HTTP/1.1
Range: bytes=0-499, 1000-1499, 5000-5999

→ HTTP/1.1 206 Partial Content
  Content-Type: multipart/byteranges; boundary=BOUNDARY
  
  --BOUNDARY
  Content-Type: application/pdf
  Content-Range: bytes 0-499/8000
  
  [byte 0-499]
  --BOUNDARY
  Content-Type: application/pdf
  Content-Range: bytes 1000-1499/8000
  
  [byte 1000-1499]
  --BOUNDARY
  Content-Type: application/pdf
  Content-Range: bytes 5000-5999/8000
  
  [byte 5000-5999]
  --BOUNDARY--
```

**Verifica supporto range:**
```http
HEAD /video.mp4 HTTP/1.1

→ HTTP/1.1 200 OK
  Accept-Ranges: bytes
  Content-Length: 524288000
  
# Accept-Ranges: bytes → supporta range requests
# Accept-Ranges: none → non supporta range requests
```

## 6.4 Codici 3xx - Redirection

I codici **3xx** indicano che il client deve eseguire ulteriori azioni per completare la richiesta.

### 6.4.1 - 301 Moved Permanently

**Significato:** Risorsa spostata permanentemente in nuova posizione.

**Uso:** Migrazione URL, ristrutturazione sito.

**Headers importanti:**
- `Location`: Nuovo URL permanente

**Esempio:**
```http
GET /old-page HTTP/1.1
Host: www.example.com

→ HTTP/1.1 301 Moved Permanently
  Location: https://www.example.com/new-page
  
  <!DOCTYPE html>
  <html>
    <body>
      <h1>Page Moved</h1>
      <p>The page has moved to <a href="/new-page">/new-page</a></p>
    </body>
  </html>
```

**Comportamento:**
- ✅ Browser aggiorna bookmark
- ✅ Search engine aggiorna indice
- ✅ Future richieste vanno al nuovo URL
- ⚠️ Metodo cambia a GET (eccetto 307/308)

**Esempio pratico: HTTP → HTTPS**
```http
GET http://example.com/page HTTP/1.1

→ HTTP/1.1 301 Moved Permanently
  Location: https://example.com/page
  
# Browser reindirizza automaticamente a HTTPS
```

**Configurazione server:**

**Nginx:**
```nginx
server {
    listen 80;
    server_name example.com;
    
    # Redirect all HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

# Redirect specifico
location /old-path {
    return 301 /new-path;
}
```

**Apache:**
```apache
# .htaccess
Redirect 301 /old-page.html /new-page.html

# Redirect HTTP to HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```

### 6.4.2 - 302 Found (Temporary Redirect)

**Significato:** Risorsa temporaneamente disponibile in altra posizione.

**Uso:** Redirect temporaneo, A/B testing, manutenzione.

**Esempio:**
```http
GET /product/123 HTTP/1.1

→ HTTP/1.1 302 Found
  Location: /products/out-of-stock
  
# Temporaneo, URL originale rimane valido
```

**Differenza 301 vs 302:**

| Aspetto | 301 Permanent | 302 Temporary |
|---------|---------------|---------------|
| **Durata** | Permanente | Temporaneo |
| **Cache** | Cachato a lungo | Cachato brevemente |
| **SEO** | Trasferisce ranking | Non trasferisce |
| **Bookmark** | Aggiorna | Non aggiorna |
| **Uso** | Migrazione definitiva | Redirect temporaneo |

**Esempio: Manutenzione**
```http
GET /api/service HTTP/1.1

→ HTTP/1.1 302 Found
  Location: /maintenance.html
  Retry-After: 3600
  
# Dopo manutenzione, /api/service torna disponibile
```

### 6.4.3 - 303 See Other

**Significato:** Risposta disponibile a diverso URI con GET.

**Uso:** POST-Redirect-GET pattern.

**Esempio: Form submission**
```http
# Step 1: User submit form
POST /api/orders HTTP/1.1
Content-Type: application/json

{"product_id": 123, "quantity": 2}

# Step 2: Server crea ordine e redirect
→ HTTP/1.1 303 See Other
  Location: /orders/456
  
# Step 3: Browser esegue GET automaticamente
GET /orders/456 HTTP/1.1

→ HTTP/1.1 200 OK
  Content-Type: text/html
  
  <html>
    <h1>Order Confirmation</h1>
    <p>Order #456 created successfully!</p>
  </html>
```

**Beneficio:** Previene doppio submit se utente ricarica pagina.

```
Senza 303:
POST /order → 200 OK con HTML
User preme F5 → ⚠️ "Resubmit form?" → Doppio ordine!

Con 303:
POST /order → 303 See Other → Location: /order/456
Browser: GET /order/456 → 200 OK con HTML
User preme F5 → ✅ GET /order/456 (safe, idempotent)
```

### 6.4.4 - 304 Not Modified

**Significato:** Risorsa non modificata, usa cache.

**Uso:** Conditional requests con `If-Modified-Since` o `If-None-Match`.

**Esempio: If-Modified-Since**
```http
# Prima richiesta
GET /style.css HTTP/1.1

→ HTTP/1.1 200 OK
  Last-Modified: Wed, 25 Oct 2025 10:00:00 GMT
  Content-Type: text/css
  Cache-Control: max-age=3600
  
  body { color: blue; }

# Seconda richiesta (dopo un po')
GET /style.css HTTP/1.1
If-Modified-Since: Wed, 25 Oct 2025 10:00:00 GMT

→ HTTP/1.1 304 Not Modified
  Last-Modified: Wed, 25 Oct 2025 10:00:00 GMT
  Cache-Control: max-age=3600
  
  [NO BODY - usa cache]
```

**Esempio: ETag**
```http
# Prima richiesta
GET /api/users/123 HTTP/1.1

→ HTTP/1.1 200 OK
  ETag: "abc123xyz"
  Content-Type: application/json
  
  {"id": 123, "name": "Mario Rossi"}

# Seconda richiesta
GET /api/users/123 HTTP/1.1
If-None-Match: "abc123xyz"

→ HTTP/1.1 304 Not Modified
  ETag: "abc123xyz"
  
  [NO BODY - dati non cambiati]
```

**Benefici:**
- ✅ Riduce banda (no body)
- ✅ Riduce latenza (risposta più veloce)
- ✅ Riduce carico server (no processing)

### 6.4.5 - 307 Temporary Redirect

**Significato:** Come 302, ma **mantiene il metodo HTTP**.

**Differenza con 302:**
- 302: metodo può cambiare a GET
- 307: metodo **rimane invariato**

**Esempio:**
```http
POST /api/v1/users HTTP/1.1
Content-Type: application/json

{"name": "Mario"}

→ HTTP/1.1 307 Temporary Redirect
  Location: /api/v2/users
  
# Browser ripete POST (non GET) a /api/v2/users
POST /api/v2/users HTTP/1.1
Content-Type: application/json

{"name": "Mario"}
```

### 6.4.6 - 308 Permanent Redirect

**Significato:** Come 301, ma **mantiene il metodo HTTP**.

**Differenza con 301:**
- 301: metodo può cambiare a GET
- 308: metodo **rimane invariato**

**Esempio:**
```http
PUT /api/v1/users/123 HTTP/1.1
Content-Type: application/json

{"name": "Mario Updated"}

→ HTTP/1.1 308 Permanent Redirect
  Location: /api/v2/users/123
  
# Browser ripete PUT (non GET) a /api/v2/users/123
PUT /api/v2/users/123 HTTP/1.1
Content-Type: application/json

{"name": "Mario Updated"}
```

**Riepilogo Redirect:**

| Codice | Tipo | Mantiene Metodo | Uso |
|--------|------|-----------------|-----|
| **301** | Permanente | ❌ No (→ GET) | Migrazione URL permanente |
| **302** | Temporaneo | ❌ No (→ GET) | Redirect temporaneo |
| **303** | See Other | ❌ Forza GET | POST-Redirect-GET |
| **307** | Temporaneo | ✅ Sì | Redirect temporaneo (preserva metodo) |
| **308** | Permanente | ✅ Sì | Migrazione permanente (preserva metodo) |

## 6.5 Codici 4xx - Client Error

I codici **4xx** indicano che il client ha fatto un errore nella richiesta.

### 6.5.1 - 400 Bad Request

**Significato:** Richiesta malformata o non valida.

**Cause comuni:**
- JSON malformato
- Parametri mancanti/non validi
- Headers incorretti
- Sintassi errata

**Esempi:**

**JSON malformato:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario", "email": }  ← sintassi non valida

→ HTTP/1.1 400 Bad Request
  Content-Type: application/json
  
  {
    "error": "INVALID_JSON",
    "message": "Malformed JSON in request body",
    "details": "Unexpected token at position 28"
  }
```

**Parametri non validi:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "", "email": "not-an-email"}

→ HTTP/1.1 400 Bad Request
  Content-Type: application/json
  
  {
    "error": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "fields": {
      "name": "Name cannot be empty",
      "email": "Invalid email format"
    }
  }
```

**Header mancante:**
```http
POST /api/users HTTP/1.1

{"name": "Mario"}

→ HTTP/1.1 400 Bad Request
  
  {
    "error": "MISSING_CONTENT_TYPE",
    "message": "Content-Type header is required"
  }
```

### 6.5.2 - 401 Unauthorized

**Significato:** Autenticazione richiesta o fallita.

**Headers importanti:**
- `WWW-Authenticate`: Schema di autenticazione richiesto

**Esempi:**

**Nessuna autenticazione:**
```http
GET /api/private HTTP/1.1

→ HTTP/1.1 401 Unauthorized
  WWW-Authenticate: Bearer realm="API"
  Content-Type: application/json
  
  {
    "error": "AUTHENTICATION_REQUIRED",
    "message": "Authentication token is required"
  }
```

**Token non valido/scaduto:**
```http
GET /api/private HTTP/1.1
Authorization: Bearer expired-token-xyz

→ HTTP/1.1 401 Unauthorized
  WWW-Authenticate: Bearer realm="API", error="invalid_token"
  Content-Type: application/json
  
  {
    "error": "INVALID_TOKEN",
    "message": "Token is expired or invalid"
  }
```

**Basic Authentication:**
```http
GET /admin HTTP/1.1

→ HTTP/1.1 401 Unauthorized
  WWW-Authenticate: Basic realm="Admin Area"
  
# Browser mostra dialog di login
```

**Credenziali errate:**
```http
POST /api/login HTTP/1.1
Content-Type: application/json

{"username": "mario", "password": "wrong"}

→ HTTP/1.1 401 Unauthorized
  Content-Type: application/json
  
  {
    "error": "INVALID_CREDENTIALS",
    "message": "Username or password incorrect"
  }
```

### 6.5.3 - 403 Forbidden

**Significato:** Autenticato ma non autorizzato (nessun permesso).

**Differenza 401 vs 403:**
- **401**: Non sei autenticato (chi sei?)
- **403**: Sei autenticato ma non hai permessi (non puoi fare questo)

**Esempi:**

**Permessi insufficienti:**
```http
DELETE /api/users/456 HTTP/1.1
Authorization: Bearer user-token-123

→ HTTP/1.1 403 Forbidden
  Content-Type: application/json
  
  {
    "error": "INSUFFICIENT_PERMISSIONS",
    "message": "You don't have permission to delete users",
    "required_role": "admin",
    "your_role": "user"
  }
```

**Accesso a risorsa di altri:**
```http
GET /api/users/456/private-data HTTP/1.1
Authorization: Bearer user-123-token

→ HTTP/1.1 403 Forbidden
  
  {
    "error": "ACCESS_DENIED",
    "message": "You can only access your own private data"
  }
```

**IP bloccato:**
```http
GET /api/data HTTP/1.1

→ HTTP/1.1 403 Forbidden
  
  {
    "error": "IP_BLOCKED",
    "message": "Your IP address is blocked",
    "contact": "support@example.com"
  }
```

### 6.5.4 - 404 Not Found

**Significato:** Risorsa non trovata.

**Uso:** URL non esiste, risorsa eliminata, ID non valido.

**Esempi:**

**Risorsa non esiste:**
```http
GET /api/users/99999 HTTP/1.1

→ HTTP/1.1 404 Not Found
  Content-Type: application/json
  
  {
    "error": "USER_NOT_FOUND",
    "message": "User with ID 99999 does not exist"
  }
```

**Endpoint non esiste:**
```http
GET /api/nonexistent HTTP/1.1

→ HTTP/1.1 404 Not Found
  Content-Type: application/json
  
  {
    "error": "ENDPOINT_NOT_FOUND",
    "message": "The requested endpoint does not exist",
    "path": "/api/nonexistent"
  }
```

**Pagina web:**
```http
GET /missing-page.html HTTP/1.1

→ HTTP/1.1 404 Not Found
  Content-Type: text/html
  
  <!DOCTYPE html>
  <html>
    <head><title>404 Not Found</title></head>
    <body>
      <h1>404 - Page Not Found</h1>
      <p>The page you are looking for does not exist.</p>
    </body>
  </html>
```

### 6.5.5 - 405 Method Not Allowed

**Significato:** Metodo HTTP non permesso per questa risorsa.

**Headers importanti:**
- `Allow`: Metodi permessi

**Esempio:**
```http
POST /api/users/123 HTTP/1.1

→ HTTP/1.1 405 Method Not Allowed
  Allow: GET, PUT, PATCH, DELETE
  Content-Type: application/json
  
  {
    "error": "METHOD_NOT_ALLOWED",
    "message": "POST method is not allowed for this resource",
    "allowed_methods": ["GET", "PUT", "PATCH", "DELETE"]
  }
```

**Esempio 2:**
```http
DELETE /api/products HTTP/1.1

→ HTTP/1.1 405 Method Not Allowed
  Allow: GET, POST
  
  {
    "error": "METHOD_NOT_ALLOWED",
    "message": "Cannot DELETE collection, use /api/products/{id}"
  }
```

### 6.5.6 - 409 Conflict

**Significato:** Conflitto con lo stato corrente della risorsa.

**Uso:** Race conditions, vincoli violati, duplicate.

**Esempi:**

**Email duplicata:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario", "email": "existing@example.com"}

→ HTTP/1.1 409 Conflict
  Content-Type: application/json
  
  {
    "error": "EMAIL_ALREADY_EXISTS",
    "message": "A user with this email already exists",
    "conflicting_field": "email"
  }
```

**Versione non corrente (optimistic locking):**
```http
PUT /api/documents/123 HTTP/1.1
If-Match: "version-5"
Content-Type: application/json

{"title": "Updated Title", "version": 6}

→ HTTP/1.1 409 Conflict
  ETag: "version-7"
  
  {
    "error": "VERSION_CONFLICT",
    "message": "Document has been modified by another user",
    "current_version": 7,
    "your_version": 5
  }
```

**Stato non valido:**
```http
DELETE /api/orders/123 HTTP/1.1

→ HTTP/1.1 409 Conflict
  
  {
    "error": "CANNOT_DELETE_SHIPPED_ORDER",
    "message": "Cannot delete order that has been shipped",
    "order_status": "shipped"
  }
```

### 6.5.7 - 429 Too Many Requests

**Significato:** Troppi richieste (rate limiting).

**Headers importanti:**
- `Retry-After`: Quando riprovare
- `X-RateLimit-*`: Info rate limiting

**Esempio:**
```http
GET /api/users HTTP/1.1

→ HTTP/1.1 429 Too Many Requests
  Retry-After: 60
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 0
  X-RateLimit-Reset: 1698667200
  Content-Type: application/json
  
  {
    "error": "RATE_LIMIT_EXCEEDED",
    "message": "API rate limit exceeded",
    "limit": 100,
    "period": "hour",
    "retry_after": 60
  }
```

**Rate Limiting Headers:**
```http
# Prima richiesta
GET /api/data HTTP/1.1

→ HTTP/1.1 200 OK
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 99
  X-RateLimit-Reset: 1698667200
  
# Dopo 100 richieste
GET /api/data HTTP/1.1

→ HTTP/1.1 429 Too Many Requests
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 0
  X-RateLimit-Reset: 1698667200
  Retry-After: 3600
```

---

**Continua nella Parte 2...**

Prossimi argomenti:
- 6.6 Altri codici 4xx (410, 413, 414, 415, 422, etc.)
- 6.7 Codici 5xx - Server Error (500, 502, 503, 504)
- 6.8 Best Practices per Status Codes
- 6.9 Custom Status Codes

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
