# 32. CORS Avanzato

## 32.1 Introduzione a CORS

**Cross-Origin Resource Sharing (CORS)** è un meccanismo di sicurezza che permette a risorse web di essere richieste da un dominio diverso.

**Same-Origin Policy:**

```
Origin = Protocol + Domain + Port

http://example.com:80
https://example.com:443    ← Different protocol
http://api.example.com:80  ← Different subdomain
http://example.com:8080    ← Different port
```

**Same-Origin Examples:**

```
Origin: http://example.com
✓ http://example.com/page.html
✓ http://example.com/api/users
✗ https://example.com         (different protocol)
✗ http://api.example.com      (different subdomain)
✗ http://example.com:8080     (different port)
```

---

## 32.2 Simple vs Preflight Requests

### 32.2.1 - Simple Requests

**Simple requests don't trigger preflight:**

```
Conditions for Simple Request:
1. Methods: GET, HEAD, POST
2. Headers: Accept, Accept-Language, Content-Language, Content-Type
3. Content-Type: application/x-www-form-urlencoded, multipart/form-data, text/plain
```

**Example simple request:**

```javascript
// Simple GET request
fetch('http://api.example.com/users')
    .then(response => response.json())
    .then(data => console.log(data));

// Request headers:
GET /users HTTP/1.1
Host: api.example.com
Origin: http://example.com
```

**Server response:**

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://example.com
Content-Type: application/json

{"users": [...]}
```

### 32.2.2 - Preflight Requests

**Complex requests trigger OPTIONS preflight:**

```
Triggers Preflight:
1. Methods: PUT, DELETE, PATCH, etc.
2. Custom headers: Authorization, X-Custom-Header
3. Content-Type: application/json, application/xml
```

**Example preflight:**

```javascript
// This triggers preflight
fetch('http://api.example.com/users', {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer token123'
    },
    body: JSON.stringify({ name: 'John' })
});
```

**Preflight flow:**

```
1. Browser sends OPTIONS request:
OPTIONS /users HTTP/1.1
Host: api.example.com
Origin: http://example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: authorization,content-type

2. Server responds:
HTTP/1.1 204 No Content
Access-Control-Allow-Origin: http://example.com
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: Authorization, Content-Type
Access-Control-Max-Age: 86400

3. Browser sends actual request:
POST /users HTTP/1.1
Host: api.example.com
Origin: http://example.com
Authorization: Bearer token123
Content-Type: application/json

{"name": "John"}
```

---

## 32.3 CORS Headers

### 32.3.1 - Request Headers

**Access-Control-Request-Method:**

```
OPTIONS /api/users HTTP/1.1
Access-Control-Request-Method: POST

Indicates which method will be used in the actual request
```

**Access-Control-Request-Headers:**

```
OPTIONS /api/users HTTP/1.1
Access-Control-Request-Headers: authorization, content-type

Lists custom headers that will be sent
```

**Origin:**

```
GET /api/users HTTP/1.1
Origin: http://example.com

Always sent by the browser, cannot be modified by JavaScript
```

### 32.3.2 - Response Headers

**Access-Control-Allow-Origin:**

```javascript
// Allow specific origin
Access-Control-Allow-Origin: http://example.com

// Allow all origins (not recommended for credentials)
Access-Control-Allow-Origin: *

// Dynamic origin
const origin = req.headers.origin;
if (allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
}
```

**Access-Control-Allow-Methods:**

```
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
```

**Access-Control-Allow-Headers:**

```
Access-Control-Allow-Headers: Authorization, Content-Type, X-Requested-With
```

**Access-Control-Max-Age:**

```
Access-Control-Max-Age: 86400

Cache preflight response for 24 hours
```

**Access-Control-Allow-Credentials:**

```
Access-Control-Allow-Credentials: true

Required when sending cookies or authorization headers
```

**Access-Control-Expose-Headers:**

```
Access-Control-Expose-Headers: X-Total-Count, X-Page-Number

Allows JavaScript to access these response headers
```

---

## 32.4 Express.js CORS Configuration

### 32.4.1 - Basic CORS Setup

**Simple CORS middleware:**

```javascript
const express = require('express');
const app = express();

// Manual CORS middleware
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    // Handle preflight
    if (req.method === 'OPTIONS') {
        return res.sendStatus(204);
    }
    
    next();
});

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.listen(3000);
```

### 32.4.2 - CORS Package

**Using cors package:**

```javascript
const express = require('express');
const cors = require('cors');

const app = express();

// Enable CORS for all routes
app.use(cors());

// Custom CORS configuration
app.use(cors({
    origin: 'http://example.com',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
    maxAge: 86400
}));

app.listen(3000);
```

### 32.4.3 - Dynamic Origin Validation

**Whitelist multiple origins:**

```javascript
const express = require('express');
const cors = require('cors');

const app = express();

const allowedOrigins = [
    'http://localhost:3000',
    'http://example.com',
    'https://example.com',
    'https://app.example.com'
];

const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (mobile apps, Postman)
        if (!origin) {
            return callback(null, true);
        }
        
        if (allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.listen(3000);
```

### 32.4.4 - Route-Specific CORS

**Different CORS for different routes:**

```javascript
const express = require('express');
const cors = require('cors');

const app = express();

// Public API - allow all origins
const publicCors = cors({
    origin: '*',
    methods: ['GET']
});

// Private API - strict origin control
const privateCors = cors({
    origin: 'https://app.example.com',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    credentials: true
});

// Public routes
app.get('/api/public/status', publicCors, (req, res) => {
    res.json({ status: 'OK' });
});

app.get('/api/public/products', publicCors, (req, res) => {
    res.json({ products: [] });
});

// Private routes
app.use('/api/users', privateCors);
app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.use('/api/orders', privateCors);
app.post('/api/orders', (req, res) => {
    res.json({ order: {} });
});

app.listen(3000);
```

---

## 32.5 CORS with Credentials

### 32.5.1 - Sending Cookies

**Client-side with credentials:**

```javascript
// Fetch API
fetch('http://api.example.com/users', {
    method: 'GET',
    credentials: 'include'  // Send cookies
})
.then(response => response.json())
.then(data => console.log(data));

// Axios
axios.get('http://api.example.com/users', {
    withCredentials: true  // Send cookies
})
.then(response => console.log(response.data));

// XMLHttpRequest
const xhr = new XMLHttpRequest();
xhr.open('GET', 'http://api.example.com/users');
xhr.withCredentials = true;  // Send cookies
xhr.send();
```

**Server-side configuration:**

```javascript
const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');

const app = express();
app.use(cookieParser());

app.use(cors({
    origin: 'http://example.com',  // MUST specify exact origin (not *)
    credentials: true               // Allow credentials
}));

app.get('/api/login', (req, res) => {
    // Set cookie
    res.cookie('sessionId', 'abc123', {
        httpOnly: true,
        secure: true,
        sameSite: 'none',  // Required for cross-origin
        maxAge: 24 * 60 * 60 * 1000
    });
    
    res.json({ message: 'Logged in' });
});

app.get('/api/profile', (req, res) => {
    const sessionId = req.cookies.sessionId;
    
    if (!sessionId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }
    
    res.json({ user: { name: 'John' } });
});

app.listen(3000);
```

### 32.5.2 - Authorization Headers

**Bearer token with CORS:**

```javascript
// Client
const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

fetch('http://api.example.com/users', {
    method: 'GET',
    headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
    },
    credentials: 'include'
})
.then(response => response.json())
.then(data => console.log(data));
```

**Server:**

```javascript
const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const app = express();

app.use(cors({
    origin: 'http://example.com',
    credentials: true,
    allowedHeaders: ['Authorization', 'Content-Type']
}));

app.use(express.json());

const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
        return res.status(401).json({ error: 'No token' });
    }
    
    const token = authHeader.split(' ')[1];
    
    try {
        const decoded = jwt.verify(token, 'secret');
        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

app.get('/api/users', authenticate, (req, res) => {
    res.json({ users: [] });
});

app.listen(3000);
```

---

## 32.6 CORS Error Troubleshooting

### 32.6.1 - Common Errors

**Error 1: No 'Access-Control-Allow-Origin' header**

```
Error: No 'Access-Control-Allow-Origin' header is present

Solution:
app.use(cors());
// or
res.setHeader('Access-Control-Allow-Origin', 'http://example.com');
```

**Error 2: Credentials and wildcard origin**

```
Error: Access-Control-Allow-Origin cannot be '*' when credentials flag is true

Wrong:
app.use(cors({
    origin: '*',
    credentials: true  // Not allowed!
}));

Correct:
app.use(cors({
    origin: 'http://example.com',  // Specific origin
    credentials: true
}));
```

**Error 3: Method not allowed**

```
Error: Method POST is not allowed by Access-Control-Allow-Methods

Solution:
app.use(cors({
    methods: ['GET', 'POST', 'PUT', 'DELETE']
}));
```

**Error 4: Header not allowed**

```
Error: Request header 'Authorization' is not allowed

Solution:
app.use(cors({
    allowedHeaders: ['Authorization', 'Content-Type']
}));
```

### 32.6.2 - Debugging CORS

**Debug middleware:**

```javascript
const express = require('express');
const app = express();

// CORS debugging middleware
app.use((req, res, next) => {
    console.log('--- CORS Debug ---');
    console.log('Method:', req.method);
    console.log('Origin:', req.headers.origin);
    console.log('Request Headers:', req.headers['access-control-request-headers']);
    console.log('Request Method:', req.headers['access-control-request-method']);
    console.log('------------------');
    next();
});

app.use(cors({
    origin: function (origin, callback) {
        console.log('Checking origin:', origin);
        callback(null, true);
    },
    credentials: true
}));

app.get('/api/test', (req, res) => {
    res.json({ message: 'CORS working' });
});

app.listen(3000);
```

---

## 32.7 Nginx CORS Configuration

### 32.7.1 - Basic Nginx CORS

**nginx.conf:**

```nginx
server {
    listen 80;
    server_name api.example.com;
    
    location /api/ {
        # Simple CORS
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS';
        add_header Access-Control-Allow-Headers 'Authorization, Content-Type';
        
        # Preflight
        if ($request_method = OPTIONS) {
            return 204;
        }
        
        proxy_pass http://backend;
    }
}
```

### 32.7.2 - Advanced Nginx CORS

**Dynamic origin with credentials:**

```nginx
map $http_origin $cors_origin {
    default "";
    "~^https?://(localhost:3000|example\.com|app\.example\.com)$" $http_origin;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    location /api/ {
        # Dynamic origin
        add_header Access-Control-Allow-Origin $cors_origin always;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
        add_header Access-Control-Allow-Credentials 'true' always;
        add_header Access-Control-Max-Age '86400' always;
        
        # Expose custom headers
        add_header Access-Control-Expose-Headers 'X-Total-Count, X-Page-Number' always;
        
        # Preflight
        if ($request_method = OPTIONS) {
            add_header Access-Control-Allow-Origin $cors_origin always;
            add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header Access-Control-Allow-Headers 'Authorization, Content-Type, X-Requested-With' always;
            add_header Access-Control-Allow-Credentials 'true' always;
            add_header Access-Control-Max-Age '86400' always;
            add_header Content-Length 0;
            add_header Content-Type text/plain;
            return 204;
        }
        
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 32.8 CORS Security Best Practices

### 32.8.1 - Strict Origin Control

**Avoid wildcards in production:**

```javascript
// ❌ Bad - allows any origin
app.use(cors({ origin: '*' }));

// ✓ Good - specific origins
const allowedOrigins = [
    'https://example.com',
    'https://app.example.com'
];

app.use(cors({
    origin: function (origin, callback) {
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    }
}));
```

### 32.8.2 - Environment-Based Configuration

**Different configs for dev/prod:**

```javascript
const express = require('express');
const cors = require('cors');

const app = express();

const isDevelopment = process.env.NODE_ENV === 'development';

const corsOptions = isDevelopment
    ? {
          // Development - permissive
          origin: true,  // Reflect request origin
          credentials: true
      }
    : {
          // Production - strict
          origin: [
              'https://example.com',
              'https://app.example.com'
          ],
          credentials: true,
          methods: ['GET', 'POST', 'PUT', 'DELETE'],
          allowedHeaders: ['Authorization', 'Content-Type'],
          maxAge: 86400
      };

app.use(cors(corsOptions));

app.listen(3000);
```

### 32.8.3 - Rate Limiting CORS Requests

**Prevent CORS abuse:**

```javascript
const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');

const app = express();

// Rate limit OPTIONS requests
const preflightLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: 'Too many preflight requests',
    skip: (req) => req.method !== 'OPTIONS'
});

app.use(preflightLimiter);

app.use(cors({
    origin: 'https://example.com',
    credentials: true
}));

app.listen(3000);
```

### 32.8.4 - Complete Production Setup

**Full production CORS configuration:**

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();

// Security headers
app.use(helmet());

// Allowed origins from environment
const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',')
    : ['https://example.com'];

// CORS configuration
const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (mobile apps, curl)
        if (!origin) {
            return callback(null, true);
        }
        
        if (allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            console.warn(`CORS blocked origin: ${origin}`);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Authorization', 'Content-Type', 'X-Requested-With'],
    exposedHeaders: ['X-Total-Count', 'X-Page-Number'],
    maxAge: 86400,  // 24 hours
    optionsSuccessStatus: 204
};

app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});

app.use('/api/', limiter);

// Error handler for CORS errors
app.use((err, req, res, next) => {
    if (err.message === 'Not allowed by CORS') {
        res.status(403).json({
            error: 'CORS policy violation',
            origin: req.headers.origin
        });
    } else {
        next(err);
    }
});

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
    console.log('Allowed origins:', allowedOrigins);
});
```

---

## 32.9 Testing CORS

### 32.9.1 - Manual Testing with curl

**Test preflight request:**

```bash
# Preflight request
curl -X OPTIONS http://api.example.com/users \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Authorization, Content-Type" \
  -v

# Actual request
curl -X POST http://api.example.com/users \
  -H "Origin: http://example.com" \
  -H "Authorization: Bearer token123" \
  -H "Content-Type: application/json" \
  -d '{"name":"John"}' \
  -v
```

### 32.9.2 - Automated Tests

**Jest test for CORS:**

```javascript
const request = require('supertest');
const app = require('./app');

describe('CORS Tests', () => {
    test('should allow requests from allowed origin', async () => {
        const response = await request(app)
            .get('/api/users')
            .set('Origin', 'http://example.com');
        
        expect(response.status).toBe(200);
        expect(response.headers['access-control-allow-origin']).toBe('http://example.com');
    });
    
    test('should block requests from disallowed origin', async () => {
        const response = await request(app)
            .get('/api/users')
            .set('Origin', 'http://evil.com');
        
        expect(response.status).toBe(403);
    });
    
    test('should handle preflight request', async () => {
        const response = await request(app)
            .options('/api/users')
            .set('Origin', 'http://example.com')
            .set('Access-Control-Request-Method', 'POST')
            .set('Access-Control-Request-Headers', 'Authorization, Content-Type');
        
        expect(response.status).toBe(204);
        expect(response.headers['access-control-allow-methods']).toContain('POST');
        expect(response.headers['access-control-allow-headers']).toContain('Authorization');
    });
    
    test('should allow credentials', async () => {
        const response = await request(app)
            .get('/api/users')
            .set('Origin', 'http://example.com');
        
        expect(response.headers['access-control-allow-credentials']).toBe('true');
    });
});
```

---

Prossimo: **Capitolo 33 - Content Security Policy (CSP)**
