# 31. Progressive Web Apps (PWA) e Service Workers

## 31.1 Introduzione alle PWA

**Progressive Web App (PWA)** è un'applicazione web che utilizza moderne API per offrire funzionalità simili alle app native.

**Caratteristiche PWA:**

```
1. Progressive
   Funziona per tutti gli utenti, indipendentemente dal browser

2. Responsive
   Si adatta a qualsiasi form factor: desktop, mobile, tablet

3. Offline-first
   Funziona anche senza connessione internet

4. App-like
   Interazione simile a un'app native

5. Fresh
   Sempre aggiornata grazie ai service worker

6. Safe
   Servita via HTTPS per prevenire attacchi

7. Discoverable
   Identificabile come "applicazione" dai motori di ricerca

8. Re-engageable
   Notifiche push per aumentare engagement

9. Installable
   Può essere installata sulla home screen

10. Linkable
    Condivisibile tramite URL
```

---

## 31.2 Service Worker Fundamentals

### 31.2.1 - Service Worker Lifecycle

**Lifecycle states:**

```
1. Registration
   navigator.serviceWorker.register('/sw.js')

2. Installation
   self.addEventListener('install', event => {})

3. Activation
   self.addEventListener('activate', event => {})

4. Idle
   Worker is waiting for events

5. Fetch/Message
   Worker handles events

6. Termination
   Browser terminates to save memory
```

**Lifecycle diagram:**

```
Register → Installing → Installed → Activating → Activated → Redundant
                ↓           ↓           ↓
              install    waiting    activate
              event                  event
```

### 31.2.2 - Basic Service Worker

**Register service worker:**

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My PWA</title>
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/icon.png">
</head>
<body>
    <h1>Progressive Web App</h1>
    <p>Check Console for Service Worker status</p>
    
    <script>
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', async () => {
                try {
                    const registration = await navigator.serviceWorker.register('/sw.js');
                    
                    console.log('Service Worker registered:', registration.scope);
                    
                    // Check for updates
                    registration.addEventListener('updatefound', () => {
                        const newWorker = registration.installing;
                        
                        newWorker.addEventListener('statechange', () => {
                            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                                console.log('New version available! Refresh to update.');
                            }
                        });
                    });
                } catch (error) {
                    console.error('Service Worker registration failed:', error);
                }
            });
        } else {
            console.warn('Service Workers not supported');
        }
    </script>
</body>
</html>
```

**Basic service worker:**

```javascript
// sw.js
const CACHE_NAME = 'my-pwa-v1';

const urlsToCache = [
    '/',
    '/index.html',
    '/styles.css',
    '/app.js',
    '/icon.png'
];

// Install event - cache resources
self.addEventListener('install', event => {
    console.log('Service Worker installing...');
    
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('Opened cache');
                return cache.addAll(urlsToCache);
            })
    );
    
    // Force activation
    self.skipWaiting();
});

// Activate event - clean old caches
self.addEventListener('activate', event => {
    console.log('Service Worker activating...');
    
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(cacheName => cacheName !== CACHE_NAME)
                    .map(cacheName => {
                        console.log('Deleting old cache:', cacheName);
                        return caches.delete(cacheName);
                    })
            );
        })
    );
    
    // Take control immediately
    return self.clients.claim();
});

// Fetch event - serve from cache
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(response => {
                // Cache hit - return response
                if (response) {
                    return response;
                }
                
                // Clone request
                const fetchRequest = event.request.clone();
                
                return fetch(fetchRequest).then(response => {
                    // Check if valid response
                    if (!response || response.status !== 200 || response.type !== 'basic') {
                        return response;
                    }
                    
                    // Clone response
                    const responseToCache = response.clone();
                    
                    caches.open(CACHE_NAME)
                        .then(cache => {
                            cache.put(event.request, responseToCache);
                        });
                    
                    return response;
                });
            })
    );
});
```

---

## 31.3 Caching Strategies

### 31.3.1 - Cache-First Strategy

**Serve from cache, fallback to network:**

```javascript
// sw.js
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.match(event.request)
            .then(cachedResponse => {
                if (cachedResponse) {
                    return cachedResponse;
                }
                
                return fetch(event.request).then(response => {
                    // Cache new responses
                    return caches.open(CACHE_NAME).then(cache => {
                        cache.put(event.request, response.clone());
                        return response;
                    });
                });
            })
            .catch(() => {
                // Return offline page if both cache and network fail
                return caches.match('/offline.html');
            })
    );
});
```

### 31.3.2 - Network-First Strategy

**Try network first, fallback to cache:**

```javascript
self.addEventListener('fetch', event => {
    event.respondWith(
        fetch(event.request)
            .then(response => {
                // Update cache with fresh response
                return caches.open(CACHE_NAME).then(cache => {
                    cache.put(event.request, response.clone());
                    return response;
                });
            })
            .catch(() => {
                // Network failed, try cache
                return caches.match(event.request);
            })
    );
});
```

### 31.3.3 - Stale-While-Revalidate

**Return cached response immediately, update cache in background:**

```javascript
self.addEventListener('fetch', event => {
    event.respondWith(
        caches.open(CACHE_NAME).then(cache => {
            return cache.match(event.request).then(cachedResponse => {
                const fetchPromise = fetch(event.request).then(networkResponse => {
                    // Update cache in background
                    cache.put(event.request, networkResponse.clone());
                    return networkResponse;
                });
                
                // Return cached response immediately, or wait for network
                return cachedResponse || fetchPromise;
            });
        })
    );
});
```

### 31.3.4 - Advanced Routing

**Different strategies for different resources:**

```javascript
// sw.js
const CACHE_NAME = 'my-pwa-v1';
const API_CACHE = 'api-cache-v1';
const IMG_CACHE = 'img-cache-v1';

self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);
    
    // API requests - Network-first
    if (url.pathname.startsWith('/api/')) {
        event.respondWith(
            fetch(request)
                .then(response => {
                    const clone = response.clone();
                    caches.open(API_CACHE).then(cache => cache.put(request, clone));
                    return response;
                })
                .catch(() => caches.match(request))
        );
        return;
    }
    
    // Images - Cache-first with expiration
    if (request.destination === 'image') {
        event.respondWith(
            caches.open(IMG_CACHE).then(cache => {
                return cache.match(request).then(cached => {
                    if (cached) {
                        // Check if cached image is still fresh (7 days)
                        const cachedDate = new Date(cached.headers.get('date'));
                        const now = new Date();
                        const age = (now - cachedDate) / 1000 / 60 / 60 / 24; // days
                        
                        if (age < 7) {
                            return cached;
                        }
                    }
                    
                    return fetch(request).then(response => {
                        cache.put(request, response.clone());
                        return response;
                    });
                });
            })
        );
        return;
    }
    
    // Static assets - Cache-first
    if (request.destination === 'style' || request.destination === 'script') {
        event.respondWith(
            caches.match(request)
                .then(cached => cached || fetch(request))
        );
        return;
    }
    
    // Everything else - Stale-while-revalidate
    event.respondWith(
        caches.match(request).then(cached => {
            const fetchPromise = fetch(request).then(response => {
                caches.open(CACHE_NAME).then(cache => cache.put(request, response.clone()));
                return response;
            });
            
            return cached || fetchPromise;
        })
    );
});
```

---

## 31.4 Web App Manifest

### 31.4.1 - Complete Manifest

**manifest.json:**

```json
{
  "name": "My Progressive Web App",
  "short_name": "MyPWA",
  "description": "A complete PWA example",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#2196F3",
  "orientation": "portrait-primary",
  "scope": "/",
  "icons": [
    {
      "src": "/icons/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icons/icon-96x96.png",
      "sizes": "96x96",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-128x128.png",
      "sizes": "128x128",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png"
    },
    {
      "src": "/icons/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ],
  "shortcuts": [
    {
      "name": "Dashboard",
      "short_name": "Dashboard",
      "description": "Open dashboard",
      "url": "/dashboard",
      "icons": [{ "src": "/icons/dashboard.png", "sizes": "192x192" }]
    },
    {
      "name": "Profile",
      "short_name": "Profile",
      "description": "View profile",
      "url": "/profile",
      "icons": [{ "src": "/icons/profile.png", "sizes": "192x192" }]
    }
  ],
  "categories": ["productivity", "utilities"],
  "screenshots": [
    {
      "src": "/screenshots/desktop.png",
      "sizes": "1280x720",
      "type": "image/png",
      "form_factor": "wide"
    },
    {
      "src": "/screenshots/mobile.png",
      "sizes": "750x1334",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ]
}
```

### 31.4.2 - Install Prompt

**Handle install prompt:**

```javascript
// app.js
let deferredPrompt;

window.addEventListener('beforeinstallprompt', (e) => {
    // Prevent default browser install prompt
    e.preventDefault();
    
    // Store event for later use
    deferredPrompt = e;
    
    // Show custom install button
    const installButton = document.getElementById('installButton');
    installButton.style.display = 'block';
    
    installButton.addEventListener('click', async () => {
        // Hide button
        installButton.style.display = 'none';
        
        // Show install prompt
        deferredPrompt.prompt();
        
        // Wait for user choice
        const { outcome } = await deferredPrompt.userChoice;
        
        console.log(`User response: ${outcome}`);
        
        // Clear prompt
        deferredPrompt = null;
    });
});

// Track installation
window.addEventListener('appinstalled', (e) => {
    console.log('PWA installed successfully');
    
    // Track in analytics
    gtag('event', 'pwa_install', {
        event_category: 'engagement'
    });
});
```

---

## 31.5 Background Sync

### 31.5.1 - Basic Background Sync

**Register sync event:**

```javascript
// app.js
async function submitForm(data) {
    try {
        await fetch('/api/submit', {
            method: 'POST',
            body: JSON.stringify(data),
            headers: { 'Content-Type': 'application/json' }
        });
        
        console.log('Submitted successfully');
    } catch (error) {
        // Save to IndexedDB for later sync
        await saveToIndexedDB(data);
        
        // Register background sync
        const registration = await navigator.serviceWorker.ready;
        await registration.sync.register('submit-form');
        
        console.log('Form saved, will sync when online');
    }
}
```

**Handle sync in service worker:**

```javascript
// sw.js
self.addEventListener('sync', event => {
    if (event.tag === 'submit-form') {
        event.waitUntil(syncForms());
    }
});

async function syncForms() {
    const forms = await getFormsFromIndexedDB();
    
    for (const form of forms) {
        try {
            const response = await fetch('/api/submit', {
                method: 'POST',
                body: JSON.stringify(form),
                headers: { 'Content-Type': 'application/json' }
            });
            
            if (response.ok) {
                await removeFromIndexedDB(form.id);
                console.log('Form synced:', form.id);
            }
        } catch (error) {
            console.error('Sync failed for form:', form.id);
        }
    }
}
```

### 31.5.2 - Periodic Background Sync

**Register periodic sync:**

```javascript
// app.js
async function registerPeriodicSync() {
    const registration = await navigator.serviceWorker.ready;
    
    if ('periodicSync' in registration) {
        try {
            await registration.periodicSync.register('update-content', {
                minInterval: 24 * 60 * 60 * 1000 // 24 hours
            });
            
            console.log('Periodic sync registered');
        } catch (error) {
            console.error('Periodic sync registration failed:', error);
        }
    }
}
```

**Handle periodic sync:**

```javascript
// sw.js
self.addEventListener('periodicsync', event => {
    if (event.tag === 'update-content') {
        event.waitUntil(updateContent());
    }
});

async function updateContent() {
    try {
        const response = await fetch('/api/latest');
        const data = await response.json();
        
        // Update cache
        const cache = await caches.open('content-cache-v1');
        await cache.put('/api/latest', new Response(JSON.stringify(data)));
        
        console.log('Content updated in background');
    } catch (error) {
        console.error('Background update failed:', error);
    }
}
```

---

## 31.6 Push Notifications

### 31.6.1 - Request Permission

**Request notification permission:**

```javascript
// app.js
async function requestNotificationPermission() {
    const permission = await Notification.requestPermission();
    
    if (permission === 'granted') {
        console.log('Notification permission granted');
        await subscribeUserToPush();
    } else {
        console.log('Notification permission denied');
    }
}

async function subscribeUserToPush() {
    const registration = await navigator.serviceWorker.ready;
    
    // Public VAPID key from server
    const publicKey = 'YOUR_PUBLIC_VAPID_KEY';
    
    const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey)
    });
    
    // Send subscription to server
    await fetch('/api/push-subscribe', {
        method: 'POST',
        body: JSON.stringify(subscription),
        headers: { 'Content-Type': 'application/json' }
    });
    
    console.log('Push subscription:', subscription);
}

function urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
        .replace(/-/g, '+')
        .replace(/_/g, '/');
    
    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);
    
    for (let i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i);
    }
    
    return outputArray;
}
```

### 31.6.2 - Handle Push Events

**Service worker push handler:**

```javascript
// sw.js
self.addEventListener('push', event => {
    let data = {
        title: 'Default Title',
        body: 'Default message',
        icon: '/icon.png',
        badge: '/badge.png'
    };
    
    if (event.data) {
        data = event.data.json();
    }
    
    const options = {
        body: data.body,
        icon: data.icon,
        badge: data.badge,
        vibrate: [100, 50, 100],
        data: {
            dateOfArrival: Date.now(),
            primaryKey: data.id
        },
        actions: [
            { action: 'view', title: 'View' },
            { action: 'close', title: 'Close' }
        ]
    };
    
    event.waitUntil(
        self.registration.showNotification(data.title, options)
    );
});

// Handle notification click
self.addEventListener('notificationclick', event => {
    event.notification.close();
    
    if (event.action === 'view') {
        event.waitUntil(
            clients.openWindow('/notifications/' + event.notification.data.primaryKey)
        );
    }
});
```

### 31.6.3 - Server-Side Push

**Node.js server with web-push:**

```javascript
const express = require('express');
const webpush = require('web-push');

const app = express();
app.use(express.json());

// VAPID keys (generate with: web-push generate-vapid-keys)
const vapidKeys = {
    publicKey: process.env.VAPID_PUBLIC_KEY,
    privateKey: process.env.VAPID_PRIVATE_KEY
};

webpush.setVapidDetails(
    'mailto:your-email@example.com',
    vapidKeys.publicKey,
    vapidKeys.privateKey
);

// Store subscriptions (use database in production)
const subscriptions = [];

// Subscribe endpoint
app.post('/api/push-subscribe', (req, res) => {
    const subscription = req.body;
    subscriptions.push(subscription);
    
    console.log('New subscription:', subscription.endpoint);
    res.status(201).json({ message: 'Subscription saved' });
});

// Send notification to all subscribers
app.post('/api/push-notify', async (req, res) => {
    const { title, body } = req.body;
    
    const payload = JSON.stringify({
        title,
        body,
        icon: '/icon.png',
        badge: '/badge.png'
    });
    
    const results = await Promise.allSettled(
        subscriptions.map(subscription => 
            webpush.sendNotification(subscription, payload)
                .catch(error => {
                    if (error.statusCode === 410) {
                        // Subscription expired, remove it
                        const index = subscriptions.indexOf(subscription);
                        subscriptions.splice(index, 1);
                    }
                })
        )
    );
    
    const sent = results.filter(r => r.status === 'fulfilled').length;
    res.json({ message: `Sent to ${sent} subscribers` });
});

app.listen(3000);
```

---

## 31.7 IndexedDB Storage

### 31.7.1 - IndexedDB Wrapper

**Simple IndexedDB wrapper:**

```javascript
// db.js
class Database {
    constructor(dbName, version = 1) {
        this.dbName = dbName;
        this.version = version;
        this.db = null;
    }
    
    async open(stores) {
        return new Promise((resolve, reject) => {
            const request = indexedDB.open(this.dbName, this.version);
            
            request.onerror = () => reject(request.error);
            request.onsuccess = () => {
                this.db = request.result;
                resolve(this.db);
            };
            
            request.onupgradeneeded = (event) => {
                const db = event.target.result;
                
                stores.forEach(store => {
                    if (!db.objectStoreNames.contains(store.name)) {
                        const objectStore = db.createObjectStore(store.name, {
                            keyPath: store.keyPath || 'id',
                            autoIncrement: store.autoIncrement || true
                        });
                        
                        // Create indexes
                        if (store.indexes) {
                            store.indexes.forEach(index => {
                                objectStore.createIndex(index.name, index.keyPath, {
                                    unique: index.unique || false
                                });
                            });
                        }
                    }
                });
            };
        });
    }
    
    async add(storeName, data) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return new Promise((resolve, reject) => {
            const request = store.add(data);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }
    
    async get(storeName, key) {
        const tx = this.db.transaction(storeName, 'readonly');
        const store = tx.objectStore(storeName);
        return new Promise((resolve, reject) => {
            const request = store.get(key);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }
    
    async getAll(storeName) {
        const tx = this.db.transaction(storeName, 'readonly');
        const store = tx.objectStore(storeName);
        return new Promise((resolve, reject) => {
            const request = store.getAll();
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }
    
    async put(storeName, data) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return new Promise((resolve, reject) => {
            const request = store.put(data);
            request.onsuccess = () => resolve(request.result);
            request.onerror = () => reject(request.error);
        });
    }
    
    async delete(storeName, key) {
        const tx = this.db.transaction(storeName, 'readwrite');
        const store = tx.objectStore(storeName);
        return new Promise((resolve, reject) => {
            const request = store.delete(key);
            request.onsuccess = () => resolve();
            request.onerror = () => reject(request.error);
        });
    }
}

// Usage
const db = new Database('MyPWA', 1);

await db.open([
    {
        name: 'todos',
        keyPath: 'id',
        autoIncrement: true,
        indexes: [
            { name: 'status', keyPath: 'status' },
            { name: 'created', keyPath: 'createdAt' }
        ]
    }
]);

// Add
await db.add('todos', {
    title: 'Learn PWA',
    status: 'pending',
    createdAt: Date.now()
});

// Get all
const todos = await db.getAll('todos');
console.log(todos);
```

---

## 31.8 Complete PWA Example

**Full offline-capable todo app:**

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Todo PWA</title>
    <link rel="manifest" href="/manifest.json">
    <link rel="icon" href="/icon.png">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: Arial, sans-serif; padding: 20px; max-width: 600px; margin: 0 auto; }
        h1 { margin-bottom: 20px; }
        #addTodo { display: flex; gap: 10px; margin-bottom: 20px; }
        #addTodo input { flex: 1; padding: 10px; font-size: 16px; }
        #addTodo button { padding: 10px 20px; background: #2196F3; color: white; border: none; cursor: pointer; }
        .todo { display: flex; align-items: center; gap: 10px; padding: 10px; border-bottom: 1px solid #eee; }
        .todo.completed span { text-decoration: line-through; opacity: 0.6; }
        .todo span { flex: 1; }
        .todo button { background: #f44336; color: white; border: none; padding: 5px 10px; cursor: pointer; }
        #status { padding: 10px; background: #4CAF50; color: white; margin-bottom: 20px; border-radius: 4px; }
    </style>
</head>
<body>
    <div id="status">Online</div>
    <h1>Todo PWA</h1>
    
    <div id="addTodo">
        <input type="text" id="todoInput" placeholder="Add new todo...">
        <button onclick="addTodo()">Add</button>
    </div>
    
    <div id="todoList"></div>
    
    <script src="/db.js"></script>
    <script src="/app.js"></script>
</body>
</html>
```

```javascript
// app.js
const db = new Database('TodoPWA', 1);
let todos = [];

// Initialize
(async function init() {
    await db.open([
        {
            name: 'todos',
            keyPath: 'id',
            autoIncrement: true
        }
    ]);
    
    await loadTodos();
    renderTodos();
    
    // Register service worker
    if ('serviceWorker' in navigator) {
        await navigator.serviceWorker.register('/sw.js');
        console.log('Service Worker registered');
    }
    
    // Online/offline status
    updateOnlineStatus();
    window.addEventListener('online', updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);
})();

function updateOnlineStatus() {
    const status = document.getElementById('status');
    if (navigator.onLine) {
        status.textContent = 'Online';
        status.style.background = '#4CAF50';
        syncTodos();
    } else {
        status.textContent = 'Offline - Changes will sync when online';
        status.style.background = '#FF9800';
    }
}

async function loadTodos() {
    todos = await db.getAll('todos');
}

function renderTodos() {
    const list = document.getElementById('todoList');
    list.innerHTML = todos.map(todo => `
        <div class="todo ${todo.completed ? 'completed' : ''}">
            <input type="checkbox" 
                   ${todo.completed ? 'checked' : ''}
                   onchange="toggleTodo(${todo.id})">
            <span>${todo.title}</span>
            <button onclick="deleteTodo(${todo.id})">Delete</button>
        </div>
    `).join('');
}

async function addTodo() {
    const input = document.getElementById('todoInput');
    const title = input.value.trim();
    
    if (!title) return;
    
    const todo = {
        title,
        completed: false,
        createdAt: Date.now(),
        synced: false
    };
    
    const id = await db.add('todos', todo);
    todo.id = id;
    todos.push(todo);
    
    input.value = '';
    renderTodos();
    
    // Sync to server if online
    if (navigator.onLine) {
        syncTodos();
    }
}

async function toggleTodo(id) {
    const todo = todos.find(t => t.id === id);
    todo.completed = !todo.completed;
    todo.synced = false;
    
    await db.put('todos', todo);
    renderTodos();
    
    if (navigator.onLine) {
        syncTodos();
    }
}

async function deleteTodo(id) {
    todos = todos.filter(t => t.id !== id);
    await db.delete('todos', id);
    renderTodos();
    
    if (navigator.onLine) {
        syncTodos();
    }
}

async function syncTodos() {
    const unsyncedTodos = todos.filter(t => !t.synced);
    
    for (const todo of unsyncedTodos) {
        try {
            await fetch('/api/todos', {
                method: 'POST',
                body: JSON.stringify(todo),
                headers: { 'Content-Type': 'application/json' }
            });
            
            todo.synced = true;
            await db.put('todos', todo);
        } catch (error) {
            console.error('Sync failed:', error);
        }
    }
}
```

**Service worker:**

```javascript
// sw.js
const CACHE_NAME = 'todo-pwa-v1';
const urlsToCache = [
    '/',
    '/index.html',
    '/app.js',
    '/db.js',
    '/manifest.json',
    '/icon.png'
];

self.addEventListener('install', event => {
    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => cache.addAll(urlsToCache))
    );
    self.skipWaiting();
});

self.addEventListener('activate', event => {
    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(cacheName => cacheName !== CACHE_NAME)
                    .map(cacheName => caches.delete(cacheName))
            );
        })
    );
    return self.clients.claim();
});

self.addEventListener('fetch', event => {
    // API requests - network first
    if (event.request.url.includes('/api/')) {
        event.respondWith(
            fetch(event.request)
                .catch(() => new Response(JSON.stringify({ offline: true })))
        );
        return;
    }
    
    // Static assets - cache first
    event.respondWith(
        caches.match(event.request)
            .then(response => response || fetch(event.request))
    );
});
```

---

**Capitolo 31 completato!**

Abbiamo coperto Service Workers, caching strategies, Web App Manifest, Background Sync, Push Notifications, IndexedDB, e una PWA completa.

Prossimi argomenti suggeriti: Security Headers avanzati, HTTP/3 in produzione, Performance optimization, etc.
