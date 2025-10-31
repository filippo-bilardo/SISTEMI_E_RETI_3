# 39. Security Headers

## 39.1 Introduzione ai Security Headers

**Security headers** proteggono le applicazioni web da attacchi comuni.

**Header principali:**

```
1. Strict-Transport-Security (HSTS)
   - Forza HTTPS

2. Content-Security-Policy (CSP)
   - Previene XSS e code injection

3. X-Frame-Options
   - Previene clickjacking

4. X-Content-Type-Options
   - Previene MIME sniffing

5. Referrer-Policy
   - Controlla informazioni Referer

6. Permissions-Policy
   - Controlla API browser

7. X-XSS-Protection
   - Filtro XSS legacy

8. Cross-Origin-* Headers
   - CORS, CORP, COEP, COOP
```

---

## 39.2 Strict-Transport-Security (HSTS)

### 39.2.1 - HSTS Header

**Forza connessioni HTTPS:**

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**Parametri:**

```
max-age=<seconds>
   → Durata della policy (1 anno = 31536000)

includeSubDomains
   → Applica anche ai sottodomini

preload
   → Includi nella HSTS preload list dei browser
```

### 39.2.2 - Express HSTS

**Implementazione in Express:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// HSTS con Helmet
app.use(helmet.hsts({
    maxAge: 31536000,           // 1 anno in secondi
    includeSubDomains: true,    // Include sottodomini
    preload: true               // Preload list
}));

// HSTS manuale
app.use((req, res, next) => {
    if (req.secure || req.headers['x-forwarded-proto'] === 'https') {
        res.setHeader(
            'Strict-Transport-Security',
            'max-age=31536000; includeSubDomains; preload'
        );
    }
    next();
});

app.get('/', (req, res) => {
    res.send('HSTS enabled');
});

app.listen(3000);
```

### 39.2.3 - Nginx HSTS

**Nginx configuration:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    location / {
        proxy_pass http://localhost:3000;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com;
    
    return 301 https://$server_name$request_uri;
}
```

---

## 39.3 X-Frame-Options

### 39.3.1 - Clickjacking Prevention

**Previene embedding in iframe:**

```http
X-Frame-Options: DENY
   → Non può essere in iframe

X-Frame-Options: SAMEORIGIN
   → Solo iframe dallo stesso origin

X-Frame-Options: ALLOW-FROM https://example.com
   → Solo da specifico dominio (deprecato, usa CSP frame-ancestors)
```

### 39.3.2 - Express Implementation

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Con Helmet
app.use(helmet.frameguard({ action: 'deny' }));

// Manuale
app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'DENY');
    next();
});

// SAMEORIGIN per pagine con iframe interni
app.get('/dashboard', (req, res) => {
    res.setHeader('X-Frame-Options', 'SAMEORIGIN');
    res.send('<html>...</html>');
});

app.listen(3000);
```

**Moderno: CSP frame-ancestors**

```javascript
app.use((req, res, next) => {
    // CSP sostituisce X-Frame-Options
    res.setHeader('Content-Security-Policy', "frame-ancestors 'none'");
    next();
});
```

---

## 39.4 X-Content-Type-Options

### 39.4.1 - MIME Sniffing Prevention

**Previene MIME type sniffing:**

```http
X-Content-Type-Options: nosniff
```

**Problema senza nosniff:**

```javascript
// Senza nosniff
// Browser può interpretare text/plain come text/html se contiene HTML
res.setHeader('Content-Type', 'text/plain');
res.send('<script>alert("XSS")</script>');
// Browser potrebbe eseguire lo script!
```

### 39.4.2 - Express Implementation

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Con Helmet
app.use(helmet.noSniff());

// Manuale
app.use((req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    next();
});

// File upload sicuro
app.post('/upload', upload.single('file'), (req, res) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Content-Disposition', 'attachment');
    
    res.send(req.file.buffer);
});

app.listen(3000);
```

---

## 39.5 Referrer-Policy

### 39.5.1 - Referrer Control

**Controlla invio header Referer:**

```http
Referrer-Policy: no-referrer
   → Non invia mai Referer

Referrer-Policy: no-referrer-when-downgrade (default)
   → Non invia Referer su HTTPS → HTTP

Referrer-Policy: origin
   → Invia solo origin (https://example.com)

Referrer-Policy: origin-when-cross-origin
   → Full URL same-origin, solo origin cross-origin

Referrer-Policy: same-origin
   → Referer solo per same-origin

Referrer-Policy: strict-origin
   → Solo origin, non su downgrade HTTPS → HTTP

Referrer-Policy: strict-origin-when-cross-origin
   → Full URL same-origin, origin cross-origin, niente su downgrade

Referrer-Policy: unsafe-url
   → Sempre full URL (anche HTTPS → HTTP)
```

### 39.5.2 - Express Implementation

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Con Helmet
app.use(helmet.referrerPolicy({ 
    policy: 'strict-origin-when-cross-origin' 
}));

// Manuale
app.use((req, res, next) => {
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    next();
});

// Different policies per route
app.get('/public', (req, res) => {
    res.setHeader('Referrer-Policy', 'origin');
    res.send('Public page');
});

app.get('/private', authenticate, (req, res) => {
    res.setHeader('Referrer-Policy', 'no-referrer');
    res.send('Private page - no referer leaked');
});

app.listen(3000);
```

**HTML meta tag:**

```html
<!DOCTYPE html>
<html>
<head>
    <meta name="referrer" content="strict-origin-when-cross-origin">
</head>
<body>
    <!-- Link specifico -->
    <a href="https://external.com" referrerpolicy="no-referrer">
        External link (no referrer)
    </a>
</body>
</html>
```

---

## 39.6 Permissions-Policy

### 39.6.1 - Feature Policy

**Controlla accesso a API browser:**

```http
Permissions-Policy: geolocation=(), microphone=(), camera=()
   → Blocca tutte le origini

Permissions-Policy: geolocation=(self)
   → Solo same-origin

Permissions-Policy: geolocation=(self "https://maps.example.com")
   → Same-origin e dominio specifico

Permissions-Policy: geolocation=*
   → Tutte le origini (sconsigliato)
```

**Feature disponibili:**

```
- geolocation
- microphone
- camera
- payment
- usb
- accelerometer
- gyroscope
- magnetometer
- fullscreen
- picture-in-picture
- display-capture (screen sharing)
- web-share
- autoplay
- encrypted-media
```

### 39.6.2 - Express Implementation

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Con Helmet
app.use(helmet.permissionsPolicy({
    features: {
        geolocation: ["'none'"],
        microphone: ["'none'"],
        camera: ["'none'"],
        payment: ["'self'"],
        usb: ["'none'"],
        fullscreen: ["'self'"]
    }
}));

// Manuale
app.use((req, res, next) => {
    res.setHeader(
        'Permissions-Policy',
        [
            'geolocation=()',
            'microphone=()',
            'camera=()',
            'payment=(self)',
            'fullscreen=(self)'
        ].join(', ')
    );
    next();
});

// Video conferencing page
app.get('/video-call', (req, res) => {
    res.setHeader(
        'Permissions-Policy',
        'microphone=(self), camera=(self), display-capture=(self)'
    );
    res.send('<html>Video call page</html>');
});

app.listen(3000);
```

**HTML:**

```html
<!-- Iframe con permissions limitate -->
<iframe 
    src="https://maps.example.com" 
    allow="geolocation 'self' https://maps.example.com">
</iframe>

<iframe 
    src="https://video.example.com" 
    allow="camera; microphone">
</iframe>
```

---

## 39.7 Cross-Origin Headers

### 39.7.1 - CORP (Cross-Origin-Resource-Policy)

**Previene risorse caricate da altri origin:**

```http
Cross-Origin-Resource-Policy: same-origin
   → Solo stesso origin

Cross-Origin-Resource-Policy: same-site
   → Stesso site (*.example.com)

Cross-Origin-Resource-Policy: cross-origin
   → Qualsiasi origin
```

**Express:**

```javascript
const express = require('express');
const app = express();

// Immagini solo same-origin
app.use('/images', (req, res, next) => {
    res.setHeader('Cross-Origin-Resource-Policy', 'same-origin');
    next();
}, express.static('images'));

// API cross-origin
app.get('/api/public', (req, res) => {
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.json({ data: 'public' });
});

app.listen(3000);
```

### 39.7.2 - COEP (Cross-Origin-Embedder-Policy)

**Richiede CORP su risorse embedded:**

```http
Cross-Origin-Embedder-Policy: require-corp
   → Tutte le risorse devono avere CORP

Cross-Origin-Embedder-Policy: credentialless
   → Risorse cross-origin senza credenziali
```

**Express:**

```javascript
app.use((req, res, next) => {
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});
```

### 39.7.3 - COOP (Cross-Origin-Opener-Policy)

**Isola browsing context:**

```http
Cross-Origin-Opener-Policy: same-origin
   → Solo stesso origin in window.opener

Cross-Origin-Opener-Policy: same-origin-allow-popups
   → Permette popup cross-origin

Cross-Origin-Opener-Policy: unsafe-none
   → Default, nessuna restrizione
```

**Express:**

```javascript
app.use((req, res, next) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    next();
});

// Isolation completa per SharedArrayBuffer
app.use((req, res, next) => {
    res.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    res.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    next();
});
```

---

## 39.8 X-XSS-Protection (Legacy)

### 39.8.1 - XSS Filter

**Header legacy (deprecato, usare CSP):**

```http
X-XSS-Protection: 0
   → Disabilita filtro (raccomandato con CSP)

X-XSS-Protection: 1
   → Abilita filtro

X-XSS-Protection: 1; mode=block
   → Blocca pagina se XSS rilevato

X-XSS-Protection: 1; report=<reporting-uri>
   → Report XSS rilevato
```

**Express:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Disabilita X-XSS-Protection (usa CSP invece)
app.use(helmet.xssFilter({ setOnOldIE: true }));

// Oppure manuale
app.use((req, res, next) => {
    // Disabilita se hai CSP forte
    res.setHeader('X-XSS-Protection', '0');
    next();
});

app.listen(3000);
```

---

## 39.9 Complete Security Headers

### 39.9.1 - Helmet Full Configuration

**Tutti gli header di sicurezza:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Helmet con tutte le protezioni
app.use(helmet({
    // HSTS
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    
    // CSP
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"]
        }
    },
    
    // X-Frame-Options
    frameguard: {
        action: 'deny'
    },
    
    // X-Content-Type-Options
    noSniff: true,
    
    // Referrer-Policy
    referrerPolicy: {
        policy: 'strict-origin-when-cross-origin'
    },
    
    // Permissions-Policy
    permissionsPolicy: {
        features: {
            geolocation: ["'none'"],
            microphone: ["'none'"],
            camera: ["'none'"],
            payment: ["'self'"],
            usb: ["'none'"]
        }
    },
    
    // X-XSS-Protection (disabilitato)
    xssFilter: false,
    
    // Cross-Origin headers
    crossOriginEmbedderPolicy: true,
    crossOriginOpenerPolicy: { policy: 'same-origin' },
    crossOriginResourcePolicy: { policy: 'same-origin' },
    
    // Hide X-Powered-By
    hidePoweredBy: true,
    
    // DNS Prefetch Control
    dnsPrefetchControl: { allow: false },
    
    // IE No Open
    ieNoOpen: true,
    
    // Expect-CT (deprecato)
    expectCt: {
        maxAge: 86400,
        enforce: true
    }
}));

app.get('/', (req, res) => {
    res.send('Fully secured app');
});

app.listen(3000);
```

### 39.9.2 - Nginx Complete Headers

**Nginx security headers:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # CSP
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
    
    # X-Frame-Options
    add_header X-Frame-Options "DENY" always;
    
    # X-Content-Type-Options
    add_header X-Content-Type-Options "nosniff" always;
    
    # Referrer-Policy
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Permissions-Policy
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=(self)" always;
    
    # Cross-Origin headers
    add_header Cross-Origin-Opener-Policy "same-origin" always;
    add_header Cross-Origin-Embedder-Policy "require-corp" always;
    add_header Cross-Origin-Resource-Policy "same-origin" always;
    
    # X-XSS-Protection
    add_header X-XSS-Protection "0" always;
    
    # Hide server version
    server_tokens off;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 39.10 Testing Security Headers

### 39.10.1 - Check Headers

**Test con curl:**

```bash
# Check all headers
curl -I https://example.com

# Specific header
curl -I https://example.com | grep -i "strict-transport-security"

# Verbose
curl -v https://example.com 2>&1 | grep -i "< "
```

**Node.js test:**

```javascript
const https = require('https');

function checkSecurityHeaders(url) {
    https.get(url, (res) => {
        console.log('Security Headers:');
        console.log('=================');
        
        const securityHeaders = [
            'strict-transport-security',
            'content-security-policy',
            'x-frame-options',
            'x-content-type-options',
            'referrer-policy',
            'permissions-policy',
            'cross-origin-opener-policy',
            'cross-origin-embedder-policy',
            'cross-origin-resource-policy'
        ];
        
        securityHeaders.forEach(header => {
            const value = res.headers[header];
            if (value) {
                console.log(`✓ ${header}: ${value}`);
            } else {
                console.log(`✗ ${header}: MISSING`);
            }
        });
    });
}

checkSecurityHeaders('https://example.com');
```

### 39.10.2 - Automated Testing

**Jest test suite:**

```javascript
const request = require('supertest');
const app = require('./app');

describe('Security Headers', () => {
    test('should have HSTS header', async () => {
        const res = await request(app).get('/');
        expect(res.headers['strict-transport-security']).toBeDefined();
        expect(res.headers['strict-transport-security']).toContain('max-age=31536000');
    });
    
    test('should have CSP header', async () => {
        const res = await request(app).get('/');
        expect(res.headers['content-security-policy']).toBeDefined();
        expect(res.headers['content-security-policy']).toContain("default-src 'self'");
    });
    
    test('should have X-Frame-Options', async () => {
        const res = await request(app).get('/');
        expect(res.headers['x-frame-options']).toBe('DENY');
    });
    
    test('should have X-Content-Type-Options', async () => {
        const res = await request(app).get('/');
        expect(res.headers['x-content-type-options']).toBe('nosniff');
    });
    
    test('should have Referrer-Policy', async () => {
        const res = await request(app).get('/');
        expect(res.headers['referrer-policy']).toBeDefined();
    });
    
    test('should not expose X-Powered-By', async () => {
        const res = await request(app).get('/');
        expect(res.headers['x-powered-by']).toBeUndefined();
    });
});
```

### 39.10.3 - Online Tools

**Security header scanners:**

```
1. SecurityHeaders.com
   https://securityheaders.com/
   → Analizza tutti gli header di sicurezza
   → Assegna rating A-F

2. Mozilla Observatory
   https://observatory.mozilla.org/
   → Test completo sicurezza
   → Raccomandazioni specifiche

3. SSL Labs
   https://www.ssllabs.com/ssltest/
   → Test SSL/TLS
   → Verifica HSTS

4. Chrome DevTools
   → Network tab → Headers
   → Security tab → View certificate

5. curl command
   curl -I https://example.com
```

---

## 39.11 Production Best Practices

### 39.11.1 - Complete Production Setup

**Full production security:**

```javascript
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');

const app = express();

// Trust proxy (behind Nginx/load balancer)
app.set('trust proxy', 1);

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: 'Too many requests'
});
app.use(limiter);

// Helmet with all security headers
app.use(helmet({
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "'unsafe-inline'", 'https://cdn.example.com'],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", 'https://api.example.com'],
            fontSrc: ["'self'", 'https://fonts.gstatic.com'],
            objectSrc: ["'none'"],
            mediaSrc: ["'self'"],
            frameSrc: ["'none'"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"]
        }
    },
    frameguard: { action: 'deny' },
    noSniff: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
    permissionsPolicy: {
        features: {
            geolocation: ["'none'"],
            microphone: ["'none'"],
            camera: ["'none'"]
        }
    },
    crossOriginEmbedderPolicy: true,
    crossOriginOpenerPolicy: { policy: 'same-origin' },
    crossOriginResourcePolicy: { policy: 'same-origin' }
}));

// Body parser with limit
app.use(express.json({ limit: '10kb' }));
app.use(express.urlencoded({ extended: true, limit: '10kb' }));

// Sanitize data
app.use(mongoSanitize());

// Prevent parameter pollution
app.use(hpp());

// CORS
app.use((req, res, next) => {
    const allowedOrigins = ['https://example.com', 'https://www.example.com'];
    const origin = req.headers.origin;
    
    if (allowedOrigins.includes(origin)) {
        res.setHeader('Access-Control-Allow-Origin', origin);
    }
    
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    res.setHeader('Access-Control-Max-Age', '86400');
    
    if (req.method === 'OPTIONS') {
        return res.status(204).end();
    }
    
    next();
});

// Routes
app.get('/', (req, res) => {
    res.send('Secure app');
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Secure server running on port ${PORT}`);
});
```

---

**Capitolo 39 completato!** Tutti gli header di sicurezza HTTP: HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, Cross-Origin headers, e setup production completo! 🔒
