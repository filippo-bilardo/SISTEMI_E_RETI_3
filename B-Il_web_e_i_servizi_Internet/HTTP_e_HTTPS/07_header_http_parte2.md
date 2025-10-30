# 7. Header HTTP (Parte 2)

## 7.3.7 - Referer

**Scopo:** URL della pagina che ha generato la richiesta.

**⚠️ Nota:** "Referer" è un typo storico (dovrebbe essere "Referrer"), ma mantenuto per compatibilità.

**Sintassi:**
```http
Referer: <url>
```

**Esempi:**

**Link su pagina:**
```http
# User su https://www.example.com/page1
# Clicca link a https://www.example.com/page2

GET /page2 HTTP/1.1
Host: www.example.com
Referer: https://www.example.com/page1
```

**Immagine in pagina:**
```html
<!-- Pagina: https://site1.com/article.html -->
<img src="https://cdn.example.com/image.jpg">

<!-- Richiesta immagine: -->
GET /image.jpg HTTP/1.1
Host: cdn.example.com
Referer: https://site1.com/article.html
```

**Form submission:**
```html
<!-- Form su https://www.example.com/form.html -->
<form action="https://www.example.com/submit" method="POST">
  ...
</form>

POST /submit HTTP/1.1
Host: www.example.com
Referer: https://www.example.com/form.html
```

**Casi d'uso:**

**1. Analytics:**
```javascript
app.use((req, res, next) => {
  const referer = req.get('Referer');
  
  if (referer) {
    analytics.track('pageview', {
      page: req.path,
      referer: referer,
      external: !referer.includes(req.hostname)
    });
  }
  
  next();
});
```

**2. Hotlink protection:**
```javascript
app.get('/images/:filename', (req, res) => {
  const referer = req.get('Referer');
  const allowedDomains = ['example.com', 'cdn.example.com'];
  
  if (!referer) {
    // Nessun referer (direct access o privacy mode)
    return res.status(403).json({ error: 'Direct access forbidden' });
  }
  
  const refererDomain = new URL(referer).hostname;
  
  if (!allowedDomains.some(domain => refererDomain.includes(domain))) {
    return res.status(403).json({ 
      error: 'Hotlinking forbidden',
      referer: refererDomain 
    });
  }
  
  res.sendFile(`/path/to/images/${req.params.filename}`);
});
```

**3. CSRF protection (basic):**
```javascript
app.post('/api/sensitive-action', (req, res) => {
  const referer = req.get('Referer');
  
  if (!referer || !referer.startsWith('https://www.example.com')) {
    return res.status(403).json({ 
      error: 'Invalid referer',
      message: 'Request must originate from our domain' 
    });
  }
  
  // Process action
});
```

**Privacy e Referer Policy:**

**Controllo Referer con Referrer-Policy:**
```html
<!-- Nelle pagine HTML -->
<meta name="referrer" content="no-referrer">
<meta name="referrer" content="origin">
<meta name="referrer" content="strict-origin-when-cross-origin">

<!-- In singoli link -->
<a href="https://external.com" referrerpolicy="no-referrer">Link</a>
```

**HTTP Header:**
```http
HTTP/1.1 200 OK
Referrer-Policy: strict-origin-when-cross-origin
```

**Valori Referrer-Policy:**

| Valore | Comportamento |
|--------|---------------|
| `no-referrer` | Non inviare mai Referer |
| `no-referrer-when-downgrade` | Non inviare Referer se HTTPS→HTTP |
| `origin` | Invia solo origin (no path) |
| `origin-when-cross-origin` | Full URL same-origin, solo origin cross-origin |
| `same-origin` | Invia solo per same-origin |
| `strict-origin` | Origin solo se HTTPS→HTTPS o HTTP→HTTP |
| `strict-origin-when-cross-origin` | Full URL same-origin, origin cross-origin se sicuro |
| `unsafe-url` | Sempre full URL (⚠️ non sicuro) |

**Esempi:**

```http
# no-referrer
https://example.com/page?token=secret → https://external.com/link
GET /link HTTP/1.1
Host: external.com
[NO Referer header]

# origin
https://example.com/page?token=secret → https://external.com/link
GET /link HTTP/1.1
Host: external.com
Referer: https://example.com/

# strict-origin-when-cross-origin (default moderno)
# Same-origin: full URL
https://example.com/page1 → https://example.com/page2
Referer: https://example.com/page1

# Cross-origin: solo origin
https://example.com/page?secret → https://external.com/link
Referer: https://example.com/

# HTTPS → HTTP: no referer
https://example.com/page → http://external.com/link
[NO Referer header]
```

## 7.3.8 - Cookie

**Scopo:** Invia cookie al server.

**Sintassi:**
```http
Cookie: <name1>=<value1>[; <name2>=<value2>; ...]
```

**Esempi:**

**Singolo cookie:**
```http
Cookie: session_id=abc123xyz
```

**Multipli cookie:**
```http
Cookie: session_id=abc123xyz; user_id=12345; theme=dark; lang=it
```

**Flow completo:**

**1. Server imposta cookie (Set-Cookie):**
```http
HTTP/1.1 200 OK
Set-Cookie: session_id=abc123xyz; Path=/; HttpOnly; Secure
Set-Cookie: user_pref=theme:dark|lang:it; Path=/; Max-Age=2592000

<!DOCTYPE html>...
```

**2. Browser salva cookie**

**3. Richieste successive includono cookie:**
```http
GET /api/profile HTTP/1.1
Host: www.example.com
Cookie: session_id=abc123xyz; user_pref=theme:dark|lang:it
```

**Server legge cookie (Express.js):**
```javascript
const cookieParser = require('cookie-parser');
app.use(cookieParser());

app.get('/api/profile', (req, res) => {
  const sessionId = req.cookies.session_id;
  const userPref = req.cookies.user_pref;
  
  console.log('Session ID:', sessionId);
  console.log('User preferences:', userPref);
  
  res.json({ 
    session: sessionId,
    preferences: userPref 
  });
});
```

**Attributi Cookie (in Set-Cookie, non in Cookie header):**

| Attributo | Descrizione |
|-----------|-------------|
| `Domain` | Domini che ricevono il cookie |
| `Path` | Path che ricevono il cookie |
| `Expires` | Data scadenza assoluta |
| `Max-Age` | Secondi fino a scadenza |
| `Secure` | Solo HTTPS |
| `HttpOnly` | Non accessibile da JavaScript |
| `SameSite` | Protezione CSRF |

**Approfondimento nella sezione Response Headers (Set-Cookie).**

## 7.3.9 - Conditional Headers (If-*)

Header per richieste condizionali (cache validation, optimistic locking).

### If-Modified-Since

**Scopo:** Richiedi risorsa solo se modificata dopo data.

**Sintassi:**
```http
If-Modified-Since: <date>
```

**Esempio:**

```http
# Prima richiesta
GET /style.css HTTP/1.1
Host: www.example.com

→ HTTP/1.1 200 OK
  Last-Modified: Mon, 01 Oct 2025 12:00:00 GMT
  Content-Type: text/css
  
  body { color: blue; }

# Seconda richiesta (risorsa in cache)
GET /style.css HTTP/1.1
Host: www.example.com
If-Modified-Since: Mon, 01 Oct 2025 12:00:00 GMT

→ HTTP/1.1 304 Not Modified
  Last-Modified: Mon, 01 Oct 2025 12:00:00 GMT
  
  [NO BODY - usa cache]
```

**Server implementation:**
```javascript
app.get('/api/data', (req, res) => {
  const lastModified = new Date('2025-10-01T12:00:00Z');
  const ifModifiedSince = req.get('If-Modified-Since');
  
  if (ifModifiedSince) {
    const clientDate = new Date(ifModifiedSince);
    
    if (clientDate >= lastModified) {
      // Non modificato
      res.set('Last-Modified', lastModified.toUTCString());
      return res.status(304).end();
    }
  }
  
  // Modificato o prima richiesta
  res.set('Last-Modified', lastModified.toUTCString());
  res.json({ data: 'value' });
});
```

### If-None-Match

**Scopo:** Richiedi risorsa solo se ETag diverso.

**Sintassi:**
```http
If-None-Match: "<etag>"[, "<etag2>", ...]
```

**Esempio:**

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
  
  [NO BODY]
```

**Multipli ETag:**
```http
If-None-Match: "abc123", "def456", "ghi789"
# Se corrente è uno di questi → 304
# Se diverso → 200 con nuovi dati
```

**Wildcard:**
```http
If-None-Match: *
# Se risorsa esiste → 304
# Se non esiste → 200 (o 404)
```

**Server implementation:**
```javascript
const crypto = require('crypto');

app.get('/api/users/:id', async (req, res) => {
  const user = await db.users.findById(req.params.id);
  
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }
  
  // Genera ETag (hash del contenuto)
  const etag = crypto
    .createHash('md5')
    .update(JSON.stringify(user))
    .digest('hex');
  
  const ifNoneMatch = req.get('If-None-Match');
  
  if (ifNoneMatch === `"${etag}"`) {
    // Non modificato
    res.set('ETag', `"${etag}"`);
    return res.status(304).end();
  }
  
  // Modificato o prima richiesta
  res.set('ETag', `"${etag}"`);
  res.json(user);
});
```

### If-Match

**Scopo:** Esegui operazione solo se ETag corrisponde (optimistic locking).

**Sintassi:**
```http
If-Match: "<etag>"[, "<etag2>", ...]
```

**Esempio (update condizionale):**

```http
# Client legge risorsa
GET /api/documents/123 HTTP/1.1

→ HTTP/1.1 200 OK
  ETag: "version-5"
  
  {"id": 123, "title": "Document", "content": "..."}

# Client modifica e salva
PUT /api/documents/123 HTTP/1.1
If-Match: "version-5"
Content-Type: application/json

{"id": 123, "title": "Updated Document", "content": "..."}

→ Scenario 1: Nessun altro ha modificato
HTTP/1.1 200 OK
ETag: "version-6"

{"id": 123, "title": "Updated Document", ...}

→ Scenario 2: Qualcun altro ha modificato (ETag ora è "version-7")
HTTP/1.1 412 Precondition Failed
ETag: "version-7"

{
  "error": "PRECONDITION_FAILED",
  "message": "Document has been modified by another user",
  "current_version": "version-7",
  "your_version": "version-5"
}
```

**Server implementation:**
```javascript
app.put('/api/documents/:id', async (req, res) => {
  const doc = await db.documents.findById(req.params.id);
  
  if (!doc) {
    return res.status(404).json({ error: 'Document not found' });
  }
  
  const currentEtag = `"version-${doc.version}"`;
  const ifMatch = req.get('If-Match');
  
  if (ifMatch && ifMatch !== currentEtag) {
    // Conflict: documento modificato da altri
    res.set('ETag', currentEtag);
    return res.status(412).json({
      error: 'PRECONDITION_FAILED',
      message: 'Document has been modified',
      current_version: doc.version
    });
  }
  
  // Update documento
  doc.title = req.body.title;
  doc.content = req.body.content;
  doc.version += 1;
  await doc.save();
  
  const newEtag = `"version-${doc.version}"`;
  res.set('ETag', newEtag);
  res.json(doc);
});
```

### If-Unmodified-Since

**Scopo:** Esegui operazione solo se risorsa NON modificata dopo data.

**Esempio:**
```http
PUT /api/files/report.pdf HTTP/1.1
If-Unmodified-Since: Wed, 30 Oct 2025 10:00:00 GMT

[file data]

→ HTTP/1.1 412 Precondition Failed
  Last-Modified: Wed, 30 Oct 2025 11:00:00 GMT
  
  {
    "error": "FILE_MODIFIED",
    "message": "File was modified after specified date"
  }
```

### If-Range

**Scopo:** Resume download solo se risorsa non modificata.

**Esempio:**

```http
# Download parziale (primi 1MB)
GET /large-file.zip HTTP/1.1
Range: bytes=0-1048575

→ HTTP/1.1 206 Partial Content
  ETag: "abc123"
  Content-Range: bytes 0-1048575/10485760
  
  [primi 1MB]

# Resume download (se file non modificato)
GET /large-file.zip HTTP/1.1
Range: bytes=1048576-
If-Range: "abc123"

→ Scenario 1: File non modificato
HTTP/1.1 206 Partial Content
ETag: "abc123"
Content-Range: bytes 1048576-10485759/10485760

[resto del file]

→ Scenario 2: File modificato (ETag diverso)
HTTP/1.1 200 OK
ETag: "xyz789"
Content-Length: 10485760

[file completo da inizio - non può resumare]
```

**Beneficio:**
```
Senza If-Range:
1. Client: Range request
2. Server: 206 Partial Content (ma file modificato!)
3. Client: File corrotto (parte vecchia + parte nuova)

Con If-Range:
1. Client: Range request + If-Range
2a. Server: 206 (file non modificato) → Resume OK
2b. Server: 200 (file modificato) → Download completo, no corruzione
```

## 7.4 Response Headers

Header specifici delle risposte HTTP.

### 7.4.1 - Server

**Scopo:** Identifica software del server.

**Sintassi:**
```http
Server: <product>/<version> [<comment>]
```

**Esempi:**

```http
Server: nginx/1.24.0
Server: Apache/2.4.57 (Ubuntu)
Server: Microsoft-IIS/10.0
Server: Cloudflare
Server: Express
Server: gunicorn/20.1.0
```

**⚠️ Security concern:**
```http
# ❌ Troppi dettagli (vulnerabilità note)
Server: Apache/2.4.41 (Ubuntu) OpenSSL/1.1.1f PHP/7.4.3

# ✅ Minimalista
Server: Server
# o nascosto completamente
```

**Nascondere/modificare Server header:**

**Nginx:**
```nginx
http {
    server_tokens off;  # Rimuove versione
    
    # O custom
    more_set_headers "Server: CustomServer";
}
```

**Apache:**
```apache
ServerTokens Prod
ServerSignature Off

# O custom
Header set Server "CustomServer"
```

**Express.js:**
```javascript
app.disable('x-powered-by');

app.use((req, res, next) => {
  res.removeHeader('Server');
  // O custom
  res.setHeader('Server', 'MyApp');
  next();
});
```

### 7.4.2 - Location

**Scopo:** URL di redirect o risorsa creata.

**Sintassi:**
```http
Location: <url>
```

**Uso con 3xx (redirect):**
```http
HTTP/1.1 301 Moved Permanently
Location: https://www.example.com/new-page

HTTP/1.1 302 Found
Location: /temporary-page

HTTP/1.1 303 See Other
Location: /order/12345
```

**Uso con 201 (risorsa creata):**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario Rossi"}

→ HTTP/1.1 201 Created
  Location: /api/users/456
  Content-Type: application/json
  
  {"id": 456, "name": "Mario Rossi", ...}
```

**URL assoluto vs relativo:**

```http
# Assoluto (raccomandato)
Location: https://www.example.com/new-page

# Relativo al server
Location: /new-page

# Relativo al path corrente
Location: ../other-page
```

**Express.js:**
```javascript
// Redirect
app.get('/old-page', (req, res) => {
  res.redirect(301, '/new-page');
  // Imposta automaticamente Location header
});

// Created resource
app.post('/api/users', async (req, res) => {
  const user = await db.users.create(req.body);
  
  res.status(201)
    .location(`/api/users/${user.id}`)
    .json(user);
});
```

### 7.4.3 - Retry-After

**Scopo:** Indica quando riprovare la richiesta.

**Sintassi:**
```http
Retry-After: <seconds>
Retry-After: <date>
```

**Uso con 429 (Too Many Requests):**
```http
HTTP/1.1 429 Too Many Requests
Retry-After: 60
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 0

{
  "error": "RATE_LIMIT_EXCEEDED",
  "message": "Try again in 60 seconds"
}
```

**Uso con 503 (Service Unavailable):**
```http
HTTP/1.1 503 Service Unavailable
Retry-After: 3600

{
  "error": "MAINTENANCE",
  "message": "Server under maintenance, retry in 1 hour"
}
```

**Con data:**
```http
HTTP/1.1 503 Service Unavailable
Retry-After: Wed, 30 Oct 2025 13:00:00 GMT

{
  "message": "Maintenance until 13:00 GMT"
}
```

**Client handling:**
```javascript
async function fetchWithRetry(url, maxRetries = 3) {
  let retries = 0;
  
  while (retries < maxRetries) {
    const response = await fetch(url);
    
    if (response.ok) {
      return response;
    }
    
    if (response.status === 429 || response.status === 503) {
      const retryAfter = response.headers.get('Retry-After');
      
      if (retryAfter) {
        const seconds = parseInt(retryAfter) || 60;
        console.log(`Rate limited. Retrying in ${seconds} seconds...`);
        await sleep(seconds * 1000);
        retries++;
        continue;
      }
    }
    
    throw new Error(`HTTP ${response.status}`);
  }
  
  throw new Error('Max retries exceeded');
}
```

### 7.4.4 - Set-Cookie

**Scopo:** Imposta cookie nel browser.

**Sintassi:**
```http
Set-Cookie: <name>=<value>[; <attribute>][; <attribute>...]
```

**Attributi:**

| Attributo | Descrizione | Esempio |
|-----------|-------------|---------|
| `Domain` | Domini che ricevono cookie | `Domain=example.com` |
| `Path` | Path che ricevono cookie | `Path=/api` |
| `Expires` | Data scadenza | `Expires=Wed, 30 Oct 2025 12:00:00 GMT` |
| `Max-Age` | Secondi fino a scadenza | `Max-Age=3600` |
| `Secure` | Solo HTTPS | `Secure` |
| `HttpOnly` | Non accessibile da JS | `HttpOnly` |
| `SameSite` | Protezione CSRF | `SameSite=Strict` |

**Esempi:**

**Cookie sessione (senza scadenza):**
```http
Set-Cookie: session_id=abc123xyz; Path=/; HttpOnly; Secure
```

**Cookie persistente:**
```http
Set-Cookie: user_id=12345; Max-Age=2592000; Path=/; Secure
# Max-Age=2592000 = 30 giorni
```

**Cookie con dominio:**
```http
Set-Cookie: lang=it; Domain=.example.com; Path=/; Max-Age=31536000
# Valido per example.com e tutti i sottodomini (*.example.com)
```

**Multipli cookie:**
```http
HTTP/1.1 200 OK
Set-Cookie: session_id=abc123; Path=/; HttpOnly; Secure
Set-Cookie: theme=dark; Path=/; Max-Age=31536000
Set-Cookie: lang=it; Path=/; Max-Age=31536000
```

**SameSite values:**

| Valore | Comportamento |
|--------|---------------|
| `Strict` | Cookie inviato solo same-site (no cross-site) |
| `Lax` | Cookie inviato in top-level navigation cross-site |
| `None` | Cookie sempre inviato (richiede Secure) |

**Esempi SameSite:**

```http
# Strict (massima protezione CSRF)
Set-Cookie: auth=token123; SameSite=Strict; Secure; HttpOnly
# Cookie inviato solo se richiesta da stesso sito
# ❌ NON inviato se user clicca link da email/social

# Lax (default moderno)
Set-Cookie: session=abc123; SameSite=Lax; Secure; HttpOnly
# ✅ Inviato in top-level navigation (click link)
# ❌ NON inviato in iframe, fetch cross-origin

# None (permissivo, per cross-site)
Set-Cookie: tracking=xyz789; SameSite=None; Secure
# ✅ Sempre inviato (richiede HTTPS)
```

**Express.js:**
```javascript
app.post('/api/login', (req, res) => {
  // Verifica credenziali
  const user = authenticateUser(req.body);
  
  // Imposta cookie
  res.cookie('session_id', user.sessionId, {
    httpOnly: true,    // No JS access
    secure: true,      // Solo HTTPS
    sameSite: 'strict', // Protezione CSRF
    maxAge: 3600000    // 1 ora (millisecondi)
  });
  
  res.json({ message: 'Logged in' });
});

app.post('/api/logout', (req, res) => {
  // Cancella cookie
  res.clearCookie('session_id');
  res.json({ message: 'Logged out' });
});
```

**Security best practices:**

```javascript
// ✅ Cookie sessione sicuro
res.cookie('session', sessionId, {
  httpOnly: true,     // ✅ Protegge da XSS
  secure: true,       // ✅ Solo HTTPS
  sameSite: 'strict', // ✅ Protegge da CSRF
  maxAge: 3600000,    // ✅ Scadenza limitata
  domain: '.example.com', // ⚠️ Solo se necessario
  path: '/'           // ⚠️ Limita se possibile
});

// ❌ Cookie non sicuro
res.cookie('session', sessionId, {
  // ❌ HttpOnly mancante (accessibile da JS)
  // ❌ Secure mancante (inviato su HTTP)
  // ❌ SameSite mancante (vulnerabile CSRF)
  // ❌ Scadenza eccessiva
  maxAge: 31536000000 // 1 anno
});
```

**Cookie prefissi (security):**

```http
# __Secure- prefix (richiede Secure)
Set-Cookie: __Secure-session=abc123; Secure; Path=/

# __Host- prefix (richiede Secure, Path=/, no Domain)
Set-Cookie: __Host-session=abc123; Secure; Path=/; HttpOnly
```

---

**Continua nella Parte 3...**

Prossimi argomenti:
- 7.5 Entity Headers (Content-Type, Content-Length, Content-Encoding)
- 7.6 CORS Headers
- 7.7 Security Headers
- 7.8 Custom Headers
- 7.9 Header Best Practices

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
