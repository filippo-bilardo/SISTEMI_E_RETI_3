# 40. API Versioning e Documentation

## 40.1 Introduzione al Versioning

**API versioning** permette di evolvere l'API senza rompere i client esistenti.

**Motivi per il versioning:**

```
1. Breaking Changes
   - Modifiche incompatibili con versione precedente

2. Nuove Feature
   - Aggiungere funzionalità senza impattare client vecchi

3. Deprecation
   - Rimuovere gradualmente endpoint obsoleti

4. Migration
   - Tempo ai client per migrare alla nuova versione
```

**Strategie di versioning:**

```
1. URI Versioning
   /api/v1/users
   /api/v2/users

2. Query Parameter
   /api/users?version=1
   /api/users?version=2

3. Header Versioning
   Accept: application/vnd.api.v1+json
   X-API-Version: 1

4. Content Negotiation
   Accept: application/vnd.api+json; version=1

5. Subdomain
   v1.api.example.com
   v2.api.example.com
```

---

## 40.2 URI Versioning

### 40.2.1 - Path-Based Versioning

**Versione nell'URL (più comune):**

```javascript
const express = require('express');
const app = express();

// V1 API
const v1Router = express.Router();

v1Router.get('/users', (req, res) => {
    res.json({
        version: 'v1',
        users: [
            { id: 1, name: 'John Doe' }
        ]
    });
});

v1Router.get('/users/:id', (req, res) => {
    res.json({
        version: 'v1',
        user: { id: req.params.id, name: 'John Doe' }
    });
});

// V2 API (breaking changes)
const v2Router = express.Router();

v2Router.get('/users', (req, res) => {
    res.json({
        version: 'v2',
        data: [
            { 
                id: 1, 
                firstName: 'John',   // Changed from 'name'
                lastName: 'Doe',
                email: 'john@example.com'
            }
        ],
        meta: {
            total: 1,
            page: 1
        }
    });
});

v2Router.get('/users/:id', (req, res) => {
    res.json({
        version: 'v2',
        data: { 
            id: req.params.id, 
            firstName: 'John',
            lastName: 'Doe',
            email: 'john@example.com'
        }
    });
});

// Mount routers
app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);

// Default to latest version
app.use('/api', v2Router);

app.listen(3000);
```

### 40.2.2 - Organized Structure

**File organization:**

```
project/
├── routes/
│   ├── v1/
│   │   ├── users.js
│   │   ├── posts.js
│   │   └── index.js
│   ├── v2/
│   │   ├── users.js
│   │   ├── posts.js
│   │   └── index.js
│   └── index.js
├── controllers/
│   ├── v1/
│   │   ├── userController.js
│   │   └── postController.js
│   └── v2/
│       ├── userController.js
│       └── postController.js
└── app.js
```

**routes/v1/users.js:**

```javascript
const express = require('express');
const router = express.Router();
const userController = require('../../controllers/v1/userController');

router.get('/', userController.getUsers);
router.get('/:id', userController.getUser);
router.post('/', userController.createUser);
router.put('/:id', userController.updateUser);
router.delete('/:id', userController.deleteUser);

module.exports = router;
```

**routes/v1/index.js:**

```javascript
const express = require('express');
const router = express.Router();

const usersRouter = require('./users');
const postsRouter = require('./posts');

router.use('/users', usersRouter);
router.use('/posts', postsRouter);

module.exports = router;
```

**app.js:**

```javascript
const express = require('express');
const app = express();

const v1Routes = require('./routes/v1');
const v2Routes = require('./routes/v2');

app.use(express.json());

app.use('/api/v1', v1Routes);
app.use('/api/v2', v2Routes);

// Latest version as default
app.use('/api', v2Routes);

app.listen(3000);
```

---

## 40.3 Header Versioning

### 40.3.1 - Custom Header

**API version in custom header:**

```javascript
const express = require('express');
const app = express();

function versionMiddleware(req, res, next) {
    // Get version from header
    const version = req.headers['x-api-version'] || '1';
    req.apiVersion = version;
    
    res.setHeader('X-API-Version', version);
    next();
}

app.use(versionMiddleware);

app.get('/api/users', (req, res) => {
    if (req.apiVersion === '1') {
        // V1 response
        res.json({
            users: [{ id: 1, name: 'John Doe' }]
        });
    } else if (req.apiVersion === '2') {
        // V2 response
        res.json({
            data: [{ 
                id: 1, 
                firstName: 'John', 
                lastName: 'Doe' 
            }],
            meta: { total: 1 }
        });
    } else {
        res.status(400).json({ 
            error: 'Unsupported API version' 
        });
    }
});

app.listen(3000);
```

### 40.3.2 - Accept Header (Content Negotiation)

**Versione nel MIME type:**

```javascript
const express = require('express');
const app = express();

app.get('/api/users', (req, res) => {
    const accept = req.headers.accept || '';
    
    if (accept.includes('application/vnd.api.v1+json')) {
        // V1
        res.setHeader('Content-Type', 'application/vnd.api.v1+json');
        res.json({ users: [{ id: 1, name: 'John' }] });
        
    } else if (accept.includes('application/vnd.api.v2+json')) {
        // V2
        res.setHeader('Content-Type', 'application/vnd.api.v2+json');
        res.json({ 
            data: [{ id: 1, firstName: 'John', lastName: 'Doe' }],
            meta: { total: 1 }
        });
        
    } else {
        // Default to latest
        res.setHeader('Content-Type', 'application/vnd.api.v2+json');
        res.json({ 
            data: [{ id: 1, firstName: 'John', lastName: 'Doe' }],
            meta: { total: 1 }
        });
    }
});

app.listen(3000);
```

**Client request:**

```bash
# V1
curl -H "Accept: application/vnd.api.v1+json" http://localhost:3000/api/users

# V2
curl -H "Accept: application/vnd.api.v2+json" http://localhost:3000/api/users
```

---

## 40.4 Deprecation Strategy

### 40.4.1 - Deprecation Headers

**Deprecare endpoint vecchi:**

```javascript
const express = require('express');
const app = express();

// V1 - Deprecated
app.use('/api/v1', (req, res, next) => {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', 'Sat, 31 Dec 2025 23:59:59 GMT');
    res.setHeader('Link', '</api/v2>; rel="successor-version"');
    
    // Warn header
    res.setHeader(
        'Warning', 
        '299 - "API v1 is deprecated. Migrate to v2 by Dec 31, 2025"'
    );
    
    next();
});

const v1Router = express.Router();

v1Router.get('/users', (req, res) => {
    res.json({
        warning: 'This endpoint is deprecated. Use /api/v2/users',
        users: [{ id: 1, name: 'John' }]
    });
});

app.use('/api/v1', v1Router);

// V2 - Current
const v2Router = express.Router();

v2Router.get('/users', (req, res) => {
    res.json({
        data: [{ id: 1, firstName: 'John', lastName: 'Doe' }]
    });
});

app.use('/api/v2', v2Router);

app.listen(3000);
```

### 40.4.2 - Graceful Migration

**Periodo di transizione:**

```javascript
const express = require('express');
const app = express();

// Configuration
const DEPRECATION_DATE = new Date('2025-12-31');
const SUNSET_DATE = new Date('2026-03-31');
const now = new Date();

// V1 endpoint
app.get('/api/v1/users', (req, res) => {
    const daysUntilSunset = Math.ceil(
        (SUNSET_DATE - now) / (1000 * 60 * 60 * 24)
    );
    
    // Check if already sunset
    if (now > SUNSET_DATE) {
        return res.status(410).json({
            error: 'This endpoint has been removed',
            message: 'API v1 was sunset on March 31, 2026',
            migrate_to: '/api/v2/users'
        });
    }
    
    // Deprecation warnings
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', SUNSET_DATE.toUTCString());
    res.setHeader('Link', '</api/v2/users>; rel="successor-version"');
    
    if (daysUntilSunset <= 30) {
        res.setHeader(
            'Warning',
            `299 - "This endpoint will be removed in ${daysUntilSunset} days"`
        );
    }
    
    // Log usage for metrics
    console.log(`V1 API used: ${req.path} (${daysUntilSunset} days until sunset)`);
    
    res.json({
        _deprecation: {
            deprecated: true,
            sunset_date: SUNSET_DATE.toISOString(),
            days_remaining: daysUntilSunset,
            migrate_to: '/api/v2/users'
        },
        users: [{ id: 1, name: 'John Doe' }]
    });
});

app.listen(3000);
```

---

## 40.5 OpenAPI/Swagger Documentation

### 40.5.1 - Swagger Setup

**Setup Swagger con versioning:**

```javascript
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

const app = express();

// Swagger definition V1
const swaggerOptionsV1 = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'My API V1',
            version: '1.0.0',
            description: 'API Version 1 (Deprecated)',
            contact: {
                name: 'API Support',
                email: 'support@example.com'
            }
        },
        servers: [
            {
                url: 'http://localhost:3000/api/v1',
                description: 'Development server V1'
            }
        ],
        externalDocs: {
            description: 'Migration guide to V2',
            url: 'https://docs.example.com/migration-v1-to-v2'
        }
    },
    apis: ['./routes/v1/*.js']
};

const swaggerSpecV1 = swaggerJsdoc(swaggerOptionsV1);

// Swagger definition V2
const swaggerOptionsV2 = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'My API V2',
            version: '2.0.0',
            description: 'API Version 2 (Current)'
        },
        servers: [
            {
                url: 'http://localhost:3000/api/v2',
                description: 'Development server V2'
            }
        ]
    },
    apis: ['./routes/v2/*.js']
};

const swaggerSpecV2 = swaggerJsdoc(swaggerOptionsV2);

// Serve Swagger UI
app.use('/api-docs/v1', swaggerUi.serveFiles(swaggerSpecV1), swaggerUi.setup(swaggerSpecV1));
app.use('/api-docs/v2', swaggerUi.serveFiles(swaggerSpecV2), swaggerUi.setup(swaggerSpecV2));

// Redirect /api-docs to latest
app.get('/api-docs', (req, res) => {
    res.redirect('/api-docs/v2');
});

app.listen(3000);
```

### 40.5.2 - Swagger Annotations

**routes/v2/users.js con annotations:**

```javascript
const express = require('express');
const router = express.Router();

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - firstName
 *         - lastName
 *         - email
 *       properties:
 *         id:
 *           type: integer
 *           description: User ID
 *         firstName:
 *           type: string
 *           description: User's first name
 *         lastName:
 *           type: string
 *           description: User's last name
 *         email:
 *           type: string
 *           format: email
 *           description: User's email
 *       example:
 *         id: 1
 *         firstName: John
 *         lastName: Doe
 *         email: john@example.com
 */

/**
 * @swagger
 * /users:
 *   get:
 *     summary: Get all users
 *     tags: [Users]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page number
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Items per page
 *     responses:
 *       200:
 *         description: List of users
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 meta:
 *                   type: object
 *                   properties:
 *                     total:
 *                       type: integer
 *                     page:
 *                       type: integer
 *                     limit:
 *                       type: integer
 */
router.get('/', (req, res) => {
    const { page = 1, limit = 10 } = req.query;
    
    res.json({
        data: [
            { 
                id: 1, 
                firstName: 'John', 
                lastName: 'Doe', 
                email: 'john@example.com' 
            }
        ],
        meta: {
            total: 1,
            page: parseInt(page),
            limit: parseInt(limit)
        }
    });
});

/**
 * @swagger
 * /users/{id}:
 *   get:
 *     summary: Get user by ID
 *     tags: [Users]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: User ID
 *     responses:
 *       200:
 *         description: User details
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       404:
 *         description: User not found
 */
router.get('/:id', (req, res) => {
    res.json({
        data: { 
            id: req.params.id, 
            firstName: 'John', 
            lastName: 'Doe',
            email: 'john@example.com'
        }
    });
});

/**
 * @swagger
 * /users:
 *   post:
 *     summary: Create new user
 *     tags: [Users]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/User'
 *     responses:
 *       201:
 *         description: User created
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: Invalid input
 */
router.post('/', (req, res) => {
    res.status(201).json({
        data: { 
            id: 2, 
            ...req.body 
        }
    });
});

module.exports = router;
```

---

## 40.6 API Documentation Best Practices

### 40.6.1 - README Documentation

**API README.md:**

```markdown
# My API Documentation

## Base URL
```
http://localhost:3000/api
```

## Versioning

This API uses URI versioning. The current version is **v2**.

- V1: `/api/v1` (Deprecated - Sunset: Dec 31, 2025)
- V2: `/api/v2` (Current)

## Authentication

All requests require an API key in the header:

```
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### Users

#### Get All Users

```http
GET /api/v2/users
```

**Query Parameters:**
- `page` (integer, optional): Page number (default: 1)
- `limit` (integer, optional): Items per page (default: 10)

**Response:**
```json
{
  "data": [
    {
      "id": 1,
      "firstName": "John",
      "lastName": "Doe",
      "email": "john@example.com"
    }
  ],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 10
  }
}
```

#### Get User by ID

```http
GET /api/v2/users/:id
```

**Response:**
```json
{
  "data": {
    "id": 1,
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com"
  }
}
```

## Error Responses

All errors follow this format:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
```

## Rate Limiting

- 100 requests per 15 minutes per API key
- Rate limit info in headers:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Migration from V1 to V2

### Breaking Changes

1. **User object structure:**
   - V1: `name` → V2: `firstName` + `lastName`
   - V2 adds: `email` field

2. **Response format:**
   - V1: Direct array `{ users: [...] }`
   - V2: Wrapped in `data` with `meta`: `{ data: [...], meta: {...} }`

### Migration Example

**V1:**
```json
{
  "users": [
    { "id": 1, "name": "John Doe" }
  ]
}
```

**V2:**
```json
{
  "data": [
    { 
      "id": 1, 
      "firstName": "John", 
      "lastName": "Doe",
      "email": "john@example.com"
    }
  ],
  "meta": {
    "total": 1,
    "page": 1
  }
}
```
```

### 40.6.2 - Interactive Documentation

**Postman Collection:**

```json
{
  "info": {
    "name": "My API V2",
    "description": "Complete API documentation",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Users",
      "item": [
        {
          "name": "Get All Users",
          "request": {
            "method": "GET",
            "header": [
              {
                "key": "Authorization",
                "value": "Bearer {{api_key}}",
                "type": "text"
              }
            ],
            "url": {
              "raw": "{{base_url}}/api/v2/users?page=1&limit=10",
              "host": ["{{base_url}}"],
              "path": ["api", "v2", "users"],
              "query": [
                {
                  "key": "page",
                  "value": "1"
                },
                {
                  "key": "limit",
                  "value": "10"
                }
              ]
            }
          }
        }
      ]
    }
  ]
}
```

---

## 40.7 Complete Versioned API Example

### 40.7.1 - Production Setup

**Complete production API:**

```javascript
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const swaggerUi = require('swagger-ui-express');
const swaggerJsdoc = require('swagger-jsdoc');

const app = express();

// Middleware
app.use(helmet());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: 'Too many requests'
});
app.use('/api', limiter);

// Swagger V2 (current)
const swaggerSpec = swaggerJsdoc({
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'My API',
            version: '2.0.0',
            description: 'Production API with versioning'
        },
        servers: [
            {
                url: process.env.API_URL || 'http://localhost:3000/api/v2'
            }
        ]
    },
    apis: ['./routes/v2/*.js']
});

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// V1 Routes (deprecated)
const v1Router = express.Router();

v1Router.use((req, res, next) => {
    const sunsetDate = new Date('2026-03-31');
    const daysRemaining = Math.ceil((sunsetDate - new Date()) / (1000 * 60 * 60 * 24));
    
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', sunsetDate.toUTCString());
    res.setHeader('Link', '</api/v2>; rel="successor-version"');
    res.setHeader('Warning', `299 - "API v1 deprecated. ${daysRemaining} days until sunset"`);
    
    next();
});

v1Router.get('/users', (req, res) => {
    res.json({
        users: [{ id: 1, name: 'John Doe' }],
        _deprecation: {
            message: 'This endpoint is deprecated',
            sunset: '2026-03-31',
            migrate_to: '/api/v2/users'
        }
    });
});

// V2 Routes (current)
const v2Router = express.Router();

v2Router.get('/users', (req, res) => {
    const { page = 1, limit = 10 } = req.query;
    
    res.json({
        data: [
            { 
                id: 1, 
                firstName: 'John', 
                lastName: 'Doe',
                email: 'john@example.com'
            }
        ],
        meta: {
            total: 1,
            page: parseInt(page),
            limit: parseInt(limit)
        }
    });
});

v2Router.get('/users/:id', (req, res) => {
    res.json({
        data: { 
            id: req.params.id, 
            firstName: 'John', 
            lastName: 'Doe',
            email: 'john@example.com'
        }
    });
});

// Mount routers
app.use('/api/v1', v1Router);
app.use('/api/v2', v2Router);
app.use('/api', v2Router);  // Default to latest

// Health check
app.get('/health', (req, res) => {
    res.json({ 
        status: 'ok',
        version: '2.0.0',
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: {
            code: 'NOT_FOUND',
            message: 'Endpoint not found',
            path: req.path
        }
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({
        error: {
            code: 'INTERNAL_ERROR',
            message: 'Internal server error'
        }
    });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`API running on port ${PORT}`);
    console.log(`Documentation: http://localhost:${PORT}/api-docs`);
});
```

---

**Capitolo 40 completato!** 

Ho completato i **capitoli 39-40**:

✅ **Capitolo 39** - Security Headers (~1000 righe)
- HSTS (Strict-Transport-Security)
- X-Frame-Options (clickjacking prevention)
- X-Content-Type-Options (MIME sniffing)
- Referrer-Policy
- Permissions-Policy
- Cross-Origin headers (CORP, COEP, COOP)
- Complete production setup con Helmet e Nginx

✅ **Capitolo 40** - API Versioning & Documentation (~950 righe)
- URI versioning (path-based)
- Header versioning
- Content negotiation
- Deprecation strategy con Sunset header
- OpenAPI/Swagger documentation
- Migration best practices
- Complete production API example

Ora hai **40 capitoli completi** (80% del totale di 50 capitoli)! 🎉