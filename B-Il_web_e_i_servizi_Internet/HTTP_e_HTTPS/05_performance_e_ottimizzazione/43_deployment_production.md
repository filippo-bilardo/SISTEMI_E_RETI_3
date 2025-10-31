# 43. Deployment e Production

## 43.1 Introduzione al Deployment

**Deployment in produzione** richiede configurazioni specifiche per sicurezza, performance e affidabilità.

**Checklist produzione:**

```
1. Security
   ✓ HTTPS configurato
   ✓ Security headers attivi
   ✓ Rate limiting
   ✓ Input validation
   ✓ Secrets management

2. Performance
   ✓ Caching configurato
   ✓ Compression attiva
   ✓ CDN setup
   ✓ Database indexes
   ✓ Connection pooling

3. Monitoring
   ✓ Logging configurato
   ✓ Metrics collection
   ✓ Error tracking
   ✓ Health checks
   ✓ Alerts setup

4. Reliability
   ✓ Auto-scaling
   ✓ Load balancing
   ✓ Backup strategy
   ✓ Disaster recovery
   ✓ Zero-downtime deployment
```

---

## 43.2 Environment Configuration

### 43.2.1 - Environment Variables

**.env.example:**

```bash
# Application
NODE_ENV=production
PORT=3000
APP_URL=https://api.example.com

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=dbuser
DB_PASSWORD=secure_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=redis_password

# JWT
JWT_SECRET=very_secure_random_string
JWT_EXPIRATION=1h

# External Services
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1

SENTRY_DSN=https://xxx@sentry.io/xxx
SENDGRID_API_KEY=SG.xxx

# Rate Limiting
RATE_LIMIT_WINDOW=15m
RATE_LIMIT_MAX=100
```

**config.js:**

```javascript
require('dotenv').config();

const config = {
    env: process.env.NODE_ENV || 'development',
    port: parseInt(process.env.PORT, 10) || 3000,
    
    database: {
        host: process.env.DB_HOST,
        port: parseInt(process.env.DB_PORT, 10),
        name: process.env.DB_NAME,
        user: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        pool: {
            min: 2,
            max: 10
        }
    },
    
    redis: {
        host: process.env.REDIS_HOST,
        port: parseInt(process.env.REDIS_PORT, 10),
        password: process.env.REDIS_PASSWORD
    },
    
    jwt: {
        secret: process.env.JWT_SECRET,
        expiration: process.env.JWT_EXPIRATION
    },
    
    cors: {
        origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000']
    },
    
    rateLimit: {
        windowMs: 15 * 60 * 1000, // 15 minutes
        max: parseInt(process.env.RATE_LIMIT_MAX, 10) || 100
    }
};

// Validate required env vars
const required = [
    'DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASSWORD',
    'JWT_SECRET'
];

for (const key of required) {
    if (!process.env[key]) {
        throw new Error(`Missing required environment variable: ${key}`);
    }
}

module.exports = config;
```

### 43.2.2 - Secrets Management

**Using AWS Secrets Manager:**

```javascript
const AWS = require('aws-sdk');

const secretsManager = new AWS.SecretsManager({
    region: process.env.AWS_REGION
});

async function getSecret(secretName) {
    try {
        const data = await secretsManager.getSecretValue({
            SecretId: secretName
        }).promise();
        
        if (data.SecretString) {
            return JSON.parse(data.SecretString);
        }
        
        const buff = Buffer.from(data.SecretBinary, 'base64');
        return buff.toString('ascii');
        
    } catch (error) {
        console.error('Error retrieving secret:', error);
        throw error;
    }
}

// Load secrets at startup
async function loadSecrets() {
    const dbSecret = await getSecret('prod/database');
    const jwtSecret = await getSecret('prod/jwt');
    
    process.env.DB_PASSWORD = dbSecret.password;
    process.env.JWT_SECRET = jwtSecret.secret;
}

module.exports = { loadSecrets };
```

---

## 43.3 Production Server Setup

### 43.3.1 - Express Production Config

**app.js:**

```javascript
const express = require('express');
const helmet = require('helmet');
const compression = require('compression');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const config = require('./config');

const app = express();

// Trust proxy (behind load balancer)
app.set('trust proxy', 1);

// Security headers
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'"],
            imgSrc: ["'self'", 'data:', 'https:'],
        }
    },
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    }
}));

// CORS
app.use(cors({
    origin: config.cors.origin,
    credentials: true,
    optionsSuccessStatus: 200
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Data sanitization
app.use(mongoSanitize());
app.use(hpp());

// Compression
app.use(compression({
    level: 6,
    threshold: 1024,
    filter: (req, res) => {
        if (req.headers['x-no-compression']) {
            return false;
        }
        return compression.filter(req, res);
    }
}));

// Rate limiting
const limiter = rateLimit({
    windowMs: config.rateLimit.windowMs,
    max: config.rateLimit.max,
    message: 'Too many requests from this IP',
    standardHeaders: true,
    legacyHeaders: false
});

app.use('/api', limiter);

// Health check
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

// Routes
app.use('/api/v1', require('./routes'));

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not found',
        path: req.path
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err);
    
    res.status(err.status || 500).json({
        error: config.env === 'production' 
            ? 'Internal server error'
            : err.message
    });
});

module.exports = app;
```

### 43.3.2 - Server Startup

**server.js:**

```javascript
const app = require('./app');
const config = require('./config');
const logger = require('./utils/logger');
const { connectDatabase } = require('./database');
const { loadSecrets } = require('./secrets');

async function startServer() {
    try {
        // Load secrets
        if (config.env === 'production') {
            await loadSecrets();
        }
        
        // Connect to database
        await connectDatabase();
        logger.info('Database connected');
        
        // Start server
        const server = app.listen(config.port, () => {
            logger.info(`Server running on port ${config.port}`);
            logger.info(`Environment: ${config.env}`);
        });
        
        // Graceful shutdown
        process.on('SIGTERM', () => {
            logger.info('SIGTERM received, closing server gracefully');
            
            server.close(() => {
                logger.info('Server closed');
                process.exit(0);
            });
            
            // Force shutdown after 30s
            setTimeout(() => {
                logger.error('Forced shutdown after timeout');
                process.exit(1);
            }, 30000);
        });
        
        // Handle errors
        process.on('unhandledRejection', (reason, promise) => {
            logger.error('Unhandled Rejection:', reason);
        });
        
        process.on('uncaughtException', (error) => {
            logger.error('Uncaught Exception:', error);
            process.exit(1);
        });
        
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();
```

---

## 43.4 Process Management

### 43.4.1 - PM2 Configuration

**ecosystem.config.js:**

```javascript
module.exports = {
    apps: [{
        name: 'api-server',
        script: './server.js',
        instances: 'max',
        exec_mode: 'cluster',
        env: {
            NODE_ENV: 'development'
        },
        env_production: {
            NODE_ENV: 'production'
        },
        error_file: './logs/err.log',
        out_file: './logs/out.log',
        log_date_format: 'YYYY-MM-DD HH:mm:ss',
        merge_logs: true,
        max_memory_restart: '500M',
        watch: false,
        ignore_watch: ['node_modules', 'logs'],
        autorestart: true,
        max_restarts: 10,
        min_uptime: '10s'
    }]
};
```

**PM2 commands:**

```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start ecosystem.config.js --env production

# Monitor
pm2 monit

# List processes
pm2 list

# Logs
pm2 logs

# Reload (zero-downtime)
pm2 reload ecosystem.config.js --env production

# Stop
pm2 stop api-server

# Delete
pm2 delete api-server

# Startup script
pm2 startup
pm2 save
```

### 43.4.2 - Docker Deployment

**Dockerfile:**

```dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy app source
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
RUN chown -R nodejs:nodejs /app

USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node healthcheck.js

# Start app
CMD ["node", "server.js"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DB_HOST=postgres
      - REDIS_HOST=redis
    env_file:
      - .env.production
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    networks:
      - app-network
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=dbuser
      - POSTGRES_PASSWORD=secure_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass redis_password
    volumes:
      - redis-data:/data
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api
    networks:
      - app-network

volumes:
  postgres-data:
  redis-data:

networks:
  app-network:
    driver: bridge
```

**healthcheck.js:**

```javascript
const http = require('http');

const options = {
    host: 'localhost',
    port: 3000,
    path: '/health',
    timeout: 2000
};

const healthCheck = http.request(options, (res) => {
    if (res.statusCode === 200) {
        process.exit(0);
    } else {
        process.exit(1);
    }
});

healthCheck.on('error', () => {
    process.exit(1);
});

healthCheck.end();
```

---

## 43.5 Reverse Proxy (Nginx)

### 43.5.1 - Nginx Configuration

**nginx.conf:**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # Compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_status 429;

    # Upstream
    upstream api_backend {
        least_conn;
        server api:3000 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # HTTP server (redirect to HTTPS)
    server {
        listen 80;
        server_name api.example.com;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$server_name$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name api.example.com;

        # SSL certificates
        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;
        
        # SSL configuration
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

        # Health check
        location /health {
            access_log off;
            proxy_pass http://api_backend;
        }

        # API endpoints
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            
            proxy_pass http://api_backend;
            proxy_http_version 1.1;
            
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Connection "";
            
            proxy_connect_timeout 5s;
            proxy_send_timeout 60s;
            proxy_read_timeout 60s;
            
            proxy_buffering off;
            proxy_cache_bypass $http_upgrade;
        }

        # Static files
        location /static/ {
            alias /var/www/static/;
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

---

## 43.6 SSL/TLS Configuration

### 43.6.1 - Let's Encrypt (Certbot)

**Setup SSL:**

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d api.example.com

# Auto-renewal (cron)
sudo crontab -e
# Add line:
0 12 * * * /usr/bin/certbot renew --quiet
```

### 43.6.2 - SSL Configuration

**Strong SSL config:**

```nginx
# Modern SSL configuration
ssl_protocols TLSv1.3 TLSv1.2;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers off;

# SSL session
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/ssl/chain.pem;

# DNS resolver
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
```

---

## 43.7 CI/CD Pipeline

### 43.7.1 - GitHub Actions

**.github/workflows/deploy.yml:**

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Run linter
        run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            myapp/api:latest
            myapp/api:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.PROD_HOST }}
          username: ${{ secrets.PROD_USER }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /app
            docker-compose pull
            docker-compose up -d
            docker system prune -f
```

---

## 43.8 Zero-Downtime Deployment

### 43.8.1 - Blue-Green Deployment

**deploy.sh:**

```bash
#!/bin/bash

# Blue-Green deployment script

BLUE_PORT=3000
GREEN_PORT=3001
NGINX_CONFIG="/etc/nginx/sites-available/api"

# Determine current active
if grep -q "$BLUE_PORT" "$NGINX_CONFIG"; then
    CURRENT="blue"
    CURRENT_PORT=$BLUE_PORT
    NEW="green"
    NEW_PORT=$GREEN_PORT
else
    CURRENT="green"
    CURRENT_PORT=$GREEN_PORT
    NEW="blue"
    NEW_PORT=$BLUE_PORT
fi

echo "Current active: $CURRENT ($CURRENT_PORT)"
echo "Deploying to: $NEW ($NEW_PORT)"

# Pull new code
git pull origin main

# Install dependencies
npm ci --only=production

# Start new instance
PORT=$NEW_PORT pm2 start ecosystem.config.js --name "api-$NEW"

# Wait for health check
echo "Waiting for $NEW to be healthy..."
for i in {1..30}; do
    if curl -f http://localhost:$NEW_PORT/health > /dev/null 2>&1; then
        echo "$NEW is healthy!"
        break
    fi
    sleep 2
done

# Switch Nginx upstream
sed -i "s/$CURRENT_PORT/$NEW_PORT/g" "$NGINX_CONFIG"
nginx -s reload

echo "Traffic switched to $NEW"

# Wait before stopping old instance
sleep 10

# Stop old instance
pm2 delete "api-$CURRENT"

echo "Deployment complete!"
```

---

**Capitolo 43 completato!** Deployment e produzione completo: environment config, secrets, production setup, PM2, Docker, Nginx, SSL, CI/CD, zero-downtime deployment! 🚀
