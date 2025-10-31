# 8. Caching HTTP

## 8.1 Introduzione al Caching

Il **caching** è il processo di memorizzazione temporanea di risposte HTTP per riutilizzarle in richieste successive, riducendo latenza, traffico di rete e carico sul server.

### 8.1.1 - Vantaggi del Caching

**Performance:**
- ⚡ Riduce latenza (risposta immediata da cache)
- 📉 Riduce traffico di rete (meno dati trasferiti)
- 🚀 Migliora user experience (pagine più veloci)

**Scalabilità:**
- 💰 Riduce costi server (meno richieste da gestire)
- 📊 Migliora scalabilità (gestisce più utenti)
- 🔄 Riduce carico database

**Esempio performance:**
```
Senza cache:
Request → Server → Database → Response
Time: 500ms

Con cache:
Request → Cache → Response
Time: 10ms (50x più veloce!)
```

### 8.1.2 - Tipi di Cache

**1. Browser Cache (Private Cache):**
```
User Browser
├── Cached: images, CSS, JavaScript
├── Storage: Disco locale
└── Scope: Singolo utente
```

**2. Proxy Cache (Shared Cache):**
```
Company Proxy
├── Cached: Risorse comuni
├── Storage: Server proxy
└── Scope: Tutti gli utenti della rete
```

**3. CDN Cache:**
```
CDN Edge Servers
├── Cached: Static assets
├── Storage: Edge locations
└── Scope: Globale
```

**4. Reverse Proxy Cache:**
```
Nginx/Varnish
├── Cached: HTML, API responses
├── Storage: Server cache
└── Scope: Tutti i client
```

### 8.1.3 - Cache Lifecycle

```
1. Request → Cache Lookup
   ↓
2. Cache Hit? 
   ├─ Yes → Return cached response
   └─ No → Continue
   ↓
3. Send request to origin server
   ↓
4. Receive response
   ↓
5. Store in cache (if cacheable)
   ↓
6. Return response to client
```

## 8.2 Cache-Control Header

Header principale per controllare il comportamento della cache.

### 8.2.1 - Direttive Request

**no-cache:**
```http
Cache-Control: no-cache
# Deve validare con server prima di usare cache
```

**no-store:**
```http
Cache-Control: no-store
# Non memorizzare mai in cache (dati sensibili)
```

**max-age:**
```http
Cache-Control: max-age=0
# Accetta solo risposta fresca (età massima 0 secondi)
```

**max-stale:**
```http
Cache-Control: max-stale=3600
# Accetta risposta scaduta da max 1 ora
```

**min-fresh:**
```http
Cache-Control: min-fresh=60
# Vuole risposta fresca per almeno 1 minuto
```

**only-if-cached:**
```http
Cache-Control: only-if-cached
# Usa solo cache, non contattare server
```

### 8.2.2 - Direttive Response

**public:**
```http
Cache-Control: public, max-age=31536000
# Può essere cachato da qualsiasi cache (browser, CDN, proxy)
# Uso: Static assets (CSS, JS, images)
```

**private:**
```http
Cache-Control: private, max-age=3600
# Solo browser cache (no CDN, no proxy)
# Uso: Dati personali utente
```

**no-cache:**
```http
Cache-Control: no-cache
# Può cachare ma deve revalidare prima di usare
# Uso: Contenuto che cambia spesso
```

**no-store:**
```http
Cache-Control: no-store
# Non cachare mai
# Uso: Dati sensibili (password, pagamenti)
```

**max-age:**
```http
Cache-Control: max-age=3600
# Fresco per 3600 secondi (1 ora)
```

**s-maxage:**
```http
Cache-Control: s-maxage=86400, max-age=3600
# s-maxage per shared cache (CDN, proxy)
# max-age per browser cache
# CDN: 24h, Browser: 1h
```

**must-revalidate:**
```http
Cache-Control: max-age=3600, must-revalidate
# Dopo scadenza, DEVE revalidare (no stale)
```

**proxy-revalidate:**
```http
Cache-Control: max-age=3600, proxy-revalidate
# Solo proxy deve revalidare, browser può usare stale
```

**immutable:**
```http
Cache-Control: public, max-age=31536000, immutable
# Contenuto non cambierà MAI
# Uso: Versioned assets (app.abc123.js)
```

**no-transform:**
```http
Cache-Control: no-transform
# Proxy non deve modificare (es. compressione)
```

### 8.2.3 - Esempi Pratici

**Static assets (CSS, JS, images con versioning):**
```http
HTTP/1.1 200 OK
Cache-Control: public, max-age=31536000, immutable
# Cache per 1 anno, non cambia mai
```

```html
<!-- Versioning in filename -->
<link rel="stylesheet" href="/css/style.v123.css">
<script src="/js/app.v456.js"></script>
```

**HTML pages:**
```http
HTTP/1.1 200 OK
Cache-Control: no-cache
# Sempre revalidare (contenuto dinamico)
```

**API responses (public data):**
```http
HTTP/1.1 200 OK
Cache-Control: public, max-age=60
# Cache per 1 minuto
```

**API responses (user data):**
```http
HTTP/1.1 200 OK
Cache-Control: private, max-age=300
# Cache privata per 5 minuti
```

**Sensitive data:**
```http
HTTP/1.1 200 OK
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
# Mai cachare
```

**CDN + Browser:**
```http
HTTP/1.1 200 OK
Cache-Control: public, s-maxage=86400, max-age=3600
# CDN: 24h, Browser: 1h
```

### 8.2.4 - Express.js Examples

```javascript
const express = require('express');
const app = express();

// Static assets (versioned)
app.use('/static', express.static('public', {
  maxAge: '1y',
  immutable: true
}));

// HTML (no cache)
app.get('/', (req, res) => {
  res.set('Cache-Control', 'no-cache');
  res.sendFile('index.html');
});

// API public data
app.get('/api/products', (req, res) => {
  res.set('Cache-Control', 'public, max-age=60');
  res.json({ products: [...] });
});

// API user data
app.get('/api/user/:id', (req, res) => {
  res.set('Cache-Control', 'private, max-age=300');
  res.json({ user: {...} });
});

// Sensitive data
app.post('/api/payment', (req, res) => {
  res.set('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.set('Pragma', 'no-cache');
  res.json({ status: 'ok' });
});

// CDN + Browser
app.get('/api/config', (req, res) => {
  res.set('Cache-Control', 'public, s-maxage=86400, max-age=3600');
  res.json({ config: {...} });
});
```

### 8.2.5 - Nginx Examples

```nginx
http {
    # Static assets (versioned)
    location ~* \.(css|js|jpg|png|gif|ico|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # HTML
    location ~* \.html$ {
        add_header Cache-Control "no-cache";
    }
    
    # API
    location /api/public/ {
        add_header Cache-Control "public, max-age=60";
        proxy_pass http://backend;
    }
    
    location /api/user/ {
        add_header Cache-Control "private, max-age=300";
        proxy_pass http://backend;
    }
    
    # Disable cache
    location /api/payment/ {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache";
        proxy_pass http://backend;
    }
}
```

## 8.3 Validazione della Cache (Conditional Requests)

### 8.3.1 - ETag (Entity Tag)

**Identificatore univoco di una risorsa.**

**Strong ETag:**
```http
ETag: "33a64df551425fcc55e4d42a148795d9f25f89d4"
# Hash MD5/SHA del contenuto
# Byte-by-byte identico
```

**Weak ETag:**
```http
ETag: W/"33a64df551425fcc55e4d42a148795d9f25f89d4"
# Semanticamente equivalente
# Può differire leggermente (whitespace, compressione)
```

**Flow con ETag:**

**Prima richiesta:**
```http
GET /api/user/123 HTTP/1.1

→ HTTP/1.1 200 OK
  ETag: "abc123"
  Cache-Control: max-age=60
  
  {"id": 123, "name": "Mario"}
```

**Richiesta successiva (dopo scadenza):**
```http
GET /api/user/123 HTTP/1.1
If-None-Match: "abc123"

→ HTTP/1.1 304 Not Modified
  ETag: "abc123"
  # Nessun body, usa cache locale
```

**Se modificato:**
```http
GET /api/user/123 HTTP/1.1
If-None-Match: "abc123"

→ HTTP/1.1 200 OK
  ETag: "def456"
  
  {"id": 123, "name": "Mario Rossi"}
```

**Express.js ETag:**
```javascript
const crypto = require('crypto');

// Automatic ETag (default)
app.get('/api/user/:id', (req, res) => {
  const user = getUser(req.params.id);
  res.json(user);
  // Express genera automaticamente ETag
});

// Custom ETag
app.get('/api/data', (req, res) => {
  const data = getData();
  const etag = crypto
    .createHash('md5')
    .update(JSON.stringify(data))
    .digest('hex');
  
  res.set('ETag', `"${etag}"`);
  
  if (req.get('If-None-Match') === `"${etag}"`) {
    return res.status(304).end();
  }
  
  res.json(data);
});

// Disable ETag
app.set('etag', false);
```

### 8.3.2 - Last-Modified

**Data ultima modifica risorsa.**

**Flow con Last-Modified:**

**Prima richiesta:**
```http
GET /document.pdf HTTP/1.1

→ HTTP/1.1 200 OK
  Last-Modified: Wed, 15 Mar 2025 10:30:00 GMT
  Cache-Control: max-age=3600
  
  [PDF data]
```

**Richiesta successiva:**
```http
GET /document.pdf HTTP/1.1
If-Modified-Since: Wed, 15 Mar 2025 10:30:00 GMT

→ HTTP/1.1 304 Not Modified
  Last-Modified: Wed, 15 Mar 2025 10:30:00 GMT
  # Nessun body
```

**Se modificato:**
```http
GET /document.pdf HTTP/1.1
If-Modified-Since: Wed, 15 Mar 2025 10:30:00 GMT

→ HTTP/1.1 200 OK
  Last-Modified: Wed, 15 Mar 2025 14:00:00 GMT
  
  [PDF data aggiornato]
```

**Express.js Last-Modified:**
```javascript
const fs = require('fs');

app.get('/document/:id', (req, res) => {
  const filePath = `/path/to/${req.params.id}.pdf`;
  const stats = fs.statSync(filePath);
  const lastModified = stats.mtime.toUTCString();
  
  res.set('Last-Modified', lastModified);
  
  const ifModifiedSince = req.get('If-Modified-Since');
  if (ifModifiedSince && new Date(ifModifiedSince) >= stats.mtime) {
    return res.status(304).end();
  }
  
  res.sendFile(filePath);
});
```

**Nginx:**
```nginx
location /documents/ {
    # Nginx aggiunge automaticamente Last-Modified per file statici
    add_header Cache-Control "public, max-age=3600";
}
```

### 8.3.3 - ETag vs Last-Modified

| ETag | Last-Modified |
|------|---------------|
| Basato su contenuto | Basato su timestamp |
| Più accurato | Meno accurato (precisione 1 sec) |
| Funziona per contenuto dinamico | Meglio per file statici |
| Overhead computazionale (hash) | Leggero (solo timestamp) |
| Strong/Weak validation | Solo timestamp |

**Best practice: Usa entrambi**
```http
HTTP/1.1 200 OK
ETag: "abc123"
Last-Modified: Wed, 15 Mar 2025 10:30:00 GMT
Cache-Control: max-age=3600
```

Client invia entrambi:
```http
GET /resource HTTP/1.1
If-None-Match: "abc123"
If-Modified-Since: Wed, 15 Mar 2025 10:30:00 GMT
```

Server controlla ETag prima (più preciso), fallback su Last-Modified.

## 8.4 Strategie di Caching

### 8.4.1 - Cache-First

```
Request → Cache?
├─ Hit → Return cached
└─ Miss → Server → Cache → Return
```

**Uso:** Static assets, raramente modificati

```javascript
// Service Worker
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then(response => response || fetch(event.request))
  );
});
```

### 8.4.2 - Network-First

```
Request → Network
├─ Success → Cache → Return
└─ Fail → Cache → Return (fallback)
```

**Uso:** Contenuto dinamico con offline fallback

```javascript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then(response => {
        const clone = response.clone();
        caches.open('v1').then(cache => cache.put(event.request, clone));
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
```

### 8.4.3 - Stale-While-Revalidate

```
Request → Return cached immediately
       → Update cache in background
```

**Uso:** Balance tra freschezza e performance

```http
Cache-Control: max-age=60, stale-while-revalidate=86400
# Usa cache per 60s
# Se stale, ritorna cache ma aggiorna in background per 24h
```

```javascript
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.open('v1').then(cache => {
      return cache.match(event.request).then(cached => {
        const fetchPromise = fetch(event.request).then(response => {
          cache.put(event.request, response.clone());
          return response;
        });
        
        return cached || fetchPromise;
      });
    })
  );
});
```

### 8.4.4 - Cache Busting

**Versioning in filename:**
```html
<!-- Ogni deploy, nuovo hash -->
<link rel="stylesheet" href="/css/style.abc123.css">
<script src="/js/app.def456.js"></script>
```

```http
Cache-Control: public, max-age=31536000, immutable
# Cache infinita, nuovo file = nuovo URL
```

**Query string (meno preferito):**
```html
<link rel="stylesheet" href="/css/style.css?v=123">
<script src="/js/app.js?v=456"></script>
```

**Webpack config:**
```javascript
module.exports = {
  output: {
    filename: '[name].[contenthash].js',
    chunkFilename: '[name].[contenthash].js'
  }
};
```

## 8.5 CDN Caching

### 8.5.1 - CDN Cache Headers

```http
HTTP/1.1 200 OK
Cache-Control: public, s-maxage=86400, max-age=3600
CDN-Cache-Control: max-age=2592000
# CDN: 30 giorni
# Browser: 1 ora
```

**CloudFlare:**
```http
Cache-Control: public, max-age=14400
CF-Cache-Status: HIT
# HIT: Servito da cache
# MISS: Fetch da origin
# EXPIRED: Cache scaduta, revalidato
# BYPASS: Non cacheable
```

**Cloudflare Page Rules:**
```
Cache Level: Cache Everything
Edge Cache TTL: 1 month
Browser Cache TTL: 4 hours
```

### 8.5.2 - Purge Cache

**Cloudflare API:**
```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"files":["https://example.com/style.css"]}'
```

**Nginx FastCGI Cache Purge:**
```nginx
location ~ /purge(/.*) {
    fastcgi_cache_purge cache_zone "$scheme$request_method$host$1";
}
```

```bash
curl http://example.com/purge/api/data
```

## 8.6 Redis Cache (Application Level)

```javascript
const redis = require('redis');
const client = redis.createClient();

// Cache middleware
const cache = (duration) => {
  return async (req, res, next) => {
    const key = `cache:${req.originalUrl}`;
    
    const cached = await client.get(key);
    if (cached) {
      return res.json(JSON.parse(cached));
    }
    
    res.originalJson = res.json;
    res.json = (data) => {
      client.setex(key, duration, JSON.stringify(data));
      res.originalJson(data);
    };
    
    next();
  };
};

// Uso
app.get('/api/products', cache(60), (req, res) => {
  const products = getProducts();
  res.json(products);
  // Cachato per 60 secondi
});

// Invalidation
app.post('/api/products', async (req, res) => {
  const product = createProduct(req.body);
  
  // Invalida cache
  await client.del('cache:/api/products');
  
  res.json(product);
});
```

## 8.7 Best Practices

### 8.7.1 - Cache Strategy per Tipo di Risorsa

**HTML:**
```http
Cache-Control: no-cache
# Sempre revalidare
```

**CSS/JS (versioned):**
```http
Cache-Control: public, max-age=31536000, immutable
```

**Images (versioned):**
```http
Cache-Control: public, max-age=31536000, immutable
```

**Images (non-versioned):**
```http
Cache-Control: public, max-age=2592000
# 30 giorni
```

**Fonts:**
```http
Cache-Control: public, max-age=31536000, immutable
```

**API (public data):**
```http
Cache-Control: public, max-age=60
```

**API (user data):**
```http
Cache-Control: private, max-age=300
```

**API (sensitive):**
```http
Cache-Control: no-store
```

### 8.7.2 - Vary Header

```http
Vary: Accept-Encoding, Accept-Language
# Cache separata per encoding e language
```

**Esempio:**
```http
GET / HTTP/1.1
Accept-Encoding: gzip
Accept-Language: it

→ HTTP/1.1 200 OK
  Vary: Accept-Encoding, Accept-Language
  Content-Encoding: gzip
  # Cachato per: gzip + it
```

```http
GET / HTTP/1.1
Accept-Encoding: br
Accept-Language: en

→ HTTP/1.1 200 OK
  Vary: Accept-Encoding, Accept-Language
  Content-Encoding: br
  # Cache separata: br + en
```

### 8.7.3 - Cache Checklist

✅ **DO:**
- Usa versioning per static assets
- Imposta `immutable` per versioned files
- Usa ETag + Last-Modified insieme
- Imposta `Vary` per content negotiation
- Usa CDN per static assets
- Monitora cache hit rate
- Testa cache con browser DevTools

❌ **DON'T:**
- Non cachare dati sensibili
- Non usare query string per versioning (usa filename)
- Non dimenticare `Vary` con compressione
- Non usare cache per POST/PUT/DELETE
- Non fare over-caching (bilanciare freschezza)

---

**Capitolo 8 completato!**

Prossimo: **Capitolo 9 - Autenticazione e Autorizzazione**
