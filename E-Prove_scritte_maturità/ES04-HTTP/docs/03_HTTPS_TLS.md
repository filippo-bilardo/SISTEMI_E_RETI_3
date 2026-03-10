# 03 — HTTPS e TLS: Comunicazione Web Sicura

## Perché HTTP Non è Sicuro

Il protocollo HTTP trasmette tutti i dati **in chiaro** (plaintext): testo leggibile direttamente da chiunque riesca ad intercettare il traffico di rete. Questo espone gli utenti a numerosi rischi.

### Scenari di attacco su HTTP

#### 1. Sniffing / Intercettazione
Un attaccante sulla stessa rete (es. Wi-Fi pubblica in un bar) può catturare il traffico di rete con strumenti come **Wireshark** o **tcpdump** e leggere:
- Username e password di login
- Dati di carte di credito
- Contenuto delle email webmail
- Cookie di sessione (che permettono di impersonare l'utente)

```
PC utente ----HTTP----> Access Point Wi-Fi -----> Server
                              |
                        [Attaccante con
                         Wireshark vede tutto]
```

#### 2. Man-in-the-Middle (MITM)
L'attaccante si inserisce tra client e server, intercettando e potenzialmente modificando le comunicazioni:

```
PC utente ----> [Attaccante] ----> Server
                    ↓
           Legge E modifica
           i dati in transito
```

Tecniche comuni per MITM su reti locali:
- **ARP spoofing**: avvelena la cache ARP dei dispositivi
- **DNS poisoning**: risponde con IP falsi alle query DNS
- **Rogue AP**: crea un access point Wi-Fi falso

#### 3. Injection
L'attaccante può iniettare contenuto malevolo nelle risposte HTTP prima che arrivino al browser:
- Inserire codice JavaScript (cross-site scripting tramite MITM)
- Modificare il contenuto di una pagina
- Aggiungere pubblicità o link a malware

#### 4. Cosa vede l'attaccante su HTTP

```
[RICHIESTA HTTP intercettata — VISIBILE IN CHIARO]

POST /login HTTP/1.1
Host: www.banca.it
Content-Type: application/x-www-form-urlencoded

username=mario.rossi&password=MiaPassword123!
          ↑                    ↑
          VISIBILE!            VISIBILE!
```

> ⚠️ **Regola pratica**: su qualsiasi rete che non controlli (Wi-Fi pubblica, rete aziendale sconosciuta), usare HTTP equivale a trasmettere le credenziali su un foglio di carta aperto.

---

## TLS — Transport Layer Security

**TLS** (*Transport Layer Security*) è il protocollo crittografico che HTTPS usa per garantire la sicurezza della comunicazione. TLS opera tra il livello applicativo (HTTP) e il livello di trasporto (TCP), creando un "tunnel" cifrato.

### Proprietà garantite da TLS

| Proprietà | Descrizione | Come si ottiene |
|-----------|-------------|-----------------|
| **Riservatezza** | I dati sono cifrati e illeggibili agli intercettatori | Cifratura simmetrica (AES, ChaCha20) |
| **Autenticazione** | Il server (e opzionalmente il client) è chi dice di essere | Certificati X.509 firmati da CA |
| **Integrità** | I dati non possono essere modificati in transito | HMAC, firma digitale |

### Versioni di TLS

| Versione | Anno | Stato | Note |
|----------|------|-------|------|
| SSL 2.0 | 1995 | ❌ Deprecato | Vulnerabilità gravi |
| SSL 3.0 | 1996 | ❌ Deprecato | Attacco POODLE (2014) |
| TLS 1.0 | 1999 | ❌ Deprecato | Attacchi BEAST, POODLE su CBC |
| TLS 1.1 | 2006 | ❌ Deprecato | Rimosso dai browser moderni (2020) |
| **TLS 1.2** | **2008** | ✅ Raccomandato | Standard attuale, molto diffuso |
| **TLS 1.3** | **2018** | ✅ Raccomandato | Più veloce, più sicuro, handshake semplificato |

> 💡 Da gennaio 2020, tutti i principali browser (Chrome, Firefox, Safari, Edge) hanno disabilitato TLS 1.0 e 1.1.

---

## Handshake TLS 1.2 — Passo per Passo

L'**handshake TLS** è la fase iniziale in cui client e server si autenticano, negoziano i parametri crittografici e stabiliscono le chiavi di sessione.

```
CLIENT                                          SERVER
  |                                               |
  |-------- 1. ClientHello ---------------------->|
  |   Versioni TLS supportate                     |
  |   Cipher suites supportate                    |
  |   Client Random (32 byte casuali)             |
  |   Estensioni (SNI, ALPN...)                   |
  |                                               |
  |<-------- 2. ServerHello ----------------------|
  |   Versione TLS scelta                         |
  |   Cipher suite scelta                         |
  |   Server Random (32 byte casuali)             |
  |                                               |
  |<-------- 3. Certificate ----------------------|
  |   Certificato X.509 del server                |
  |   (contiene chiave pubblica del server)       |
  |                                               |
  |<-------- 4. ServerHelloDone ------------------|
  |                                               |
  |  [CLIENT verifica il certificato:             |
  |   - Firma della CA valida?                    |
  |   - Certificato non scaduto?                  |
  |   - Nome host corrisponde?]                   |
  |                                               |
  |-------- 5. ClientKeyExchange --------------->|
  |   Pre-Master Secret cifrato con chiave        |
  |   pubblica del server                         |
  |                                               |
  |  [ENTRAMBI calcolano la Master Secret         |
  |   e derivano le chiavi di sessione]           |
  |                                               |
  |-------- 6. ChangeCipherSpec ----------------->|
  |   "Da ora in poi cifro tutto"                 |
  |                                               |
  |-------- 7. Finished ------------------------->|
  |   Hash di tutto l'handshake (cifrato)         |
  |                                               |
  |<-------- 8. ChangeCipherSpec -----------------|
  |<-------- 9. Finished --------------------------|
  |                                               |
  |========= TUNNEL CIFRATO TLS STABILITO ========|
  |                                               |
  |-------- HTTP GET /pagina.html --------------->|  (cifrato)
  |<-------- HTTP 200 OK + HTML ------------------|  (cifrato)
```

### Handshake TLS 1.3 — Più Veloce

TLS 1.3 riduce il numero di round-trip dell'handshake:

```
CLIENT                                          SERVER
  |                                               |
  |--- ClientHello + Key Share ------------------>|
  |    (include subito la chiave DH pubblica)     |
  |                                               |
  |<-- ServerHello + Certificate + Finished ------|
  |    (server risponde in un solo messaggio)     |
  |                                               |
  |--- Finished + HTTP Request ------------------>|
  |                                               |
  |  1-RTT (un solo round-trip per handshake)     |
  |  vs 2-RTT di TLS 1.2                          |
```

---

## Certificati X.509

Un **certificato digitale X.509** è un documento elettronico che associa una chiave pubblica a un'identità (nome di dominio, organizzazione). È firmato digitalmente da un'autorità fidata (**CA — Certificate Authority**).

### Struttura di un certificato X.509

```
┌─────────────────────────────────────────────────────────────┐
│  CERTIFICATO X.509                                          │
├─────────────────────────────────────────────────────────────┤
│  Versione: 3                                                │
│  Numero Seriale: 0x1A2B3C4D5E6F                            │
│  Algoritmo firma: SHA256withRSA                             │
├─────────────────────────────────────────────────────────────┤
│  SOGGETTO (Subject):                                        │
│    CN = www.banca.it                                        │
│    O  = Banca Sicura S.p.A.                                 │
│    C  = IT                                                  │
│    L  = Milano                                              │
├─────────────────────────────────────────────────────────────┤
│  EMITTENTE (Issuer — la CA):                                │
│    CN = DigiCert TLS RSA SHA256 2020 CA1                    │
│    O  = DigiCert Inc                                        │
│    C  = US                                                  │
├─────────────────────────────────────────────────────────────┤
│  VALIDITÀ:                                                  │
│    Non prima di: 2024-01-01 00:00:00 UTC                    │
│    Non dopo:     2025-01-01 23:59:59 UTC                    │
├─────────────────────────────────────────────────────────────┤
│  CHIAVE PUBBLICA: RSA 2048-bit                              │
│    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQ...            │
├─────────────────────────────────────────────────────────────┤
│  ESTENSIONI:                                                │
│    Subject Alternative Name: DNS:www.banca.it, DNS:banca.it │
│    Key Usage: Digital Signature, Key Encipherment           │
│    Extended Key Usage: TLS Web Server Authentication        │
├─────────────────────────────────────────────────────────────┤
│  FIRMA DIGITALE della CA:                                   │
│    (hash del certificato, cifrato con chiave privata CA)    │
└─────────────────────────────────────────────────────────────┘
```

### CA — Certificate Authority

Le **CA** (Autorità di Certificazione) sono enti fidati che:
1. Verificano l'identità di chi richiede un certificato
2. Firmano il certificato con la propria chiave privata
3. Mantengono liste di certificati revocati (CRL / OCSP)

**Gerarchia di fiducia (catena di certificati):**
```
Root CA (auto-firmata, pre-installata nel browser/OS)
    └── Intermediate CA (firmata dalla Root CA)
            └── Certificato del sito web (firmato dall'Intermediate CA)
```

**CA principali nel mondo:**
- DigiCert
- Sectigo (ex Comodo)
- GlobalSign
- Let's Encrypt (gratuita, automatizzata)
- IdenTrust

### Tipi di certificato

| Tipo | Sigla | Verifica | Indicato per | Costo |
|------|-------|---------|--------------|-------|
| Domain Validated | DV | Solo proprietà dominio (automatica) | Siti personali, blog | Gratis (Let's Encrypt) |
| Organization Validated | OV | Identità organizzazione (manuale) | Aziende, e-commerce | ~50–200 €/anno |
| Extended Validation | EV | Verifica approfondita (legale) | Banche, servizi critici | ~200–800 €/anno |
| Wildcard | * | Un dominio + tutti i sottodomini | `*.esempio.it` | ~100–400 €/anno |
| Multi-domain (SAN) | SAN | Più domini in un certificato | Ottimizzazione costi | Variabile |

### Certificati Self-Signed
I certificati **auto-firmati** sono creati e firmati dallo stesso server, senza una CA. Il browser mostra un avviso di sicurezza perché non può verificare l'identità del server.

```
⚠️ La connessione non è privata
   Impossibile verificare l'identità del sito.
   www.server-interno.local usa un certificato di sicurezza
   non considerato attendibile dal computer.
```

**Uso accettabile**: reti interne aziendali, laboratori, testing.  
**Non accettabile**: siti pubblici, qualsiasi servizio che gestisce dati sensibili.

---

## HSTS — HTTP Strict Transport Security

**HSTS** è un meccanismo di sicurezza che forza il browser a usare **sempre HTTPS** per un dominio, anche se l'utente digita `http://`.

### Come funziona

Il server include nella risposta HTTPS:
```http
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
```

| Parametro | Significato |
|-----------|-------------|
| `max-age=31536000` | Il browser ricorda di usare HTTPS per 1 anno (31536000 secondi) |
| `includeSubDomains` | Estende la regola a tutti i sottodomini |
| `preload` | Richiede inserimento nella preload list dei browser |

### HSTS Preload
Browser come Chrome e Firefox mantengono una lista di domini "HSTS preloaded": per questi domini, HTTPS viene usato **prima ancora di contattare il server** (protegge anche la prima connessione). Sito: [hstspreload.org](https://hstspreload.org/)

---

## Redirect da HTTP a HTTPS

Il pattern standard per forzare HTTPS è un redirect 301:

```
Client        Server HTTP (porta 80)      Server HTTPS (porta 443)
  |                    |                            |
  |-- GET / HTTP/1.0 ->|                            |
  |                    |-- 301 + Location: https:// ->|
  |<-- 301 Moved ----  |                            |
  |                                                 |
  |-------------- HTTPS GET / -------------------->|
  |<------------- HTTPS 200 OK + pagina -----------|
```

### Configurazione tipica (es. Apache)
```apache
<VirtualHost *:80>
    ServerName www.esempio.it
    Redirect permanent / https://www.esempio.it/
</VirtualHost>

<VirtualHost *:443>
    ServerName www.esempio.it
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/esempio.crt
    SSLCertificateKeyFile /etc/ssl/private/esempio.key
    # ...configurazione sito...
</VirtualHost>
```

---

## HTTPS in Cisco Packet Tracer

### Cosa PT simula
Cisco Packet Tracer include una simulazione semplificata di HTTPS:
- Il servizio HTTPS si abilita su **Services → HTTP → HTTPS: On** (porta 443)
- Il browser simulato supporta `https://` come prefisso
- PT mostra i pacchetti TCP sulla porta 443 in Simulation Mode

### Limitazioni della simulazione
| Funzionalità | HTTP in PT | HTTPS in PT |
|---|---|---|
| Visualizzazione PDU completa | ✅ Sì | ⚠️ Parziale |
| Handshake TLS | ❌ Non simulato | ❌ Non simulato |
| Certificati reali | ❌ No | ❌ No |
| Verifica certificato | ❌ No | ❌ No |
| Contenuto cifrato | ❌ No | ❌ No (PT non cifra) |

> 💡 In PT, HTTPS viene trattato come HTTP sulla porta 443, senza vera cifratura. Per lo studio del TLS in modo realistico si usa **Wireshark** con traffico reale o applicazioni dedicate.

---

## Come Verificare HTTPS nel Browser

### Il lucchetto 🔒
- **Lucchetto chiuso verde/grigio**: connessione HTTPS con certificato valido
- **Lucchetto con avviso ⚠️**: HTTPS ma con problemi (contenuto misto HTTP/HTTPS, certificato quasi scaduto)
- **"Non sicuro" ⛔**: HTTP o HTTPS con certificato invalido

### Informazioni del certificato
In Chrome/Firefox: clicca sul lucchetto → "La connessione è sicura" → "Certificato valido"

Si visualizza:
- Nome del dominio (CN / SAN)
- Organizzazione (se certificato OV/EV)
- Emittente (CA)
- Date di validità
- Impronta digitale (fingerprint SHA-256)

### DevTools — Tab Security
1. Apri DevTools (F12) → tab **Security**
2. Mostra: protocollo TLS, cipher suite usata, validità certificato, key exchange algorithm

---

## Let's Encrypt — Certificati Gratuiti

**Let's Encrypt** è una CA gratuita, automatizzata e open-source gestita da ISRG (Internet Security Research Group). Ha reso HTTPS accessibile a tutti:

- **Gratuito**: nessun costo per il certificato
- **Automatico**: il tool `certbot` ottiene e rinnova automaticamente i certificati
- **Dominio Validated (DV)**: verifica solo la proprietà del dominio
- **Durata**: 90 giorni (rinnovabili automaticamente)
- **Ampiamente fidata**: certificati riconosciuti da tutti i browser moderni

```bash
# Installazione certbot e ottenimento certificato (esempio su Ubuntu + Apache)
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d www.esempio.it -d esempio.it

# Il certificato viene salvato in:
# /etc/letsencrypt/live/www.esempio.it/fullchain.pem  (certificato + catena)
# /etc/letsencrypt/live/www.esempio.it/privkey.pem    (chiave privata)
```

---

> 📖 Continua con: [04_Cookie_Sessioni_Cache.md](04_Cookie_Sessioni_Cache.md) — Cookie, sessioni, autenticazione e cache HTTP
