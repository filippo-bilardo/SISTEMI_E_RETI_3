# 04 — Cookie, Sessioni, Autenticazione e Cache HTTP

## Il Problema della Statelessness HTTP

Come abbiamo visto, HTTP è un protocollo **stateless**: ogni richiesta è completamente indipendente dalle altre. Il server non mantiene alcuna memoria delle interazioni precedenti con il client.

**Problema pratico**: come fa un sito web a "ricordare" che hai fatto login? Come può mantenere il contenuto del tuo carrello acquisti tra una pagina e l'altra?

```
HTTP puro (stateless):

  Browser                     Server
    |--- GET /profilo.html -->|
    |<-- 200 OK + profilo  ---|
    |                         |
    |--- GET /ordini.html  -->|
    |   "Chi sei? Non lo so!" |  ← il server non ricorda!
```

Le soluzioni per aggiungere stato a HTTP sono:
1. **Cookie** — piccoli file di dati che il server memorizza nel browser
2. **Sessioni lato server** — ID univoco nel cookie, dati reali sul server
3. **Token** (es. JWT) — dati firmati nel header Authorization
4. **URL rewriting** — ID sessione nell'URL (obsoleto, insicuro)

---

## Cookie HTTP

I **cookie** sono piccoli frammenti di dati (max ~4KB) che il server invia al browser con l'header `Set-Cookie`. Il browser li memorizza e li invia automaticamente ad ogni richiesta successiva allo stesso dominio con l'header `Cookie`.

### Meccanismo Set-Cookie / Cookie

```
1. Client visita il sito per la prima volta
   Browser ─── GET /index.html ──────────────> Server
   Browser <── 200 OK                          Server
               Set-Cookie: user_id=42; Path=/; Max-Age=86400

2. Client fa una seconda richiesta (stessa sessione o dopo)
   Browser ─── GET /profilo.html ────────────> Server
               Cookie: user_id=42
   Browser <── 200 OK + dati utente 42         Server
                                               (il server "ricorda" chi sei!)
```

### Attributi dei Cookie

| Attributo | Descrizione | Esempio | Note |
|-----------|-------------|---------|------|
| **Name=Value** | Nome e valore del cookie (obbligatori) | `session=abc123` | Il valore non può contenere spazi, virgole, punti e virgola |
| **Domain** | Dominio per cui il cookie è valido | `Domain=.esempio.it` | Il punto iniziale include i sottodomini |
| **Path** | Path per cui il cookie è valido | `Path=/admin` | Cookie inviato solo per URL che iniziano con `/admin` |
| **Expires** | Data/ora di scadenza assoluta | `Expires=Sat, 01 Feb 2025 12:00:00 GMT` | Se assente: session cookie |
| **Max-Age** | Durata in secondi dalla creazione | `Max-Age=3600` | 1 ora; ha precedenza su Expires |
| **HttpOnly** | Cookie non accessibile da JavaScript | `HttpOnly` | Protezione da XSS (Cross-Site Scripting) |
| **Secure** | Cookie inviato solo su HTTPS | `Secure` | Fondamentale per cookie di autenticazione |
| **SameSite** | Controllo invio cross-site | `SameSite=Strict` | Protezione da CSRF |

### Esempio di Set-Cookie completo

```http
HTTP/1.1 200 OK
Set-Cookie: session_id=eyJhbGciOiJIUzI1NiJ9; Path=/; Max-Age=3600; HttpOnly; Secure; SameSite=Strict
Set-Cookie: preferenza_tema=scuro; Path=/; Max-Age=31536000; SameSite=Lax
Set-Cookie: _analytics=abc123; Path=/; Domain=.esempio.it; Max-Age=31536000
```

### SameSite — Valori possibili

| Valore | Comportamento | Protezione CSRF |
|--------|---------------|----------------|
| `Strict` | Cookie inviato SOLO per richieste dallo stesso sito | Massima |
| `Lax` | Cookie inviato per navigazione top-level da altri siti | Media |
| `None` | Cookie inviato sempre (richiede `Secure`) | Nessuna |

---

## Session Cookie vs Persistent Cookie

### Session Cookie

```
Set-Cookie: cart_id=xyz789; Path=/
```

- **Nessun attributo** `Expires` o `Max-Age`
- Viene **eliminato quando il browser viene chiuso**
- Memorizzato solo in RAM, non su disco
- Usato per: sessioni di navigazione temporanee, autenticazione durante la sessione

```
Apertura browser → Cookie creato (RAM)
  Navigazione  → Cookie inviato ad ogni richiesta
Chiusura browser → Cookie ELIMINATO
Riapertura → Cookie non esiste più → devi fare login di nuovo
```

### Persistent Cookie

```
Set-Cookie: remember_me=token123; Path=/; Max-Age=2592000; HttpOnly; Secure
```

- Ha un attributo `Expires` o `Max-Age`
- **Sopravvive alla chiusura del browser** (salvato su disco)
- Scade alla data/ora indicata o dopo i secondi specificati
- Usato per: "ricordami", preferenze utente, analytics, tracking

```
Prima visita → Cookie creato (disco, scade tra 30 giorni)
Chiusura browser
Riapertura dopo 15 giorni → Cookie ancora presente → login automatico
Riapertura dopo 31 giorni → Cookie scaduto → devi fare login di nuovo
```

### Confronto

| Caratteristica | Session Cookie | Persistent Cookie |
|----------------|---------------|-------------------|
| Scadenza | Fine sessione browser | Data/ora specificata |
| Storage | RAM | Disco |
| Sopravvive alla chiusura | ❌ No | ✅ Sì |
| Uso tipico | Login attivo, carrello | "Ricordami", preferenze |
| Sicurezza | Più sicuro | Rischio se dispositivo condiviso |

---

## Sessioni Lato Server

I cookie da soli hanno un problema: i dati nel cookie sono visibili al browser (anche se non modificabili se firmati). La soluzione più comune è usare le **sessioni lato server**:

1. Il server genera un **ID di sessione univoco** (stringa casuale sicura)
2. L'ID viene inviato al browser come cookie (`session_id`)
3. I **dati della sessione** (utente, permessi, carrello) rimangono sul **server** (RAM, database, Redis)
4. Ad ogni richiesta, il browser invia l'ID sessione → il server recupera i dati

```
Login:
  Browser ─── POST /login (user+pass) ─────────> Server
  Server verifica credenziali
  Server crea sessione: {id: "abc123", user_id: 42, ruolo: "admin"}
  Server salva sessione in database
  Browser <── 200 OK + Set-Cookie: session_id=abc123; HttpOnly  ── Server

Richieste successive:
  Browser ─── GET /dashboard + Cookie: session_id=abc123 ──────> Server
  Server legge session_id=abc123 → trova sessione → sa chi è l'utente
  Browser <── 200 OK + pagina dashboard personalizzata ──────── Server
```

### Session Hijacking

Il **session hijacking** è l'attacco in cui un malintenzionato ruba il cookie di sessione di un altro utente per impersonarlo:

```
Attacco via XSS (se cookie NON è HttpOnly):
  document.cookie  // JavaScript legge il cookie session_id

Attacco via sniffing (se cookie NON è Secure):
  Intercetta traffico HTTP → vede il cookie in chiaro

Con il cookie rubato:
  Attaccante ─── GET /dashboard + Cookie: session_id=abc123 ──> Server
  Server <─── risponde con i dati dell'utente 42 ────────────── Attaccante
```

**Contromisure**:
- Sempre `HttpOnly` sui cookie di sessione
- Sempre `Secure` sui cookie di sessione
- Usare HTTPS (obbligatorio)
- Rotazione del session ID dopo il login (Session Fixation prevention)
- Timeout di sessione (scadenza automatica dopo inattività)

---

## Autenticazione HTTP

### Basic Authentication

Il metodo più semplice (e meno sicuro) di autenticazione HTTP:

```http
GET /area-riservata HTTP/1.1
Host: www.esempio.it
Authorization: Basic bWFyaW86c2VncmV0bzEyMw==
```

Il valore dopo `Basic` è `Base64(username:password)`. **Non è cifratura** — è solo encoding! Chiunque intercetti il traffico può decodificarlo:

```
Base64.decode("bWFyaW86c2VncmV0bzEyMw==") → "mario:segreto123"
```

> ⚠️ Basic Auth è accettabile SOLO su HTTPS, mai su HTTP.

### Bearer Token / JWT

Il metodo moderno per le API REST:

```http
GET /api/profilo HTTP/1.1
Host: api.esempio.it
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjo0MiwicnVvbG8iOiJhZG1pbiIsImV4cCI6MTcwNTMyMDgwMH0.FIRMA_DIGITALE
```

Un **JWT** (JSON Web Token) contiene:
- **Header**: algoritmo usato
- **Payload**: dati utente (user_id, ruolo, scadenza)
- **Firma**: garantisce che il token non sia stato alterato

I 3 segmenti sono separati da `.` e codificati in Base64url.

### OAuth 2.0

Standard per l'autorizzazione delegata (es. "Accedi con Google"):
- L'utente autorizza un'app ad accedere alle sue risorse su un altro servizio
- L'app riceve un access token per fare richieste a nome dell'utente
- Non condivide mai la password dell'utente con l'app terza

---

## Cache HTTP

La **cache HTTP** permette di memorizzare copie di risorse per evitare di riscaricarle ad ogni richiesta, migliorando prestazioni e riducendo il carico del server.

### Dove si trova la cache

```
Browser → Proxy/CDN → Server di Origine
  ↑            ↑
Cache locale  Cache condivisa
(privata)     (pubblica)
```

### Header Cache-Control (principale)

`Cache-Control` è l'header più importante per il controllo della cache (HTTP/1.1+):

| Direttiva | Tipo | Significato |
|-----------|------|-------------|
| `max-age=N` | Risposta | La risorsa è fresca per N secondi |
| `s-maxage=N` | Risposta | Come max-age ma solo per cache condivise (CDN) |
| `public` | Risposta | Può essere memorizzata da qualsiasi cache (anche condivise) |
| `private` | Risposta | Solo nel browser dell'utente (non CDN) |
| `no-cache` | Risposta | Deve rivalidare con il server prima di usare la cache |
| `no-store` | Risposta | Non memorizzare mai (dati sensibili) |
| `must-revalidate` | Risposta | Rivalidare obbligatoriamente quando scaduta |
| `immutable` | Risposta | La risorsa non cambierà mai (ottimizzazione estrema) |

### Esempi di Cache-Control per diversi scenari

```http
# Pagina HTML dinamica (aggiornata spesso)
Cache-Control: no-cache, no-store, must-revalidate

# CSS/JS con hash nel nome file (può essere cached per sempre)
Cache-Control: public, max-age=31536000, immutable

# Pagina pubblica che cambia raramente
Cache-Control: public, max-age=3600

# Dati utente personali
Cache-Control: private, max-age=300

# Risposta API sempre fresca
Cache-Control: no-store
```

### Validazione della Cache con ETag

**ETag** (Entity Tag) è un identificatore univoco per una specifica versione di una risorsa:

```
Prima richiesta:
  Browser ─── GET /style.css ──────────────────────────────> Server
  Browser <── 200 OK + CSS + ETag: "v3.abc123" ─────────── Server

Il browser memorizza ETag e il file in cache.

Richiesta successiva (cache scaduta o no-cache):
  Browser ─── GET /style.css + If-None-Match: "v3.abc123" ─> Server
  
  Se il file NON è cambiato:
  Browser <── 304 Not Modified (nessun body!) ──────────── Server
  [Il browser usa la copia in cache — risparmia banda!]
  
  Se il file è cambiato:
  Browser <── 200 OK + NUOVO CSS + ETag: "v4.xyz789" ────── Server
```

### Validazione con Last-Modified

Alternativa più semplice all'ETag basata sulla data di modifica:

```
Prima richiesta:
  GET /immagine.jpg
  ← 200 OK + Last-Modified: Mon, 14 Jan 2024 10:00:00 GMT

Richiesta successiva:
  GET /immagine.jpg
  If-Modified-Since: Mon, 14 Jan 2024 10:00:00 GMT
  ← 304 Not Modified  (oppure 200 OK se cambiata)
```

### Diagramma di flusso della cache

```
Browser ha la risorsa in cache?
        │
        ├─ NO ──→ Richiesta al server → memorizza risposta
        │
        └─ SÌ → La cache è ancora fresca (max-age non scaduto)?
                      │
                      ├─ SÌ ──→ Usa la cache direttamente (nessuna richiesta!)
                      │
                      └─ NO → Invia richiesta di rivalidazione
                                (If-None-Match o If-Modified-Since)
                                      │
                                      ├─ 304 Not Modified → Usa cache (aggiorna scadenza)
                                      └─ 200 OK → Aggiorna cache con nuova versione
```

---

## CDN — Content Delivery Network

Una **CDN** è una rete di server distribuiti geograficamente che memorizzano copie delle risorse statiche di un sito (immagini, CSS, JS, video) vicino agli utenti finali.

```
Senza CDN:
  Utente (Milano) ──────────────────────> Server (New York) [latenza alta]

Con CDN:
  Utente (Milano) ──> CDN Edge (Frankfurt) ──> Server Origine (New York)
                       [risposta dalla cache CDN, latenza bassa]
```

**Vantaggi CDN**:
- Minore latenza (server vicino all'utente)
- Riduzione carico sul server di origine
- Maggiore scalabilità (gestisce picchi di traffico)
- Spesso include protezione DDoS

**CDN popolari**: Cloudflare, AWS CloudFront, Fastly, Akamai, Azure CDN.

---

## LocalStorage e SessionStorage

**Web Storage API** è un meccanismo del browser (JavaScript) per memorizzare dati lato client, alternativo ai cookie per certi usi.

### Confronto Cookie vs LocalStorage vs SessionStorage

| Caratteristica | Cookie | LocalStorage | SessionStorage |
|----------------|--------|-------------|---------------|
| Capacità | ~4 KB | ~5–10 MB | ~5–10 MB |
| Inviato al server | ✅ Automaticamente | ❌ Mai | ❌ Mai |
| Scadenza | Configurabile | Nessuna (permanente) | Fine sessione browser |
| Accesso JavaScript | ✅ (se non HttpOnly) | ✅ Sempre | ✅ Sempre |
| Accessibile cross-tab | ✅ Sì | ✅ Sì | ❌ No (solo stessa tab) |
| Sicurezza | HttpOnly, Secure | Solo su HTTPS | Solo su HTTPS |
| Uso tipico | Autenticazione, tracking | Preferenze utente, dati app | Dati temporanei di pagina |

### Uso in JavaScript

```javascript
// LocalStorage
localStorage.setItem('tema', 'scuro');
const tema = localStorage.getItem('tema');    // → "scuro"
localStorage.removeItem('tema');
localStorage.clear();  // Rimuove tutto

// SessionStorage
sessionStorage.setItem('dati_form', JSON.stringify({nome: 'Mario'}));
const dati = JSON.parse(sessionStorage.getItem('dati_form'));
```

> ⚠️ LocalStorage e SessionStorage non devono essere usati per memorizzare dati sensibili (token, password) perché accessibili da qualsiasi JavaScript della pagina (vulnerabili a XSS).

---

## Tabella di Riepilogo — Meccanismi di Stato HTTP

| Meccanismo | Dove si trovano i dati | Chi li invia al server | Sicurezza | Scadenza |
|------------|----------------------|----------------------|-----------|---------|
| Cookie | Browser (RAM/disco) | Browser (automatico) | HttpOnly, Secure | Configurabile |
| Sessione server | Server (DB/RAM) | Solo l'ID (nel cookie) | Alta (dati sul server) | Configurabile |
| JWT (Bearer) | Client (cookie/storage) | Header Authorization | Firma digitale | Campo `exp` |
| LocalStorage | Browser (disco) | Mai (solo JS) | Bassa (no attributi sicurezza) | Nessuna |
| SessionStorage | Browser (RAM) | Mai (solo JS) | Bassa | Fine tab/browser |

---

> 📖 Fine delle guide teoriche ES04. Torna a: [README.md](../README.md) | Procedi con: [esercizio_a.md](../esercizio_a.md)
