# 23. API Documentation (OpenAPI/Swagger)

## 23.1 Introduzione

**OpenAPI** (ex Swagger) è una specifica standard per documentare REST API.

**Vantaggi:**
- ✅ **Documentazione interattiva** (Swagger UI)
- ✅ **Client code generation** (SDK automatici)
- ✅ **Server code generation** (stub/mock servers)
- ✅ **Validation** (request/response conformi a spec)
- ✅ **Testing** automatico
- ✅ **Standardizzazione** tra team

**OpenAPI Specification versions:**
- OpenAPI 3.1 (latest, 2021)
- OpenAPI 3.0 (2017)
- Swagger 2.0 (legacy, 2014)

---

## 23.2 OpenAPI Specification Basics

### 23.2.1 - Basic Structure

**openapi.yaml (minimal):**

```yaml
openapi: 3.0.0

info:
  title: User API
  description: REST API for user management
  version: 1.0.0
  contact:
    name: API Support
    email: support@example.com
  license:
    name: MIT

servers:
  - url: https://api.example.com/v1
    description: Production server
  - url: https://staging-api.example.com/v1
    description: Staging server
  - url: http://localhost:3000/v1
    description: Development server

paths:
  /users:
    get:
      summary: Get all users
      description: Returns a list of users
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'

components:
  schemas:
    User:
      type: object
      required:
        - id
        - username
        - email
      properties:
        id:
          type: integer
          example: 123
        username:
          type: string
          example: john_doe
        email:
          type: string
          format: email
          example: john@example.com
```

### 23.2.2 - Path Operations

**Complete CRUD endpoints:**

```yaml
paths:
  /users:
    get:
      summary: List users
      tags:
        - Users
      parameters:
        - name: page
          in: query
          description: Page number
          required: false
          schema:
            type: integer
            default: 1
        - name: per_page
          in: query
          description: Items per page
          required: false
          schema:
            type: integer
            default: 20
            maximum: 100
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      $ref: '#/components/schemas/User'
                  meta:
                    $ref: '#/components/schemas/Pagination'
    
    post:
      summary: Create user
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
      responses:
        '201':
          description: User created
          headers:
            Location:
              schema:
                type: string
              description: URI of created user
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          $ref: '#/components/responses/Conflict'

  /users/{id}:
    parameters:
      - name: id
        in: path
        required: true
        description: User ID
        schema:
          type: integer
    
    get:
      summary: Get user by ID
      tags:
        - Users
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
    
    patch:
      summary: Update user
      tags:
        - Users
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/UpdateUserRequest'
      responses:
        '200':
          description: User updated
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          $ref: '#/components/responses/NotFound'
    
    delete:
      summary: Delete user
      tags:
        - Users
      responses:
        '204':
          description: User deleted
        '404':
          $ref: '#/components/responses/NotFound'
```

### 23.2.3 - Schemas

**Reusable schemas:**

```yaml
components:
  schemas:
    User:
      type: object
      required:
        - id
        - username
        - email
      properties:
        id:
          type: integer
          readOnly: true
          example: 123
        username:
          type: string
          minLength: 3
          maxLength: 30
          pattern: '^[a-zA-Z0-9_]+$'
          example: john_doe
        email:
          type: string
          format: email
          example: john@example.com
        bio:
          type: string
          maxLength: 500
          nullable: true
          example: Software developer
        avatar_url:
          type: string
          format: uri
          nullable: true
          example: https://example.com/avatars/123.jpg
        status:
          type: string
          enum:
            - active
            - inactive
            - suspended
          default: active
        created_at:
          type: string
          format: date-time
          readOnly: true
          example: '2024-01-15T10:30:00Z'
    
    CreateUserRequest:
      type: object
      required:
        - username
        - email
        - password
      properties:
        username:
          type: string
          minLength: 3
          maxLength: 30
        email:
          type: string
          format: email
        password:
          type: string
          format: password
          minLength: 8
    
    UpdateUserRequest:
      type: object
      properties:
        username:
          type: string
          minLength: 3
          maxLength: 30
        email:
          type: string
          format: email
        bio:
          type: string
          maxLength: 500
    
    Pagination:
      type: object
      properties:
        total:
          type: integer
          example: 150
        page:
          type: integer
          example: 1
        per_page:
          type: integer
          example: 20
        total_pages:
          type: integer
          example: 8
    
    Error:
      type: object
      required:
        - error
        - message
      properties:
        error:
          type: string
          example: Bad Request
        message:
          type: string
          example: Validation failed
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string
```

### 23.2.4 - Reusable Responses

**Common error responses:**

```yaml
components:
  responses:
    BadRequest:
      description: Bad Request
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Bad Request
            message: Invalid request parameters
    
    Unauthorized:
      description: Unauthorized
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Unauthorized
            message: Authentication required
    
    Forbidden:
      description: Forbidden
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Forbidden
            message: Insufficient permissions
    
    NotFound:
      description: Not Found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Not Found
            message: Resource not found
    
    Conflict:
      description: Conflict
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Conflict
            message: Resource already exists
    
    InternalServerError:
      description: Internal Server Error
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: Internal Server Error
            message: An unexpected error occurred
```

---

## 23.3 Authentication & Security

### 23.3.1 - Security Schemes

**Bearer JWT:**

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT token in Authorization header

security:
  - BearerAuth: []

paths:
  /users/me:
    get:
      summary: Get current user
      security:
        - BearerAuth: []
      responses:
        '200':
          description: Success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '401':
          $ref: '#/components/responses/Unauthorized'
```

**API Key:**

```yaml
components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API key in custom header
```

**OAuth2:**

```yaml
components:
  securitySchemes:
    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://example.com/oauth/authorize
          tokenUrl: https://example.com/oauth/token
          scopes:
            read:users: Read user information
            write:users: Modify user information
            admin: Admin access

paths:
  /admin/users:
    get:
      summary: Admin user list
      security:
        - OAuth2:
            - admin
      responses:
        '200':
          description: Success
```

**Multiple security schemes:**

```yaml
security:
  - BearerAuth: []
  - ApiKeyAuth: []
  # Client può usare JWT OR API Key
```

---

## 23.4 Swagger UI

### 23.4.1 - Setup Swagger UI (Express.js)

**Installation:**

```bash
npm install swagger-ui-express yamljs
```

**Server setup:**

```javascript
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');

const app = express();

// Load OpenAPI spec
const swaggerDocument = YAML.load('./openapi.yaml');

// Swagger UI
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'User API Documentation'
}));

// API routes
app.get('/v1/users', (req, res) => {
  res.json({ data: [] });
});

app.listen(3000, () => {
  console.log('API running on http://localhost:3000');
  console.log('Swagger UI: http://localhost:3000/api-docs');
});
```

**Access Swagger UI:**

```
http://localhost:3000/api-docs
```

**Features:**
- 🔵 Interactive API testing
- 🔵 "Try it out" per ogni endpoint
- 🔵 Authentication testing
- 🔵 Request/response examples
- 🔵 Schema visualization

### 23.4.2 - Generate Spec from Code

**swagger-jsdoc (annotations in code):**

```bash
npm install swagger-jsdoc
```

**Express.js with JSDoc:**

```javascript
const express = require('express');
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');

const app = express();
app.use(express.json());

const swaggerOptions = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'User API',
      version: '1.0.0',
      description: 'User management API'
    },
    servers: [
      {
        url: 'http://localhost:3000/v1'
      }
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT'
        }
      }
    },
    security: [
      {
        BearerAuth: []
      }
    ]
  },
  apis: ['./routes/*.js']  // Files con annotations
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - id
 *         - username
 *         - email
 *       properties:
 *         id:
 *           type: integer
 *           example: 123
 *         username:
 *           type: string
 *           example: john_doe
 *         email:
 *           type: string
 *           format: email
 *           example: john@example.com
 */

/**
 * @swagger
 * /v1/users:
 *   get:
 *     summary: Get all users
 *     tags:
 *       - Users
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 */
app.get('/v1/users', async (req, res) => {
  const users = await User.findAll();
  res.json({ data: users });
});

/**
 * @swagger
 * /v1/users/{id}:
 *   get:
 *     summary: Get user by ID
 *     tags:
 *       - Users
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Success
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 *       404:
 *         description: User not found
 */
app.get('/v1/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  
  if (!user) {
    return res.status(404).json({ error: 'Not found' });
  }
  
  res.json(user);
});

/**
 * @swagger
 * /v1/users:
 *   post:
 *     summary: Create user
 *     tags:
 *       - Users
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - username
 *               - email
 *               - password
 *             properties:
 *               username:
 *                 type: string
 *               email:
 *                 type: string
 *                 format: email
 *               password:
 *                 type: string
 *                 format: password
 *     responses:
 *       201:
 *         description: User created
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/User'
 */
app.post('/v1/users', async (req, res) => {
  const { username, email, password } = req.body;
  
  const user = await User.create({
    username,
    email,
    password_hash: await bcrypt.hash(password, 10)
  });
  
  res.status(201)
     .location(`/v1/users/${user.id}`)
     .json(user);
});

app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
  console.log('API docs: http://localhost:3000/api-docs');
});
```

---

## 23.5 Code Generation

### 23.5.1 - Client SDK Generation

**OpenAPI Generator:**

```bash
# Install
npm install @openapitools/openapi-generator-cli -g

# Generate JavaScript client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g javascript \
  -o ./clients/javascript

# Generate Python client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g python \
  -o ./clients/python

# Generate Java client
openapi-generator-cli generate \
  -i openapi.yaml \
  -g java \
  -o ./clients/java
```

**Usage (generated JavaScript client):**

```javascript
const UserApi = require('./clients/javascript');

const apiClient = new UserApi.ApiClient();
apiClient.basePath = 'https://api.example.com/v1';

const api = new UserApi.UsersApi(apiClient);

// Get all users
api.getUsers({ page: 1, perPage: 20 }, (error, data, response) => {
  if (error) {
    console.error(error);
  } else {
    console.log('Users:', data);
  }
});

// Get user by ID
api.getUserById(123, (error, data, response) => {
  if (error) {
    console.error(error);
  } else {
    console.log('User:', data);
  }
});

// Create user
const newUser = {
  username: 'new_user',
  email: 'new@example.com',
  password: 'SecurePass123!'
};

api.createUser(newUser, (error, data, response) => {
  if (error) {
    console.error(error);
  } else {
    console.log('Created user:', data);
  }
});
```

### 23.5.2 - Server Stub Generation

**Generate Express.js server stub:**

```bash
openapi-generator-cli generate \
  -i openapi.yaml \
  -g nodejs-express-server \
  -o ./server-stub
```

**Generated structure:**

```
server-stub/
├── api/
│   └── openapi.yaml
├── controllers/
│   └── Users.js
├── services/
│   └── UsersService.js
├── utils/
│   └── openapiRouter.js
├── index.js
└── package.json
```

**Generated controller (controllers/Users.js):**

```javascript
const UsersService = require('../services/UsersService');

module.exports.getUsers = async (req, res, next) => {
  try {
    const { page, perPage } = req.query;
    const response = await UsersService.getUsers(page, perPage);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

module.exports.getUserById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const response = await UsersService.getUserById(id);
    res.status(200).json(response);
  } catch (error) {
    next(error);
  }
};

module.exports.createUser = async (req, res, next) => {
  try {
    const response = await UsersService.createUser(req.body);
    res.status(201).json(response);
  } catch (error) {
    next(error);
  }
};
```

**Implement business logic (services/UsersService.js):**

```javascript
const User = require('../models/User');

module.exports.getUsers = async (page = 1, perPage = 20) => {
  const offset = (page - 1) * perPage;
  
  const { count, rows } = await User.findAndCountAll({
    limit: perPage,
    offset: offset
  });
  
  return {
    data: rows,
    meta: {
      total: count,
      page: page,
      per_page: perPage,
      total_pages: Math.ceil(count / perPage)
    }
  };
};

module.exports.getUserById = async (id) => {
  const user = await User.findById(id);
  
  if (!user) {
    const error = new Error('User not found');
    error.status = 404;
    throw error;
  }
  
  return user;
};

module.exports.createUser = async (userData) => {
  const { username, email, password } = userData;
  
  const existing = await User.findOne({ where: { email } });
  if (existing) {
    const error = new Error('User already exists');
    error.status = 409;
    throw error;
  }
  
  const user = await User.create({
    username,
    email,
    password_hash: await bcrypt.hash(password, 10)
  });
  
  return user;
};
```

---

## 23.6 Validation

### 23.6.1 - Request Validation

**express-openapi-validator:**

```bash
npm install express-openapi-validator
```

**Automatic validation:**

```javascript
const express = require('express');
const OpenApiValidator = require('express-openapi-validator');

const app = express();
app.use(express.json());

// OpenAPI validation middleware
app.use(
  OpenApiValidator.middleware({
    apiSpec: './openapi.yaml',
    validateRequests: true,   // Valida requests
    validateResponses: true,  // Valida responses
  })
);

// Routes
app.get('/v1/users', async (req, res) => {
  // req.query già validato contro openapi.yaml!
  const users = await User.findAll();
  res.json({ data: users });
});

app.post('/v1/users', async (req, res) => {
  // req.body già validato contro schema!
  const user = await User.create(req.body);
  res.status(201).json(user);
});

// Error handler per validation errors
app.use((err, req, res, next) => {
  if (err.status === 400) {
    // Validation error
    return res.status(400).json({
      error: 'Validation failed',
      details: err.errors
    });
  }
  
  res.status(err.status || 500).json({
    error: err.message
  });
});

app.listen(3000);
```

**Invalid request example:**

```http
POST /v1/users HTTP/1.1
Content-Type: application/json

{
  "username": "ab",
  "email": "invalid-email"
}
```

**Automatic validation error response:**

```json
{
  "error": "Validation failed",
  "details": [
    {
      "path": ".body.username",
      "message": "should NOT be shorter than 3 characters"
    },
    {
      "path": ".body.email",
      "message": "should match format \"email\""
    },
    {
      "path": ".body",
      "message": "should have required property 'password'"
    }
  ]
}
```

### 23.6.2 - Response Validation

**Validate responses match schema:**

```javascript
app.use(
  OpenApiValidator.middleware({
    apiSpec: './openapi.yaml',
    validateResponses: true
  })
);

app.get('/v1/users/:id', async (req, res) => {
  const user = await User.findById(req.params.id);
  
  // ❌ Questo causerà errore se schema richiede "id" field
  res.json({
    username: user.username,
    email: user.email
    // Missing "id" field!
  });
});

// Validator catches schema mismatch
// Error: response should have required property 'id'
```

---

## 23.7 Testing with OpenAPI

### 23.7.1 - Contract Testing

**Dredd (API testing tool):**

```bash
npm install -g dredd
```

**Test API against OpenAPI spec:**

```bash
dredd openapi.yaml http://localhost:3000
```

**Dredd output:**

```
pass: GET /v1/users duration: 150ms
pass: POST /v1/users duration: 80ms
pass: GET /v1/users/123 duration: 65ms
fail: PATCH /v1/users/123 duration: 120ms
  headers: Status code is 500 instead of 200
  
4 passing, 1 failing, 0 errors, 0 skipped
```

**Dredd hooks (custom logic):**

```javascript
// hooks.js
const hooks = require('hooks');

hooks.before('Users > Create user', (transaction) => {
  // Modify request before sending
  transaction.request.body = JSON.stringify({
    username: 'test_user',
    email: 'test@example.com',
    password: 'TestPass123!'
  });
});

hooks.after('Users > Get user by ID', (transaction) => {
  // Validate response
  const response = JSON.parse(transaction.real.body);
  if (response.username !== 'test_user') {
    transaction.fail('Username mismatch');
  }
});
```

**Run with hooks:**

```bash
dredd openapi.yaml http://localhost:3000 --hookfiles=hooks.js
```

---

## 23.8 Best Practices

### 23.8.1 - Documentation Guidelines

**✅ DO:**

```yaml
# Clear, concise descriptions
/users/{id}:
  get:
    summary: Get user by ID
    description: |
      Retrieves a single user by their unique ID.
      Returns 404 if user does not exist.
    parameters:
      - name: id
        in: path
        required: true
        description: Unique user identifier
        schema:
          type: integer
          minimum: 1
        example: 123

# Include examples
components:
  schemas:
    User:
      properties:
        username:
          type: string
          example: john_doe
        email:
          type: string
          format: email
          example: john@example.com
```

**❌ DON'T:**

```yaml
# Vague descriptions
/users/{id}:
  get:
    summary: Get user
    # Missing description
    parameters:
      - name: id
        in: path
        required: true
        # Missing description
        schema:
          type: integer
        # Missing example

# No examples
components:
  schemas:
    User:
      properties:
        username:
          type: string
          # Missing example
```

### 23.8.2 - Versioning Strategy

**Option 1: Separate spec per version:**

```
/docs/
  ├── openapi-v1.yaml
  ├── openapi-v2.yaml
  └── openapi-v3.yaml
```

**Option 2: Single spec with all versions:**

```yaml
paths:
  /v1/users:
    get:
      summary: List users (v1)
      deprecated: true
  
  /v2/users:
    get:
      summary: List users (v2)
```

**Option 3: Header versioning:**

```yaml
paths:
  /users:
    get:
      summary: List users
      parameters:
        - name: X-API-Version
          in: header
          schema:
            type: string
            enum: ['1', '2', '3']
            default: '3'
```

---

**Capitolo 23 completato!**

Capitoli 21-23 ora disponibili con documentazione dettagliata su:
- **Capitolo 21:** RESTful API Design completo
- **Capitolo 22:** GraphQL vs REST comparison
- **Capitolo 23:** OpenAPI/Swagger documentation
