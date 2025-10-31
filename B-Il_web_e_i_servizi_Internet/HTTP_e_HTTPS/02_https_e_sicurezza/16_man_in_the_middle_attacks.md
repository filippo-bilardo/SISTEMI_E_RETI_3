# 16. Man-in-the-Middle (MITM) Attacks

## 16.1 Introduzione

**MITM** (Man-in-the-Middle) è un attacco dove l'attaccante si **interpone** tra client e server, **intercettando** e potenzialmente **modificando** la comunicazione.

**Impatto:**
- 🔴 Intercettazione credenziali (username/password)
- 🔴 Furto session cookie
- 🔴 Intercettazione dati sensibili
- 🔴 Modifica richieste/risposte
- 🔴 Injection di malware

## 16.2 Scenari di Attacco

### 16.2.1 - WiFi Pubblico (ARP Spoofing)

**Scenario tipico:**
```
Cliente WiFi Café
    ↓
Laptop vittima (192.168.1.10)
    ↓
Attaccante (192.168.1.50) ← Intercetta tutto il traffico
    ↓
Router WiFi (192.168.1.1)
    ↓
Internet
```

**ARP Spoofing attack:**
```bash
# Attaccante esegue:

# 1. Enable IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# 2. ARP spoofing (Ettercap/arpspoof)
arpspoof -i wlan0 -t 192.168.1.10 192.168.1.1  # Vittima
arpspoof -i wlan0 -t 192.168.1.1 192.168.1.10  # Router

# 3. Sniff traffico
wireshark -i wlan0

# Vittima pensa di comunicare con router
# In realtà tutto passa per attaccante!
```

**Traffico HTTP intercettato:**
```http
POST /login HTTP/1.1
Host: example.com
Content-Type: application/x-www-form-urlencoded

username=mario&password=secret123

← Attaccante vede username e password in chiaro!
```

### 16.2.2 - DNS Spoofing

**Attack flow:**
```
1. Vittima richiede: www.bank.com
2. Attaccante intercetta richiesta DNS
3. Attaccante risponde: www.bank.com = 1.2.3.4 (server attaccante)
4. Vittima connette a server fasullo
5. Attaccante fa phishing credenziali
```

**dnsspoof esempio:**
```bash
# dnsspoof.conf
www.bank.com  1.2.3.4  # IP attaccante

# Esegue DNS spoofing
dnsspoof -i wlan0 -f dnsspoof.conf
```

### 16.2.3 - SSL Stripping

**Attacco downgrade HTTPS → HTTP:**

```
Vittima richiede: http://bank.com

1. Server risponde: 301 Redirect → https://bank.com
   
2. Attaccante INTERCETTA redirect
   Modifica risposta in: 200 OK (fake HTTP page)
   
3. Vittima rimane su HTTP (non HTTPS)
   
4. Attaccante vede tutto in chiaro
   Comunica con vero server in HTTPS per mascherare attacco
```

**sslstrip tool:**
```bash
# 1. Redirect traffico
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# 2. Run sslstrip
sslstrip -l 8080

# 3. Vittima vede http:// invece di https://
# Attaccante intercetta tutto!
```

---

## 16.3 Difese

### 16.3.1 - HTTPS/TLS

**✅ Usa SEMPRE HTTPS:**

```nginx
# Nginx: Force HTTPS
server {
    listen 80;
    server_name example.com;
    
    # Redirect HTTP → HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Strong TLS config
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location / {
        root /var/www/html;
    }
}
```

### 16.3.2 - HSTS (HTTP Strict Transport Security)

**Force HTTPS a livello browser:**

```nginx
# Nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
```

```javascript
// Express.js
app.use((req, res, next) => {
    res.setHeader(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains; preload'
    );
    next();
});
```

**HTTP Response:**
```http
HTTP/2 200 OK
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

**Effetto:**
```
1. Browser riceve header HSTS
2. Browser memorizza: example.com DEVE usare HTTPS
3. Per 1 anno (31536000 secondi):
   - Ogni richiesta http://example.com automaticamente → https://
   - Browser RIFIUTA certificati invalidi (no click-through)
   - MITM con certificato fake NON funziona
```

**Preload list:**
```
https://hstspreload.org/

Inserisci dominio in lista HSTS preload
→ Browser nativamente usano HTTPS (anche prima visita)
→ Protezione massima
```

### 16.3.3 - Certificate Pinning

**Pin certificato specifico:**

**HTTP Public Key Pinning (HPKP) - Header:**
```nginx
# ⚠️ HPKP deprecato, usare cautela

add_header Public-Key-Pins '
    pin-sha256="base64==";
    pin-sha256="backup_base64==";
    max-age=5184000;
    includeSubDomains
';
```

**App mobile - Certificate pinning:**
```javascript
// React Native
import { fetch } from 'react-native-ssl-pinning';

fetch('https://api.example.com/data', {
    method: 'GET',
    sslPinning: {
        certs: ['cert1', 'cert2'] // SHA-256 hashes
    }
})
.then(response => response.json())
.then(data => console.log(data));

// Solo certificati con hash specificati accettati
// MITM con certificato fake fallisce
```

**Node.js - TLS pinning:**
```javascript
const https = require('https');
const fs = require('fs');
const crypto = require('crypto');

// Expected certificate fingerprint
const EXPECTED_FINGERPRINT = 'AA:BB:CC:DD:...';

const options = {
    hostname: 'api.example.com',
    port: 443,
    path: '/data',
    method: 'GET',
    checkServerIdentity: (hostname, cert) => {
        const fingerprint = crypto
            .createHash('sha256')
            .update(cert.raw)
            .digest('hex')
            .toUpperCase()
            .match(/.{2}/g)
            .join(':');
        
        if (fingerprint !== EXPECTED_FINGERPRINT) {
            throw new Error('Certificate pinning failed');
        }
    }
};

https.get(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => console.log(data));
});
```

### 16.3.4 - Certificate Transparency

**Verifica certificati emessi:**

```bash
# Check CT logs
curl https://crt.sh/?q=example.com

# Verifica certificato attuale
openssl s_client -connect example.com:443 -showcerts

# Compare con CT logs
# Se certificato non in CT logs → possibile MITM
```

**Expect-CT header:**
```nginx
add_header Expect-CT "max-age=86400, enforce";
```

### 16.3.5 - VPN

**Tunnel criptato:**
```
Laptop → VPN Client → Encrypted Tunnel → VPN Server → Internet

Attaccante su WiFi pubblico vede solo:
- Traffico criptato VPN
- Destinazione: VPN server IP
- NO contenuti HTTP/HTTPS
```

**OpenVPN esempio:**
```bash
# Client
sudo openvpn --config client.ovpn

# Tutto il traffico ora passa per tunnel VPN criptato
# MITM locale inefficace
```

---

## 16.4 Rilevamento MITM

### 16.4.1 - Certificate Inspection

**Browser warnings:**
```
⚠️ Your connection is not private
   NET::ERR_CERT_AUTHORITY_INVALID
   
→ Possibile MITM attack!
→ Certificato non fidato
```

**Verifica manuale certificato:**
```bash
# Check certificato server
openssl s_client -connect example.com:443 -showcerts | openssl x509 -noout -text

# Verifica:
Issuer: CN=Let's Encrypt Authority X3  ✅ OK
Issuer: CN=Burp Suite CA                ❌ MITM tool!
Issuer: CN=mitmproxy                     ❌ MITM tool!
```

### 16.4.2 - Network Monitoring

**Detect ARP spoofing:**
```bash
# arpwatch - monitor ARP table
sudo arpwatch -i wlan0

# Alert se MAC address cambia per stesso IP
# Possibile ARP spoofing
```

**Check ARP table:**
```bash
# Linux
arp -a

# Verifica IP router ha MAC corretto
# Se MAC cambia → possibile ARP spoofing
```

### 16.4.3 - DNS Verification

**Check DNS responses:**
```bash
# Query DNS pubblico (Google)
dig @8.8.8.8 example.com

# Query DNS locale
dig example.com

# Compare IP addresses
# Se diversi → possibile DNS spoofing
```

---

## 16.5 Testing MITM (Etico)

### 16.5.1 - Burp Suite

**Proxy HTTP/HTTPS per testing:**

```
Setup:
1. Burp Suite → Proxy → Options → Port 8080
2. Browser → Proxy settings → localhost:8080
3. Burp Suite → Proxy → Intercept → On

Flow:
Browser → Burp Proxy → Intercept/Modify → Server

Uso:
- Testare SQL injection
- Testare XSS
- Modificare requests/responses
- Analizzare API calls
```

**Install Burp CA certificate:**
```
1. Burp → Proxy → Options → Import/Export CA Certificate
2. Browser → Settings → Certificates → Import burp.crt
3. Ora Burp può intercettare HTTPS (per testing)
```

### 16.5.2 - mitmproxy

**Console HTTP(S) proxy:**

```bash
# Install
pip install mitmproxy

# Run proxy
mitmproxy -p 8080

# Configure browser proxy: localhost:8080

# Install certificate
# Browse to: http://mitm.it
# Download certificate per OS

# Ora puoi intercettare HTTPS
```

**Scripting con mitmproxy:**
```python
# script.py
from mitmproxy import http

def request(flow: http.HTTPFlow) -> None:
    # Log tutte le richieste
    print(f"Request: {flow.request.url}")
    
    # Modifica header
    flow.request.headers["X-Custom"] = "Modified"

def response(flow: http.HTTPFlow) -> None:
    # Log risposte
    print(f"Response: {flow.response.status_code}")
    
    # Modifica content
    if "text/html" in flow.response.headers.get("content-type", ""):
        flow.response.text = flow.response.text.replace(
            "</body>",
            "<script>alert('Injected')</script></body>"
        )

# Run: mitmproxy -s script.py
```

### 16.5.3 - Wireshark

**Analisi pacchetti:**

```bash
# Capture traffico
sudo wireshark

# Filters:
http               # Solo HTTP
http.request       # Solo HTTP requests
http.response.code == 200  # Solo 200 OK
tcp.port == 443    # HTTPS (encrypted)

# Follow HTTP stream
Right-click packet → Follow → HTTP Stream

# Vedi conversazione HTTP completa
# ⚠️ HTTP in chiaro visibile!
# ✅ HTTPS criptato (non leggibile)
```

---

## 16.6 Best Practices

### 16.6.1 - Checklist Sicurezza

**Server-side:**
```
✅ Usa HTTPS per tutto
✅ Redirect HTTP → HTTPS
✅ HSTS header abilitato
✅ HSTS preload list
✅ Strong TLS config (TLS 1.2+)
✅ Valid SSL certificate (Let's Encrypt)
✅ Certificate transparency
✅ Disabilita weak ciphers
```

**Client-side:**
```
✅ Verifica HTTPS (🔒 in URL bar)
✅ Check certificato (click 🔒)
✅ Attenzione warning certificati
✅ Usa VPN su reti pubbliche
✅ Aggiorna browser (security patches)
✅ Evita WiFi pubblici non sicuri
✅ Usa HTTPS Everywhere extension
```

### 16.6.2 - Nginx Secure Config

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # Certificati
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # TLS versions
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Strong ciphers
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        root /var/www/html;
    }
}

# HTTP → HTTPS redirect
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

### 16.6.3 - Express.js Secure Config

```javascript
const express = require('express');
const helmet = require('helmet');
const https = require('https');
const fs = require('fs');

const app = express();

// Security headers
app.use(helmet({
    hsts: {
        maxAge: 31536000,
        includeSubDomains: true,
        preload: true
    },
    frameguard: {
        action: 'deny'
    },
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"]
        }
    }
}));

// Force HTTPS
app.use((req, res, next) => {
    if (!req.secure && req.get('x-forwarded-proto') !== 'https') {
        return res.redirect(301, `https://${req.hostname}${req.url}`);
    }
    next();
});

app.get('/', (req, res) => {
    res.send('Hello HTTPS!');
});

// HTTPS server
const options = {
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
};

https.createServer(options, app).listen(443, () => {
    console.log('HTTPS server on port 443');
});

// HTTP redirect server
const http = require('http');
http.createServer((req, res) => {
    res.writeHead(301, { Location: `https://${req.headers.host}${req.url}` });
    res.end();
}).listen(80);
```

---

**Capitolo 16 completato!**

Prossimo: **Capitolo 17 - Denial of Service (DoS/DDoS)**
