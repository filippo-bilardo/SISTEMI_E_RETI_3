# 5. Metodi HTTP

## 5.1 Panoramica dei Metodi HTTP

I **metodi HTTP** (anche chiamati **verbi HTTP**) definiscono l'azione che il client vuole eseguire sulla risorsa specificata.

### Metodi Standard

| Metodo | Scopo Principale | RFC |
|--------|------------------|-----|
| **GET** | Recuperare una risorsa | RFC 7231 |
| **POST** | Creare una risorsa / inviare dati | RFC 7231 |
| **PUT** | Aggiornare/sostituire una risorsa | RFC 7231 |
| **DELETE** | Eliminare una risorsa | RFC 7231 |
| **PATCH** | Modificare parzialmente una risorsa | RFC 5789 |
| **HEAD** | Come GET ma solo headers (no body) | RFC 7231 |
| **OPTIONS** | Descrivere opzioni di comunicazione | RFC 7231 |
| **CONNECT** | Stabilire un tunnel | RFC 7231 |
| **TRACE** | Loop-back test | RFC 7231 |

### Tabella Riassuntiva delle Caratteristiche

| Metodo | Sicuro | Idempotente | Cacheable | Request Body | Response Body |
|--------|--------|-------------|-----------|--------------|---------------|
| GET | ✅ | ✅ | ✅ | ❌ No | ✅ Sì |
| POST | ❌ | ❌ | ⚠️ Raro | ✅ Sì | ✅ Sì |
| PUT | ❌ | ✅ | ❌ | ✅ Sì | ✅ Sì |
| PATCH | ❌ | ❌ | ❌ | ✅ Sì | ✅ Sì |
| DELETE | ❌ | ✅ | ❌ | ⚠️ Raro | ✅ Sì |
| HEAD | ✅ | ✅ | ✅ | ❌ No | ❌ No |
| OPTIONS | ✅ | ✅ | ❌ | ❌ No | ✅ Sì |
| CONNECT | ❌ | ❌ | ❌ | ❌ No | ✅ Sì |
| TRACE | ✅ | ✅ | ❌ | ❌ No | ✅ Sì |

## 5.2 Metodi Sicuri (Safe Methods)

Un metodo è **sicuro** se non modifica lo stato del server.

### Definizione

> Un metodo è sicuro se eseguirlo non ha effetti collaterali osservabili sul server.

**Metodi sicuri:**
- ✅ **GET**: legge dati, non modifica
- ✅ **HEAD**: come GET, solo metadata
- ✅ **OPTIONS**: richiede informazioni
- ✅ **TRACE**: diagnostica

**Metodi NON sicuri:**
- ❌ **POST**: crea risorse
- ❌ **PUT**: modifica risorse
- ❌ **PATCH**: modifica parzialmente
- ❌ **DELETE**: elimina risorse
- ❌ **CONNECT**: stabilisce connessione

### Implicazioni

**Sicurezza:**
```
GET /api/users/123  →  ✅ Sicuro da ripetere
DELETE /api/users/123  →  ❌ NON sicuro da ripetere
```

**Browser:**
- I browser possono **pre-fetch** metodi sicuri
- I link (`<a href="...">`) usano sempre GET (sicuro)
- I form hanno `method="GET"` o `method="POST"`

**Cache:**
- I metodi sicuri possono essere cachati per default
- I metodi non sicuri richiedono esplicita autorizzazione per caching

**Esempi:**

✅ **Sicuro (GET):**
```http
GET /api/products?category=electronics HTTP/1.1
# Può essere chiamato infinite volte senza problemi
```

❌ **NON sicuro (POST):**
```http
POST /api/orders HTTP/1.1
Content-Type: application/json

{"product_id": 123, "quantity": 1}
# Ogni chiamata crea un nuovo ordine!
```

## 5.3 Metodi Idempotenti

Un metodo è **idempotente** se eseguirlo N volte ha lo stesso effetto di eseguirlo 1 volta.

### Definizione

> Un metodo è idempotente se il risultato finale sul server è lo stesso, indipendentemente da quante volte viene eseguito.

**Metodi idempotenti:**
- ✅ **GET**: leggere N volte = leggere 1 volta
- ✅ **PUT**: aggiornare N volte = aggiornare 1 volta (stesso valore)
- ✅ **DELETE**: eliminare N volte = eliminare 1 volta
- ✅ **HEAD**: come GET, idempotente
- ✅ **OPTIONS**: idempotente
- ✅ **TRACE**: idempotente

**Metodi NON idempotenti:**
- ❌ **POST**: creare N risorse ≠ creare 1 risorsa
- ❌ **PATCH**: dipende dall'implementazione

### Esempi

**✅ Idempotente (PUT):**
```http
PUT /api/users/123 HTTP/1.1
Content-Type: application/json

{"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}

# Eseguire 1 volta o 10 volte → stesso risultato
# L'utente 123 avrà quei dati
```

**✅ Idempotente (DELETE):**
```http
DELETE /api/users/123 HTTP/1.1

# Prima chiamata: elimina l'utente → 200 OK
# Seconda chiamata: utente già eliminato → 404 Not Found (ma stato finale uguale!)
# Terza chiamata: utente già eliminato → 404 Not Found
# Risultato finale: utente 123 non esiste (sempre)
```

**❌ NON idempotente (POST):**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario Rossi", "email": "mario@example.com"}

# Prima chiamata: crea utente con ID 456
# Seconda chiamata: crea utente con ID 457 (nuovo!)
# Terza chiamata: crea utente con ID 458 (nuovo!)
# Risultato: 3 utenti diversi creati
```

**⚠️ PATCH (dipende):**
```http
# NON idempotente (incremento)
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{"increment_login_count": 1}
# Ogni chiamata incrementa il contatore → NON idempotente

# Idempotente (set valore)
PATCH /api/users/123 HTTP/1.1
Content-Type: application/json

{"email": "nuovo@example.com"}
# Ogni chiamata imposta lo stesso valore → Idempotente
```

### Perché l'Idempotenza è Importante?

**1. Retry Safety**
```
Client → Server: PUT /api/users/123
Server: [timeout, nessuna risposta]
Client: Posso riprovare? ✅ Sì, è idempotente!
Client → Server: PUT /api/users/123 (retry)
Server: 200 OK
# Risultato corretto anche con retry
```

**2. Network Reliability**
```
Connessione instabile:
- Richiesta inviata ma risposta persa
- Client può riprovare in sicurezza (se idempotente)
- Sistemi distribuiti: eventual consistency
```

**3. API Design**
```
GET /api/resource    →  ✅ Idempotente (safe + idempotent)
PUT /api/resource    →  ✅ Idempotente (update in-place)
DELETE /api/resource →  ✅ Idempotente (delete)
POST /api/resource   →  ❌ NON idempotente (create)
```

## 5.4 GET - Recuperare Risorse

Il metodo **GET** è usato per recuperare dati dal server.

### Caratteristiche

- ✅ **Sicuro**: non modifica il server
- ✅ **Idempotente**: stesso risultato ogni volta
- ✅ **Cacheable**: può essere cachato
- ❌ **NO body**: i dati sono nella query string

### 5.4.1 Sintassi e Utilizzo

```http
GET /path/to/resource?param1=value1&param2=value2 HTTP/1.1
Host: example.com
```

**Esempi:**

**Recuperare singola risorsa:**
```http
GET /api/users/123 HTTP/1.1
Host: api.example.com
Accept: application/json

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json

{"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}
```

**Recuperare collezione:**
```http
GET /api/users HTTP/1.1
Host: api.example.com
Accept: application/json

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json

[
  {"id": 123, "name": "Mario Rossi"},
  {"id": 124, "name": "Luigi Verdi"},
  {"id": 125, "name": "Anna Bianchi"}
]
```

**Recuperare pagina HTML:**
```http
GET /about.html HTTP/1.1
Host: www.example.com
Accept: text/html

→ Risposta:
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>...
```

### 5.4.2 Query String e Parametri

La **query string** permette di passare parametri nella URL.

**Sintassi:**
```
?param1=value1&param2=value2&param3=value3
```

**Esempi comuni:**

**1. Paginazione**
```http
GET /api/products?page=2&limit=20 HTTP/1.1
# Pagina 2, 20 elementi per pagina
```

**2. Filtri**
```http
GET /api/products?category=electronics&price_min=100&price_max=500 HTTP/1.1
# Prodotti elettronici tra 100€ e 500€
```

**3. Ordinamento**
```http
GET /api/products?sort=price&order=asc HTTP/1.1
# Ordina per prezzo crescente
```

**4. Ricerca**
```http
GET /api/products?q=laptop&brand=dell HTTP/1.1
# Cerca "laptop" del brand "dell"
```

**5. Selezione campi**
```http
GET /api/users/123?fields=id,name,email HTTP/1.1
# Restituisci solo id, name, email (non tutti i campi)
```

**6. Espansione relazioni**
```http
GET /api/users/123?expand=posts,comments HTTP/1.1
# Include anche posts e comments dell'utente
```

**Esempio complesso:**
```http
GET /api/products?category=electronics&brand=apple&price_max=2000&sort=created_at&order=desc&page=1&limit=10&fields=id,name,price HTTP/1.1
Host: api.example.com

# Traduzione:
# - Categoria: electronics
# - Brand: apple
# - Prezzo massimo: 2000€
# - Ordina per data creazione (decrescente)
# - Prima pagina, 10 risultati
# - Campi: solo id, name, price
```

### 5.4.3 Limitazioni e Best Practices

#### Limitazioni

**1. Lunghezza URL**
```
Browser limits:
- Chrome: ~2MB
- Firefox: ~65,536 caratteri
- Safari: ~80,000 caratteri
- IE/Edge: ~2,083 caratteri ⚠️

Server limits:
- Apache: 8KB (default)
- Nginx: 4KB-8KB (default)
- IIS: 16KB (default)
```

**Problema:**
```http
# URL troppo lungo (può essere troncato)
GET /api/search?keywords=very+long+search+query+with+hundreds+of+words...&filters=...&options=... HTTP/1.1
```

**Soluzione:**
```http
# Usa POST per query complesse
POST /api/search HTTP/1.1
Content-Type: application/json

{
  "keywords": "very long search query with hundreds of words...",
  "filters": {...},
  "options": {...}
}
```

**2. Sicurezza**
```
⚠️ Dati sensibili nella URL sono visibili:
- Browser history
- Server logs
- Proxy logs
- Referer headers

❌ MAI fare così:
GET /api/login?username=mario&password=secret123

✅ Usa POST invece:
POST /api/login
Content-Type: application/json

{"username": "mario", "password": "secret123"}
```

**3. NO Body**
```http
# ❌ SBAGLIATO
GET /api/users HTTP/1.1
Content-Type: application/json

{"filters": {"active": true}}

# ✅ CORRETTO
GET /api/users?active=true HTTP/1.1
```

#### Best Practices

**1. Naming Convention**
```http
# ✅ Buono: sostantivi plurali
GET /api/users
GET /api/products
GET /api/orders

# ❌ Evitare: verbi, singolare
GET /api/getUsers
GET /api/user
```

**2. Gerarchie**
```http
# ✅ Risorse nidificate
GET /api/users/123/posts
GET /api/users/123/posts/456/comments

# Leggibile e intuitivo
```

**3. Versioning**
```http
# ✅ Versione nell'URL
GET /api/v1/users
GET /api/v2/users

# ✅ Versione nell'header (alternativa)
GET /api/users
Accept: application/vnd.example.v2+json
```

**4. Filtri descrittivi**
```http
# ✅ Chiaro e leggibile
GET /api/products?category=electronics&in_stock=true&price_max=1000

# ❌ Oscuro
GET /api/products?c=1&s=1&p=1000
```

**5. Paginazione consistente**
```http
# ✅ Offset/Limit
GET /api/users?offset=0&limit=20

# ✅ Page/Size
GET /api/users?page=1&size=20

# ✅ Cursor (per grandi dataset)
GET /api/users?cursor=abc123&limit=20
```

## 5.5 POST - Creare Risorse

Il metodo **POST** è usato per inviare dati al server, tipicamente per creare nuove risorse.

### Caratteristiche

- ❌ **NON sicuro**: modifica il server
- ❌ **NON idempotente**: chiamate multiple = risorse multiple
- ⚠️ **Cacheable**: raramente cachato
- ✅ **Body**: tipicamente contiene dati

### 5.5.1 Sintassi e Utilizzo

```http
POST /path/to/collection HTTP/1.1
Host: example.com
Content-Type: media-type
Content-Length: size

[body data]
```

**Esempio: Creare utente**
```http
POST /api/users HTTP/1.1
Host: api.example.com
Content-Type: application/json
Content-Length: 85

{
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "role": "developer"
}

→ Risposta:
HTTP/1.1 201 Created
Location: /api/users/456
Content-Type: application/json

{
  "id": 456,
  "name": "Mario Rossi",
  "email": "mario.rossi@example.com",
  "role": "developer",
  "created_at": "2025-10-30T12:00:00Z"
}
```

**Esempio: Submit form**
```http
POST /contact HTTP/1.1
Host: www.example.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 65

name=Mario+Rossi&email=mario%40example.com&message=Ciao

→ Risposta:
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
<body>
  <h1>Grazie!</h1>
  <p>Il tuo messaggio è stato inviato.</p>
</body>
</html>
```

### 5.5.2 Content-Type e Formato Dati

**1. JSON (application/json)**
```http
POST /api/products HTTP/1.1
Content-Type: application/json

{
  "name": "Laptop Dell XPS",
  "price": 1499.99,
  "category": "electronics"
}
```

**2. Form URL-encoded (application/x-www-form-urlencoded)**
```http
POST /login HTTP/1.1
Content-Type: application/x-www-form-urlencoded

username=mario&password=secret&remember=on
```

**3. Multipart (multipart/form-data)**
```http
POST /api/upload HTTP/1.1
Content-Type: multipart/form-data; boundary=----Boundary123

------Boundary123
Content-Disposition: form-data; name="title"

My Photo
------Boundary123
Content-Disposition: form-data; name="file"; filename="photo.jpg"
Content-Type: image/jpeg

[binary data]
------Boundary123--
```

**4. XML (application/xml)**
```http
POST /api/data HTTP/1.1
Content-Type: application/xml

<?xml version="1.0"?>
<product>
  <name>Laptop</name>
  <price>1499.99</price>
</product>
```

**5. Plain Text (text/plain)**
```http
POST /api/notes HTTP/1.1
Content-Type: text/plain

Questa è una nota semplice.
```

### 5.5.3 POST vs GET

| Aspetto | GET | POST |
|---------|-----|------|
| **Scopo** | Recuperare dati | Inviare dati |
| **Dati** | Query string (URL) | Body |
| **Sicuro** | ✅ Sì | ❌ No |
| **Idempotente** | ✅ Sì | ❌ No |
| **Cacheable** | ✅ Sì | ⚠️ Raramente |
| **Lunghezza** | Limitata (URL) | Illimitata (body) |
| **Bookmark** | ✅ Sì | ❌ No |
| **History** | ✅ Sì | ❌ No (solitamente) |
| **Back/Forward** | ✅ Safe | ⚠️ Richiede conferma |
| **Visibilità dati** | URL (visibili) | Body (nascosti) |
| **Sicurezza** | ⚠️ Non per dati sensibili | ✅ OK per dati sensibili |

**Quando usare GET:**
```http
# ✅ Recuperare dati
GET /api/products?category=electronics

# ✅ Ricerca
GET /search?q=laptop

# ✅ Filtri
GET /api/users?role=admin&active=true
```

**Quando usare POST:**
```http
# ✅ Creare risorsa
POST /api/users

# ✅ Login (dati sensibili)
POST /api/login

# ✅ Upload file
POST /api/upload

# ✅ Operazioni complesse
POST /api/complex-calculation

# ✅ Ricerca complessa (troppi parametri per URL)
POST /api/advanced-search
```

## 5.6 PUT - Aggiornare Risorse

Il metodo **PUT** è usato per aggiornare una risorsa esistente o crearla se non esiste.

### Caratteristiche

- ❌ **NON sicuro**: modifica il server
- ✅ **Idempotente**: stesso risultato ripetuto N volte
- ❌ **NON cacheable**
- ✅ **Body**: contiene la risorsa completa

### 5.6.1 Sintassi e Utilizzo

```http
PUT /path/to/resource HTTP/1.1
Host: example.com
Content-Type: media-type

[complete resource representation]
```

**Esempio: Aggiornare utente**
```http
PUT /api/users/123 HTTP/1.1
Host: api.example.com
Content-Type: application/json

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.rossi.new@example.com",
  "role": "senior-developer",
  "active": true
}

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json

{
  "id": 123,
  "name": "Mario Rossi",
  "email": "mario.rossi.new@example.com",
  "role": "senior-developer",
  "active": true,
  "updated_at": "2025-10-30T12:00:00Z"
}
```

**Importante:** PUT richiede la **risorsa completa**, non solo i campi modificati.

### 5.6.2 PUT vs POST

| Aspetto | POST | PUT |
|---------|------|-----|
| **Scopo** | Creare risorsa | Aggiornare/sostituire risorsa |
| **Idempotente** | ❌ No | ✅ Sì |
| **URI** | Collezione (`/users`) | Risorsa specifica (`/users/123`) |
| **Risultato** | Nuova risorsa | Risorsa aggiornata |
| **ID** | Generato dal server | Specificato dal client |
| **Ripetizione** | Crea duplicati | Stesso risultato |

**Esempi comparativi:**

**POST - Creare (ID generato dal server):**
```http
POST /api/users HTTP/1.1
Content-Type: application/json

{"name": "Mario", "email": "mario@example.com"}

→ HTTP/1.1 201 Created
  Location: /api/users/456
  {"id": 456, "name": "Mario", "email": "mario@example.com"}

# Seconda chiamata:
POST /api/users HTTP/1.1
{"name": "Mario", "email": "mario@example.com"}

→ HTTP/1.1 201 Created
  Location: /api/users/457
  {"id": 457, "name": "Mario", "email": "mario@example.com"}
  
# Due utenti diversi creati! (NON idempotente)
```

**PUT - Aggiornare (ID specificato dal client):**
```http
PUT /api/users/123 HTTP/1.1
Content-Type: application/json

{"id": 123, "name": "Mario", "email": "mario@example.com"}

→ HTTP/1.1 200 OK
  {"id": 123, "name": "Mario", "email": "mario@example.com"}

# Seconda chiamata:
PUT /api/users/123 HTTP/1.1
{"id": 123, "name": "Mario", "email": "mario@example.com"}

→ HTTP/1.1 200 OK
  {"id": 123, "name": "Mario", "email": "mario@example.com"}
  
# Stesso utente, stesso risultato! (Idempotente)
```

### 5.6.3 Idempotenza

PUT è **idempotente**: chiamarlo N volte ha lo stesso effetto di chiamarlo 1 volta.

**Esempio:**
```http
# Prima chiamata
PUT /api/users/123 HTTP/1.1
{"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}

→ Utente 123: name="Mario Rossi", email="mario@example.com"

# Seconda chiamata (stessi dati)
PUT /api/users/123 HTTP/1.1
{"id": 123, "name": "Mario Rossi", "email": "mario@example.com"}

→ Utente 123: name="Mario Rossi", email="mario@example.com"
# Nessun cambiamento! Idempotente ✅

# Terza chiamata (dati diversi)
PUT /api/users/123 HTTP/1.1
{"id": 123, "name": "Luigi Verdi", "email": "luigi@example.com"}

→ Utente 123: name="Luigi Verdi", email="luigi@example.com"

# Quarta chiamata (stessi dati della terza)
PUT /api/users/123 HTTP/1.1
{"id": 123, "name": "Luigi Verdi", "email": "luigi@example.com"}

→ Utente 123: name="Luigi Verdi", email="luigi@example.com"
# Di nuovo nessun cambiamento! Idempotente ✅
```

**Beneficio dell'idempotenza:**
```
Scenario: Network timeout

Client → Server: PUT /api/users/123 {...}
Server: [processa richiesta]
Server → Client: 200 OK [risposta persa per problema di rete]
Client: [timeout, non ha ricevuto risposta]
Client: Posso riprovare? ✅ SÌ, è idempotente!
Client → Server: PUT /api/users/123 {...} [stesso payload]
Server: [processa richiesta di nuovo]
Server → Client: 200 OK
Client: ✅ Successo!

Risultato: Corretto! La risorsa è nello stato desiderato.
```

**PUT per creare (se non esiste):**
```http
# Risorsa non esiste
PUT /api/users/999 HTTP/1.1
{"id": 999, "name": "Nuovo Utente", "email": "nuovo@example.com"}

→ HTTP/1.1 201 Created
  Location: /api/users/999
  {"id": 999, "name": "Nuovo Utente", "email": "nuovo@example.com"}

# Risorsa esiste
PUT /api/users/999 HTTP/1.1
{"id": 999, "name": "Utente Aggiornato", "email": "aggiornato@example.com"}

→ HTTP/1.1 200 OK
  {"id": 999, "name": "Utente Aggiornato", "email": "aggiornato@example.com"}
```

## 5.7 DELETE - Eliminare Risorse

Il metodo **DELETE** è usato per eliminare una risorsa.

### Caratteristiche

- ❌ **NON sicuro**: modifica il server
- ✅ **Idempotente**: eliminare N volte = eliminare 1 volta
- ❌ **NON cacheable**
- ⚠️ **Body**: solitamente assente (opzionale)

### 5.7.1 Sintassi e Utilizzo

```http
DELETE /path/to/resource HTTP/1.1
Host: example.com
```

**Esempio: Eliminare utente**
```http
DELETE /api/users/123 HTTP/1.1
Host: api.example.com

→ Risposta (successo):
HTTP/1.1 204 No Content
```

**Oppure con body nella risposta:**
```http
DELETE /api/users/123 HTTP/1.1

→ Risposta:
HTTP/1.1 200 OK
Content-Type: application/json

{
  "message": "Utente eliminato con successo",
  "deleted_id": 123,
  "deleted_at": "2025-10-30T12:00:00Z"
}
```

**Risorsa non trovata:**
```http
DELETE /api/users/999 HTTP/1.1

→ Risposta:
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "USER_NOT_FOUND",
  "message": "L'utente con ID 999 non esiste"
}
```

**Risorsa già eliminata (idempotenza):**
```http
# Prima chiamata
DELETE /api/users/123 HTTP/1.1
→ HTTP/1.1 204 No Content (eliminato)

# Seconda chiamata (risorsa già eliminata)
DELETE /api/users/123 HTTP/1.1
→ HTTP/1.1 404 Not Found (non esiste più)
# Oppure: HTTP/1.1 204 No Content (alcune API trattano come successo)

# Stato finale: utente 123 non esiste (idempotente ✅)
```

### 5.7.2 Considerazioni di Sicurezza

**1. Autenticazione e Autorizzazione**
```http
# ❌ Senza autenticazione
DELETE /api/users/123 HTTP/1.1

→ HTTP/1.1 401 Unauthorized
  WWW-Authenticate: Bearer realm="API"

# ✅ Con autenticazione
DELETE /api/users/123 HTTP/1.1
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

→ Verifica:
  - Utente autenticato? ✅
  - Ha permessi di eliminare? ✅
  → HTTP/1.1 204 No Content

# ❌ Senza permessi sufficienti
DELETE /api/users/456 HTTP/1.1
Authorization: Bearer [token_utente_normale]

→ HTTP/1.1 403 Forbidden
  {
    "error": "INSUFFICIENT_PERMISSIONS",
    "message": "Non hai i permessi per eliminare questo utente"
  }
```

**2. Soft Delete vs Hard Delete**

**Hard Delete (eliminazione fisica):**
```http
DELETE /api/users/123 HTTP/1.1

# Record eliminato dal database
→ Record non esiste più, irrecuperabile
```

**Soft Delete (eliminazione logica):**
```http
DELETE /api/users/123 HTTP/1.1

# Record marcato come eliminato (deleted_at != null)
→ Record esiste ancora, ma nascosto
→ Può essere recuperato se necessario

# Implementazione:
{
  "id": 123,
  "name": "Mario Rossi",
  "deleted_at": "2025-10-30T12:00:00Z",
  "deleted_by": 456
}

# Query GET /api/users esclude i record con deleted_at != null
```

**3. Cascading Deletes**
```http
DELETE /api/users/123 HTTP/1.1

# Cosa succede a:
# - Posts dell'utente?
# - Comments dell'utente?
# - Ordini dell'utente?

# Opzioni:
# 1. Cascade: elimina tutto
# 2. Nullify: imposta user_id = null
# 3. Restrict: blocca se ha dipendenze
# 4. Error: ritorna errore se ha dipendenze
```

**Esempio con dipendenze:**
```http
DELETE /api/users/123 HTTP/1.1

→ HTTP/1.1 409 Conflict
  Content-Type: application/json
  
  {
    "error": "CANNOT_DELETE",
    "message": "Impossibile eliminare utente con ordini attivi",
    "details": {
      "active_orders": 3,
      "pending_payments": 1
    }
  }
```

**4. Confirmation Token (per azioni critiche)**
```http
# Step 1: Richiedi token di conferma
POST /api/users/123/delete-request HTTP/1.1

→ HTTP/1.1 200 OK
  {
    "confirmation_token": "abc123xyz",
    "expires_at": "2025-10-30T12:05:00Z"
  }

# Step 2: Elimina con token
DELETE /api/users/123 HTTP/1.1
X-Confirmation-Token: abc123xyz

→ HTTP/1.1 204 No Content
```

**5. Audit Log**
```http
DELETE /api/users/123 HTTP/1.1
Authorization: Bearer [admin_token]

# Logged:
{
  "action": "DELETE",
  "resource": "/api/users/123",
  "performed_by": 456,
  "timestamp": "2025-10-30T12:00:00Z",
  "ip_address": "192.168.1.100",
  "user_agent": "Mozilla/5.0..."
}
```

**Best Practices per DELETE:**

✅ **Do:**
- Richiedi autenticazione
- Verifica autorizzazioni
- Usa soft delete per dati importanti
- Implementa audit logging
- Ritorna status appropriato (204 o 200)
- Gestisci dipendenze (cascade, restrict, etc.)
- Considera confirmation token per azioni critiche

❌ **Don't:**
- Permettere eliminazione senza autenticazione
- Hard delete di dati critici senza backup
- Ignorare dipendenze
- Esporre dettagli interni negli errori

---

## Continua...

Nei prossimi paragrafi approfondiremo:
- 5.8 HEAD - Metadati delle risorse
- 5.9 OPTIONS - Opzioni di comunicazione
- 5.10 PATCH - Modifiche parziali
- 5.11 CONNECT - Tunnel HTTP
- 5.12 TRACE - Debugging delle richieste

**Data ultimo aggiornamento**: Ottobre 2025  
**Versione guida**: 1.0
