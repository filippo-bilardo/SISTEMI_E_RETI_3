# 10. Cookies e Sessioni HTTP

## 10.1 Cookies

### 10.1.1 - Cosa sono i Cookies

I **cookies** sono piccoli file di testo memorizzati dal browser e inviati automaticamente con ogni richiesta HTTP allo stesso dominio.

**Scopo:**
- 🔐 Gestione sessioni (login)
- 📊 Tracking utente (analytics)
- 🛒 Carrello e-commerce
- ⚙️ Preferenze utente
- 🎯 Personalizzazione contenuto

**Dimensione max:** ~4KB per cookie

### 10.1.2 - Set-Cookie Header

**Server imposta cookie:**
```http
HTTP/1.1 200 OK
Set-Cookie: sessionId=abc123; Path=/; HttpOnly; Secure; SameSite=Strict
Set-Cookie: username=mario; Max-Age=3600
```

**Browser invia cookie:**
```http
GET /api/profile HTTP/1.1
Cookie: sessionId=abc123; username=mario
```

### 10.1.3 - Attributi Cookie

**Name=Value:**
```http
Set-Cookie: userId=123
```

**Expires:**
```http
Set-Cookie: token=xyz; Expires=Wed, 21 Oct 2025 07:28:00 GMT
```

**Max-Age (preferito):**
```http
Set-Cookie: sessionId=abc; Max-Age=3600
# Scade dopo 3600 secondi (1 ora)
```

**Domain:**
```http
Set-Cookie: token=xyz; Domain=example.com
# Inviato a example.com e tutti i sottodomini
# (www.example.com, api.example.com, ecc.)
```

```http
Set-Cookie: token=xyz; Domain=www.example.com
# Solo www.example.com
```

**Path:**
```http
Set-Cookie: data=value; Path=/api
# Inviato solo per /api/* requests
```

```http
Set-Cookie: data=value; Path=/
# Inviato per tutte le richieste
```

**Secure:**
```http
Set-Cookie: sessionId=abc; Secure
# Inviato SOLO su HTTPS
```

**HttpOnly:**
```http
Set-Cookie: sessionId=abc; HttpOnly
# Non accessibile via JavaScript (document.cookie)
# Previene XSS
```

**SameSite:**
```http
Set-Cookie: sessionId=abc; SameSite=Strict
# Strict: Mai inviato cross-site
# Lax: Inviato in top-level navigation GET
# None: Sempre inviato (richiede Secure)
```

### 10.1.4 - Cookie Prefixes

**__Secure- prefix:**
```http
Set-Cookie: __Secure-token=xyz; Secure; Path=/
# DEVE avere Secure
# Solo HTTPS
```

**__Host- prefix:**
```http
Set-Cookie: __Host-sessionId=abc; Secure; Path=/
# DEVE avere: Secure, Path=/, NO Domain
# Più sicuro, legato a exact host
```

### 10.1.5 - Express.js Cookie Management

**Set cookies:**
```javascript
const express = require('express');
const cookieParser = require('cookie-parser');

const app = express();
app.use(cookieParser());

// Simple cookie
app.get('/set-cookie', (req, res) => {
  res.cookie('username', 'mario', { 
    maxAge: 3600000, // 1 ora in ms
    httpOnly: false  // Accessibile da JS
  });
  res.send('Cookie set');
});

// Secure session cookie
app.get('/login', (req, res) => {
  res.cookie('sessionId', 'abc123', {
    httpOnly: true,   // No JavaScript access
    secure: true,     // HTTPS only
    sameSite: 'strict', // No cross-site
    maxAge: 24 * 60 * 60 * 1000 // 24h
  });
  res.send('Logged in');
});

// Signed cookie (tamper-proof)
app.use(cookieParser('secret-key'));

app.get('/set-signed', (req, res) => {
  res.cookie('userId', '123', { signed: true });
  res.send('Signed cookie set');
});

app.get('/read-signed', (req, res) => {
  const userId = req.signedCookies.userId;
  res.json({ userId });
});
```

**Read cookies:**
```javascript
app.get('/get-cookie', (req, res) => {
  const username = req.cookies.username;
  res.json({ username });
});
```

**Delete cookies:**
```javascript
app.get('/logout', (req, res) => {
  res.clearCookie('sessionId');
  res.send('Logged out');
});
```

### 10.1.6 - Client-Side Cookie (JavaScript)

**Set cookie:**
```javascript
// Simple
document.cookie = "username=mario";

// With attributes
document.cookie = "sessionId=abc123; max-age=3600; path=/; secure; samesite=strict";

// Helper function
function setCookie(name, value, days) {
  const expires = new Date(Date.now() + days * 24 * 60 * 60 * 1000).toUTCString();
  document.cookie = `${name}=${value}; expires=${expires}; path=/; secure; samesite=lax`;
}

setCookie('theme', 'dark', 365);
```

**Read cookie:**
```javascript
function getCookie(name) {
  const cookies = document.cookie.split('; ');
  
  for (const cookie of cookies) {
    const [key, value] = cookie.split('=');
    if (key === name) {
      return value;
    }
  }
  
  return null;
}

const theme = getCookie('theme'); // 'dark'
```

**Delete cookie:**
```javascript
function deleteCookie(name) {
  document.cookie = `${name}=; max-age=0; path=/`;
}

deleteCookie('theme');
```

**⚠️ Note:** Cookies con `HttpOnly` non sono accessibili via JavaScript.

### 10.1.7 - Cookie Security Best Practices

**✅ Session cookies:**
```http
Set-Cookie: __Host-sessionId=abc123; Secure; HttpOnly; SameSite=Strict; Path=/
```

**✅ CSRF token:**
```http
Set-Cookie: csrfToken=xyz789; Secure; SameSite=Strict; Path=/
```

**✅ Preference cookies:**
```http
Set-Cookie: theme=dark; Max-Age=31536000; Secure; SameSite=Lax; Path=/
```

**❌ Never store:**
- Passwords
- Credit card numbers
- Personal sensitive data

## 10.2 Sessioni

### 10.2.1 - Session Management

**Problema:** HTTP è stateless, ma applicazioni web servono stato (login, carrello).

**Soluzione:** Sessioni lato server identificate da session ID in cookie.

**Flow:**
```
1. User login
2. Server crea sessione
3. Server → Set-Cookie: sessionId=abc123
4. Client → Cookie: sessionId=abc123 (ogni richiesta)
5. Server lookup sessione da ID
6. Server ha accesso a dati utente
```

### 10.2.2 - Express.js Sessions

**express-session:**
```javascript
const session = require('express-session');

app.use(session({
  secret: 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,      // HTTPS only
    httpOnly: true,    // No JS access
    maxAge: 24 * 60 * 60 * 1000, // 24h
    sameSite: 'strict'
  }
}));

// Login
app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  
  const user = await authenticateUser(username, password);
  
  if (user) {
    // Store in session
    req.session.userId = user.id;
    req.session.username = user.username;
    req.session.role = user.role;
    
    res.json({ message: 'Logged in' });
  } else {
    res.status(401).json({ error: 'Invalid credentials' });
  }
});

// Protected route
app.get('/dashboard', (req, res) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Not logged in' });
  }
  
  res.json({ 
    username: req.session.username,
    role: req.session.role
  });
});

// Logout
app.post('/logout', (req, res) => {
  req.session.destroy(err => {
    if (err) {
      return res.status(500).json({ error: 'Logout failed' });
    }
    res.clearCookie('connect.sid');
    res.json({ message: 'Logged out' });
  });
});

// Session middleware
const requireAuth = (req, res, next) => {
  if (!req.session.userId) {
    return res.status(401).json({ error: 'Authentication required' });
  }
  next();
};

app.get('/api/profile', requireAuth, async (req, res) => {
  const user = await db.users.findById(req.session.userId);
  res.json(user);
});
```

### 10.2.3 - Redis Session Store

**Problema:** In-memory sessions perdute al restart server.

**Soluzione:** Persistenza con Redis.

```javascript
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const { createClient } = require('redis');

// Create Redis client
const redisClient = createClient({
  host: 'localhost',
  port: 6379
});

redisClient.connect().catch(console.error);

// Configure session with Redis
app.use(session({
  store: new RedisStore({ client: redisClient }),
  secret: 'your-secret-key',
  resave: false,
  saveUninitialized: false,
  cookie: {
    secure: true,
    httpOnly: true,
    maxAge: 24 * 60 * 60 * 1000
  }
}));
```

**Redis data:**
```
Key: sess:abc123
Value: {
  "cookie": {...},
  "userId": 123,
  "username": "mario",
  "role": "user"
}
TTL: 86400 (24h)
```

### 10.2.4 - Session vs JWT

| Feature | Session | JWT |
|---------|---------|-----|
| Storage | Server-side | Client-side |
| Scalability | Needs shared store (Redis) | Stateless, easy scaling |
| Revocation | Easy (delete from DB) | Hard (needs blacklist) |
| Size | Small cookie (ID only) | Large token (all data) |
| Security | Server controls data | Client sees data (signed) |
| Performance | DB lookup each request | No DB lookup |
| Use case | Traditional web apps | APIs, microservices |

**Quando usare Session:**
- ✅ Monolithic app
- ✅ Serve revoca immediata
- ✅ Dati session complessi

**Quando usare JWT:**
- ✅ Microservices
- ✅ Mobile/SPA apps
- ✅ Scalabilità orizzontale

## 10.3 CSRF Protection

### 10.3.1 - CSRF Attack

**Cross-Site Request Forgery:**

```html
<!-- Sito attaccante: evil.com -->
<img src="https://bank.com/transfer?to=attacker&amount=1000">
<!-- Se utente loggato su bank.com, cookie inviato automaticamente! -->
```

**Flow:**
```
1. User loggato su bank.com (cookie valido)
2. User visita evil.com
3. evil.com → Request a bank.com con cookie utente
4. bank.com esegue transfer (pensa sia l'utente)
```

### 10.3.2 - Protezione con CSRF Token

**Token unico per ogni sessione, validato lato server.**

**Express.js (csurf):**
```javascript
const csrf = require('csurf');

const csrfProtection = csrf({ cookie: true });

// Form GET (invia token)
app.get('/form', csrfProtection, (req, res) => {
  res.render('form', { csrfToken: req.csrfToken() });
});

// Form POST (valida token)
app.post('/submit', csrfProtection, (req, res) => {
  // Token validato automaticamente
  res.send('Form submitted');
});
```

**HTML Form:**
```html
<form method="POST" action="/submit">
  <input type="hidden" name="_csrf" value="<%= csrfToken %>">
  <input type="text" name="data">
  <button type="submit">Submit</button>
</form>
```

**AJAX:**
```javascript
// Get token from meta tag
const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

fetch('/api/data', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'CSRF-Token': csrfToken
  },
  body: JSON.stringify({ data: 'value' })
});
```

### 10.3.3 - SameSite Cookie (Modern CSRF Protection)

```http
Set-Cookie: sessionId=abc123; SameSite=Strict
```

**Strict:** Cookie mai inviato cross-site  
**Lax:** Cookie inviato in top-level navigation GET  
**None:** Cookie sempre inviato (legacy, richiede Secure)

**Esempio Strict:**
```
User su evil.com
evil.com → <a href="bank.com/transfer">Click</a>
User click → bank.com
Cookie sessionId NON inviato (SameSite=Strict)
User non autenticato, transfer fallisce ✅
```

**Best practice:** `SameSite=Strict` + CSRF token (defense in depth).

## 10.4 Cookie Consent (GDPR)

### 10.4.1 - Categorie Cookie

**Strictly Necessary (sempre permessi):**
- Session cookies
- Authentication
- Security (CSRF)
- Load balancing

**Functional:**
- Language preference
- User settings
- Remember me

**Analytics:**
- Google Analytics
- Heatmaps
- Performance monitoring

**Marketing/Advertising:**
- Tracking
- Retargeting
- Social media

### 10.4.2 - Implementation

```javascript
// Cookie consent library
const cookieConsent = require('cookie-consent');

app.use(cookieConsent({
  categories: ['necessary', 'functional', 'analytics', 'marketing'],
  defaultConsent: ['necessary']
}));

// Set cookie with category
app.get('/set-preference', (req, res) => {
  if (req.cookieConsent.functional) {
    res.cookie('theme', 'dark', { category: 'functional' });
  }
  res.send('Preference set');
});

// Analytics only if consented
app.get('/page', (req, res) => {
  if (req.cookieConsent.analytics) {
    // Track page view
    analytics.track('pageview', req.path);
  }
  res.render('page');
});
```

**Frontend banner:**
```html
<div id="cookie-banner" style="display: none;">
  <p>We use cookies to improve your experience.</p>
  <button onclick="acceptAll()">Accept All</button>
  <button onclick="acceptNecessary()">Necessary Only</button>
  <button onclick="showSettings()">Customize</button>
</div>

<script>
function acceptAll() {
  document.cookie = "cookie-consent=all; max-age=31536000; path=/; samesite=lax";
  hideBanner();
}

function acceptNecessary() {
  document.cookie = "cookie-consent=necessary; max-age=31536000; path=/; samesite=lax";
  hideBanner();
}

function hideBanner() {
  document.getElementById('cookie-banner').style.display = 'none';
}

// Show banner if no consent
if (!getCookie('cookie-consent')) {
  document.getElementById('cookie-banner').style.display = 'block';
}
</script>
```

## 10.5 Cookie Best Practices

**✅ Security:**
```javascript
res.cookie('sessionId', id, {
  httpOnly: true,      // ✅ Prevent XSS
  secure: true,        // ✅ HTTPS only
  sameSite: 'strict',  // ✅ Prevent CSRF
  maxAge: 3600000,     // ✅ Expiration
  signed: true         // ✅ Tamper detection
});
```

**✅ Performance:**
- Minimizza dimensione cookies
- Usa session storage per dati grandi
- Imposta Path correttamente (limita scope)

**✅ Privacy:**
- GDPR consent per non-necessary cookies
- Clear cookie policy
- Allow user to delete cookies

**❌ Never:**
- Store passwords/credit cards
- Store sensitive data unencrypted
- Use cookies without HTTPS (no Secure flag)
- Forget HttpOnly for session cookies

## 10.6 Esempi Completi

### 10.6.1 - Shopping Cart

```javascript
app.use(cookieParser());

// Add to cart
app.post('/cart/add', (req, res) => {
  const { productId, quantity } = req.body;
  
  let cart = req.cookies.cart ? JSON.parse(req.cookies.cart) : [];
  
  const existingItem = cart.find(item => item.productId === productId);
  
  if (existingItem) {
    existingItem.quantity += quantity;
  } else {
    cart.push({ productId, quantity });
  }
  
  res.cookie('cart', JSON.stringify(cart), {
    maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
    httpOnly: false, // Needs JS access
    sameSite: 'lax'
  });
  
  res.json({ cart });
});

// View cart
app.get('/cart', (req, res) => {
  const cart = req.cookies.cart ? JSON.parse(req.cookies.cart) : [];
  res.json({ cart });
});
```

### 10.6.2 - Remember Me

```javascript
app.post('/login', async (req, res) => {
  const { username, password, rememberMe } = req.body;
  
  const user = await authenticateUser(username, password);
  
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  // Session cookie
  req.session.userId = user.id;
  
  // Remember me cookie (long-lived)
  if (rememberMe) {
    const rememberToken = crypto.randomBytes(32).toString('hex');
    
    await db.rememberTokens.create({
      userId: user.id,
      token: rememberToken,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
    });
    
    res.cookie('rememberMe', rememberToken, {
      maxAge: 30 * 24 * 60 * 60 * 1000,
      httpOnly: true,
      secure: true,
      sameSite: 'strict'
    });
  }
  
  res.json({ message: 'Logged in' });
});

// Auto-login from remember token
app.use(async (req, res, next) => {
  if (!req.session.userId && req.cookies.rememberMe) {
    const token = await db.rememberTokens.findOne({
      token: req.cookies.rememberMe,
      expiresAt: { $gt: new Date() }
    });
    
    if (token) {
      req.session.userId = token.userId;
    } else {
      res.clearCookie('rememberMe');
    }
  }
  
  next();
});
```

---

**Capitolo 10 completato!**

Prossimo: **Capitolo 11 - HTTPS e TLS/SSL**
