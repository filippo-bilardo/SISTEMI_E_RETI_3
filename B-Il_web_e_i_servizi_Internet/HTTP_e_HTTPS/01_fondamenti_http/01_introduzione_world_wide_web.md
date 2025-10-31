# 01. Introduzione al World Wide Web

## 1.1 Cos'è HTTP?

**HTTP** (HyperText Transfer Protocol) è il protocollo fondamentale che permette la comunicazione tra client e server nel World Wide Web. È il linguaggio che consente ai browser di richiedere pagine web, immagini, video e altri contenuti ai server, e ai server di rispondere con le risorse richieste.

### Definizione Formale

HTTP è un **protocollo a livello applicativo** che:
- Opera sopra il livello di trasporto TCP/IP
- Utilizza il modello richiesta-risposta (request-response)
- È stateless (senza stato) per default
- È basato su testo e human-readable

### Caratteristiche Principali

```
┌─────────────────────────────────────────────┐
│           CARATTERISTICHE HTTP              │
├─────────────────────────────────────────────┤
│ ✓ Protocollo testuale                      │
│ ✓ Stateless (ogni richiesta è indipendente)│
│ ✓ Estensibile (header personalizzabili)    │
│ ✓ Client-Server architecture               │
│ ✓ Supporto caching                         │
│ ✓ Negoziazione contenuti                   │
└─────────────────────────────────────────────┘
```
s
### Esempio di Comunicazione HTTP

**Richiesta dal client:**
```http
GET /index.html HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0
Accept: text/html
```

**Risposta dal server:**
```http
HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1234

<!DOCTYPE html>
<html>
<head><title>Esempio</title></head>
<body><h1>Benvenuto!</h1></body>
</html>
```

---

## 1.2 Storia ed Evoluzione del Protocollo

### Timeline Evolutiva

```
1989        1991        1996        1999        2015        2022
 │           │           │           │           │           │
 │           │           │           │           │           │
HTTP/0.9   HTTP/1.0   HTTP/1.1   HTTP/1.1    HTTP/2     HTTP/3
(concept)  (RFC 1945) (RFC 2068)  (RFC 2616)  (RFC 7540) (RFC 9114)
           Single     Persistent  Chunked     Binary     QUIC
           request    connections Transfer    protocol   over UDP
```

### HTTP/0.9 (1991) - Il Protocollo Originale

**Caratteristiche:**
- Estremamente semplice
- Solo metodo GET
- Solo documenti HTML
- Nessun header
- Chiusura connessione dopo ogni richiesta

**Esempio HTTP/0.9:**
```
GET /mypage.html
```

**Risposta:**
```html
<HTML>
A very simple HTML page
</HTML>
```

**Limiti:**
- Non supportava header
- Solo HTML, nessun altro tipo di file
- Nessuna informazione sullo stato
- Impossibile gestire errori

---

### HTTP/1.0 (1996) - RFC 1945

**Innovazioni:**
- Introduzione di header HTTP
- Supporto per diversi tipi di contenuto (MIME types)
- Codici di stato (200, 404, 500, etc.)
- Metodi POST e HEAD oltre a GET
- Versioning del protocollo

**Esempio HTTP/1.0:**

**Richiesta:**
```http
GET /mypage.html HTTP/1.0
User-Agent: NCSA_Mosaic/2.0 (Windows 3.1)
```

**Risposta:**
```http
HTTP/1.0 200 OK
Date: Mon, 01 Jan 1996 12:00:00 GMT
Server: CERN/3.0 libwww/2.17
Content-Type: text/html
Content-Length: 137

<HTML>
A page with an image
<IMG SRC="/myimage.gif">
</HTML>
```

**Problema principale:** Ogni richiesta apriva una nuova connessione TCP!

```
┌─────────┐                              ┌─────────┐
│ Browser │                              │ Server  │
└────┬────┘                              └────┬────┘
     │                                        │
     │ ─── TCP handshake (3-way) ────────► │
     │ ◄── GET /page.html ─────────────── │
     │ ─── 200 OK + HTML ─────────────────► │
     │ ◄── TCP close ─────────────────────┘ │
     │                                        │
     │ ─── TCP handshake (per CSS) ───────► │
     │ ◄── GET /style.css ────────────────  │
     │ ─── 200 OK + CSS ──────────────────► │
     │ ◄── TCP close ─────────────────────┘ │
     │                                        │
     │ ─── TCP handshake (per immagine) ──► │
     │ ... (continua per ogni risorsa)       │
```

---

### HTTP/1.1 (1997-1999) - RFC 2068/2616

**Miglioramenti principali:**

#### 1. Connessioni Persistenti (Keep-Alive)
```http
GET /page.html HTTP/1.1
Host: www.example.com
Connection: keep-alive

HTTP/1.1 200 OK
Connection: keep-alive
Keep-Alive: timeout=5, max=100
```

**Vantaggi:**
- Riutilizzo della stessa connessione TCP
- Riduzione latenza (no 3-way handshake ripetuto)
- Minor carico sul server

#### 2. Pipelining
```
┌─────────┐                              ┌─────────┐
│ Browser │                              │ Server  │
└────┬────┘                              └────┬────┘
     │ ─── GET /page.html ──────────────► │
     │ ─── GET /style.css ──────────────► │
     │ ─── GET /script.js ──────────────► │
     │                                        │
     │ ◄── 200 OK (page.html) ───────────  │
     │ ◄── 200 OK (style.css) ───────────  │
     │ ◄── 200 OK (script.js) ───────────  │
```

#### 3. Host Header (obbligatorio)
Permette virtual hosting - più siti sullo stesso IP:
```http
GET /index.html HTTP/1.1
Host: www.site1.com

GET /index.html HTTP/1.1
Host: www.site2.com
```

#### 4. Chunked Transfer Encoding
Streaming di contenuti senza conoscere la dimensione totale:
```http
HTTP/1.1 200 OK
Transfer-Encoding: chunked

1A
Questo è il primo chunk di dati
14
Secondo chunk di dati
0
```

#### 5. Nuovi Metodi HTTP
- **PUT** - Carica/sostituisci risorsa
- **DELETE** - Elimina risorsa
- **OPTIONS** - Interroga opzioni supportate
- **TRACE** - Echo per debugging

#### 6. Caching Avanzato
```http
Cache-Control: max-age=3600, must-revalidate
ETag: "686897696a7c876b7e"
Last-Modified: Wed, 21 Oct 2015 07:28:00 GMT
```

---

### HTTP/2 (2015) - RFC 7540

**Problema di HTTP/1.1:** Head-of-line blocking

```
Request 1 (grande) ████████████████████████████
Request 2 (piccola)                            ██
Request 3 (piccola)                              ██
                   │←── ASPETTA ──→│
```

**Soluzione HTTP/2:**

#### 1. Multiplexing
```
┌───────────────────────────────────────────┐
│       Singola Connessione TCP             │
├───────────────────────────────────────────┤
│ Stream 1: ████ ████ ████                  │
│ Stream 2:      ██ ██ ██                   │
│ Stream 3:        ███ ███                  │
│ Stream 4:            ██ ██                │
└───────────────────────────────────────────┘
```

Ogni richiesta/risposta è uno "stream" indipendente.

#### 2. Protocollo Binario
```
HTTP/1.1 (text):
GET /index.html HTTP/1.1\r\n
Host: example.com\r\n
\r\n

HTTP/2 (binary frames):
[HEADERS frame] [DATA frame] [...]
┌────────┬────────┬─────────┐
│ Length │  Type  │ Flags   │
├────────┼────────┼─────────┤
│ Stream │ Payload          │
└────────┴──────────────────┘
```

**Vantaggi:**
- Parsing più efficiente
- Meno errori
- Compatto

#### 3. Server Push
Il server può inviare risorse prima che il client le richieda:
```
Client richiede: /index.html

Server risponde con:
- /index.html
- /style.css (push)
- /script.js (push)
- /logo.png (push)
```

#### 4. Header Compression (HPACK)
```
Prima richiesta:
:method: GET
:path: /index.html
:scheme: https
host: example.com
user-agent: Mozilla/5.0...

Seconda richiesta (compresso):
:method: GET
:path: /style.css
[2]  (riferimento a header già inviato)
[3]
```

**Risultati HTTP/2:**
- Riduzione latenza 50%
- Uso efficiente della banda
- Meno connessioni = meno overhead

---

### HTTP/3 (2022) - RFC 9114

**Problema di HTTP/2:** Ancora usa TCP

```
TCP Packet Loss:

Packet 1: ✓ Arrivato
Packet 2: ✗ PERSO!
Packet 3: ⏸ In attesa...
Packet 4: ⏸ In attesa...

HTTP/2 si blocca anche se Packet 3 e 4 
appartengono a stream diversi!
```

**Soluzione HTTP/3:** QUIC (Quick UDP Internet Connections)

#### Caratteristiche QUIC:

**1. Basato su UDP (non TCP)**
```
TCP:                    QUIC:
┌──────────────┐       ┌──────────────┐
│  HTTP/2      │       │   HTTP/3     │
├──────────────┤       ├──────────────┤
│     TLS      │       │  QUIC (TLS)  │
├──────────────┤       ├──────────────┤
│     TCP      │       │     UDP      │
├──────────────┤       ├──────────────┤
│      IP      │       │      IP      │
└──────────────┘       └──────────────┘
```

**2. Multiplexing Reale**
```
Stream 1: ████ ████ ████
Stream 2:      ██ ✗  ██  ← Packet loss NON blocca
Stream 3:        ███ ███  ← altri stream!
Stream 4:            ██ ██
```

**3. Connessione Più Veloce**
```
TCP + TLS 1.2:          QUIC (0-RTT):
┌─────────────┐        ┌─────────────┐
│ TCP SYN     │ RTT 1  │ QUIC Hello  │
│ TCP SYN-ACK │        │ + App Data! │
│ TCP ACK     │        └─────────────┘
│ TLS Hello   │ RTT 2  
│ TLS Response│        1 RTT invece di 2-3!
│ App Data    │ RTT 3
└─────────────┘
```

**4. Connection Migration**
```
WiFi → 4G cambio rete

TCP/HTTP/2:             QUIC/HTTP/3:
Nuova connessione       Continua sessione
completa! ✗             esistente! ✓

┌───────────┐           ┌───────────┐
│ Ricomincia│           │Connection │
│ da capo   │           │    ID     │
│  😞       │           │  😊       │
└───────────┘           └───────────┘
```

---

### Confronto Versioni HTTP

| Feature | HTTP/1.0 | HTTP/1.1 | HTTP/2 | HTTP/3 |
|---------|----------|----------|---------|---------|
| **Anno** | 1996 | 1999 | 2015 | 2022 |
| **Connessioni** | Una per richiesta | Persistenti | Multiplexing | Multiplexing |
| **Formato** | Testuale | Testuale | Binario | Binario |
| **Trasporto** | TCP | TCP | TCP | UDP (QUIC) |
| **Compressione Header** | ✗ | ✗ | ✓ (HPACK) | ✓ (QPACK) |
| **Server Push** | ✗ | ✗ | ✓ | ✓ |
| **Crittografia** | Opzionale | Opzionale | Opzionale | Obbligatoria |
| **Head-of-line** | N/A | Sì | A livello TCP | No |

---

## 1.3 Il Modello Client-Server e il Ruolo di Browser e Server

### Architettura Client-Server

HTTP si basa sul paradigma **client-server**, dove:
- Il **client** inizia sempre la comunicazione
- Il **server** risponde alle richieste
- La comunicazione è **unidirezionale** (client → server → client)

```
┌──────────────────────────────────────────────────────┐
│                  MODELLO CLIENT-SERVER                │
└──────────────────────────────────────────────────────┘

┌─────────────────┐                    ┌─────────────────┐
│     CLIENT      │                    │     SERVER      │
│                 │                    │                 │
│  • Browser      │                    │  • Apache       │
│  • App Mobile   │   ─────────────►   │  • Nginx        │
│  • CLI Tool     │   1. Richiesta     │  • Node.js      │
│  • IoT Device   │                    │  • IIS          │
│                 │   ◄─────────────   │                 │
│  Inizia sempre  │   2. Risposta      │  Risponde       │
│  comunicazione  │                    │  sempre         │
└─────────────────┘                    └─────────────────┘
```

### Flusso di Comunicazione

```
1. Client inizia connessione
   ┌────────┐
   │ Client │ ─── TCP SYN ──────►
   └────────┘

2. Server accetta
                              ┌────────┐
              ◄── TCP SYN-ACK ─── │ Server │
                              └────────┘

3. Connessione stabilita
   ┌────────┐                ┌────────┐
   │ Client │ ─── TCP ACK ──► │ Server │
   └────────┘                └────────┘

4. Client invia richiesta HTTP
   ┌────────┐                ┌────────┐
   │ GET /  │ ──────────────► │ Server │
   └────────┘                └────────┘

5. Server elabora e risponde
   ┌────────┐                ┌────────┐
   │ Client │ ◄────────────── │200 OK  │
   └────────┘                └────────┘
```

---

### Il Ruolo del Browser (Client)

Il browser è il client HTTP più comune. Le sue responsabilità includono:

#### 1. Parsing degli URL
```javascript
Utente digita: https://www.example.com/page.html?id=123

Browser analizza:
┌────────────────────────────────────────────────┐
│ Protocollo: https                              │
│ Host: www.example.com                          │
│ Porta: 443 (default per HTTPS)                 │
│ Path: /page.html                               │
│ Query: ?id=123                                 │
└────────────────────────────────────────────────┘
```

#### 2. Risoluzione DNS
```
1. Browser → DNS Resolver: "Qual è l'IP di www.example.com?"
2. DNS Resolver → Root DNS
3. Root DNS → TLD DNS (.com)
4. TLD DNS → Authoritative DNS
5. Authoritative DNS → DNS Resolver: "93.184.216.34"
6. DNS Resolver → Browser: "93.184.216.34"
```

#### 3. Costruzione Richiesta HTTP
```http
GET /page.html?id=123 HTTP/1.1
Host: www.example.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)
Accept: text/html,application/xhtml+xml
Accept-Language: it-IT,it;q=0.9,en;q=0.8
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
```

#### 4. Rendering della Pagina
```
HTML ricevuto → DOM Tree
CSS ricevuto → CSSOM Tree
        ↓
   Render Tree
        ↓
    Layout
        ↓
    Paint
```

#### 5. Gestione Risorse Multiple
```html
<!DOCTYPE html>
<html>
  <head>
    <link rel="stylesheet" href="/style.css">  ← Richiesta 2
    <script src="/script.js"></script>         ← Richiesta 3
  </head>
  <body>
    <img src="/logo.png">                      ← Richiesta 4
  </body>
</html>
```

Ogni risorsa genera una nuova richiesta HTTP!

---

### Il Ruolo del Server

Il server HTTP ha le seguenti responsabilità:

#### 1. Ascolto Connessioni
```python
# Pseudo-codice server
server = create_socket()
server.bind(('0.0.0.0', 80))
server.listen()

while True:
    client, address = server.accept()
    handle_request(client)
```

#### 2. Parsing Richiesta
```
Riceve:
GET /api/users/123 HTTP/1.1
Host: api.example.com

Estrae:
- Metodo: GET
- Path: /api/users/123
- Versione HTTP: 1.1
- Headers: Host, ecc.
```

#### 3. Routing e Processing
```javascript
// Esempio Express.js (Node.js)
app.get('/api/users/:id', (req, res) => {
    const userId = req.params.id;
    
    // 1. Valida input
    if (!isValid(userId)) {
        return res.status(400).json({ error: 'Invalid ID' });
    }
    
    // 2. Interroga database
    const user = database.findUser(userId);
    
    // 3. Risponde
    if (user) {
        res.status(200).json(user);
    } else {
        res.status(404).json({ error: 'User not found' });
    }
});
```

#### 4. Generazione Risposta
```http
HTTP/1.1 200 OK
Date: Mon, 27 Jul 2024 12:00:00 GMT
Server: Apache/2.4.41
Content-Type: application/json
Content-Length: 87
Connection: keep-alive

{
    "id": 123,
    "name": "Mario Rossi",
    "email": "mario@example.com"
}
```

---

### Componenti Intermedi

Oltre a client e server, esistono componenti intermedi:

#### 1. Proxy
```
┌────────┐      ┌───────┐      ┌────────┐
│ Client │ ───► │ Proxy │ ───► │ Server │
└────────┘      └───────┘      └────────┘
                    │
                 Funzioni:
                 • Cache
                 • Filtraggio
                 • Bilanciamento
                 • Anonimizzazione
```

#### 2. Cache/CDN
```
┌────────┐                      ┌────────┐
│ Client │ ───┐                 │ Origin │
└────────┘    │                 │ Server │
              │                 └────────┘
┌────────┐    ├─► ┌──────┐         ▲
│ Client │ ───┤   │ CDN  │ ────────┘
└────────┘    │   │Cache │ (se non in cache)
              │   └──────┘
┌────────┐    │       │
│ Client │ ───┘       └─► 99% risposte da cache
└────────┘
```

#### 3. Load Balancer
```
                  ┌────────────┐
┌────────┐        │   Load     │        ┌─────────┐
│        │        │  Balancer  │ ─────► │ Server1 │
│ Client │ ─────► │            │        ├─────────┤
│        │        │  (Nginx/   │ ─────► │ Server2 │
└────────┘        │   HAProxy) │        ├─────────┤
                  │            │ ─────► │ Server3 │
                  └────────────┘        └─────────┘
                       │
                  Algoritmi:
                  • Round Robin
                  • Least Connections
                  • IP Hash
```

---

## 1.4 URI, URL e URN: Gli Indirizzi del Web

### Gerarchia dei Concetti

```
┌─────────────────────────────────────────┐
│              URI                        │
│   (Uniform Resource Identifier)         │
│                                         │
│  ┌────────────────┐  ┌───────────────┐ │
│  │      URL       │  │      URN      │ │
│  │  (Locator)     │  │    (Name)     │ │
│  │  DOVE trovarlo │  │  COSA è       │ │
│  └────────────────┘  └───────────────┘ │
└─────────────────────────────────────────┘
```

---

### URI (Uniform Resource Identifier)

**Definizione:** Identificatore generico per qualsiasi risorsa.

**Sintassi Completa:**
```
scheme:[//[user[:password]@]host[:port]][/path][?query][#fragment]
```

**Componenti:**

```
https://john:pass123@www.example.com:8080/path/to/page?id=123&lang=it#section2
│      │   │        │ │                │ │              │           │          │
│      │   │        │ │                │ │              │           │          │
scheme user password host            port    path        query       fragment
```

#### 1. Scheme (Protocollo)
```
http://      → HTTP non sicuro
https://     → HTTP sicuro (TLS/SSL)
ftp://       → File Transfer Protocol
mailto:      → Email
file://      → File locale
ws://        → WebSocket
wss://       → WebSocket sicuro
```

#### 2. Authority (user@host:port)
```
Esempi:
admin@localhost:8080
user:password@192.168.1.1:3000
www.example.com              (porta di default)
```

#### 3. Path
```
/                           → Root
/users                      → Collezione
/users/123                  → Risorsa specifica
/api/v1/products/search     → Path annidato
```

#### 4. Query String
```
?id=123                     → Singolo parametro
?name=Mario&age=25          → Parametri multipli
?tags=html&tags=css         → Parametro ripetuto (array)
?search=hello%20world       → Caratteri codificati
```

#### 5. Fragment (Hash)
```
#section1                   → Ancora nella pagina
#top                        → Scroll to top
#                          → Fragment vuoto
```

---

### URL (Uniform Resource Locator)

**URL è un sottoinsieme di URI** che specifica **dove** trovare la risorsa.

#### Esempi URL Validi:

```
1. URL Semplice
   https://www.google.com

2. URL con Path
   https://www.example.com/products/laptop

3. URL con Query
   https://search.example.com/results?q=javascript&page=2

4. URL con Fragment
   https://docs.example.com/guide.html#installation

5. URL Completo
   https://admin:secret@api.example.com:8443/v2/users?active=true#section1
```

#### URL Encoding (Percent Encoding)

Caratteri speciali devono essere codificati:

```
Carattere   →   Codifica
─────────────────────────
spazio          %20 o +
!               %21
#               %23
$               %24
&               %26
=               %3D
@               %40
```

**Esempi:**
```
Original: Hello World!
Encoded:  Hello%20World%21

Original: name=Mario&age=25
Encoded:  name%3DMario%26age%3D25

Original: https://example.com/path?q=test search
Encoded:  https://example.com/path?q=test%20search
```

**In JavaScript:**
```javascript
// Encoding
encodeURIComponent("Hello World!") 
// → "Hello%20World%21"

encodeURI("https://example.com/hello world")
// → "https://example.com/hello%20world"

// Decoding
decodeURIComponent("Hello%20World%21")
// → "Hello World!"
```

---

### URN (Uniform Resource Name)

**URN identifica COSA è la risorsa**, non dove trovarla.

#### Sintassi:
```
urn:namespace:specific-string
```

#### Esempi:

```
1. ISBN (libri)
   urn:isbn:978-0-13-110362-7

2. ISSN (periodici)
   urn:issn:1234-5678

3. UUID
   urn:uuid:6e8bc430-9c3a-11d9-9669-0800200c9a66

4. Namespace personalizzato
   urn:mycompany:user:12345
```

#### Confronto URL vs URN:

```
URL (dove trovarlo):
https://library.example.com/books/978-0-13-110362-7

URN (cosa è):
urn:isbn:978-0-13-110362-7

Il libro è sempre lo stesso (URN),
ma può trovarsi in luoghi diversi (URL)
```

---

### Esempi Pratici Completi

#### Esempio 1: Sito Web
```
URL: https://www.example.com/products/laptop?color=black&size=15#reviews

Breakdown:
┌─────────────────────────────────────────────────────────────┐
│ Scheme:    https                                            │
│ Host:      www.example.com                                  │
│ Port:      443 (implicito per HTTPS)                        │
│ Path:      /products/laptop                                 │
│ Query:     color=black&size=15                              │
│ Fragment:  reviews                                          │
└─────────────────────────────────────────────────────────────┘

Significato:
- Connessione sicura (https)
- Al server www.example.com
- Richiedi la pagina del laptop
- Con filtri colore nero e dimensione 15"
- Scroll alla sezione recensioni
```

#### Esempio 2: API REST
```
URL: https://api.github.com/repos/facebook/react/issues?state=open&per_page=10

Breakdown:
┌─────────────────────────────────────────────────────────────┐
│ Scheme:    https                                            │
│ Host:      api.github.com                                   │
│ Path:      /repos/facebook/react/issues                     │
│ Query:     state=open&per_page=10                           │
└─────────────────────────────────────────────────────────────┘

Significato:
- API GitHub
- Repository facebook/react
- Issues endpoint
- Filtro: solo issue aperte
- Limite: 10 risultati per pagina
```

#### Esempio 3: Email
```
mailto:support@example.com?subject=Help&body=I%20need%20help

Breakdown:
┌─────────────────────────────────────────────────────────────┐
│ Scheme:    mailto                                           │
│ To:        support@example.com                              │
│ Query:     subject=Help&body=I%20need%20help                │
└─────────────────────────────────────────────────────────────┘

Apre client email con:
- Destinatario: support@example.com
- Oggetto: Help
- Corpo: I need help
```

---

### Best Practices per URI/URL

#### 1. ✅ URL Descrittivi e Leggibili
```
❌ Bad:  /page.php?id=123&type=prod
✅ Good: /products/laptop-dell-xps-15
```

#### 2. ✅ Usa Kebab-Case
```
❌ Bad:  /MyProducts/newArrivals
✅ Good: /my-products/new-arrivals
```

#### 3. ✅ Minuscole
```
❌ Bad:  /Products/LAPTOP
✅ Good: /products/laptop
```

#### 4. ✅ Evita Estensioni File
```
❌ Bad:  /about.html
✅ Good: /about
```

#### 5. ✅ Gerarchia Logica
```
❌ Bad:  /product-laptop-dell
✅ Good: /products/laptops/dell
```

#### 6. ✅ Query String per Filtri
```
✅ /products?category=laptop&brand=dell&sort=price
```

#### 7. ✅ Versioning API
```
✅ /api/v1/users
✅ /api/v2/users
```

---

### Strumenti per Lavorare con URL

#### JavaScript
```javascript
// Parsing URL
const url = new URL('https://example.com/path?id=123');
console.log(url.protocol);  // "https:"
console.log(url.host);      // "example.com"
console.log(url.pathname);  // "/path"
console.log(url.search);    // "?id=123"

// Costruzione URL
const params = new URLSearchParams();
params.append('name', 'Mario');
params.append('age', '25');
const url = `https://api.example.com/users?${params.toString()}`;
// https://api.example.com/users?name=Mario&age=25
```

#### Python
```python
from urllib.parse import urlparse, urlencode

# Parsing
url = urlparse('https://example.com/path?id=123')
print(url.scheme)   # 'https'
print(url.netloc)   # 'example.com'
print(url.path)     # '/path'

# Costruzione query string
params = {'name': 'Mario', 'age': 25}
query = urlencode(params)  # 'name=Mario&age=25'
```

#### curl (Command Line)
```bash
# URL encoding automatico
curl "https://example.com/search?q=hello world"

# URL encoding manuale
curl "https://example.com/search?q=hello%20world"

# URL complesso con autenticazione
curl -u user:pass "https://api.example.com/data?format=json"
```

---

## Riepilogo Capitolo 1

### Concetti Chiave

1. **HTTP** è il protocollo che fa funzionare il Web
2. Si è evoluto da HTTP/0.9 (1991) a HTTP/3 (2022)
3. Basato su modello **client-server**
4. **URI** identifica risorse (generico)
5. **URL** specifica dove trovare risorse (specifico)
6. **URN** identifica cosa sono le risorse (nome)

### Evoluzione in Sintesi

| Versione | Anno | Innovazione Principale |
|----------|------|------------------------|
| HTTP/0.9 | 1991 | Protocollo base |
| HTTP/1.0 | 1996 | Header e metodi |
| HTTP/1.1 | 1999 | Keep-alive, pipelining |
| HTTP/2 | 2015 | Multiplexing, binario |
| HTTP/3 | 2022 | QUIC (UDP), 0-RTT |

### Domande di Verifica

1. Qual è la differenza tra HTTP/1.1 e HTTP/2?
2. Cosa significa che HTTP è "stateless"?
3. Quali sono le componenti di un URL completo?
4. Quando si usa URN invece di URL?
5. Qual è il vantaggio principale di HTTP/3?

---

**Prossimo capitolo:** [02. Il Funzionamento di una Richiesta HTTP](02_funzionamento_richiesta_http.md)
