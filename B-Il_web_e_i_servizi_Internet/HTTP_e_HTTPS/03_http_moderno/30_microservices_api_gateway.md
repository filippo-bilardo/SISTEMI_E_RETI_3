# 30. Microservices e API Gateway

## 30.1 Introduzione

**Microservices Architecture** divide un'applicazione monolitica in servizi indipendenti, piccoli e specializzati.

**Monolith vs Microservices:**

```
MONOLITH:
┌─────────────────────────────────┐
│    Single Application           │
│  ┌───────────────────────────┐  │
│  │ Users │ Orders │ Products │  │
│  │ Auth  │ Payment│ Inventory│  │
│  └───────────────────────────┘  │
│    Single Database              │
└─────────────────────────────────┘

Problems:
- Tight coupling
- Difficult to scale specific parts
- Single point of failure
- Long deployment cycles

MICROSERVICES:
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Users  │  │ Orders  │  │Products │
│ Service │  │ Service │  │ Service │
│   DB    │  │   DB    │  │   DB    │
└─────────┘  └─────────┘  └─────────┘
┌─────────┐  ┌─────────┐  ┌─────────┐
│  Auth   │  │ Payment │  │Inventory│
│ Service │  │ Service │  │ Service │
│   DB    │  │   DB    │  │   DB    │
└─────────┘  └─────────┘  └─────────┘

Benefits:
- Independent deployment
- Technology diversity
- Scalability per service
- Fault isolation
```

**API Gateway** è il single entry point per tutti i client, che instrada le richieste ai microservizi appropriati.

```
Client → API Gateway → [Users, Orders, Products, etc.]
```

---

## 30.2 API Gateway Pattern

### 30.2.1 - Gateway Responsibilities

**API Gateway functions:**

```
1. Request Routing
   Client → Gateway → Microservice A

2. Authentication & Authorization
   Verify JWT → Route request

3. Rate Limiting
   Enforce 100 req/min per user

4. Load Balancing
   Distribute requests across instances

5. Response Aggregation
   Combine responses from multiple services

6. Protocol Translation
   HTTP → gRPC, REST → GraphQL

7. Caching
   Cache frequent responses

8. Logging & Monitoring
   Track all requests centrally
```

### 30.2.2 - Gateway Architecture

```
                 API Gateway
                      |
    +-----------------+--------------------+
    |                 |                    |
┌─────────┐      ┌─────────┐         ┌─────────┐
│ Service │      │ Service │         │ Service │
│    A    │      │    B    │         │    C    │
│ :3001   │      │ :3002   │         │ :3003   │
└─────────┘      └─────────┘         └─────────┘
    |                 |                    |
┌─────────┐      ┌─────────┐         ┌─────────┐
│   DB    │      │   DB    │         │   DB    │
└─────────┘      └─────────┘         └─────────┘
```

---

## 30.3 Express.js API Gateway

### 30.3.1 - Basic Gateway

**Simple routing gateway:**

```javascript
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Routes to microservices
app.use('/users', createProxyMiddleware({
    target: 'http://localhost:3001',
    changeOrigin: true,
    pathRewrite: {
        '^/users': '/api/users'
    }
}));

app.use('/orders', createProxyMiddleware({
    target: 'http://localhost:3002',
    changeOrigin: true,
    pathRewrite: {
        '^/orders': '/api/orders'
    }
}));

app.use('/products', createProxyMiddleware({
    target: 'http://localhost:3003',
    changeOrigin: true,
    pathRewrite: {
        '^/products': '/api/products'
    }
}));

const PORT = 8080;
app.listen(PORT, () => {
    console.log(`API Gateway running on port ${PORT}`);
});
```

### 30.3.2 - Gateway with Authentication

**JWT authentication at gateway:**

```javascript
const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'secret';

// Authentication middleware
const authenticate = (req, res, next) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
        return res.status(401).json({ error: 'No token provided' });
    }
    
    const token = authHeader.split(' ')[1];
    
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = decoded;
        
        // Pass user info to microservices
        req.headers['x-user-id'] = decoded.id;
        req.headers['x-user-role'] = decoded.role;
        
        next();
    } catch (error) {
        return res.status(401).json({ error: 'Invalid token' });
    }
};

// Public routes (no auth)
app.post('/auth/login', createProxyMiddleware({
    target: 'http://localhost:3001',
    changeOrigin: true
}));

app.post('/auth/register', createProxyMiddleware({
    target: 'http://localhost:3001',
    changeOrigin: true
}));

// Protected routes (require auth)
app.use('/users', authenticate, createProxyMiddleware({
    target: 'http://localhost:3001',
    changeOrigin: true
}));

app.use('/orders', authenticate, createProxyMiddleware({
    target: 'http://localhost:3002',
    changeOrigin: true
}));

app.use('/products', authenticate, createProxyMiddleware({
    target: 'http://localhost:3003',
    changeOrigin: true
}));

app.listen(8080);
```

### 30.3.3 - Response Aggregation

**Combine responses from multiple services:**

```javascript
const express = require('express');
const axios = require('axios');

const app = express();

// Aggregate data from multiple services
app.get('/dashboard', authenticate, async (req, res) => {
    try {
        const userId = req.user.id;
        
        // Call multiple services in parallel
        const [userProfile, orders, recommendations] = await Promise.all([
            axios.get(`http://localhost:3001/users/${userId}`),
            axios.get(`http://localhost:3002/orders/user/${userId}`),
            axios.get(`http://localhost:3003/products/recommended/${userId}`)
        ]);
        
        // Aggregate responses
        const dashboard = {
            user: userProfile.data,
            recentOrders: orders.data.slice(0, 5),
            recommendations: recommendations.data
        };
        
        res.json(dashboard);
    } catch (error) {
        console.error('Error aggregating dashboard:', error);
        res.status(500).json({ error: 'Failed to load dashboard' });
    }
});

// User details with orders
app.get('/users/:id/full', authenticate, async (req, res) => {
    try {
        const { id } = req.params;
        
        // Get user
        const userResponse = await axios.get(`http://localhost:3001/users/${id}`);
        const user = userResponse.data;
        
        // Get user's orders
        const ordersResponse = await axios.get(`http://localhost:3002/orders/user/${id}`);
        user.orders = ordersResponse.data;
        
        res.json(user);
    } catch (error) {
        res.status(500).json({ error: 'Failed to load user' });
    }
});

app.listen(8080);
```

### 30.3.4 - Circuit Breaker Pattern

**Prevent cascading failures:**

```javascript
const express = require('express');
const axios = require('axios');

const app = express();

// Circuit breaker implementation
class CircuitBreaker {
    constructor(service, threshold = 5, timeout = 60000) {
        this.service = service;
        this.failureThreshold = threshold;
        this.timeout = timeout;
        this.failureCount = 0;
        this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
        this.nextAttempt = Date.now();
    }
    
    async call(url, options) {
        if (this.state === 'OPEN') {
            if (Date.now() < this.nextAttempt) {
                throw new Error(`Circuit breaker OPEN for ${this.service}`);
            }
            
            // Try half-open
            this.state = 'HALF_OPEN';
        }
        
        try {
            const response = await axios({ url, ...options });
            this.onSuccess();
            return response;
        } catch (error) {
            this.onFailure();
            throw error;
        }
    }
    
    onSuccess() {
        this.failureCount = 0;
        
        if (this.state === 'HALF_OPEN') {
            this.state = 'CLOSED';
            console.log(`Circuit breaker CLOSED for ${this.service}`);
        }
    }
    
    onFailure() {
        this.failureCount++;
        
        if (this.failureCount >= this.failureThreshold) {
            this.state = 'OPEN';
            this.nextAttempt = Date.now() + this.timeout;
            console.error(`Circuit breaker OPEN for ${this.service}`);
        }
    }
}

// Create circuit breakers for each service
const breakers = {
    users: new CircuitBreaker('users'),
    orders: new CircuitBreaker('orders'),
    products: new CircuitBreaker('products')
};

app.get('/users/:id', async (req, res) => {
    try {
        const response = await breakers.users.call(
            `http://localhost:3001/users/${req.params.id}`
        );
        
        res.json(response.data);
    } catch (error) {
        if (error.message.includes('Circuit breaker OPEN')) {
            res.status(503).json({
                error: 'Service temporarily unavailable',
                retry_after: 60
            });
        } else {
            res.status(500).json({ error: 'Internal error' });
        }
    }
});

app.listen(8080);
```

---

## 30.4 Kong API Gateway

### 30.4.1 - Kong Installation

**Docker Compose setup:**

```yaml
version: '3.8'

services:
  kong-database:
    image: postgres:13
    environment:
      POSTGRES_DB: kong
      POSTGRES_USER: kong
      POSTGRES_PASSWORD: kong
    volumes:
      - kong-db-data:/var/lib/postgresql/data
    networks:
      - kong-net

  kong-migration:
    image: kong:latest
    command: kong migrations bootstrap
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: kong
    depends_on:
      - kong-database
    networks:
      - kong-net

  kong:
    image: kong:latest
    environment:
      KONG_DATABASE: postgres
      KONG_PG_HOST: kong-database
      KONG_PG_USER: kong
      KONG_PG_PASSWORD: kong
      KONG_PROXY_ACCESS_LOG: /dev/stdout
      KONG_ADMIN_ACCESS_LOG: /dev/stdout
      KONG_PROXY_ERROR_LOG: /dev/stderr
      KONG_ADMIN_ERROR_LOG: /dev/stderr
      KONG_ADMIN_LISTEN: 0.0.0.0:8001
    ports:
      - "8000:8000"  # Proxy
      - "8443:8443"  # Proxy SSL
      - "8001:8001"  # Admin API
      - "8444:8444"  # Admin API SSL
    depends_on:
      - kong-migration
    networks:
      - kong-net

volumes:
  kong-db-data:

networks:
  kong-net:
```

### 30.4.2 - Kong Configuration

**Add services and routes:**

```bash
# Add Users Service
curl -i -X POST http://localhost:8001/services \
  --data name=users-service \
  --data url=http://users-api:3001

# Add route for Users Service
curl -i -X POST http://localhost:8001/services/users-service/routes \
  --data 'paths[]=/users' \
  --data 'strip_path=false'

# Add Orders Service
curl -i -X POST http://localhost:8001/services \
  --data name=orders-service \
  --data url=http://orders-api:3002

curl -i -X POST http://localhost:8001/services/orders-service/routes \
  --data 'paths[]=/orders'

# Add Products Service
curl -i -X POST http://localhost:8001/services \
  --data name=products-service \
  --data url=http://products-api:3003

curl -i -X POST http://localhost:8001/services/products-service/routes \
  --data 'paths[]=/products'
```

### 30.4.3 - Kong Plugins

**Enable authentication plugin:**

```bash
# Enable JWT plugin on Users Service
curl -X POST http://localhost:8001/services/users-service/plugins \
  --data "name=jwt"

# Enable rate limiting
curl -X POST http://localhost:8001/services/users-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=100" \
  --data "config.policy=local"

# Enable CORS
curl -X POST http://localhost:8001/services/users-service/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET,POST,PUT,DELETE" \
  --data "config.headers=Authorization,Content-Type"

# Enable request/response logging
curl -X POST http://localhost:8001/services/users-service/plugins \
  --data "name=http-log" \
  --data "config.http_endpoint=http://logger:5000/logs"
```

**Enable caching:**

```bash
curl -X POST http://localhost:8001/services/products-service/plugins \
  --data "name=proxy-cache" \
  --data "config.strategy=memory" \
  --data "config.content_type[]=application/json" \
  --data "config.cache_ttl=300"
```

---

## 30.5 Nginx as API Gateway

### 30.5.1 - Nginx Gateway Configuration

**Complete Nginx gateway:**

```nginx
upstream users_service {
    least_conn;
    server users-api-1:3001;
    server users-api-2:3001;
    server users-api-3:3001;
}

upstream orders_service {
    least_conn;
    server orders-api-1:3002;
    server orders-api-2:3002;
}

upstream products_service {
    least_conn;
    server products-api-1:3003;
    server products-api-2:3003;
}

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/m;
limit_req_zone $http_authorization zone=user_limit:10m rate=1000r/m;

# Cache
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g inactive=60m;

server {
    listen 80;
    server_name api.example.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    ssl_certificate /etc/ssl/certs/api.example.com.crt;
    ssl_certificate_key /etc/ssl/private/api.example.com.key;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    
    # CORS
    add_header Access-Control-Allow-Origin "*" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    
    # OPTIONS preflight
    if ($request_method = OPTIONS) {
        return 204;
    }
    
    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
    }
    
    # Users Service
    location /users {
        limit_req zone=user_limit burst=20 nodelay;
        
        proxy_pass http://users_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 10s;
    }
    
    # Orders Service
    location /orders {
        limit_req zone=user_limit burst=20 nodelay;
        
        proxy_pass http://orders_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Products Service (with caching)
    location /products {
        limit_req zone=api_limit burst=50 nodelay;
        
        # Enable caching for GET requests
        proxy_cache api_cache;
        proxy_cache_methods GET HEAD;
        proxy_cache_valid 200 5m;
        proxy_cache_valid 404 1m;
        proxy_cache_key "$scheme$request_method$host$request_uri";
        
        add_header X-Cache-Status $upstream_cache_status;
        
        proxy_pass http://products_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # Error pages
    error_page 502 503 504 /50x.json;
    location = /50x.json {
        return 503 '{"error":"Service temporarily unavailable"}';
    }
}
```

### 30.5.2 - JWT Validation with Nginx

**Using lua-nginx-module:**

```nginx
server {
    listen 443 ssl http2;
    server_name api.example.com;
    
    location /protected {
        access_by_lua_block {
            local jwt = require "resty.jwt"
            local jwt_secret = os.getenv("JWT_SECRET")
            
            -- Get Authorization header
            local auth_header = ngx.var.http_authorization
            
            if not auth_header then
                ngx.status = 401
                ngx.say('{"error":"No token provided"}')
                return ngx.exit(401)
            end
            
            -- Extract token
            local token = string.match(auth_header, "Bearer%s+(.+)")
            
            if not token then
                ngx.status = 401
                ngx.say('{"error":"Invalid token format"}')
                return ngx.exit(401)
            end
            
            -- Verify JWT
            local jwt_obj = jwt:verify(jwt_secret, token)
            
            if not jwt_obj.verified then
                ngx.status = 401
                ngx.say('{"error":"Invalid token"}')
                return ngx.exit(401)
            end
            
            -- Add user info to headers
            ngx.req.set_header("X-User-ID", jwt_obj.payload.sub)
            ngx.req.set_header("X-User-Role", jwt_obj.payload.role)
        }
        
        proxy_pass http://backend;
    }
}
```

---

## 30.6 Service Discovery

### 30.6.1 - Consul Integration

**Service registration:**

```javascript
const express = require('express');
const Consul = require('consul');

const app = express();
const consul = new Consul({ host: 'consul', port: 8500 });

const SERVICE_NAME = 'users-service';
const SERVICE_ID = `${SERVICE_NAME}-${process.env.INSTANCE_ID}`;
const SERVICE_PORT = 3001;

// Register service with Consul
const registerService = async () => {
    const registration = {
        id: SERVICE_ID,
        name: SERVICE_NAME,
        address: process.env.HOST || 'localhost',
        port: SERVICE_PORT,
        check: {
            http: `http://${process.env.HOST}:${SERVICE_PORT}/health`,
            interval: '10s',
            timeout: '5s'
        }
    };
    
    await consul.agent.service.register(registration);
    console.log('Service registered with Consul');
};

// Deregister on shutdown
const deregisterService = async () => {
    await consul.agent.service.deregister(SERVICE_ID);
    console.log('Service deregistered from Consul');
    process.exit(0);
};

process.on('SIGTERM', deregisterService);
process.on('SIGINT', deregisterService);

// Health endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'UP' });
});

app.listen(SERVICE_PORT, async () => {
    console.log(`Service running on port ${SERVICE_PORT}`);
    await registerService();
});
```

**Gateway with Consul:**

```javascript
const express = require('express');
const Consul = require('consul');
const axios = require('axios');

const app = express();
const consul = new Consul({ host: 'consul', port: 8500 });

// Get healthy service instance
const getServiceUrl = async (serviceName) => {
    const result = await consul.health.service({
        service: serviceName,
        passing: true
    });
    
    if (result.length === 0) {
        throw new Error(`No healthy instances of ${serviceName}`);
    }
    
    // Round-robin selection
    const instance = result[Math.floor(Math.random() * result.length)];
    return `http://${instance.Service.Address}:${instance.Service.Port}`;
};

app.get('/users/:id', async (req, res) => {
    try {
        const serviceUrl = await getServiceUrl('users-service');
        const response = await axios.get(`${serviceUrl}/users/${req.params.id}`);
        
        res.json(response.data);
    } catch (error) {
        res.status(503).json({ error: 'Service unavailable' });
    }
});

app.listen(8080);
```

---

## 30.7 Monitoring & Observability

### 30.7.1 - Distributed Tracing

**OpenTelemetry implementation:**

```javascript
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { registerInstrumentations } = require('@opentelemetry/instrumentation');
const { HttpInstrumentation } = require('@opentelemetry/instrumentation-http');
const { ExpressInstrumentation } = require('@opentelemetry/instrumentation-express');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');

// Setup tracing
const provider = new NodeTracerProvider();

provider.addSpanProcessor(
    new BatchSpanProcessor(
        new JaegerExporter({
            endpoint: 'http://jaeger:14268/api/traces'
        })
    )
);

provider.register();

registerInstrumentations({
    instrumentations: [
        new HttpInstrumentation(),
        new ExpressInstrumentation()
    ]
});

// Express app with tracing
const express = require('express');
const app = express();

app.get('/users/:id', async (req, res) => {
    // Automatically traced!
    const user = await fetchUser(req.params.id);
    res.json(user);
});

app.listen(3001);
```

### 30.7.2 - Metrics Collection

**Prometheus metrics:**

```javascript
const express = require('express');
const prometheus = require('prom-client');

const app = express();

// Metrics
const httpRequestsTotal = new prometheus.Counter({
    name: 'http_requests_total',
    help: 'Total HTTP requests',
    labelNames: ['method', 'route', 'status']
});

const httpRequestDuration = new prometheus.Histogram({
    name: 'http_request_duration_seconds',
    help: 'HTTP request duration',
    labelNames: ['method', 'route', 'status'],
    buckets: [0.001, 0.01, 0.1, 0.5, 1, 5]
});

// Middleware
app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        
        httpRequestsTotal.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
        httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
    });
    
    next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(3001);
```

---

**Capitolo 30 completato!**

Prossimo: **Capitolo 31 - Progressive Web Apps (PWA) e Service Workers**
