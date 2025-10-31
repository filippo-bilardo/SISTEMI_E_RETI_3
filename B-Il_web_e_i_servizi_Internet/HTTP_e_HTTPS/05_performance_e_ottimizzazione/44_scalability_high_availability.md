# 44. Scalabilità e High Availability

## 44.1 Introduzione alla Scalabilità

**Scalabilità** è la capacità di gestire crescita del traffico mantenendo performance.

**Tipi di scaling:**

```
1. Vertical Scaling (Scale Up)
   - Aumentare risorse server (CPU, RAM)
   - Limite fisico dell'hardware
   - Downtime per upgrade
   - Costo elevato

2. Horizontal Scaling (Scale Out)
   - Aggiungere più server
   - Scalabilità illimitata
   - Zero downtime
   - Load balancing richiesto

3. Auto-Scaling
   - Scaling automatico basato su metriche
   - Ottimizzazione costi
   - Elasticità
```

---

## 44.2 Load Balancing

### 44.2.1 - Nginx Load Balancer

**nginx.conf:**

```nginx
upstream backend {
    # Load balancing methods:
    
    # 1. Round Robin (default)
    # Distribuisce richieste in modo circolare
    server backend1.example.com:3000;
    server backend2.example.com:3000;
    server backend3.example.com:3000;
    
    # 2. Least Connections
    # least_conn;
    # Invia alla connessione con meno richieste attive
    
    # 3. IP Hash
    # ip_hash;
    # Stesso client sempre allo stesso server
    
    # 4. Weighted
    # server backend1.example.com:3000 weight=3;
    # server backend2.example.com:3000 weight=2;
    # server backend3.example.com:3000 weight=1;
    
    # Health checks
    server backend1.example.com:3000 max_fails=3 fail_timeout=30s;
    server backend2.example.com:3000 max_fails=3 fail_timeout=30s;
    server backend3.example.com:3000 max_fails=3 fail_timeout=30s backup;
    
    # Keep-alive connections
    keepalive 32;
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
}
```

### 44.2.2 - HAProxy Configuration

**haproxy.cfg:**

```
global
    maxconn 4096
    daemon
    log 127.0.0.1 local0
    
defaults
    mode http
    log global
    option httplog
    option dontlognull
    timeout connect 5s
    timeout client 50s
    timeout server 50s
    
frontend http-in
    bind *:80
    
    # ACL definitions
    acl is_api path_beg /api
    acl is_static path_beg /static
    
    # Routing
    use_backend api_servers if is_api
    use_backend static_servers if is_static
    default_backend web_servers
    
backend api_servers
    balance leastconn
    option httpchk GET /health
    http-check expect status 200
    
    server api1 10.0.1.10:3000 check inter 2s fall 3 rise 2
    server api2 10.0.1.11:3000 check inter 2s fall 3 rise 2
    server api3 10.0.1.12:3000 check inter 2s fall 3 rise 2
    
backend web_servers
    balance roundrobin
    cookie SERVERID insert indirect nocache
    
    server web1 10.0.2.10:80 check cookie web1
    server web2 10.0.2.11:80 check cookie web2
    
backend static_servers
    balance source
    server cdn1 10.0.3.10:80 check
    server cdn2 10.0.3.11:80 check

# Stats page
listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
    stats auth admin:password
```

---

## 44.3 Session Management

### 44.3.1 - Sticky Sessions

**Nginx sticky sessions:**

```nginx
upstream backend {
    ip_hash;  # Same IP always to same server
    server backend1:3000;
    server backend2:3000;
    server backend3:3000;
}
```

### 44.3.2 - Shared Session Store

**Redis session store:**

```javascript
const express = require('express');
const session = require('express-session');
const RedisStore = require('connect-redis').default;
const { createClient } = require('redis');

const app = express();

// Redis client
const redisClient = createClient({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    password: process.env.REDIS_PASSWORD,
    legacyMode: true
});

redisClient.connect().catch(console.error);

// Session middleware
app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: {
        secure: process.env.NODE_ENV === 'production',
        httpOnly: true,
        maxAge: 1000 * 60 * 60 * 24 // 24 hours
    }
}));

app.get('/login', (req, res) => {
    req.session.userId = 123;
    req.session.username = 'john';
    res.json({ message: 'Logged in' });
});

app.get('/profile', (req, res) => {
    if (!req.session.userId) {
        return res.status(401).json({ error: 'Not authenticated' });
    }
    
    res.json({
        userId: req.session.userId,
        username: req.session.username
    });
});

app.listen(3000);
```

### 44.3.3 - Stateless Authentication (JWT)

**JWT per stateless apps:**

```javascript
const express = require('express');
const jwt = require('jsonwebtoken');

const app = express();
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET;

// Login
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    
    // Validate credentials (simplified)
    if (email === 'user@example.com' && password === 'password') {
        const token = jwt.sign(
            { userId: 123, email },
            JWT_SECRET,
            { expiresIn: '1h' }
        );
        
        res.json({ token });
    } else {
        res.status(401).json({ error: 'Invalid credentials' });
    }
});

// Auth middleware
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }
    
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ error: 'Invalid token' });
        }
        req.user = user;
        next();
    });
}

// Protected route
app.get('/profile', authenticateToken, (req, res) => {
    res.json({
        userId: req.user.userId,
        email: req.user.email
    });
});

app.listen(3000);
```

---

## 44.4 Database Scaling

### 44.4.1 - Read Replicas

**PostgreSQL replication:**

```javascript
const { Pool } = require('pg');

// Master (write)
const masterPool = new Pool({
    host: process.env.DB_MASTER_HOST,
    port: 5432,
    database: 'myapp',
    user: 'dbuser',
    password: 'password',
    max: 20
});

// Replica (read)
const replicaPool = new Pool({
    host: process.env.DB_REPLICA_HOST,
    port: 5432,
    database: 'myapp',
    user: 'dbuser',
    password: 'password',
    max: 20
});

// Write operation
async function createUser(name, email) {
    const result = await masterPool.query(
        'INSERT INTO users (name, email) VALUES ($1, $2) RETURNING *',
        [name, email]
    );
    return result.rows[0];
}

// Read operation
async function getUser(id) {
    const result = await replicaPool.query(
        'SELECT * FROM users WHERE id = $1',
        [id]
    );
    return result.rows[0];
}

// List operation (read)
async function getUsers() {
    const result = await replicaPool.query('SELECT * FROM users');
    return result.rows;
}
```

### 44.4.2 - Sharding

**Database sharding:**

```javascript
const { Pool } = require('pg');

// Multiple shards
const shards = [
    new Pool({ host: 'shard1.db.example.com', database: 'myapp' }),
    new Pool({ host: 'shard2.db.example.com', database: 'myapp' }),
    new Pool({ host: 'shard3.db.example.com', database: 'myapp' })
];

// Sharding key (user ID)
function getShardForUser(userId) {
    const shardIndex = userId % shards.length;
    return shards[shardIndex];
}

// Operations
async function getUserById(userId) {
    const shard = getShardForUser(userId);
    const result = await shard.query(
        'SELECT * FROM users WHERE id = $1',
        [userId]
    );
    return result.rows[0];
}

async function createUser(userId, name, email) {
    const shard = getShardForUser(userId);
    const result = await shard.query(
        'INSERT INTO users (id, name, email) VALUES ($1, $2, $3) RETURNING *',
        [userId, name, email]
    );
    return result.rows[0];
}

// Cross-shard query (expensive!)
async function getAllUsers() {
    const results = await Promise.all(
        shards.map(shard => shard.query('SELECT * FROM users'))
    );
    
    return results.flatMap(r => r.rows);
}
```

---

## 44.5 Caching Strategies

### 44.5.1 - Multi-Level Cache

**Cache hierarchy:**

```javascript
const NodeCache = require('node-cache');
const redis = require('redis');

// L1: In-memory cache (fast, local)
const memoryCache = new NodeCache({ stdTTL: 60 });

// L2: Redis cache (shared, persistent)
const redisClient = redis.createClient({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
});

redisClient.connect();

async function getCachedData(key) {
    // Check L1 cache
    let data = memoryCache.get(key);
    if (data) {
        console.log('L1 cache hit');
        return data;
    }
    
    // Check L2 cache
    data = await redisClient.get(key);
    if (data) {
        console.log('L2 cache hit');
        data = JSON.parse(data);
        
        // Populate L1 cache
        memoryCache.set(key, data);
        return data;
    }
    
    // Cache miss - fetch from database
    console.log('Cache miss');
    data = await fetchFromDatabase(key);
    
    // Populate both caches
    memoryCache.set(key, data);
    await redisClient.setEx(key, 3600, JSON.stringify(data));
    
    return data;
}

async function invalidateCache(key) {
    memoryCache.del(key);
    await redisClient.del(key);
}
```

### 44.5.2 - Cache-Aside Pattern

**Application-managed cache:**

```javascript
const express = require('express');
const redis = require('redis');

const app = express();
const redisClient = redis.createClient();
redisClient.connect();

app.get('/users/:id', async (req, res) => {
    const userId = req.params.id;
    const cacheKey = `user:${userId}`;
    
    try {
        // Try cache first
        let user = await redisClient.get(cacheKey);
        
        if (user) {
            console.log('Cache hit');
            return res.json(JSON.parse(user));
        }
        
        // Cache miss - fetch from DB
        console.log('Cache miss');
        user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
        
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        // Store in cache (TTL 1 hour)
        await redisClient.setEx(cacheKey, 3600, JSON.stringify(user));
        
        res.json(user);
        
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Update user (invalidate cache)
app.put('/users/:id', async (req, res) => {
    const userId = req.params.id;
    const cacheKey = `user:${userId}`;
    
    try {
        // Update database
        const user = await db.query(
            'UPDATE users SET name = $1 WHERE id = $2 RETURNING *',
            [req.body.name, userId]
        );
        
        // Invalidate cache
        await redisClient.del(cacheKey);
        
        res.json(user);
        
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(3000);
```

---

## 44.6 Message Queue

### 44.6.1 - RabbitMQ Producer/Consumer

**Producer (API server):**

```javascript
const amqp = require('amqplib');

async function sendToQueue(queueName, data) {
    try {
        const connection = await amqp.connect(process.env.RABBITMQ_URL);
        const channel = await connection.createChannel();
        
        await channel.assertQueue(queueName, { durable: true });
        
        channel.sendToQueue(
            queueName,
            Buffer.from(JSON.stringify(data)),
            { persistent: true }
        );
        
        console.log('Message sent to queue:', queueName);
        
        setTimeout(() => {
            connection.close();
        }, 500);
        
    } catch (error) {
        console.error('Queue error:', error);
    }
}

// API endpoint
app.post('/orders', async (req, res) => {
    const order = req.body;
    
    // Save to database
    const savedOrder = await db.saveOrder(order);
    
    // Send to queue for async processing
    await sendToQueue('order-processing', {
        orderId: savedOrder.id,
        userId: savedOrder.userId,
        items: savedOrder.items
    });
    
    res.status(201).json(savedOrder);
});
```

**Consumer (Worker):**

```javascript
const amqp = require('amqplib');

async function startConsumer() {
    try {
        const connection = await amqp.connect(process.env.RABBITMQ_URL);
        const channel = await connection.createChannel();
        
        const queueName = 'order-processing';
        await channel.assertQueue(queueName, { durable: true });
        
        // Prefetch: process 1 message at a time
        channel.prefetch(1);
        
        console.log('Waiting for messages in queue:', queueName);
        
        channel.consume(queueName, async (msg) => {
            if (msg) {
                const data = JSON.parse(msg.content.toString());
                
                try {
                    console.log('Processing order:', data.orderId);
                    
                    // Process order (send email, charge payment, etc.)
                    await processOrder(data);
                    
                    // Acknowledge message
                    channel.ack(msg);
                    
                    console.log('Order processed:', data.orderId);
                    
                } catch (error) {
                    console.error('Processing error:', error);
                    
                    // Reject and requeue
                    channel.nack(msg, false, true);
                }
            }
        });
        
    } catch (error) {
        console.error('Consumer error:', error);
    }
}

startConsumer();
```

---

## 44.7 Auto-Scaling

### 44.7.1 - AWS Auto Scaling

**Auto Scaling Group configuration:**

```json
{
  "AutoScalingGroupName": "api-servers",
  "MinSize": 2,
  "MaxSize": 10,
  "DesiredCapacity": 3,
  "DefaultCooldown": 300,
  "HealthCheckType": "ELB",
  "HealthCheckGracePeriod": 300,
  "LaunchTemplate": {
    "LaunchTemplateId": "lt-xxx",
    "Version": "$Latest"
  },
  "TargetGroupARNs": ["arn:aws:elasticloadbalancing:..."],
  "VPCZoneIdentifier": "subnet-xxx,subnet-yyy"
}
```

**Scaling policies:**

```json
{
  "PolicyName": "scale-up",
  "AutoScalingGroupName": "api-servers",
  "PolicyType": "TargetTrackingScaling",
  "TargetTrackingConfiguration": {
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "TargetValue": 70.0
  }
}
```

### 44.7.2 - Kubernetes Horizontal Pod Autoscaler

**deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: myapp/api:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-deployment
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

---

## 44.8 Circuit Breaker Pattern

### 44.8.1 - Circuit Breaker Implementation

**Protect against cascading failures:**

```javascript
class CircuitBreaker {
    constructor(options = {}) {
        this.failureThreshold = options.failureThreshold || 5;
        this.timeout = options.timeout || 60000;
        this.resetTimeout = options.resetTimeout || 30000;
        
        this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
        this.failures = 0;
        this.nextAttempt = Date.now();
    }
    
    async call(fn) {
        if (this.state === 'OPEN') {
            if (Date.now() < this.nextAttempt) {
                throw new Error('Circuit breaker is OPEN');
            }
            this.state = 'HALF_OPEN';
        }
        
        try {
            const result = await Promise.race([
                fn(),
                new Promise((_, reject) => 
                    setTimeout(() => reject(new Error('Timeout')), this.timeout)
                )
            ]);
            
            this.onSuccess();
            return result;
            
        } catch (error) {
            this.onFailure();
            throw error;
        }
    }
    
    onSuccess() {
        this.failures = 0;
        if (this.state === 'HALF_OPEN') {
            this.state = 'CLOSED';
        }
    }
    
    onFailure() {
        this.failures++;
        if (this.failures >= this.failureThreshold) {
            this.state = 'OPEN';
            this.nextAttempt = Date.now() + this.resetTimeout;
        }
    }
}

// Usage
const axios = require('axios');
const breaker = new CircuitBreaker({ failureThreshold: 3 });

async function callExternalAPI() {
    try {
        const result = await breaker.call(async () => {
            return await axios.get('https://api.example.com/data');
        });
        
        return result.data;
        
    } catch (error) {
        console.error('API call failed:', error.message);
        return { error: 'Service unavailable' };
    }
}
```

---

**Capitolo 44 completato!** Scalabilità e HA completo: load balancing, session management, database scaling, caching, message queue, auto-scaling, circuit breaker! ⚡
