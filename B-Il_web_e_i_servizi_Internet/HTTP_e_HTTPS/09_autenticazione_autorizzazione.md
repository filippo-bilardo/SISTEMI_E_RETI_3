# 9. Autenticazione e Autorizzazione HTTP

## 9.1 Differenza tra Autenticazione e Autorizzazione

**Autenticazione (Authentication):**
- ❓ "Chi sei?"
- 🔑 Verifica identità utente
- 📝 Login con username/password, token, certificato

**Autorizzazione (Authorization):**
- ❓ "Cosa puoi fare?"
- 🛡️ Verifica permessi utente
- 📋 Accesso a risorse specifiche

**Esempio:**
```
User: Mario (autenticato)
Role: Editor (autorizzazione)

✅ Può: Creare articoli, modificare propri articoli
❌ Non può: Eliminare utenti (solo Admin)
```

## 9.2 HTTP Basic Authentication

### 9.2.1 - Come Funziona

**Flow:**
```
1. Client → GET /api/data
2. Server → 401 Unauthorized
           WWW-Authenticate: Basic realm="API"
3. Client → GET /api/data
           Authorization: Basic dXNlcjpwYXNz
4. Server → 200 OK (se credenziali valide)
```

### 9.2.2 - Header Format

**Server challenge:**
```http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Restricted Area"
```

**Client credentials:**
```http
GET /api/data HTTP/1.1
Authorization: Basic dXNlcjpwYXNzd29yZA==
```

**Encoding:**
```javascript
const username = 'user';
const password = 'password';
const credentials = Buffer.from(`${username}:${password}`).toString('base64');
// "user:password" → "dXNlcjpwYXNzd29yZA=="
```

### 9.2.3 - Implementazione

**Express.js:**
```javascript
const basicAuth = require('express-basic-auth');

// Simple
app.use(basicAuth({
  users: { 
    'admin': 'supersecret',
    'user': 'password123'
  },
  challenge: true,
  realm: 'API'
}));

// Custom authorizer
app.use(basicAuth({
  authorizer: async (username, password, cb) => {
    const user = await db.users.findOne({ username });
    
    if (user && await bcrypt.compare(password, user.passwordHash)) {
      return cb(null, true);
    }
    
    cb(null, false);
  },
  authorizeAsync: true,
  challenge: true
}));
```

**Manual implementation:**
```javascript
const basicAuthMiddleware = async (req, res, next) => {
  const authHeader = req.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Basic ')) {
    res.set('WWW-Authenticate', 'Basic realm="API"');
    return res.status(401).json({ error: 'Authentication required' });
  }
  
  const base64Credentials = authHeader.split(' ')[1];
  const credentials = Buffer.from(base64Credentials, 'base64').toString('utf-8');
  const [username, password] = credentials.split(':');
  
  const user = await db.users.findOne({ username });
  
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  req.user = user;
  next();
};

app.get('/api/protected', basicAuthMiddleware, (req, res) => {
  res.json({ message: `Hello ${req.user.username}` });
});
```

**Nginx:**
```nginx
location /admin {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

**Create .htpasswd:**
```bash
htpasswd -c /etc/nginx/.htpasswd admin
# Inserisci password quando richiesto
```

### 9.2.4 - Sicurezza

**⚠️ PROBLEMI:**
- ❌ Credenziali in Base64 (NON criptate!)
- ❌ Inviate in ogni richiesta
- ❌ No logout (browser cache credenziali)
- ❌ Difficile invalidare sessione

**✅ BEST PRACTICES:**
- ✅ **SEMPRE** usare HTTPS
- ✅ Usare solo per API interne o sviluppo
- ✅ Preferire Bearer token per produzione

**Esempio insicuro (HTTP):**
```http
GET /api/data HTTP/1.1
Authorization: Basic dXNlcjpwYXNz
# Base64 decode = "user:pass" in chiaro!
# Intercettabile da attaccante
```

**Sicuro (HTTPS):**
```http
GET /api/data HTTPS/1.1
Authorization: Basic dXNlcjpwYXNz
# Traffico criptato con TLS
```

## 9.3 Bearer Token Authentication (JWT)

### 9.3.1 - JSON Web Token (JWT)

**Struttura:**
```
header.payload.signature
```

**Example:**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

**Decoded:**
```json
// Header
{
  "alg": "HS256",
  "typ": "JWT"
}

// Payload
{
  "sub": "1234567890",
  "name": "John Doe",
  "iat": 1516239022,
  "exp": 1516242622
}

// Signature
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

### 9.3.2 - Flow

**Login:**
```http
POST /api/login HTTP/1.1
Content-Type: application/json

{"username": "mario", "password": "secret123"}

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": 3600
  }
```

**Richieste successive:**
```http
GET /api/user/profile HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

→ HTTP/1.1 200 OK
  Content-Type: application/json
  
  {"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}
```

### 9.3.3 - Implementazione

**Express.js:**
```javascript
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
const JWT_EXPIRES_IN = '1h';

// Login
app.post('/api/login', async (req, res) => {
  const { username, password } = req.body;
  
  // Trova utente
  const user = await db.users.findOne({ username });
  if (!user) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  // Verifica password
  const valid = await bcrypt.compare(password, user.passwordHash);
  if (!valid) {
    return res.status(401).json({ error: 'Invalid credentials' });
  }
  
  // Genera token
  const token = jwt.sign(
    { 
      userId: user.id,
      username: user.username,
      role: user.role
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
  
  res.json({ 
    token,
    expiresIn: 3600
  });
});

// Middleware autenticazione
const authenticateToken = (req, res, next) => {
  const authHeader = req.get('Authorization');
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
  
  if (!token) {
    return res.status(401).json({ error: 'Token required' });
  }
  
  jwt.verify(token, JWT_SECRET, (err, decoded) => {
    if (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ error: 'Token expired' });
      }
      return res.status(403).json({ error: 'Invalid token' });
    }
    
    req.user = decoded;
    next();
  });
};

// Protected route
app.get('/api/user/profile', authenticateToken, async (req, res) => {
  const user = await db.users.findById(req.user.userId);
  res.json(user);
});

// Middleware autorizzazione (role-based)
const requireRole = (role) => {
  return (req, res, next) => {
    if (req.user.role !== role) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
};

app.delete('/api/users/:id', 
  authenticateToken, 
  requireRole('admin'),
  async (req, res) => {
    await db.users.delete(req.params.id);
    res.json({ message: 'User deleted' });
  }
);
```

**Client (JavaScript):**
```javascript
// Login
async function login(username, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  });
  
  const { token } = await response.json();
  localStorage.setItem('token', token);
  
  return token;
}

// Richiesta autenticata
async function fetchProfile() {
  const token = localStorage.getItem('token');
  
  const response = await fetch('/api/user/profile', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  if (response.status === 401) {
    // Token expired, redirect to login
    window.location.href = '/login';
    return;
  }
  
  return await response.json();
}

// Logout
function logout() {
  localStorage.removeItem('token');
  window.location.href = '/login';
}
```

### 9.3.4 - Refresh Token

**Problema:** JWT expiration breve (15 min) per sicurezza, ma re-login frequente scomodo.

**Soluzione:** Refresh token (long-lived) per ottenere nuovo access token.

```javascript
// Login (return both tokens)
app.post('/api/login', async (req, res) => {
  const user = await authenticateUser(req.body);
  
  const accessToken = jwt.sign(
    { userId: user.id, username: user.username, role: user.role },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
  
  const refreshToken = jwt.sign(
    { userId: user.id },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );
  
  // Store refresh token in DB
  await db.refreshTokens.create({
    userId: user.id,
    token: refreshToken,
    expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
  });
  
  res.json({ 
    accessToken,
    refreshToken,
    expiresIn: 900
  });
});

// Refresh endpoint
app.post('/api/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  
  if (!refreshToken) {
    return res.status(401).json({ error: 'Refresh token required' });
  }
  
  // Verify refresh token
  let decoded;
  try {
    decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
  } catch (err) {
    return res.status(403).json({ error: 'Invalid refresh token' });
  }
  
  // Check if token exists in DB
  const storedToken = await db.refreshTokens.findOne({
    userId: decoded.userId,
    token: refreshToken
  });
  
  if (!storedToken) {
    return res.status(403).json({ error: 'Refresh token not found' });
  }
  
  // Generate new access token
  const user = await db.users.findById(decoded.userId);
  const newAccessToken = jwt.sign(
    { userId: user.id, username: user.username, role: user.role },
    JWT_SECRET,
    { expiresIn: '15m' }
  );
  
  res.json({ 
    accessToken: newAccessToken,
    expiresIn: 900
  });
});

// Logout (invalidate refresh token)
app.post('/api/logout', authenticateToken, async (req, res) => {
  const { refreshToken } = req.body;
  
  await db.refreshTokens.delete({ token: refreshToken });
  
  res.json({ message: 'Logged out' });
});
```

**Client con refresh:**
```javascript
let accessToken = null;
let refreshToken = null;

async function login(username, password) {
  const response = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password })
  });
  
  const data = await response.json();
  accessToken = data.accessToken;
  refreshToken = data.refreshToken;
  
  localStorage.setItem('refreshToken', refreshToken);
}

async function fetchWithAuth(url, options = {}) {
  options.headers = {
    ...options.headers,
    'Authorization': `Bearer ${accessToken}`
  };
  
  let response = await fetch(url, options);
  
  // If 401, try refresh
  if (response.status === 401) {
    const refreshed = await refreshAccessToken();
    
    if (refreshed) {
      // Retry original request
      options.headers['Authorization'] = `Bearer ${accessToken}`;
      response = await fetch(url, options);
    } else {
      // Refresh failed, redirect to login
      window.location.href = '/login';
      return;
    }
  }
  
  return response;
}

async function refreshAccessToken() {
  const storedRefreshToken = localStorage.getItem('refreshToken');
  
  if (!storedRefreshToken) {
    return false;
  }
  
  try {
    const response = await fetch('/api/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: storedRefreshToken })
    });
    
    if (!response.ok) {
      return false;
    }
    
    const data = await response.json();
    accessToken = data.accessToken;
    
    return true;
  } catch (err) {
    return false;
  }
}
```

### 9.3.5 - JWT Best Practices

**✅ DO:**
- ✅ Usa HTTPS sempre
- ✅ Short expiration per access token (15 min)
- ✅ Store refresh token in DB (revocable)
- ✅ Usa strong secret (min 256 bit)
- ✅ Includi minimal claims (no sensitive data)
- ✅ Valida `exp`, `iat`, `nbf` claims
- ✅ Usa `RS256` per microservices (asymmetric)

**❌ DON'T:**
- ❌ Non mettere password/dati sensibili in JWT
- ❌ Non usare secret debole
- ❌ Non fidarti di JWT senza verifica
- ❌ Non usare `alg: none`
- ❌ Non fare long-lived JWT senza refresh

## 9.4 OAuth 2.0

### 9.4.1 - Ruoli OAuth

**Resource Owner:** Utente che possiede i dati  
**Client:** Applicazione che vuole accedere  
**Authorization Server:** Rilascia token (es. Google)  
**Resource Server:** API con dati protetti

### 9.4.2 - Authorization Code Flow

```
1. User → Click "Login with Google"
2. Client → Redirect to Authorization Server
   https://accounts.google.com/o/oauth2/v2/auth?
     client_id=YOUR_CLIENT_ID&
     redirect_uri=https://yourapp.com/callback&
     response_type=code&
     scope=profile email
3. User → Login + Authorize
4. Authorization Server → Redirect to callback with code
   https://yourapp.com/callback?code=AUTH_CODE
5. Client → Exchange code for token
   POST https://oauth2.googleapis.com/token
   {
     code: AUTH_CODE,
     client_id: YOUR_CLIENT_ID,
     client_secret: YOUR_CLIENT_SECRET,
     redirect_uri: https://yourapp.com/callback,
     grant_type: authorization_code
   }
6. Authorization Server → Return tokens
   {
     access_token: "ya29.a0...",
     refresh_token: "1//0e...",
     expires_in: 3600,
     token_type: "Bearer"
   }
7. Client → Access resource
   GET https://www.googleapis.com/oauth2/v1/userinfo
   Authorization: Bearer ya29.a0...
```

### 9.4.3 - Implementazione (Google OAuth)

**Express.js:**
```javascript
const passport = require('passport');
const GoogleStrategy = require('passport-google-oauth20').Strategy;

passport.use(new GoogleStrategy({
    clientID: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackURL: "http://localhost:3000/auth/google/callback"
  },
  async (accessToken, refreshToken, profile, done) => {
    // Find or create user
    let user = await db.users.findOne({ googleId: profile.id });
    
    if (!user) {
      user = await db.users.create({
        googleId: profile.id,
        email: profile.emails[0].value,
        name: profile.displayName,
        avatar: profile.photos[0].value
      });
    }
    
    done(null, user);
  }
));

app.get('/auth/google',
  passport.authenticate('google', { scope: ['profile', 'email'] })
);

app.get('/auth/google/callback', 
  passport.authenticate('google', { failureRedirect: '/login' }),
  (req, res) => {
    // Generate JWT for our app
    const token = jwt.sign(
      { userId: req.user.id },
      JWT_SECRET,
      { expiresIn: '1h' }
    );
    
    res.redirect(`/dashboard?token=${token}`);
  }
);
```

## 9.5 API Keys

### 9.5.1 - Uso

**Header:**
```http
GET /api/data HTTP/1.1
X-API-Key: 7a8b9c0d1e2f3g4h5i6j7k8l9m0n1o2p
```

**Query parameter:**
```http
GET /api/data?api_key=7a8b9c0d1e2f3g4h5i6j7k8l9m0n1o2p HTTP/1.1
```

### 9.5.2 - Implementazione

```javascript
const crypto = require('crypto');

// Generate API key
function generateApiKey() {
  return crypto.randomBytes(32).toString('hex');
}

// Middleware
const apiKeyAuth = async (req, res, next) => {
  const apiKey = req.get('X-API-Key') || req.query.api_key;
  
  if (!apiKey) {
    return res.status(401).json({ error: 'API key required' });
  }
  
  const key = await db.apiKeys.findOne({ 
    key: apiKey,
    active: true
  });
  
  if (!key) {
    return res.status(403).json({ error: 'Invalid API key' });
  }
  
  // Rate limiting check
  const usage = await db.apiUsage.count({
    apiKeyId: key.id,
    timestamp: { $gte: new Date(Date.now() - 60000) }
  });
  
  if (usage >= key.rateLimit) {
    return res.status(429).json({ error: 'Rate limit exceeded' });
  }
  
  // Log usage
  await db.apiUsage.create({
    apiKeyId: key.id,
    endpoint: req.path,
    timestamp: new Date()
  });
  
  req.apiKey = key;
  next();
};

app.get('/api/data', apiKeyAuth, (req, res) => {
  res.json({ data: 'protected data' });
});
```

---

**Capitolo 9 completato!**

Prossimo: **Capitolo 10 - Cookies e Sessioni**
