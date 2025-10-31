# 20. Information Disclosure

## 20.1 Introduzione

**Information Disclosure** (leakage) rivela informazioni sensibili su sistema, configurazione, dati interni.

**Informazioni a rischio:**
- 🔴 Versioni software/server
- 🔴 Struttura directory
- 🔴 Credenziali e API keys
- 🔴 Indirizzi IP interni
- 🔴 Stack traces ed errori dettagliati
- 🔴 Commenti nel codice sorgente
- 🔴 Metadati file
- 🔴 Configurazioni di debug

**Impatto:**
- Facilita reconnaissance per attacchi mirati
- Espone vulnerabilità note (CVE) via versioni
- Rivela struttura applicazione
- Leak di dati sensibili (password, token, PII)

---

## 20.2 Server Version Disclosure

### 20.2.1 - Default Server Headers

**Problema: Header HTTP rivelano versioni:**

```bash
curl -I https://example.com

HTTP/1.1 200 OK
Server: Apache/2.4.41 (Ubuntu)
X-Powered-By: PHP/7.4.3
X-AspNet-Version: 4.0.30319
```

**Attaccante usa queste info per:**
```
1. Apache 2.4.41 → Cerca CVE per questa versione
2. PHP 7.4.3 → Identifica vulnerabilità note
3. Target exploit specifici
```

### 20.2.2 - Hide Server Version (Nginx)

**Nginx default:**

```nginx
# /etc/nginx/nginx.conf

http {
    # Default: server_tokens on;
    # Header: Server: nginx/1.18.0
    
    # Nascondi versione
    server_tokens off;
    # Header: Server: nginx
}
```

**Nascondere completamente nome server:**

```nginx
http {
    server_tokens off;
    
    # Usa more_set_headers module (nginx-extras)
    more_set_headers 'Server: Web Server';
}
```

**Install nginx-extras (Ubuntu/Debian):**

```bash
sudo apt install nginx-extras

# Verifica modulo
nginx -V 2>&1 | grep more_set_headers
```

**Config con custom server header:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    server_tokens off;
    more_set_headers 'Server: ';  # Rimuove completamente
    # oppure
    # more_set_headers 'Server: MyApp';  # Nome custom
    
    location / {
        root /var/www/html;
    }
}
```

**Verifica:**

```bash
curl -I https://example.com

HTTP/2 200 OK
# Server header rimosso o custom
```

### 20.2.3 - Hide Server Version (Apache)

**Apache default:**

```bash
curl -I https://example.com

Server: Apache/2.4.41 (Ubuntu) OpenSSL/1.1.1f
```

**Nascondi versione:**

```apache
# /etc/apache2/conf-available/security.conf

# Default: ServerTokens OS
# Mostra: Apache/2.4.41 (Ubuntu)

ServerTokens Prod
# Mostra solo: Apache

ServerSignature Off
# Rimuove footer in error pages
```

**Enable configuration:**

```bash
sudo a2enconf security
sudo systemctl reload apache2

# Verifica
curl -I https://example.com
# Server: Apache (senza versione)
```

**Valori ServerTokens:**

```
Full        → Apache/2.4.41 (Ubuntu) OpenSSL/1.1.1f PHP/7.4.3
OS          → Apache/2.4.41 (Ubuntu)
Minor       → Apache/2.4
Minimal     → Apache/2
Major       → Apache/2
Prod        → Apache
```

### 20.2.4 - Remove X-Powered-By (Express.js)

**Express default:**

```javascript
const express = require('express');
const app = express();

app.get('/', (req, res) => {
    res.send('Hello');
});

app.listen(3000);
```

**Response:**
```http
HTTP/1.1 200 OK
X-Powered-By: Express
```

**Rimuovi header:**

```javascript
const express = require('express');
const app = express();

// Disabilita X-Powered-By
app.disable('x-powered-by');

app.get('/', (req, res) => {
    res.send('Hello');
});

app.listen(3000);
```

**Oppure con helmet:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

app.use(helmet.hidePoweredBy());

app.listen(3000);
```

---

## 20.3 Error Message Disclosure

### 20.3.1 - Detailed Error Messages

**Problema: Stack traces in production:**

```javascript
// Express app senza error handling
const express = require('express');
const app = express();

app.get('/user/:id', (req, res) => {
    const userId = req.params.id;
    
    // Query database
    db.query('SELECT * FROM users WHERE id = ?', [userId], (err, result) => {
        if (err) {
            // ❌ ERRORE: Leak dettagli
            res.status(500).send(err);
        }
        res.json(result);
    });
});
```

**Response con errore:**

```http
HTTP/1.1 500 Internal Server Error

Error: ER_NO_SUCH_TABLE: Table 'mydb.users' doesn't exist
    at Query.Sequence._packetToError (/app/node_modules/mysql/lib/protocol/sequences/Sequence.js:47:14)
    at /app/node_modules/mysql/lib/protocol/Protocol.js:188:14
    at /app/server.js:125:9
```

**Leak:**
- Database type (MySQL)
- Table name (users)
- File paths (/app/server.js)
- Framework details (mysql module)

### 20.3.2 - Safe Error Handling

**Express production error handler:**

```javascript
const express = require('express');
const app = express();

// Routes
app.get('/user/:id', async (req, res, next) => {
    try {
        const userId = req.params.id;
        const result = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
        res.json(result);
    } catch (err) {
        // Passa errore a error handler
        next(err);
    }
});

// Error handling middleware (DEVE essere ultimo)
app.use((err, req, res, next) => {
    // Log dettagliato (solo server-side)
    console.error('Error details:', {
        message: err.message,
        stack: err.stack,
        timestamp: new Date().toISOString(),
        url: req.url,
        method: req.method
    });
    
    // Response generica (client)
    if (process.env.NODE_ENV === 'production') {
        res.status(500).json({
            error: 'Internal Server Error',
            message: 'An unexpected error occurred'
        });
    } else {
        // Development: mostra dettagli
        res.status(500).json({
            error: err.message,
            stack: err.stack
        });
    }
});

app.listen(3000);
```

**Nginx custom error pages:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /var/www/errors;
        internal;
    }
    
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
    
    # Nascondi versione Nginx in error pages
    server_tokens off;
}
```

**Custom 404.html:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Page Not Found</title>
</head>
<body>
    <h1>404 - Page Not Found</h1>
    <p>The requested page does not exist.</p>
    <!-- ❌ NON includere dettagli percorsi, server, etc. -->
</body>
</html>
```

---

## 20.4 Directory Listing

### 20.4.1 - Exposed Directory Structure

**Problema: Autoindex abilitato:**

**Nginx default (a volte):**

```nginx
location /uploads {
    root /var/www;
    autoindex on;  # ❌ PERICOLOSO
}
```

**Browser mostra:**

```
Index of /uploads/
../
contract.pdf          2024-01-15 10:30    2.5M
passwords.txt         2024-01-10 14:22    156
backup-db.sql         2024-01-08 09:15    45M
id_rsa                2024-01-05 11:00    1.6K
```

**Attaccante scarica file sensibili!**

### 20.4.2 - Disable Directory Listing

**Nginx:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    location / {
        root /var/www/html;
        autoindex off;  # ✅ Disabilita listing
    }
    
    # Blocca accesso a directory comuni
    location ~ ^/(backup|config|\.git|\.env|node_modules) {
        deny all;
        return 404;
    }
}
```

**Apache:**

```apache
<Directory /var/www/html>
    Options -Indexes  # ✅ Disabilita listing
    AllowOverride None
    Require all granted
</Directory>

# Blocca file sensibili
<FilesMatch "^\.env|^\.git|\.sql$|\.bak$">
    Require all denied
</FilesMatch>
```

**Express.js:**

```javascript
const express = require('express');
const path = require('path');

const app = express();

// ❌ MAI usare:
// app.use(express.static('public', { dotfiles: 'allow', index: false }));

// ✅ Safe static files
app.use(express.static('public', {
    dotfiles: 'deny',     // Blocca file nascosti (.env, .git, etc.)
    index: 'index.html',  // Serve index.html invece di listing
    redirect: false       // No redirect automatici
}));

app.listen(3000);
```

---

## 20.5 Sensitive Data in Responses

### 20.5.1 - Verbose API Responses

**Problema: Troppi dati in JSON:**

```javascript
app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    
    // ❌ ERRORE: Invia tutto il record
    res.json(user);
});
```

**Response leak:**

```json
{
    "id": 123,
    "username": "john_doe",
    "email": "john@example.com",
    "password_hash": "$2b$10$EixZaYVK1fsbw1ZfbX3OX...",
    "api_key": "sk_live_abc123xyz",
    "credit_card": "4532-1111-2222-3333",
    "ssn": "123-45-6789",
    "internal_notes": "VIP customer, bypass fraud checks",
    "created_at": "2023-01-15T10:30:00Z",
    "last_login_ip": "192.168.1.100"
}
```

**Soluzione: Whitelist fields:**

```javascript
app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    
    // ✅ Solo campi pubblici
    const safeUser = {
        id: user.id,
        username: user.username,
        avatar: user.avatar_url
    };
    
    res.json(safeUser);
});
```

**Oppure usa serializer:**

```javascript
class UserSerializer {
    static publicFields(user) {
        return {
            id: user.id,
            username: user.username,
            avatar: user.avatar_url,
            created_at: user.created_at
        };
    }
    
    static privateFields(user) {
        return {
            ...this.publicFields(user),
            email: user.email,
            phone: user.phone
        };
    }
}

app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    
    // Owner vede tutti i campi
    if (req.user.id === user.id) {
        res.json(UserSerializer.privateFields(user));
    } else {
        // Altri vedono solo pubblici
        res.json(UserSerializer.publicFields(user));
    }
});
```

### 20.5.2 - Comments in Production Code

**Problema: Commenti sensibili in HTML/JS:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Login</title>
</head>
<body>
    <form action="/login" method="POST">
        <input name="username">
        <input name="password" type="password">
        <button>Login</button>
    </form>
    
    <!-- TODO: Remove debug endpoint /api/debug before production -->
    <!-- Admin password: temp123 (change later!) -->
    <!-- Database server: db-internal.company.local -->
    
    <script>
        // API key for testing: sk_test_abc123xyz
        // Production key in .env file
    </script>
</body>
</html>
```

**Soluzione: Build process rimuove commenti:**

**Webpack config:**

```javascript
// webpack.config.js
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    mode: 'production',
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    format: {
                        comments: false  // ✅ Rimuove tutti i commenti
                    }
                },
                extractComments: false
            })
        ]
    }
};
```

**HTML minifier (Gulp):**

```javascript
const gulp = require('gulp');
const htmlmin = require('gulp-htmlmin');

gulp.task('minify-html', () => {
    return gulp.src('src/*.html')
        .pipe(htmlmin({
            collapseWhitespace: true,
            removeComments: true  // ✅ Rimuove commenti
        }))
        .pipe(gulp.dest('dist'));
});
```

---

## 20.6 Debug Mode in Production

### 20.6.1 - Debug Endpoints

**Problema: Endpoint di debug attivi:**

```javascript
const express = require('express');
const app = express();

// ❌ ERRORE: Debug endpoint in production
app.get('/debug/env', (req, res) => {
    res.json(process.env);  // Leak tutte le env vars!
});

app.get('/debug/routes', (req, res) => {
    res.json(app._router.stack);  // Leak tutte le routes
});

app.get('/debug/sessions', (req, res) => {
    // Leak sessioni attive
    res.json(sessionStore.all());
});
```

**Soluzione: Rimuovi o proteggi:**

```javascript
const express = require('express');
const app = express();

// ✅ Solo in development
if (process.env.NODE_ENV === 'development') {
    app.get('/debug/env', (req, res) => {
        res.json(process.env);
    });
}

// ✅ Oppure proteggi con autenticazione
const isAdmin = (req, res, next) => {
    if (req.user && req.user.role === 'admin') {
        next();
    } else {
        res.status(403).json({ error: 'Forbidden' });
    }
};

app.get('/admin/debug', isAdmin, (req, res) => {
    res.json({
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        // Solo informazioni safe
    });
});
```

### 20.6.2 - Environment Variables

**Problema: .env file esposto:**

```bash
# .env file nella web root
# http://example.com/.env

DB_HOST=internal-db.company.local
DB_USER=admin
DB_PASSWORD=SuperSecret123!
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
STRIPE_SECRET_KEY=sk_live_abc123xyz
```

**Soluzione: Blocca accesso:**

**Nginx:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    # Blocca file sensibili
    location ~ /\. {
        deny all;
        return 404;
    }
    
    location ~ \.(env|git|sql|bak|log)$ {
        deny all;
        return 404;
    }
}
```

**Apache (.htaccess):**

```apache
<FilesMatch "^\.env">
    Require all denied
</FilesMatch>

<FilesMatch "\.(sql|bak|log|old)$">
    Require all denied
</FilesMatch>
```

**Express.js:**

```javascript
const express = require('express');
const app = express();

// Blocca file sensibili
app.use((req, res, next) => {
    const blocked = ['.env', '.git', '.sql', '.bak', '.log'];
    
    if (blocked.some(ext => req.path.includes(ext))) {
        return res.status(404).send('Not Found');
    }
    
    next();
});
```

**File system protection:**

```bash
# Sposta .env fuori da web root
/var/www/
├── app/               # Web root
│   ├── public/
│   └── index.html
└── config/
    └── .env          # ✅ Non accessibile via HTTP

# Permissions
chmod 600 /var/www/config/.env
chown www-data:www-data /var/www/config/.env
```

---

## 20.7 Security.txt & Responsible Disclosure

### 20.7.1 - security.txt File

**RFC 9116: Security information endpoint:**

```
# /.well-known/security.txt

Contact: security@example.com
Expires: 2025-12-31T23:59:59.000Z
Preferred-Languages: en, it
Canonical: https://example.com/.well-known/security.txt

# Policy
Policy: https://example.com/security-policy

# Acknowledgments
Acknowledgments: https://example.com/hall-of-fame

# Hiring
Hiring: https://example.com/jobs/security-engineer
```

**Nginx serve security.txt:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;
    
    location = /.well-known/security.txt {
        alias /var/www/.well-known/security.txt;
        add_header Content-Type text/plain;
    }
}
```

**Generate signed security.txt:**

```bash
# Create GPG key
gpg --full-generate-key

# Sign security.txt
gpg --clearsign security.txt

# Risultato: security.txt.asc
```

---

## 20.8 Best Practices

### 20.8.1 - Complete Hardening Checklist

**Server configuration:**
```
✅ server_tokens off (Nginx)
✅ ServerTokens Prod (Apache)
✅ Remove X-Powered-By headers
✅ Custom error pages (no stack traces)
✅ Disable directory listing
✅ Block sensitive files (.env, .git, .sql, .bak)
✅ HTTPS only
✅ Security headers (CSP, HSTS, etc.)
```

**Application code:**
```
✅ Environment-based error handling
✅ Whitelist API response fields
✅ Remove debug endpoints in production
✅ Sanitize error messages
✅ Log errors server-side (not client)
✅ Use serializers for data exposure
✅ Minify/remove comments in production build
```

**Secrets management:**
```
✅ .env outside web root
✅ Proper file permissions (600)
✅ Rotate API keys regularly
✅ Use secrets manager (AWS Secrets Manager, Vault)
✅ Never commit secrets to Git
✅ .gitignore: .env, *.key, *.pem
```

**Monitoring:**
```
✅ Log access to sensitive endpoints
✅ Alert on 500 errors (stack trace leak?)
✅ Monitor for directory traversal attempts
✅ Rate limit error responses
```

### 20.8.2 - Production-Ready Configuration

**Complete Express.js secure app:**

```javascript
const express = require('express');
const helmet = require('helmet');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../config/.env') });

const app = express();

// Security headers
app.use(helmet({
    hidePoweredBy: true,
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            frameAncestors: ["'none'"]
        }
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true
    }
}));

// Blocca file sensibili
app.use((req, res, next) => {
    const blocked = ['.env', '.git', '.sql', '.bak', '.log', 'node_modules'];
    
    if (blocked.some(pattern => req.path.includes(pattern))) {
        return res.status(404).send('Not Found');
    }
    
    next();
});

// Static files (safe)
app.use(express.static('public', {
    dotfiles: 'deny',
    index: 'index.html'
}));

// API routes
app.get('/api/users/:id', async (req, res, next) => {
    try {
        const user = await User.findById(req.params.id);
        
        // Whitelist fields
        res.json({
            id: user.id,
            username: user.username,
            avatar: user.avatar_url
        });
    } catch (err) {
        next(err);
    }
});

// Error handler
app.use((err, req, res, next) => {
    // Log dettagliato (server-side)
    console.error({
        timestamp: new Date().toISOString(),
        error: err.message,
        stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
        url: req.url,
        method: req.method,
        ip: req.ip
    });
    
    // Response generica (client)
    res.status(err.status || 500).json({
        error: process.env.NODE_ENV === 'production' 
            ? 'Internal Server Error' 
            : err.message
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not Found' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

**Nginx production config:**

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # Security headers
    server_tokens off;
    more_set_headers 'Server: ';
    
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Custom error pages
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    
    location = /404.html {
        root /var/www/errors;
        internal;
    }
    
    location = /50x.html {
        root /var/www/errors;
        internal;
    }
    
    # Blocca file sensibili
    location ~ /\. {
        deny all;
        return 404;
    }
    
    location ~ \.(env|git|sql|bak|log|old)$ {
        deny all;
        return 404;
    }
    
    # Disable directory listing
    location / {
        root /var/www/html;
        autoindex off;
        try_files $uri $uri/ =404;
    }
    
    # Security.txt
    location = /.well-known/security.txt {
        alias /var/www/.well-known/security.txt;
        add_header Content-Type text/plain;
    }
}
```
