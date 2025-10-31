# 27. WebSockets e Real-Time Communication

## 27.1 Introduzione

**WebSocket** è un protocollo che permette comunicazione bidirezionale full-duplex tra client e server su una singola connessione TCP persistente.

**Problema con HTTP tradizionale:**

```
HTTP Request-Response:
Client → Request → Server
Client ← Response ← Server

Limitations:
- One-way: Client must initiate
- Overhead: Headers su ogni request
- Latency: Round-trip per ogni update
```

**Soluzione WebSocket:**

```
WebSocket Persistent Connection:
Client ↔ Server

Benefits:
- Bidirectional: Server can push
- Low overhead: No headers dopo handshake
- Real-time: Instant updates
```

**Use cases:**
- 💬 **Chat applications:** Messaggi istantanei
- 🎮 **Gaming:** Multiplayer real-time
- 📊 **Live dashboards:** Metriche in tempo reale
- 📈 **Trading platforms:** Quote di mercato
- 🔔 **Notifications:** Push notifications
- 👥 **Collaboration:** Editing collaborativo (Google Docs)
- 📹 **Live streaming:** Commenti live, reactions

---

## 27.2 WebSocket Protocol

### 27.2.1 - Handshake

**HTTP Upgrade request:**

```http
GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: http://example.com
```

**Server response:**

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

**Handshake process:**

```
1. Client → HTTP GET con Upgrade header
2. Server → 101 Switching Protocols
3. Connection upgrades to WebSocket
4. Full-duplex communication begins
```

### 27.2.2 - Frame Structure

**WebSocket frames:**

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-------+-+-------------+-------------------------------+
|F|R|R|R| opcode|M| Payload len |    Extended payload length    |
|I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
|N|V|V|V|       |S|             |                               |
| |1|2|3|       |K|             |                               |
+-+-+-+-+-------+-+-------------+-------------------------------+
|     Extended payload length continued, if payload len == 127  |
+---------------------------------------------------------------+
|                     Payload Data                              |
+---------------------------------------------------------------+

FIN: Final fragment
RSV1-3: Reserved (must be 0)
Opcode: Frame type
  - 0x0: Continuation
  - 0x1: Text
  - 0x2: Binary
  - 0x8: Close
  - 0x9: Ping
  - 0xA: Pong
MASK: Masking key present (client → server must be masked)
Payload len: Length of payload data
```

---

## 27.3 Client Implementation

### 27.3.1 - Browser WebSocket API

**Basic connection:**

```javascript
// Create WebSocket connection
const socket = new WebSocket('ws://localhost:8080');

// Connection opened
socket.addEventListener('open', (event) => {
    console.log('Connected to server');
    socket.send('Hello Server!');
});

// Listen for messages
socket.addEventListener('message', (event) => {
    console.log('Message from server:', event.data);
});

// Listen for errors
socket.addEventListener('error', (error) => {
    console.error('WebSocket error:', error);
});

// Connection closed
socket.addEventListener('close', (event) => {
    console.log('Disconnected from server');
    console.log('Code:', event.code);
    console.log('Reason:', event.reason);
});

// Send data
const sendMessage = (message) => {
    if (socket.readyState === WebSocket.OPEN) {
        socket.send(message);
    } else {
        console.error('Socket not open');
    }
};

// Send JSON
const sendJSON = (data) => {
    socket.send(JSON.stringify(data));
};

// Send binary
const sendBinary = (arrayBuffer) => {
    socket.send(arrayBuffer);
};

// Close connection
const disconnect = () => {
    socket.close(1000, 'Normal closure');
};
```

**Connection states:**

```javascript
const checkState = () => {
    switch (socket.readyState) {
        case WebSocket.CONNECTING:
            console.log('Connecting...');
            break;
        case WebSocket.OPEN:
            console.log('Connected');
            break;
        case WebSocket.CLOSING:
            console.log('Closing...');
            break;
        case WebSocket.CLOSED:
            console.log('Closed');
            break;
    }
};
```

### 27.3.2 - Auto-Reconnect

**Reconnection logic:**

```javascript
class ReconnectingWebSocket {
    constructor(url, options = {}) {
        this.url = url;
        this.options = {
            reconnectInterval: 1000,
            maxReconnectInterval: 30000,
            reconnectDecay: 1.5,
            maxReconnectAttempts: null,
            ...options
        };
        
        this.reconnectAttempts = 0;
        this.reconnectInterval = this.options.reconnectInterval;
        
        this.connect();
    }
    
    connect() {
        console.log('Connecting to', this.url);
        
        this.ws = new WebSocket(this.url);
        
        this.ws.onopen = (event) => {
            console.log('Connected');
            this.reconnectAttempts = 0;
            this.reconnectInterval = this.options.reconnectInterval;
            
            if (this.onopen) this.onopen(event);
        };
        
        this.ws.onmessage = (event) => {
            if (this.onmessage) this.onmessage(event);
        };
        
        this.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
            if (this.onerror) this.onerror(error);
        };
        
        this.ws.onclose = (event) => {
            console.log('Connection closed');
            
            if (this.onclose) this.onclose(event);
            
            // Attempt reconnect
            if (
                this.options.maxReconnectAttempts === null ||
                this.reconnectAttempts < this.options.maxReconnectAttempts
            ) {
                this.reconnect();
            }
        };
    }
    
    reconnect() {
        this.reconnectAttempts++;
        
        console.log(
            `Reconnecting in ${this.reconnectInterval}ms (attempt ${this.reconnectAttempts})`
        );
        
        setTimeout(() => {
            this.connect();
        }, this.reconnectInterval);
        
        // Exponential backoff
        this.reconnectInterval = Math.min(
            this.reconnectInterval * this.options.reconnectDecay,
            this.options.maxReconnectInterval
        );
    }
    
    send(data) {
        if (this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(data);
        } else {
            console.error('Cannot send, socket not open');
        }
    }
    
    close() {
        this.ws.close();
    }
}

// Usage
const socket = new ReconnectingWebSocket('ws://localhost:8080', {
    reconnectInterval: 1000,
    maxReconnectInterval: 30000,
    reconnectDecay: 1.5
});

socket.onopen = () => {
    console.log('Ready!');
};

socket.onmessage = (event) => {
    console.log('Message:', event.data);
};

socket.send('Hello!');
```

---

## 27.4 Server Implementation

### 27.4.1 - Node.js ws Library

**Installation:**

```bash
npm install ws
```

**Basic server:**

```javascript
const WebSocket = require('ws');

// Create WebSocket server
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws, request) => {
    const clientIp = request.socket.remoteAddress;
    console.log('New connection from', clientIp);
    
    // Send welcome message
    ws.send(JSON.stringify({
        type: 'welcome',
        message: 'Connected to server'
    }));
    
    // Listen for messages
    ws.on('message', (data) => {
        console.log('Received:', data.toString());
        
        // Echo back
        ws.send(`Echo: ${data}`);
    });
    
    // Handle errors
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
    
    // Connection closed
    ws.on('close', (code, reason) => {
        console.log('Client disconnected:', code, reason.toString());
    });
    
    // Ping/Pong (keep-alive)
    ws.on('pong', () => {
        ws.isAlive = true;
    });
});

// Heartbeat (detect dead connections)
const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
        if (ws.isAlive === false) {
            console.log('Terminating dead connection');
            return ws.terminate();
        }
        
        ws.isAlive = false;
        ws.ping();
    });
}, 30000);

wss.on('close', () => {
    clearInterval(interval);
});

console.log('WebSocket server running on ws://localhost:8080');
```

### 27.4.2 - Broadcasting

**Send to all connected clients:**

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

// Broadcast to all clients
const broadcast = (data) => {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
};

// Broadcast to all except sender
const broadcastExcept = (data, sender) => {
    wss.clients.forEach((client) => {
        if (client !== sender && client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
};

wss.on('connection', (ws) => {
    console.log('New client connected');
    console.log('Total clients:', wss.clients.size);
    
    // Notify all about new user
    broadcast(JSON.stringify({
        type: 'user-joined',
        count: wss.clients.size
    }));
    
    ws.on('message', (data) => {
        const message = JSON.parse(data);
        
        if (message.type === 'chat') {
            // Broadcast chat message to all except sender
            broadcastExcept(JSON.stringify({
                type: 'chat',
                user: message.user,
                text: message.text,
                timestamp: Date.now()
            }), ws);
        }
    });
    
    ws.on('close', () => {
        console.log('Client disconnected');
        
        // Notify remaining clients
        broadcast(JSON.stringify({
            type: 'user-left',
            count: wss.clients.size
        }));
    });
});
```

### 27.4.3 - Rooms/Channels

**Chat with multiple rooms:**

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const rooms = new Map();

// Join room
const joinRoom = (ws, roomName) => {
    if (!rooms.has(roomName)) {
        rooms.set(roomName, new Set());
    }
    
    rooms.get(roomName).add(ws);
    ws.currentRoom = roomName;
    
    console.log(`Client joined room: ${roomName}`);
};

// Leave room
const leaveRoom = (ws) => {
    if (ws.currentRoom) {
        const room = rooms.get(ws.currentRoom);
        if (room) {
            room.delete(ws);
            
            // Delete empty rooms
            if (room.size === 0) {
                rooms.delete(ws.currentRoom);
            }
        }
        
        ws.currentRoom = null;
    }
};

// Broadcast to room
const broadcastToRoom = (roomName, data, sender = null) => {
    const room = rooms.get(roomName);
    
    if (room) {
        room.forEach((client) => {
            if (client !== sender && client.readyState === WebSocket.OPEN) {
                client.send(data);
            }
        });
    }
};

wss.on('connection', (ws) => {
    ws.on('message', (data) => {
        const message = JSON.parse(data);
        
        switch (message.type) {
            case 'join':
                leaveRoom(ws); // Leave current room
                joinRoom(ws, message.room);
                
                ws.send(JSON.stringify({
                    type: 'joined',
                    room: message.room
                }));
                
                broadcastToRoom(message.room, JSON.stringify({
                    type: 'user-joined',
                    user: message.user
                }), ws);
                break;
            
            case 'message':
                broadcastToRoom(ws.currentRoom, JSON.stringify({
                    type: 'message',
                    user: message.user,
                    text: message.text,
                    timestamp: Date.now()
                }), ws);
                break;
            
            case 'leave':
                broadcastToRoom(ws.currentRoom, JSON.stringify({
                    type: 'user-left',
                    user: message.user
                }), ws);
                
                leaveRoom(ws);
                break;
        }
    });
    
    ws.on('close', () => {
        leaveRoom(ws);
    });
});
```

---

## 27.5 Authentication & Security

### 27.5.1 - Token-Based Authentication

**Client sends token in URL:**

```javascript
// Client
const token = 'jwt-token-here';
const socket = new WebSocket(`ws://localhost:8080?token=${token}`);
```

**Server validates token:**

```javascript
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');

const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws, request) => {
    // Parse token from URL
    const url = new URL(request.url, 'ws://localhost:8080');
    const token = url.searchParams.get('token');
    
    if (!token) {
        ws.close(1008, 'Token required');
        return;
    }
    
    // Verify token
    try {
        const user = jwt.verify(token, 'secret-key');
        ws.user = user;
        
        console.log('Authenticated user:', user.username);
        
        ws.send(JSON.stringify({
            type: 'authenticated',
            user: user.username
        }));
    } catch (error) {
        console.error('Invalid token');
        ws.close(1008, 'Invalid token');
        return;
    }
    
    // Handle messages
    ws.on('message', (data) => {
        // ws.user is available here
        console.log(`Message from ${ws.user.username}:`, data.toString());
    });
});
```

**Alternative: Header-based authentication:**

```javascript
// Client (using custom library that supports headers)
const socket = new WebSocket('ws://localhost:8080', {
    headers: {
        'Authorization': `Bearer ${token}`
    }
});

// Server
wss.on('connection', (ws, request) => {
    const authHeader = request.headers['authorization'];
    
    if (!authHeader) {
        ws.close(1008, 'Authorization required');
        return;
    }
    
    const token = authHeader.split(' ')[1];
    
    try {
        const user = jwt.verify(token, 'secret-key');
        ws.user = user;
    } catch (error) {
        ws.close(1008, 'Invalid token');
    }
});
```

### 27.5.2 - Rate Limiting

**Prevent spam:**

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

const MESSAGE_LIMIT = 10;
const WINDOW_MS = 60000; // 1 minute

wss.on('connection', (ws) => {
    ws.messageCount = 0;
    ws.lastReset = Date.now();
    
    ws.on('message', (data) => {
        const now = Date.now();
        
        // Reset counter every minute
        if (now - ws.lastReset > WINDOW_MS) {
            ws.messageCount = 0;
            ws.lastReset = now;
        }
        
        // Check limit
        if (ws.messageCount >= MESSAGE_LIMIT) {
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Rate limit exceeded'
            }));
            return;
        }
        
        ws.messageCount++;
        
        // Process message
        console.log('Message:', data.toString());
    });
});
```

---

## 27.6 Express.js Integration

### 27.6.1 - WebSocket + HTTP Server

**Share same server:**

```javascript
const express = require('express');
const http = require('http');
const WebSocket = require('ws');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// HTTP routes
app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

app.get('/api/stats', (req, res) => {
    res.json({
        connections: wss.clients.size
    });
});

// WebSocket
wss.on('connection', (ws) => {
    console.log('WebSocket client connected');
    
    ws.on('message', (data) => {
        console.log('Received:', data.toString());
    });
});

// Start server
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`HTTP server on http://localhost:${PORT}`);
    console.log(`WebSocket server on ws://localhost:${PORT}`);
});
```

### 27.6.2 - Socket.IO (High-Level Library)

**Socket.IO features:**
- Auto-reconnection
- Rooms/namespaces
- Broadcasting
- Fallback to HTTP polling (if WebSocket not available)

**Installation:**

```bash
npm install socket.io
```

**Server:**

```javascript
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.get('/', (req, res) => {
    res.sendFile(__dirname + '/index.html');
});

// Socket.IO events
io.on('connection', (socket) => {
    console.log('User connected:', socket.id);
    
    // Join room
    socket.on('join-room', (room) => {
        socket.join(room);
        console.log(`${socket.id} joined ${room}`);
        
        // Notify room
        io.to(room).emit('user-joined', {
            userId: socket.id,
            timestamp: Date.now()
        });
    });
    
    // Broadcast to room
    socket.on('message', ({ room, text }) => {
        io.to(room).emit('message', {
            userId: socket.id,
            text,
            timestamp: Date.now()
        });
    });
    
    // Private message
    socket.on('private-message', ({ to, text }) => {
        io.to(to).emit('private-message', {
            from: socket.id,
            text,
            timestamp: Date.now()
        });
    });
    
    // Disconnect
    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

server.listen(3000, () => {
    console.log('Server running on http://localhost:3000');
});
```

**Client:**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Socket.IO Chat</title>
</head>
<body>
    <div id="messages"></div>
    <input id="message-input" type="text" placeholder="Type message...">
    <button id="send-btn">Send</button>
    
    <script src="/socket.io/socket.io.js"></script>
    <script>
        const socket = io();
        
        const room = 'general';
        
        // Connect
        socket.on('connect', () => {
            console.log('Connected');
            socket.emit('join-room', room);
        });
        
        // Join confirmation
        socket.on('user-joined', (data) => {
            console.log('User joined:', data);
        });
        
        // Receive message
        socket.on('message', (data) => {
            const messagesDiv = document.getElementById('messages');
            const messageEl = document.createElement('div');
            messageEl.textContent = `${data.userId}: ${data.text}`;
            messagesDiv.appendChild(messageEl);
        });
        
        // Send message
        document.getElementById('send-btn').addEventListener('click', () => {
            const input = document.getElementById('message-input');
            const text = input.value;
            
            if (text) {
                socket.emit('message', { room, text });
                input.value = '';
            }
        });
    </script>
</body>
</html>
```

---

## 27.7 Production Deployment

### 27.7.1 - Nginx Proxy

**Nginx WebSocket proxy:**

```nginx
http {
    upstream websocket_backend {
        server localhost:8080;
        server localhost:8081;
        server localhost:8082;
    }
    
    server {
        listen 443 ssl http2;
        server_name example.com;
        
        ssl_certificate /etc/ssl/certs/example.com.crt;
        ssl_certificate_key /etc/ssl/private/example.com.key;
        
        # WebSocket endpoint
        location /ws {
            proxy_pass http://websocket_backend;
            
            # WebSocket headers
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            
            # Preserve client info
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts (long-lived connections)
            proxy_read_timeout 3600s;
            proxy_send_timeout 3600s;
        }
        
        # HTTP endpoints
        location / {
            proxy_pass http://websocket_backend;
            proxy_set_header Host $host;
        }
    }
}
```

### 27.7.2 - Horizontal Scaling (Redis Adapter)

**Problem: Multiple server instances:**

```
User A → Server 1
User B → Server 2

User A sends message → Only reaches Server 1 clients!
User B doesn't receive it (connected to Server 2)
```

**Solution: Redis pub/sub:**

```bash
npm install redis socket.io-redis
```

```javascript
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const { createAdapter } = require('@socket.io/redis-adapter');
const { createClient } = require('redis');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Redis clients
const pubClient = createClient({ host: 'localhost', port: 6379 });
const subClient = pubClient.duplicate();

Promise.all([pubClient.connect(), subClient.connect()]).then(() => {
    // Attach Redis adapter
    io.adapter(createAdapter(pubClient, subClient));
    
    console.log('Redis adapter attached');
});

io.on('connection', (socket) => {
    socket.on('message', (data) => {
        // Broadcast to ALL servers via Redis
        io.emit('message', data);
    });
});

server.listen(3000);
```

**Now messages propagate across all server instances!**

---

## 27.8 Monitoring & Debugging

### 27.8.1 - Metrics

**Track WebSocket metrics:**

```javascript
const WebSocket = require('ws');
const prometheus = require('prom-client');

const wss = new WebSocket.Server({ port: 8080 });

// Metrics
const connections = new prometheus.Gauge({
    name: 'websocket_connections',
    help: 'Current WebSocket connections'
});

const messagesReceived = new prometheus.Counter({
    name: 'websocket_messages_received_total',
    help: 'Total messages received'
});

const messagesSent = new prometheus.Counter({
    name: 'websocket_messages_sent_total',
    help: 'Total messages sent'
});

wss.on('connection', (ws) => {
    connections.inc();
    
    ws.on('message', (data) => {
        messagesReceived.inc();
    });
    
    // Override send
    const originalSend = ws.send.bind(ws);
    ws.send = (data, ...args) => {
        messagesSent.inc();
        return originalSend(data, ...args);
    };
    
    ws.on('close', () => {
        connections.dec();
    });
});

// Metrics endpoint
const express = require('express');
const app = express();

app.get('/metrics', async (req, res) => {
    res.set('Content-Type', prometheus.register.contentType);
    res.end(await prometheus.register.metrics());
});

app.listen(9090);
```

---

## 27.9 Best Practices

**Complete production WebSocket server:**

```javascript
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Security
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100
});
app.use(limiter);

// WebSocket connection
wss.on('connection', (ws, request) => {
    // Authentication
    const url = new URL(request.url, 'ws://localhost');
    const token = url.searchParams.get('token');
    
    try {
        const user = jwt.verify(token, process.env.JWT_SECRET);
        ws.user = user;
    } catch (error) {
        ws.close(1008, 'Invalid token');
        return;
    }
    
    // Rate limiting
    ws.messageCount = 0;
    ws.lastReset = Date.now();
    
    // Heartbeat
    ws.isAlive = true;
    ws.on('pong', () => {
        ws.isAlive = true;
    });
    
    ws.on('message', (data) => {
        // Rate limit check
        const now = Date.now();
        if (now - ws.lastReset > 60000) {
            ws.messageCount = 0;
            ws.lastReset = now;
        }
        
        if (ws.messageCount >= 10) {
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Rate limit exceeded'
            }));
            return;
        }
        
        ws.messageCount++;
        
        // Process message
        try {
            const message = JSON.parse(data);
            handleMessage(ws, message);
        } catch (error) {
            ws.send(JSON.stringify({
                type: 'error',
                message: 'Invalid JSON'
            }));
        }
    });
    
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
    
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

// Heartbeat interval
const interval = setInterval(() => {
    wss.clients.forEach((ws) => {
        if (!ws.isAlive) {
            return ws.terminate();
        }
        
        ws.isAlive = false;
        ws.ping();
    });
}, 30000);

wss.on('close', () => {
    clearInterval(interval);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server...');
    
    server.close(() => {
        console.log('HTTP server closed');
    });
    
    wss.clients.forEach((ws) => {
        ws.close(1001, 'Server shutting down');
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

---

**Capitolo 27 completato!**

Hai completato i capitoli 24-27! 🎉
