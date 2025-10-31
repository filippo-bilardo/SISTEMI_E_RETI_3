# 34. Subresource Integrity (SRI)

## 34.1 Introduzione a SRI

**Subresource Integrity (SRI)** è un meccanismo di sicurezza che permette ai browser di verificare che le risorse scaricate (da CDN) non siano state manipolate.

**Problema senza SRI:**

```
Your Website → CDN → User
                ↑
            Compromised!

Se un CDN viene compromesso, script malevoli possono essere iniettati:
<script src="https://cdn.example.com/jquery.js"></script>
                                    ↑
                            Could be malware now!
```

**Soluzione con SRI:**

```html
<script src="https://cdn.example.com/jquery.js"
        integrity="sha384-abc123..."
        crossorigin="anonymous"></script>

Browser verifica:
1. Download file da CDN
2. Calcola hash SHA-384
3. Confronta con integrity attribute
4. Se match → esegue
5. Se no match → blocca e lancia errore
```

---

## 34.2 Come Funziona SRI

### 34.2.1 - Hash Algorithms

**Algoritmi supportati:**

```
sha256 - SHA-256 (meno sicuro ma più veloce)
sha384 - SHA-384 (raccomandato, balance tra security e performance)
sha512 - SHA-512 (più sicuro ma più lento)

Browser sceglie l'algoritmo più forte se multiple hashes forniti:
integrity="sha256-abc... sha384-def... sha512-ghi..."
                                         ↑
                                    Uses this one
```

### 34.2.2 - Generating Hashes

**Command line con OpenSSL:**

```bash
# Download file
curl https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js -o axios.min.js

# Generate SHA-384 hash
cat axios.min.js | openssl dgst -sha384 -binary | openssl base64 -A

# Output:
# sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo

# Use in HTML:
<script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"
        integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo"
        crossorigin="anonymous"></script>
```

**Node.js hash generation:**

```javascript
const crypto = require('crypto');
const fs = require('fs');

function generateSRI(filePath, algorithm = 'sha384') {
    const fileContent = fs.readFileSync(filePath);
    const hash = crypto.createHash(algorithm).update(fileContent).digest('base64');
    return `${algorithm}-${hash}`;
}

// Usage
const integrity = generateSRI('./axios.min.js');
console.log(integrity);
// sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo
```

**Online SRI Generator:**

```
https://www.srihash.org/

1. Enter CDN URL
2. Click "Hash!"
3. Copy generated <script> or <link> tag with integrity
```

---

## 34.3 SRI per Script

### 34.3.1 - Basic Script SRI

**jQuery example:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRI Demo</title>
</head>
<body>
    <!-- jQuery con SRI -->
    <script 
        src="https://code.jquery.com/jquery-3.6.0.min.js"
        integrity="sha384-vtXRMe3mGCbOeY7l30aIg8H9p3GdeSe4IFlP6G8JMa7o7lXvnz3GFKzPxzJdPfGK"
        crossorigin="anonymous">
    </script>
    
    <script>
        // Verify jQuery loaded
        if (typeof jQuery !== 'undefined') {
            console.log('jQuery loaded successfully with SRI verification');
        } else {
            console.error('jQuery failed to load - SRI check failed or CDN unavailable');
        }
    </script>
</body>
</html>
```

### 34.3.2 - Multiple CDN Fallback

**Fallback se SRI fallisce:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRI with Fallback</title>
</head>
<body>
    <!-- Try primary CDN with SRI -->
    <script 
        src="https://cdn.jsdelivr.net/npm/vue@3.3.4/dist/vue.global.min.js"
        integrity="sha384-abc123..."
        crossorigin="anonymous">
    </script>
    
    <!-- Fallback to secondary CDN -->
    <script>
        if (typeof Vue === 'undefined') {
            document.write('<script src="https://unpkg.com/vue@3.3.4/dist/vue.global.min.js" integrity="sha384-def456..." crossorigin="anonymous"><\/script>');
        }
    </script>
    
    <!-- Fallback to local copy -->
    <script>
        if (typeof Vue === 'undefined') {
            document.write('<script src="/js/vue.global.min.js"><\/script>');
        }
    </script>
    
    <script>
        if (typeof Vue === 'undefined') {
            alert('Critical error: Vue.js failed to load from all sources');
        }
    </script>
</body>
</html>
```

### 34.3.3 - Multiple Hashes

**Support multiple versions:**

```html
<!-- Multiple integrity hashes per diverse versioni del file -->
<script 
    src="https://cdn.example.com/lib.js"
    integrity="sha384-hash1 sha384-hash2 sha512-hash3"
    crossorigin="anonymous">
</script>

<!-- Browser accetta se almeno uno degli hash matcha -->
```

---

## 34.4 SRI per CSS

### 34.4.1 - Basic CSS SRI

**Bootstrap example:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>CSS SRI Demo</title>
    
    <!-- Bootstrap CSS con SRI -->
    <link 
        rel="stylesheet" 
        href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
        integrity="sha384-9ndCyUaIbzAi2FUVXJi0CjmCapSmO7SnpJef0486qhLnuZ2cdeRhO02iuK6FUUVM"
        crossorigin="anonymous">
</head>
<body>
    <div class="container">
        <h1 class="text-primary">Bootstrap con SRI</h1>
        <p class="text-muted">Stylesheet verificato tramite Subresource Integrity</p>
    </div>
</body>
</html>
```

### 34.4.2 - Font Awesome Example

**Complete Font Awesome setup:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Font Awesome SRI</title>
    
    <!-- Font Awesome CSS -->
    <link 
        rel="stylesheet" 
        href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
        integrity="sha512-iecdLmaskl7CVkqkXNQ/ZH/XLlvWZOJyj7Yy7tcenmpD1ypASozpmT/E0iPtmFIB46ZmdtAc9eNBvH0H/ZpiBw=="
        crossorigin="anonymous"
        referrerpolicy="no-referrer">
</head>
<body>
    <h1><i class="fas fa-lock"></i> Secure with SRI</h1>
    <p><i class="fas fa-check-circle"></i> Font Awesome verified</p>
</body>
</html>
```

---

## 34.5 CORS e SRI

### 34.5.1 - Crossorigin Attribute

**Perché crossorigin è necessario:**

```html
<!-- ❌ Senza crossorigin - SRI non funziona -->
<script 
    src="https://cdn.example.com/lib.js"
    integrity="sha384-abc123...">
</script>

<!-- ✓ Con crossorigin - SRI funziona -->
<script 
    src="https://cdn.example.com/lib.js"
    integrity="sha384-abc123..."
    crossorigin="anonymous">
</script>
```

**Crossorigin values:**

```
anonymous:
- Nessuna credenziale inviata
- CORS header necessari dal server

use-credentials:
- Credenziali (cookies) inviate
- Server deve rispondere con Access-Control-Allow-Credentials: true

Nessun attributo:
- Nessuna CORS check
- SRI NON funziona con risorse cross-origin
```

### 34.5.2 - Server CORS Configuration

**CDN deve supportare CORS per SRI:**

```javascript
// Server CDN configuration
const express = require('express');
const app = express();

// Enable CORS for SRI
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    next();
});

// Serve static files
app.use(express.static('public', {
    setHeaders: (res, path) => {
        // Cache immutable files
        if (path.endsWith('.min.js') || path.endsWith('.min.css')) {
            res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
        }
    }
}));

app.listen(3000);
```

---

## 34.6 Automated SRI Generation

### 34.6.1 - Webpack Plugin

**webpack-subresource-integrity:**

```javascript
// webpack.config.js
const SriPlugin = require('webpack-subresource-integrity');

module.exports = {
    output: {
        crossOriginLoading: 'anonymous'
    },
    plugins: [
        new SriPlugin({
            hashFuncNames: ['sha256', 'sha384'],
            enabled: process.env.NODE_ENV === 'production'
        })
    ]
};
```

**Generated HTML:**

```html
<!DOCTYPE html>
<html>
<head>
    <script 
        src="/js/app.js" 
        integrity="sha384-abc123... sha256-def456..."
        crossorigin="anonymous">
    </script>
    <link 
        rel="stylesheet" 
        href="/css/style.css"
        integrity="sha384-ghi789..."
        crossorigin="anonymous">
</head>
<body>
    <!-- content -->
</body>
</html>
```

### 34.6.2 - Gulp Task

**Generate SRI with Gulp:**

```javascript
const gulp = require('gulp');
const crypto = require('crypto');
const through = require('through2');
const fs = require('fs');

function generateSRI() {
    return through.obj(function(file, enc, cb) {
        if (file.isBuffer()) {
            const hash = crypto
                .createHash('sha384')
                .update(file.contents)
                .digest('base64');
            
            const integrity = `sha384-${hash}`;
            
            // Save to manifest
            const manifest = {
                [file.relative]: {
                    integrity,
                    path: file.relative
                }
            };
            
            fs.writeFileSync(
                'sri-manifest.json',
                JSON.stringify(manifest, null, 2)
            );
        }
        
        cb(null, file);
    });
}

gulp.task('sri', function() {
    return gulp.src(['dist/**/*.{js,css}'])
        .pipe(generateSRI());
});
```

### 34.6.3 - Express Middleware

**Dynamic SRI injection:**

```javascript
const express = require('express');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();

// Load SRI manifest
const sriManifest = JSON.parse(
    fs.readFileSync('sri-manifest.json', 'utf-8')
);

// Helper function
app.locals.sri = function(filepath) {
    const manifest = sriManifest[filepath];
    if (manifest) {
        return `integrity="${manifest.integrity}" crossorigin="anonymous"`;
    }
    return '';
};

// Template rendering
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <link rel="stylesheet" href="/css/style.css" ${app.locals.sri('css/style.css')}>
        </head>
        <body>
            <h1>Dynamic SRI</h1>
            <script src="/js/app.js" ${app.locals.sri('js/app.js')}></script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

---

## 34.7 SRI Best Practices

### 34.7.1 - When to Use SRI

**Use SRI for:**

```
✓ Third-party scripts from CDN
✓ Third-party stylesheets from CDN
✓ External libraries (jQuery, React, Vue, etc.)
✓ Font libraries (Font Awesome, Google Fonts)
✓ Analytics scripts (if from CDN)

✗ Don't use SRI for:
✗ Your own frequently-updated scripts
✗ Dynamic content
✗ APIs that return different content
```

### 34.7.2 - SRI Update Strategy

**Automated SRI updates:**

```javascript
// update-sri.js
const axios = require('axios');
const crypto = require('crypto');
const fs = require('fs');

const dependencies = [
    {
        name: 'axios',
        url: 'https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js'
    },
    {
        name: 'vue',
        url: 'https://cdn.jsdelivr.net/npm/vue@3/dist/vue.global.min.js'
    }
];

async function updateSRI() {
    const manifest = {};
    
    for (const dep of dependencies) {
        console.log(`Updating ${dep.name}...`);
        
        const response = await axios.get(dep.url);
        const content = response.data;
        
        const hash = crypto
            .createHash('sha384')
            .update(content)
            .digest('base64');
        
        manifest[dep.name] = {
            url: dep.url,
            integrity: `sha384-${hash}`,
            updated: new Date().toISOString()
        };
    }
    
    fs.writeFileSync(
        'sri-dependencies.json',
        JSON.stringify(manifest, null, 2)
    );
    
    console.log('SRI manifest updated!');
}

updateSRI().catch(console.error);
```

**Run weekly via cron:**

```bash
# crontab -e
0 0 * * 0 node /path/to/update-sri.js
```

### 34.7.3 - Monitoring SRI Failures

**Detect SRI failures:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SRI Monitoring</title>
    
    <script>
        // Monitor script load errors
        window.addEventListener('error', function(e) {
            if (e.target.tagName === 'SCRIPT' || e.target.tagName === 'LINK') {
                const resource = e.target.src || e.target.href;
                const integrity = e.target.integrity;
                
                // Log SRI failure
                console.error('SRI verification failed:', {
                    resource,
                    integrity,
                    timestamp: new Date().toISOString()
                });
                
                // Send to monitoring service
                fetch('/api/sri-error', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        resource,
                        integrity,
                        userAgent: navigator.userAgent,
                        timestamp: new Date().toISOString()
                    })
                });
            }
        }, true);
    </script>
    
    <script 
        src="https://cdn.example.com/lib.js"
        integrity="sha384-wronghash..."
        crossorigin="anonymous">
    </script>
</head>
<body>
    <h1>SRI Monitoring Demo</h1>
</body>
</html>
```

**Server-side monitoring:**

```javascript
const express = require('express');
const app = express();

app.use(express.json());

app.post('/api/sri-error', (req, res) => {
    const { resource, integrity, userAgent, timestamp } = req.body;
    
    console.error('SRI Failure:', {
        resource,
        integrity,
        userAgent,
        timestamp
    });
    
    // Alert team
    // sendAlert('SRI verification failed for ' + resource);
    
    // Log to monitoring service
    // logToSentry({ resource, integrity });
    
    res.status(200).json({ received: true });
});

app.listen(3000);
```

---

## 34.8 SRI with CSP

### 34.8.1 - Combining SRI and CSP

**Maximum security:**

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();

app.use((req, res, next) => {
    const nonce = crypto.randomBytes(16).toString('base64');
    res.locals.nonce = nonce;
    
    // CSP with SRI requirement
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            `script-src 'self' 'nonce-${nonce}' https://cdn.jsdelivr.net`,
            "require-sri-for script style",  // Require SRI
            "style-src 'self' https://cdn.jsdelivr.net"
        ].join('; ')
    );
    
    next();
});

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <!-- Must have SRI due to require-sri-for -->
            <link 
                rel="stylesheet" 
                href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
                integrity="sha384-9ndCyUaIbzAi2FUVXJi0CjmCapSmO7SnpJef0486qhLnuZ2cdeRhO02iuK6FUUVM"
                crossorigin="anonymous">
        </head>
        <body>
            <h1>SRI + CSP</h1>
            
            <!-- Must have SRI -->
            <script 
                src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"
                integrity="sha384-q8i/X+965DzO0rT7abK41JStQIAqVgRVzpbzo5smXKp4YfRvH+8abtTE1Pi6jizo"
                crossorigin="anonymous">
            </script>
            
            <!-- Nonce for inline scripts -->
            <script nonce="${res.locals.nonce}">
                console.log('Secure inline script');
            </script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

### 34.8.2 - Production Configuration

**Complete secure setup:**

```javascript
const express = require('express');
const helmet = require('helmet');
const crypto = require('crypto');
const fs = require('fs');

const app = express();

// Load SRI manifest
const sriManifest = JSON.parse(
    fs.readFileSync('sri-manifest.json', 'utf-8')
);

// Nonce middleware
app.use((req, res, next) => {
    res.locals.nonce = crypto.randomBytes(16).toString('base64');
    next();
});

// Helmet with CSP
app.use((req, res, next) => {
    helmet.contentSecurityPolicy({
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: [
                "'self'",
                `'nonce-${res.locals.nonce}'`,
                "https://cdn.jsdelivr.net",
                "https://cdnjs.cloudflare.com"
            ],
            styleSrc: [
                "'self'",
                "https://cdn.jsdelivr.net",
                "https://fonts.googleapis.com"
            ],
            fontSrc: [
                "'self'",
                "https://fonts.gstatic.com"
            ],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.example.com"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
            upgradeInsecureRequests: []
        }
    })(req, res, next);
});

// SRI helper
app.locals.getSRI = function(filepath) {
    const entry = sriManifest[filepath];
    return entry ? entry.integrity : '';
};

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Production Security</title>
            
            <link 
                rel="stylesheet" 
                href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css"
                integrity="${app.locals.getSRI('bootstrap.css')}"
                crossorigin="anonymous">
            
            <link 
                rel="stylesheet" 
                href="/css/app.css"
                integrity="${app.locals.getSRI('app.css')}"
                crossorigin="anonymous">
        </head>
        <body>
            <div class="container">
                <h1>Maximum Security</h1>
                <p>CSP + SRI + HTTPS + Helmet</p>
            </div>
            
            <script 
                src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"
                integrity="${app.locals.getSRI('axios.js')}"
                crossorigin="anonymous">
            </script>
            
            <script 
                src="/js/app.js"
                integrity="${app.locals.getSRI('app.js')}"
                crossorigin="anonymous">
            </script>
            
            <script nonce="${res.locals.nonce}">
                console.log('Application loaded securely');
            </script>
        </body>
        </html>
    `);
});

const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
    console.log(`Secure server running on port ${PORT}`);
    console.log('Security features: CSP, SRI, HSTS, X-Frame-Options');
});
```

---

**Capitolo 34 completato!**

Prossimo: **Capitolo 35 - MIME Types e Content-Type**
