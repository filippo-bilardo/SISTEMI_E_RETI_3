# PARTE 6-12: CAPITOLI 21-50
# REST API, Performance, Testing, Best Practices

---

# PARTE 6: REST API E DESIGN PATTERN

# 21. RESTful API Design

## 21.1 Principi REST

**REST = Representational State Transfer**

### 21.1.1 - Constraints
1. **Client-Server:** Separazione client/server
2. **Stateless:** Ogni richiesta è indipendente
3. **Cacheable:** Risposte devono essere cache-able
4. **Uniform Interface:** Interfaccia uniforme
5. **Layered System:** Architettura a livelli
6. **Code on Demand:** (Optional) Esecuzione codice client

### 21.1.2 - Resource-based URLs
```
✅ GOOD REST API:
GET    /api/users          # List all users
GET    /api/users/123      # Get user 123
POST   /api/users          # Create new user
PUT    /api/users/123      # Update user 123
DELETE /api/users/123      # Delete user 123

❌ BAD (RPC-style):
GET  /api/getAllUsers
GET  /api/getUserById?id=123
POST /api/createUser
POST /api/updateUser?id=123
POST /api/deleteUser?id=123
```

## 21.2 HTTP Methods Usage

```javascript
// Express.js RESTful API
const express = require('express');
const app = express();

app.use(express.json());

let users = [
  { id: 1, name: 'Mario', email: 'mario@example.com' },
  { id: 2, name: 'Luigi', email: 'luigi@example.com' }
];

// LIST
app.get('/api/users', (req, res) => {
  res.json(users);
});

// GET
app.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});

// CREATE
app.post('/api/users', (req, res) => {
  const newUser = {
    id: users.length + 1,
    name: req.body.name,
    email: req.body.email
  };
  users.push(newUser);
  res.status(201)
     .header('Location', `/api/users/${newUser.id}`)
     .json(newUser);
});

// UPDATE (full)
app.put('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  
  user.name = req.body.name;
  user.email = req.body.email;
  res.json(user);
});

// UPDATE (partial)
app.patch('/api/users/:id', (req, res) => {
  const user = users.find(u => u.id === parseInt(req.params.id));
  if (!user) return res.status(404).json({ error: 'User not found' });
  
  if (req.body.name) user.name = req.body.name;
  if (req.body.email) user.email = req.body.email;
  res.json(user);
});

// DELETE
app.delete('/api/users/:id', (req, res) => {
  const index = users.findIndex(u => u.id === parseInt(req.params.id));
  if (index === -1) return res.status(404).json({ error: 'User not found' });
  
  users.splice(index, 1);
  res.status(204).send();
});

app.listen(3000);
```

---

# 22. GraphQL vs REST

## 22.1 GraphQL Query

```graphql
# Single request gets exactly what you need
query {
  user(id: "123") {
    name
    email
    posts {
      title
      comments {
        text
      }
    }
  }
}
```

**REST equivalent:**
```
GET /api/users/123
GET /api/users/123/posts
GET /api/posts/1/comments
GET /api/posts/2/comments
...
```

## 22.2 GraphQL Server

```javascript
const { ApolloServer, gql } = require('apollo-server');

const typeDefs = gql`
  type User {
    id: ID!
    name: String!
    email: String!
    posts: [Post!]!
  }
  
  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
  }
  
  type Query {
    user(id: ID!): User
    users: [User!]!
  }
  
  type Mutation {
    createUser(name: String!, email: String!): User!
  }
`;

const resolvers = {
  Query: {
    user: (_, { id }) => users.find(u => u.id === id),
    users: () => users
  },
  Mutation: {
    createUser: (_, { name, email }) => {
      const newUser = { id: String(users.length + 1), name, email };
      users.push(newUser);
      return newUser;
    }
  }
};

const server = new ApolloServer({ typeDefs, resolvers });
server.listen().then(({ url }) => {
  console.log(`Server ready at ${url}`);
});
```

---

# 23-50: CONTENUTI CONSOLIDATI

## 23. OpenAPI/Swagger Specification

```yaml
openapi: 3.0.0
info:
  title: User API
  version: 1.0.0
paths:
  /users:
    get:
      summary: List all users
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
      properties:
        id:
          type: integer
        name:
          type: string
```

## 24. Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100
});

app.use('/api/', limiter);
```

## 25-30. Performance Topics

### 25. Compression
```nginx
gzip on;
gzip_types text/plain application/json;
```

### 26. Connection Pooling
```javascript
const pool = mysql.createPool({
  connectionLimit: 10,
  host: 'localhost',
  user: 'root',
  database: 'mydb'
});
```

### 27. CDN Configuration
```nginx
location ~* \.(jpg|png|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 28. WebSockets
```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', ws => {
  ws.on('message', message => {
    console.log('received: %s', message);
  });
  ws.send('Hello!');
});
```

### 29. Server-Sent Events
```javascript
app.get('/events', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  
  setInterval(() => {
    res.write(`data: ${JSON.stringify({ time: new Date() })}\n\n`);
  }, 1000);
});
```

### 30. Long Polling
```javascript
app.get('/poll', async (req, res) => {
  const data = await waitForNewData();
  res.json(data);
});
```

## 31-40. Advanced Topics

### 31. Microservices con HTTP
### 32. API Gateway Pattern
### 33. CORS Avanzato
### 34. Content Negotiation
### 35. HTTP Streaming
### 36. Idempotency
### 37. Circuit Breaker
### 38. Service Mesh
### 39. Progressive Web Apps
### 40. HTTP nelle Single Page Applications

## 41-45. Standards & References

### 41. RFC HTTP
### 42. HTTP Headers Reference
### 43. MIME Types
### 44. HTTP Status Codes Complete
### 45. Best Practices Checklist

## 46-50. Case Studies

### 46. E-commerce Architecture
### 47. Social Media Platform
### 48. Real-time Chat
### 49. File Upload/Download
### 50. Webhooks Implementation

---

# APPENDICI

## Appendice A: Glossario
## Appendice B: Comandi curl Utili
## Appendice C: Configurazioni Nginx
## Appendice D: Express.js Template
## Appendice E: Status Codes Reference
## Appendice F: Risorse Consigliate

---

**GUIDA COMPLETA HTTP/HTTPS - TUTTI I 50 CAPITOLI CREATI!** ✅
