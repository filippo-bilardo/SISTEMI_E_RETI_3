# 25. HTTP Compression (Gzip, Brotli)

## 25.1 Introduzione

**HTTP Compression** riduce le dimensioni dei dati trasferiti tra server e client.

**Vantaggi:**
- 📉 **Bandwidth savings:** 60-90% riduzione dimensioni
- ⚡ **Faster load times:** Meno dati = meno tempo transfer
- 💰 **Cost reduction:** Meno bandwidth = meno costi
- 🌍 **Better UX:** Soprattutto su mobile/slow connections
- 🎯 **SEO boost:** Google favorisce siti veloci

**Compression algorithms:**
- **Gzip:** Standard, supportato ovunque, ratio ~70%
- **Brotli:** Nuovo, migliore ratio ~80%, Google push
- **Deflate:** Obsoleto, non più usato

---

## 25.2 Come Funziona la Compression

### 25.2.1 - Content Negotiation

**Client richiede compression:**

```http
GET /api/data HTTP/1.1
Host: api.example.com
Accept-Encoding: gzip, deflate, br
```

**Server risponde con compressed content:**

```http
HTTP/1.1 200 OK
Content-Type: application/json
Content-Encoding: gzip
Content-Length: 1234
Vary: Accept-Encoding

[compressed binary data]
```

**Process flow:**

```
1. Client → Accept-Encoding: gzip, br
2. Server → Compress response
3. Server → Content-Encoding: gzip
4. Server → Send compressed data
5. Client → Decompress automatically
```

### 25.2.2 - Vary Header

**Essenziale per caching:**

```http
HTTP/1.1 200 OK
Content-Encoding: gzip
Vary: Accept-Encoding
```

**Perché Vary è importante:**

```
Senza Vary:
1. Client A (supports gzip) → cached compressed version
2. Client B (no compression) → riceve cached gzip (ERROR!)

Con Vary:
1. Client A → cached as "gzip version"
2. Client B → cached as "uncompressed version"
```

---

## 25.3 Gzip Compression

### 25.3.1 - Nginx Gzip

**Configuration completa:**

```nginx
http {
    # Enable gzip
    gzip on;
    
    # Minimum file size to compress (< 1KB not worth it)
    gzip_min_length 1000;
    
    # Compression level (1-9, 6 is optimal balance)
    gzip_comp_level 6;
    
    # Buffers for compression
    gzip_buffers 16 8k;
    
    # HTTP version (1.1 recommended)
    gzip_http_version 1.1;
    
    # Proxied responses to compress
    gzip_proxied any;
    
    # Disable for old IE browsers
    gzip_disable "msie6";
    
    # MIME types to compress
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/x-javascript
        image/svg+xml;
    
    # Add Vary header
    gzip_vary on;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            root /var/www/html;
        }
    }
}
```

**Test compression:**

```bash
# Without compression
curl -I https://example.com/bundle.js
# Content-Length: 150000

# With compression
curl -I -H "Accept-Encoding: gzip" https://example.com/bundle.js
# Content-Length: 30000 (80% savings!)
# Content-Encoding: gzip
```

### 25.3.2 - Apache Gzip

**mod_deflate configuration:**

```apache
# Enable mod_deflate
<IfModule mod_deflate.c>
    # Compression level (1-9)
    DeflateCompressionLevel 6
    
    # Compress specific MIME types
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE text/javascript
    AddOutputFilterByType DEFLATE application/json
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE image/svg+xml
    
    # Exclude old browsers
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html
    
    # Add Vary header
    Header append Vary Accept-Encoding
</IfModule>
```

### 25.3.3 - Express.js Gzip

**compression middleware:**

```bash
npm install compression
```

```javascript
const express = require('express');
const compression = require('compression');

const app = express();

// Enable compression
app.use(compression({
    // Compression level (0-9)
    level: 6,
    
    // Minimum size to compress (bytes)
    threshold: 1024,
    
    // Filter function
    filter: (req, res) => {
        // Don't compress if client doesn't support it
        if (req.headers['x-no-compression']) {
            return false;
        }
        
        // Use compression for all other responses
        return compression.filter(req, res);
    }
}));

app.get('/api/large-data', (req, res) => {
    const data = {
        items: Array(1000).fill({ name: 'Item', description: 'Description' })
    };
    
    res.json(data);
    // Automatically compressed!
});

app.listen(3000);
```

**Selective compression:**

```javascript
const express = require('express');
const compression = require('compression');

const app = express();

// Compress only specific routes
const compressibleRoutes = compression();

app.get('/api/data', compressibleRoutes, (req, res) => {
    res.json({ data: 'compressed' });
});

// Don't compress images (already compressed)
app.get('/images/:filename', (req, res) => {
    res.sendFile(`/images/${req.params.filename}`);
});

app.listen(3000);
```

---

## 25.4 Brotli Compression

### 25.4.1 - Nginx Brotli

**Installation (requires module):**

```bash
# Install brotli module
git clone https://github.com/google/ngx_brotli.git
cd nginx-source
./configure --add-module=../ngx_brotli
make && make install
```

**Configuration:**

```nginx
http {
    # Enable brotli
    brotli on;
    
    # Compression quality (0-11, 6 is balanced)
    brotli_comp_level 6;
    
    # Minimum size
    brotli_min_length 1000;
    
    # MIME types
    brotli_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/x-javascript
        image/svg+xml;
    
    # Static compression (pre-compressed files)
    brotli_static on;
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        location / {
            root /var/www/html;
        }
    }
}
```

**Pre-compression (build time):**

```bash
# Compress files at build time
find /var/www/html -type f -name "*.js" -exec brotli {} \;
find /var/www/html -type f -name "*.css" -exec brotli {} \;

# Results:
# bundle.js (150 KB)
# bundle.js.br (25 KB) ← 83% savings!

# Nginx will serve .br file if it exists and client supports brotli
```

### 25.4.2 - Express.js Brotli

```bash
npm install shrink-ray-current
```

```javascript
const express = require('express');
const shrinkRay = require('shrink-ray-current');

const app = express();

// Enable both gzip and brotli
app.use(shrinkRay({
    // Brotli quality (0-11)
    brotli: {
        quality: 6
    },
    
    // Gzip level (0-9)
    zlib: {
        level: 6
    },
    
    // Threshold
    threshold: 1024,
    
    // Cache compressed responses
    cache: (req) => {
        return req.method === 'GET';
    }
}));

app.get('/api/data', (req, res) => {
    const data = { items: Array(1000).fill({ name: 'Item' }) };
    res.json(data);
    // Brotli if supported, else gzip
});

app.listen(3000);
```

### 25.4.3 - Brotli vs Gzip Comparison

**Compression ratio test:**

```javascript
const fs = require('fs');
const zlib = require('zlib');

const data = fs.readFileSync('bundle.js');
const originalSize = data.length;

// Gzip
const gzipped = zlib.gzipSync(data, { level: 6 });
const gzipSize = gzipped.length;
const gzipRatio = ((1 - gzipSize / originalSize) * 100).toFixed(1);

// Brotli
const brotlied = zlib.brotliCompressSync(data, {
    params: {
        [zlib.constants.BROTLI_PARAM_QUALITY]: 6
    }
});
const brotliSize = brotlied.length;
const brotliRatio = ((1 - brotliSize / originalSize) * 100).toFixed(1);

console.log('Original:', originalSize, 'bytes');
console.log('Gzip:', gzipSize, 'bytes', `(${gzipRatio}% savings)`);
console.log('Brotli:', brotliSize, 'bytes', `(${brotliRatio}% savings)`);
console.log('Brotli advantage:', ((1 - brotliSize / gzipSize) * 100).toFixed(1), '%');

// Example output:
// Original: 150000 bytes
// Gzip: 45000 bytes (70% savings)
// Brotli: 30000 bytes (80% savings)
// Brotli advantage: 33.3%
```

---

## 25.5 Static Pre-Compression

### 25.5.1 - Build-Time Compression

**Webpack plugin:**

```bash
npm install compression-webpack-plugin brotli-webpack-plugin --save-dev
```

```javascript
// webpack.config.js
const CompressionPlugin = require('compression-webpack-plugin');
const BrotliPlugin = require('brotli-webpack-plugin');

module.exports = {
    // ... other config
    
    plugins: [
        // Gzip compression
        new CompressionPlugin({
            filename: '[path][base].gz',
            algorithm: 'gzip',
            test: /\.(js|css|html|svg)$/,
            threshold: 1024,
            minRatio: 0.8
        }),
        
        // Brotli compression
        new BrotliPlugin({
            asset: '[path].br[query]',
            test: /\.(js|css|html|svg)$/,
            threshold: 1024,
            minRatio: 0.8
        })
    ]
};
```

**Build output:**

```
dist/
├── bundle.js (150 KB)
├── bundle.js.gz (45 KB)
├── bundle.js.br (30 KB)
├── styles.css (50 KB)
├── styles.css.gz (10 KB)
└── styles.css.br (8 KB)
```

### 25.5.2 - Nginx Serve Pre-Compressed

**Configuration:**

```nginx
http {
    server {
        listen 443 ssl http2;
        server_name example.com;
        root /var/www/dist;
        
        # Serve brotli if exists
        location ~ \.(js|css|svg|json)$ {
            brotli_static on;  # Serve .br files
            gzip_static on;    # Serve .gz files
            
            # Try brotli → gzip → original
            try_files $uri.br $uri.gz $uri =404;
        }
    }
}
```

**Request flow:**

```
Client supports brotli:
GET /bundle.js
Accept-Encoding: br, gzip
→ Serve bundle.js.br (30 KB)

Client supports only gzip:
GET /bundle.js
Accept-Encoding: gzip
→ Serve bundle.js.gz (45 KB)

Client no compression:
GET /bundle.js
→ Serve bundle.js (150 KB)
```

---

## 25.6 What to Compress

### 25.6.1 - Compressible Content

**✅ COMPRESS:**

```
Text-based content:
- HTML, CSS, JavaScript
- JSON, XML
- SVG images
- Plain text
- CSV
- Markdown

Typical savings: 60-90%
```

**❌ DON'T COMPRESS:**

```
Already compressed:
- Images: JPEG, PNG, GIF, WebP
- Videos: MP4, WebM
- Audio: MP3, AAC
- Archives: ZIP, RAR, 7Z
- Fonts: WOFF, WOFF2 (already compressed)

Result: 0-5% savings (not worth CPU cost)
```

### 25.6.2 - Smart Compression Filter

**Express.js example:**

```javascript
const express = require('express');
const compression = require('compression');

const app = express();

// Smart compression filter
const shouldCompress = (req, res) => {
    // Check Content-Type
    const contentType = res.getHeader('Content-Type');
    
    // Don't compress already compressed formats
    const nonCompressible = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'video/',
        'audio/',
        'application/zip',
        'application/x-rar',
        'font/woff',
        'font/woff2'
    ];
    
    if (contentType) {
        for (const type of nonCompressible) {
            if (contentType.includes(type)) {
                return false;
            }
        }
    }
    
    // Use default compression filter
    return compression.filter(req, res);
};

app.use(compression({ filter: shouldCompress }));

app.listen(3000);
```

---

## 25.7 Performance Optimization

### 25.7.1 - Compression Level Tuning

**Trade-off: Compression ratio vs CPU time**

```javascript
const zlib = require('zlib');
const fs = require('fs');

const data = fs.readFileSync('bundle.js');

// Test different levels
for (let level = 1; level <= 9; level++) {
    const start = Date.now();
    const compressed = zlib.gzipSync(data, { level });
    const time = Date.now() - start;
    const ratio = ((1 - compressed.length / data.length) * 100).toFixed(1);
    
    console.log(`Level ${level}: ${compressed.length} bytes (${ratio}%) in ${time}ms`);
}

// Example output:
// Level 1: 52000 bytes (65.3%) in 15ms  ← FAST but low ratio
// Level 6: 45000 bytes (70.0%) in 45ms  ← BALANCED ✅
// Level 9: 43000 bytes (71.3%) in 180ms ← HIGH ratio but SLOW
```

**Recommendations:**

```
Development:
- Level 1-3: Fast compression for dev speed

Production (dynamic):
- Level 5-7: Balanced (Nginx default: 6)

Production (static):
- Level 9-11: Maximum compression at build time
```

### 25.7.2 - Caching Compressed Responses

**Express.js with cache:**

```javascript
const express = require('express');
const shrinkRay = require('shrink-ray-current');
const NodeCache = require('node-cache');

const app = express();
const compressionCache = new NodeCache({ stdTTL: 3600 });

app.use(shrinkRay({
    cache: (req) => {
        // Cache GET requests
        if (req.method !== 'GET') {
            return false;
        }
        
        // Check if response is cached
        const cached = compressionCache.get(req.url);
        if (cached) {
            return cached;
        }
        
        return true;
    },
    
    // Store in cache after compression
    cacheResults: (req, compressed) => {
        if (req.method === 'GET') {
            compressionCache.set(req.url, compressed);
        }
    }
}));

app.listen(3000);
```

### 25.7.3 - CDN Pre-Compression

**Cloudflare automatic compression:**

```
Cloudflare automatically compresses:
- HTML, CSS, JavaScript
- JSON, XML
- SVG

No configuration needed (free feature)
Brotli supported automatically
```

**Custom CDN configuration:**

```nginx
# Origin server
server {
    listen 80;
    server_name origin.example.com;
    
    # Pre-compress at origin
    location / {
        brotli_static on;
        gzip_static on;
        root /var/www/dist;
    }
}

# CDN caches both compressed and uncompressed versions
# based on Accept-Encoding header
```

---

## 25.8 Compression Security

### 25.8.1 - BREACH Attack

**Vulnerability:**

```
BREACH (Browser Reconnaissance and Exfiltration via Adaptive Compression of Hypertext)

Attack scenario:
1. Attacker injects content in HTTPS response
2. Compression reveals secrets via response size
3. Iteratively guess secret tokens

Vulnerable:
- CSRF tokens in compressed HTML
- Secrets in JSON responses
```

**Mitigation:**

```javascript
const express = require('express');
const compression = require('compression');
const crypto = require('crypto');

const app = express();

// 1. Disable compression for sensitive data
app.get('/api/secret', (req, res) => {
    res.set('X-No-Compression', '1'); // Disable compression
    res.json({ csrf_token: req.csrfToken() });
});

// 2. Add random padding to responses
const addRandomPadding = (req, res, next) => {
    const originalJson = res.json.bind(res);
    
    res.json = (data) => {
        // Add random padding
        data._padding = crypto.randomBytes(16).toString('hex');
        return originalJson(data);
    };
    
    next();
};

app.use(addRandomPadding);
app.use(compression());

// 3. Rate limit sensitive endpoints
const rateLimit = require('express-rate-limit');

const csrfLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10 // Only 10 CSRF token requests per 15 min
});

app.get('/api/csrf-token', csrfLimiter, (req, res) => {
    res.json({ token: req.csrfToken() });
});

app.listen(3000);
```

### 25.8.2 - CRIME Attack

**Vulnerability (TLS compression):**

```
CRIME (Compression Ratio Info-leak Made Easy)

Attack on TLS compression (not HTTP compression)
Disabled in modern browsers/servers
```

**Protection:**

```nginx
# Nginx: Disable TLS compression
ssl_prefer_server_ciphers on;
ssl_ciphers HIGH:!aNULL:!MD5:!RC4;

# HTTP compression is SAFE (only HTTPS/TLS compression was vulnerable)
gzip on;
brotli on;
```

---

## 25.9 Testing & Monitoring

### 25.9.1 - Test Compression

**Command line:**

```bash
# Test gzip
curl -I -H "Accept-Encoding: gzip" https://example.com/bundle.js

# Test brotli
curl -I -H "Accept-Encoding: br" https://example.com/bundle.js

# Compare sizes
curl -H "Accept-Encoding: gzip" https://example.com/bundle.js | wc -c
curl https://example.com/bundle.js | wc -c
```

**Node.js test:**

```javascript
const https = require('https');
const zlib = require('zlib');

const testCompression = (url) => {
    return new Promise((resolve) => {
        https.get(url, {
            headers: {
                'Accept-Encoding': 'gzip, br'
            }
        }, (res) => {
            const encoding = res.headers['content-encoding'];
            let size = 0;
            
            let stream = res;
            if (encoding === 'gzip') {
                stream = res.pipe(zlib.createGunzip());
            } else if (encoding === 'br') {
                stream = res.pipe(zlib.createBrotliDecompress());
            }
            
            stream.on('data', (chunk) => {
                size += chunk.length;
            });
            
            stream.on('end', () => {
                resolve({
                    encoding,
                    compressed: parseInt(res.headers['content-length']),
                    uncompressed: size,
                    ratio: (1 - parseInt(res.headers['content-length']) / size) * 100
                });
            });
        });
    });
};

testCompression('https://example.com/bundle.js').then(result => {
    console.log(`Encoding: ${result.encoding}`);
    console.log(`Compressed: ${result.compressed} bytes`);
    console.log(`Uncompressed: ${result.uncompressed} bytes`);
    console.log(`Savings: ${result.ratio.toFixed(1)}%`);
});
```

### 25.9.2 - Monitoring

**Prometheus metrics:**

```javascript
const express = require('express');
const compression = require('compression');
const prometheus = require('prom-client');

const app = express();

// Metrics
const compressionSavings = new prometheus.Counter({
    name: 'http_compression_bytes_saved_total',
    help: 'Total bytes saved by compression',
    labelNames: ['encoding']
});

const compressionRatio = new prometheus.Histogram({
    name: 'http_compression_ratio',
    help: 'Compression ratio',
    labelNames: ['encoding'],
    buckets: [0.5, 0.6, 0.7, 0.8, 0.9]
});

// Custom compression with metrics
app.use((req, res, next) => {
    const originalSend = res.send.bind(res);
    
    res.send = (body) => {
        const originalSize = Buffer.byteLength(body);
        
        // Call original send (compression happens here)
        originalSend(body);
        
        const encoding = res.getHeader('Content-Encoding');
        if (encoding) {
            const compressedSize = parseInt(res.getHeader('Content-Length'));
            const saved = originalSize - compressedSize;
            const ratio = 1 - (compressedSize / originalSize);
            
            compressionSavings.labels(encoding).inc(saved);
            compressionRatio.labels(encoding).observe(ratio);
        }
    };
    
    next();
});

app.use(compression());

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(3000);
```

---

## 25.10 Best Practices

### 25.10.1 - Complete Production Setup

**Nginx configuration:**

```nginx
http {
    # Gzip configuration
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_disable "msie6";
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/x-javascript
        image/svg+xml;
    
    # Brotli configuration
    brotli on;
    brotli_comp_level 6;
    brotli_min_length 1000;
    brotli_static on;
    brotli_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        image/svg+xml;
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        root /var/www/dist;
        
        # Cache control for static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
            
            # Serve pre-compressed if available
            brotli_static on;
            gzip_static on;
        }
        
        # No caching for HTML (may contain dynamic content)
        location ~* \.html$ {
            add_header Cache-Control "no-cache";
            brotli_static on;
            gzip_static on;
        }
    }
}
```

**Express.js production:**

```javascript
const express = require('express');
const shrinkRay = require('shrink-ray-current');
const helmet = require('helmet');

const app = express();

// Security headers
app.use(helmet());

// Compression
app.use(shrinkRay({
    brotli: { quality: 6 },
    zlib: { level: 6 },
    threshold: 1024,
    
    filter: (req, res) => {
        // Don't compress if requested
        if (req.headers['x-no-compression']) {
            return false;
        }
        
        // Check content type
        const contentType = res.getHeader('Content-Type');
        if (!contentType) return false;
        
        // Compress text-based content only
        return contentType.startsWith('text/') ||
               contentType.includes('json') ||
               contentType.includes('javascript') ||
               contentType.includes('xml');
    }
}));

// Serve static files (pre-compressed at build time)
app.use(express.static('dist', {
    maxAge: '1y',
    immutable: true
}));

app.listen(3000);
```

---

Prossimo: **Capitolo 26 - Content Delivery Networks (CDN)**
