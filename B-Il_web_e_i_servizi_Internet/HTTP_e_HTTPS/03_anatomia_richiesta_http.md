# 3. Anatomia di una Richiesta HTTP

## 3.1 Struttura Generale di una Richiesta

Una richiesta HTTP è composta da **tre parti principali**:

```
┌─────────────────────────────────────────┐
│  REQUEST LINE                           │  ← Obbligatoria
│  [Metodo] [URI] [Versione HTTP]         │
├─────────────────────────────────────────┤
│  HEADERS                                │  ← Opzionali (ma consigliati)
│  Header-Name: Header-Value              │
│  Header-Name: Header-Value              │
│  ...                                    │
├─────────────────────────────────────────┤
│  BLANK LINE                             │  ← Obbligatoria (separatore)
├─────────────────────────────────────────┤
│  BODY                                   │  ← Opzionale
│  [Dati della richiesta]                 │
└─────────────────────────────────────────┘
```

### Esempio Completo

```http
GET /api/users?page=1&limit=10 HTTP/1.1
Host: api.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Accept: application/json
Accept-Language: it-IT,it;q=0.9,en;q=0.8
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cache-Control: no-cache
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

```

**Analisi:**
1. **Request Line**: `GET /api/users?page=1&limit=10 HTTP/1.1`
2. **Headers**: 8 headers che forniscono metadati
3. **Blank Line**: linea vuota che separa headers dal body
4. **Body**: assente (tipico per GET)

### Esempio con Body (POST)

```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 85
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

{
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "role": "developer"
}
```

## 3.2 Request Line

La **Request Line** è la prima riga della richiesta HTTP e contiene tre elementi fondamentali:

```
[METODO] [URI] [VERSIONE]
```

### 3.2.1 Metodo HTTP

Il **metodo** (o verbo HTTP) indica l'azione che il client vuole eseguire.

#### Metodi Principali

| Metodo | Scopo | Idempotente | Sicuro | Body |
|--------|-------|-------------|--------|------|
| **GET** | Recuperare risorsa | ✅ | ✅ | ❌ No |
| **POST** | Creare risorsa | ❌ | ❌ | ✅ Sì |
| **PUT** | Aggiornare/sostituire | ✅ | ❌ | ✅ Sì |
| **PATCH** | Modificare parzialmente | ❌ | ❌ | ✅ Sì |
| **DELETE** | Eliminare risorsa | ✅ | ❌ | ❌ No* |
| **HEAD** | Come GET ma solo headers | ✅ | ✅ | ❌ No |
| **OPTIONS** | Opzioni di comunicazione | ✅ | ✅ | ❌ No |
| **CONNECT** | Stabilire tunnel | ❌ | ❌ | ❌ No |
| **TRACE** | Loop-back di diagnostica | ✅ | ✅ | ❌ No |

\* DELETE può avere un body, ma è raro

**Definizioni:**
- **Sicuro (Safe)**: non modifica lo stato del server
- **Idempotente**: multiple chiamate identiche hanno lo stesso effetto di una singola chiamata

#### Esempi di Metodi

**GET - Recuperare dati:**
```http
GET /api/products/123 HTTP/1.1
Host: api.example.com
```

**POST - Creare nuova risorsa:**
```http
POST /api/products HTTP/1.1
Host: api.example.com
Content-Type: application/json

{"name": "Laptop", "price": 999.99}
```

**PUT - Aggiornare risorsa completa:**
```http
PUT /api/products/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{"id": 123, "name": "Laptop Pro", "price": 1299.99, "stock": 50}
```

**PATCH - Aggiornare parzialmente:**
```http
PATCH /api/products/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{"price": 1199.99}
```

**DELETE - Eliminare risorsa:**
```http
DELETE /api/products/123 HTTP/1.1
Host: api.example.com
```

**HEAD - Ottenere solo metadata:**
```http
HEAD /api/products/123 HTTP/1.1
Host: api.example.com
```

**OPTIONS - Scoprire opzioni disponibili:**
```http
OPTIONS /api/products HTTP/1.1
Host: api.example.com
```

### 3.2.2 URI (Uniform Resource Identifier)

L'**URI** identifica la risorsa su cui eseguire l'azione.

#### Struttura di un URI

```
/path/to/resource?query=value&param=123#fragment
│                 │                     │
│                 │                     └─ Fragment (ignorato dal server)
│                 └─ Query String
└─ Path
```

#### Componenti dell'URI

**1. Path (Percorso)**
```http
GET /api/v1/users/123/posts HTTP/1.1
     └────────┬──────────┘
         Path completo
```

**Convenzioni:**
- Usa `/` per separare livelli gerarchici
- Usa sostantivi al plurale: `/users`, `/products`
- Evita verbi: ❌ `/getUsers`, ✅ `/users` (il verbo è nel metodo)
- Minuscole preferite: `/users` meglio di `/Users`
- Usa `-` invece di `_`: `/user-profiles` meglio di `/user_profiles`

**2. Query String (Parametri)**
```http
GET /api/users?page=2&limit=20&sort=name&order=asc HTTP/1.1
              └─────────────────┬────────────────────┘
                          Query parameters
```

**Formato:**
```
?param1=value1&param2=value2&param3=value3
```

**Usi comuni:**
- **Paginazione**: `?page=1&limit=10`
- **Filtri**: `?status=active&role=admin`
- **Ordinamento**: `?sort=created_at&order=desc`
- **Ricerca**: `?q=mario+rossi`
- **Campi**: `?fields=id,name,email`

**Encoding dei caratteri speciali:**
```
Spazio:     " " → %20 o +
&:          "&" → %26
=:          "=" → %3D
#:          "#" → %23
?:          "?" → %3F
À:          "À" → %C3%80

Esempio:
"Mario Rossi" → "Mario+Rossi" o "Mario%20Rossi"
"2+2=4"       → "2%2B2%3D4"
```

**3. Fragment (Frammento)**
```http
GET /docs/guide.html#section-3 HTTP/1.1
                     └────┬────┘
                      Fragment
```

⚠️ **Importante**: Il fragment **NON viene inviato al server**! È usato solo dal client (browser) per navigare all'interno della risorsa.

```
URL completo:  https://example.com/page#section2
Richiesta HTTP: GET /page HTTP/1.1
                    └─ Fragment omesso!
```

#### Esempi di URI Completi

**E-commerce:**
```http
GET /api/products?category=electronics&price_max=1000&sort=popularity HTTP/1.1
```

**Social Media:**
```http
GET /api/users/mario_rossi/posts?limit=20&offset=40 HTTP/1.1
```

**Ricerca:**
```http
GET /search?q=http+protocol&lang=it&safe=on HTTP/1.1
```

**API con versioning:**
```http
GET /api/v2/customers/123/orders?status=pending HTTP/1.1
```

### 3.2.3 Versione del Protocollo

La **versione HTTP** indica quale versione del protocollo il client supporta.

#### Versioni Supportate

```
HTTP/0.9  →  Obsoleta (solo storica)
HTTP/1.0  →  Ancora usata (rara)
HTTP/1.1  →  Più comune (default)
HTTP/2    →  Moderna (binaria)
HTTP/3    →  Più recente (QUIC)
```

#### Formato nella Request Line

**HTTP/1.1:**
```http
GET /index.html HTTP/1.1
                └───┬───┘
                 Versione
```

**HTTP/2 e HTTP/3:**
⚠️ Nota: HTTP/2 e HTTP/3 sono **binari**, quindi non hanno una "request line" testuale. La versione è negoziata durante l'handshake.

```
HTTP/1.1:  Testuale, leggibile
HTTP/2:    Binario (frames)
HTTP/3:    Binario (QUIC)
```

#### Negoziazione della Versione

**1. HTTP/1.1 → HTTP/2 (TLS ALPN)**
```
Client → Server: TLS ClientHello
                 ALPN extension: ["h2", "http/1.1"]

Server → Client: TLS ServerHello
                 ALPN selected: "h2"

→ Connessione HTTP/2 stabilita
```

**2. HTTP/1.1 → HTTP/2 (Upgrade header - raro)**
```http
GET / HTTP/1.1
Host: example.com
Connection: Upgrade, HTTP2-Settings
Upgrade: h2c
HTTP2-Settings: <base64-encoded-settings>

HTTP/1.1 101 Switching Protocols
Connection: Upgrade
Upgrade: h2c

[HTTP/2 connection starts]
```

**3. HTTP/2 → HTTP/3 (Alt-Svc header)**
```http
HTTP/2 Response:
Alt-Svc: h3=":443"; ma=86400

→ Client può usare HTTP/3 per richieste future
```

## 3.3 Request Headers

Gli **headers** forniscono metadati aggiuntivi sulla richiesta.

### Sintassi degli Headers

```
Header-Name: Header-Value
```

**Regole:**
- Nome: case-insensitive (`Content-Type` = `content-type`)
- Separatore: `: ` (due punti + spazio)
- Un header per riga
- Possono esserci headers multipli con stesso nome

### 3.3.1 Headers Generali

Headers applicabili sia a richieste che risposte.

#### Connection

Controlla la gestione della connessione.

```http
Connection: keep-alive    # Mantieni connessione aperta
Connection: close         # Chiudi dopo questa richiesta
Connection: Upgrade       # Aggiornamento protocollo
```

**Esempio:**
```http
GET / HTTP/1.1
Host: example.com
Connection: keep-alive

# Server può mantenere la connessione per richieste future
```

#### Cache-Control

Direttive per il comportamento della cache.

```http
Cache-Control: no-cache              # Revalidare sempre
Cache-Control: no-store              # Non cachare mai
Cache-Control: max-age=3600          # Cache per 1 ora
Cache-Control: no-cache, no-store    # Multipli valori
```

**Esempi:**
```http
# Sempre fresco dal server
GET /api/realtime-data HTTP/1.1
Cache-Control: no-cache

# Può essere cachato
GET /api/static-config HTTP/1.1
Cache-Control: max-age=86400
```

#### Date

Data e ora della richiesta (raro nelle richieste, comune nelle risposte).

```http
Date: Thu, 30 Oct 2025 12:00:00 GMT
```

Formato: **RFC 7231** (sempre GMT/UTC)

### 3.3.2 Headers di Richiesta

Headers specifici per le richieste.

#### Host

**Obbligatorio in HTTP/1.1!** Specifica l'host e porta del server.

```http
Host: www.example.com
Host: api.example.com:8080
Host: 192.168.1.1:3000
```

**Perché è obbligatorio?**
Permette **virtual hosting**: più siti web sullo stesso IP.

```
Server IP: 93.184.216.34

Host: site1.com      → Virtual Host 1
Host: site2.com      → Virtual Host 2
Host: site3.com      → Virtual Host 3
```

**Esempio:**
```http
GET /index.html HTTP/1.1
Host: www.example.com
# ← Senza Host, errore 400 Bad Request in HTTP/1.1
```

#### User-Agent

Identifica il client che fa la richiesta.

```http
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36
```

**Struttura tipica:**
```
[Product]/[Version] ([System]; [Platform]) [Extensions]
```

**Esempi reali:**

**Browser Desktop:**
```http
# Chrome su Windows
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36

# Firefox su macOS
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:121.0) Gecko/20100101 Firefox/121.0

# Safari su macOS
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15
```

**Mobile:**
```http
# Chrome su Android
User-Agent: Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.43 Mobile Safari/537.36

# Safari su iPhone
User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1
```

**Bot e Crawler:**
```http
# Googlebot
User-Agent: Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)

# Bingbot
User-Agent: Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)
```

**CLI Tools:**
```http
# curl
User-Agent: curl/7.68.0

# wget
User-Agent: Wget/1.20.3 (linux-gnu)
```

**Custom Apps:**
```http
User-Agent: MyApp/1.2.3 (iOS 17.0; iPhone14,2)
User-Agent: MobileApp/2.0.1 (Android 14; Samsung SM-G998B)
```

#### Referer

Indica da quale pagina proviene la richiesta.

```http
Referer: https://www.google.com/search?q=http+protocol
```

**Uso:**
- Analytics: tracciare la provenienza del traffico
- Security: verificare la provenienza delle richieste
- Conditional logic: comportamento diverso in base alla sorgente

**Esempio:**
```http
# User clicca un link su Google
GET /article/123 HTTP/1.1
Host: blog.example.com
Referer: https://www.google.com/search?q=interesting+article
```

**Nota ortografica:** 
⚠️ Si scrive **"Referer"** (con un solo 'r') per errore storico nello standard!
Corretto sarebbe "Referrer", ma lo standard usa "Referer".

**Privacy:**
```http
# Non inviare referer
Referrer-Policy: no-referrer

# Invia solo origin
Referrer-Policy: origin

# Invia URL completo solo per HTTPS→HTTPS
Referrer-Policy: strict-origin-when-cross-origin
```

#### Accept Headers (Content Negotiation)

Il client indica quali tipi di contenuto, lingue, encoding accetta.

**Accept - Tipo di media:**
```http
Accept: application/json
Accept: text/html
Accept: image/png
Accept: */*                          # Qualsiasi tipo
Accept: application/json, text/html  # Multipli tipi
```

**Con priorità (q-values):**
```http
Accept: application/json;q=1.0, text/html;q=0.9, */*;q=0.8
        └──────┬──────┘             └─────┬─────┘       └─┬─┘
         Preferito (q=1.0)        Secondo (q=0.9)   Altro (q=0.8)
```

**Accept-Language - Lingua preferita:**
```http
Accept-Language: it-IT, it;q=0.9, en;q=0.8
                 └──┬─┘  └───┬───┘  └──┬─┘
                Italiano  Italiano   Inglese
                (Italia)  (generale) (fallback)
```

**Accept-Encoding - Compressione:**
```http
Accept-Encoding: gzip, deflate, br
                 └─┬┘  └──┬──┘  └┬┘
                 gzip  deflate  Brotli
```

**Accept-Charset - Set di caratteri (deprecato):**
```http
Accept-Charset: utf-8, iso-8859-1;q=0.7
```

**Esempio completo:**
```http
GET /api/users HTTP/1.1
Host: api.example.com
Accept: application/json, application/xml;q=0.9, */*;q=0.8
Accept-Language: it-IT, it;q=0.9, en;q=0.8
Accept-Encoding: gzip, deflate, br
```

Server risponderà con il formato più appropriato in base alle preferenze del client.

### 3.3.3 Headers di Entità

Headers che descrivono il body del messaggio.

#### Content-Type

Specifica il tipo di media del body.

```http
Content-Type: media-type [; charset=encoding] [; boundary=string]
```

**Tipi comuni:**

**JSON:**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario", "email": "mario@example.com"}
```

**Form URL-encoded:**
```http
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=mario&password=secret123
```

**Multipart (file upload):**
```http
POST /upload HTTP/1.1
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="file"; filename="document.pdf"
Content-Type: application/pdf

[binary data]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

**XML:**
```http
POST /api/data HTTP/1.1
Content-Type: application/xml

<?xml version="1.0"?>
<user>
  <name>Mario</name>
  <email>mario@example.com</email>
</user>
```

**Plain text:**
```http
POST /api/notes HTTP/1.1
Content-Type: text/plain; charset=utf-8

Questa è una semplice nota di testo.
```

**HTML:**
```http
POST /api/content HTTP/1.1
Content-Type: text/html

<h1>Titolo</h1>
<p>Contenuto HTML</p>
```

#### Content-Length

Dimensione del body in byte.

```http
Content-Length: 1234
```

**Esempio:**
```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 58

{"name":"Mario Rossi","email":"mario.rossi@example.com"}
```

**Calcolo:**
```json
{"name":"Mario Rossi","email":"mario.rossi@example.com"}
← 58 bytes (inclusi spazi, virgole, virgolette)
```

**Importante:**
- Se Content-Length è errato → errore o dati troncati
- Se omesso e non chunked → server non sa quando finisce il body
- Con `Transfer-Encoding: chunked` → Content-Length non deve esserci

#### Content-Encoding

Indica la codifica/compressione applicata al body.

```http
Content-Encoding: gzip
Content-Encoding: deflate
Content-Encoding: br          # Brotli
Content-Encoding: compress    # Deprecato
```

**Esempio (raro nelle richieste):**
```http
POST /api/large-data HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Encoding: gzip
Content-Length: 456

[dati JSON compressi con gzip]
```

**Più comune nelle risposte:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Encoding: gzip

[HTML compresso]
```

#### Content-Language

Specifica la lingua del contenuto (raro nelle richieste).

```http
Content-Language: it-IT
Content-Language: en-US
Content-Language: fr, de
```

## 3.4 Request Body

Il **body** contiene i dati effettivi inviati al server.

### Quando Usare il Body

| Metodo | Body tipico? | Note |
|--------|-------------|------|
| GET | ❌ No | Usa query string invece |
| POST | ✅ Sì | Creazione risorse, submit form |
| PUT | ✅ Sì | Aggiornamento completo |
| PATCH | ✅ Sì | Aggiornamento parziale |
| DELETE | ⚠️ Raro | Possibile ma inusuale |
| HEAD | ❌ No | Come GET senza body |
| OPTIONS | ❌ No | Opzioni di comunicazione |

### Formati del Body

#### 1. JSON (application/json)

**Il più comune per API moderne.**

```http
POST /api/products HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 156

{
  "name": "Laptop Dell XPS 15",
  "category": "electronics",
  "price": 1499.99,
  "specs": {
    "cpu": "Intel i7",
    "ram": "16GB",
    "storage": "512GB SSD"
  },
  "in_stock": true
}
```

**Vantaggi:**
- ✅ Leggibile
- ✅ Supporto nativo in JavaScript
- ✅ Gerarchico (oggetti annidati)
- ✅ Supporta array, null, boolean, numeri

#### 2. Form URL-Encoded (application/x-www-form-urlencoded)

**Formato tradizionale dei form HTML.**

```http
POST /login HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 38

username=mario&password=secret&remember=on
```

**Encoding:**
```
Spazi:           " " → "+"
Caratteri spec:  "&" → "%26", "=" → "%3D"

Esempio:
nome=Mario Rossi&email=mario@test.com
↓
nome=Mario+Rossi&email=mario%40test.com
```

**HTML Form:**
```html
<form method="POST" action="/login">
  <input name="username" value="mario">
  <input name="password" type="password">
  <button type="submit">Login</button>
</form>

<!-- Genera richiesta con application/x-www-form-urlencoded -->
```

#### 3. Multipart Form Data (multipart/form-data)

**Usato per upload di file.**

```http
POST /api/upload HTTP/1.1
Host: api.example.com
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Length: 2456

------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="title"

My Document
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="category"

reports
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="file"; filename="report.pdf"
Content-Type: application/pdf

[binary PDF data...]
------WebKitFormBoundary7MA4YWxkTrZu0gW
Content-Disposition: form-data; name="thumbnail"; filename="thumb.jpg"
Content-Type: image/jpeg

[binary JPEG data...]
------WebKitFormBoundary7MA4YWxkTrZu0gW--
```

**HTML Form:**
```html
<form method="POST" action="/upload" enctype="multipart/form-data">
  <input name="title" value="My Document">
  <input name="file" type="file">
  <button type="submit">Upload</button>
</form>
```

#### 4. XML (application/xml)

**Meno comune nelle API moderne, ma ancora usato.**

```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/xml
Content-Length: 178

<?xml version="1.0" encoding="UTF-8"?>
<user>
  <name>Mario Rossi</name>
  <email>mario.rossi@example.com</email>
  <role>developer</role>
  <active>true</active>
</user>
```

#### 5. Plain Text (text/plain)

**Testo semplice.**

```http
POST /api/notes HTTP/1.1
Host: api.example.com
Content-Type: text/plain; charset=utf-8
Content-Length: 87

Questa è una nota importante.
Può contenere più righe.
Senza struttura particolare.
```

#### 6. Binary Data (application/octet-stream)

**Dati binari grezzi.**

```http
POST /api/data HTTP/1.1
Host: api.example.com
Content-Type: application/octet-stream
Content-Length: 4096

[binary data...]
```

## 3.5 Esempi Pratici di Richieste HTTP

### Esempio 1: GET Semplice

```http
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Accept: text/html,application/xhtml+xml
Accept-Language: it-IT,it;q=0.9
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cache-Control: max-age=0

```

### Esempio 2: POST con JSON

```http
POST /api/v1/users HTTP/1.1
Host: api.example.com
User-Agent: MyApp/1.0
Content-Type: application/json
Content-Length: 102
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json

{
  "username": "mario.rossi",
  "email": "mario.rossi@example.com",
  "full_name": "Mario Rossi",
  "role": "user"
}
```

### Esempio 3: PUT per Update

```http
PUT /api/v1/users/123 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Content-Length: 145
If-Match: "686897696a7c876b7e"

{
  "id": 123,
  "username": "mario.rossi",
  "email": "mario.rossi.new@example.com",
  "full_name": "Mario Rossi",
  "role": "admin",
  "active": true
}
```

### Esempio 4: DELETE

```http
DELETE /api/v1/users/123 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

```

### Esempio 5: Form Submit

```http
POST /contact HTTP/1.1
Host: www.example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 87

name=Mario+Rossi&email=mario%40example.com&message=Ciao%2C+vorrei+informazioni&subject=Info
```

### Esempio 6: File Upload

```http
POST /api/documents HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: multipart/form-data; boundary=----Boundary1234567890
Content-Length: 3456

------Boundary1234567890
Content-Disposition: form-data; name="title"

Annual Report 2025
------Boundary1234567890
Content-Disposition: form-data; name="file"; filename="report.pdf"
Content-Type: application/pdf

%PDF-1.4
[binary PDF content...]
------Boundary1234567890--
```

### Esempio 7: API con Paginazione e Filtri

```http
GET /api/v1/products?page=2&limit=20&category=electronics&sort=price&order=desc&min_price=100&max_price=1000 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json
Accept-Language: it-IT
Cache-Control: no-cache

```

### Esempio 8: Conditional Request

```http
GET /api/data.json HTTP/1.1
Host: api.example.com
If-None-Match: "686897696a7c876b7e"
If-Modified-Since: Wed, 29 Oct 2025 19:00:00 GMT
Cache-Control: max-age=0

```

### Esempio 9: Range Request (Download Parziale)

```http
GET /videos/movie.mp4 HTTP/1.1
Host: cdn.example.com
Range: bytes=0-1048575
User-Agent: VideoPlayer/3.0

```

### Esempio 10: PATCH per Update Parziale

```http
PATCH /api/v1/users/123 HTTP/1.1
Host: api.example.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Content-Length: 27

{
  "email": "nuovo@email.com"
}
```

---

## Riepilogo

Una richiesta HTTP è strutturata in:

1. **Request Line**
   - Metodo (GET, POST, PUT, DELETE, etc.)
   - URI (path + query string)
   - Versione HTTP (HTTP/1.1, HTTP/2, HTTP/3)

2. **Headers**
   - **Generali**: Connection, Cache-Control, Date
   - **Richiesta**: Host (obbligatorio), User-Agent, Referer, Accept*
   - **Entità**: Content-Type, Content-Length, Content-Encoding

3. **Blank Line**
   - Separa headers da body

4. **Body** (opzionale)
   - JSON, Form data, Multipart, XML, Plain text, Binary
   - Dipende dal Content-Type

**Best Practices:**
- ✅ Usa metodi HTTP appropriati (semantica corretta)
- ✅ Includi sempre Host header (HTTP/1.1)
- ✅ Specifica Content-Type quando hai un body
- ✅ Usa Accept headers per content negotiation
- ✅ Implementa autenticazione quando necessario
- ✅ Gestisci encoding caratteri (UTF-8)

Nel prossimo capitolo vedremo la struttura delle **risposte HTTP**.

---

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
