# 38. Performance Optimization

## 38.1 Introduzione alla Performance

**Metriche chiave di performance:**

```
1. TTFB (Time To First Byte)
   - Tempo per ricevere il primo byte
   - Target: < 200ms

2. FCP (First Contentful Paint)
   - Primo contenuto renderizzato
   - Target: < 1.8s

3. LCP (Largest Contentful Paint)
   - Elemento più grande renderizzato
   - Target: < 2.5s

4. FID (First Input Delay)
   - Tempo di risposta alla prima interazione
   - Target: < 100ms

5. CLS (Cumulative Layout Shift)
   - Stabilità del layout
   - Target: < 0.1

6. TTI (Time To Interactive)
   - Tempo per diventare interattivo
   - Target: < 3.8s
```

**Strategie di ottimizzazione:**

```
- Minimizzazione risorse (HTML, CSS, JS)
- Compressione (Gzip, Brotli)
- Caching aggressivo
- Lazy loading
- Code splitting
- CDN
- HTTP/2 o HTTP/3
- Preload/Prefetch
- Service Worker
```

---

## 38.2 Minification

### 38.2.1 - Minify HTML, CSS, JS

**Setup con Webpack:**

```javascript
// webpack.config.js
const path = require('path');
const HtmlWebpackPlugin = require('html-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const CssMinimizerPlugin = require('css-minimizer-webpack-plugin');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    mode: 'production',
    entry: './src/index.js',
    output: {
        filename: '[name].[contenthash].js',
        path: path.resolve(__dirname, 'dist'),
        clean: true
    },
    module: {
        rules: [
            {
                test: /\.css$/,
                use: [MiniCssExtractPlugin.loader, 'css-loader']
            },
            {
                test: /\.js$/,
                exclude: /node_modules/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            }
        ]
    },
    plugins: [
        new HtmlWebpackPlugin({
            template: './src/index.html',
            minify: {
                collapseWhitespace: true,
                removeComments: true,
                removeRedundantAttributes: true,
                useShortDoctype: true,
                removeEmptyAttributes: true,
                removeStyleLinkTypeAttributes: true,
                keepClosingSlash: true,
                minifyJS: true,
                minifyCSS: true,
                minifyURLs: true
            }
        }),
        new MiniCssExtractPlugin({
            filename: '[name].[contenthash].css'
        })
    ],
    optimization: {
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    compress: {
                        drop_console: true,
                        drop_debugger: true
                    }
                }
            }),
            new CssMinimizerPlugin()
        ],
        splitChunks: {
            chunks: 'all'
        }
    }
};
```

### 38.2.2 - Express Minification

**Runtime minification in production:**

```javascript
const express = require('express');
const compression = require('compression');
const minify = require('express-minify');
const uglifyJs = require('uglify-js');

const app = express();

// Compression (Gzip/Brotli)
app.use(compression());

// Minification
app.use(minify({
    cache: false,
    uglifyJsModule: uglifyJs,
    errorHandler: console.error,
    jsMatch: /\.js$/,
    cssMatch: /\.css$/,
    jsonMatch: /\.json$/,
    sassMatch: /\.scss$/
}));

// Serve static files
app.use('/static', express.static('public', {
    maxAge: '1y',
    immutable: true
}));

app.listen(3000);
```

---

## 38.3 Compression

### 38.3.1 - Gzip e Brotli

**Nginx compression:**

```nginx
# nginx.conf

http {
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
    gzip_min_length 256;
    
    # Brotli compression (if available)
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/rss+xml
        font/truetype
        font/opentype
        application/vnd.ms-fontobject
        image/svg+xml;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            proxy_pass http://localhost:3000;
            
            # Headers
            proxy_set_header Accept-Encoding "gzip, br";
            
            # Add Vary header
            add_header Vary "Accept-Encoding";
        }
    }
}
```

**Express.js compression:**

```javascript
const express = require('express');
const compression = require('compression');

const app = express();

// Compression middleware
app.use(compression({
    level: 6,  // Compression level (0-9)
    threshold: 1024,  // Only compress if > 1KB
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

app.get('/large-data', (req, res) => {
    const data = {
        items: Array.from({ length: 10000 }, (_, i) => ({
            id: i,
            name: `Item ${i}`,
            description: 'Lorem ipsum dolor sit amet...'
        }))
    };
    
    // Compression middleware applica automaticamente gzip
    res.json(data);
});

app.listen(3000);
```

### 38.3.2 - Compression Comparison

**Test compression efficiency:**

```javascript
const express = require('express');
const compression = require('compression');
const zlib = require('zlib');
const { promisify } = require('util');

const gzipAsync = promisify(zlib.gzip);
const brotliAsync = promisify(zlib.brotliCompress);

const app = express();

app.get('/compression-test', async (req, res) => {
    const data = JSON.stringify({
        items: Array.from({ length: 1000 }, (_, i) => ({
            id: i,
            value: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'
        }))
    });
    
    const original = Buffer.byteLength(data);
    
    // Gzip
    const gzipData = await gzipAsync(data);
    const gzipSize = gzipData.length;
    const gzipRatio = ((1 - gzipSize / original) * 100).toFixed(2);
    
    // Brotli
    const brotliData = await brotliAsync(data);
    const brotliSize = brotliData.length;
    const brotliRatio = ((1 - brotliSize / original) * 100).toFixed(2);
    
    res.json({
        original: `${original} bytes`,
        gzip: {
            size: `${gzipSize} bytes`,
            ratio: `${gzipRatio}% smaller`
        },
        brotli: {
            size: `${brotliSize} bytes`,
            ratio: `${brotliRatio}% smaller`
        }
    });
});

app.listen(3000);
```

---

## 38.4 Resource Hints

### 38.4.1 - Preload, Prefetch, Preconnect

**HTML resource hints:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Performance Optimization</title>
    
    <!-- DNS Prefetch: risolve DNS in anticipo -->
    <link rel="dns-prefetch" href="//fonts.googleapis.com">
    <link rel="dns-prefetch" href="//cdn.example.com">
    
    <!-- Preconnect: stabilisce connessione completa -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    
    <!-- Preload: carica risorse critiche subito -->
    <link rel="preload" href="/styles/critical.css" as="style">
    <link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
    <link rel="preload" href="/scripts/app.js" as="script">
    <link rel="preload" href="/images/hero.jpg" as="image">
    
    <!-- Prefetch: carica risorse per navigazione futura -->
    <link rel="prefetch" href="/page2.html">
    <link rel="prefetch" href="/api/data.json">
    
    <!-- Prerender: prerenderizza pagina intera -->
    <link rel="prerender" href="/next-page.html">
    
    <!-- Critical CSS inline -->
    <style>
        /* Critical CSS for above-the-fold content */
        body { margin: 0; font-family: Arial; }
        .header { background: #333; color: white; padding: 20px; }
    </style>
    
    <!-- Load CSS asynchronously -->
    <link rel="stylesheet" href="/styles/main.css" media="print" onload="this.media='all'">
    
    <!-- Module preload -->
    <link rel="modulepreload" href="/modules/main.js">
</head>
<body>
    <h1>Performance Test</h1>
    
    <script>
        // Dynamic preload
        function preloadResource(url, as) {
            const link = document.createElement('link');
            link.rel = 'preload';
            link.href = url;
            link.as = as;
            document.head.appendChild(link);
        }
        
        // Preload next page resources on hover
        document.querySelectorAll('a').forEach(link => {
            link.addEventListener('mouseenter', () => {
                const href = link.getAttribute('href');
                if (href && !href.startsWith('#')) {
                    preloadResource(href, 'document');
                }
            });
        });
    </script>
</body>
</html>
```

### 38.4.2 - Express Resource Hints

**Server-side resource hints:**

```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
    // Preload critical resources
    res.setHeader('Link', [
        '</styles/critical.css>; rel=preload; as=style',
        '</scripts/app.js>; rel=preload; as=script',
        '</fonts/main.woff2>; rel=preload; as=font; crossorigin',
        '<https://cdn.example.com>; rel=preconnect'
    ].join(', '));
    
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Performance App</title>
            <link rel="stylesheet" href="/styles/critical.css">
        </head>
        <body>
            <h1>Hello World</h1>
            <script src="/scripts/app.js"></script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

---

## 38.5 Lazy Loading

### 38.5.1 - Image Lazy Loading

**Native lazy loading:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Lazy Loading</title>
    <style>
        img {
            width: 100%;
            height: 400px;
            object-fit: cover;
            background: #f0f0f0;
        }
    </style>
</head>
<body>
    <h1>Lazy Loading Images</h1>
    
    <!-- Native lazy loading -->
    <img src="image1.jpg" loading="lazy" alt="Image 1">
    <img src="image2.jpg" loading="lazy" alt="Image 2">
    <img src="image3.jpg" loading="lazy" alt="Image 3">
    
    <!-- Eager loading (default) -->
    <img src="hero.jpg" loading="eager" alt="Hero">
    
    <!-- With placeholder -->
    <img 
        src="placeholder.jpg" 
        data-src="large-image.jpg" 
        loading="lazy" 
        class="lazy"
        alt="Large Image">
    
    <script>
        // Intersection Observer for advanced lazy loading
        const images = document.querySelectorAll('img.lazy');
        
        const imageObserver = new IntersectionObserver((entries, observer) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src;
                    img.classList.remove('lazy');
                    observer.unobserve(img);
                }
            });
        });
        
        images.forEach(img => imageObserver.observe(img));
    </script>
</body>
</html>
```

### 38.5.2 - Component Lazy Loading (React)

**React lazy loading:**

```javascript
import React, { Suspense, lazy } from 'react';

// Lazy load components
const Dashboard = lazy(() => import('./components/Dashboard'));
const Profile = lazy(() => import('./components/Profile'));
const Settings = lazy(() => import('./components/Settings'));

function App() {
    return (
        <div>
            <h1>My App</h1>
            
            <Suspense fallback={<div>Loading...</div>}>
                <Dashboard />
            </Suspense>
            
            <Suspense fallback={<div>Loading profile...</div>}>
                <Profile />
            </Suspense>
        </div>
    );
}

export default App;
```

**Dynamic import:**

```javascript
// app.js

// Load module on demand
async function loadModule() {
    const module = await import('./heavy-module.js');
    module.init();
}

// Load on button click
document.getElementById('loadBtn').addEventListener('click', async () => {
    const { default: Chart } = await import('./chart.js');
    new Chart('#canvas', { data: [...] });
});

// Conditional loading
if (window.innerWidth > 768) {
    import('./desktop-features.js').then(module => {
        module.init();
    });
}
```

---

## 38.6 Code Splitting

### 38.6.1 - Webpack Code Splitting

**Split code into chunks:**

```javascript
// webpack.config.js
module.exports = {
    entry: {
        main: './src/index.js',
        vendor: './src/vendor.js'
    },
    output: {
        filename: '[name].[contenthash].js',
        path: path.resolve(__dirname, 'dist')
    },
    optimization: {
        splitChunks: {
            chunks: 'all',
            cacheGroups: {
                vendor: {
                    test: /[\\/]node_modules[\\/]/,
                    name: 'vendors',
                    priority: 10
                },
                common: {
                    minChunks: 2,
                    priority: 5,
                    reuseExistingChunk: true
                }
            }
        },
        runtimeChunk: 'single'
    }
};
```

**Dynamic imports:**

```javascript
// src/index.js

// Static import (always bundled)
import { add } from './math.js';

// Dynamic import (separate chunk)
document.getElementById('loadChart').addEventListener('click', async () => {
    const { default: Chart } = await import(
        /* webpackChunkName: "chart" */
        './chart.js'
    );
    
    new Chart('#canvas');
});

// Route-based code splitting
async function loadRoute(route) {
    switch (route) {
        case '/dashboard':
            const { Dashboard } = await import('./routes/Dashboard.js');
            return Dashboard;
        case '/profile':
            const { Profile } = await import('./routes/Profile.js');
            return Profile;
        default:
            const { Home } = await import('./routes/Home.js');
            return Home;
    }
}
```

---

## 38.7 HTTP/2 Optimization

### 38.7.1 - HTTP/2 Server Push

**Nginx HTTP/2 push:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        root /var/www/html;
        
        # HTTP/2 Server Push
        location = /index.html {
            http2_push /styles/main.css;
            http2_push /scripts/app.js;
            http2_push /images/logo.png;
        }
    }
}
```

**Node.js HTTP/2 push:**

```javascript
const http2 = require('http2');
const fs = require('fs');
const path = require('path');

const server = http2.createSecureServer({
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
});

server.on('stream', (stream, headers) => {
    const reqPath = headers[':path'];
    
    if (reqPath === '/') {
        // Push critical resources
        const pushResources = [
            { path: '/styles/main.css', type: 'text/css' },
            { path: '/scripts/app.js', type: 'application/javascript' },
            { path: '/images/logo.png', type: 'image/png' }
        ];
        
        pushResources.forEach(resource => {
            stream.pushStream({ ':path': resource.path }, (err, pushStream) => {
                if (err) throw err;
                
                pushStream.respond({
                    ':status': 200,
                    'content-type': resource.type
                });
                
                const filePath = path.join(__dirname, 'public', resource.path);
                const file = fs.createReadStream(filePath);
                file.pipe(pushStream);
            });
        });
        
        // Serve index.html
        stream.respond({
            ':status': 200,
            'content-type': 'text/html'
        });
        
        const html = fs.createReadStream('public/index.html');
        html.pipe(stream);
    }
});

server.listen(3000);
```

### 38.7.2 - HTTP/2 Multiplexing

**Multiple requests in parallel:**

```javascript
const http2 = require('http2');

const client = http2.connect('https://example.com');

// Multiple concurrent requests
const requests = [
    '/api/user',
    '/api/posts',
    '/api/comments',
    '/api/notifications'
];

requests.forEach(path => {
    const req = client.request({
        ':path': path,
        ':method': 'GET'
    });
    
    req.on('response', headers => {
        console.log(`Response for ${path}:`, headers[':status']);
    });
    
    let data = '';
    req.on('data', chunk => {
        data += chunk;
    });
    
    req.on('end', () => {
        console.log(`${path} completed:`, JSON.parse(data));
    });
});

// All requests use single TCP connection
```

---

## 38.8 Performance Monitoring

### 38.8.1 - Web Vitals

**Measure Core Web Vitals:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Performance Monitoring</title>
</head>
<body>
    <h1>Performance Test</h1>
    
    <script type="module">
        import {getCLS, getFID, getFCP, getLCP, getTTFB} from 'https://unpkg.com/web-vitals@3?module';
        
        function sendToAnalytics(metric) {
            const body = JSON.stringify(metric);
            
            // Use `navigator.sendBeacon()` if available, falling back to `fetch()`
            if (navigator.sendBeacon) {
                navigator.sendBeacon('/analytics', body);
            } else {
                fetch('/analytics', {
                    body,
                    method: 'POST',
                    keepalive: true
                });
            }
        }
        
        getCLS(sendToAnalytics);
        getFID(sendToAnalytics);
        getFCP(sendToAnalytics);
        getLCP(sendToAnalytics);
        getTTFB(sendToAnalytics);
    </script>
    
    <script>
        // Performance Observer
        const observer = new PerformanceObserver((list) => {
            for (const entry of list.getEntries()) {
                console.log(entry.entryType, entry);
                
                if (entry.entryType === 'largest-contentful-paint') {
                    console.log('LCP:', entry.renderTime || entry.loadTime);
                }
                
                if (entry.entryType === 'first-input') {
                    console.log('FID:', entry.processingStart - entry.startTime);
                }
                
                if (entry.entryType === 'layout-shift' && !entry.hadRecentInput) {
                    console.log('CLS:', entry.value);
                }
            }
        });
        
        observer.observe({ 
            entryTypes: ['largest-contentful-paint', 'first-input', 'layout-shift']
        });
        
        // Navigation Timing
        window.addEventListener('load', () => {
            const perfData = performance.getEntriesByType('navigation')[0];
            
            console.log('Performance Metrics:');
            console.log('DNS Lookup:', perfData.domainLookupEnd - perfData.domainLookupStart, 'ms');
            console.log('TCP Connection:', perfData.connectEnd - perfData.connectStart, 'ms');
            console.log('Request Time:', perfData.responseStart - perfData.requestStart, 'ms');
            console.log('Response Time:', perfData.responseEnd - perfData.responseStart, 'ms');
            console.log('DOM Processing:', perfData.domComplete - perfData.domLoading, 'ms');
            console.log('Load Complete:', perfData.loadEventEnd - perfData.loadEventStart, 'ms');
            
            const ttfb = perfData.responseStart - perfData.requestStart;
            const domLoad = perfData.domContentLoadedEventEnd - perfData.domContentLoadedEventStart;
            const windowLoad = perfData.loadEventEnd - perfData.loadEventStart;
            
            fetch('/analytics/timing', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ttfb, domLoad, windowLoad })
            });
        });
    </script>
</body>
</html>
```

### 38.8.2 - Server-Side Performance

**Express performance monitoring:**

```javascript
const express = require('express');
const responseTime = require('response-time');

const app = express();

// Response time middleware
app.use(responseTime((req, res, time) => {
    console.log(`${req.method} ${req.url} - ${time.toFixed(2)}ms`);
    
    // Send to monitoring service
    if (time > 1000) {
        console.warn(`Slow request: ${req.url} took ${time}ms`);
    }
}));

// Custom performance middleware
app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        
        const logData = {
            method: req.method,
            url: req.url,
            status: res.statusCode,
            duration,
            userAgent: req.get('user-agent'),
            ip: req.ip,
            timestamp: new Date().toISOString()
        };
        
        console.log(JSON.stringify(logData));
    });
    
    next();
});

app.get('/api/data', (req, res) => {
    // Simulate slow operation
    setTimeout(() => {
        res.json({ data: 'Response' });
    }, 500);
});

app.listen(3000);
```

---

**Capitolo 38 completato!** Tutte le tecniche di ottimizzazione delle performance: minification, compression, resource hints, lazy loading, code splitting, HTTP/2, e monitoring! 🚀