# 29. HTTP/2 Server Push

## 29.1 Introduzione

**HTTP/2 Server Push** permette al server di inviare risorse al client **prima** che vengano richieste, anticipando i bisogni del browser.

**Traditional HTTP/1.1 flow:**

```
1. Client → GET /index.html
2. Server → 200 OK (HTML)
3. Client parses HTML, discovers style.css
4. Client → GET /style.css
5. Server → 200 OK (CSS)
6. Client parses HTML, discovers script.js
7. Client → GET /script.js
8. Server → 200 OK (JS)

Total: 3 round-trips
```

**HTTP/2 Server Push flow:**

```
1. Client → GET /index.html
2. Server → PUSH_PROMISE /style.css
3. Server → PUSH_PROMISE /script.js
4. Server → 200 OK (HTML)
5. Server → 200 OK (CSS - pushed)
6. Server → 200 OK (JS - pushed)

Total: 1 round-trip!
```

**Vantaggi:**
- ⚡ **Faster page load:** Elimina round-trips
- 🚀 **Reduced latency:** Risorse critiche disponibili subito
- 📊 **Better resource utilization:** Server sa cosa serve
- 🎯 **Optimized critical path:** Priorità risorse critiche

**Limitazioni:**
- ⚠️ **Cache blindness:** Server non sa cosa è in cache
- 📈 **Bandwidth waste:** Rischio di push inutili
- 🔍 **Complex to configure:** Richiede analisi dependencies
- 🌐 **Browser support:** Non tutti i browser supportano bene

---

## 29.2 Come Funziona Server Push

### 29.2.1 - PUSH_PROMISE Frame

**HTTP/2 protocol:**

```
Client sends:
HEADERS frame
  :method: GET
  :path: /index.html
  :scheme: https
  :authority: example.com

Server sends:
PUSH_PROMISE frame (stream 2)
  :method: GET
  :path: /styles.css
  :scheme: https
  :authority: example.com

PUSH_PROMISE frame (stream 4)
  :method: GET
  :path: /script.js

HEADERS frame (stream 1 - original request)
  :status: 200
  content-type: text/html

DATA frame (stream 1)
  <html>...</html>

HEADERS frame (stream 2 - pushed)
  :status: 200
  content-type: text/css

DATA frame (stream 2)
  body { ... }

HEADERS frame (stream 4 - pushed)
  :status: 200
  content-type: application/javascript

DATA frame (stream 4)
  console.log('pushed');
```

### 29.2.2 - Client Can Reject Push

**RST_STREAM to cancel unwanted push:**

```
Server → PUSH_PROMISE /image.jpg

Client checks cache, already has image.jpg

Client → RST_STREAM (stream 2)
  error_code: CANCEL

Server stops sending pushed resource
```

---

## 29.3 Nginx Configuration

### 29.3.1 - Basic Server Push

**Nginx HTTP/2 push:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    
    root /var/www/html;
    
    location / {
        # Push critical resources when serving HTML
        http2_push /styles/critical.css;
        http2_push /js/app.js;
        
        index index.html;
    }
    
    location /styles/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    location /js/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### 29.3.2 - Conditional Push

**Push based on request:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    
    root /var/www/html;
    
    # Push for homepage
    location = / {
        http2_push /css/home.css;
        http2_push /js/home.js;
        http2_push /images/logo.svg;
        
        try_files /index.html =404;
    }
    
    # Push for product pages
    location ~ ^/products/ {
        http2_push /css/product.css;
        http2_push /js/product.js;
        
        try_files $uri $uri/index.html =404;
    }
    
    # No push for API
    location /api/ {
        proxy_pass http://backend;
    }
}
```

### 29.3.3 - Link Preload Headers

**Alternative to direct push (more flexible):**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    root /var/www/html;
    
    location = /index.html {
        # Add Link header with preload
        add_header Link "</styles/critical.css>; rel=preload; as=style";
        add_header Link "</js/app.js>; rel=preload; as=script";
        add_header Link "</fonts/main.woff2>; rel=preload; as=font; crossorigin";
        
        # Nginx 1.13.9+ automatically converts to HTTP/2 push
        http2_push_preload on;
    }
}
```

---

## 29.4 Node.js Implementation

### 29.4.1 - Node.js http2 Module

**Basic server push:**

```javascript
const http2 = require('http2');
const fs = require('fs');
const path = require('path');

const server = http2.createSecureServer({
    key: fs.readFileSync('server-key.pem'),
    cert: fs.readFileSync('server-cert.pem')
});

server.on('stream', (stream, headers) => {
    const reqPath = headers[':path'];
    
    console.log('Request:', reqPath);
    
    if (reqPath === '/') {
        // Push critical resources
        pushResource(stream, '/styles.css', 'text/css');
        pushResource(stream, '/script.js', 'application/javascript');
        
        // Respond with HTML
        stream.respond({
            ':status': 200,
            'content-type': 'text/html'
        });
        
        stream.end(fs.readFileSync('index.html'));
    } else {
        // Serve requested file
        const filePath = path.join(__dirname, 'public', reqPath);
        
        if (fs.existsSync(filePath)) {
            const contentType = getContentType(reqPath);
            
            stream.respond({
                ':status': 200,
                'content-type': contentType
            });
            
            stream.end(fs.readFileSync(filePath));
        } else {
            stream.respond({ ':status': 404 });
            stream.end('Not Found');
        }
    }
});

function pushResource(stream, path, contentType) {
    stream.pushStream({ ':path': path }, (err, pushStream) => {
        if (err) {
            console.error('Push error:', err);
            return;
        }
        
        pushStream.respond({
            ':status': 200,
            'content-type': contentType
        });
        
        const filePath = `public${path}`;
        pushStream.end(fs.readFileSync(filePath));
        
        console.log('Pushed:', path);
    });
}

function getContentType(filePath) {
    const ext = path.extname(filePath);
    const types = {
        '.html': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.svg': 'image/svg+xml'
    };
    return types[ext] || 'application/octet-stream';
}

server.listen(8443, () => {
    console.log('HTTP/2 server running on https://localhost:8443');
});
```

### 29.4.2 - Express.js with SPDY

**Using spdy module (HTTP/2 for Express):**

```bash
npm install spdy express
```

```javascript
const spdy = require('spdy');
const express = require('express');
const fs = require('fs');

const app = express();

// Middleware to push resources
const pushResources = (res, resources) => {
    if (res.push) {
        resources.forEach(({ path, contentType }) => {
            const stream = res.push(path, {
                status: 200,
                method: 'GET',
                request: {
                    accept: '*/*'
                },
                response: {
                    'content-type': contentType
                }
            });
            
            if (stream) {
                stream.on('error', (err) => {
                    console.error('Push stream error:', err);
                });
                
                const filePath = `public${path}`;
                stream.end(fs.readFileSync(filePath));
                
                console.log('Pushed:', path);
            }
        });
    }
};

// Homepage
app.get('/', (req, res) => {
    // Push critical resources
    pushResources(res, [
        { path: '/css/critical.css', contentType: 'text/css' },
        { path: '/js/app.js', contentType: 'application/javascript' },
        { path: '/fonts/main.woff2', contentType: 'font/woff2' }
    ]);
    
    res.sendFile(__dirname + '/public/index.html');
});

// Product page
app.get('/products/:id', (req, res) => {
    pushResources(res, [
        { path: '/css/product.css', contentType: 'text/css' },
        { path: '/js/product.js', contentType: 'application/javascript' }
    ]);
    
    res.sendFile(__dirname + '/public/product.html');
});

// Static files
app.use(express.static('public'));

// Create HTTPS/2 server
const options = {
    key: fs.readFileSync('server-key.pem'),
    cert: fs.readFileSync('server-cert.pem')
};

spdy.createServer(options, app).listen(8443, () => {
    console.log('SPDY server running on https://localhost:8443');
});
```

### 29.4.3 - Smart Push with Cookie

**Avoid pushing cached resources:**

```javascript
const spdy = require('spdy');
const express = require('express');
const fs = require('fs');

const app = express();

app.get('/', (req, res) => {
    // Check if resources already cached
    const hasResources = req.cookies && req.cookies.has_resources === 'true';
    
    if (!hasResources) {
        // First visit - push resources
        pushResources(res, [
            { path: '/css/critical.css', contentType: 'text/css' },
            { path: '/js/app.js', contentType: 'application/javascript' }
        ]);
        
        // Set cookie to indicate resources are cached
        res.cookie('has_resources', 'true', {
            maxAge: 24 * 60 * 60 * 1000, // 24 hours
            httpOnly: true
        });
    } else {
        console.log('Resources already cached, skipping push');
    }
    
    res.sendFile(__dirname + '/public/index.html');
});

app.use(express.static('public'));

const options = {
    key: fs.readFileSync('server-key.pem'),
    cert: fs.readFileSync('server-cert.pem')
};

spdy.createServer(options, app).listen(8443);
```

---

## 29.5 Apache Configuration

### 29.5.1 - mod_http2 Push

**Apache HTTP/2 push:**

```apache
# Enable HTTP/2
LoadModule http2_module modules/mod_http2.so

<VirtualHost *:443>
    ServerName example.com
    
    # Enable HTTP/2
    Protocols h2 http/1.1
    
    # SSL configuration
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
    
    DocumentRoot /var/www/html
    
    # Push resources for HTML files
    <FilesMatch "\.html$">
        # Push critical CSS and JS
        Header add Link "</css/critical.css>; rel=preload; as=style"
        Header add Link "</js/app.js>; rel=preload; as=script"
        Header add Link "</fonts/main.woff2>; rel=preload; as=font; crossorigin"
        
        # Enable automatic push from Link headers
        H2Push on
        H2PushPriority * after 16
    </FilesMatch>
    
    # Cache static assets
    <Directory "/var/www/html/static">
        Header set Cache-Control "public, max-age=31536000, immutable"
    </Directory>
</VirtualHost>
```

### 29.5.2 - Conditional Push

```apache
<VirtualHost *:443>
    ServerName example.com
    Protocols h2 http/1.1
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
    
    DocumentRoot /var/www/html
    
    # Homepage - push critical resources
    <Location "/">
        <If "%{REQUEST_URI} == '/' || %{REQUEST_URI} == '/index.html'">
            Header add Link "</css/home.css>; rel=preload; as=style"
            Header add Link "</js/home.js>; rel=preload; as=script"
            H2Push on
        </If>
    </Location>
    
    # Product pages
    <LocationMatch "^/products/">
        Header add Link "</css/product.css>; rel=preload; as=style"
        Header add Link "</js/product.js>; rel=preload; as=script"
        H2Push on
    </LocationMatch>
    
    # Don't push for API
    <Location "/api">
        H2Push off
    </Location>
</VirtualHost>
```

---

## 29.6 Optimization Strategies

### 29.6.1 - What to Push

**✅ PUSH:**

```
Critical rendering path resources:
- Critical CSS (above-the-fold styles)
- Essential JavaScript (needed for first render)
- Web fonts (used in visible text)
- Hero images (above the fold)

Characteristics:
- Small size (<50KB)
- High priority
- Always needed
- Not in cache (first visit)
```

**❌ DON'T PUSH:**

```
Non-critical resources:
- Large images
- Below-the-fold content
- Analytics scripts
- Social widgets
- Resources likely in cache

Risks:
- Bandwidth waste
- Blocks more important resources
- Client can't cancel large pushes efficiently
```

### 29.6.2 - Push Priority

**Nginx with priority:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    location = / {
        # Critical CSS - highest priority
        http2_push /css/critical.css;
        
        # Essential JS - high priority
        http2_push /js/app.js;
        
        # Font - medium priority
        http2_push /fonts/main.woff2;
        
        # Logo - lower priority
        http2_push /images/logo.svg;
    }
}
```

### 29.6.3 - Measure Push Effectiveness

**Chrome DevTools analysis:**

```javascript
// Check if resource was pushed
performance.getEntriesByType('resource').forEach(entry => {
    if (entry.nextHopProtocol === 'h2') {
        console.log(`${entry.name}:`, {
            pushed: entry.transferSize === 0 && entry.decodedBodySize > 0,
            size: entry.decodedBodySize,
            duration: entry.duration
        });
    }
});

// Output example:
// /css/critical.css: { pushed: true, size: 15234, duration: 45 }
// /js/app.js: { pushed: false, size: 89234, duration: 123 }
```

**Server-side logging:**

```javascript
const http2 = require('http2');
const fs = require('fs');

const server = http2.createSecureServer({
    key: fs.readFileSync('server-key.pem'),
    cert: fs.readFileSync('server-cert.pem')
});

const pushStats = {
    pushed: 0,
    cancelled: 0,
    failed: 0
};

server.on('stream', (stream, headers) => {
    if (headers[':path'] === '/') {
        stream.pushStream({ ':path': '/styles.css' }, (err, pushStream) => {
            if (err) {
                pushStats.failed++;
                console.error('Push failed:', err);
                return;
            }
            
            pushStats.pushed++;
            
            pushStream.on('close', () => {
                if (pushStream.rstCode === 8) { // CANCEL
                    pushStats.cancelled++;
                    console.log('Push cancelled by client');
                }
            });
            
            pushStream.respond({
                ':status': 200,
                'content-type': 'text/css'
            });
            
            pushStream.end(fs.readFileSync('public/styles.css'));
        });
        
        stream.respond({
            ':status': 200,
            'content-type': 'text/html'
        });
        
        stream.end(fs.readFileSync('public/index.html'));
    }
});

// Log stats every minute
setInterval(() => {
    console.log('Push stats:', pushStats);
    console.log('Cancel rate:', (pushStats.cancelled / pushStats.pushed * 100).toFixed(1) + '%');
}, 60000);

server.listen(8443);
```

---

## 29.7 Cache-Aware Push

### 29.7.1 - Cache Digest

**RFC 8639 - Cache Digests for HTTP/2:**

```
Client sends cache digest in SETTINGS frame:
SETTINGS_CACHE_DIGEST: <digest>

Digest contains Bloom filter of cached URLs

Server checks digest before pushing:
- If resource in digest → Don't push
- If resource not in digest → Push
```

**Implementation (experimental):**

```javascript
const http2 = require('http2');
const crypto = require('crypto');

// Simple cache digest implementation
class CacheDigest {
    constructor(size = 256) {
        this.size = size;
        this.bits = new Uint8Array(size);
    }
    
    add(url) {
        const hash1 = this.hash(url, 0);
        const hash2 = this.hash(url, 1);
        const hash3 = this.hash(url, 2);
        
        this.setBit(hash1);
        this.setBit(hash2);
        this.setBit(hash3);
    }
    
    has(url) {
        const hash1 = this.hash(url, 0);
        const hash2 = this.hash(url, 1);
        const hash3 = this.hash(url, 2);
        
        return this.getBit(hash1) && 
               this.getBit(hash2) && 
               this.getBit(hash3);
    }
    
    hash(url, seed) {
        const hash = crypto.createHash('sha256')
            .update(url + seed)
            .digest();
        return hash.readUInt32BE(0) % (this.size * 8);
    }
    
    setBit(index) {
        const byteIndex = Math.floor(index / 8);
        const bitIndex = index % 8;
        this.bits[byteIndex] |= (1 << bitIndex);
    }
    
    getBit(index) {
        const byteIndex = Math.floor(index / 8);
        const bitIndex = index % 8;
        return (this.bits[byteIndex] & (1 << bitIndex)) !== 0;
    }
}

// Server usage
const server = http2.createSecureServer(options);

server.on('stream', (stream, headers) => {
    // Get client cache digest (if sent)
    const cacheDigestHeader = headers['cache-digest'];
    let cacheDigest = null;
    
    if (cacheDigestHeader) {
        cacheDigest = parseCacheDigest(cacheDigestHeader);
    }
    
    if (headers[':path'] === '/') {
        // Check cache before pushing
        const resourcesToPush = [
            '/css/critical.css',
            '/js/app.js'
        ];
        
        resourcesToPush.forEach(path => {
            if (!cacheDigest || !cacheDigest.has(path)) {
                console.log('Pushing:', path);
                pushResource(stream, path);
            } else {
                console.log('Skipping push (in cache):', path);
            }
        });
        
        // Respond with HTML
        stream.respond({
            ':status': 200,
            'content-type': 'text/html'
        });
        stream.end(fs.readFileSync('index.html'));
    }
});
```

---

## 29.8 Alternatives to Server Push

### 29.8.1 - Resource Hints

**Preload (fetch resource now):**

```html
<head>
    <link rel="preload" href="/critical.css" as="style">
    <link rel="preload" href="/app.js" as="script">
    <link rel="preload" href="/font.woff2" as="font" crossorigin>
</head>
```

**Prefetch (fetch for next navigation):**

```html
<link rel="prefetch" href="/next-page.html">
<link rel="prefetch" href="/next-page.css">
```

**DNS Prefetch & Preconnect:**

```html
<link rel="dns-prefetch" href="//api.example.com">
<link rel="preconnect" href="https://cdn.example.com">
```

### 29.8.2 - Early Hints (103 Status Code)

**RFC 8297 - 103 Early Hints:**

```http
Client → GET /index.html

Server → 103 Early Hints
Link: </critical.css>; rel=preload; as=style
Link: </app.js>; rel=preload; as=script

Server → 200 OK
Content-Type: text/html

<html>...</html>
```

**Nginx configuration:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    location = / {
        # Send 103 Early Hints
        add_header Link "</css/critical.css>; rel=preload; as=style" always;
        add_header Link "</js/app.js>; rel=preload; as=script" always;
        
        # Enable early hints
        http2_push_preload on;
        
        try_files /index.html =404;
    }
}
```

---

## 29.9 Best Practices

### 29.9.1 - Complete Production Setup

**Nginx optimized push configuration:**

```nginx
http {
    # Enable HTTP/2
    http2_max_field_size 16k;
    http2_max_header_size 32k;
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        ssl_certificate /etc/ssl/certs/example.com.crt;
        ssl_certificate_key /etc/ssl/private/example.com.key;
        
        # SSL optimizations
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        
        root /var/www/html;
        
        # Push for homepage
        location = / {
            # Only push on first visit (check cookie)
            if ($cookie_returning_visitor != "true") {
                http2_push /css/critical.css;
                http2_push /js/app.js;
                http2_push /fonts/main.woff2;
            }
            
            # Set cookie for returning visitors
            add_header Set-Cookie "returning_visitor=true; Max-Age=86400; Path=/";
            
            try_files /index.html =404;
        }
        
        # Static assets with long cache
        location ~* \.(css|js|woff2|svg|png|jpg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 29.9.2 - Monitoring

**Track push effectiveness:**

```javascript
// Client-side
if ('performance' in window) {
    window.addEventListener('load', () => {
        const resources = performance.getEntriesByType('resource');
        const pushStats = {
            total: 0,
            pushed: 0,
            cached: 0
        };
        
        resources.forEach(entry => {
            if (entry.nextHopProtocol === 'h2') {
                pushStats.total++;
                
                if (entry.transferSize === 0) {
                    if (entry.decodedBodySize > 0) {
                        pushStats.pushed++;
                    } else {
                        pushStats.cached++;
                    }
                }
            }
        });
        
        console.log('Push stats:', pushStats);
        
        // Send to analytics
        sendAnalytics('http2_push', pushStats);
    });
}
```

---

Prossimo: **Capitolo 30 - Microservices e API Gateway**
