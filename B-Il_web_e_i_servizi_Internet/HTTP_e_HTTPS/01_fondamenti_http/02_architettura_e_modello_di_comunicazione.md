# 2. Architettura e Modello di Comunicazione

## 2.1 Il Modello Client-Server

Il protocollo HTTP si basa sul paradigma **client-server**, un'architettura fondamentale dell'informatica distribuita dove le responsabilità sono nettamente separate tra due entità:

### Definizioni

**Client:**
- Entità che **inizia** la comunicazione
- **Richiede** risorse o servizi
- **Attende** risposte dal server
- Tipicamente user-facing (browser, app mobile)

**Server:**
- Entità che **risponde** alle richieste
- **Fornisce** risorse o servizi
- **Rimane in ascolto** di nuove richieste
- Tipicamente backend, sempre attivo

### Diagramma del Modello

```
┌───────────────────┐                    ┌───────────────────┐
│                   │                    │                   │
│     CLIENT        │                    │     SERVER        │
│                   │                    │                   │
│ ┌───────────────┐ │                    │ ┌───────────────┐ │
│ │   Browser     │ │   1. REQUEST       │ │  Web Server   │ │
│ │   Mobile App  │ │─────────────────>  │ │  (Apache,     │ │
│ │   CLI Tool    │ │                    │ │   Nginx)      │ │
│ │   Script      │ │   2. RESPONSE      │ │               │ │
│ └───────────────┘ │  <─────────────────│ └───────────────┘ │
│                   │                    │         ▲         │
│  - Invia richieste│                    │         │         │
│  - Mostra UI      │                    │         ▼         │
│  - Gestisce input │                    │ ┌───────────────┐ │
│                   │                    │ │  Application  │ │
│                   │                    │ │  Backend      │ │
│                   │                    │ │  Database     │ │
│                   │                    │ └───────────────┘ │
└───────────────────┘                    └───────────────────┘
```

### Caratteristiche del Modello Client-Server in HTTP

1. **Asimmetria dei Ruoli**
   ```
   Client: "Voglio /index.html"    → Inizia
   Server: "Ecco /index.html"      → Risponde
   
   Server NON può iniziare una comunicazione con il client!
   (eccezione: HTTP/2 Server Push)
   ```

2. **Relazione Uno-a-Molti**
   ```
   Un Server può servire migliaia di Client contemporaneamente
   
        Client 1 ─┐
        Client 2 ─┤
        Client 3 ─┼──> SERVER
        ...      ─┤
        Client N ─┘
   ```

3. **Indipendenza delle Implementazioni**
   - Il client non sa (e non deve sapere) come il server elabora le richieste
   - Il server non sa quale tipo di client sta facendo la richiesta
   - Comunicano solo tramite il protocollo HTTP standardizzato

4. **Scalabilità**
   - I server possono essere replicati (load balancing)
   - I client sono indipendenti tra loro
   - Nessuna sincronizzazione necessaria tra client diversi

### Esempio Pratico: Caricamento di una Pagina Web

```
1. Utente digita: https://www.example.com

2. CLIENT (Browser):
   ┌─────────────────────────────────────┐
   │ a) Risoluzione DNS                  │
   │    www.example.com → 93.184.216.34  │
   │                                     │
   │ b) Apertura connessione TCP         │
   │    → porta 443 (HTTPS)              │
   │                                     │
   │ c) Handshake TLS                    │
   │    → connessione sicura             │
   │                                     │
   │ d) Invio richiesta HTTP             │
   │    GET / HTTP/1.1                   │
   │    Host: www.example.com            │
   └─────────────────────────────────────┘
                    │
                    ▼
3. SERVER (Web Server):
   ┌─────────────────────────────────────┐
   │ a) Riceve richiesta                 │
   │                                     │
   │ b) Parse della richiesta            │
   │    - Metodo: GET                    │
   │    - Path: /                        │
   │    - Headers: Host, User-Agent, ... │
   │                                     │
   │ c) Elaborazione                     │
   │    - Verifica permessi              │
   │    - Legge file /index.html         │
   │    - Genera risposta                │
   │                                     │
   │ d) Invio risposta HTTP              │
   │    HTTP/1.1 200 OK                  │
   │    Content-Type: text/html          │
   │    <html>...</html>                 │
   └─────────────────────────────────────┘
                    │
                    ▼
4. CLIENT (Browser):
   ┌─────────────────────────────────────┐
   │ a) Riceve risposta                  │
   │                                     │
   │ b) Parse HTML                       │
   │    - Trova <link href="style.css">  │
   │    - Trova <img src="logo.png">     │
   │                                     │
   │ c) Nuove richieste parallele        │
   │    GET /style.css                   │
   │    GET /logo.png                    │
   │                                     │
   │ d) Rendering pagina                 │
   └─────────────────────────────────────┘
```

### Vantaggi del Modello Client-Server

| Vantaggio | Descrizione |
|-----------|-------------|
| **Centralizzazione** | La logica business è centralizzata sul server, facilitando aggiornamenti e manutenzione |
| **Sicurezza** | Il server controlla l'accesso ai dati sensibili e valida tutte le richieste |
| **Scalabilità** | Possibile scalare il server indipendentemente dai client |
| **Manutenibilità** | Aggiornamenti al server sono immediati per tutti i client |
| **Eterogeneità** | Client diversi (web, mobile, IoT) possono usare lo stesso server |
| **Specializzazione** | Client e server possono specializzarsi nei loro compiti specifici |

### Svantaggi e Limitazioni

| Svantaggio | Mitigazione |
|------------|-------------|
| **Single Point of Failure** | Load balancing, ridondanza, failover |
| **Collo di bottiglia** | Caching, CDN, scalabilità orizzontale |
| **Latenza di rete** | Edge computing, HTTP/2, HTTP/3 |
| **Dipendenza dalla connessione** | Service Workers, offline-first, caching |

## 2.2 User Agent e Web Server

### User Agent (Client)

Un **User Agent** è qualsiasi software che agisce per conto dell'utente, inviando richieste HTTP.

#### Tipi di User Agent

1. **Browser Web**
   ```http
   User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 
               (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
   ```
   - Chrome, Firefox, Safari, Edge
   - Interpretano HTML, CSS, JavaScript
   - Gestiscono cookies, storage, cache

2. **Mobile Apps**
   ```http
   User-Agent: MyApp/1.2.3 (iOS 17.0; iPhone14,2)
   ```
   - App native iOS/Android
   - Comunicano con API REST
   - Gestione specifica per mobile

3. **CLI Tools**
   ```http
   User-Agent: curl/7.68.0
   ```
   - curl, wget, httpie
   - Automazione e scripting
   - Testing e debugging

4. **Bot e Crawler**
   ```http
   User-Agent: Googlebot/2.1 (+http://www.google.com/bot.html)
   ```
   - Spider dei motori di ricerca
   - Monitoring tools
   - Scraping tools

5. **Librerie HTTP**
   ```python
   # Python requests
   import requests
   r = requests.get('https://api.example.com/data')
   # User-Agent: python-requests/2.31.0
   ```

#### Responsabilità del User Agent

```
┌─────────────────────────────────────────┐
│         User Agent Duties               │
├─────────────────────────────────────────┤
│ 1. Costruire richieste HTTP valide      │
│    - Metodo corretto                    │
│    - Headers appropriati                │
│    - Body formattato correttamente      │
│                                         │
│ 2. Gestire connessioni di rete         │
│    - DNS resolution                     │
│    - TCP connection                     │
│    - TLS handshake                      │
│                                         │
│ 3. Inviare richieste e ricevere        │
│    risposte                             │
│    - Timeout management                 │
│    - Retry logic                        │
│    - Error handling                     │
│                                         │
│ 4. Interpretare risposte                │
│    - Parse status codes                 │
│    - Process headers                    │
│    - Decode body                        │
│                                         │
│ 5. Gestire stato                        │
│    - Cookies                            │
│    - Cache                              │
│    - Authentication tokens              │
│                                         │
│ 6. Seguire protocollo                   │
│    - Redirect (3xx)                     │
│    - Content negotiation                │
│    - Compression                        │
└─────────────────────────────────────────┘
```

### Web Server

Un **Web Server** è un software che riceve richieste HTTP e fornisce risposte.

#### Web Server Popolari

1. **Apache HTTP Server**
   ```
   - Market share: ~30%
   - Linguaggio: C
   - Modello: Process/thread based
   - Punti di forza: Maturità, modularità, .htaccess
   ```

2. **Nginx**
   ```
   - Market share: ~35%
   - Linguaggio: C
   - Modello: Event-driven, asynchronous
   - Punti di forza: Performance, reverse proxy, load balancing
   ```

3. **Microsoft IIS**
   ```
   - Market share: ~10%
   - Linguaggio: C++
   - Ambiente: Windows
   - Punti di forza: Integrazione Windows, .NET
   ```

4. **LiteSpeed**
   ```
   - Market share: ~5%
   - Compatibilità: Drop-in replacement per Apache
   - Punti di forza: Performance, compatibilità .htaccess
   ```

5. **Application Servers**
   ```javascript
   // Node.js (Express)
   const express = require('express');
   const app = express();
   app.get('/', (req, res) => res.send('Hello World!'));
   app.listen(3000);
   ```

#### Responsabilità del Web Server

```
┌─────────────────────────────────────────┐
│         Web Server Duties               │
├─────────────────────────────────────────┤
│ 1. Ascoltare su porta                   │
│    - Bind su IP:Port (es. :80, :443)   │
│    - Accept connessioni                 │
│                                         │
│ 2. Ricevere e parsare richieste        │
│    - Parse HTTP request                 │
│    - Validate headers                   │
│    - Handle malformed requests          │
│                                         │
│ 3. Routing                              │
│    - Mappare URL a risorse              │
│    - Virtual hosting                    │
│    - URL rewriting                      │
│                                         │
│ 4. Elaborare richieste                  │
│    - Serve file statici                 │
│    - Proxy to application server        │
│    - Execute server-side scripts        │
│                                         │
│ 5. Gestire sicurezza                    │
│    - TLS/SSL termination                │
│    - Authentication                     │
│    - Authorization                      │
│    - Input validation                   │
│                                         │
│ 6. Costruire risposte                   │
│    - Set appropriate status code        │
│    - Add headers                        │
│    - Send body                          │
│                                         │
│ 7. Logging e Monitoring                 │
│    - Access logs                        │
│    - Error logs                         │
│    - Performance metrics                │
└─────────────────────────────────────────┘
```

#### Configurazione Esempio (Nginx)

```nginx
# nginx.conf

# Server per HTTP (redirect a HTTPS)
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$server_name$request_uri;
}

# Server per HTTPS
server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # Certificati SSL
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Root directory
    root /var/www/html;
    index index.html index.htm;

    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Serve file statici
    location / {
        try_files $uri $uri/ =404;
    }

    # Proxy per API
    location /api/ {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Cache per risorse statiche
    location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

## 2.3 Intermediari HTTP

Gli **intermediari HTTP** sono componenti che si posizionano tra client e server, processando le richieste e le risposte.

```
Client <──> [Intermediario] <──> Server
```

### 2.3.1 Proxy

Un **proxy** è un intermediario che inoltra richieste per conto dei client.

#### Forward Proxy (Proxy Client-Side)

```
Client → Forward Proxy → Internet → Server

Caso d'uso: Corporate network, privacy
```

**Esempio:**
```
Azienda ACME:

Employee PC ──┐
Employee PC ──┤
Employee PC ──┼──> Corporate Proxy ──> Internet
Employee PC ──┤            │
Employee PC ──┘            │
                    - Filtering
                    - Caching
                    - Logging
                    - Authentication
```

**Configurazione Client (esempio):**
```bash
# Variabili ambiente
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080

# curl con proxy
curl -x http://proxy.company.com:8080 https://example.com
```

#### Reverse Proxy (Proxy Server-Side)

```
Client → Internet → Reverse Proxy → Backend Servers

Caso d'uso: Load balancing, caching, SSL termination
```

**Esempio:**
```
Internet
   │
   ▼
Reverse Proxy (Nginx)
   │
   ├──> Backend Server 1
   ├──> Backend Server 2
   ├──> Backend Server 3
   └──> Backend Server 4
```

**Funzioni del Reverse Proxy:**

1. **Load Balancing**
   ```nginx
   upstream backend {
       server backend1.example.com;
       server backend2.example.com;
       server backend3.example.com;
   }
   
   server {
       location / {
           proxy_pass http://backend;
       }
   }
   ```

2. **SSL Termination**
   ```
   Client (HTTPS) → Reverse Proxy → Backend (HTTP)
                    ┌─────────────┐
                    │ Decrypt SSL │
                    │ Certificate │
                    └─────────────┘
   ```

3. **Caching**
   ```nginx
   proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m;
   
   server {
       location / {
           proxy_cache my_cache;
           proxy_pass http://backend;
       }
   }
   ```

4. **Compression**
   ```nginx
   gzip on;
   gzip_types text/plain text/css application/json;
   ```

### 2.3.2 Gateway

Un **gateway** (o reverse proxy applicativo) traduce tra protocolli diversi.

**Esempi:**

1. **API Gateway**
   ```
   Mobile App (REST) ─┐
   Web App (REST)    ─┼─> API Gateway ─┬─> Microservice 1 (gRPC)
   Partner (SOAP)    ─┘                ├─> Microservice 2 (REST)
                                       └─> Legacy System (SOAP)
   ```

2. **Protocol Gateway**
   ```
   HTTP Client → Gateway → WebSocket Server
   HTTP Client → Gateway → MQTT Broker
   ```

**Funzioni dell'API Gateway:**
- **Routing**: direziona richieste al servizio appropriato
- **Authentication**: centralizza l'autenticazione
- **Rate Limiting**: protegge backend da overload
- **Request/Response Transformation**: adatta formati
- **Aggregation**: combina risposte da più servizi

### 2.3.3 Tunnel

Un **tunnel** stabilisce una connessione end-to-end attraverso un intermediario.

**Metodo CONNECT:**
```http
CONNECT server.example.com:443 HTTP/1.1
Host: server.example.com:443
```

**Utilizzo principale:**
- HTTPS attraverso proxy HTTP
- VPN over HTTP

**Flusso:**
```
1. Client → Proxy: CONNECT server.com:443
2. Proxy: stabilisce connessione TCP con server.com:443
3. Proxy → Client: HTTP/1.1 200 Connection Established
4. Client ←→ Server: comunicazione cifrata (tunnel trasparente)
```

### 2.3.4 Cache

Una **cache** memorizza risposte per servirle velocemente a richieste future identiche.

#### Livelli di Cache

```
1. Browser Cache (client)
   ↓
2. Proxy Cache (intermediario)
   ↓
3. Reverse Proxy Cache (server-side)
   ↓
4. CDN Cache (edge)
   ↓
5. Origin Server
```

#### Esempio di Caching

```http
# Prima richiesta
GET /image.jpg HTTP/1.1
Host: example.com

HTTP/1.1 200 OK
Cache-Control: public, max-age=31536000
ETag: "abc123"
Content-Type: image/jpeg

[dati dell'immagine]

# ── CACHE MEMORIZZA ──

# Seconda richiesta (validazione)
GET /image.jpg HTTP/1.1
Host: example.com
If-None-Match: "abc123"

HTTP/1.1 304 Not Modified
Cache-Control: public, max-age=31536000
ETag: "abc123"

# ── CACHE USA VERSIONE MEMORIZZATA ──
```

**Vantaggi della Cache:**
- ✅ Riduce latenza
- ✅ Diminuisce carico sul server
- ✅ Risparmia banda
- ✅ Migliora user experience
- ✅ Riduce costi (banda, server)

## 2.4 Il Ciclo Richiesta-Risposta

Il ciclo fondamentale di HTTP consiste in quattro fasi:

```
┌────────────────────────────────────────────┐
│  1. CONNESSIONE                            │
│     Client apre connessione TCP al server  │
└────────────────┬───────────────────────────┘
                 ▼
┌────────────────────────────────────────────┐
│  2. RICHIESTA                              │
│     Client invia richiesta HTTP            │
└────────────────┬───────────────────────────┘
                 ▼
┌────────────────────────────────────────────┐
│  3. ELABORAZIONE                           │
│     Server processa la richiesta           │
└────────────────┬───────────────────────────┘
                 ▼
┌────────────────────────────────────────────┐
│  4. RISPOSTA                               │
│     Server invia risposta HTTP             │
└────────────────┬───────────────────────────┘
                 ▼
┌────────────────────────────────────────────┐
│  5. CHIUSURA (opzionale)                   │
│     Connessione chiusa o mantenuta aperta  │
└────────────────────────────────────────────┘
```

### Dettaglio del Ciclo

#### Fase 1: Connessione TCP

```
Client                              Server
  |                                    |
  | SYN (seq=x)                        |
  |----------------------------------->|
  |                                    |
  |                    SYN-ACK (seq=y) |
  |<-----------------------------------|
  |                                    |
  | ACK                                |
  |----------------------------------->|
  |                                    |
  |  TCP Connection Established        |
```

**Tempo**: ~1 RTT (Round Trip Time)

#### Fase 2 + 3 + 4: Richiesta HTTP, Elaborazione, Risposta

```http
# CLIENT INVIA
GET /api/users/123 HTTP/1.1
Host: api.example.com
User-Agent: MyApp/1.0
Accept: application/json
Authorization: Bearer token123


# SERVER ELABORA
- Parse richiesta
- Autenticazione (verifica token)
- Autorizzazione (permessi)
- Query database
- Genera risposta JSON


# SERVER RISPONDE
HTTP/1.1 200 OK
Date: Thu, 30 Oct 2025 12:00:00 GMT
Content-Type: application/json
Content-Length: 87

{"id":123,"name":"Mario Rossi","email":"mario@example.com"}
```

**Tempo**: variabile (dipende dall'elaborazione server)

#### Fase 5: Gestione Connessione

**HTTP/1.0 (connessione non persistente):**
```
Request 1 → Response 1 → CHIUDI
Request 2 → Response 2 → CHIUDI
Request 3 → Response 3 → CHIUDI

Ogni richiesta = nuova connessione TCP (overhead!)
```

**HTTP/1.1 (connessione persistente):**
```http
Connection: keep-alive

Request 1 → Response 1 
Request 2 → Response 2  } Stessa connessione TCP
Request 3 → Response 3 
             ↓
          CHIUDI (dopo timeout o Connection: close)
```

## 2.5 Connessioni HTTP

### 2.5.1 Connessioni Non Persistenti

Usate in HTTP/1.0 (default).

**Caratteristiche:**
- Una richiesta HTTP per connessione TCP
- Connessione chiusa dopo ogni risposta
- Header `Connection: close`

**Esempio:**
```
Timeline:

0ms:   Apri TCP connection
100ms: TCP established
       Invia GET /index.html
200ms: Ricevi /index.html
       CHIUDI connessione

200ms: Apri TCP connection (per style.css)
300ms: TCP established  
       Invia GET /style.css
400ms: Ricevi /style.css
       CHIUDI connessione

400ms: Apri TCP connection (per script.js)
500ms: TCP established
       Invia GET /script.js
600ms: Ricevi /script.js
       CHIUDI connessione

Totale: 600ms per 3 file
```

**Problemi:**
- ❌ Overhead del TCP handshake per ogni richiesta
- ❌ Slow start TCP riparte ogni volta
- ❌ Spreco risorse (socket, tempo)
- ❌ Latenza elevata

### 2.5.2 Connessioni Persistenti

Default in HTTP/1.1.

**Caratteristiche:**
- Multiple richieste sulla stessa connessione TCP
- Header `Connection: keep-alive`
- Timeout configurable (es. 5 secondi)

**Esempio:**
```http
# Prima richiesta
GET /index.html HTTP/1.1
Host: example.com
Connection: keep-alive

HTTP/1.1 200 OK
Connection: keep-alive
Keep-Alive: timeout=5, max=100
Content-Length: 1234

[body]

# Seconda richiesta (stessa connessione!)
GET /style.css HTTP/1.1
Host: example.com
Connection: keep-alive

HTTP/1.1 200 OK
Connection: keep-alive
Content-Length: 5678

[body]
```

**Timeline:**
```
0ms:   Apri TCP connection
100ms: TCP established
       Invia GET /index.html
200ms: Ricevi /index.html
       
       Invia GET /style.css (stessa connessione!)
300ms: Ricevi /style.css
       
       Invia GET /script.js (stessa connessione!)
400ms: Ricevi /script.js
       
       CHIUDI dopo timeout

Totale: 400ms per 3 file (vs 600ms)
Risparmio: 33%!
```

**Vantaggi:**
- ✅ Riduzione latenza
- ✅ Meno overhead TCP
- ✅ Migliore utilizzo slow start TCP
- ✅ Meno carico sui server (meno socket)

**Configurazione Server:**

```nginx
# Nginx
keepalive_timeout 65;
keepalive_requests 100;
```

```apache
# Apache
KeepAlive On
MaxKeepAliveRequests 100
KeepAliveTimeout 5
```

### 2.5.3 Pipelining

**HTTP/1.1 Pipelining** permette di inviare multiple richieste senza attendere le risposte.

**Senza Pipelining:**
```
Request 1  → ←  Response 1
                Request 2  → ←  Response 2
                                Request 3  → ←  Response 3
```

**Con Pipelining:**
```
Request 1  →
Request 2  →
Request 3  →
                ←  Response 1
                ←  Response 2
                ←  Response 3
```

**Esempio:**
```
0ms:   Invia GET /index.html
       Invia GET /style.css
       Invia GET /script.js
100ms: Ricevi /index.html
120ms: Ricevi /style.css
150ms: Ricevi /script.js
```

**Problemi del Pipelining:**
- ❌ **Head-of-Line Blocking**: risposta lenta blocca le successive
- ❌ Implementazioni buggy nei server/proxy
- ❌ Disabilitato di default nei browser
- ❌ Superato da HTTP/2 multiplexing

**HTTP/2 Multiplexing** (soluzione migliore):
```
Stream 1: GET /index.html  →  ← Response (frame 1, 3, 7)
Stream 3: GET /style.css   →  ← Response (frame 2, 5, 9)
Stream 5: GET /script.js   →  ← Response (frame 4, 6, 8)

Frames possono essere inframezzati!
```

---

## Riepilogo

L'architettura HTTP si basa su:

1. **Modello Client-Server**
   - Client inizia, Server risponde
   - Ruoli asimmetrici e ben definiti
   - Scalabilità e separazione delle responsabilità

2. **User Agent e Web Server**
   - User Agent: browser, app, tool, bot
   - Web Server: Apache, Nginx, IIS, application servers
   - Responsabilità chiare per ciascuno

3. **Intermediari**
   - **Proxy**: forward (client-side), reverse (server-side)
   - **Gateway**: traduzione protocolli
   - **Tunnel**: connessioni end-to-end
   - **Cache**: memorizzazione risposte

4. **Ciclo Richiesta-Risposta**
   - Connessione → Richiesta → Elaborazione → Risposta → Chiusura

5. **Gestione Connessioni**
   - **Non persistenti**: una richiesta per connessione (HTTP/1.0)
   - **Persistenti**: multiple richieste (HTTP/1.1+)
   - **Pipelining**: richieste parallele (deprecato)
   - **Multiplexing**: richieste concorrenti (HTTP/2+)

Nei prossimi capitoli approfondiremo la struttura dettagliata di richieste e risposte HTTP.

---

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0

--- 
[Torna all'indice](README.md)
[Capitolo successivo: Anatomia di una Richiesta HTTP](03_anatomia_richiesta_http.md)