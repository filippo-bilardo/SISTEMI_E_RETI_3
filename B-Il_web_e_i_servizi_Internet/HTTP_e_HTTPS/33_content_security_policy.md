# 33. Content Security Policy (CSP)

## 33.1 Introduzione a CSP

**Content Security Policy (CSP)** è un header HTTP che previene attacchi XSS, clickjacking e code injection controllando quali risorse possono essere caricate.

**Perché CSP:**

```
Problems senza CSP:
1. XSS attacks - script malevoli iniettati
2. Data exfiltration - dati rubati verso server esterni
3. Clickjacking - pagine incorporate in iframe malevoli
4. Mixed content - risorse HTTP su pagine HTTPS

Solutions con CSP:
1. Whitelist di origini fidate
2. Blocco inline script/style
3. Report delle violazioni
4. Protezione iframe
```

---

## 33.2 CSP Directives

### 33.2.1 - Fetch Directives

**default-src:**

```
Base fallback per tutte le fetch directives

Content-Security-Policy: default-src 'self'

Significa: carica risorse solo dallo stesso origin
```

**script-src:**

```
Controlla JavaScript sources

Content-Security-Policy: script-src 'self' https://cdn.example.com

Allowed:
✓ <script src="/app.js"></script>
✓ <script src="https://cdn.example.com/lib.js"></script>

Blocked:
✗ <script src="http://evil.com/malware.js"></script>
✗ <script>alert('XSS')</script>  (inline)
✗ onclick="..." (inline event handlers)
```

**style-src:**

```
Controlla CSS sources

Content-Security-Policy: style-src 'self' 'unsafe-inline'

Allowed:
✓ <link href="/styles.css">
✓ <style>body { color: red; }</style>  (unsafe-inline)

Blocked:
✗ <link href="http://evil.com/malware.css">
```

**img-src:**

```
Controlla image sources

Content-Security-Policy: img-src 'self' data: https:

Allowed:
✓ <img src="/logo.png">
✓ <img src="data:image/png;base64,...">
✓ <img src="https://cdn.example.com/image.jpg">

Blocked:
✗ <img src="http://example.com/image.jpg">  (HTTP non permesso)
```

**connect-src:**

```
Controlla fetch, XMLHttpRequest, WebSocket

Content-Security-Policy: connect-src 'self' https://api.example.com

Allowed:
✓ fetch('/api/users')
✓ fetch('https://api.example.com/data')

Blocked:
✗ fetch('http://evil.com/steal')
```

**font-src, media-src, object-src, frame-src:**

```
Content-Security-Policy: 
    font-src 'self' https://fonts.gstatic.com;
    media-src 'self' https://cdn.example.com;
    object-src 'none';
    frame-src 'self'
```

### 33.2.2 - Document Directives

**base-uri:**

```
Limita URL in <base> tag

Content-Security-Policy: base-uri 'self'

Allowed:
✓ <base href="/">
✓ <base href="/app/">

Blocked:
✗ <base href="http://evil.com/">
```

**sandbox:**

```
Applica sandbox restrictions

Content-Security-Policy: sandbox allow-scripts allow-forms

Restrictions:
- Treats page as from unique origin
- Blocks form submission (unless allow-forms)
- Blocks scripts (unless allow-scripts)
- Blocks popups (unless allow-popups)
```

### 33.2.3 - Navigation Directives

**form-action:**

```
Limita form submission

Content-Security-Policy: form-action 'self'

Allowed:
✓ <form action="/submit">

Blocked:
✗ <form action="http://evil.com/steal">
```

**frame-ancestors:**

```
Controlla chi può embedare la pagina

Content-Security-Policy: frame-ancestors 'none'

Prevents:
✗ <iframe src="https://yoursite.com">  (clickjacking)

Options:
frame-ancestors 'none'           - Non può essere in iframe
frame-ancestors 'self'           - Solo same-origin iframe
frame-ancestors https://example.com  - Solo da example.com
```

---

## 33.3 CSP Keywords

### 33.3.1 - Source Keywords

**'self':**

```
Content-Security-Policy: script-src 'self'

Allows resources from same origin (protocol + domain + port)
```

**'none':**

```
Content-Security-Policy: object-src 'none'

Blocks all sources (no plugins allowed)
```

**'unsafe-inline':**

```
Content-Security-Policy: script-src 'self' 'unsafe-inline'

⚠️ Allows inline scripts (NOT RECOMMENDED)

<script>console.log('allowed')</script>
<div onclick="alert('allowed')">Click</div>
```

**'unsafe-eval':**

```
Content-Security-Policy: script-src 'self' 'unsafe-eval'

⚠️ Allows eval(), setTimeout(string), etc. (NOT RECOMMENDED)

eval('alert(1)')  // Allowed but dangerous
```

### 33.3.2 - Nonce-based CSP

**Using nonces for inline scripts:**

```javascript
// Server generates random nonce
const crypto = require('crypto');
const nonce = crypto.randomBytes(16).toString('base64');

res.setHeader(
    'Content-Security-Policy',
    `script-src 'self' 'nonce-${nonce}'`
);

// HTML
const html = `
<!DOCTYPE html>
<html>
<head>
    <script nonce="${nonce}">
        console.log('This inline script is allowed');
    </script>
    
    <script>
        console.log('This will be blocked - no nonce');
    </script>
</head>
<body>
    <script src="/app.js"></script>
</body>
</html>
`;

res.send(html);
```

**Express middleware with nonce:**

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();

// CSP middleware
app.use((req, res, next) => {
    const nonce = crypto.randomBytes(16).toString('base64');
    res.locals.nonce = nonce;
    
    res.setHeader(
        'Content-Security-Policy',
        `script-src 'self' 'nonce-${nonce}'; style-src 'self' 'nonce-${nonce}'`
    );
    
    next();
});

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <style nonce="${res.locals.nonce}">
                body { font-family: Arial; }
            </style>
        </head>
        <body>
            <h1>CSP with Nonce</h1>
            <script nonce="${res.locals.nonce}">
                console.log('Allowed inline script');
            </script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

### 33.3.3 - Hash-based CSP

**Using hashes for inline scripts:**

```javascript
const crypto = require('crypto');

// Calculate SHA-256 hash of inline script
const script = "console.log('Hello')";
const hash = crypto.createHash('sha256').update(script).digest('base64');

// CSP header
res.setHeader(
    'Content-Security-Policy',
    `script-src 'self' 'sha256-${hash}'`
);

// HTML
res.send(`
    <!DOCTYPE html>
    <html>
    <body>
        <script>console.log('Hello')</script>
    </body>
    </html>
`);
```

**Pre-calculate hashes:**

```javascript
const crypto = require('crypto');

const scripts = [
    "console.log('Script 1')",
    "console.log('Script 2')"
];

const hashes = scripts.map(script => {
    return 'sha256-' + crypto.createHash('sha256').update(script).digest('base64');
});

const csp = `script-src 'self' ${hashes.join(' ')}`;
console.log(csp);
// script-src 'self' 'sha256-abc123...' 'sha256-def456...'
```

---

## 33.4 CSP Configuration Examples

### 33.4.1 - Basic Strict CSP

**Secure default configuration:**

```javascript
const express = require('express');
const app = express();

app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            "script-src 'self'",
            "style-src 'self'",
            "img-src 'self' data: https:",
            "font-src 'self'",
            "connect-src 'self'",
            "frame-ancestors 'none'",
            "base-uri 'self'",
            "form-action 'self'"
        ].join('; ')
    );
    next();
});

app.listen(3000);
```

### 33.4.2 - CSP with CDN

**Allow external resources:**

```javascript
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            "script-src 'self' https://cdn.jsdelivr.net https://cdnjs.cloudflare.com",
            "style-src 'self' https://fonts.googleapis.com 'unsafe-inline'",
            "font-src 'self' https://fonts.gstatic.com",
            "img-src 'self' data: https:",
            "connect-src 'self' https://api.example.com",
            "frame-src 'none'",
            "object-src 'none'"
        ].join('; ')
    );
    next();
});
```

### 33.4.3 - CSP for SPA (React, Vue, Angular)

**Configuration for Single Page Applications:**

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();

app.use((req, res, next) => {
    const nonce = crypto.randomBytes(16).toString('base64');
    res.locals.nonce = nonce;
    
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            `script-src 'self' 'nonce-${nonce}'`,
            `style-src 'self' 'nonce-${nonce}' 'unsafe-inline'`,  // unsafe-inline for styled-components
            "img-src 'self' data: blob: https:",
            "font-src 'self' data:",
            "connect-src 'self' https://api.example.com wss://api.example.com",
            "frame-src 'none'",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
            "upgrade-insecure-requests"
        ].join('; ')
    );
    
    next();
});

// Serve React app
app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>React App</title>
        </head>
        <body>
            <div id="root"></div>
            <script nonce="${res.locals.nonce}" src="/static/js/bundle.js"></script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

---

## 33.5 CSP Reporting

### 33.5.1 - Report-Only Mode

**Test CSP without breaking site:**

```javascript
const express = require('express');
const app = express();

// Report violations without blocking
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy-Report-Only',
        [
            "default-src 'self'",
            "script-src 'self'",
            "report-uri /csp-violation-report"
        ].join('; ')
    );
    next();
});

// Report endpoint
app.post('/csp-violation-report', express.json({ type: 'application/csp-report' }), (req, res) => {
    console.log('CSP Violation:', JSON.stringify(req.body, null, 2));
    res.status(204).end();
});

app.listen(3000);
```

### 33.5.2 - Violation Reports

**Report structure:**

```json
{
  "csp-report": {
    "document-uri": "http://example.com/page",
    "referrer": "",
    "violated-directive": "script-src 'self'",
    "effective-directive": "script-src",
    "original-policy": "default-src 'self'; script-src 'self'; report-uri /csp-violation-report",
    "blocked-uri": "http://evil.com/malware.js",
    "status-code": 200,
    "script-sample": ""
  }
}
```

**Advanced report handler:**

```javascript
const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();

app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            "script-src 'self'",
            "style-src 'self' 'unsafe-inline'",
            "img-src 'self' data: https:",
            "report-uri /csp-violation-report",
            "report-to csp-endpoint"
        ].join('; ')
    );
    
    // Report-To header (newer API)
    res.setHeader('Report-To', JSON.stringify({
        group: 'csp-endpoint',
        max_age: 86400,
        endpoints: [
            { url: 'https://example.com/csp-violation-report' }
        ]
    }));
    
    next();
});

app.post('/csp-violation-report', express.json({ type: 'application/csp-report' }), (req, res) => {
    const violation = req.body['csp-report'];
    
    // Log violation
    const logEntry = {
        timestamp: new Date().toISOString(),
        documentUri: violation['document-uri'],
        violatedDirective: violation['violated-directive'],
        blockedUri: violation['blocked-uri'],
        userAgent: req.headers['user-agent']
    };
    
    console.error('CSP Violation:', logEntry);
    
    // Save to file
    const logFile = path.join(__dirname, 'csp-violations.log');
    fs.appendFileSync(logFile, JSON.stringify(logEntry) + '\n');
    
    // Send to monitoring service
    // sendToMonitoring(logEntry);
    
    res.status(204).end();
});

app.listen(3000);
```

### 33.5.3 - Report Analysis

**Analyze violations:**

```javascript
const fs = require('fs');

const violations = fs.readFileSync('csp-violations.log', 'utf-8')
    .split('\n')
    .filter(line => line.trim())
    .map(line => JSON.parse(line));

// Group by blocked URI
const blockedUris = {};
violations.forEach(v => {
    const uri = v.blockedUri;
    blockedUris[uri] = (blockedUris[uri] || 0) + 1;
});

console.log('Most blocked URIs:');
Object.entries(blockedUris)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)
    .forEach(([uri, count]) => {
        console.log(`${count}x - ${uri}`);
    });

// Group by directive
const directives = {};
violations.forEach(v => {
    const directive = v.violatedDirective;
    directives[directive] = (directives[directive] || 0) + 1;
});

console.log('\nViolated directives:');
Object.entries(directives)
    .sort((a, b) => b[1] - a[1])
    .forEach(([directive, count]) => {
        console.log(`${count}x - ${directive}`);
    });
```

---

## 33.6 Helmet.js Integration

### 33.6.1 - Basic Helmet Setup

**Using helmet for CSP:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Default helmet (includes basic CSP)
app.use(helmet());

// Custom CSP with helmet
app.use(
    helmet.contentSecurityPolicy({
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", "https://cdn.jsdelivr.net"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "https://api.example.com"],
            fontSrc: ["'self'"],
            objectSrc: ["'none'"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"]
        }
    })
);

app.listen(3000);
```

### 33.6.2 - Helmet with Nonce

**Dynamic nonce with helmet:**

```javascript
const express = require('express');
const helmet = require('helmet');
const crypto = require('crypto');

const app = express();

// Generate nonce middleware
app.use((req, res, next) => {
    res.locals.nonce = crypto.randomBytes(16).toString('base64');
    next();
});

// Helmet with dynamic nonce
app.use((req, res, next) => {
    helmet.contentSecurityPolicy({
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'", `'nonce-${res.locals.nonce}'`],
            styleSrc: ["'self'", `'nonce-${res.locals.nonce}'`]
        }
    })(req, res, next);
});

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <style nonce="${res.locals.nonce}">
                body { font-family: Arial; }
            </style>
        </head>
        <body>
            <h1>CSP with Helmet</h1>
            <script nonce="${res.locals.nonce}">
                console.log('Allowed');
            </script>
        </body>
        </html>
    `);
});

app.listen(3000);
```

---

## 33.7 Nginx CSP Configuration

### 33.7.1 - Static CSP in Nginx

**nginx.conf:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # CSP header
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self'; connect-src 'self' https://api.example.com; frame-ancestors 'none'; base-uri 'self'; form-action 'self'" always;
    
    location / {
        root /var/www/html;
        index index.html;
    }
}
```

### 33.7.2 - Dynamic CSP with Nginx

**Using Nginx variables:**

```nginx
map $request_uri $csp_script_src {
    default "'self'";
    ~^/admin/ "'self' 'unsafe-inline'";
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    # Dynamic CSP
    add_header Content-Security-Policy "default-src 'self'; script-src $csp_script_src; style-src 'self' 'unsafe-inline'" always;
    
    location / {
        root /var/www/html;
    }
}
```

---

## 33.8 CSP Best Practices

### 33.8.1 - Progressive CSP Implementation

**Step-by-step approach:**

```javascript
// Step 1: Report-Only mode
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy-Report-Only',
        "default-src 'self'; report-uri /csp-report"
    );
    next();
});

// Step 2: Analyze reports, adjust policy

// Step 3: Add more directives in Report-Only
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy-Report-Only',
        [
            "default-src 'self'",
            "script-src 'self' https://cdn.example.com",
            "style-src 'self' 'unsafe-inline'",
            "report-uri /csp-report"
        ].join('; ')
    );
    next();
});

// Step 4: Switch to enforcement
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        [
            "default-src 'self'",
            "script-src 'self' https://cdn.example.com",
            "style-src 'self' 'unsafe-inline'",
            "report-uri /csp-report"
        ].join('; ')
    );
    next();
});
```

### 33.8.2 - Avoid Unsafe Directives

**Eliminate unsafe-inline:**

```javascript
// ❌ Bad - unsafe-inline
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        "script-src 'self' 'unsafe-inline'"
    );
    next();
});

// ✓ Good - use nonces
app.use((req, res, next) => {
    const nonce = crypto.randomBytes(16).toString('base64');
    res.locals.nonce = nonce;
    res.setHeader(
        'Content-Security-Policy',
        `script-src 'self' 'nonce-${nonce}'`
    );
    next();
});

// ✓ Good - use hashes
app.use((req, res, next) => {
    res.setHeader(
        'Content-Security-Policy',
        "script-src 'self' 'sha256-xyz123...'"
    );
    next();
});
```

### 33.8.3 - Complete Production CSP

**Full production configuration:**

```javascript
const express = require('express');
const helmet = require('helmet');
const crypto = require('crypto');

const app = express();

// Nonce generation
app.use((req, res, next) => {
    res.locals.cspNonce = crypto.randomBytes(16).toString('base64');
    next();
});

// Comprehensive CSP
app.use((req, res, next) => {
    helmet.contentSecurityPolicy({
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: [
                "'self'",
                `'nonce-${res.locals.cspNonce}'`,
                "https://cdn.jsdelivr.net",
                "https://cdnjs.cloudflare.com"
            ],
            styleSrc: [
                "'self'",
                `'nonce-${res.locals.cspNonce}'`,
                "https://fonts.googleapis.com"
            ],
            imgSrc: ["'self'", "data:", "https:"],
            fontSrc: ["'self'", "https://fonts.gstatic.com"],
            connectSrc: [
                "'self'",
                "https://api.example.com",
                "wss://api.example.com"
            ],
            mediaSrc: ["'self'"],
            objectSrc: ["'none'"],
            frameSrc: ["'none'"],
            frameAncestors: ["'none'"],
            baseUri: ["'self'"],
            formAction: ["'self'"],
            upgradeInsecureRequests: [],
            blockAllMixedContent: []
        },
        reportOnly: false
    })(req, res, next);
});

// Additional security headers
app.use(helmet.hsts({
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
}));

app.use(helmet.noSniff());
app.use(helmet.frameguard({ action: 'deny' }));
app.use(helmet.xssFilter());

app.get('/', (req, res) => {
    res.send(`
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Secure App</title>
            <style nonce="${res.locals.cspNonce}">
                body { font-family: Arial, sans-serif; }
            </style>
        </head>
        <body>
            <h1>Content Security Policy Demo</h1>
            <script nonce="${res.locals.cspNonce}">
                console.log('Secure inline script with nonce');
            </script>
            <script src="https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js"></script>
        </body>
        </html>
    `);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT} with strict CSP`);
});
```

---

**Capitolo 33 completato!**

Prossimo: **Capitolo 34 - Subresource Integrity (SRI)**
