# 22. GraphQL vs REST

## 22.1 Introduzione

**GraphQL** è un query language per API sviluppato da Facebook (2015), alternativa a REST.

**Differenze chiave:**

| Aspetto | REST | GraphQL |
|---------|------|---------|
| **Endpoint** | Multipli (`/users`, `/posts`) | Singolo (`/graphql`) |
| **Data fetching** | Over-fetching / Under-fetching | Esattamente i dati richiesti |
| **Versioning** | URI versioning (`/v1`, `/v2`) | Schema evolution (no versioning) |
| **HTTP Methods** | GET, POST, PUT, DELETE | POST (principalmente) |
| **Caching** | HTTP caching nativo | Richiede caching custom |
| **Learning curve** | Basso | Medio-alto |

---

## 22.2 REST Problems

### 22.2.1 - Over-fetching

**Problema: REST ritorna più dati del necessario**

**REST API:**

```http
GET /api/users/123 HTTP/1.1
```

**Response:**

```json
{
  "id": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "bio": "Software developer",
  "avatar_url": "https://...",
  "phone": "+1234567890",
  "address": {
    "street": "123 Main St",
    "city": "New York",
    "country": "USA"
  },
  "preferences": {
    "theme": "dark",
    "language": "en",
    "notifications": true
  },
  "created_at": "2023-01-15T10:30:00Z",
  "updated_at": "2024-10-20T14:22:00Z",
  "last_login": "2024-10-30T09:15:00Z"
}
```

**Client needs only:**
```json
{
  "username": "john_doe",
  "avatar_url": "https://..."
}
```

**❌ Over-fetching:** 80% dei dati inutilizzati, spreco bandwidth!

### 22.2.2 - Under-fetching

**Problema: REST richiede multiple request**

**Scenario: Dashboard mostra user + posts + comments**

**REST richiede 3 requests:**

```http
# Request 1: Get user
GET /api/users/123

# Request 2: Get user's posts
GET /api/users/123/posts

# Request 3: Get comments for each post
GET /api/posts/456/comments
GET /api/posts/457/comments
...
```

**❌ N+1 query problem:** Troppe roundtrip HTTP!

### 22.2.3 - Versioning

**REST API evolution:**

```
/api/v1/users → { id, name, email }
/api/v2/users → { id, username, email, avatar }  (field renamed)
```

**❌ Problema:** Mantenere V1 e V2 simultaneamente

---

## 22.3 GraphQL Basics

### 22.3.1 - Schema Definition

**GraphQL schema (Type system):**

```graphql
# schema.graphql

type User {
  id: ID!
  username: String!
  email: String!
  bio: String
  avatar_url: String
  posts: [Post!]!
  created_at: String!
}

type Post {
  id: ID!
  title: String!
  content: String!
  author: User!
  comments: [Comment!]!
  published_at: String!
}

type Comment {
  id: ID!
  text: String!
  author: User!
  post: Post!
  created_at: String!
}

type Query {
  user(id: ID!): User
  users(limit: Int, offset: Int): [User!]!
  post(id: ID!): Post
  posts(author_id: ID): [Post!]!
}

type Mutation {
  createUser(username: String!, email: String!, password: String!): User!
  updateUser(id: ID!, username: String, bio: String): User!
  deleteUser(id: ID!): Boolean!
  
  createPost(title: String!, content: String!, author_id: ID!): Post!
}

type Subscription {
  newPost: Post!
  newComment(post_id: ID!): Comment!
}
```

**Tipi base:**
- **Scalar types:** `String`, `Int`, `Float`, `Boolean`, `ID`
- **Object types:** Custom types (`User`, `Post`)
- **`!`:** Non-nullable field
- **`[Type!]!`:** Non-nullable array of non-nullable items

### 22.3.2 - Queries

**GraphQL query (client):**

```graphql
query GetUser {
  user(id: "123") {
    username
    avatar_url
  }
}
```

**Response (solo campi richiesti!):**

```json
{
  "data": {
    "user": {
      "username": "john_doe",
      "avatar_url": "https://..."
    }
  }
}
```

**✅ No over-fetching!**

**Nested query (risolve under-fetching):**

```graphql
query GetUserWithPosts {
  user(id: "123") {
    username
    avatar_url
    posts {
      title
      published_at
      comments {
        text
        author {
          username
        }
      }
    }
  }
}
```

**Response:**

```json
{
  "data": {
    "user": {
      "username": "john_doe",
      "avatar_url": "https://...",
      "posts": [
        {
          "title": "GraphQL Introduction",
          "published_at": "2024-10-25T10:00:00Z",
          "comments": [
            {
              "text": "Great post!",
              "author": {
                "username": "jane_smith"
              }
            }
          ]
        }
      ]
    }
  }
}
```

**✅ Single request per tutti i dati!**

### 22.3.3 - Mutations

**Create resource:**

```graphql
mutation CreateUser {
  createUser(
    username: "new_user"
    email: "new@example.com"
    password: "SecurePass123!"
  ) {
    id
    username
    email
    created_at
  }
}
```

**Response:**

```json
{
  "data": {
    "createUser": {
      "id": "124",
      "username": "new_user",
      "email": "new@example.com",
      "created_at": "2024-10-30T15:30:00Z"
    }
  }
}
```

**Update resource:**

```graphql
mutation UpdateUser {
  updateUser(
    id: "123"
    bio: "Updated bio"
  ) {
    id
    username
    bio
  }
}
```

### 22.3.4 - Subscriptions

**Real-time updates (WebSocket):**

```graphql
subscription OnNewPost {
  newPost {
    id
    title
    author {
      username
    }
    published_at
  }
}
```

**Server push quando nuovo post pubblicato:**

```json
{
  "data": {
    "newPost": {
      "id": "789",
      "title": "Breaking News",
      "author": {
        "username": "admin"
      },
      "published_at": "2024-10-30T16:00:00Z"
    }
  }
}
```

---

## 22.4 GraphQL Server Implementation

### 22.4.1 - Apollo Server (Node.js)

**Installation:**

```bash
npm install apollo-server graphql
```

**Basic server:**

```javascript
const { ApolloServer, gql } = require('apollo-server');

// Schema
const typeDefs = gql`
  type User {
    id: ID!
    username: String!
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
    post(id: ID!): Post
  }
  
  type Mutation {
    createUser(username: String!, email: String!, password: String!): User!
    createPost(title: String!, content: String!, author_id: ID!): Post!
  }
`;

// Resolvers
const resolvers = {
  Query: {
    user: async (parent, args, context) => {
      // args.id contiene l'ID richiesto
      const user = await User.findById(args.id);
      return user;
    },
    
    users: async () => {
      const users = await User.findAll();
      return users;
    },
    
    post: async (parent, args) => {
      const post = await Post.findById(args.id);
      return post;
    }
  },
  
  Mutation: {
    createUser: async (parent, args) => {
      const { username, email, password } = args;
      
      const passwordHash = await bcrypt.hash(password, 10);
      
      const user = await User.create({
        username,
        email,
        password_hash: passwordHash
      });
      
      return user;
    },
    
    createPost: async (parent, args) => {
      const { title, content, author_id } = args;
      
      const post = await Post.create({
        title,
        content,
        author_id
      });
      
      return post;
    }
  },
  
  // Field resolvers (nested data)
  User: {
    posts: async (user) => {
      // user è l'oggetto User parent
      const posts = await Post.findAll({
        where: { author_id: user.id }
      });
      return posts;
    }
  },
  
  Post: {
    author: async (post) => {
      // post è l'oggetto Post parent
      const author = await User.findById(post.author_id);
      return author;
    }
  }
};

// Server
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    // Context disponibile in tutti i resolvers
    const token = req.headers.authorization || '';
    const user = getUserFromToken(token);
    return { user };
  }
});

server.listen({ port: 4000 }).then(({ url }) => {
  console.log(`GraphQL server ready at ${url}`);
});
```

**GraphQL Playground (built-in):**

```
http://localhost:4000/
```

### 22.4.2 - Authentication

**Protected queries:**

```javascript
const resolvers = {
  Query: {
    me: (parent, args, context) => {
      // context.user popolato dal middleware
      if (!context.user) {
        throw new Error('Not authenticated');
      }
      
      return context.user;
    },
    
    users: (parent, args, context) => {
      if (!context.user || context.user.role !== 'admin') {
        throw new Error('Not authorized');
      }
      
      return User.findAll();
    }
  }
};

// Context with JWT
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    const token = req.headers.authorization?.replace('Bearer ', '');
    
    if (!token) {
      return { user: null };
    }
    
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = { id: decoded.id, role: decoded.role };
      return { user };
    } catch (err) {
      return { user: null };
    }
  }
});
```

**Client query with auth:**

```http
POST /graphql HTTP/1.1
Host: localhost:4000
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

{
  "query": "query { me { id username email } }"
}
```

### 22.4.3 - DataLoader (N+1 Problem)

**Problema: N+1 queries**

```graphql
query {
  posts {
    title
    author {
      username
    }
  }
}
```

**Naive resolver:**

```javascript
Post: {
  author: async (post) => {
    // ❌ Chiamato per ogni post!
    // 100 posts → 100 DB queries!
    return await User.findById(post.author_id);
  }
}
```

**Soluzione: DataLoader (batching)**

```bash
npm install dataloader
```

```javascript
const DataLoader = require('dataloader');

// Batch function
const batchUsers = async (userIds) => {
  // Riceve array di IDs: [1, 2, 3, 4]
  const users = await User.findAll({
    where: { id: userIds }
  });
  
  // DEVE ritornare array nello stesso ordine degli IDs
  const userMap = {};
  users.forEach(user => {
    userMap[user.id] = user;
  });
  
  return userIds.map(id => userMap[id] || null);
};

// Context with DataLoader
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: () => ({
    userLoader: new DataLoader(batchUsers)
  })
});

// Resolver usa DataLoader
const resolvers = {
  Post: {
    author: async (post, args, context) => {
      // ✅ DataLoader batcha le richieste
      // 100 posts → 1 DB query!
      return await context.userLoader.load(post.author_id);
    }
  }
};
```

**Come funziona:**
```
1. Query chiede 100 posts + authors
2. Resolver Post.author chiamato 100 volte
3. DataLoader colleziona tutti gli IDs: [1, 2, 3, ...]
4. Esegue 1 singola query: SELECT * FROM users WHERE id IN (1,2,3,...)
5. Ritorna risultati cached
```

---

## 22.5 GraphQL vs REST Comparison

### 22.5.1 - When to use REST

**✅ REST è meglio quando:**

```
✅ API pubblica semplice (few endpoints)
✅ CRUD operations standard
✅ HTTP caching importante
✅ File upload/download
✅ Team non ha esperienza GraphQL
✅ Need strong HTTP semantics (status codes)
✅ API per third-party developers (easy to understand)
```

**Esempi REST ideale:**

```
GET    /api/products           → Lista prodotti (cacheable)
GET    /api/products/123       → Singolo prodotto (cacheable)
POST   /api/orders             → Crea ordine
GET    /api/invoices/456.pdf   → Download PDF
```

### 22.5.2 - When to use GraphQL

**✅ GraphQL è meglio quando:**

```
✅ Client diversi con esigenze diverse (mobile, web, etc.)
✅ Nested data relationships complesse
✅ Rapid iteration (frontend cambia spesso)
✅ Real-time updates (subscriptions)
✅ Aggregation da multiple data sources
✅ Over-fetching/under-fetching problematico
✅ Strong typing importante
```

**Esempi GraphQL ideale:**

```graphql
# Mobile app: solo dati essenziali
query MobileApp {
  user(id: "123") {
    username
    avatar_url
  }
}

# Web app: tutti i dettagli
query WebApp {
  user(id: "123") {
    username
    email
    bio
    avatar_url
    posts {
      title
      comments { text }
    }
  }
}
```

### 22.5.3 - Hybrid Approach

**REST + GraphQL insieme:**

```javascript
const express = require('express');
const { ApolloServer } = require('apollo-server-express');

const app = express();

// REST endpoints (simple CRUD)
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/upload', upload.single('file'), (req, res) => {
  res.json({ url: req.file.path });
});

// GraphQL endpoint (complex queries)
const server = new ApolloServer({ typeDefs, resolvers });
server.applyMiddleware({ app, path: '/graphql' });

app.listen(4000);
```

**Client usa entrambi:**

```javascript
// REST per upload file
const formData = new FormData();
formData.append('file', file);

await fetch('/api/upload', {
  method: 'POST',
  body: formData
});

// GraphQL per query complesse
await fetch('/graphql', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    query: `
      query {
        user(id: "123") {
          username
          posts { title }
        }
      }
    `
  })
});
```

---

## 22.6 GraphQL Challenges

### 22.6.1 - HTTP Caching

**Problema: GraphQL usa sempre POST**

```http
POST /graphql HTTP/1.1

{
  "query": "query { user(id: \"123\") { username } }"
}
```

**❌ POST non è cacheable da HTTP cache!**

**Soluzione 1: Persisted Queries**

```javascript
// Client invia hash invece di query
POST /graphql HTTP/1.1

{
  "id": "abc123hash",
  "variables": { "userId": "123" }
}

// Server ha mapping hash → query
const queries = {
  "abc123hash": "query GetUser($userId: ID!) { user(id: $userId) { username } }"
};
```

**Soluzione 2: GET per queries (Apollo)**

```http
GET /graphql?query=query{user(id:"123"){username}} HTTP/1.1

# Ora è cacheable!
```

**Apollo Client config:**

```javascript
const client = new ApolloClient({
  link: createHttpLink({
    uri: '/graphql',
    useGETForQueries: true  // ✅ Use GET for queries
  }),
  cache: new InMemoryCache()
});
```

### 22.6.2 - Rate Limiting

**Problema: Query complexity è variabile**

```graphql
# Query semplice (cheap)
query {
  user(id: "123") {
    username
  }
}

# Query costosa (expensive!)
query {
  users {
    posts {
      comments {
        author {
          posts {
            comments {
              author { username }
            }
          }
        }
      }
    }
  }
}
```

**❌ Rate limiting basato su request count non basta!**

**Soluzione: Query cost analysis**

```bash
npm install graphql-cost-analysis
```

```javascript
const { createComplexityLimitRule } = require('graphql-validation-complexity');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    createComplexityLimitRule(1000, {
      scalarCost: 1,
      objectCost: 5,
      listFactor: 10
    })
  ]
});
```

**Query depth limit:**

```javascript
const depthLimit = require('graphql-depth-limit');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    depthLimit(5)  // Max 5 livelli di nesting
  ]
});
```

### 22.6.3 - Error Handling

**GraphQL ritorna sempre 200 OK (anche con errori!):**

```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "data": {
    "user": null
  },
  "errors": [
    {
      "message": "User not found",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["user"]
    }
  ]
}
```

**Custom errors:**

```javascript
const { ApolloError } = require('apollo-server');

class NotFoundError extends ApolloError {
  constructor(message) {
    super(message, 'NOT_FOUND');
  }
}

class UnauthorizedError extends ApolloError {
  constructor(message) {
    super(message, 'UNAUTHORIZED');
  }
}

const resolvers = {
  Query: {
    user: async (parent, args, context) => {
      if (!context.user) {
        throw new UnauthorizedError('Authentication required');
      }
      
      const user = await User.findById(args.id);
      
      if (!user) {
        throw new NotFoundError('User not found');
      }
      
      return user;
    }
  }
};
```

**Response:**

```json
{
  "data": {
    "user": null
  },
  "errors": [
    {
      "message": "User not found",
      "extensions": {
        "code": "NOT_FOUND"
      },
      "path": ["user"]
    }
  ]
}
```

---

## 22.7 Performance Comparison

### 22.7.1 - REST Multiple Requests

**Scenario: User dashboard (user + posts + comments)**

**REST:**

```javascript
// 3 sequential requests
const user = await fetch('/api/users/123');
const posts = await fetch('/api/users/123/posts');
const comments = await fetch('/api/posts/456/comments');

// Tempo totale: ~300ms (3 x 100ms)
```

**Waterfall:**

```
|---user---| (100ms)
          |---posts---| (100ms)
                     |---comments---| (100ms)
Total: 300ms
```

### 22.7.2 - GraphQL Single Request

**GraphQL:**

```javascript
const response = await fetch('/graphql', {
  method: 'POST',
  body: JSON.stringify({
    query: `
      query {
        user(id: "123") {
          username
          posts {
            title
            comments { text }
          }
        }
      }
    `
  })
});

// Tempo totale: ~150ms (1 request, parallel DB queries)
```

**✅ 50% faster!**

### 22.7.3 - Data Transfer Size

**REST over-fetching:**

```json
// GET /api/users/123
{
  "id": 123,
  "username": "john_doe",
  "email": "john@example.com",
  "bio": "...",
  "phone": "...",
  "address": {...},
  "preferences": {...}
  // Total: 2 KB
}

// Client uses only: username, avatar_url
// Wasted: ~1.8 KB (90%)
```

**GraphQL exact data:**

```json
// query { user(id: "123") { username avatar_url } }
{
  "data": {
    "user": {
      "username": "john_doe",
      "avatar_url": "https://..."
    }
  }
}
// Total: 200 bytes
```

**✅ 90% bandwidth savings!**

---

## 22.8 Complete GraphQL Example

**Full working server:**

```javascript
const { ApolloServer, gql } = require('apollo-server');
const DataLoader = require('dataloader');

// Schema
const typeDefs = gql`
  type User {
    id: ID!
    username: String!
    email: String!
    posts: [Post!]!
    created_at: String!
  }
  
  type Post {
    id: ID!
    title: String!
    content: String!
    author: User!
    comments: [Comment!]!
    published_at: String!
  }
  
  type Comment {
    id: ID!
    text: String!
    author: User!
    post: Post!
    created_at: String!
  }
  
  type Query {
    user(id: ID!): User
    users(limit: Int, offset: Int): [User!]!
    post(id: ID!): Post
    posts(author_id: ID): [Post!]!
  }
  
  type Mutation {
    createUser(username: String!, email: String!, password: String!): User!
    createPost(title: String!, content: String!): Post!
    createComment(post_id: ID!, text: String!): Comment!
  }
  
  type Subscription {
    newPost: Post!
  }
`;

// DataLoaders
const createLoaders = () => ({
  userLoader: new DataLoader(async (ids) => {
    const users = await User.findAll({ where: { id: ids } });
    const userMap = {};
    users.forEach(u => userMap[u.id] = u);
    return ids.map(id => userMap[id]);
  }),
  
  postsByUserLoader: new DataLoader(async (userIds) => {
    const posts = await Post.findAll({ where: { author_id: userIds } });
    const postsMap = {};
    userIds.forEach(id => postsMap[id] = []);
    posts.forEach(p => postsMap[p.author_id].push(p));
    return userIds.map(id => postsMap[id] || []);
  })
});

// Resolvers
const resolvers = {
  Query: {
    user: async (_, { id }, { userLoader }) => {
      return await userLoader.load(id);
    },
    
    users: async (_, { limit = 20, offset = 0 }) => {
      return await User.findAll({ limit, offset });
    },
    
    post: async (_, { id }) => {
      return await Post.findById(id);
    },
    
    posts: async (_, { author_id }) => {
      const where = author_id ? { author_id } : {};
      return await Post.findAll({ where });
    }
  },
  
  Mutation: {
    createUser: async (_, { username, email, password }, { user }) => {
      if (!user) {
        throw new Error('Not authenticated');
      }
      
      const passwordHash = await bcrypt.hash(password, 10);
      
      return await User.create({
        username,
        email,
        password_hash: passwordHash
      });
    },
    
    createPost: async (_, { title, content }, { user }) => {
      if (!user) {
        throw new Error('Not authenticated');
      }
      
      const post = await Post.create({
        title,
        content,
        author_id: user.id
      });
      
      // Trigger subscription
      pubsub.publish('NEW_POST', { newPost: post });
      
      return post;
    },
    
    createComment: async (_, { post_id, text }, { user }) => {
      if (!user) {
        throw new Error('Not authenticated');
      }
      
      return await Comment.create({
        post_id,
        text,
        author_id: user.id
      });
    }
  },
  
  User: {
    posts: async (user, _, { postsByUserLoader }) => {
      return await postsByUserLoader.load(user.id);
    }
  },
  
  Post: {
    author: async (post, _, { userLoader }) => {
      return await userLoader.load(post.author_id);
    },
    
    comments: async (post) => {
      return await Comment.findAll({ where: { post_id: post.id } });
    }
  },
  
  Comment: {
    author: async (comment, _, { userLoader }) => {
      return await userLoader.load(comment.author_id);
    },
    
    post: async (comment) => {
      return await Post.findById(comment.post_id);
    }
  },
  
  Subscription: {
    newPost: {
      subscribe: () => pubsub.asyncIterator(['NEW_POST'])
    }
  }
};

// Server
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req }) => {
    const token = req.headers.authorization?.replace('Bearer ', '');
    const user = token ? getUserFromToken(token) : null;
    
    return {
      user,
      ...createLoaders()
    };
  }
});

server.listen({ port: 4000 }).then(({ url }) => {
  console.log(`GraphQL server ready at ${url}`);
});
```

---

**Capitolo 22 completato!**

Prossimo: **Capitolo 23 - API Documentation (OpenAPI/Swagger)**
