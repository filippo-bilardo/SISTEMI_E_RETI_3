# 02 — Codici di Stato HTTP e Header

## Codici di Stato HTTP

I **codici di stato HTTP** sono numeri a 3 cifre che il server include nella riga di stato di ogni risposta. Indicano il risultato dell'elaborazione della richiesta. La prima cifra definisce la **classe**:

| Classe | Range | Significato generale |
|--------|-------|---------------------|
| **1xx** | 100–199 | Informativi — richiesta ricevuta, elaborazione in corso |
| **2xx** | 200–299 | ✅ Successo — richiesta ricevuta, capita e accettata |
| **3xx** | 300–399 | 🔀 Redirect — ulteriori azioni necessarie per completare |
| **4xx** | 400–499 | ❌ Errore client — richiesta errata o non autorizzata |
| **5xx** | 500–599 | ⚠️ Errore server — il server non è riuscito a soddisfare |

---

## Classe 1xx — Informativi

Raramente usati direttamente dagli sviluppatori. Segnalano uno stato intermedio.

| Codice | Nome | Descrizione | Uso tipico |
|--------|------|-------------|-----------|
| `100` | Continue | Il server ha ricevuto gli header, il client può inviare il body | Richieste con body grande (pre-verifica con `Expect: 100-continue`) |
| `101` | Switching Protocols | Il server accetta il cambio di protocollo richiesto | Upgrade da HTTP a WebSocket |
| `103` | Early Hints | Il server invia header di pre-caricamento prima della risposta finale | Ottimizzazione prestazioni (Link: preload) |

---

## Classe 2xx — Successo ✅

| Codice | Nome | Descrizione | Uso tipico |
|--------|------|-------------|-----------|
| `200` | **OK** | Richiesta eseguita con successo | GET di una pagina, risposta API |
| `201` | **Created** | Risorsa creata con successo | POST che crea un nuovo record (es. nuovo utente) |
| `202` | Accepted | Richiesta accettata ma elaborazione asincrona | Job in background, elaborazione differita |
| `204` | **No Content** | Successo ma nessun contenuto da restituire | DELETE eseguito, PUT/PATCH senza risposta |
| `206` | Partial Content | Risposta parziale (range request) | Download ripreso, streaming video |

### Esempio di risposta 201 Created
```http
HTTP/1.1 201 Created
Location: /api/utenti/42
Content-Type: application/json

{"id": 42, "nome": "Mario Rossi", "email": "mario@esempio.it"}
```

---

## Classe 3xx — Redirect 🔀

Il client deve effettuare una nuova richiesta verso un URL diverso (indicato nell'header `Location`).

| Codice | Nome | Tipo | Descrizione | Caso d'uso |
|--------|------|------|-------------|-----------|
| `301` | **Moved Permanently** | Permanente | La risorsa è stata spostata definitivamente | Cambio dominio, URL ristrutturati |
| `302` | **Found** | Temporaneo | La risorsa è temporaneamente altrove | Redirect temporaneo, login → dashboard |
| `303` | See Other | Temporaneo | Vai a vedere un'altra URL (sempre con GET) | Post/Redirect/Get pattern |
| `304` | **Not Modified** | Cache | La risorsa non è cambiata dalla cache | Risposta a If-Modified-Since / If-None-Match |
| `307` | Temporary Redirect | Temporaneo | Come 302 ma mantiene il metodo originale | Redirect POST → POST (non cambia in GET) |
| `308` | Permanent Redirect | Permanente | Come 301 ma mantiene il metodo originale | Redirect permanente POST → POST |

### 301 vs 302: differenza pratica

```
301 Moved Permanently:
  Browser memorizza il redirect → nelle visite future va direttamente al nuovo URL
  I motori di ricerca trasferiscono il "link juice" al nuovo URL
  Cache: permanente

302 Found (Temporary):
  Browser non memorizza il redirect → ogni volta fa la richiesta all'URL originale
  I motori di ricerca tengono l'URL originale nell'indice
  Cache: non permanente
```

### Esempio di risposta 301
```http
HTTP/1.1 301 Moved Permanently
Location: https://www.esempio.it/nuova-pagina
Cache-Control: max-age=31536000
```

---

## Classe 4xx — Errori del Client ❌

Il problema è nella richiesta inviata dal client (URL sbagliato, autenticazione mancante, ecc.).

| Codice | Nome | Descrizione | Causa tipica |
|--------|------|-------------|--------------|
| `400` | **Bad Request** | Richiesta malformata | Sintassi errata, parametri mancanti |
| `401` | **Unauthorized** | Autenticazione richiesta ma non fornita | Mancano credenziali (login necessario) |
| `403` | **Forbidden** | Accesso negato nonostante autenticazione | Permessi insufficienti (autenticato ma non autorizzato) |
| `404` | **Not Found** | Risorsa non trovata | URL inesistente, risorsa eliminata |
| `405` | Method Not Allowed | Metodo HTTP non consentito per questa risorsa | POST su endpoint solo GET |
| `408` | Request Timeout | Il client ha impiegato troppo tempo a inviare la richiesta | Connessione lenta, client bloccato |
| `409` | Conflict | Conflitto con lo stato attuale della risorsa | Upload di versione obsoleta, duplicato |
| `410` | Gone | La risorsa è stata rimossa definitivamente | Pagina cancellata intenzionalmente |
| `413` | Content Too Large | Body della richiesta troppo grande | Upload file oltre il limite |
| `414` | URI Too Long | URL troppo lungo | Query string troppo lunga |
| `415` | Unsupported Media Type | Tipo di contenuto non accettato | JSON inviato dove si aspetta XML |
| `422` | Unprocessable Entity | Dati semanticamente errati | Validazione form fallita (email non valida) |
| `429` | Too Many Requests | Troppe richieste (rate limiting) | Superato il limite di chiamate API |

### 401 vs 403: differenza fondamentale

```
401 Unauthorized:
  "Non so chi sei" — mancano le credenziali
  Risposta include: WWW-Authenticate: Basic realm="Area Riservata"
  Soluzione: inviare credenziali di autenticazione

403 Forbidden:
  "So chi sei, ma non puoi accedere" — hai fatto login ma non hai il permesso
  Il server conosce l'identità ma rifiuta l'accesso
  Soluzione: richiedere permessi all'amministratore
```

---

## Classe 5xx — Errori del Server ⚠️

Il server ha ricevuto una richiesta valida ma non è riuscito a soddisfarla per un problema interno.

| Codice | Nome | Descrizione | Causa tipica |
|--------|------|-------------|--------------|
| `500` | **Internal Server Error** | Errore generico del server | Bug nel codice server-side, eccezione non gestita |
| `501` | Not Implemented | Metodo non implementato dal server | Server non supporta il metodo richiesto |
| `502` | **Bad Gateway** | Il gateway ha ricevuto una risposta invalida | Proxy/load balancer non riesce a contattare il backend |
| `503` | **Service Unavailable** | Servizio temporaneamente non disponibile | Server sovraccarico, manutenzione programmata |
| `504` | Gateway Timeout | Il gateway non ha ricevuto risposta in tempo | Backend troppo lento, timeout |
| `507` | Insufficient Storage | Spazio di archiviazione esaurito | Disco pieno |

### Esempio di risposta 503 con Retry-After
```http
HTTP/1.1 503 Service Unavailable
Retry-After: 120
Content-Type: text/html

<html><body>Il servizio è in manutenzione. Riprova tra 2 minuti.</body></html>
```

---

## Header HTTP Principali

Gli **header HTTP** sono coppie `Nome: Valore` che trasportano metadati sulla richiesta o sulla risposta. Sono case-insensitive nel nome (per convenzione si usa PascalCase con trattini).

### Header di Richiesta (inviati dal client)

| Header | Descrizione | Esempio |
|--------|-------------|---------|
| `Host` | **Obbligatorio in HTTP/1.1** — dominio del server richiesto (per virtual hosting) | `Host: www.esempio.it` |
| `User-Agent` | Identifica il client (browser, versione, OS) | `User-Agent: Mozilla/5.0 (Windows NT 10.0) Chrome/120` |
| `Accept` | Tipi di contenuto accettati dal client | `Accept: text/html,application/xhtml+xml,*/*;q=0.8` |
| `Accept-Language` | Lingue preferite per il contenuto | `Accept-Language: it-IT,it;q=0.9,en;q=0.8` |
| `Accept-Encoding` | Algoritmi di compressione accettati | `Accept-Encoding: gzip, deflate, br` |
| `Connection` | Tipo di connessione richiesto | `Connection: keep-alive` |
| `Content-Type` | Tipo del body inviato (in POST/PUT) | `Content-Type: application/json` |
| `Content-Length` | Dimensione in byte del body | `Content-Length: 152` |
| `Authorization` | Credenziali di autenticazione | `Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...` |
| `Cookie` | Cookie precedentemente impostati dal server | `Cookie: session_id=abc123; lang=it` |
| `Referer` | URL della pagina da cui proviene la richiesta | `Referer: https://www.google.it/search?q=...` |
| `If-None-Match` | ETag della versione in cache (per cache validation) | `If-None-Match: "abc123def456"` |
| `If-Modified-Since` | Data dell'ultima versione in cache | `If-Modified-Since: Mon, 14 Jan 2024 10:00:00 GMT` |
| `Range` | Richiesta di un sottoinsieme della risorsa | `Range: bytes=0-1023` |

### Header di Risposta (inviati dal server)

| Header | Descrizione | Esempio |
|--------|-------------|---------|
| `Content-Type` | Tipo MIME del body della risposta | `Content-Type: text/html; charset=UTF-8` |
| `Content-Length` | Dimensione in byte del body | `Content-Length: 2048` |
| `Content-Encoding` | Compressione applicata al body | `Content-Encoding: gzip` |
| `Date` | Data e ora della risposta | `Date: Mon, 15 Jan 2024 10:30:00 GMT` |
| `Server` | Identificazione del software server | `Server: nginx/1.24.0 (Ubuntu)` |
| `Location` | URL di redirect (usato con 3xx) | `Location: https://www.esempio.it/nuova-pagina` |
| `Set-Cookie` | Imposta un cookie nel browser del client | `Set-Cookie: session=abc123; HttpOnly; Secure; Path=/` |
| `Cache-Control` | Direttive di caching | `Cache-Control: max-age=3600, public` |
| `Expires` | Data di scadenza della cache (vecchio metodo) | `Expires: Tue, 16 Jan 2024 10:30:00 GMT` |
| `ETag` | Identificatore univoco versione risorsa | `ETag: "abc123def456789"` |
| `Last-Modified` | Data ultima modifica della risorsa | `Last-Modified: Sun, 14 Jan 2024 08:00:00 GMT` |
| `WWW-Authenticate` | Schema di autenticazione richiesto (con 401) | `WWW-Authenticate: Basic realm="Area Admin"` |
| `Access-Control-Allow-Origin` | CORS — origini permesse | `Access-Control-Allow-Origin: https://www.esempio.it` |
| `Strict-Transport-Security` | HSTS — forza HTTPS | `Strict-Transport-Security: max-age=31536000; includeSubDomains` |
| `X-Frame-Options` | Protezione da clickjacking | `X-Frame-Options: DENY` |
| `Transfer-Encoding` | Modalità di trasferimento del body | `Transfer-Encoding: chunked` |

---

## MIME Types Comuni

**MIME** (*Multipurpose Internet Mail Extensions*) è lo standard per identificare il tipo di contenuto. Usato nell'header `Content-Type`.

| MIME Type | Descrizione | Usato per |
|-----------|-------------|-----------|
| `text/html` | Documento HTML | Pagine web |
| `text/css` | Foglio di stile CSS | Stili web |
| `text/javascript` | Codice JavaScript | Script client |
| `text/plain` | Testo puro senza formattazione | Log, note |
| `application/json` | Dati in formato JSON | API REST, AJAX |
| `application/xml` | Dati in formato XML | Web services SOAP |
| `application/pdf` | Documento PDF | Download documenti |
| `application/zip` | Archivio ZIP | Download archivi |
| `application/octet-stream` | Dati binari generici | Download file generico |
| `application/x-www-form-urlencoded` | Form HTML encodato | Invio form (POST) |
| `multipart/form-data` | Form con upload file | Upload file |
| `image/jpeg` | Immagine JPEG | Fotografie |
| `image/png` | Immagine PNG | Grafica con trasparenza |
| `image/gif` | Immagine GIF | Animazioni |
| `image/svg+xml` | Grafica vettoriale SVG | Logo, icone scalabili |
| `image/webp` | Immagine WebP (Google) | Immagini web ottimizzate |
| `audio/mpeg` | Audio MP3 | File audio |
| `video/mp4` | Video MP4 | Streaming video |
| `font/woff2` | Font web WOFF2 | Tipografia web |

---

## Esempi di Transazioni HTTP Complete

### Esempio 1: Navigazione web normale

**Richiesta:**
```http
GET /blog/articolo-http HTTP/1.1
Host: www.techblog.it
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120
Accept: text/html,application/xhtml+xml,*/*;q=0.8
Accept-Language: it-IT,it;q=0.9
Accept-Encoding: gzip, deflate, br
Connection: keep-alive
Cookie: _ga=GA1.2.123456789; preferenze=tema_scuro

```

**Risposta:**
```http
HTTP/1.1 200 OK
Date: Mon, 15 Jan 2024 14:22:00 GMT
Server: nginx/1.24.0
Content-Type: text/html; charset=UTF-8
Content-Encoding: gzip
Content-Length: 8432
Cache-Control: max-age=3600, public
ETag: "d4e5f6a7b8c9"
Last-Modified: Mon, 15 Jan 2024 09:00:00 GMT
Connection: keep-alive

<!DOCTYPE html>
<html lang="it">...
```

### Esempio 2: Login con form

**Richiesta POST:**
```http
POST /utenti/login HTTP/1.1
Host: www.portale.it
Content-Type: application/x-www-form-urlencoded
Content-Length: 38
Connection: keep-alive
Referer: https://www.portale.it/login

email=mario%40esempio.it&password=segreto
```

**Risposta con redirect e cookie:**
```http
HTTP/1.1 302 Found
Location: /dashboard
Set-Cookie: session_token=eyJhbGciOiJIUzI1NiJ9...; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=3600
Content-Length: 0

```

### Esempio 3: API REST — Creazione risorsa

**Richiesta POST JSON:**
```http
POST /api/v1/prodotti HTTP/1.1
Host: api.negozio.it
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Length: 97

{
  "nome": "Laptop Gaming Pro",
  "prezzo": 1299.99,
  "categoria": "informatica",
  "stock": 50
}
```

**Risposta 201 Created:**
```http
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/v1/prodotti/789
Date: Mon, 15 Jan 2024 14:25:00 GMT

{
  "id": 789,
  "nome": "Laptop Gaming Pro",
  "prezzo": 1299.99,
  "categoria": "informatica",
  "stock": 50,
  "creato_il": "2024-01-15T14:25:00Z"
}
```

### Esempio 4: Risposta con cache 304

**Richiesta con validazione cache:**
```http
GET /style.css HTTP/1.1
Host: www.esempio.it
If-None-Match: "abc123"
If-Modified-Since: Mon, 14 Jan 2024 10:00:00 GMT

```

**Risposta — risorsa non cambiata:**
```http
HTTP/1.1 304 Not Modified
Date: Mon, 15 Jan 2024 14:30:00 GMT
ETag: "abc123"
Cache-Control: max-age=86400

```
*(nessun body — il browser usa la copia in cache)*

---

> 📖 Continua con: [03_HTTPS_TLS.md](03_HTTPS_TLS.md) — HTTPS, TLS e certificati digitali
