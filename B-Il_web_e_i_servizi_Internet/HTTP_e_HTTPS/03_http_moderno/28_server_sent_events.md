# 28. Server-Sent Events (SSE)

## 28.1 Introduzione

**Server-Sent Events (SSE)** è una tecnologia che permette al server di inviare aggiornamenti in tempo reale ai client tramite HTTP.

**Differenza con WebSocket:**

```
WebSocket:
- Bidirectional (client ↔ server)
- Full-duplex
- Binary + Text
- Custom protocol
- More complex

SSE:
- Unidirectional (server → client)
- Text only
- Standard HTTP
- Simpler
- Auto-reconnect built-in
```

**Quando usare SSE:**

```
✅ SSE è ideale per:
- Live notifications
- News feeds
- Stock tickers
- Social media updates
- Progress tracking
- Server logs streaming
- Monitoring dashboards

❌ Usa WebSocket se:
- Serve comunicazione bidirezionale
- Serve inviare dati binary
- Serve bassa latenza (<10ms)
```

**Vantaggi SSE:**
- 📡 **Simple:** Standard HTTP, no custom protocol
- 🔄 **Auto-reconnect:** Built-in reconnection logic
- 🆔 **Event IDs:** Resume from last received event
- 🔒 **Works with proxies:** Standard HTTP/HTTPS
- 🚀 **Easy to implement:** Native browser API

---

## 28.2 SSE Protocol

### 28.2.1 - Message Format

**SSE stream structure:**

```
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

data: First message\n\n

data: Second message\n\n

event: custom\ndata: Custom event\nid: 123\n\n

data: Multi-line\ndata: message\n\n
```

**Field types:**

```
event: nome_evento
  → Event type (default: "message")

data: contenuto
  → Message payload (can be multi-line)

id: 123
  → Unique event ID (for reconnection)

retry: 5000
  → Reconnection delay in ms

: commento
  → Comment (ignored by client)
```

### 28.2.2 - Event Stream Example

```
: This is a comment

event: update
data: {"user": "John", "action": "login"}
id: 1

data: Simple message without event type
id: 2

event: notification
data: {"type": "warning", "text": "Low battery"}
id: 3

retry: 10000

data: Multi-line
data: message with
data: multiple lines
id: 4
```

---

## 28.3 Client Implementation

### 28.3.1 - Browser EventSource API

**Basic usage:**

```javascript
// Create EventSource connection
const eventSource = new EventSource('/events');

// Listen for "message" events (default)
eventSource.addEventListener('message', (event) => {
    console.log('New message:', event.data);
    console.log('Event ID:', event.lastEventId);
});

// Listen for custom events
eventSource.addEventListener('update', (event) => {
    const data = JSON.parse(event.data);
    console.log('Update:', data);
});

// Connection opened
eventSource.addEventListener('open', () => {
    console.log('Connection opened');
});

// Connection error
eventSource.addEventListener('error', (error) => {
    console.error('EventSource error:', error);
    
    switch (eventSource.readyState) {
        case EventSource.CONNECTING:
            console.log('Reconnecting...');
            break;
        case EventSource.CLOSED:
            console.log('Connection closed');
            break;
    }
});

// Close connection manually
const closeConnection = () => {
    eventSource.close();
    console.log('Connection closed');
};
```

**Connection states:**

```javascript
const checkState = () => {
    switch (eventSource.readyState) {
        case EventSource.CONNECTING:
            console.log('Connecting... (0)');
            break;
        case EventSource.OPEN:
            console.log('Connected (1)');
            break;
        case EventSource.CLOSED:
            console.log('Closed (2)');
            break;
    }
};
```

### 28.3.2 - Real-Time Dashboard

**Live metrics dashboard:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Live Dashboard</title>
    <style>
        .metric {
            padding: 20px;
            margin: 10px;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        .metric-value {
            font-size: 2em;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>Live Metrics Dashboard</h1>
    
    <div id="metrics">
        <div class="metric">
            <div>CPU Usage</div>
            <div class="metric-value" id="cpu">-</div>
        </div>
        
        <div class="metric">
            <div>Memory Usage</div>
            <div class="metric-value" id="memory">-</div>
        </div>
        
        <div class="metric">
            <div>Active Users</div>
            <div class="metric-value" id="users">-</div>
        </div>
    </div>
    
    <div id="notifications"></div>
    
    <script>
        const eventSource = new EventSource('/api/metrics');
        
        // Receive metrics updates
        eventSource.addEventListener('metrics', (event) => {
            const data = JSON.parse(event.data);
            
            document.getElementById('cpu').textContent = 
                data.cpu.toFixed(1) + '%';
            document.getElementById('memory').textContent = 
                data.memory.toFixed(1) + ' MB';
            document.getElementById('users').textContent = 
                data.activeUsers;
        });
        
        // Receive notifications
        eventSource.addEventListener('notification', (event) => {
            const data = JSON.parse(event.data);
            
            const notifDiv = document.createElement('div');
            notifDiv.className = 'notification';
            notifDiv.textContent = `${data.type}: ${data.message}`;
            
            document.getElementById('notifications')
                .prepend(notifDiv);
        });
        
        // Handle errors
        eventSource.addEventListener('error', (error) => {
            console.error('Connection error:', error);
        });
    </script>
</body>
</html>
```

### 28.3.3 - Authentication with Headers

**EventSource doesn't support custom headers directly:**

```javascript
// ❌ This doesn't work:
const eventSource = new EventSource('/events', {
    headers: {
        'Authorization': 'Bearer token123'
    }
});
```

**✅ Solutions:**

**1. Token in URL (least secure):**

```javascript
const token = 'jwt-token-here';
const eventSource = new EventSource(`/events?token=${token}`);
```

**2. Cookie-based authentication (recommended):**

```javascript
// Server sets cookie
res.cookie('auth_token', token, {
    httpOnly: true,
    secure: true,
    sameSite: 'strict'
});

// Client (cookie sent automatically)
const eventSource = new EventSource('/events', {
    withCredentials: true
});
```

**3. Custom implementation with fetch:**

```javascript
class AuthenticatedEventSource {
    constructor(url, token) {
        this.url = url;
        this.token = token;
        this.listeners = new Map();
        this.connect();
    }
    
    async connect() {
        const response = await fetch(this.url, {
            headers: {
                'Authorization': `Bearer ${this.token}`,
                'Accept': 'text/event-stream'
            }
        });
        
        const reader = response.body.getReader();
        const decoder = new TextDecoder();
        
        let buffer = '';
        
        while (true) {
            const { done, value } = await reader.read();
            
            if (done) break;
            
            buffer += decoder.decode(value, { stream: true });
            
            const lines = buffer.split('\n\n');
            buffer = lines.pop(); // Keep incomplete event
            
            for (const line of lines) {
                this.processEvent(line);
            }
        }
    }
    
    processEvent(eventText) {
        const lines = eventText.split('\n');
        let event = { type: 'message', data: '' };
        
        for (const line of lines) {
            if (line.startsWith('event:')) {
                event.type = line.slice(6).trim();
            } else if (line.startsWith('data:')) {
                event.data += line.slice(5).trim() + '\n';
            } else if (line.startsWith('id:')) {
                event.id = line.slice(3).trim();
            }
        }
        
        event.data = event.data.trim();
        
        const listeners = this.listeners.get(event.type) || [];
        listeners.forEach(callback => callback(event));
    }
    
    addEventListener(type, callback) {
        if (!this.listeners.has(type)) {
            this.listeners.set(type, []);
        }
        this.listeners.get(type).push(callback);
    }
}

// Usage
const sse = new AuthenticatedEventSource('/events', 'jwt-token');
sse.addEventListener('message', (event) => {
    console.log('Message:', event.data);
});
```

---

## 28.4 Server Implementation

### 28.4.1 - Node.js Express

**Basic SSE endpoint:**

```javascript
const express = require('express');
const app = express();

app.get('/events', (req, res) => {
    // Set SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // CORS (if needed)
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    // Send initial message
    res.write('data: Connected\n\n');
    
    // Send periodic updates
    const intervalId = setInterval(() => {
        const message = {
            timestamp: Date.now(),
            value: Math.random()
        };
        
        res.write(`data: ${JSON.stringify(message)}\n\n`);
    }, 1000);
    
    // Cleanup on connection close
    req.on('close', () => {
        clearInterval(intervalId);
        console.log('Client disconnected');
    });
});

app.listen(3000, () => {
    console.log('SSE server running on http://localhost:3000');
});
```

### 28.4.2 - Custom Events with ID

**Send different event types:**

```javascript
const express = require('express');
const app = express();

let eventId = 0;

app.get('/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // Helper function to send events
    const sendEvent = (eventType, data) => {
        eventId++;
        res.write(`event: ${eventType}\n`);
        res.write(`id: ${eventId}\n`);
        res.write(`data: ${JSON.stringify(data)}\n\n`);
    };
    
    // Send welcome
    sendEvent('message', { text: 'Connected to server' });
    
    // Send metrics every second
    const metricsInterval = setInterval(() => {
        sendEvent('metrics', {
            cpu: (Math.random() * 100).toFixed(2),
            memory: (Math.random() * 8192).toFixed(2),
            activeUsers: Math.floor(Math.random() * 100)
        });
    }, 1000);
    
    // Send random notifications
    const notifInterval = setInterval(() => {
        if (Math.random() > 0.7) {
            sendEvent('notification', {
                type: 'info',
                message: 'Random notification'
            });
        }
    }, 5000);
    
    // Cleanup
    req.on('close', () => {
        clearInterval(metricsInterval);
        clearInterval(notifInterval);
        console.log('Client disconnected');
    });
});

app.listen(3000);
```

### 28.4.3 - Resume from Last Event ID

**Client reconnection with Last-Event-ID:**

```javascript
const express = require('express');
const app = express();

// Store events in memory (in production, use database)
const events = [];
let eventId = 0;

const addEvent = (type, data) => {
    eventId++;
    const event = {
        id: eventId,
        type,
        data,
        timestamp: Date.now()
    };
    events.push(event);
    
    // Keep only last 100 events
    if (events.length > 100) {
        events.shift();
    }
    
    return event;
};

app.get('/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // Get last event ID from client
    const lastEventId = parseInt(req.headers['last-event-id'] || '0');
    
    console.log(`Client reconnected, last ID: ${lastEventId}`);
    
    // Send missed events
    const missedEvents = events.filter(e => e.id > lastEventId);
    missedEvents.forEach(event => {
        res.write(`event: ${event.type}\n`);
        res.write(`id: ${event.id}\n`);
        res.write(`data: ${JSON.stringify(event.data)}\n\n`);
    });
    
    console.log(`Sent ${missedEvents.length} missed events`);
    
    // Store client connection
    clients.add(res);
    
    req.on('close', () => {
        clients.delete(res);
        console.log('Client disconnected');
    });
});

// Broadcast to all clients
const clients = new Set();

const broadcast = (type, data) => {
    const event = addEvent(type, data);
    
    clients.forEach(client => {
        client.write(`event: ${event.type}\n`);
        client.write(`id: ${event.id}\n`);
        client.write(`data: ${JSON.stringify(event.data)}\n\n`);
    });
};

// Simulate events
setInterval(() => {
    broadcast('update', {
        value: Math.random(),
        timestamp: Date.now()
    });
}, 2000);

app.listen(3000);
```

---

## 28.5 Advanced Patterns

### 28.5.1 - Progress Tracking

**Long-running task with progress updates:**

```javascript
const express = require('express');
const app = express();

// Store active tasks
const tasks = new Map();

// Start task
app.post('/api/tasks', (req, res) => {
    const taskId = Date.now().toString();
    
    tasks.set(taskId, {
        id: taskId,
        status: 'pending',
        progress: 0,
        result: null
    });
    
    // Simulate long-running task
    simulateTask(taskId);
    
    res.json({ taskId });
});

// SSE endpoint for task progress
app.get('/api/tasks/:taskId/progress', (req, res) => {
    const { taskId } = req.params;
    
    if (!tasks.has(taskId)) {
        res.status(404).json({ error: 'Task not found' });
        return;
    }
    
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    const sendUpdate = () => {
        const task = tasks.get(taskId);
        
        res.write(`data: ${JSON.stringify(task)}\n\n`);
        
        if (task.status === 'completed' || task.status === 'failed') {
            res.end();
        }
    };
    
    // Send initial state
    sendUpdate();
    
    // Send updates every second
    const intervalId = setInterval(sendUpdate, 1000);
    
    req.on('close', () => {
        clearInterval(intervalId);
    });
});

const simulateTask = async (taskId) => {
    const task = tasks.get(taskId);
    task.status = 'running';
    
    for (let i = 0; i <= 100; i += 10) {
        await new Promise(resolve => setTimeout(resolve, 500));
        task.progress = i;
    }
    
    task.status = 'completed';
    task.result = { data: 'Task completed!' };
};

app.listen(3000);
```

**Client:**

```javascript
const startTask = async () => {
    // Start task
    const response = await fetch('/api/tasks', { method: 'POST' });
    const { taskId } = await response.json();
    
    // Listen for progress
    const eventSource = new EventSource(`/api/tasks/${taskId}/progress`);
    
    eventSource.addEventListener('message', (event) => {
        const task = JSON.parse(event.data);
        
        console.log(`Progress: ${task.progress}%`);
        
        if (task.status === 'completed') {
            console.log('Task completed:', task.result);
            eventSource.close();
        } else if (task.status === 'failed') {
            console.error('Task failed');
            eventSource.close();
        }
    });
};
```

### 28.5.2 - Live Log Streaming

**Stream server logs to browser:**

```javascript
const express = require('express');
const fs = require('fs');
const { spawn } = require('child_process');

const app = express();

app.get('/logs', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    // Tail log file
    const tail = spawn('tail', ['-f', '/var/log/app.log']);
    
    tail.stdout.on('data', (data) => {
        const lines = data.toString().split('\n');
        
        lines.forEach(line => {
            if (line.trim()) {
                res.write(`data: ${line}\n\n`);
            }
        });
    });
    
    tail.stderr.on('data', (data) => {
        console.error('Tail error:', data.toString());
    });
    
    req.on('close', () => {
        tail.kill();
        console.log('Log streaming stopped');
    });
});

app.listen(3000);
```

**Client:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Live Logs</title>
    <style>
        #logs {
            font-family: monospace;
            background: #000;
            color: #0f0;
            padding: 10px;
            height: 500px;
            overflow-y: auto;
        }
        .log-line {
            margin: 2px 0;
        }
    </style>
</head>
<body>
    <h1>Live Server Logs</h1>
    <div id="logs"></div>
    
    <script>
        const logsDiv = document.getElementById('logs');
        const eventSource = new EventSource('/logs');
        
        eventSource.addEventListener('message', (event) => {
            const line = document.createElement('div');
            line.className = 'log-line';
            line.textContent = event.data;
            
            logsDiv.appendChild(line);
            
            // Auto-scroll
            logsDiv.scrollTop = logsDiv.scrollHeight;
            
            // Keep only last 1000 lines
            while (logsDiv.children.length > 1000) {
                logsDiv.removeChild(logsDiv.firstChild);
            }
        });
    </script>
</body>
</html>
```

---

## 28.6 Production Deployment

### 28.6.1 - Nginx Proxy

**Nginx configuration for SSE:**

```nginx
http {
    upstream sse_backend {
        server localhost:3000;
        server localhost:3001;
        server localhost:3002;
    }
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        ssl_certificate /etc/ssl/certs/example.com.crt;
        ssl_certificate_key /etc/ssl/private/example.com.key;
        
        # SSE endpoint
        location /events {
            proxy_pass http://sse_backend;
            
            # SSE headers
            proxy_set_header Connection '';
            proxy_http_version 1.1;
            chunked_transfer_encoding off;
            
            # Disable buffering (important for SSE!)
            proxy_buffering off;
            proxy_cache off;
            
            # Preserve client info
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            
            # Long timeout for SSE
            proxy_read_timeout 24h;
            proxy_send_timeout 24h;
        }
        
        # Regular endpoints
        location / {
            proxy_pass http://sse_backend;
            proxy_set_header Host $host;
        }
    }
}
```

### 28.6.2 - Connection Management

**Limit connections and handle cleanup:**

```javascript
const express = require('express');
const app = express();

const MAX_CONNECTIONS = 1000;
const clients = new Map();

app.get('/events', (req, res) => {
    // Check connection limit
    if (clients.size >= MAX_CONNECTIONS) {
        res.status(503).json({
            error: 'Too many connections',
            retry_after: 60
        });
        return;
    }
    
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    const clientId = Date.now() + Math.random();
    
    clients.set(clientId, {
        res,
        connectedAt: Date.now()
    });
    
    console.log(`Client connected: ${clientId} (total: ${clients.size})`);
    
    // Send heartbeat every 30 seconds
    const heartbeatId = setInterval(() => {
        res.write(': heartbeat\n\n');
    }, 30000);
    
    // Cleanup on disconnect
    req.on('close', () => {
        clearInterval(heartbeatId);
        clients.delete(clientId);
        console.log(`Client disconnected: ${clientId} (total: ${clients.size})`);
    });
});

// Broadcast to all clients
const broadcast = (eventType, data) => {
    const message = `event: ${eventType}\ndata: ${JSON.stringify(data)}\n\n`;
    
    clients.forEach((client, clientId) => {
        try {
            client.res.write(message);
        } catch (error) {
            console.error(`Error sending to client ${clientId}:`, error);
            clients.delete(clientId);
        }
    });
};

// Cleanup stale connections (older than 1 hour)
setInterval(() => {
    const now = Date.now();
    const maxAge = 60 * 60 * 1000; // 1 hour
    
    clients.forEach((client, clientId) => {
        if (now - client.connectedAt > maxAge) {
            console.log(`Closing stale connection: ${clientId}`);
            client.res.end();
            clients.delete(clientId);
        }
    });
}, 60000);

app.listen(3000);
```

---

## 28.7 Monitoring & Metrics

**Track SSE metrics:**

```javascript
const express = require('express');
const prometheus = require('prom-client');

const app = express();

// Metrics
const activeConnections = new prometheus.Gauge({
    name: 'sse_active_connections',
    help: 'Current SSE connections'
});

const totalConnections = new prometheus.Counter({
    name: 'sse_connections_total',
    help: 'Total SSE connections'
});

const messagesSent = new prometheus.Counter({
    name: 'sse_messages_sent_total',
    help: 'Total SSE messages sent',
    labelNames: ['event_type']
});

const clients = new Set();

app.get('/events', (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    
    clients.add(res);
    activeConnections.inc();
    totalConnections.inc();
    
    req.on('close', () => {
        clients.delete(res);
        activeConnections.dec();
    });
});

const broadcast = (eventType, data) => {
    const message = `event: ${eventType}\ndata: ${JSON.stringify(data)}\n\n`;
    
    clients.forEach(client => {
        client.write(message);
        messagesSent.labels(eventType).inc();
    });
};

// Metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(3000);
```

---

## 28.8 Best Practices

**Complete production SSE server:**

```javascript
const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');

const app = express();

// Security
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});
app.use(limiter);

// Configuration
const MAX_CONNECTIONS = 1000;
const HEARTBEAT_INTERVAL = 30000;
const MAX_CONNECTION_AGE = 3600000; // 1 hour

const clients = new Map();

// Authentication middleware
const authenticate = (req, res, next) => {
    const token = req.query.token;
    
    if (!token) {
        res.status(401).json({ error: 'Token required' });
        return;
    }
    
    try {
        const user = jwt.verify(token, process.env.JWT_SECRET);
        req.user = user;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Invalid token' });
    }
};

// SSE endpoint
app.get('/events', authenticate, (req, res) => {
    // Check connection limit
    if (clients.size >= MAX_CONNECTIONS) {
        res.status(503).json({
            error: 'Too many connections',
            retry_after: 60
        });
        return;
    }
    
    // Set SSE headers
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.setHeader('X-Accel-Buffering', 'no'); // Disable Nginx buffering
    
    const clientId = `${req.user.id}-${Date.now()}`;
    
    clients.set(clientId, {
        res,
        user: req.user,
        connectedAt: Date.now()
    });
    
    console.log(`Client connected: ${clientId} (total: ${clients.size})`);
    
    // Send welcome
    res.write(`data: ${JSON.stringify({ type: 'connected', clientId })}\n\n`);
    
    // Heartbeat
    const heartbeatId = setInterval(() => {
        res.write(': heartbeat\n\n');
    }, HEARTBEAT_INTERVAL);
    
    // Cleanup
    req.on('close', () => {
        clearInterval(heartbeatId);
        clients.delete(clientId);
        console.log(`Client disconnected: ${clientId} (total: ${clients.size})`);
    });
});

// Broadcast function
const broadcast = (eventType, data, filter = null) => {
    const message = `event: ${eventType}\ndata: ${JSON.stringify(data)}\n\n`;
    
    clients.forEach((client, clientId) => {
        // Apply filter if provided
        if (filter && !filter(client)) {
            return;
        }
        
        try {
            client.res.write(message);
        } catch (error) {
            console.error(`Error sending to ${clientId}:`, error);
            clients.delete(clientId);
        }
    });
};

// Cleanup stale connections
setInterval(() => {
    const now = Date.now();
    
    clients.forEach((client, clientId) => {
        if (now - client.connectedAt > MAX_CONNECTION_AGE) {
            console.log(`Closing stale connection: ${clientId}`);
            client.res.end();
            clients.delete(clientId);
        }
    });
}, 60000);

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing connections...');
    
    clients.forEach((client) => {
        client.res.write('event: shutdown\ndata: Server shutting down\n\n');
        client.res.end();
    });
    
    clients.clear();
    process.exit(0);
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`SSE server running on port ${PORT}`);
});
```

---

**Capitolo 28 completato!**

Prossimo: **Capitolo 29 - HTTP/2 Server Push**
