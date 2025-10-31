# 42. Monitoring e Logging

## 42.1 Introduzione al Monitoring

**Monitoring** permette di osservare e analizzare il comportamento dell'applicazione in produzione.

**Metriche chiave:**

```
1. Request Metrics
   - Request count
   - Response time (latency)
   - Error rate
   - Throughput (requests/sec)

2. System Metrics
   - CPU usage
   - Memory usage
   - Disk I/O
   - Network I/O

3. Application Metrics
   - Active connections
   - Database queries
   - Cache hit rate
   - Queue length

4. Business Metrics
   - User registrations
   - Transactions
   - Conversion rate
```

---

## 42.2 Logging con Morgan

### 42.2.1 - Setup Morgan

**Basic logging:**

```javascript
const express = require('express');
const morgan = require('morgan');

const app = express();

// Predefined formats
app.use(morgan('dev'));      // Colorful dev logs
// app.use(morgan('combined')); // Apache combined format
// app.use(morgan('common'));   // Apache common format
// app.use(morgan('short'));    // Shorter format
// app.use(morgan('tiny'));     // Minimal output

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.listen(3000);

// Output (dev format):
// GET /api/users 200 12.345 ms - 15
```

### 42.2.2 - Custom Format

**Custom log format:**

```javascript
const express = require('express');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

const app = express();

// Custom tokens
morgan.token('user-id', (req) => {
    return req.user ? req.user.id : 'anonymous';
});

morgan.token('body', (req) => {
    return JSON.stringify(req.body);
});

// Custom format
const customFormat = ':method :url :status :response-time ms - :user-id - :body';

app.use(express.json());
app.use(morgan(customFormat));

app.listen(3000);
```

### 42.2.3 - Log to File

**File logging:**

```javascript
const express = require('express');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');
const rfs = require('rotating-file-stream');

const app = express();

// Create logs directory
const logsDir = path.join(__dirname, 'logs');
if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir);
}

// Rotating file stream (daily rotation)
const accessLogStream = rfs.createStream('access.log', {
    interval: '1d',     // Rotate daily
    path: logsDir,
    maxFiles: 30,       // Keep 30 days
    compress: 'gzip'    // Compress old logs
});

// Log to file (production)
app.use(morgan('combined', { stream: accessLogStream }));

// Log to console (development)
if (process.env.NODE_ENV !== 'production') {
    app.use(morgan('dev'));
}

app.listen(3000);
```

---

## 42.3 Winston Logger

### 42.3.1 - Setup Winston

**Advanced logging:**

```javascript
const winston = require('winston');

// Create logger
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: winston.format.combine(
        winston.format.timestamp({
            format: 'YYYY-MM-DD HH:mm:ss'
        }),
        winston.format.errors({ stack: true }),
        winston.format.splat(),
        winston.format.json()
    ),
    defaultMeta: { service: 'api-service' },
    transports: [
        // Error logs
        new winston.transports.File({ 
            filename: 'logs/error.log', 
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5
        }),
        
        // Combined logs
        new winston.transports.File({ 
            filename: 'logs/combined.log',
            maxsize: 5242880,
            maxFiles: 10
        })
    ]
});

// Console logging in development
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple()
        )
    }));
}

module.exports = logger;
```

### 42.3.2 - Using Winston

**Application logging:**

```javascript
const express = require('express');
const logger = require('./logger');

const app = express();

// Request logging middleware
app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        
        logger.info('HTTP Request', {
            method: req.method,
            url: req.url,
            status: res.statusCode,
            duration: `${duration}ms`,
            ip: req.ip,
            userAgent: req.get('user-agent')
        });
    });
    
    next();
});

// API endpoints
app.get('/api/users', (req, res) => {
    logger.debug('Fetching users', { query: req.query });
    
    try {
        const users = [{ id: 1, name: 'John' }];
        
        logger.info('Users fetched successfully', { 
            count: users.length 
        });
        
        res.json({ data: users });
        
    } catch (error) {
        logger.error('Error fetching users', { 
            error: error.message,
            stack: error.stack
        });
        
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        url: req.url,
        method: req.method
    });
    
    res.status(500).json({ error: 'Internal server error' });
});

app.listen(3000);
```

---

## 42.4 Application Metrics

### 42.4.1 - Response Time Middleware

**Track response times:**

```javascript
const express = require('express');
const responseTime = require('response-time');

const app = express();

// Response time header
app.use(responseTime());

// Custom metrics
const metrics = {
    requests: 0,
    errors: 0,
    responseTimes: []
};

app.use((req, res, next) => {
    const start = Date.now();
    
    metrics.requests++;
    
    res.on('finish', () => {
        const duration = Date.now() - start;
        metrics.responseTimes.push(duration);
        
        if (res.statusCode >= 400) {
            metrics.errors++;
        }
        
        // Keep only last 1000 requests
        if (metrics.responseTimes.length > 1000) {
            metrics.responseTimes.shift();
        }
    });
    
    next();
});

// Metrics endpoint
app.get('/metrics', (req, res) => {
    const avgResponseTime = metrics.responseTimes.length > 0
        ? metrics.responseTimes.reduce((a, b) => a + b, 0) / metrics.responseTimes.length
        : 0;
    
    const p95 = metrics.responseTimes.length > 0
        ? metrics.responseTimes.sort((a, b) => a - b)[Math.floor(metrics.responseTimes.length * 0.95)]
        : 0;
    
    res.json({
        requests: metrics.requests,
        errors: metrics.errors,
        errorRate: metrics.requests > 0 
            ? (metrics.errors / metrics.requests * 100).toFixed(2) + '%'
            : '0%',
        avgResponseTime: avgResponseTime.toFixed(2) + 'ms',
        p95ResponseTime: p95.toFixed(2) + 'ms'
    });
});

app.listen(3000);
```

### 42.4.2 - Prometheus Metrics

**Prometheus integration:**

```javascript
const express = require('express');
const promClient = require('prom-client');

const app = express();

// Create a Registry
const register = new promClient.Registry();

// Add default metrics (CPU, memory, etc.)
promClient.collectDefaultMetrics({ register });

// Custom metrics
const httpRequestDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
});

const httpRequestTotal = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

const activeConnections = new promClient.Gauge({
    name: 'http_active_connections',
    help: 'Number of active HTTP connections'
});

// Register metrics
register.registerMetric(httpRequestDuration);
register.registerMetric(httpRequestTotal);
register.registerMetric(activeConnections);

// Metrics middleware
app.use((req, res, next) => {
    const start = Date.now();
    
    activeConnections.inc();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        
        const labels = {
            method: req.method,
            route: req.route?.path || req.path,
            status_code: res.statusCode
        };
        
        httpRequestDuration.observe(labels, duration);
        httpRequestTotal.inc(labels);
        activeConnections.dec();
    });
    
    next();
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', register.contentType);
    const metrics = await register.metrics();
    res.send(metrics);
});

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.listen(3000);
```

---

## 42.5 Health Checks

### 42.5.1 - Basic Health Check

**Simple health endpoint:**

```javascript
const express = require('express');
const app = express();

app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV
    });
});

app.listen(3000);
```

### 42.5.2 - Advanced Health Check

**Comprehensive health check:**

```javascript
const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');

const app = express();
const redisClient = redis.createClient();

// Health check function
async function checkHealth() {
    const health = {
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        checks: {}
    };
    
    // Database check
    try {
        await mongoose.connection.db.admin().ping();
        health.checks.database = {
            status: 'ok',
            responseTime: 0
        };
    } catch (error) {
        health.status = 'degraded';
        health.checks.database = {
            status: 'error',
            error: error.message
        };
    }
    
    // Redis check
    try {
        const start = Date.now();
        await new Promise((resolve, reject) => {
            redisClient.ping((err, reply) => {
                if (err) reject(err);
                else resolve(reply);
            });
        });
        health.checks.redis = {
            status: 'ok',
            responseTime: Date.now() - start
        };
    } catch (error) {
        health.status = 'degraded';
        health.checks.redis = {
            status: 'error',
            error: error.message
        };
    }
    
    // Memory check
    const memUsage = process.memoryUsage();
    const memLimit = 512 * 1024 * 1024; // 512MB
    
    health.checks.memory = {
        status: memUsage.heapUsed < memLimit ? 'ok' : 'warning',
        heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024) + 'MB',
        heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024) + 'MB'
    };
    
    return health;
}

// Health endpoint
app.get('/health', async (req, res) => {
    const health = await checkHealth();
    const statusCode = health.status === 'ok' ? 200 : 503;
    res.status(statusCode).json(health);
});

// Readiness probe (Kubernetes)
app.get('/ready', async (req, res) => {
    const health = await checkHealth();
    
    if (health.status === 'ok') {
        res.status(200).json({ ready: true });
    } else {
        res.status(503).json({ ready: false });
    }
});

// Liveness probe (Kubernetes)
app.get('/live', (req, res) => {
    res.status(200).json({ alive: true });
});

app.listen(3000);
```

---

## 42.6 Error Tracking

### 42.6.1 - Sentry Integration

**Error tracking con Sentry:**

```javascript
const express = require('express');
const Sentry = require('@sentry/node');

const app = express();

// Initialize Sentry
Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 1.0
});

// Request handler must be first
app.use(Sentry.Handlers.requestHandler());

// Tracing middleware
app.use(Sentry.Handlers.tracingHandler());

app.use(express.json());

// Routes
app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

app.get('/error', (req, res) => {
    throw new Error('Test error');
});

// Error handler must be before other error middleware
app.use(Sentry.Handlers.errorHandler());

// Custom error handler
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({
        error: 'Internal server error',
        id: res.sentry // Sentry error ID
    });
});

app.listen(3000);
```

### 42.6.2 - Custom Error Tracking

**Manual error tracking:**

```javascript
const express = require('express');
const logger = require('./logger');

const app = express();

// Error tracking store
const errors = [];

function trackError(error, context = {}) {
    const errorData = {
        timestamp: new Date().toISOString(),
        message: error.message,
        stack: error.stack,
        context
    };
    
    errors.push(errorData);
    
    // Keep only last 100 errors
    if (errors.length > 100) {
        errors.shift();
    }
    
    logger.error('Error tracked', errorData);
    
    // Send to external service
    // sendToErrorService(errorData);
}

app.get('/api/users/:id', async (req, res, next) => {
    try {
        const userId = req.params.id;
        
        if (!userId) {
            throw new Error('User ID required');
        }
        
        // Simulate error
        if (userId === '999') {
            throw new Error('User not found');
        }
        
        res.json({ user: { id: userId } });
        
    } catch (error) {
        trackError(error, {
            url: req.url,
            method: req.method,
            params: req.params,
            userId: req.user?.id
        });
        
        next(error);
    }
});

// Error dashboard
app.get('/errors', (req, res) => {
    res.json({
        total: errors.length,
        errors: errors.slice(-20) // Last 20 errors
    });
});

app.listen(3000);
```

---

## 42.7 APM (Application Performance Monitoring)

### 42.7.1 - New Relic Integration

**Performance monitoring:**

```javascript
// Load New Relic first
require('newrelic');

const express = require('express');
const app = express();

app.get('/api/users', async (req, res) => {
    // New Relic automatically tracks this
    const users = await fetchUsers();
    res.json({ users });
});

app.listen(3000);
```

**newrelic.js configuration:**

```javascript
exports.config = {
    app_name: ['My API'],
    license_key: process.env.NEW_RELIC_LICENSE_KEY,
    logging: {
        level: 'info'
    },
    allow_all_headers: true,
    attributes: {
        exclude: [
            'request.headers.cookie',
            'request.headers.authorization'
        ]
    }
};
```

### 42.7.2 - Custom Transactions

**Track custom operations:**

```javascript
const newrelic = require('newrelic');

async function processOrder(orderId) {
    // Start custom transaction
    return newrelic.startBackgroundTransaction('process-order', async () => {
        const transaction = newrelic.getTransaction();
        
        // Add custom attributes
        transaction.addCustomAttribute('orderId', orderId);
        
        // Create segments for different parts
        const fetchSegment = newrelic.startSegment('fetch-order', true, () => {
            return fetchOrderFromDB(orderId);
        });
        
        const processSegment = newrelic.startSegment('process-payment', true, () => {
            return processPayment(orderId);
        });
        
        transaction.end();
    });
}
```

---

## 42.8 Complete Monitoring Setup

### 42.8.1 - Production Monitoring

**Full monitoring stack:**

```javascript
const express = require('express');
const winston = require('winston');
const promClient = require('prom-client');
const Sentry = require('@sentry/node');

const app = express();

// Sentry
Sentry.init({
    dsn: process.env.SENTRY_DSN,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 1.0
});

app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.tracingHandler());

// Winston logger
const logger = winston.createLogger({
    level: 'info',
    format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.json()
    ),
    transports: [
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' })
    ]
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple()
    }));
}

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpDuration = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5]
});

const httpErrors = new promClient.Counter({
    name: 'http_errors_total',
    help: 'Total number of HTTP errors',
    labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpDuration);
register.registerMetric(httpErrors);

// Metrics middleware
app.use((req, res, next) => {
    const start = Date.now();
    
    res.on('finish', () => {
        const duration = (Date.now() - start) / 1000;
        
        const labels = {
            method: req.method,
            route: req.route?.path || req.path,
            status_code: res.statusCode
        };
        
        httpDuration.observe(labels, duration);
        
        if (res.statusCode >= 400) {
            httpErrors.inc(labels);
        }
        
        logger.info('HTTP Request', {
            ...labels,
            duration: `${duration.toFixed(3)}s`,
            ip: req.ip,
            userAgent: req.get('user-agent')
        });
    });
    
    next();
});

// Routes
app.get('/metrics', async (req, res) => {
    res.setHeader('Content-Type', register.contentType);
    res.send(await register.metrics());
});

app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/api/users', (req, res) => {
    res.json({ users: [] });
});

// Error handling
app.use(Sentry.Handlers.errorHandler());

app.use((err, req, res, next) => {
    logger.error('Unhandled error', {
        error: err.message,
        stack: err.stack,
        url: req.url
    });
    
    res.status(500).json({ 
        error: 'Internal server error',
        id: res.sentry
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    logger.info(`Server started on port ${PORT}`);
});
```

---

**Capitolo 42 completato!** Monitoring e logging completo: Morgan, Winston, Prometheus, health checks, Sentry, APM, e setup production-ready! 📊
