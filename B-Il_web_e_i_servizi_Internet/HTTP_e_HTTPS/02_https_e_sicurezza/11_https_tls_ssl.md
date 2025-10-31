# 11. HTTPS e TLS/SSL

## 11.1 Introduzione a HTTPS

**HTTPS** = HTTP + TLS (Transport Layer Security)

### 11.1.1 - Perché HTTPS

**HTTP problems:**
- 🔓 Dati in chiaro (leggibili da chiunque)
- 🕵️ Man-in-the-middle attacks
- 📝 Nessuna autenticazione server
- 🔧 Dati modificabili in transito

**HTTPS benefits:**
- 🔒 Crittografia end-to-end
- ✅ Autenticazione server (certificati)
- 🛡️ Integrità dati (no tampering)
- 🔐 Privacy utente
- 📈 SEO boost (Google ranking)
- ⚡ HTTP/2 richiede HTTPS

### 11.1.2 - HTTP vs HTTPS

```
HTTP:
Client ←--[ user:pass ]--→ Server
       ↑ In chiaro! Leggibile da attaccante

HTTPS:
Client ←--[ x7@#9%mK... ]--→ Server
       ↑ Crittografato! Illeggibile
```

**Porte:**
- HTTP: porta 80
- HTTPS: porta 443

## 11.2 TLS/SSL

### 11.2.1 - Storia

**SSL (Secure Sockets Layer):**
- SSL 1.0: Mai rilasciato
- SSL 2.0: 1995 (deprecato, vulnerabile)
- SSL 3.0: 1996 (deprecato 2015, POODLE attack)

**TLS (Transport Layer Security):**
- TLS 1.0: 1999 (deprecato 2021)
- TLS 1.1: 2006 (deprecato 2021)
- TLS 1.2: 2008 (**ancora usato**)
- TLS 1.3: 2018 (**raccomandato**, più veloce e sicuro)

**Nota:** "SSL" spesso usato genericamente, ma TLS è il nome corretto.

### 11.2.2 - TLS Handshake (TLS 1.2)

```
1. Client Hello
   ├─ Versioni TLS supportate
   ├─ Cipher suites
   ├─ Random bytes
   └─ Extensions (SNI, ALPN)

2. Server Hello
   ├─ Versione TLS scelta
   ├─ Cipher suite scelto
   ├─ Random bytes
   └─ Session ID

3. Server Certificate
   └─ Certificato X.509 (public key)

4. Server Key Exchange (opzionale)
   └─ Parametri DH/ECDH

5. Server Hello Done

6. Client Key Exchange
   ├─ Pre-master secret (encrypted with server public key)
   └─ Generate master secret

7. Change Cipher Spec
   └─ Da ora usa encryption

8. Finished (encrypted)
   └─ Hash di tutti messaggi handshake

9. Server: Change Cipher Spec

10. Server: Finished (encrypted)

✅ Connessione sicura stabilita!
```

**Tempo:** ~2 RTT (Round-Trip Time)

### 11.2.3 - TLS 1.3 Handshake (più veloce)

```
1. Client Hello
   ├─ Supported versions (TLS 1.3)
   ├─ Cipher suites
   ├─ Key share (già invia public key!)
   └─ Extensions

2. Server Hello
   ├─ Version (TLS 1.3)
   ├─ Cipher suite
   ├─ Key share
   └─ [Certificate, Finished] encrypted

✅ Connessione sicura! Solo 1 RTT
```

**Miglioramenti TLS 1.3:**
- ⚡ 1-RTT handshake (vs 2-RTT in 1.2)
- 🚀 0-RTT resumption (ancora più veloce)
- 🔒 Cipher suites moderni (rimossi vecchi insicuri)
- 🛡️ Perfect Forward Secrecy obbligatorio
- 🔐 Tutto crittografato (anche certificati)

## 11.3 Certificati SSL/TLS

### 11.3.1 - Cosa sono

**Certificato X.509:** Documento digitale che associa public key a identità (dominio).

**Contenuto:**
- Dominio (Common Name)
- Organizzazione
- Public key
- Validity period (start/end date)
- Certificate Authority (CA) signature
- Serial number

### 11.3.2 - Verifica Certificato

```
1. Browser riceve certificato
2. Verifica firma CA (trusted?)
3. Verifica domain name match
4. Verifica validity period
5. Verifica revocation (CRL, OCSP)
6. ✅ Se tutto OK, connessione sicura
```

**Esempio certificato:**
```
Subject: CN=example.com
Issuer: CN=Let's Encrypt Authority X3
Validity:
  Not Before: Mar 1 00:00:00 2025 GMT
  Not After:  May 30 23:59:59 2025 GMT
Public Key: RSA 2048 bit
Signature: sha256WithRSAEncryption
```

### 11.3.3 - Tipi di Certificati

**Domain Validation (DV):**
- ✅ Verifica solo possesso dominio
- ⚡ Rilascio veloce (minuti)
- 💰 Economico/gratuito (Let's Encrypt)
- 🎯 Uso: Piccoli siti, blog

**Organization Validation (OV):**
- ✅ Verifica dominio + organizzazione
- ⏱️ Rilascio: ore/giorni
- 💰 Medio costo
- 🎯 Uso: Aziende, e-commerce

**Extended Validation (EV):**
- ✅ Verifica approfondita organizzazione
- ⏱️ Rilascio: giorni/settimane
- 💰 Costoso
- 🎯 Uso: Banche, grandi aziende
- 🟢 Barra verde browser (alcuni browser)

**Wildcard:**
```
*.example.com
# Copre tutti i sottodomini:
# www.example.com, api.example.com, blog.example.com
```

**Multi-domain (SAN):**
```
Subject Alternative Names:
- example.com
- www.example.com
- api.example.com
- example.net
```

### 11.3.4 - Certificate Authorities (CA)

**Trusted CAs:**
- Let's Encrypt (gratuito, automated)
- DigiCert
- Sectigo (ex Comodo)
- GlobalSign
- GoDaddy

**Chain of Trust:**
```
Root CA (self-signed, in browser trust store)
  └─ Intermediate CA
       └─ End-entity Certificate (your site)
```

Browser ha lista di Root CA trusted (Mozilla, Google, Microsoft).

## 11.4 Let's Encrypt (Certificati Gratuiti)

### 11.4.1 - Certbot Installation

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install certbot python3-certbot-nginx
```

**CentOS/RHEL:**
```bash
sudo yum install certbot python3-certbot-nginx
```

### 11.4.2 - Ottenere Certificato (Nginx)

**Automatic:**
```bash
sudo certbot --nginx -d example.com -d www.example.com
```

Certbot:
1. Ottiene certificato
2. Configura Nginx automaticamente
3. Setup auto-renewal

**Manual (webroot):**
```bash
sudo certbot certonly --webroot -w /var/www/html -d example.com
```

Files generati:
```
/etc/letsencrypt/live/example.com/
├── fullchain.pem  (certificato + intermediate)
├── privkey.pem    (private key)
├── cert.pem       (solo certificato)
└── chain.pem      (solo intermediate)
```

### 11.4.3 - Nginx Configuration

```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    
    # Redirect HTTP → HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;
    
    # SSL Certificate
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL Protocol
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Cipher Suites (modern)
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    
    # Session
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    
    location / {
        root /var/www/html;
        index index.html;
    }
}
```

### 11.4.4 - Auto-renewal

**Test renewal:**
```bash
sudo certbot renew --dry-run
```

**Cron job (automatic):**
```bash
sudo crontab -e

# Renew at 2am daily
0 2 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

Certificati Let's Encrypt scadono dopo **90 giorni**.

## 11.5 HTTPS Best Practices

### 11.5.1 - SSL Labs Test

**Testa configurazione:**
```
https://www.ssllabs.com/ssltest/analyze.html?d=example.com
```

**Target: A+ rating**

### 11.5.2 - Security Headers

```nginx
# HSTS (force HTTPS)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# CSP (prevent XSS)
add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self';" always;

# Clickjacking protection
add_header X-Frame-Options "SAMEORIGIN" always;

# MIME sniffing protection
add_header X-Content-Type-Options "nosniff" always;

# Referrer policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
```

### 11.5.3 - Redirect HTTP → HTTPS

**Nginx:**
```nginx
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

**Apache:**
```apache
<VirtualHost *:80>
    ServerName example.com
    Redirect permanent / https://example.com/
</VirtualHost>
```

**Express.js:**
```javascript
app.use((req, res, next) => {
  if (req.header('x-forwarded-proto') !== 'https') {
    return res.redirect(`https://${req.header('host')}${req.url}`);
  }
  next();
});
```

### 11.5.4 - Mixed Content

**Problema:** HTTPS page che carica risorsa HTTP.

```html
<!-- ❌ BAD: Mixed content -->
<script src="http://example.com/script.js"></script>
<img src="http://example.com/image.jpg">

<!-- ✅ GOOD: All HTTPS -->
<script src="https://example.com/script.js"></script>
<img src="https://example.com/image.jpg">

<!-- ✅ GOOD: Protocol-relative -->
<script src="//example.com/script.js"></script>
```

**Browser:** Blocca active mixed content (scripts, iframes), warning per passive (images).

## 11.6 Node.js HTTPS Server

### 11.6.1 - Basic HTTPS Server

```javascript
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('/etc/letsencrypt/live/example.com/privkey.pem'),
  cert: fs.readFileSync('/etc/letsencrypt/live/example.com/fullchain.pem')
};

https.createServer(options, (req, res) => {
  res.writeHead(200);
  res.end('Hello HTTPS!');
}).listen(443);

console.log('HTTPS server running on port 443');
```

### 11.6.2 - Express.js HTTPS

```javascript
const express = require('express');
const https = require('https');
const http = require('http');
const fs = require('fs');

const app = express();

// Routes
app.get('/', (req, res) => {
  res.send('Hello HTTPS!');
});

// HTTPS server
const httpsOptions = {
  key: fs.readFileSync('/etc/letsencrypt/live/example.com/privkey.pem'),
  cert: fs.readFileSync('/etc/letsencrypt/live/example.com/fullchain.pem')
};

https.createServer(httpsOptions, app).listen(443, () => {
  console.log('HTTPS server on 443');
});

// HTTP server (redirect to HTTPS)
http.createServer((req, res) => {
  res.writeHead(301, { 
    Location: `https://${req.headers.host}${req.url}` 
  });
  res.end();
}).listen(80, () => {
  console.log('HTTP redirect server on 80');
});
```

### 11.6.3 - Self-Signed Certificate (Development)

**Generate certificate:**
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Answer prompts:
# Country: IT
# State: Lazio
# City: Rome
# Organization: MyCompany
# Common Name: localhost
```

**Use in dev:**
```javascript
const options = {
  key: fs.readFileSync('./key.pem'),
  cert: fs.readFileSync('./cert.pem')
};

https.createServer(options, app).listen(3000);
```

**⚠️ Browser warning:** Self-signed non trusted, solo per sviluppo!

## 11.7 Advanced Topics

### 11.7.1 - Perfect Forward Secrecy (PFS)

**Problema:** Se private key compromessa, attaccante può decrittare tutto il traffico passato.

**Soluzione:** Ephemeral key exchange (DHE, ECDHE).

Ogni sessione usa chiavi temporanee diverse. Compromissione private key non compromette sessioni passate.

**Nginx config:**
```nginx
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
# ECDHE = Elliptic Curve Diffie-Hellman Ephemeral
```

### 11.7.2 - OCSP Stapling

**Problema:** Client deve contattare CA per verificare revoca certificato (slow).

**Soluzione:** Server recupera OCSP response e la "staple" nel handshake.

```nginx
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
```

**Benefit:** Più veloce, più privacy (client non contatta CA).

### 11.7.3 - Session Resumption

**Problema:** Full handshake ogni connessione (slow).

**Soluzione 1: Session IDs**
```nginx
ssl_session_cache shared:SSL:50m;
ssl_session_timeout 1d;
```

Client salva session ID, riconnessione riutilizza chiavi (1 RTT).

**Soluzione 2: Session Tickets**
```nginx
ssl_session_tickets off;  # Disabilita (privacy)
```

Server cifra session state in ticket, client lo presenta. No server storage, ma meno sicuro (no PFS).

**TLS 1.3: 0-RTT Resumption**
Client invia dati già nel primo messaggio (0 RTT). Super veloce ma vulnerabile a replay attacks.

### 11.7.4 - Certificate Pinning

**Problema:** CA compromise può emettere certificati falsi.

**Soluzione:** Client "pinna" certificato atteso (fingerprint).

**HTTP Header:**
```http
Public-Key-Pins: 
  pin-sha256="base64=="; 
  pin-sha256="backup=="; 
  max-age=5184000; 
  includeSubDomains
```

**⚠️ Deprecato:** Pericoloso (rischio lockout), rimosso da Chrome. Usare Certificate Transparency invece.

### 11.7.5 - Certificate Transparency

**Google CT:** Log pubblici di tutti i certificati emessi.

Browser verifica certificato presente nei CT logs (SCT - Signed Certificate Timestamp).

Previene emissione certificati fraudolenti senza detection.

## 11.8 Troubleshooting

### 11.8.1 - Common Errors

**ERR_CERT_AUTHORITY_INVALID:**
- Self-signed certificate
- CA non trusted
- **Fix:** Usa certificato da CA trusted

**ERR_CERT_COMMON_NAME_INVALID:**
- Domain mismatch
- Certificato per `example.com`, visiti `www.example.com`
- **Fix:** Usa wildcard o SAN certificate

**ERR_CERT_DATE_INVALID:**
- Certificato scaduto o not yet valid
- **Fix:** Renew certificate

**NET::ERR_CERT_REVOKED:**
- Certificato revocato
- **Fix:** Nuovo certificato

### 11.8.2 - Testing Tools

**OpenSSL:**
```bash
# Test connection
openssl s_client -connect example.com:443

# Check certificate
openssl s_client -connect example.com:443 -showcerts

# Test specific TLS version
openssl s_client -connect example.com:443 -tls1_3

# Check certificate expiration
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates
```

**curl:**
```bash
# Test HTTPS
curl -v https://example.com

# Ignore certificate (insecure)
curl -k https://example.com
```

**nmap:**
```bash
# Scan SSL/TLS
nmap --script ssl-enum-ciphers -p 443 example.com
```

---

**Capitolo 11 completato!**

Prossimo: **Capitolo 12 - HTTP/2**
