# LAB 2.1 - Web Server in DMZ con HTTPS

## Informazioni Generali
**Piattaforma:** Cisco Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**File da creare:** `lab2.1-web-server-https.pkt`  
**Prerequisiti:** LAB 1.1 o 1.2

---

## Obiettivi del Laboratorio
- Configurare web server con HTTP e HTTPS
- Implementare port forwarding per porte multiple
- Configurare certificati SSL/TLS (simulato in PT)
- Testare accesso da Internet e LAN
- Comprendere differenze HTTP vs HTTPS
- Implementare redirect HTTP → HTTPS

---

## Topologia

```
[Internet] ←→ [Firewall] ←→ [Switch-DMZ] ←→ [Web-Server]
 192.0.2.2      |                              10.0.1.10
                |                              HTTP: 80
                ↓                              HTTPS: 443
           [Switch-LAN]
                |
           [PC-1, PC-2]
         172.16.0.10-11
```

---

## Parte 1: Setup Topologia Base

### Dispositivi
- 1x Router 2911 (Firewall)
- 2x Switch 2960
- 1x Server-PT (Web-Server)
- 2x PC-PT
- 1x Cloud-PT (Internet)

### Piano IP

| Dispositivo | Interfaccia | IP | Mask | Gateway |
|-------------|-------------|----|----|---------|
| Firewall | G0/0 (WAN) | 192.0.2.1 | /30 | - |
| Firewall | G0/1 (DMZ) | 10.0.1.1 | /24 | - |
| Firewall | G0/2 (LAN) | 172.16.0.1 | /24 | - |
| Internet | Fa0 | 192.0.2.2 | /30 | - |
| Web-Server | Fa0 | 10.0.1.10 | /24 | 10.0.1.1 |
| PC-1 | Fa0 | 172.16.0.10 | /24 | 172.16.0.1 |
| PC-2 | Fa0 | 172.16.0.11 | /24 | 172.16.0.1 |

---

## Parte 2: Configurazione Firewall

### Step 2.1 - Interfacce Base

```cisco
Router> enable
Router# configure terminal
Router(config)# hostname FW-WEB
FW-WEB(config)#

! WAN
FW-WEB(config)# interface GigabitEthernet 0/0
FW-WEB(config-if)# description *** WAN - Internet ***
FW-WEB(config-if)# ip address 192.0.2.1 255.255.255.252
FW-WEB(config-if)# no shutdown
FW-WEB(config-if)# exit

! DMZ
FW-WEB(config)# interface GigabitEthernet 0/1
FW-WEB(config-if)# description *** DMZ - Web Server ***
FW-WEB(config-if)# ip address 10.0.1.1 255.255.255.0
FW-WEB(config-if)# no shutdown
FW-WEB(config-if)# exit

! LAN
FW-WEB(config)# interface GigabitEthernet 0/2
FW-WEB(config-if)# description *** LAN Interna ***
FW-WEB(config-if)# ip address 172.16.0.1 255.255.255.0
FW-WEB(config-if)# no shutdown
FW-WEB(config-if)# exit
```

### Step 2.2 - Port Forwarding (NAT per HTTP e HTTPS)

```cisco
! Definire inside/outside
FW-WEB(config)# interface GigabitEthernet 0/0
FW-WEB(config-if)# ip nat outside
FW-WEB(config-if)# exit

FW-WEB(config)# interface GigabitEthernet 0/1
FW-WEB(config-if)# ip nat inside
FW-WEB(config-if)# exit

FW-WEB(config)# interface GigabitEthernet 0/2
FW-WEB(config-if)# ip nat inside
FW-WEB(config-if)# exit

! Static NAT per HTTP (porta 80)
FW-WEB(config)# ip nat inside source static tcp 10.0.1.10 80 interface GigabitEthernet 0/0 80

! Static NAT per HTTPS (porta 443)
FW-WEB(config)# ip nat inside source static tcp 10.0.1.10 443 interface GigabitEthernet 0/0 443

! NAT overload per LAN
FW-WEB(config)# access-list 1 permit 172.16.0.0 0.0.0.255
FW-WEB(config)# ip nat inside source list 1 interface GigabitEthernet 0/0 overload
```

### Step 2.3 - ACL per Sicurezza

```cisco
! ACL per traffico da Internet
FW-WEB(config)# ip access-list extended INTERNET-TO-DMZ

! Permettere HTTP
FW-WEB(config-ext-nacl)# remark Allow HTTP to Web Server
FW-WEB(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80

! Permettere HTTPS
FW-WEB(config-ext-nacl)# remark Allow HTTPS to Web Server
FW-WEB(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 443

! Permettere established connections (risposte)
FW-WEB(config-ext-nacl)# permit tcp any any established

! Permettere ICMP echo-reply
FW-WEB(config-ext-nacl)# permit icmp any any echo-reply

! Bloccare tutto il resto
FW-WEB(config-ext-nacl)# deny ip any any log

FW-WEB(config-ext-nacl)# exit

! Applicare ACL
FW-WEB(config)# interface GigabitEthernet 0/0
FW-WEB(config-if)# ip access-group INTERNET-TO-DMZ in
FW-WEB(config-if)# exit

! Routing
FW-WEB(config)# ip route 0.0.0.0 0.0.0.0 192.0.2.2

! Salvare
FW-WEB(config)# exit
FW-WEB# write memory
```

---

## Parte 3: Configurazione Web Server

### Step 3.1 - Configurazione IP

1. Clicca su **Web-Server**
2. Tab **Desktop** → **IP Configuration**
   - IP Address: `10.0.1.10`
   - Subnet Mask: `255.255.255.0`
   - Default Gateway: `10.0.1.1`
   - DNS Server: `8.8.8.8`

### Step 3.2 - Abilitare Servizi HTTP e HTTPS

1. Tab **Services**
2. **HTTP**:
   - Verifica sia **ON**
   - Porta: `80`
3. **HTTPS**:
   - Clicca su **HTTPS**
   - Toggle **ON**
   - Porta: `443`

### Step 3.3 - Creare Certificato SSL (Simulato)

**Nota:** In Packet Tracer, HTTPS funziona automaticamente con certificato self-signed simulato. In ambiente reale:

```bash
# Generare certificato self-signed (esempio Linux)
openssl genrsa -out private.key 2048
openssl req -new -x509 -key private.key -out certificate.crt -days 365

# Installare su web server
cp certificate.crt /etc/ssl/certs/
cp private.key /etc/ssl/private/
```

### Step 3.4 - Creare Contenuto Web Avanzato

Clicca su **HTTP** → **index.html** → Modifica:

```html
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure Web Server - LAB 2.1</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 20px;
            color: white;
        }
        .container {
            max-width: 800px;
            margin: 50px auto;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        h1 {
            text-align: center;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        .security-badge {
            text-align: center;
            font-size: 1.2em;
            margin: 20px 0;
            padding: 10px;
            background: rgba(76, 175, 80, 0.3);
            border-radius: 10px;
        }
        .info-box {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .protocol {
            font-weight: bold;
            color: #ffeb3b;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        td {
            padding: 10px;
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            font-size: 0.9em;
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Secure Web Server</h1>
        <h2 style="text-align: center;">LAB 2.1 - HTTPS Implementation</h2>
        
        <div class="security-badge">
            ✅ SSL/TLS Encryption Active
        </div>
        
        <div class="info-box">
            <h3>Server Information</h3>
            <table>
                <tr>
                    <td><strong>IP Address:</strong></td>
                    <td>10.0.1.10</td>
                </tr>
                <tr>
                    <td><strong>Location:</strong></td>
                    <td>DMZ (Demilitarized Zone)</td>
                </tr>
                <tr>
                    <td><strong>Protocols:</strong></td>
                    <td>
                        <span class="protocol">HTTP (Port 80)</span> | 
                        <span class="protocol">HTTPS (Port 443)</span>
                    </td>
                </tr>
                <tr>
                    <td><strong>Access:</strong></td>
                    <td>Internet & Internal LAN</td>
                </tr>
            </table>
        </div>
        
        <div class="info-box">
            <h3>🔐 Security Features</h3>
            <ul>
                <li>✅ SSL/TLS Encryption (HTTPS)</li>
                <li>✅ Port Forwarding (NAT)</li>
                <li>✅ ACL Firewall Rules</li>
                <li>✅ DMZ Segmentation</li>
                <li>✅ Secure Headers</li>
            </ul>
        </div>
        
        <div class="info-box">
            <h3>📊 Connection Status</h3>
            <p id="protocol-status"></p>
        </div>
        
        <div class="footer">
            <p>LAB 2.1 - Web Server in DMZ con HTTPS</p>
            <p>Cisco Packet Tracer - Network Security Course</p>
        </div>
    </div>
    
    <script>
        // Rilevare protocollo di connessione
        const protocol = window.location.protocol;
        const statusElement = document.getElementById('protocol-status');
        
        if (protocol === 'https:') {
            statusElement.innerHTML = '<strong style="color: #4caf50;">🔒 Connesso via HTTPS - Sicuro</strong><br>La tua connessione è criptata.';
        } else {
            statusElement.innerHTML = '<strong style="color: #ff9800;">⚠️ Connesso via HTTP - Non Sicuro</strong><br>Usa HTTPS per una connessione protetta.';
        }
    </script>
</body>
</html>
```

### Step 3.5 - Creare Pagina Sicura (Solo HTTPS)

Crea nuovo file: **secure.html**

```html
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>Secure Page - HTTPS Only</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: #1e1e1e;
            color: #00ff00;
            padding: 40px;
            text-align: center;
        }
        .secure-box {
            border: 3px solid #00ff00;
            padding: 30px;
            max-width: 600px;
            margin: 50px auto;
            background: rgba(0, 255, 0, 0.1);
        }
    </style>
</head>
<body>
    <div class="secure-box">
        <h1>🔐 SECURE AREA</h1>
        <h2>HTTPS Required</h2>
        <p>Questa pagina contiene informazioni sensibili.</p>
        <p>Accessibile solo tramite connessione HTTPS criptata.</p>
        <hr>
        <p><strong>Protocol:</strong> <span id="proto"></span></p>
        <p><strong>Port:</strong> <span id="port"></span></p>
    </div>
    
    <script>
        document.getElementById('proto').textContent = window.location.protocol;
        document.getElementById('port').textContent = window.location.port || '(default)';
        
        // Redirect se non HTTPS
        if (window.location.protocol !== 'https:') {
            document.body.innerHTML = '<h1 style="color: red;">⛔ ACCESS DENIED</h1><p>This page requires HTTPS.</p>';
        }
    </script>
</body>
</html>
```

---

## Parte 4: Configurazione PC

**PC-1:**
- IP: `172.16.0.10/24`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

**PC-2:**
- IP: `172.16.0.11/24`
- Gateway: `172.16.0.1`
- DNS: `8.8.8.8`

**Internet:**
- IP: `192.0.2.2/30`

---

## Parte 5: Test di Accesso

### Test 1: HTTP da LAN

1. **PC-1** → Desktop → **Web Browser**
2. URL: `http://10.0.1.10`
3. **Risultato atteso:** ✅ Pagina visualizzata (messaggio protocollo HTTP)

### Test 2: HTTPS da LAN

1. **PC-1** → Web Browser
2. URL: `https://10.0.1.10`
3. **Risultato atteso:** ✅ Pagina visualizzata (messaggio HTTPS sicuro)

**Nota PT:** In Packet Tracer potresti vedere warning certificato self-signed (normale).

### Test 3: HTTP da Internet (via NAT)

1. **Internet** → Desktop → Web Browser
2. URL: `http://192.0.2.1` (IP pubblico del firewall)
3. **Risultato atteso:** ✅ Pagina forwarded al server DMZ

### Test 4: HTTPS da Internet

1. **Internet** → Web Browser
2. URL: `https://192.0.2.1`
3. **Risultato atteso:** ✅ Connessione sicura tramite porta 443

### Test 5: Pagina Secure (solo HTTPS)

1. **PC-1** → Web Browser
2. URL HTTP: `http://10.0.1.10/secure.html`
   - **Risultato:** ⚠️ Access Denied message
3. URL HTTPS: `https://10.0.1.10/secure.html`
   - **Risultato:** ✅ Accesso permesso

---

## Parte 6: Verifica NAT Port Forwarding

### Comandi Verifica

```cisco
FW-WEB# show ip nat translations

! Output atteso:
Pro Inside global         Inside local          Outside local         Outside global
tcp 192.0.2.1:80          10.0.1.10:80          ---                   ---
tcp 192.0.2.1:443         10.0.1.10:443         ---                   ---

! Statistiche NAT
FW-WEB# show ip nat statistics

! Testare con traffico attivo
! (mentre PC accede al server)
FW-WEB# show ip nat translations verbose
```

---

## Parte 7: Implementare HTTP → HTTPS Redirect

**Nota:** In Packet Tracer, il redirect avanzato è limitato. In ambiente reale (Apache/Nginx):

### Configurazione Apache (Riferimento)

```apache
<VirtualHost *:80>
    ServerName www.example.com
    
    # Redirect permanente HTTP → HTTPS
    Redirect permanent / https://www.example.com/
    
    # O usando mod_rewrite
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>

<VirtualHost *:443>
    ServerName www.example.com
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/certificate.crt
    SSLCertificateKeyFile /etc/ssl/private/private.key
    
    # Security headers
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    
    DocumentRoot /var/www/html
</VirtualHost>
```

### Configurazione Nginx (Riferimento)

```nginx
server {
    listen 80;
    server_name www.example.com;
    
    # Redirect HTTP → HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name www.example.com;
    
    ssl_certificate /etc/ssl/certs/certificate.crt;
    ssl_certificate_key /etc/ssl/private/private.key;
    
    # TLS/SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    root /var/www/html;
    index index.html;
}
```

---

## Parte 8: ACL Avanzate per HTTPS

### Limitare Accesso HTTPS a IP Specifici

```cisco
! ACL per limitare HTTPS a solo LAN interna
FW-WEB(config)# ip access-list extended HTTPS-RESTRICTED

! Permettere HTTPS solo da LAN
FW-WEB(config-ext-nacl)# permit tcp 172.16.0.0 0.0.0.255 host 10.0.1.10 eq 443

! Permettere HTTP da qualsiasi
FW-WEB(config-ext-nacl)# permit tcp any host 10.0.1.10 eq 80

! Applicare alla DMZ (outbound)
FW-WEB(config)# interface GigabitEthernet 0/1
FW-WEB(config-if)# ip access-group HTTPS-RESTRICTED out
```

---

## Parte 9: Monitoring e Logging

### Step 9.1 - Abilitare Logging HTTP/HTTPS

```cisco
FW-WEB(config)# logging buffered 51200 informational
FW-WEB(config)# service timestamps log datetime msec

! Log per ACL
FW-WEB(config)# ip access-list extended INTERNET-TO-DMZ
FW-WEB(config-ext-nacl)# 10 permit tcp any host 10.0.1.10 eq 80 log
FW-WEB(config-ext-nacl)# 20 permit tcp any host 10.0.1.10 eq 443 log
```

### Step 9.2 - Visualizzare Log

```cisco
FW-WEB# show logging | include 10.0.1.10

! Monitor in tempo reale
FW-WEB# terminal monitor
FW-WEB# debug ip nat
```

---

## Parte 10: Best Practices HTTP/HTTPS

### Checklist Implementazione

- [x] ✅ HTTPS abilitato su porta 443
- [x] ✅ HTTP su porta 80 (per redirect)
- [x] ✅ Port forwarding configurato per entrambe porte
- [x] ✅ ACL permette 80 e 443 da Internet
- [ ] ⏳ Certificato SSL valido (self-signed in lab)
- [ ] ⏳ HTTP → HTTPS redirect
- [ ] ⏳ HSTS header (Strict-Transport-Security)
- [ ] ⏳ Disabilitare TLS 1.0/1.1 (solo 1.2/1.3)
- [ ] ⏳ Strong cipher suites
- [ ] ⏳ Certificate pinning (avanzato)

### Security Headers (Riferimento Reale)

```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Content-Security-Policy: default-src 'self'
Referrer-Policy: no-referrer-when-downgrade
```

---

## Parte 11: Troubleshooting

### Problema 1: HTTPS non funziona

**Sintomi:** Browser non carica `https://...`

**Debug:**
```cisco
FW-WEB# show ip nat translations | include 443
FW-WEB# show access-lists | include 443
```

**Verificare:**
- Port forwarding 443 configurato
- ACL permette TCP 443
- Servizio HTTPS ON sul server

### Problema 2: Certificato invalido

**In Packet Tracer:** Normale (self-signed)

**In produzione:**
- Usare Let's Encrypt per certificati gratuiti
- Verificare CN (Common Name) match hostname
- Controllare validità certificato

```bash
openssl x509 -in certificate.crt -text -noout
```

### Problema 3: Mixed Content Warning

**Causa:** Pagina HTTPS carica risorse HTTP

**Soluzione:** Assicurati che tutte le risorse siano HTTPS:
```html
<!-- SBAGLIATO -->
<img src="http://example.com/image.jpg">

<!-- CORRETTO -->
<img src="https://example.com/image.jpg">
<!-- O meglio: relative URL -->
<img src="/images/image.jpg">
```

---

## Parte 12: Testing con Command Line

### Test da PC usando Command Prompt

**Test HTTP:**
```
C:\> ping 10.0.1.10
(verificare connettività)
```

**In ambiente reale (non PT):**
```bash
# Test HTTP
curl -I http://10.0.1.10

# Test HTTPS
curl -I https://10.0.1.10

# Verificare certificato
openssl s_client -connect 10.0.1.10:443 -showcerts

# Test redirect
curl -L http://10.0.1.10
```

---

## Conclusioni

🎉 **Congratulazioni!** Hai completato:
- ✅ Configurazione web server HTTP/HTTPS
- ✅ Port forwarding per porte multiple
- ✅ Certificate management (simulato)
- ✅ ACL per traffico HTTPS
- ✅ Pagine web responsive e sicure
- ✅ Test completi da LAN e Internet

### Concetti Appresi
- **HTTP vs HTTPS** (crittografia TLS/SSL)
- **Port forwarding multi-porta**
- **SSL/TLS certificates**
- **Security headers**
- **HTTP → HTTPS redirect**
- **NAT per servizi web**

### Differenze HTTP vs HTTPS

| Caratteristica | HTTP | HTTPS |
|----------------|------|-------|
| **Porta** | 80 | 443 |
| **Crittografia** | ❌ No | ✅ Sì (TLS/SSL) |
| **Certificato** | Non necessario | Richiesto |
| **Prestazioni** | Leggermente più veloce | Overhead minimo |
| **SEO** | Penalizzato | Favorito Google |
| **Trust** | ⚠️ Non sicuro | ✅ Sicuro |

### Prossimi Passi
- **LAB 2.2**: Mail Server con TLS
- **LAB 3.x**: ACL avanzate
- **Progetto reale**: Deploy su VPS con Let's Encrypt

---

**Salvare:** File → Save As → `lab2.1-web-server-https.pkt`

**Fine Laboratorio 2.1**
