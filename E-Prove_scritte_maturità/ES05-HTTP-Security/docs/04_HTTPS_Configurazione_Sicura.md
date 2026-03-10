# 04 — HTTPS: Configurazione Sicura

> 🎯 **Obiettivo**: Sapere configurare HTTPS in modo davvero sicuro — non basta attivarlo, bisogna scegliere le versioni TLS corrette, le cipher suite adeguate, gestire i certificati e applicare le best practice di hardening.

---

## 1. Versioni TLS: Quali Usare e Quali Evitare

### 1.1 Storia delle versioni

| Versione | Anno | Stato | Note |
|----------|------|-------|------|
| **SSL 2.0** | 1995 | ❌ Deprecato | Vulnerabilità critiche, vietato dal RFC 6176 |
| **SSL 3.0** | 1996 | ❌ Deprecato | Attacco POODLE (2014), vietato dal RFC 7568 |
| **TLS 1.0** | 1999 | ❌ Deprecato (2020) | Attacchi BEAST, POODLE. Browser moderni non lo supportano |
| **TLS 1.1** | 2006 | ❌ Deprecato (2020) | Miglioramento minimo su TLS 1.0. Rimosso da tutti i browser moderni |
| **TLS 1.2** | 2008 | ✅ Supportato | Sicuro con le cipher suite giuste. Ancora necessario per compatibilità |
| **TLS 1.3** | 2018 | ✅ Raccomandato | Più veloce, più sicuro, semplificato. Usare come default |

### 1.2 Configurazione Nginx (versioni TLS)

```nginx
# /etc/nginx/nginx.conf o nel server block
ssl_protocols TLSv1.2 TLSv1.3;   # Abilita solo 1.2 e 1.3
# ssl_protocols TLSv1 TLSv1.1;   # NON includere mai queste righe
```

### 1.3 Configurazione Apache

```apache
# /etc/apache2/mods-enabled/ssl.conf
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
# oppure esplicitamente:
SSLProtocol TLSv1.2 TLSv1.3
```

### 1.4 Novità di TLS 1.3

| Caratteristica | TLS 1.2 | TLS 1.3 |
|----------------|---------|---------|
| Handshake RTT | 2 RTT | 1 RTT (o 0-RTT per connessioni riprese) |
| Cipher suites supportate | Molte (alcune deboli) | Solo 5, tutte sicure |
| Forward Secrecy | Opzionale | ✅ Obbligatorio |
| Compressione TLS | Presente (vulnerabile a CRIME) | ❌ Rimossa |
| Renegotiation | Presente (vulnerabile) | ❌ Rimossa |

---

## 2. Cipher Suites: Sicure vs Deboli

### 2.1 Cos'è una Cipher Suite

Una **cipher suite** è una combinazione di algoritmi crittografici usata durante la connessione TLS:
- **Algoritmo di scambio chiavi** (key exchange): come server e client si accordano sulla chiave segreta
- **Algoritmo di autenticazione**: come il server prova la propria identità
- **Algoritmo di cifratura** (bulk encryption): come vengono cifrati i dati
- **Algoritmo di hash MAC**: come viene verificata l'integrità

**Notazione** (TLS 1.2):
```
TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
 │     │     │        │    │    │
 │     │     │        │    │    └─ Hash MAC: SHA-384
 │     │     │        │    └────── Modalità: GCM (Authenticated Encryption)
 │     │     │        └─────────── Chiave simmetrica: AES 256 bit
 │     │     └──────────────────── Autenticazione: RSA
 │     └────────────────────────── Key exchange: ECDHE (Elliptic Curve Diffie-Hellman Ephemeral)
 └──────────────────────────────── Protocollo: TLS
```

### 2.2 Cipher Suites Sicure (TLS 1.2)

```
✅ TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
✅ TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
✅ TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
✅ TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
✅ TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256
✅ TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256
```

### 2.3 Cipher Suites da Evitare

```
❌ TLS_RSA_* — no Forward Secrecy (la chiave privata compromessa decifra tutto il traffico passato)
❌ *_RC4_* — RC4 è rotto crittograficamente
❌ *_3DES_* — SWEET32 attack (compleanno su blocchi a 64 bit)
❌ *_DES_* — solo 56 bit di chiave, rotto dal 1999
❌ *_EXPORT_* — cipher suite indebolite (40-56 bit) per l'export USA degli anni '90
❌ *_NULL_* — nessuna cifratura!
❌ *_anon_* — nessuna autenticazione del server
```

### 2.4 Forward Secrecy (Perfect Forward Secrecy)

La **Forward Secrecy** (o Perfect Forward Secrecy, PFS) garantisce che, anche se la chiave privata del server venisse compromessa in futuro, le sessioni passate rimangano confidenziali.

Come funziona:
- Con PFS: ogni sessione usa una chiave effimera (ECDHE = Elliptic Curve Diffie-Hellman **Ephemeral**)
- Le chiavi effimere vengono distrutte dopo la sessione
- Compromettere la chiave privata del certificato non permette di decifrare sessioni passate

Senza PFS: se un attaccante registra tutto il traffico cifrato oggi e ottiene la chiave privata anni dopo, può decifrare retroattivamente tutto.

### 2.5 Configurazione Cipher Suite Nginx

```nginx
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;  # TLS 1.3: lascia scegliere al client
```

---

## 3. Certificati TLS: Gestione e Best Practice

### 3.1 Dimensione della Chiave

| Tipo | Dimensione minima | Dimensione raccomandata | Note |
|------|------------------|------------------------|------|
| **RSA** | 2048 bit | 3072–4096 bit | Più sicuro con chiavi più grandi, ma più lento |
| **ECDSA** (Elliptic Curve) | 256 bit (P-256) | 256 o 384 bit | Più efficiente di RSA a parità di sicurezza |
| **Ed25519** | — | — | Curva moderna, molto veloce, supporto crescente |

> 💡 ECDSA con P-256 (256 bit) offre sicurezza equivalente a RSA-3072 con prestazioni migliori. Raccomandato per nuove installazioni.

### 3.2 Tipi di Certificati

| Tipo | Validazione | Costo | Uso consigliato |
|------|------------|-------|----------------|
| **DV** (Domain Validation) | Solo controllo DNS | Gratuito (Let's Encrypt) | Siti generali |
| **OV** (Organization Validation) | Identità organizzazione verificata | €/anno | Aziende e siti commerciali |
| **EV** (Extended Validation) | Verifica approfondita dell'identità | €€/anno | Banche, e-commerce ad alto valore |
| **Wildcard** (`*.example.com`) | DV o OV per tutti i sottodomini | Varia | Quando si hanno molti sottodomini |
| **SAN** (Subject Alternative Names) | Un certificato per più domini | Varia | Hosting multipli sullo stesso server |

### 3.3 Let's Encrypt — Certificati Gratuiti

**Let's Encrypt** è una CA (Certificate Authority) gratuita, automatizzata e pubblica, gestita dalla Internet Security Research Group (ISRG).

- **Costo**: completamente gratuito
- **Validità**: 90 giorni (rinnovo automatico con Certbot)
- **Tipo**: DV (Domain Validation)
- **Supporto browser**: universale

**Installazione con Certbot** (Nginx su Ubuntu):
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

### 3.4 Rinnovo Certificati

| Metodo | Frequenza | Automazione |
|--------|-----------|-------------|
| Let's Encrypt + Certbot | Ogni 90 giorni | ✅ Automatico (cron/systemd) |
| Certificati a pagamento | Ogni 1–2 anni | ⚠️ Manuale o semi-automatico |

**Cron job per rinnovo automatico**:
```
0 12 * * * certbot renew --quiet
```

---

## 4. HSTS Preloading

### 4.1 Processo di iscrizione

1. Configurare HTTPS correttamente su tutti i sottodomini
2. Aggiungere l'header HSTS con `max-age=31536000; includeSubDomains; preload`
3. Verificare su [hstspreload.org](https://hstspreload.org)
4. Inviare la richiesta di iscrizione

**Tempi**: l'iscrizione richiede settimane/mesi per la distribuzione in tutti i browser.

> ⚠️ **Attenzione**: Una volta in preload list, rimuovere HTTPS è molto difficile (richiede mesi). Assicurarsi di voler mantenere HTTPS per sempre prima di iscriversi.

### 4.2 Come rimuoversi dalla Preload List

Solo via [hstspreload.org/removal](https://hstspreload.org/removal) — processo lento (mesi per la propagazione nei browser).

---

## 5. Redirect HTTP → HTTPS

### 5.1 Redirect 301 vs 302

| Codice | Tipo | Caching | Uso |
|--------|------|---------|-----|
| **301** | Permanente | ✅ Sì (browser lo memorizza) | Redirect HTTP→HTTPS definitivo |
| **302** | Temporaneo | ❌ No | Non usare per HTTPS redirect |

### 5.2 Configurazione Nginx

```nginx
server {
    listen 80;
    server_name example.com www.example.com;

    # Redirect permanente 301 verso HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # ... resto della configurazione ...
}
```

### 5.3 Configurazione Apache

```apache
<VirtualHost *:80>
    ServerName example.com
    # Redirect all'HTTPS
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>
```

### 5.4 Mixed Content

Il **Mixed Content** si verifica quando una pagina HTTPS carica risorse via HTTP (script, stili, immagini, iframe). Il browser moderno blocca questo comportamento.

| Tipo di misto | Browser moderni | Rischio |
|--------------|----------------|---------|
| **Script/CSS** via HTTP | ❌ Bloccato automaticamente | Critico: XSS e modifica stili possibili |
| **Immagini** via HTTP | ⚠️ Warning (in via di blocco) | Moderato: privacy leak |
| **Audio/Video** via HTTP | ⚠️ Warning | Moderato |
| **iFrame** via HTTP | ❌ Bloccato automaticamente | Critico |

**Come risolvere il mixed content**:
1. Cambiare tutti gli URL delle risorse da `http://` a `https://` nel codice sorgente
2. Usare URL relativi al protocollo: `//example.com/style.css` (usa lo stesso schema della pagina)
3. Aggiungere l'header CSP `upgrade-insecure-requests`: il browser converte automaticamente le richieste HTTP in HTTPS

```http
Content-Security-Policy: upgrade-insecure-requests
```

---

## 6. OCSP Stapling

### 6.1 Il problema: verifica della revoca

Come fa il browser a sapere se un certificato è stato revocato prima della scadenza? Tradizionalmente:
- **CRL** (Certificate Revocation List): lista di certificati revocati pubblicata dalla CA — può essere grande e obsoleta
- **OCSP** (Online Certificate Status Protocol): il browser chiede direttamente alla CA se il certificato è valido

**Problema con OCSP**: il browser contatta la CA della CA per ogni connessione → **privacy leak** (la CA sa quale sito stai visitando) + **latenza aggiuntiva**.

### 6.2 Soluzione: OCSP Stapling

Con OCSP Stapling:
1. Il **server** interroga periodicamente la CA e ottiene una risposta OCSP firmata
2. Il server **allega** (staple) questa risposta al TLS handshake
3. Il browser verifica la risposta OCSP senza contattare la CA
4. Nessun privacy leak, nessuna latenza aggiuntiva

```nginx
# Abilitare OCSP Stapling in Nginx
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
```

---

## 7. Test di Sicurezza TLS

### 7.1 SSL Labs (Qualys)

Il tool più usato per testare la configurazione HTTPS di un sito pubblico.

- **URL**: [ssllabs.com/ssltest](https://www.ssllabs.com/ssltest/)
- **Valutazione**: da A+ (eccellente) a F (critico)
- **Cosa controlla**: versioni TLS, cipher suites, certificato, HSTS, vulnerabilità note (POODLE, BEAST, HEARTBLEED, ecc.)

### 7.2 Obiettivo: Rating A+

Per ottenere **A+** su SSL Labs:
- TLS 1.2 e 1.3 abilitati (niente versioni precedenti)
- Solo cipher suites con Forward Secrecy
- HSTS con `max-age` ≥ 180 giorni
- Nessuna vulnerabilità nota
- Certificato valido, non scaduto, catena completa

### 7.3 Tool da Riga di Comando

**testssl.sh** — test locale senza inviare dati a terze parti:
```bash
./testssl.sh https://example.com
```

**Verifica manuale con openssl**:
```bash
# Vedere il certificato del server
openssl s_client -connect example.com:443 -showcerts

# Testare se TLS 1.0 è ancora accettato (dovrebbe fallire su server sicuro)
openssl s_client -connect example.com:443 -tls1

# Testare TLS 1.3
openssl s_client -connect example.com:443 -tls1_3
```

**Curl** — verifica connessione TLS:
```bash
curl -v https://example.com 2>&1 | grep -E "SSL|TLS|cipher"
```

---

## 8. Configurazione Sicura Completa

### 8.1 Nginx — Configurazione Hardened

```nginx
# /etc/nginx/sites-available/example.com

# Redirect HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}

# Server HTTPS principale
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name example.com www.example.com;

    # Certificato (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Versioni TLS
    ssl_protocols TLSv1.2 TLSv1.3;

    # Cipher suites sicure
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305;
    ssl_prefer_server_ciphers off;

    # Parametri DH (Forward Secrecy per TLS 1.2)
    ssl_dhparam /etc/ssl/certs/dhparam.pem;  # generato con: openssl dhparam -out /etc/ssl/certs/dhparam.pem 4096

    # Session cache
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;  # Disabilita per PFS completo

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/example.com/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;

    # Header di sicurezza HTTP
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # ... configurazione del sito ...
    root /var/www/example.com;
    index index.html;
}
```

### 8.2 Apache — Configurazione Hardened

```apache
<VirtualHost *:443>
    ServerName example.com

    # Certificato
    SSLCertificateFile /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

    # Versioni TLS
    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1

    # Cipher suites
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305
    SSLHonorCipherOrder off

    # HSTS
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"

    # Altri header di sicurezza
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    # OCSP Stapling
    SSLUseStapling on
    SSLStaplingResponderTimeout 5
    SSLStaplingReturnResponderErrors off

    # ... configurazione del sito ...
</VirtualHost>
```

---

## 9. Checklist Hardening HTTPS ✅

### Certificato e TLS
- [ ] Certificato valido, non scaduto, firmato da CA riconosciuta
- [ ] Catena di certificati completa (incluso intermediate)
- [ ] Chiave RSA ≥ 2048 bit o ECDSA ≥ 256 bit
- [ ] Solo TLS 1.2 e TLS 1.3 abilitati
- [ ] SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1 disabilitati
- [ ] Solo cipher suites con Forward Secrecy
- [ ] Nessuna cipher suite NULL, EXPORT, RC4, 3DES
- [ ] OCSP Stapling abilitato
- [ ] Session tickets disabilitati (per PFS completo)

### Redirect e Content
- [ ] Redirect 301 permanente da HTTP a HTTPS
- [ ] Nessun mixed content (tutte le risorse su HTTPS)
- [ ] Header CSP con `upgrade-insecure-requests` se ci sono ancora risorse HTTP

### Header di sicurezza
- [ ] HSTS con `max-age` ≥ 1 anno
- [ ] HSTS con `includeSubDomains` (se tutti i sottodomini usano HTTPS)
- [ ] X-Frame-Options: DENY (o SAMEORIGIN)
- [ ] X-Content-Type-Options: nosniff
- [ ] Content-Security-Policy configurata
- [ ] Referrer-Policy configurata
- [ ] Permissions-Policy configurata

### Verifica finale
- [ ] Test su SSL Labs → obiettivo A+
- [ ] Test su securityheaders.com → obiettivo A+
- [ ] Nessuna vulnerabilità nota (POODLE, BEAST, HEARTBLEED, ROBOT)
- [ ] Rinnovo certificato automatizzato (Certbot o equivalente)
