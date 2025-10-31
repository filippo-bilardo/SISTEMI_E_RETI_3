# 41. Testing e Debugging HTTP

## 41.1 Introduzione al Testing HTTP

**Testing HTTP API** garantisce affidabilità e correttezza del comportamento.

**Tipi di test:**

```
1. Unit Tests
   - Test singole funzioni/controller
   - Mocking delle dipendenze

2. Integration Tests
   - Test endpoint completi
   - Database reale o mock

3. End-to-End Tests
   - Test flow completo utente
   - Browser automation

4. Load Tests
   - Performance sotto carico
   - Stress testing

5. Security Tests
   - Vulnerability scanning
   - Penetration testing
```

---

## 41.2 Unit Testing con Jest

### 41.2.1 - Setup Jest

**package.json:**

```json
{
  "name": "api-testing",
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "supertest": "^6.3.0"
  }
}
```

**jest.config.js:**

```javascript
module.exports = {
    testEnvironment: 'node',
    coverageDirectory: 'coverage',
    collectCoverageFrom: [
        'src/**/*.js',
        '!src/index.js'
    ],
    testMatch: [
        '**/__tests__/**/*.test.js'
    ],
    verbose: true
};
```

### 41.2.2 - API Testing

**app.js:**

```javascript
const express = require('express');
const app = express();

app.use(express.json());

// In-memory database
let users = [
    { id: 1, name: 'John Doe', email: 'john@example.com' },
    { id: 2, name: 'Jane Smith', email: 'jane@example.com' }
];

// Routes
app.get('/api/users', (req, res) => {
    res.json({ data: users });
});

app.get('/api/users/:id', (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ data: user });
});

app.post('/api/users', (req, res) => {
    const { name, email } = req.body;
    
    if (!name || !email) {
        return res.status(400).json({ error: 'Name and email required' });
    }
    
    const newUser = {
        id: users.length + 1,
        name,
        email
    };
    
    users.push(newUser);
    res.status(201).json({ data: newUser });
});

app.put('/api/users/:id', (req, res) => {
    const user = users.find(u => u.id === parseInt(req.params.id));
    
    if (!user) {
        return res.status(404).json({ error: 'User not found' });
    }
    
    const { name, email } = req.body;
    if (name) user.name = name;
    if (email) user.email = email;
    
    res.json({ data: user });
});

app.delete('/api/users/:id', (req, res) => {
    const index = users.findIndex(u => u.id === parseInt(req.params.id));
    
    if (index === -1) {
        return res.status(404).json({ error: 'User not found' });
    }
    
    users.splice(index, 1);
    res.status(204).end();
});

module.exports = app;
```

**__tests__/users.test.js:**

```javascript
const request = require('supertest');
const app = require('../app');

describe('Users API', () => {
    describe('GET /api/users', () => {
        test('should return all users', async () => {
            const res = await request(app)
                .get('/api/users')
                .expect('Content-Type', /json/)
                .expect(200);
            
            expect(res.body).toHaveProperty('data');
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });
    });
    
    describe('GET /api/users/:id', () => {
        test('should return user by ID', async () => {
            const res = await request(app)
                .get('/api/users/1')
                .expect(200);
            
            expect(res.body.data).toHaveProperty('id', 1);
            expect(res.body.data).toHaveProperty('name');
            expect(res.body.data).toHaveProperty('email');
        });
        
        test('should return 404 for non-existent user', async () => {
            const res = await request(app)
                .get('/api/users/999')
                .expect(404);
            
            expect(res.body).toHaveProperty('error', 'User not found');
        });
    });
    
    describe('POST /api/users', () => {
        test('should create new user', async () => {
            const newUser = {
                name: 'Test User',
                email: 'test@example.com'
            };
            
            const res = await request(app)
                .post('/api/users')
                .send(newUser)
                .expect('Content-Type', /json/)
                .expect(201);
            
            expect(res.body.data).toHaveProperty('id');
            expect(res.body.data).toMatchObject(newUser);
        });
        
        test('should return 400 for invalid data', async () => {
            const res = await request(app)
                .post('/api/users')
                .send({ name: 'Test' })
                .expect(400);
            
            expect(res.body).toHaveProperty('error');
        });
    });
    
    describe('PUT /api/users/:id', () => {
        test('should update user', async () => {
            const update = { name: 'Updated Name' };
            
            const res = await request(app)
                .put('/api/users/1')
                .send(update)
                .expect(200);
            
            expect(res.body.data).toHaveProperty('name', 'Updated Name');
        });
    });
    
    describe('DELETE /api/users/:id', () => {
        test('should delete user', async () => {
            await request(app)
                .delete('/api/users/1')
                .expect(204);
        });
    });
});
```

---

## 41.3 HTTP Headers Testing

### 41.3.1 - Security Headers Tests

**__tests__/security.test.js:**

```javascript
const request = require('supertest');
const app = require('../app');

describe('Security Headers', () => {
    test('should have HSTS header', async () => {
        const res = await request(app).get('/');
        
        expect(res.headers).toHaveProperty('strict-transport-security');
        expect(res.headers['strict-transport-security']).toContain('max-age');
    });
    
    test('should have CSP header', async () => {
        const res = await request(app).get('/');
        
        expect(res.headers).toHaveProperty('content-security-policy');
        expect(res.headers['content-security-policy']).toContain("default-src");
    });
    
    test('should have X-Frame-Options', async () => {
        const res = await request(app).get('/');
        
        expect(res.headers).toHaveProperty('x-frame-options');
        expect(['DENY', 'SAMEORIGIN']).toContain(res.headers['x-frame-options']);
    });
    
    test('should have X-Content-Type-Options', async () => {
        const res = await request(app).get('/');
        
        expect(res.headers['x-content-type-options']).toBe('nosniff');
    });
    
    test('should not expose X-Powered-By', async () => {
        const res = await request(app).get('/');
        
        expect(res.headers['x-powered-by']).toBeUndefined();
    });
});
```

### 41.3.2 - CORS Testing

**__tests__/cors.test.js:**

```javascript
const request = require('supertest');
const app = require('../app');

describe('CORS', () => {
    test('should handle preflight request', async () => {
        const res = await request(app)
            .options('/api/users')
            .set('Origin', 'https://example.com')
            .set('Access-Control-Request-Method', 'POST')
            .expect(204);
        
        expect(res.headers).toHaveProperty('access-control-allow-origin');
        expect(res.headers).toHaveProperty('access-control-allow-methods');
    });
    
    test('should include CORS headers in response', async () => {
        const res = await request(app)
            .get('/api/users')
            .set('Origin', 'https://example.com');
        
        expect(res.headers).toHaveProperty('access-control-allow-origin');
    });
    
    test('should reject unauthorized origins', async () => {
        const res = await request(app)
            .get('/api/users')
            .set('Origin', 'https://malicious.com');
        
        expect(res.headers['access-control-allow-origin']).toBeUndefined();
    });
});
```

---

## 41.4 Debugging con curl

### 41.4.1 - Basic curl Commands

**Test GET request:**

```bash
# Simple GET
curl http://localhost:3000/api/users

# Verbose output (headers)
curl -v http://localhost:3000/api/users

# Show only headers
curl -I http://localhost:3000/api/users

# Follow redirects
curl -L http://localhost:3000/redirect

# Save response to file
curl -o response.json http://localhost:3000/api/users
```

### 41.4.2 - POST/PUT/DELETE

**POST request:**

```bash
# POST with JSON
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# POST with file
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d @user.json

# POST form data
curl -X POST http://localhost:3000/api/users \
  -F "name=John Doe" \
  -F "email=john@example.com"

# File upload
curl -X POST http://localhost:3000/upload \
  -F "file=@image.jpg"
```

**PUT request:**

```bash
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Updated Name"}'
```

**DELETE request:**

```bash
curl -X DELETE http://localhost:3000/api/users/1
```

### 41.4.3 - Headers e Authentication

**Custom headers:**

```bash
# Authorization header
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Multiple headers
curl http://localhost:3000/api/users \
  -H "Authorization: Bearer TOKEN" \
  -H "X-API-Key: abc123" \
  -H "Accept: application/json"

# Basic authentication
curl -u username:password http://localhost:3000/api/users

# Custom User-Agent
curl -A "MyApp/1.0" http://localhost:3000/api/users
```

### 41.4.4 - Advanced curl

**Performance measurement:**

```bash
# Time breakdown
curl -w "\nTime:\n  DNS: %{time_namelookup}s\n  Connect: %{time_connect}s\n  TTFB: %{time_starttransfer}s\n  Total: %{time_total}s\n" \
  http://localhost:3000/api/users

# Download speed
curl -w "Speed: %{speed_download} bytes/sec\n" \
  http://localhost:3000/large-file

# Response code
curl -w "Status: %{http_code}\n" \
  http://localhost:3000/api/users
```

**Cookies:**

```bash
# Save cookies
curl -c cookies.txt http://localhost:3000/login \
  -d "username=user&password=pass"

# Send cookies
curl -b cookies.txt http://localhost:3000/dashboard

# Send specific cookie
curl -b "session=abc123" http://localhost:3000/api/users
```

---

## 41.5 Postman Testing

### 41.5.1 - Postman Tests

**Test scripts in Postman:**

```javascript
// Status code
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

// Response time
pm.test("Response time is less than 200ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(200);
});

// JSON structure
pm.test("Response has correct structure", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property('data');
    pm.expect(jsonData.data).to.be.an('array');
});

// Specific value
pm.test("User has correct email", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.data[0].email).to.eql('john@example.com');
});

// Header check
pm.test("Content-Type is JSON", function () {
    pm.response.to.have.header("Content-Type");
    pm.expect(pm.response.headers.get("Content-Type")).to.include("application/json");
});

// Save variable
pm.test("Save user ID", function () {
    const jsonData = pm.response.json();
    pm.environment.set("userId", jsonData.data.id);
});
```

### 41.5.2 - Collection Variables

**Pre-request script:**

```javascript
// Set timestamp
pm.environment.set("timestamp", Date.now());

// Generate random data
const randomName = pm.variables.replaceIn('{{$randomFirstName}}');
pm.environment.set("userName", randomName);

// Compute signature
const data = pm.request.body.raw;
const signature = CryptoJS.HmacSHA256(data, pm.environment.get("secret"));
pm.request.headers.add({
    key: "X-Signature",
    value: signature.toString()
});
```

---

## 41.6 Load Testing

### 41.6.1 - Artillery Load Testing

**artillery.yml:**

```yaml
config:
  target: "http://localhost:3000"
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Sustained load"
    - duration: 60
      arrivalRate: 100
      name: "Spike"
  
scenarios:
  - name: "Get users"
    flow:
      - get:
          url: "/api/users"
          
  - name: "Create and get user"
    flow:
      - post:
          url: "/api/users"
          json:
            name: "Test User"
            email: "test@example.com"
          capture:
            - json: "$.data.id"
              as: "userId"
      - get:
          url: "/api/users/{{ userId }}"
```

**Run test:**

```bash
# Install
npm install -g artillery

# Run test
artillery run artillery.yml

# Quick test
artillery quick --duration 60 --rate 10 http://localhost:3000/api/users

# Generate HTML report
artillery run artillery.yml --output report.json
artillery report report.json
```

### 41.6.2 - Apache Bench (ab)

**Load testing con ab:**

```bash
# 1000 requests, 10 concurrent
ab -n 1000 -c 10 http://localhost:3000/api/users

# With POST data
ab -n 100 -c 10 -p data.json -T application/json \
  http://localhost:3000/api/users

# With headers
ab -n 100 -c 10 -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/api/users

# Keep alive
ab -n 1000 -c 10 -k http://localhost:3000/api/users
```

**Output interpretation:**

```
Server Software:        nginx
Server Hostname:        localhost
Server Port:            3000

Document Path:          /api/users
Document Length:        156 bytes

Concurrency Level:      10
Time taken for tests:   5.234 seconds
Complete requests:      1000
Failed requests:        0
Total transferred:      312000 bytes
HTML transferred:       156000 bytes

Requests per second:    191.07 [#/sec] (mean)
Time per request:       52.340 [ms] (mean)
Time per request:       5.234 [ms] (mean, across all concurrent requests)
Transfer rate:          58.21 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    1   0.5      1       3
Processing:    10   51  12.3     48     120
Waiting:        9   50  12.2     47     119
Total:         11   52  12.4     49     121

Percentage of requests served within a certain time (ms)
  50%     49
  66%     54
  75%     58
  80%     61
  90%     68
  95%     76
  98%     89
  99%    102
 100%    121 (longest request)
```

---

## 41.7 Debugging Tools

### 41.7.1 - Chrome DevTools

**Network panel inspection:**

```javascript
// In console, log fetch requests
const originalFetch = window.fetch;
window.fetch = async function(...args) {
    console.log('Fetch request:', args[0]);
    const response = await originalFetch(...args);
    console.log('Fetch response:', response.status, response.statusText);
    return response;
};

// Log all XHR
(function() {
    const originalOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url) {
        console.log('XHR:', method, url);
        return originalOpen.apply(this, arguments);
    };
})();
```

### 41.7.2 - Node.js Debugging

**Debug logging:**

```javascript
const express = require('express');
const morgan = require('morgan');

const app = express();

// HTTP request logger
app.use(morgan('dev'));

// Custom debug middleware
app.use((req, res, next) => {
    console.log('=== Request Debug ===');
    console.log('Method:', req.method);
    console.log('URL:', req.url);
    console.log('Headers:', req.headers);
    console.log('Body:', req.body);
    console.log('Query:', req.query);
    console.log('Params:', req.params);
    
    // Log response
    const originalJson = res.json.bind(res);
    res.json = (data) => {
        console.log('=== Response Debug ===');
        console.log('Status:', res.statusCode);
        console.log('Data:', data);
        return originalJson(data);
    };
    
    next();
});

app.listen(3000);
```

**NODE_DEBUG environment:**

```bash
# Debug HTTP module
NODE_DEBUG=http node app.js

# Debug multiple modules
NODE_DEBUG=http,net,tls node app.js
```

### 41.7.3 - Proxy Debugging (Charles/Fiddler)

**Setup proxy in Node.js:**

```javascript
const axios = require('axios');
const HttpsProxyAgent = require('https-proxy-agent');

const proxy = 'http://localhost:8888'; // Charles Proxy

const agent = new HttpsProxyAgent(proxy);

axios.get('https://api.example.com/data', {
    httpsAgent: agent,
    proxy: false
}).then(response => {
    console.log(response.data);
});
```

---

## 41.8 Error Testing

### 41.8.1 - Error Scenarios

**Test error handling:**

```javascript
const request = require('supertest');
const app = require('../app');

describe('Error Handling', () => {
    test('404 for non-existent endpoint', async () => {
        const res = await request(app)
            .get('/api/nonexistent')
            .expect(404);
        
        expect(res.body).toHaveProperty('error');
    });
    
    test('400 for invalid JSON', async () => {
        const res = await request(app)
            .post('/api/users')
            .set('Content-Type', 'application/json')
            .send('invalid json')
            .expect(400);
    });
    
    test('401 for unauthorized access', async () => {
        const res = await request(app)
            .get('/api/protected')
            .expect(401);
        
        expect(res.body.error).toMatch(/unauthorized/i);
    });
    
    test('500 for server error', async () => {
        // Mock error
        jest.spyOn(console, 'error').mockImplementation();
        
        const res = await request(app)
            .get('/api/trigger-error')
            .expect(500);
        
        expect(res.body).toHaveProperty('error');
    });
});
```

### 41.8.2 - Validation Testing

**Input validation tests:**

```javascript
describe('Validation', () => {
    test('should reject missing required fields', async () => {
        const res = await request(app)
            .post('/api/users')
            .send({})
            .expect(400);
        
        expect(res.body.error).toMatch(/required/i);
    });
    
    test('should reject invalid email', async () => {
        const res = await request(app)
            .post('/api/users')
            .send({
                name: 'Test',
                email: 'invalid-email'
            })
            .expect(400);
        
        expect(res.body.error).toMatch(/email/i);
    });
    
    test('should reject too long string', async () => {
        const res = await request(app)
            .post('/api/users')
            .send({
                name: 'A'.repeat(1000),
                email: 'test@example.com'
            })
            .expect(400);
    });
});
```

---

## 41.9 Complete Test Suite

### 41.9.1 - Full Test Example

**Complete test suite:**

```javascript
const request = require('supertest');
const app = require('../app');

describe('API Integration Tests', () => {
    let authToken;
    let userId;
    
    beforeAll(async () => {
        // Login and get token
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                email: 'test@example.com',
                password: 'password'
            });
        
        authToken = res.body.token;
    });
    
    afterAll(async () => {
        // Cleanup
    });
    
    describe('Authentication', () => {
        test('should login successfully', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'password'
                })
                .expect(200);
            
            expect(res.body).toHaveProperty('token');
        });
        
        test('should reject invalid credentials', async () => {
            await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'wrong'
                })
                .expect(401);
        });
    });
    
    describe('Users CRUD', () => {
        test('should create user', async () => {
            const res = await request(app)
                .post('/api/users')
                .set('Authorization', `Bearer ${authToken}`)
                .send({
                    name: 'New User',
                    email: 'new@example.com'
                })
                .expect(201);
            
            userId = res.body.data.id;
            expect(res.body.data).toMatchObject({
                name: 'New User',
                email: 'new@example.com'
            });
        });
        
        test('should get user by ID', async () => {
            const res = await request(app)
                .get(`/api/users/${userId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(200);
            
            expect(res.body.data.id).toBe(userId);
        });
        
        test('should update user', async () => {
            const res = await request(app)
                .put(`/api/users/${userId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .send({ name: 'Updated Name' })
                .expect(200);
            
            expect(res.body.data.name).toBe('Updated Name');
        });
        
        test('should delete user', async () => {
            await request(app)
                .delete(`/api/users/${userId}`)
                .set('Authorization', `Bearer ${authToken}`)
                .expect(204);
        });
    });
    
    describe('Performance', () => {
        test('should respond within acceptable time', async () => {
            const start = Date.now();
            
            await request(app)
                .get('/api/users')
                .expect(200);
            
            const duration = Date.now() - start;
            expect(duration).toBeLessThan(200);
        });
    });
});
```

---

**Capitolo 41 completato!** Testing e debugging completo: Jest, Supertest, curl, Postman, Artillery, error handling, e test suite production-ready! 🧪
