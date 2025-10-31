# 37. HTTP Caching Avanzato

## 37.1 Introduzione al Caching Avanzato

**HTTP caching** migliora le performance riducendo la latenza e il carico sul server.

**Livelli di cache:**

```
1. Browser Cache
   - Cache locale nel browser
   - Gestita da Cache-Control headers

2. Proxy Cache (Shared Cache)
   - Cache condivisa tra più utenti
   - CDN, reverse proxy (Nginx, Varnish)

3. Gateway Cache
   - Cache a livello di API gateway
   - Redis, Memcached

4. Application Cache
   - Cache a livello applicazione
   - In-memory cache (Node.js)
```

**Strategie di caching:**

```
- Cache-First: Usa cache se disponibile
- Network-First: Prova rete, poi cache
- Cache-Only: Solo dalla cache
- Network-Only: Solo dalla rete
- Stale-While-Revalidate: Usa cache stale mentre rivalidati
```

---

## 37.2 Cache-Control Avanzato

### 37.2.1 - Direttive Cache-Control

**Tutte le direttive:**

```http
Cache-Control: max-age=3600
   → Cache valida per 3600 secondi (1 ora)

Cache-Control: s-maxage=7200
   → Max age per shared cache (CDN, proxy)
   → Sovrascrive max-age per cache condivise

Cache-Control: private
   → Solo browser cache, non proxy/CDN
   → Per dati utente specifici

Cache-Control: public
   → Cache anche da proxy/CDN
   → Anche con Authorization header

Cache-Control: no-cache
   → Rivalidare sempre con server
   → Può usare cache dopo validazione

Cache-Control: no-store
   → Non salvare mai in cache
   → Per dati sensibili

Cache-Control: must-revalidate
   → Non usare cache stale
   → Rivalidare se scaduta

Cache-Control: proxy-revalidate
   → must-revalidate solo per proxy

Cache-Control: immutable
   → Non rivalidare mai
   → Per file con hash nel nome

Cache-Control: stale-while-revalidate=60
   → Usa cache stale per 60s mentre rivalidati

Cache-Control: stale-if-error=86400
   → Usa cache stale se server in errore
```

### 37.2.2 - Combinazioni Cache-Control

**Esempi pratici:**

```javascript
const express = require('express');
const app = express();

// Static assets (JS, CSS, images con hash)
app.use('/static', (req, res, next) => {
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    next();
}, express.static('public'));

// API responses (5 minuti, private)
app.get('/api/user/:id', (req, res) => {
    res.setHeader('Cache-Control', 'private, max-age=300');
    res.json({ id: req.params.id, name: 'John Doe' });
});

// HTML pages (rivalidare sempre)
app.get('/page', (req, res) => {
    res.setHeader('Cache-Control', 'no-cache, must-revalidate');
    res.send('<html>...</html>');
});

// Shared cache con stale-while-revalidate
app.get('/api/public/stats', (req, res) => {
    res.setHeader('Cache-Control', 'public, max-age=60, stale-while-revalidate=30');
    res.json({ views: 1000, users: 50 });
});

// No cache per dati sensibili
app.get('/api/account/balance', authenticate, (req, res) => {
    res.setHeader('Cache-Control', 'no-store, private');
    res.json({ balance: 1500.00 });
});

// CDN cache con fallback
app.get('/api/content', (req, res) => {
    res.setHeader('Cache-Control', 'public, max-age=300, s-maxage=3600, stale-if-error=86400');
    res.json({ content: 'Data...' });
});

app.listen(3000);
```

---

## 37.3 ETag e Validazione

### 37.3.1 - Strong vs Weak ETags

**Strong ETag:**

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();

app.get('/api/resource', (req, res) => {
    const data = { id: 1, value: 'Important data' };
    const content = JSON.stringify(data);
    
    // Strong ETag: hash del contenuto
    const etag = crypto
        .createHash('md5')
        .update(content)
        .digest('hex');
    
    res.setHeader('ETag', `"${etag}"`);  // Strong ETag
    res.setHeader('Cache-Control', 'no-cache');
    
    // Check If-None-Match
    const ifNoneMatch = req.headers['if-none-match'];
    
    if (ifNoneMatch === `"${etag}"`) {
        // Content not modified
        console.log('304 Not Modified');
        return res.status(304).end();
    }
    
    res.json(data);
});

app.listen(3000);
```

**Weak ETag:**

```javascript
app.get('/api/timestamp', (req, res) => {
    const data = { 
        time: new Date().toISOString(),
        value: Math.floor(Date.now() / 1000)  // Cambia ogni secondo
    };
    
    const content = JSON.stringify(data);
    
    // Weak ETag: hash solo del valore (ignora time)
    const etag = crypto
        .createHash('md5')
        .update(String(data.value))
        .digest('hex');
    
    res.setHeader('ETag', `W/"${etag}"`);  // Weak ETag (prefisso W/)
    res.setHeader('Cache-Control', 'no-cache');
    
    const ifNoneMatch = req.headers['if-none-match'];
    
    if (ifNoneMatch === `W/"${etag}"` || ifNoneMatch === `"${etag}"`) {
        return res.status(304).end();
    }
    
    res.json(data);
});
```

### 37.3.2 - Last-Modified

**Validazione con timestamp:**

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

app.get('/document/:id', (req, res) => {
    const filepath = path.join('documents', `${req.params.id}.json`);
    
    if (!fs.existsSync(filepath)) {
        return res.status(404).json({ error: 'Not found' });
    }
    
    const stats = fs.statSync(filepath);
    const lastModified = stats.mtime.toUTCString();
    
    res.setHeader('Last-Modified', lastModified);
    res.setHeader('Cache-Control', 'no-cache');
    
    // Check If-Modified-Since
    const ifModifiedSince = req.headers['if-modified-since'];
    
    if (ifModifiedSince && ifModifiedSince === lastModified) {
        console.log('304 Not Modified (Last-Modified)');
        return res.status(304).end();
    }
    
    const content = fs.readFileSync(filepath, 'utf8');
    res.json(JSON.parse(content));
});

app.listen(3000);
```

### 37.3.3 - ETag + Last-Modified

**Combina entrambi i metodi:**

```javascript
const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();

app.get('/file/:name', (req, res) => {
    const filepath = path.join('files', req.params.name);
    
    if (!fs.existsSync(filepath)) {
        return res.status(404).send('Not found');
    }
    
    const stats = fs.statSync(filepath);
    const content = fs.readFileSync(filepath);
    
    // Last-Modified
    const lastModified = stats.mtime.toUTCString();
    
    // ETag
    const etag = `"${crypto.createHash('md5').update(content).digest('hex')}"`;
    
    res.setHeader('Last-Modified', lastModified);
    res.setHeader('ETag', etag);
    res.setHeader('Cache-Control', 'no-cache');
    
    // Check If-None-Match (priorità su If-Modified-Since)
    const ifNoneMatch = req.headers['if-none-match'];
    const ifModifiedSince = req.headers['if-modified-since'];
    
    if (ifNoneMatch) {
        if (ifNoneMatch === etag) {
            return res.status(304).end();
        }
    } else if (ifModifiedSince) {
        if (ifModifiedSince === lastModified) {
            return res.status(304).end();
        }
    }
    
    res.send(content);
});

app.listen(3000);
```

---

## 37.4 Vary Header

### 37.4.1 - Cache Variante

**Vary header specifica quali request headers influenzano la cache:**

```javascript
const express = require('express');
const app = express();

// Vary by Accept-Language
app.get('/content', (req, res) => {
    const lang = req.headers['accept-language']?.split(',')[0] || 'en';
    
    res.setHeader('Vary', 'Accept-Language');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    
    const content = {
        en: 'Hello',
        it: 'Ciao',
        es: 'Hola'
    };
    
    res.json({ message: content[lang] || content.en });
});

// Vary by Accept (JSON vs XML)
app.get('/api/data', (req, res) => {
    res.setHeader('Vary', 'Accept');
    res.setHeader('Cache-Control', 'public, max-age=600');
    
    const data = { id: 1, value: 'Data' };
    
    res.format({
        'application/json': () => {
            res.json(data);
        },
        'application/xml': () => {
            res.type('xml').send(`<data><id>1</id><value>Data</value></data>`);
        }
    });
});

// Vary by multiple headers
app.get('/page', (req, res) => {
    res.setHeader('Vary', 'Accept-Encoding, Accept-Language, User-Agent');
    res.setHeader('Cache-Control', 'public, max-age=1800');
    
    res.send('<html>...</html>');
});

// Vary: * (non cacheable)
app.get('/dynamic', (req, res) => {
    res.setHeader('Vary', '*');
    res.json({ random: Math.random() });
});

app.listen(3000);
```

### 37.4.2 - Vary e Compression

**Vary con Accept-Encoding:**

```javascript
const express = require('express');
const compression = require('compression');

const app = express();

// Compression middleware aggiunge automaticamente Vary: Accept-Encoding
app.use(compression());

app.get('/large-data', (req, res) => {
    // compression middleware gestisce Vary automaticamente
    res.setHeader('Cache-Control', 'public, max-age=3600');
    
    const largeData = {
        items: Array.from({ length: 1000 }, (_, i) => ({
            id: i,
            value: `Item ${i}`
        }))
    };
    
    res.json(largeData);
});

app.listen(3000);
```

---

## 37.5 CDN e Reverse Proxy Cache

### 37.5.1 - Nginx Cache

**Configurazione Nginx proxy cache:**

```nginx
# nginx.conf

http {
    # Cache path
    proxy_cache_path /var/cache/nginx 
                     levels=1:2 
                     keys_zone=my_cache:10m 
                     max_size=1g 
                     inactive=60m 
                     use_temp_path=off;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            proxy_pass http://localhost:3000;
            
            # Enable cache
            proxy_cache my_cache;
            
            # Cache key
            proxy_cache_key "$scheme$request_method$host$request_uri";
            
            # Cache status header
            add_header X-Cache-Status $upstream_cache_status;
            
            # Cache methods
            proxy_cache_methods GET HEAD;
            
            # Cache valid time
            proxy_cache_valid 200 302 10m;
            proxy_cache_valid 404 1m;
            
            # Cache bypass
            proxy_cache_bypass $http_cache_control;
            
            # Headers to pass
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        # Static files con cache lunga
        location /static/ {
            proxy_pass http://localhost:3000;
            proxy_cache my_cache;
            proxy_cache_valid 200 1y;
            add_header Cache-Control "public, immutable";
            add_header X-Cache-Status $upstream_cache_status;
        }
        
        # API con cache breve
        location /api/ {
            proxy_pass http://localhost:3000;
            proxy_cache my_cache;
            proxy_cache_valid 200 5m;
            proxy_cache_key "$scheme$request_method$host$request_uri$http_authorization";
            add_header X-Cache-Status $upstream_cache_status;
        }
        
        # Purge cache endpoint
        location ~ /purge(/.*) {
            allow 127.0.0.1;
            deny all;
            proxy_cache_purge my_cache "$scheme$request_method$host$1";
        }
    }
}
```

### 37.5.2 - Cache Purge/Invalidation

**Invalidare cache manualmente:**

```javascript
const express = require('express');
const axios = require('axios');

const app = express();

// Update resource
app.put('/api/resource/:id', async (req, res) => {
    const { id } = req.params;
    
    // Update resource in database
    // ...
    
    // Purge Nginx cache
    try {
        await axios.request({
            method: 'PURGE',
            url: `http://localhost/purge/api/resource/${id}`,
            headers: { 'X-Real-IP': '127.0.0.1' }
        });
        
        console.log(`Cache purged for resource ${id}`);
    } catch (error) {
        console.error('Cache purge failed:', error.message);
    }
    
    res.json({ message: 'Resource updated' });
});

// Purge all cache
app.post('/admin/purge-cache', authenticate, async (req, res) => {
    try {
        // Delete Nginx cache directory
        const { exec } = require('child_process');
        exec('rm -rf /var/cache/nginx/*', (error) => {
            if (error) {
                console.error('Cache purge failed:', error);
                return res.status(500).json({ error: 'Purge failed' });
            }
            res.json({ message: 'Cache purged successfully' });
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(3000);
```

---

## 37.6 Service Worker Cache

### 37.6.1 - Cache Strategies

**Service Worker con cache strategies:**

```javascript
// service-worker.js

const CACHE_NAME = 'v1';
const STATIC_CACHE = 'static-v1';
const DYNAMIC_CACHE = 'dynamic-v1';

const STATIC_ASSETS = [
    '/',
    '/index.html',
    '/styles.css',
    '/app.js',
    '/offline.html'
];

// Install event
self.addEventListener('install', event => {
    console.log('Service Worker installing...');
    
    event.waitUntil(
        caches.open(STATIC_CACHE)
            .then(cache => {
                console.log('Caching static assets');
                return cache.addAll(STATIC_ASSETS);
            })
    );
});

// Activate event
self.addEventListener('activate', event => {
    console.log('Service Worker activating...');
    
    event.waitUntil(
        caches.keys().then(keys => {
            return Promise.all(
                keys
                    .filter(key => key !== STATIC_CACHE && key !== DYNAMIC_CACHE)
                    .map(key => caches.delete(key))
            );
        })
    );
});

// Fetch event - Cache strategies
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);
    
    // Cache-First strategy (static assets)
    if (request.destination === 'style' || 
        request.destination === 'script' || 
        request.destination === 'image') {
        
        event.respondWith(
            caches.match(request)
                .then(cached => {
                    if (cached) {
                        console.log('Cache hit:', request.url);
                        return cached;
                    }
                    
                    return fetch(request).then(response => {
                        return caches.open(DYNAMIC_CACHE).then(cache => {
                            cache.put(request, response.clone());
                            return response;
                        });
                    });
                })
        );
    }
    
    // Network-First strategy (API)
    else if (url.pathname.startsWith('/api/')) {
        event.respondWith(
            fetch(request)
                .then(response => {
                    const clone = response.clone();
                    caches.open(DYNAMIC_CACHE).then(cache => {
                        cache.put(request, clone);
                    });
                    return response;
                })
                .catch(() => {
                    return caches.match(request)
                        .then(cached => cached || caches.match('/offline.html'));
                })
        );
    }
    
    // Stale-While-Revalidate (HTML pages)
    else {
        event.respondWith(
            caches.match(request)
                .then(cached => {
                    const fetchPromise = fetch(request).then(response => {
                        caches.open(DYNAMIC_CACHE).then(cache => {
                            cache.put(request, response.clone());
                        });
                        return response;
                    });
                    
                    return cached || fetchPromise;
                })
        );
    }
});
```

### 37.6.2 - Cache API Manual Control

**Controllo manuale della cache:**

```javascript
// app.js

// Register Service Worker
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/service-worker.js')
        .then(reg => console.log('Service Worker registered'))
        .catch(err => console.error('SW registration failed:', err));
}

// Manual cache control
async function cacheResource(url) {
    const cache = await caches.open('my-cache');
    const response = await fetch(url);
    await cache.put(url, response);
    console.log('Cached:', url);
}

async function getCachedResource(url) {
    const cache = await caches.open('my-cache');
    const cached = await cache.match(url);
    
    if (cached) {
        console.log('Cache hit:', url);
        return cached;
    }
    
    console.log('Cache miss:', url);
    const response = await fetch(url);
    await cache.put(url, response.clone());
    return response;
}

async function deleteCachedResource(url) {
    const cache = await caches.open('my-cache');
    const deleted = await cache.delete(url);
    console.log('Cache deleted:', url, deleted);
}

async function clearAllCache() {
    const keys = await caches.keys();
    await Promise.all(keys.map(key => caches.delete(key)));
    console.log('All caches cleared');
}

// Usage
cacheResource('/api/data');
const response = await getCachedResource('/api/data');
```

---

## 37.7 Redis Cache

### 37.7.1 - API Cache con Redis

**Cache API responses in Redis:**

```javascript
const express = require('express');
const redis = require('redis');
const { promisify } = require('util');

const app = express();

// Redis client
const redisClient = redis.createClient({
    host: 'localhost',
    port: 6379
});

const getAsync = promisify(redisClient.get).bind(redisClient);
const setAsync = promisify(redisClient.setex).bind(redisClient);

// Cache middleware
function cache(duration) {
    return async (req, res, next) => {
        const key = `cache:${req.originalUrl}`;
        
        try {
            const cached = await getAsync(key);
            
            if (cached) {
                console.log('Redis cache hit:', key);
                res.setHeader('X-Cache', 'HIT');
                return res.json(JSON.parse(cached));
            }
            
            console.log('Redis cache miss:', key);
            res.setHeader('X-Cache', 'MISS');
            
            // Override res.json to cache response
            const originalJson = res.json.bind(res);
            res.json = (data) => {
                setAsync(key, duration, JSON.stringify(data))
                    .then(() => console.log('Cached in Redis:', key))
                    .catch(err => console.error('Redis cache error:', err));
                
                return originalJson(data);
            };
            
            next();
            
        } catch (error) {
            console.error('Redis error:', error);
            next();
        }
    };
}

// API endpoints with cache
app.get('/api/users', cache(300), async (req, res) => {
    // Simulate database query
    const users = [
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' }
    ];
    
    res.json(users);
});

app.get('/api/user/:id', cache(600), async (req, res) => {
    const user = { id: req.params.id, name: 'John Doe' };
    res.json(user);
});

// Invalidate cache
app.post('/api/user/:id', async (req, res) => {
    const { id } = req.params;
    
    // Update user in database
    // ...
    
    // Invalidate cache
    const key = `cache:/api/user/${id}`;
    redisClient.del(key, (err, result) => {
        if (err) console.error('Cache invalidation error:', err);
        else console.log('Cache invalidated:', key);
    });
    
    res.json({ message: 'User updated' });
});

app.listen(3000);
```

### 37.7.2 - Cache Pattern con TTL

**Advanced Redis caching patterns:**

```javascript
const express = require('express');
const redis = require('redis');
const { promisify } = require('util');

const app = express();

const redisClient = redis.createClient();
const getAsync = promisify(redisClient.get).bind(redisClient);
const setexAsync = promisify(redisClient.setex).bind(redisClient);
const delAsync = promisify(redisClient.del).bind(redisClient);
const keysAsync = promisify(redisClient.keys).bind(redisClient);

// Cache helper class
class Cache {
    static async get(key) {
        const data = await getAsync(key);
        return data ? JSON.parse(data) : null;
    }
    
    static async set(key, value, ttl = 300) {
        await setexAsync(key, ttl, JSON.stringify(value));
    }
    
    static async delete(key) {
        await delAsync(key);
    }
    
    static async deletePattern(pattern) {
        const keys = await keysAsync(pattern);
        if (keys.length > 0) {
            await Promise.all(keys.map(key => delAsync(key)));
        }
        return keys.length;
    }
    
    static async getOrSet(key, fetchFn, ttl = 300) {
        let data = await this.get(key);
        
        if (!data) {
            data = await fetchFn();
            await this.set(key, data, ttl);
        }
        
        return data;
    }
}

// Usage
app.get('/api/products', async (req, res) => {
    const cacheKey = 'products:all';
    
    const products = await Cache.getOrSet(
        cacheKey,
        async () => {
            // Simulate database query
            console.log('Fetching from database...');
            return [
                { id: 1, name: 'Product 1', price: 100 },
                { id: 2, name: 'Product 2', price: 200 }
            ];
        },
        600  // TTL 10 minutes
    );
    
    res.json(products);
});

app.get('/api/product/:id', async (req, res) => {
    const { id } = req.params;
    const cacheKey = `product:${id}`;
    
    const product = await Cache.getOrSet(
        cacheKey,
        async () => {
            console.log(`Fetching product ${id} from database...`);
            return { id, name: `Product ${id}`, price: 100 };
        },
        1800  // TTL 30 minutes
    );
    
    res.json(product);
});

app.put('/api/product/:id', async (req, res) => {
    const { id } = req.params;
    
    // Update product
    // ...
    
    // Invalidate cache
    await Cache.delete(`product:${id}`);
    await Cache.delete('products:all');
    
    res.json({ message: 'Product updated' });
});

app.delete('/api/products', async (req, res) => {
    // Delete all products cache
    const deleted = await Cache.deletePattern('product:*');
    
    res.json({ message: `Deleted ${deleted} cache entries` });
});

app.listen(3000);
```

---

## 37.8 Production Best Practices

### 37.8.1 - Complete Caching Strategy

**Full production caching system:**

```javascript
const express = require('express');
const redis = require('redis');
const crypto = require('crypto');
const compression = require('compression');
const helmet = require('helmet');

const app = express();

// Middleware
app.use(compression());
app.use(helmet());
app.use(express.json());

// Redis client
const redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    retry_strategy: (options) => {
        if (options.error && options.error.code === 'ECONNREFUSED') {
            return new Error('Redis connection refused');
        }
        if (options.total_retry_time > 1000 * 60 * 60) {
            return new Error('Redis retry time exhausted');
        }
        if (options.attempt > 10) {
            return undefined;
        }
        return Math.min(options.attempt * 100, 3000);
    }
});

const { promisify } = require('util');
const getAsync = promisify(redisClient.get).bind(redisClient);
const setexAsync = promisify(redisClient.setex).bind(redisClient);

// ETag generator
function generateETag(data) {
    return crypto
        .createHash('md5')
        .update(JSON.stringify(data))
        .digest('hex');
}

// Cache middleware with ETag
function cacheWithETag(ttl = 300) {
    return async (req, res, next) => {
        const cacheKey = `cache:${req.originalUrl}`;
        
        try {
            const cached = await getAsync(cacheKey);
            
            if (cached) {
                const { data, etag } = JSON.parse(cached);
                
                // Check If-None-Match
                if (req.headers['if-none-match'] === etag) {
                    res.setHeader('ETag', etag);
                    res.setHeader('X-Cache', 'HIT-304');
                    return res.status(304).end();
                }
                
                res.setHeader('ETag', etag);
                res.setHeader('X-Cache', 'HIT');
                res.setHeader('Cache-Control', `public, max-age=${ttl}`);
                return res.json(data);
            }
            
            res.setHeader('X-Cache', 'MISS');
            
            const originalJson = res.json.bind(res);
            res.json = (data) => {
                const etag = `"${generateETag(data)}"`;
                
                res.setHeader('ETag', etag);
                res.setHeader('Cache-Control', `public, max-age=${ttl}`);
                
                setexAsync(
                    cacheKey,
                    ttl,
                    JSON.stringify({ data, etag })
                ).catch(err => console.error('Redis cache error:', err));
                
                return originalJson(data);
            };
            
            next();
            
        } catch (error) {
            console.error('Cache middleware error:', error);
            next();
        }
    };
}

// Static assets (immutable)
app.use('/static', (req, res, next) => {
    res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    next();
}, express.static('public'));

// API with cache
app.get('/api/public/stats', cacheWithETag(60), async (req, res) => {
    const stats = {
        users: 1000,
        posts: 5000,
        comments: 15000
    };
    
    res.json(stats);
});

// Private API (no cache)
app.get('/api/private/account', authenticate, (req, res) => {
    res.setHeader('Cache-Control', 'private, no-store');
    res.json({ balance: 1000, email: 'user@example.com' });
});

// HTML pages (no-cache, must-revalidate)
app.get('/', (req, res) => {
    res.setHeader('Cache-Control', 'no-cache, must-revalidate');
    res.setHeader('Vary', 'Accept-Encoding, Accept-Language');
    res.send('<html>...</html>');
});

// Cache invalidation
app.post('/api/invalidate', authenticate, async (req, res) => {
    const { pattern } = req.body;
    
    const { promisify } = require('util');
    const keysAsync = promisify(redisClient.keys).bind(redisClient);
    const delAsync = promisify(redisClient.del).bind(redisClient);
    
    const keys = await keysAsync(pattern || 'cache:*');
    
    if (keys.length > 0) {
        await Promise.all(keys.map(key => delAsync(key)));
    }
    
    res.json({ 
        message: 'Cache invalidated',
        deleted: keys.length
    });
});

// Health check
app.get('/health', (req, res) => {
    redisClient.ping((err, reply) => {
        if (err || reply !== 'PONG') {
            return res.status(503).json({ 
                status: 'unhealthy',
                redis: 'disconnected'
            });
        }
        
        res.json({ 
            status: 'healthy',
            redis: 'connected'
        });
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

---

**Capitolo 37 completato!** Il caching HTTP avanzato con Cache-Control, ETag, Vary, Redis, Service Worker e strategie di cache per massimizzare le performance! 🚀
