# 24. Rate Limiting e Throttling

## 24.1 Introduzione

**Rate Limiting** limita il numero di richieste che un client può fare in un periodo di tempo.

**Perché implementare rate limiting:**
- 🛡️ **Protezione DoS/DDoS:** Previene abusi
- 💰 **Fair usage:** Garantisce risorse equamente distribuite
- 💸 **Cost control:** Limita costi API di terze parti
- 🎯 **QoS (Quality of Service):** Prioritizza utenti premium
- 📊 **Resource management:** Previene overload server

**Terminologia:**
- **Rate Limit:** Max requests in time window
- **Throttling:** Rallenta requests quando limite raggiunto
- **Burst:** Picco temporaneo consentito
- **Token Bucket:** Algoritmo accumula "tokens" per requests

---

## 24.2 Rate Limiting Algorithms

### 24.2.1 - Fixed Window

**Algoritmo più semplice:**

```
Window: 1 minuto
Limit: 60 requests

Timeline:
12:00:00 - 12:01:00 → Max 60 requests
12:01:00 - 12:02:00 → Max 60 requests (reset counter)
```

**Problema: Burst at boundary**

```
12:00:30 → 60 requests (OK)
12:01:00 → 60 requests (OK)
Total in 30 sec: 120 requests! (doppio del limite)
```

**Implementation:**

```javascript
class FixedWindowRateLimiter {
    constructor(limit, windowMs) {
        this.limit = limit;
        this.windowMs = windowMs;
        this.clients = new Map();
    }
    
    isAllowed(clientId) {
        const now = Date.now();
        const windowStart = Math.floor(now / this.windowMs) * this.windowMs;
        
        const key = `${clientId}:${windowStart}`;
        const count = this.clients.get(key) || 0;
        
        if (count >= this.limit) {
            return false;
        }
        
        this.clients.set(key, count + 1);
        
        // Cleanup old windows
        this.cleanup(windowStart);
        
        return true;
    }
    
    cleanup(currentWindow) {
        for (const [key, value] of this.clients.entries()) {
            const [clientId, windowStr] = key.split(':');
            const window = parseInt(windowStr);
            
            if (window < currentWindow - this.windowMs) {
                this.clients.delete(key);
            }
        }
    }
}

// Usage
const limiter = new FixedWindowRateLimiter(60, 60000); // 60 req/min

if (limiter.isAllowed('user123')) {
    // Process request
} else {
    // 429 Too Many Requests
}
```

### 24.2.2 - Sliding Window

**Più accurato del fixed window:**

```
Window slides con ogni request

12:00:00 → Request 1
12:00:30 → Request 60
12:01:00 → Check: quante req negli ultimi 60 sec?
```

**Implementation:**

```javascript
class SlidingWindowRateLimiter {
    constructor(limit, windowMs) {
        this.limit = limit;
        this.windowMs = windowMs;
        this.clients = new Map();
    }
    
    isAllowed(clientId) {
        const now = Date.now();
        
        if (!this.clients.has(clientId)) {
            this.clients.set(clientId, []);
        }
        
        const requests = this.clients.get(clientId);
        
        // Remove requests outside window
        const validRequests = requests.filter(
            timestamp => now - timestamp < this.windowMs
        );
        
        if (validRequests.length >= this.limit) {
            return false;
        }
        
        validRequests.push(now);
        this.clients.set(clientId, validRequests);
        
        return true;
    }
    
    getRemainingRequests(clientId) {
        const now = Date.now();
        const requests = this.clients.get(clientId) || [];
        const validRequests = requests.filter(
            timestamp => now - timestamp < this.windowMs
        );
        
        return Math.max(0, this.limit - validRequests.length);
    }
    
    getResetTime(clientId) {
        const requests = this.clients.get(clientId) || [];
        if (requests.length === 0) return 0;
        
        const oldest = Math.min(...requests);
        return oldest + this.windowMs;
    }
}

// Usage
const limiter = new SlidingWindowRateLimiter(60, 60000);

if (limiter.isAllowed('user123')) {
    const remaining = limiter.getRemainingRequests('user123');
    const resetTime = limiter.getResetTime('user123');
    
    console.log(`Remaining: ${remaining}`);
    console.log(`Reset at: ${new Date(resetTime)}`);
}
```

### 24.2.3 - Token Bucket

**Algoritmo più flessibile (usato da AWS, Stripe):**

```
Bucket capacity: 60 tokens
Refill rate: 1 token/second

Each request consumes 1 token
Tokens accumulate up to capacity
Allows burst if tokens available
```

**Implementation:**

```javascript
class TokenBucketRateLimiter {
    constructor(capacity, refillRate) {
        this.capacity = capacity;
        this.refillRate = refillRate; // tokens per second
        this.clients = new Map();
    }
    
    isAllowed(clientId, cost = 1) {
        const now = Date.now();
        
        if (!this.clients.has(clientId)) {
            this.clients.set(clientId, {
                tokens: this.capacity,
                lastRefill: now
            });
        }
        
        const bucket = this.clients.get(clientId);
        
        // Refill tokens
        const timePassed = (now - bucket.lastRefill) / 1000;
        const tokensToAdd = timePassed * this.refillRate;
        bucket.tokens = Math.min(this.capacity, bucket.tokens + tokensToAdd);
        bucket.lastRefill = now;
        
        // Check if enough tokens
        if (bucket.tokens >= cost) {
            bucket.tokens -= cost;
            return true;
        }
        
        return false;
    }
    
    getAvailableTokens(clientId) {
        const now = Date.now();
        const bucket = this.clients.get(clientId);
        
        if (!bucket) return this.capacity;
        
        const timePassed = (now - bucket.lastRefill) / 1000;
        const tokensToAdd = timePassed * this.refillRate;
        
        return Math.min(this.capacity, bucket.tokens + tokensToAdd);
    }
}

// Usage
const limiter = new TokenBucketRateLimiter(60, 1); // 60 tokens, 1/sec refill

// Normal request (cost 1)
if (limiter.isAllowed('user123')) {
    // Process
}

// Expensive operation (cost 10)
if (limiter.isAllowed('user123', 10)) {
    // Process heavy operation
}
```

### 24.2.4 - Leaky Bucket

**Smooths traffic (used by network QoS):**

```
Requests enter bucket
Processed at constant rate
Overflow → rejected

Like water bucket with hole at bottom
```

**Implementation:**

```javascript
class LeakyBucketRateLimiter {
    constructor(capacity, leakRate) {
        this.capacity = capacity;
        this.leakRate = leakRate; // requests per second
        this.clients = new Map();
    }
    
    isAllowed(clientId) {
        const now = Date.now();
        
        if (!this.clients.has(clientId)) {
            this.clients.set(clientId, {
                queue: 0,
                lastLeak: now
            });
        }
        
        const bucket = this.clients.get(clientId);
        
        // Leak (process) requests
        const timePassed = (now - bucket.lastLeak) / 1000;
        const leaked = timePassed * this.leakRate;
        bucket.queue = Math.max(0, bucket.queue - leaked);
        bucket.lastLeak = now;
        
        // Check capacity
        if (bucket.queue < this.capacity) {
            bucket.queue += 1;
            return true;
        }
        
        return false;
    }
}

// Usage
const limiter = new LeakyBucketRateLimiter(100, 10); // 100 capacity, 10/sec leak
```

---

## 24.3 Express.js Rate Limiting

### 24.3.1 - express-rate-limit

**Installation:**

```bash
npm install express-rate-limit
```

**Basic usage:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');

const app = express();

// Global rate limiter
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Max 100 requests per windowMs
    message: 'Too many requests, please try again later',
    standardHeaders: true, // Return rate limit info in headers
    legacyHeaders: false
});

app.use(limiter);

app.get('/api/data', (req, res) => {
    res.json({ data: 'success' });
});

app.listen(3000);
```

**Response headers:**

```http
HTTP/1.1 200 OK
RateLimit-Limit: 100
RateLimit-Remaining: 99
RateLimit-Reset: 1698765432

HTTP/1.1 429 Too Many Requests
RateLimit-Limit: 100
RateLimit-Remaining: 0
RateLimit-Reset: 1698765432
Retry-After: 900

{
  "message": "Too many requests, please try again later"
}
```

### 24.3.2 - Different Limits per Endpoint

**Stricter limits for sensitive endpoints:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');

const app = express();

// Strict limiter for auth endpoints
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5, // Only 5 login attempts per 15 min
    message: 'Too many login attempts, please try again later',
    skipSuccessfulRequests: true // Don't count successful logins
});

// Moderate limiter for API
const apiLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});

// Generous limiter for static assets
const staticLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 1000
});

// Apply limiters
app.post('/api/login', authLimiter, (req, res) => {
    // Login logic
    res.json({ token: 'abc123' });
});

app.use('/api/', apiLimiter);
app.use('/static/', staticLimiter);

app.listen(3000);
```

### 24.3.3 - Custom Key Generator

**Rate limit per user, not IP:**

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    
    // Custom key generator
    keyGenerator: (req) => {
        // Use user ID if authenticated
        if (req.user && req.user.id) {
            return `user:${req.user.id}`;
        }
        
        // Fallback to IP
        return req.ip;
    },
    
    // Skip rate limiting for admins
    skip: (req) => {
        return req.user && req.user.role === 'admin';
    },
    
    // Custom handler
    handler: (req, res) => {
        res.status(429).json({
            error: 'Too Many Requests',
            message: 'You have exceeded the rate limit',
            retryAfter: res.getHeader('Retry-After')
        });
    }
});

app.use('/api/', limiter);
```

### 24.3.4 - Redis Store (Distributed Systems)

**For multi-server deployments:**

```bash
npm install rate-limit-redis redis
```

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const { createClient } = require('redis');

// Redis client
const redisClient = createClient({
    host: 'localhost',
    port: 6379
});

redisClient.connect();

// Rate limiter with Redis store
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    store: new RedisStore({
        client: redisClient,
        prefix: 'rate-limit:'
    })
});

app.use('/api/', limiter);

// Now rate limiting works across multiple servers!
```

---

## 24.4 Nginx Rate Limiting

### 24.4.1 - limit_req_zone

**Nginx native rate limiting:**

```nginx
http {
    # Define rate limit zone
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    # $binary_remote_addr: Client IP (binary format, saves memory)
    # zone=api_limit:10m: Zone name + 10MB memory (~160k IPs)
    # rate=10r/s: 10 requests per second
    
    server {
        listen 443 ssl;
        server_name api.example.com;
        
        location /api/ {
            # Apply rate limit
            limit_req zone=api_limit burst=20 nodelay;
            # burst=20: Allow burst of 20 extra requests
            # nodelay: Process burst immediately (no delay)
            
            proxy_pass http://backend;
        }
    }
}
```

**Rate limit by other keys:**

```nginx
http {
    # By user ID (from cookie)
    limit_req_zone $cookie_user_id zone=user_limit:10m rate=100r/m;
    
    # By API key (from header)
    limit_req_zone $http_x_api_key zone=apikey_limit:10m rate=1000r/h;
    
    # By URI
    limit_req_zone $request_uri zone=uri_limit:10m rate=5r/s;
    
    server {
        location /api/expensive {
            limit_req zone=user_limit burst=10;
            proxy_pass http://backend;
        }
    }
}
```

### 24.4.2 - Custom Error Response

**Nginx rate limit error page:**

```nginx
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    server {
        listen 443 ssl;
        server_name api.example.com;
        
        location /api/ {
            limit_req zone=api_limit burst=20 nodelay;
            limit_req_status 429;
            
            # Custom error page for 429
            error_page 429 = @rate_limit_error;
            
            proxy_pass http://backend;
        }
        
        location @rate_limit_error {
            default_type application/json;
            return 429 '{
                "error": "Too Many Requests",
                "message": "Rate limit exceeded",
                "retry_after": "$limit_req_retry_after"
            }';
        }
    }
}
```

### 24.4.3 - Connection Limiting

**Limit concurrent connections:**

```nginx
http {
    # Limit concurrent connections per IP
    limit_conn_zone $binary_remote_addr zone=conn_limit:10m;
    
    server {
        listen 443 ssl;
        server_name example.com;
        
        location /downloads/ {
            # Max 2 concurrent downloads per IP
            limit_conn conn_limit 2;
            
            # Bandwidth limit
            limit_rate 500k; # 500 KB/s per connection
            
            root /var/www/downloads;
        }
    }
}
```

### 24.4.4 - Whitelist IPs

**Bypass rate limiting for trusted IPs:**

```nginx
http {
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    
    # Whitelist map
    geo $limit {
        default 1;
        10.0.0.0/8 0;     # Internal network
        192.168.0.0/16 0; # Internal network
        1.2.3.4 0;        # Trusted partner IP
    }
    
    map $limit $limit_key {
        0 "";
        1 $binary_remote_addr;
    }
    
    limit_req_zone $limit_key zone=smart_limit:10m rate=10r/s;
    
    server {
        location /api/ {
            limit_req zone=smart_limit burst=20;
            proxy_pass http://backend;
        }
    }
}
```

---

## 24.5 Advanced Rate Limiting

### 24.5.1 - Tiered Rate Limits

**Different limits for different user tiers:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');

const app = express();

const createTieredLimiter = () => {
    return rateLimit({
        windowMs: 60 * 60 * 1000, // 1 hour
        
        max: (req) => {
            if (!req.user) {
                return 10; // Anonymous: 10/hour
            }
            
            switch (req.user.tier) {
                case 'free':
                    return 100; // Free: 100/hour
                case 'premium':
                    return 1000; // Premium: 1000/hour
                case 'enterprise':
                    return 10000; // Enterprise: 10000/hour
                default:
                    return 10;
            }
        },
        
        keyGenerator: (req) => {
            return req.user ? `user:${req.user.id}` : req.ip;
        },
        
        handler: (req, res) => {
            const tier = req.user?.tier || 'anonymous';
            res.status(429).json({
                error: 'Rate limit exceeded',
                tier: tier,
                upgrade_url: tier === 'free' ? '/pricing' : null
            });
        }
    });
};

app.use('/api/', createTieredLimiter());

app.listen(3000);
```

### 24.5.2 - Cost-Based Rate Limiting

**Different endpoints consume different "credits":**

```javascript
const express = require('express');
const TokenBucketRateLimiter = require('./TokenBucketRateLimiter');

const app = express();

const limiter = new TokenBucketRateLimiter(1000, 10); // 1000 tokens, 10/sec refill

const costLimiter = (cost) => {
    return (req, res, next) => {
        const clientId = req.user?.id || req.ip;
        
        if (limiter.isAllowed(clientId, cost)) {
            const remaining = limiter.getAvailableTokens(clientId);
            
            res.setHeader('X-RateLimit-Remaining', Math.floor(remaining));
            next();
        } else {
            res.status(429).json({
                error: 'Insufficient credits',
                cost: cost,
                available: Math.floor(limiter.getAvailableTokens(clientId))
            });
        }
    };
};

// Cheap endpoint (1 credit)
app.get('/api/users/:id', costLimiter(1), (req, res) => {
    res.json({ user: {} });
});

// Moderate endpoint (10 credits)
app.get('/api/search', costLimiter(10), (req, res) => {
    res.json({ results: [] });
});

// Expensive endpoint (100 credits)
app.post('/api/reports/generate', costLimiter(100), (req, res) => {
    res.json({ report_id: '123' });
});

app.listen(3000);
```

### 24.5.3 - Dynamic Rate Limiting

**Adjust limits based on server load:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');
const os = require('os');

const app = express();

const getDynamicLimit = () => {
    const cpuUsage = os.loadavg()[0] / os.cpus().length;
    
    if (cpuUsage > 0.8) {
        return 10; // High load: strict limit
    } else if (cpuUsage > 0.5) {
        return 50; // Medium load
    } else {
        return 100; // Low load: generous limit
    }
};

const dynamicLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: getDynamicLimit,
    
    handler: (req, res) => {
        const cpuUsage = (os.loadavg()[0] / os.cpus().length * 100).toFixed(1);
        
        res.status(429).json({
            error: 'Rate limit exceeded',
            message: 'Server is under high load',
            cpu_usage: `${cpuUsage}%`,
            retry_after: res.getHeader('Retry-After')
        });
    }
});

app.use('/api/', dynamicLimiter);

app.listen(3000);
```

---

## 24.6 Rate Limit Headers

### 24.6.1 - Standard Headers

**RateLimit HTTP Headers (RFC draft):**

```http
HTTP/1.1 200 OK
RateLimit-Limit: 100
RateLimit-Remaining: 95
RateLimit-Reset: 1698765432
```

**Implementation:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');

const app = express();

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true, // Enable RateLimit-* headers
    
    // Add custom headers
    onLimitReached: (req, res) => {
        res.setHeader('X-RateLimit-Policy', '100 requests per 15 minutes');
    }
});

app.use(limiter);
```

### 24.6.2 - Retry-After Header

**Tell client when to retry:**

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 900
RateLimit-Reset: 1698765432

{
  "error": "Rate limit exceeded",
  "retry_after_seconds": 900
}
```

**Client implementation:**

```javascript
async function fetchWithRetry(url) {
    const response = await fetch(url);
    
    if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After');
        const seconds = parseInt(retryAfter);
        
        console.log(`Rate limited. Retrying in ${seconds} seconds...`);
        
        await new Promise(resolve => setTimeout(resolve, seconds * 1000));
        
        return fetchWithRetry(url); // Retry
    }
    
    return response;
}
```

---

## 24.7 Monitoring & Analytics

### 24.7.1 - Rate Limit Metrics

**Track rate limit hits:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');
const prometheus = require('prom-client');

const app = express();

// Prometheus metrics
const rateLimitHits = new prometheus.Counter({
    name: 'rate_limit_hits_total',
    help: 'Total rate limit hits',
    labelNames: ['endpoint', 'user_tier']
});

const rateLimitRequests = new prometheus.Counter({
    name: 'rate_limit_requests_total',
    help: 'Total requests to rate limited endpoints',
    labelNames: ['endpoint', 'user_tier']
});

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    
    handler: (req, res) => {
        const tier = req.user?.tier || 'anonymous';
        
        // Increment hit counter
        rateLimitHits.labels(req.path, tier).inc();
        
        res.status(429).json({
            error: 'Rate limit exceeded'
        });
    },
    
    skip: (req) => {
        const tier = req.user?.tier || 'anonymous';
        
        // Track all requests
        rateLimitRequests.labels(req.path, tier).inc();
        
        return false; // Don't skip
    }
});

app.use('/api/', limiter);

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(3000);
```

### 24.7.2 - Alerting

**Alert when rate limit abuse detected:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');

const app = express();

const sendAlert = (clientId, endpoint) => {
    console.error(`[ALERT] Rate limit abuse detected!`);
    console.error(`Client: ${clientId}`);
    console.error(`Endpoint: ${endpoint}`);
    
    // Send to monitoring service (PagerDuty, Slack, etc.)
};

const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    
    handler: (req, res) => {
        const clientId = req.user?.id || req.ip;
        
        // Check if repeated abuse
        const key = `abuse:${clientId}`;
        const abuseCount = abuseTracker.get(key) || 0;
        
        if (abuseCount > 5) {
            sendAlert(clientId, req.path);
        }
        
        abuseTracker.set(key, abuseCount + 1);
        
        res.status(429).json({
            error: 'Rate limit exceeded'
        });
    }
});

app.use('/api/', limiter);
```

---

## 24.8 Best Practices

### 24.8.1 - Complete Production Setup

**Express.js with Redis + Monitoring:**

```javascript
const express = require('express');
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const { createClient } = require('redis');
const prometheus = require('prom-client');

const app = express();

// Redis client
const redisClient = createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379
});

redisClient.connect();

// Metrics
const rateLimitHits = new prometheus.Counter({
    name: 'rate_limit_hits_total',
    help: 'Rate limit hits',
    labelNames: ['endpoint', 'tier']
});

// Auth limiter (strict)
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 5,
    store: new RedisStore({
        client: redisClient,
        prefix: 'rl:auth:'
    }),
    skipSuccessfulRequests: true,
    handler: (req, res) => {
        rateLimitHits.labels('/auth', 'all').inc();
        res.status(429).json({
            error: 'Too many login attempts'
        });
    }
});

// API limiter (tiered)
const apiLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: (req) => {
        const tier = req.user?.tier || 'free';
        const limits = {
            free: 100,
            premium: 1000,
            enterprise: 10000
        };
        return limits[tier] || 100;
    },
    store: new RedisStore({
        client: redisClient,
        prefix: 'rl:api:'
    }),
    keyGenerator: (req) => {
        return req.user?.id || req.ip;
    },
    handler: (req, res) => {
        const tier = req.user?.tier || 'free';
        rateLimitHits.labels('/api', tier).inc();
        
        res.status(429).json({
            error: 'Rate limit exceeded',
            tier: tier,
            upgrade_url: tier === 'free' ? '/pricing' : null
        });
    },
    standardHeaders: true
});

// Apply limiters
app.post('/auth/login', authLimiter, (req, res) => {
    res.json({ token: 'abc123' });
});

app.use('/api/', apiLimiter);

// Metrics
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(3000, () => {
    console.log('Server with rate limiting ready');
});
```

**Nginx + Express combination:**

```nginx
http {
    # Nginx layer: Aggressive rate limiting
    limit_req_zone $binary_remote_addr zone=ddos_protection:10m rate=100r/s;
    
    server {
        listen 443 ssl;
        server_name api.example.com;
        
        location /api/ {
            # First line of defense (Nginx)
            limit_req zone=ddos_protection burst=200 nodelay;
            
            # Pass to Express (has finer-grained limits)
            proxy_pass http://localhost:3000;
        }
    }
}
```

---

**Capitolo 24 completato!**

Prossimo: **Capitolo 25 - HTTP Compression (Gzip, Brotli)**
