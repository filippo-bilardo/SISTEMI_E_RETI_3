# 03 — Header HTTP di Sicurezza

> 🎯 **Obiettivo**: Conoscere tutti i principali header HTTP di sicurezza, comprendere cosa proteggono, come si configurano e quali rischi si corrono se sono assenti.

---

## Introduzione

Gli **header HTTP di sicurezza** sono istruzioni che il server invia al browser nella risposta HTTP. Dicono al browser come gestire il contenuto in modo sicuro: da dove caricare script, se permettere l'embedding in iframe, se forzare HTTPS, ecc.

Sono una **seconda linea di difesa**: anche se l'applicazione ha vulnerabilità, gli header possono mitigarne l'impatto. Non sostituiscono le buone pratiche di sviluppo, ma le integrano.

**Come si vedono gli header in un browser**:
- Apri DevTools (F12) → scheda **Network** → clicca su una richiesta → sezione **Response Headers**

**Esempio di risposta HTTP sicura**:
```http
HTTP/1.1 200 OK
Date: Mon, 10 Mar 2025 10:00:00 GMT
Content-Type: text/html; charset=utf-8
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Content-Security-Policy: default-src 'self'; script-src 'self' https://cdn.trusted.com
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(self)
```

---

## 1. HSTS — Strict-Transport-Security

### 1.1 Scopo

**HSTS** (HTTP Strict Transport Security) istruisce il browser a usare **esclusivamente HTTPS** per il dominio, per un periodo specificato. Una volta ricevuto questo header, il browser:
- Rifiuta connessioni HTTP semplici (le converte automaticamente in HTTPS)
- Rifiuta certificati TLS non validi senza possibilità di eccezione da parte dell'utente

### 1.2 Sintassi

```http
Strict-Transport-Security: max-age=<secondi>
Strict-Transport-Security: max-age=<secondi>; includeSubDomains
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

| Direttiva | Descrizione |
|-----------|-------------|
| `max-age=N` | Il browser ricorda la regola per N secondi (es. 31536000 = 1 anno) |
| `includeSubDomains` | La regola si applica anche a tutti i sottodomini |
| `preload` | Il sito può essere incluso nella Preload List dei browser |

### 1.3 Esempi di configurazione

**Nginx** (file di configurazione):
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

**Apache** (`.htaccess` o `httpd.conf`):
```apache
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
```

### 1.4 HSTS Preload List

La Preload List è mantenuta da Google e usata da Chrome, Firefox, Safari e Edge. I siti in lista usano HTTPS-only **anche alla prima visita** (soluzione al bootstrap problem).

Per iscriversi: [hstspreload.org](https://hstspreload.org)  
Requisiti minimi: HTTPS valido, redirect da HTTP, header HSTS con max-age ≥ 1 anno + includeSubDomains + preload.

### 1.5 Rischio se assente

| Rischio | Descrizione |
|---------|-------------|
| SSL Stripping | L'attaccante può degradare la connessione a HTTP |
| Prima visita non protetta | Il browser non sa che il sito richiede HTTPS |
| Utente ignora avvisi | Senza HSTS, l'utente può cliccare "Continua" su certificati non validi |

---

## 2. CSP — Content-Security-Policy

### 2.1 Scopo

La **CSP** (Content Security Policy) è una whitelist che dice al browser da quali origini può caricare risorse (script, stili, immagini, font, iframe, ecc.). È la **contromisura principale contro XSS**: anche se un attaccante inietta codice, il browser si rifiuta di eseguirlo se non proviene da un'origine autorizzata.

### 2.2 Sintassi Base

```http
Content-Security-Policy: <direttiva> <sorgente> [<sorgente>]; <direttiva> <sorgente>;
```

**Sorgenti speciali**:
| Sorgente | Significato |
|----------|-------------|
| `'self'` | Solo lo stesso dominio |
| `'none'` | Nessuna risorsa di quel tipo permessa |
| `'unsafe-inline'` | Permette script/stili inline (da evitare!) |
| `'unsafe-eval'` | Permette `eval()` JavaScript (da evitare!) |
| `https://cdn.example.com` | Sorgente specifica |
| `https:` | Qualsiasi sorgente HTTPS |
| `*` | Qualsiasi sorgente (sconsigliato) |
| `'nonce-<base64>'` | Script con nonce specifico permesso |

### 2.3 Direttive Principali

| Direttiva | Controlla | Esempio |
|-----------|-----------|---------|
| `default-src` | Fallback per tutte le risorse non specificate | `default-src 'self'` |
| `script-src` | File JavaScript | `script-src 'self' https://cdn.jquery.com` |
| `style-src` | Fogli di stile CSS | `style-src 'self' https://fonts.googleapis.com` |
| `img-src` | Immagini | `img-src 'self' data: https:` |
| `font-src` | Font | `font-src 'self' https://fonts.gstatic.com` |
| `connect-src` | AJAX, WebSocket, Fetch | `connect-src 'self' https://api.example.com` |
| `frame-src` | Iframe figlio (deprecated, usa `child-src`) | `frame-src 'none'` |
| `frame-ancestors` | Chi può incorniciare questa pagina | `frame-ancestors 'self'` |
| `form-action` | A quali URL possono essere inviati i form | `form-action 'self'` |
| `base-uri` | URL base del documento | `base-uri 'self'` |
| `upgrade-insecure-requests` | Converte richieste HTTP in HTTPS | `upgrade-insecure-requests` |

### 2.4 Esempi Pratici

**Politica base (sito senza CDN esterni)**:
```http
Content-Security-Policy: default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'
```

**Sito con Google Fonts e jQuery CDN**:
```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' https://code.jquery.com https://cdn.jsdelivr.net;
  style-src 'self' https://fonts.googleapis.com 'unsafe-inline';
  font-src 'self' https://fonts.gstatic.com;
  img-src 'self' data: https:;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self'
```

**Politica massima sicurezza (con nonce)**:
```http
Content-Security-Policy: default-src 'none'; script-src 'nonce-abc123'; style-src 'self'; img-src 'self'
```
Nel HTML il server include:
```html
<script nonce="abc123">
  // Questo script viene eseguito perché ha il nonce corretto
  console.log('Sicuro!');
</script>
```

### 2.5 Modalità Report-Only

Per testare CSP senza bloccare risorse (fase di sviluppo):
```http
Content-Security-Policy-Report-Only: default-src 'self'; report-uri /csp-report
```
Il browser non blocca nulla ma invia report JSON sulle violazioni all'endpoint specificato.

### 2.6 Rischio se assente

- XSS inline eseguito senza restrizioni
- Script iniettati da CDN compromessi eseguiti normalmente
- Nessun controllo su embedding in iframe (combinare con X-Frame-Options)

---

## 3. X-Frame-Options

### 3.1 Scopo

Controlla se la pagina può essere **incorporata in un iframe** da altri siti. È la difesa principale contro il Clickjacking.

### 3.2 Sintassi e Valori

```http
X-Frame-Options: DENY
X-Frame-Options: SAMEORIGIN
X-Frame-Options: ALLOW-FROM https://trusted.example.com
```

| Valore | Significato | Quando usarlo |
|--------|-------------|---------------|
| `DENY` | Vieta l'embedding in qualsiasi iframe | Default sicuro per la maggior parte delle pagine |
| `SAMEORIGIN` | Permette embedding solo dallo stesso dominio | App con iframe interni allo stesso sito |
| `ALLOW-FROM <url>` | Permette embedding solo dal dominio specificato | ⚠️ Deprecato, non supportato in Chrome/Firefox moderni |

> ⚠️ **Deprecazione**: `ALLOW-FROM` è obsoleto. Usa invece `Content-Security-Policy: frame-ancestors https://trusted.example.com` per la stessa funzionalità con pieno supporto browser.

### 3.3 CSP vs X-Frame-Options

| Caratteristica | X-Frame-Options | CSP frame-ancestors |
|----------------|----------------|---------------------|
| Supporto browser | Universale (inclusi browser vecchi) | Moderno (IE11 non supporta) |
| Granularità | Bassa (solo DENY/SAMEORIGIN) | Alta (whitelist multipla) |
| Standard | Header HTTP legacy | Parte di CSP livello 2 |
| Consiglio | Mantenerlo per compatibilità | Preferire CSP in nuovi progetti |

### 3.4 Rischio se assente

Il sito può essere incorporato in un iframe su qualsiasi dominio → **Clickjacking** possibile.

---

## 4. X-Content-Type-Options

### 4.1 Scopo

Previene il **MIME type sniffing**: il browser non deve tentare di indovinare il tipo di contenuto se il server ha già specificato il `Content-Type`. Previene attacchi in cui un file con estensione innocua (`.jpg`, `.txt`) viene eseguito come JavaScript.

### 4.2 Sintassi

```http
X-Content-Type-Options: nosniff
```

È l'unico valore valido.

### 4.3 Come funziona l'attacco senza questo header

1. Un utente carica un'immagine su `photo-upload.example.com`
2. L'utente carica invece un file JavaScript mascherato da JPEG
3. Il browser (senza `nosniff`) analizza il contenuto e capisce che è JavaScript
4. Il browser esegue il file come script → XSS via upload

**Con `nosniff`**: il browser usa solo il `Content-Type` dichiarato dal server. Se dice `image/jpeg`, il browser lo tratta come immagine — non eseguirà mai il contenuto come script.

### 4.4 Rischio se assente

Upload di file che vengono eseguiti come script nonostante l'estensione innocua.

---

## 5. Referrer-Policy

### 5.1 Scopo

Controlla quante informazioni vengono incluse nell'header `Referer` (sic — storico typo) nelle richieste HTTP. Quando un utente clicca su un link, il browser di default informa il sito destinazione di quale pagina proveniva l'utente.

### 5.2 Problema

Se una URL contiene informazioni sensibili, il sito esterno le riceve:
```
https://app.example.com/utente/12345/ordini?token=segreto
     ↓ clic su link a external.com
Referer: https://app.example.com/utente/12345/ordini?token=segreto
```

### 5.3 Valori Disponibili

| Valore | Cosa viene inviato | Quando usarlo |
|--------|-------------------|---------------|
| `no-referrer` | Nulla | Massima privacy |
| `no-referrer-when-downgrade` | URL completo solo HTTPS→HTTPS | Default browser (sconsigliato esplicitamente) |
| `origin` | Solo l'origine (`https://example.com`) | Default sicuro |
| `origin-when-cross-origin` | URL completo same-origin, solo origin cross-origin | Buon compromesso |
| `strict-origin` | Solo origin, mai HTTPS→HTTP | Sicuro |
| `strict-origin-when-cross-origin` | URL completo same-origin, origin cross-origin | **Raccomandato** |
| `unsafe-url` | URL completo sempre | ❌ Mai usare |

**Raccomandazione**:
```http
Referrer-Policy: strict-origin-when-cross-origin
```

---

## 6. Permissions-Policy

### 6.1 Scopo

Controlla l'accesso alle **API del browser** (fotocamera, microfono, geolocalizzazione, ecc.) per la pagina e per gli iframe che contiene. Precedentemente chiamato `Feature-Policy`.

### 6.2 Sintassi

```http
Permissions-Policy: <feature>=(<allowlist>)
```

**Allowlist valori**:
- `()` — nessuno può usare la funzione (disabilitata per tutti)
- `(self)` — solo il documento principale (non iframe)
- `*` — qualsiasi origine
- `(self "https://trusted.com")` — il documento e un dominio specifico

### 6.3 Esempi

```http
Permissions-Policy: camera=(), microphone=(), geolocation=(self), payment=(self "https://payment.trusted.com")
```

Disabilita fotocamera e microfono per tutti, permette geolocalizzazione solo al sito stesso, permette l'API Payment allo stesso sito e a un trusted payment provider.

### 6.4 Rischio se assente

Gli iframe incorporati possono richiedere accesso a fotocamera/microfono/geolocalizzazione — possibile abuso in attacchi di clickjacking avanzati.

---

## 7. CORS — Cross-Origin Resource Sharing

### 7.1 Same-Origin Policy

Per sicurezza, il browser impedisce a JavaScript di fare richieste HTTP a un dominio diverso dall'origine della pagina. Questo è la **Same-Origin Policy** (SOP).

Due URL hanno la stessa origine se sono identici in **schema + host + porta**:
| URL | Stessa origine di `https://app.example.com:443`? |
|-----|--------------------------------------------------|
| `https://app.example.com/page` | ✅ Sì |
| `https://app.example.com:8443/page` | ❌ No (porta diversa) |
| `http://app.example.com/page` | ❌ No (schema diverso) |
| `https://api.example.com/page` | ❌ No (host diverso) |

### 7.2 CORS — Abilitare richieste cross-origin selettivamente

**CORS** (Cross-Origin Resource Sharing) è un meccanismo che permette a un server di dichiarare quali origini esterne possono fare richieste. Funziona tramite header HTTP.

**Header CORS principali**:
```http
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST, PUT
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Allow-Credentials: true
Access-Control-Max-Age: 86400
```

**Esempio**: API su `api.example.com` che serve dati a `app.example.com`:
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://app.example.com
Access-Control-Allow-Methods: GET, POST
Access-Control-Allow-Headers: Content-Type, Authorization
```

> ⚠️ **Errore comune**: `Access-Control-Allow-Origin: *` con `Access-Control-Allow-Credentials: true` è **vietato** dal browser per motivi di sicurezza. Non si può usare wildcard con credenziali.

### 7.3 CORP — Cross-Origin Resource Policy

Complementare a CORS, `Cross-Origin-Resource-Policy` controlla chi può **includere** la risorsa (immagini, script, ecc.) da altri siti:

```http
Cross-Origin-Resource-Policy: same-site
Cross-Origin-Resource-Policy: same-origin
Cross-Origin-Resource-Policy: cross-origin
```

---

## 8. Tabella Comparativa Finale

| Header | Protezione offerta | Attacchi mitigati | Priorità | Compatibilità browser |
|--------|--------------------|------------------|----------|----------------------|
| `Strict-Transport-Security` | Forza HTTPS | SSL Stripping, MITM | 🔴 Alta | Universale |
| `Content-Security-Policy` | Whitelist risorse | XSS, Data injection | 🔴 Alta | Buona (IE11 parziale) |
| `X-Frame-Options` | Anti-framing | Clickjacking | 🔴 Alta | Universale |
| `X-Content-Type-Options` | No MIME sniffing | Script injection via upload | 🟡 Media | Universale |
| `Referrer-Policy` | Privacy del Referer | Info disclosure | 🟡 Media | Buona |
| `Permissions-Policy` | Controllo API browser | Clickjacking avanzato, abuso API | 🟡 Media | Buona (Chrome/Edge) |
| `Cross-Origin-Resource-Policy` | Protezione risorse | Spectre, Cross-origin leaks | 🟢 Bassa/Media | Moderna |

### Checklist di implementazione rapida

```
✅ HSTS con max-age >= 1 anno
✅ CSP: almeno default-src 'self' (poi raffinare)
✅ X-Frame-Options: DENY (o SAMEORIGIN se necessario)
✅ X-Content-Type-Options: nosniff
✅ Referrer-Policy: strict-origin-when-cross-origin
✅ Permissions-Policy: disabilita ciò che non usi
✅ CORS configurato con origini esplicite (no wildcard con credenziali)
```

### Test degli header

Per verificare gli header di un sito, usare:
- [securityheaders.com](https://securityheaders.com) — analisi gratuita online
- `curl -I https://example.com` — da terminale
- Browser DevTools (F12 → Network → Response Headers)
