# 21. RESTful API Design

## 21.1 Introduzione

**REST** (Representational State Transfer) è uno stile architetturale per API HTTP che usa risorse e metodi HTTP standard.

**Principi REST:**
- 📌 **Client-Server:** Separazione tra client e server
- 📌 **Stateless:** Ogni request è indipendente
- 📌 **Cacheable:** Response devono indicare se cacheable
- 📌 **Uniform Interface:** Interfaccia standard (HTTP methods, URIs)
- 📌 **Layered System:** Architettura a livelli
- 📌 **Code on Demand** (opzionale): Server può inviare codice eseguibile

**Vantaggi:**
- ✅ Semplicità e standardizzazione
- ✅ Scalabilità
- ✅ Indipendenza piattaforma
- ✅ Cache HTTP nativa
- ✅ Stateless (facile load balancing)

---

## 21.2 HTTP Methods (Verbs)

### 21.2.1 - CRUD Operations

**Mapping CRUD → HTTP:**

| Operation | HTTP Method | Idempotent | Safe |
|-----------|-------------|------------|------|
| **Create** | POST | ❌ No | ❌ No |
| **Read** | GET | ✅ Yes | ✅ Yes |
| **Update** | PUT/PATCH | ✅ Yes (PUT) | ❌ No |
| **Delete** | DELETE | ✅ Yes | ❌ No |

**Idempotent:** Chiamate multiple hanno stesso effetto di una singola chiamata  
**Safe:** Non modifica stato server

### 21.2.2 - GET: Retrieve Resources

**GET single resource:**

```http
GET /api/users/123 HTTP/1.1
Host: api.example.com
Accept: application/json
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json
Cache-Control: max-age=3600

{
  "id": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "created_at": "2024-01-15T10:30:00Z"
}
```

**GET collection:**

```http
GET /api/users HTTP/1.1
Host: api.example.com
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": [
    {
      "id": 123,
      "username": "john_doe",
      "email": "john@example.com"
    },
    {
      "id": 124,
      "username": "jane_smith",
      "email": "jane@example.com"
    }
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "per_page": 20
  }
}
```

**Express.js implementation:**

```javascript
const express = require('express');
const app = express();

// GET single user
app.get('/api/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        
        res.status(200).json(user);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET collection with pagination
app.get('/api/users', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const perPage = parseInt(req.query.per_page) || 20;
        const offset = (page - 1) * perPage;
        
        const users = await User.findAll({
            limit: perPage,
            offset: offset
        });
        
        const total = await User.count();
        
        res.status(200).json({
            data: users,
            meta: {
                total: total,
                page: page,
                per_page: perPage,
                total_pages: Math.ceil(total / perPage)
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(3000);
```

### 21.2.3 - POST: Create Resources

**POST request:**

```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json

{
  "username": "new_user",
  "email": "new@example.com",
  "password": "SecurePass123!"
}
```

**Response (201 Created):**

```http
HTTP/1.1 201 Created
Location: /api/users/125
Content-Type: application/json

{
  "id": 125,
  "username": "new_user",
  "email": "new@example.com",
  "created_at": "2024-10-30T14:25:00Z"
}
```

**Express.js:**

```javascript
const express = require('express');
const bcrypt = require('bcrypt');
const { body, validationResult } = require('express-validator');

const app = express();
app.use(express.json());

app.post('/api/users',
    // Validation
    body('username').isLength({ min: 3, max: 30 }).trim(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    
    async (req, res) => {
        // Check validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                error: 'Validation failed',
                details: errors.array()
            });
        }
        
        try {
            const { username, email, password } = req.body;
            
            // Check if user exists
            const existing = await User.findOne({ where: { email } });
            if (existing) {
                return res.status(409).json({
                    error: 'User already exists'
                });
            }
            
            // Hash password
            const passwordHash = await bcrypt.hash(password, 10);
            
            // Create user
            const user = await User.create({
                username,
                email,
                password_hash: passwordHash
            });
            
            // Response with Location header
            res.status(201)
               .location(`/api/users/${user.id}`)
               .json({
                   id: user.id,
                   username: user.username,
                   email: user.email,
                   created_at: user.created_at
               });
        } catch (err) {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

app.listen(3000);
```

### 21.2.4 - PUT: Full Update

**PUT replaces entire resource:**

```http
PUT /api/users/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{
  "username": "john_updated",
  "email": "john_new@example.com",
  "bio": "Software developer"
}
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "username": "john_updated",
  "email": "john_new@example.com",
  "bio": "Software developer",
  "updated_at": "2024-10-30T15:00:00Z"
}
```

**Express.js:**

```javascript
app.put('/api/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        
        // Full replacement
        await user.update({
            username: req.body.username,
            email: req.body.email,
            bio: req.body.bio
            // Altri campi vengono resettati se non presenti!
        });
        
        res.status(200).json(user);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

### 21.2.5 - PATCH: Partial Update

**PATCH updates only specified fields:**

```http
PATCH /api/users/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{
  "bio": "Updated bio only"
}
```

**Response:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "bio": "Updated bio only",
  "updated_at": "2024-10-30T15:10:00Z"
}
```

**Express.js:**

```javascript
app.patch('/api/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        
        // Partial update (solo campi forniti)
        const updates = {};
        if (req.body.username) updates.username = req.body.username;
        if (req.body.email) updates.email = req.body.email;
        if (req.body.bio !== undefined) updates.bio = req.body.bio;
        
        await user.update(updates);
        
        res.status(200).json(user);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

### 21.2.6 - DELETE: Remove Resources

**DELETE request:**

```http
DELETE /api/users/123 HTTP/1.1
Host: api.example.com
```

**Response (204 No Content):**

```http
HTTP/1.1 204 No Content
```

**Oppure 200 con conferma:**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "User deleted successfully",
  "id": 123
}
```

**Express.js:**

```javascript
app.delete('/api/users/:id', async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findById(userId);
        
        if (!user) {
            return res.status(404).json({
                error: 'User not found'
            });
        }
        
        await user.destroy();
        
        // 204 No Content (no body)
        res.status(204).send();
        
        // Oppure 200 con messaggio
        // res.status(200).json({
        //     message: 'User deleted successfully'
        // });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

---

## 21.3 Resource Naming Conventions

### 21.3.1 - URI Best Practices

**✅ GOOD:**

```
GET    /api/users              → Lista utenti
GET    /api/users/123          → Singolo utente
POST   /api/users              → Crea utente
PUT    /api/users/123          → Update completo
PATCH  /api/users/123          → Update parziale
DELETE /api/users/123          → Elimina utente

GET    /api/users/123/posts    → Post dell'utente 123
GET    /api/posts/456/comments → Commenti del post 456
```

**❌ BAD:**

```
GET    /api/getUsers              → Usa GET /api/users
POST   /api/createUser            → Usa POST /api/users
POST   /api/users/delete          → Usa DELETE /api/users/:id
GET    /api/user?id=123           → Usa GET /api/users/123
POST   /api/updateUser/123        → Usa PUT/PATCH /api/users/123
```

**Regole naming:**

```
✅ Usa nomi plurali: /users, /posts, /comments
✅ Lowercase: /api/users (non /api/Users)
✅ Usa - per separare parole: /api/blog-posts
❌ NO verbi nell'URI: /getUsers, /createPost
❌ NO underscore: /api/blog_posts
❌ NO trailing slash: /api/users/ (deve essere /api/users)
```

### 21.3.2 - Nested Resources

**Relationship representation:**

```http
# Post appartiene a user
GET /api/users/123/posts

# Comment appartiene a post
GET /api/posts/456/comments

# Specific comment
GET /api/posts/456/comments/789
```

**Express.js nested routes:**

```javascript
const express = require('express');
const app = express();

// User's posts
app.get('/api/users/:userId/posts', async (req, res) => {
    try {
        const userId = req.params.userId;
        const posts = await Post.findAll({
            where: { user_id: userId }
        });
        
        res.status(200).json({
            data: posts,
            meta: {
                user_id: userId,
                count: posts.length
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Post's comments
app.get('/api/posts/:postId/comments', async (req, res) => {
    try {
        const postId = req.params.postId;
        const comments = await Comment.findAll({
            where: { post_id: postId }
        });
        
        res.status(200).json({ data: comments });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Create comment for post
app.post('/api/posts/:postId/comments', async (req, res) => {
    try {
        const postId = req.params.postId;
        const { text, author_id } = req.body;
        
        const comment = await Comment.create({
            post_id: postId,
            text: text,
            author_id: author_id
        });
        
        res.status(201).json(comment);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.listen(3000);
```

**⚠️ Evita nesting profondo:**

```
❌ /api/users/123/posts/456/comments/789/likes
✅ /api/comments/789/likes
```

---

## 21.4 Query Parameters

### 21.4.1 - Filtering

**Filter by fields:**

```http
GET /api/users?status=active&role=admin
```

**Express.js:**

```javascript
app.get('/api/users', async (req, res) => {
    try {
        const filters = {};
        
        if (req.query.status) {
            filters.status = req.query.status;
        }
        
        if (req.query.role) {
            filters.role = req.query.role;
        }
        
        const users = await User.findAll({ where: filters });
        
        res.status(200).json({ data: users });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

**Multiple values:**

```http
GET /api/posts?tag=javascript&tag=nodejs&tag=express
```

```javascript
app.get('/api/posts', async (req, res) => {
    try {
        let tags = req.query.tag;
        
        // Converti a array se singolo valore
        if (typeof tags === 'string') {
            tags = [tags];
        }
        
        const posts = await Post.findAll({
            where: {
                tags: {
                    [Op.contains]: tags  // Sequelize operator
                }
            }
        });
        
        res.status(200).json({ data: posts });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

### 21.4.2 - Sorting

**Sort by field:**

```http
GET /api/users?sort=created_at
GET /api/users?sort=-created_at  (descending)
```

**Express.js:**

```javascript
app.get('/api/users', async (req, res) => {
    try {
        let order = [['created_at', 'ASC']];
        
        if (req.query.sort) {
            const sortField = req.query.sort.startsWith('-') 
                ? req.query.sort.substring(1) 
                : req.query.sort;
            
            const sortDirection = req.query.sort.startsWith('-') 
                ? 'DESC' 
                : 'ASC';
            
            order = [[sortField, sortDirection]];
        }
        
        const users = await User.findAll({ order });
        
        res.status(200).json({ data: users });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

**Multiple sort fields:**

```http
GET /api/users?sort=role,-created_at
```

### 21.4.3 - Pagination

**Offset-based pagination:**

```http
GET /api/users?page=2&per_page=20
```

**Express.js:**

```javascript
app.get('/api/users', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const perPage = parseInt(req.query.per_page) || 20;
        const offset = (page - 1) * perPage;
        
        const { count, rows } = await User.findAndCountAll({
            limit: perPage,
            offset: offset
        });
        
        res.status(200).json({
            data: rows,
            meta: {
                total: count,
                page: page,
                per_page: perPage,
                total_pages: Math.ceil(count / perPage)
            },
            links: {
                first: `/api/users?page=1&per_page=${perPage}`,
                last: `/api/users?page=${Math.ceil(count / perPage)}&per_page=${perPage}`,
                prev: page > 1 ? `/api/users?page=${page - 1}&per_page=${perPage}` : null,
                next: page < Math.ceil(count / perPage) ? `/api/users?page=${page + 1}&per_page=${perPage}` : null
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

**Cursor-based pagination (per dataset grandi):**

```http
GET /api/posts?cursor=eyJpZCI6MTIzfQ==&limit=20
```

```javascript
app.get('/api/posts', async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 20;
        let cursor = null;
        
        if (req.query.cursor) {
            // Decode base64 cursor
            const decoded = Buffer.from(req.query.cursor, 'base64').toString();
            cursor = JSON.parse(decoded);
        }
        
        const posts = await Post.findAll({
            where: cursor ? { id: { [Op.gt]: cursor.id } } : {},
            limit: limit + 1,  // +1 per verificare se ci sono altri
            order: [['id', 'ASC']]
        });
        
        const hasMore = posts.length > limit;
        const data = hasMore ? posts.slice(0, limit) : posts;
        
        const nextCursor = hasMore 
            ? Buffer.from(JSON.stringify({ id: data[data.length - 1].id })).toString('base64')
            : null;
        
        res.status(200).json({
            data: data,
            meta: {
                has_more: hasMore,
                next_cursor: nextCursor
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

### 21.4.4 - Field Selection

**Sparse fieldsets:**

```http
GET /api/users?fields=id,username,email
```

**Express.js:**

```javascript
app.get('/api/users', async (req, res) => {
    try {
        let attributes = undefined;
        
        if (req.query.fields) {
            attributes = req.query.fields.split(',');
        }
        
        const users = await User.findAll({ attributes });
        
        res.status(200).json({ data: users });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});
```

---

## 21.5 HTTP Status Codes

### 21.5.1 - Success Codes (2xx)

```
200 OK              → Request successful, response has body
201 Created         → Resource created (POST)
202 Accepted        → Request accepted, processing async
204 No Content      → Successful, no response body (DELETE)
206 Partial Content → Range request successful
```

**Esempi:**

```javascript
// 200 OK
app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    res.status(200).json(user);
});

// 201 Created
app.post('/api/users', async (req, res) => {
    const user = await User.create(req.body);
    res.status(201)
       .location(`/api/users/${user.id}`)
       .json(user);
});

// 202 Accepted
app.post('/api/reports/generate', async (req, res) => {
    const jobId = await queue.add('generate-report', req.body);
    res.status(202).json({
        message: 'Report generation started',
        job_id: jobId,
        status_url: `/api/jobs/${jobId}`
    });
});

// 204 No Content
app.delete('/api/users/:id', async (req, res) => {
    await User.destroy({ where: { id: req.params.id } });
    res.status(204).send();
});
```

### 21.5.2 - Client Error Codes (4xx)

```
400 Bad Request          → Invalid request syntax/parameters
401 Unauthorized         → Authentication required
403 Forbidden            → Authenticated but not authorized
404 Not Found            → Resource not found
405 Method Not Allowed   → HTTP method not supported
409 Conflict             → Resource conflict (duplicate)
422 Unprocessable Entity → Validation error
429 Too Many Requests    → Rate limit exceeded
```

**Esempi:**

```javascript
// 400 Bad Request
app.post('/api/users', async (req, res) => {
    if (!req.body.email || !req.body.password) {
        return res.status(400).json({
            error: 'Bad Request',
            message: 'Email and password are required'
        });
    }
});

// 401 Unauthorized
app.get('/api/profile', (req, res) => {
    if (!req.headers.authorization) {
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Authentication required'
        });
    }
});

// 403 Forbidden
app.delete('/api/users/:id', async (req, res) => {
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            error: 'Forbidden',
            message: 'Admin access required'
        });
    }
});

// 404 Not Found
app.get('/api/users/:id', async (req, res) => {
    const user = await User.findById(req.params.id);
    if (!user) {
        return res.status(404).json({
            error: 'Not Found',
            message: 'User not found'
        });
    }
});

// 409 Conflict
app.post('/api/users', async (req, res) => {
    const existing = await User.findOne({ where: { email: req.body.email } });
    if (existing) {
        return res.status(409).json({
            error: 'Conflict',
            message: 'User with this email already exists'
        });
    }
});

// 422 Unprocessable Entity
app.post('/api/users', async (req, res) => {
    const errors = validateUser(req.body);
    if (errors.length > 0) {
        return res.status(422).json({
            error: 'Validation failed',
            details: errors
        });
    }
});
```

### 21.5.3 - Server Error Codes (5xx)

```
500 Internal Server Error → Generic server error
502 Bad Gateway           → Invalid response from upstream
503 Service Unavailable   → Server temporarily unavailable
504 Gateway Timeout       → Upstream timeout
```

**Express.js error handling:**

```javascript
// Global error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    
    // Database connection error
    if (err.name === 'SequelizeConnectionError') {
        return res.status(503).json({
            error: 'Service Unavailable',
            message: 'Database temporarily unavailable'
        });
    }
    
    // Generic server error
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'production' 
            ? 'An unexpected error occurred' 
            : err.message
    });
});
```

---

## 21.6 Versioning

### 21.6.1 - URI Versioning

**Più comune e semplice:**

```http
GET /api/v1/users
GET /api/v2/users
```

**Express.js:**

```javascript
const express = require('express');
const app = express();

// V1 routes
const v1Router = express.Router();
v1Router.get('/users', (req, res) => {
    res.json({ version: 'v1', data: [] });
});
app.use('/api/v1', v1Router);

// V2 routes
const v2Router = express.Router();
v2Router.get('/users', (req, res) => {
    res.json({ 
        version: 'v2', 
        users: [],  // Campo rinominato
        meta: {}    // Nuovo campo
    });
});
app.use('/api/v2', v2Router);

app.listen(3000);
```

### 21.6.2 - Header Versioning

**Custom header:**

```http
GET /api/users HTTP/1.1
Host: api.example.com
X-API-Version: 2
```

**Accept header:**

```http
GET /api/users HTTP/1.1
Host: api.example.com
Accept: application/vnd.example.v2+json
```

**Express.js:**

```javascript
app.get('/api/users', (req, res) => {
    const version = req.header('X-API-Version') || '1';
    
    if (version === '1') {
        res.json({ data: [] });
    } else if (version === '2') {
        res.json({ users: [], meta: {} });
    } else {
        res.status(400).json({
            error: 'Unsupported API version'
        });
    }
});
```

**✅ URI versioning raccomandato per semplicità**

---

## 21.7 HATEOAS

### 21.7.1 - Hypermedia Links

**HATEOAS** (Hypermedia As The Engine Of Application State) include link per azioni disponibili.

**Esempio response con links:**

```json
{
  "id": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "links": {
    "self": "/api/users/123",
    "posts": "/api/users/123/posts",
    "edit": "/api/users/123",
    "delete": "/api/users/123"
  }
}
```

**Collection con pagination links:**

```json
{
  "data": [
    {
      "id": 123,
      "username": "john_doe"
    }
  ],
  "links": {
    "self": "/api/users?page=2",
    "first": "/api/users?page=1",
    "prev": "/api/users?page=1",
    "next": "/api/users?page=3",
    "last": "/api/users?page=10"
  },
  "meta": {
    "current_page": 2,
    "total_pages": 10,
    "total": 200
  }
}
```

**Express.js implementation:**

```javascript
app.get('/api/users/:id', async (req, res) => {
    const userId = req.params.id;
    const user = await User.findById(userId);
    
    if (!user) {
        return res.status(404).json({ error: 'Not found' });
    }
    
    res.json({
        id: user.id,
        username: user.username,
        email: user.email,
        links: {
            self: `/api/users/${user.id}`,
            posts: `/api/users/${user.id}/posts`,
            edit: `/api/users/${user.id}`,
            delete: `/api/users/${user.id}`
        }
    });
});
```

---

## 21.8 Complete RESTful API Example

**Full Express.js API:**

```javascript
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { body, validationResult } = require('express-validator');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100
});
app.use('/api/', limiter);

// GET collection
app.get('/api/v1/users', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const perPage = parseInt(req.query.per_page) || 20;
        const offset = (page - 1) * perPage;
        
        // Filters
        const filters = {};
        if (req.query.status) filters.status = req.query.status;
        if (req.query.role) filters.role = req.query.role;
        
        // Sort
        let order = [['created_at', 'DESC']];
        if (req.query.sort) {
            const sortField = req.query.sort.replace('-', '');
            const sortDir = req.query.sort.startsWith('-') ? 'DESC' : 'ASC';
            order = [[sortField, sortDir]];
        }
        
        const { count, rows } = await User.findAndCountAll({
            where: filters,
            limit: perPage,
            offset: offset,
            order: order
        });
        
        res.status(200).json({
            data: rows,
            meta: {
                total: count,
                page: page,
                per_page: perPage,
                total_pages: Math.ceil(count / perPage)
            },
            links: {
                self: `/api/v1/users?page=${page}&per_page=${perPage}`,
                first: `/api/v1/users?page=1&per_page=${perPage}`,
                last: `/api/v1/users?page=${Math.ceil(count / perPage)}&per_page=${perPage}`,
                prev: page > 1 ? `/api/v1/users?page=${page - 1}&per_page=${perPage}` : null,
                next: page < Math.ceil(count / perPage) ? `/api/v1/users?page=${page + 1}&per_page=${perPage}` : null
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// GET single resource
app.get('/api/v1/users/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        
        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'User not found'
            });
        }
        
        res.status(200).json({
            id: user.id,
            username: user.username,
            email: user.email,
            created_at: user.created_at,
            links: {
                self: `/api/v1/users/${user.id}`,
                posts: `/api/v1/users/${user.id}/posts`,
                update: `/api/v1/users/${user.id}`,
                delete: `/api/v1/users/${user.id}`
            }
        });
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// POST create resource
app.post('/api/v1/users',
    body('username').isLength({ min: 3, max: 30 }).trim(),
    body('email').isEmail().normalizeEmail(),
    body('password').isLength({ min: 8 }),
    
    async (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(422).json({
                error: 'Validation failed',
                details: errors.array()
            });
        }
        
        try {
            const { username, email, password } = req.body;
            
            const existing = await User.findOne({ where: { email } });
            if (existing) {
                return res.status(409).json({
                    error: 'Conflict',
                    message: 'User already exists'
                });
            }
            
            const user = await User.create({
                username,
                email,
                password_hash: await bcrypt.hash(password, 10)
            });
            
            res.status(201)
               .location(`/api/v1/users/${user.id}`)
               .json({
                   id: user.id,
                   username: user.username,
                   email: user.email,
                   created_at: user.created_at,
                   links: {
                       self: `/api/v1/users/${user.id}`
                   }
               });
        } catch (err) {
            res.status(500).json({ error: 'Internal server error' });
        }
    }
);

// PATCH partial update
app.patch('/api/v1/users/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        
        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'User not found'
            });
        }
        
        const updates = {};
        if (req.body.username) updates.username = req.body.username;
        if (req.body.email) updates.email = req.body.email;
        if (req.body.bio !== undefined) updates.bio = req.body.bio;
        
        await user.update(updates);
        
        res.status(200).json(user);
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// DELETE resource
app.delete('/api/v1/users/:id', async (req, res) => {
    try {
        const user = await User.findById(req.params.id);
        
        if (!user) {
            return res.status(404).json({
                error: 'Not Found',
                message: 'User not found'
            });
        }
        
        await user.destroy();
        
        res.status(204).send();
    } catch (err) {
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Error handler
app.use((err, req, res, next) => {
    console.error(err);
    res.status(500).json({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'production' 
            ? 'An unexpected error occurred' 
            : err.message
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: 'Endpoint not found'
    });
});

app.listen(3000, () => {
    console.log('API server running on port 3000');
});
```

---

**Capitolo 21 completato!**

Prossimo: **Capitolo 22 - GraphQL vs REST**
