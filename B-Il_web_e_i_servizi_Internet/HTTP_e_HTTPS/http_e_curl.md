# Guida Pratica al Protocollo HTTP con curl

## Introduzione

Il protocollo HTTP (HyperText Transfer Protocol) è il fondamento della comunicazione web, e `curl` è uno degli strumenti più potenti per testarlo e comprenderlo. Questa guida ti accompagnerà attraverso esempi pratici per padroneggiare entrambi.

## 1. Installazione e Verifica di curl

### Verifica installazione
```bash
curl --version
```

**Output atteso:**
```
curl 7.68.0 (x86_64-pc-linux-gnu) libcurl/7.68.0 OpenSSL/1.1.1f zlib/1.2.11
Release-Date: 2020-01-08
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp smb smbs smtp smtps telnet tftp
Features: AsynchDNS brotli GSS-API HTTP2 HTTPS-proxy IPv6 Kerberos Largefile libz NTLM NTLM_WB PSL SPNEGO SSL TLS-SRP UnixSockets
```

### Installazione su diversi sistemi
- **Ubuntu/Debian**: `sudo apt-get install curl`
- **CentOS/RHEL**: `sudo yum install curl`
- **macOS**: Già preinstallato o `brew install curl`
- **Windows**: Scarica da https://curl.se/ o usa Windows Subsystem for Linux

## 2. Struttura di una Richiesta HTTP

Una richiesta HTTP è composta da:
- **Metodo** (GET, POST, PUT, DELETE, etc.)
- **URL** (risorsa richiesta)
- **Headers** (metadati della richiesta)
- **Body** (dati opzionali)

## 3. Metodi HTTP Fondamentali

### GET - Recuperare Dati

**Esempio base:**
```bash
curl https://httpbin.org/get
```

**Output atteso:**
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a1-7c4d5e6f1a2b3c4d5e6f7890"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get"
}
```

**Con parametri query:**
```bash
curl "https://httpbin.org/get?nome=Mario&eta=30"
```

**Output atteso:**
```json
{
  "args": {
    "eta": "30",
    "nome": "Mario"
  },
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a2-8d5e6f7a1b2c3d4e5f678901"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get?nome=Mario&eta=30"
}
```

**Visualizzare gli headers della risposta:**
```bash
curl -i https://httpbin.org/get
```

**Output atteso:**
```
HTTP/2 200
date: Thu, 07 Sep 2023 14:30:45 GMT
content-type: application/json
content-length: 347
server: gunicorn/19.9.0
access-control-allow-origin: *
access-control-allow-credentials: true

{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a3-9e6f7a8b1c2d3e4f56789012"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get"
}
```

**Solo gli headers (senza body):**
```bash
curl -I https://httpbin.org/get
```

**Output atteso:**
```
HTTP/2 200
date: Thu, 07 Sep 2023 14:31:12 GMT
content-type: application/json
content-length: 347
server: gunicorn/19.9.0
access-control-allow-origin: *
access-control-allow-credentials: true
```

### POST - Inviare Dati

**Invio dati form-encoded:**
```bash
curl -X POST \
  -d "username=mario&password=secret" \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {
    "password": "secret",
    "username": "mario"
  },
  "headers": {
    "Accept": "*/*",
    "Content-Length": "30",
    "Content-Type": "application/x-www-form-urlencoded",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a4-af7b8c9d1e2f3a4b5c6d7890"
  },
  "json": null,
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

**Invio JSON:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"nome": "Mario", "eta": 30}' \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "{\"nome\": \"Mario\", \"eta\": 30}",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "27",
    "Content-Type": "application/json",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a5-b08c9d0e1f2a3b4c5d6e7891"
  },
  "json": {
    "eta": 30,
    "nome": "Mario"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

**Invio file:**
```bash
curl -X POST \
  -F "file=@documento.pdf" \
  -F "descrizione=Il mio documento" \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "",
  "files": {
    "file": "data:application/pdf;base64,JVBERi0xLjQKJcfsj6IKNSAwIG9iago8PA..."
  },
  "form": {
    "descrizione": "Il mio documento"
  },
  "headers": {
    "Accept": "*/*",
    "Content-Length": "1456",
    "Content-Type": "multipart/form-data; boundary=------------------------d74496d66958873e",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a6-c19d0e1f2a3b4c5d6e7f8902"
  },
  "json": null,
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

### PUT - Aggiornare Risorse

```bash
curl -X PUT \
  -H "Content-Type: application/json" \
  -d '{"id": 1, "nome": "Mario Rossi", "email": "mario@example.com"}' \
  https://httpbin.org/put
```

**Output atteso:**
```json
{
  "args": {},
  "data": "{\"id\": 1, \"nome\": \"Mario Rossi\", \"email\": \"mario@example.com\"}",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "62",
    "Content-Type": "application/json",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a7-d2ae1f203b4c5d6e7f809123"
  },
  "json": {
    "email": "mario@example.com",
    "id": 1,
    "nome": "Mario Rossi"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/put"
}
```

### DELETE - Eliminare Risorse

```bash
curl -X DELETE https://httpbin.org/delete
```

**Output atteso:**
```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a8-e3bf203c4d5e6f7890ab1234"
  },
  "json": null,
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/delete"
}
```

## 4. Gestione degli Headers

### Aggiungere headers personalizzati
```bash
curl -H "Authorization: Bearer token123" \
     -H "User-Agent: MiaApp/1.0" \
     https://httpbin.org/headers
```

**Output atteso:**
```json
{
  "headers": {
    "Accept": "*/*",
    "Authorization": "Bearer token123",
    "Host": "httpbin.org",
    "User-Agent": "MiaApp/1.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2a9-f4c0314d5e6f7890ab12345"
  }
}
```

### Headers comuni e utili
```bash
# Content-Type per JSON
curl -H "Content-Type: application/json" ...

# Autenticazione Basic
curl -H "Authorization: Basic dXNlcjpwYXNz" ...

# Accept per specificare il formato di risposta
curl -H "Accept: application/json" ...

# Custom headers
curl -H "X-API-Key: abc123" ...
```

## 5. Autenticazione

### Basic Authentication
```bash
curl -u username:password https://httpbin.org/basic-auth/username/password
```

**Output atteso (successo):**
```json
{
  "authenticated": true,
  "user": "username"
}
```

**Output con credenziali errate:**
```
HTTP/1.1 401 UNAUTHORIZED
www-authenticate: Basic realm="Fake Realm"
```

### Bearer Token
```bash
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
     https://httpbin.org/bearer
```

**Output atteso:**
```json
{
  "authenticated": true,
  "token": "eyJhbGciOiJIUzI1NiIs..."
}
```

### API Key
```bash
curl -H "X-API-Key: your-api-key-here" \
     https://httpbin.org/headers
```

**Output atteso:**
```json
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Api-Key": "your-api-key-here",
    "X-Amzn-Trace-Id": "Root=1-64f8b2aa-05d1425e6f7890ab123456"
  }
}
```

## 6. Gestione dei Cookies

### Salvare cookies
```bash
curl -c cookies.txt https://httpbin.org/cookies/set/session/abc123
```

**Output atteso:**
```json
{
  "cookies": {
    "session": "abc123"
  }
}
```

**Contenuto di cookies.txt:**
```
# Netscape HTTP Cookie File
# This is a generated file!  Do not edit.

httpbin.org	FALSE	/	FALSE	0	session	abc123
```

### Utilizzare cookies salvati
```bash
curl -b cookies.txt https://httpbin.org/cookies
```

**Output atteso:**
```json
{
  "cookies": {
    "session": "abc123"
  }
}
```

### Cookie inline
```bash
curl -b "session=abc123; theme=dark" https://httpbin.org/cookies
```

**Output atteso:**
```json
{
  "cookies": {
    "session": "abc123",
    "theme": "dark"
  }
}
```

## 7. Redirect e Response Codes

### Seguire i redirect
```bash
curl -L https://httpbin.org/redirect/3
```

**Output atteso:**
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2ab-16e2536f7890ab1234567"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get"
}
```

**Senza -L (mostra solo il primo redirect):**
```bash
curl https://httpbin.org/redirect/3
```

**Output atteso:**
```html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>Redirecting...</title>
<h1>Redirecting...</h1>
<p>You should be redirected automatically to target URL: <a href="/redirect/2">/redirect/2</a>.  If not click the link.
```

### Limitare i redirect
```bash
curl -L --max-redirs 5 https://httpbin.org/redirect/10
```

**Output atteso (errore dopo 5 redirect):**
```
curl: (47) Maximum (5) redirects followed
```

### Visualizzare solo il codice di stato
```bash
curl -o /dev/null -s -w "%{http_code}\n" https://httpbin.org/status/200
```

**Output atteso:**
```
200
```

```bash
curl -o /dev/null -s -w "%{http_code}\n" https://httpbin.org/status/404
```

**Output atteso:**
```
404
```

## 8. Timeout e Retry

### Impostare timeout
```bash
curl --connect-timeout 10 --max-time 30 https://httpbin.org/delay/5
```

**Output atteso (dopo 5 secondi):**
```json
{
  "args": {},
  "data": "",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2ac-27f3647890ab123456789"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/delay/5"
}
```

**Con timeout troppo breve:**
```bash
curl --max-time 3 https://httpbin.org/delay/5
```

**Output atteso:**
```
curl: (28) Operation timed out after 3001 milliseconds with 0 bytes received
```

### Retry automatico
```bash
curl --retry 3 --retry-delay 2 https://httpbin.org/status/500
```

**Output atteso (dopo 3 tentativi):**
```
Warning: Problem : HTTP error. Will retry in 2 seconds. 3 retries left.
Warning: Problem : HTTP error. Will retry in 2 seconds. 2 retries left.  
Warning: Problem : HTTP error. Will retry in 2 seconds. 1 retries left.
Warning: Problem : HTTP error. Will retry in 2 seconds. 0 retries left.
curl: (22) The requested URL returned error: 500 INTERNAL SERVER ERROR
```

## 9. Upload e Download di File

### Download con progress bar
```bash
curl -# -o file.zip https://httpbin.org/uuid
```

**Output atteso:**
```
######################################################################## 100.0%
```

**Contenuto di file.zip:**
```json
{
  "uuid": "f47ac10b-58cc-4372-a567-0e02b2c3d479"
}
```

### Upload multipart
```bash
curl -X POST \
  -F "file=@image.jpg" \
  -F "title=La mia foto" \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "",
  "files": {
    "file": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBD..."
  },
  "form": {
    "title": "La mia foto"
  },
  "headers": {
    "Accept": "*/*",
    "Content-Length": "2847",
    "Content-Type": "multipart/form-data; boundary=------------------------829374638472",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2ad-38047590ab123456789012"
  },
  "json": null,
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

### Upload raw data
```bash
curl -X POST \
  --data-binary @data.json \
  -H "Content-Type: application/json" \
  https://httpbin.org/post
```

**Output atteso (assumendo che data.json contenga `{"test": "data"}`):**
```json
{
  "args": {},
  "data": "{\"test\": \"data\"}",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "16",
    "Content-Type": "application/json",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2ae-490586ab1234567890123"
  },
  "json": {
    "test": "data"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

## 10. Debug e Troubleshooting

### Modalità verbose
```bash
curl -v https://httpbin.org/get
```

**Output atteso:**
```
* Trying 3.213.151.39:443...
* TCP_NODELAY set
* Connected to httpbin.org (3.213.151.39) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/certs/ca-certificates.crt
  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=httpbin.org
*  start date: Aug  2 00:00:00 2023 GMT
*  expire date: Aug 30 23:59:59 2024 GMT
*  subjectAltName: host "httpbin.org" matched cert's "httpbin.org"
*  issuer: C=US; O=Amazon; OU=Server CA 1B; CN=Amazon
*  SSL certificate verify ok.
* Using HTTP2, server supports multi-use
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x55f8b2c3d2a0)
> GET /get HTTP/2
> Host: httpbin.org
> user-agent: curl/7.68.0
> accept: */*
> 
* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!
< HTTP/2 200 
< date: Thu, 07 Sep 2023 14:45:30 GMT
< content-type: application/json
< content-length: 347
< server: gunicorn/19.9.0
< access-control-allow-origin: *
< access-control-allow-credentials: true
< 
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2af-5a169bcd234567890123456"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get"
}
* Connection #0 to host httpbin.org left intact
```

### Trace completo
```bash
curl --trace-ascii trace.txt https://httpbin.org/get
cat trace.txt
```

**Output atteso in trace.txt:**
```
== Info: Trying 3.213.151.39:443...
== Info: TCP_NODELAY set
== Info: Connected to httpbin.org (3.213.151.39) port 443 (#0)
== Info: ALPN, offering h2
== Info: ALPN, offering http/1.1
=> Send header
0000: GET /get HTTP/2
0010: Host: httpbin.org
0025: User-Agent: curl/7.68.0
003e: Accept: */*
004b: 
== Info: TLSv1.3 (IN), TLS handshake, Server hello (2):
<= Recv header
0000: HTTP/2 200 
000c: date: Thu, 07 Sep 2023 14:46:15 GMT
0030: content-type: application/json
0051: content-length: 347
=> Recv data
0000: {."args": {},.  "headers": {.    "Accept": "*/*",.    "Host": "h
0040: ttpbin.org",.    "User-Agent": "curl/7.68.0",.    "X-Amzn-Trac
0080: e-Id": "Root=1-64f8b2b0-6b27acde345678901234567".  },.  "origi
00c0: n": "203.0.113.42",.  "url": "https://httpbin.org/get".}
== Info: Connection #0 to host httpbin.org left intact
```

### Misurare le performance
```bash
curl -w "@curl-format.txt" -o /dev/null -s https://httpbin.org/get
```

**File curl-format.txt:**
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

**Output atteso:**
```
     time_namelookup:  0.004
        time_connect:  0.028
     time_appconnect:  0.156
    time_pretransfer:  0.156
       time_redirect:  0.000
  time_starttransfer:  0.284
                     ----------
          time_total:  0.285
```

## 11. Esempi di API Testing

### Test di un'API REST completa

**1. Ottenere lista utenti:**
```bash
curl -H "Accept: application/json" \
     https://jsonplaceholder.typicode.com/users
```

**Output atteso (parziale):**
```json
[
  {
    "id": 1,
    "name": "Leanne Graham",
    "username": "Bret",
    "email": "Sincere@april.biz",
    "address": {
      "street": "Kulas Light",
      "suite": "Apt. 556",
      "city": "Gwenborough",
      "zipcode": "92998-3874",
      "geo": {
        "lat": "-37.3159",
        "lng": "81.1496"
      }
    },
    "phone": "1-770-736-8031 x56442",
    "website": "hildegard.org",
    "company": {
      "name": "Romaguera-Crona",
      "catchPhrase": "Multi-layered client-server neural-net",
      "bs": "harness real-time e-markets"
    }
  },
  // ... altri 9 utenti
]
```

**2. Creare un nuovo post:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Il mio post",
    "body": "Contenuto del post",
    "userId": 1
  }' \
  https://jsonplaceholder.typicode.com/posts
```

**Output atteso:**
```json
{
  "id": 101,
  "title": "Il mio post",
  "body": "Contenuto del post",
  "userId": 1
}
```

**3. Aggiornare un post:**
```bash
curl -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "id": 1,
    "title": "Post aggiornato",
    "body": "Contenuto modificato",
    "userId": 1
  }' \
  https://jsonplaceholder.typicode.com/posts/1
```

**Output atteso:**
```json
{
  "id": 1,
  "title": "Post aggiornato",
  "body": "Contenuto modificato",
  "userId": 1
}
```

**4. Eliminare un post:**
```bash
curl -X DELETE \
     https://jsonplaceholder.typicode.com/posts/1
```

**Output atteso:**
```json
{}
```

## 12. Script Avanzati

### Script per test automatizzato di API
```bash
#!/bin/bash

API_BASE="https://jsonplaceholder.typicode.com"
TOKEN="your-token-here"

# Test GET
echo "Testing GET /posts"
response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$API_BASE/posts/1")
http_code="${response: -3}"
body="${response%???}"

if [ "$http_code" -eq 200 ]; then
    echo "✅ GET test passed"
else
    echo "❌ GET test failed (HTTP $http_code)"
fi

# Test POST
echo "Testing POST /posts"
response=$(curl -s -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"title":"Test","body":"Test body","userId":1}' \
    "$API_BASE/posts")

http_code="${response: -3}"
if [ "$http_code" -eq 201 ]; then
    echo "✅ POST test passed"
else
    echo "❌ POST test failed (HTTP $http_code)"
fi
```

**Output atteso dello script:**
```
Testing GET /posts
✅ GET test passed
Testing POST /posts
✅ POST test passed
```

## 13. Best Practices e Tips

### 1. Sicurezza
- Non includere mai credenziali direttamente nei comandi
- Usa variabili d'ambiente per API keys:
```bash
export API_KEY="your-secret-key"
curl -H "X-API-Key: $API_KEY" https://httpbin.org/headers
```

**Output atteso:**
```json
{
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Api-Key": "your-secret-key",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b1-7c38deab456789012345678"
  }
}
```

### 2. Output e Logging
```bash
# Salvare sia output che errori
curl https://httpbin.org/get 2>&1 | tee request.log
```

**Output atteso (sia a schermo che nel file request.log):**
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b2-8d49efbc567890123456789"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/get"
}
```

```bash
# Solo salvare il body della risposta
curl -s https://httpbin.org/get > response.json
cat response.json
```

**Output atteso in response.json:**
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b3-9e5af0cd678901234567890"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/
}
```

### 3. Configurazione globale
Crea un file `~/.curlrc`:
```
# Seguire sempre i redirect
-L

# Mostrare progress bar
-#

# Timeout di 30 secondi
--max-time 30

# User agent personalizzato
user-agent = "MyApp/1.0"
```

**Test della configurazione:**
```bash
curl https://httpbin.org/user-agent
```

**Output atteso (con .curlrc configurato):**
```json
{
  "user-agent": "MyApp/1.0"
}
```

## 14. Esercizi Pratici

### Esercizio 1: API Weather
Usa l'API di OpenWeatherMap per ottenere il meteo:
```bash
# Registrati su openweathermap.org e ottieni una API key
curl "https://api.openweathermap.org/data/2.5/weather?q=Milano&appid=YOUR_API_KEY&units=metric"
```

**Output atteso:**
```json
{
  "coord": {
    "lon": 9.1895,
    "lat": 45.4643
  },
  "weather": [
    {
      "id": 800,
      "main": "Clear",
      "description": "clear sky",
      "icon": "01d"
    }
  ],
  "base": "stations",
  "main": {
    "temp": 23.45,
    "feels_like": 23.12,
    "temp_min": 21.87,
    "temp_max": 25.21,
    "pressure": 1013,
    "humidity": 58
  },
  "visibility": 10000,
  "wind": {
    "speed": 2.57,
    "deg": 340
  },
  "clouds": {
    "all": 0
  },
  "dt": 1694095830,
  "sys": {
    "type": 2,
    "id": 2012644,
    "country": "IT",
    "sunrise": 1694061726,
    "sunset": 1694109584
  },
  "timezone": 7200,
  "id": 3173435,
  "name": "Milano",
  "cod": 200
}
```

**Con API key non valida:**
```json
{
  "cod": 401,
  "message": "Invalid API key. Please see http://openweathermap.org/faq#error401 for more info."
}
```

### Esercizio 2: Test di Autenticazione
1. **Richiesta senza autenticazione:**
```bash
curl https://httpbin.org/basic-auth/user/pass
```

**Output atteso:**
```
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>401 Unauthorized</title>
<h1>Unauthorized</h1>
<p>The server could not verify that you are authorized to access the URL requested.</p>
```

2. **Osserva l'errore 401:**
```bash
curl -i https://httpbin.org/basic-auth/user/pass
```

**Output atteso:**
```
HTTP/2 401 
date: Thu, 07 Sep 2023 15:20:45 GMT
content-type: text/html; charset=utf-8
content-length: 188
server: gunicorn/19.9.0
www-authenticate: Basic realm="Fake Realm"
access-control-allow-origin: *
access-control-allow-credentials: true

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<title>401 Unauthorized</title>
<h1>Unauthorized</h1>
<p>The server could not verify that you are authorized to access the URL requested.</p>
```

3. **Ripeti con credenziali corrette:**
```bash
curl -u user:pass https://httpbin.org/basic-auth/user/pass
```

**Output atteso:**
```json
{
  "authenticated": true,
  "user": "user"
}
```

### Esercizio 3: Upload di File
1. **Crea un file di test:**
```bash
echo "Questo è un file di test" > test.txt
```

2. **Caricalo usando curl:**
```bash
curl -X POST \
  -F "file=@test.txt" \
  -F "name=test-upload" \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "",
  "files": {
    "file": "Questo è un file di test\n"
  },
  "form": {
    "name": "test-upload"
  },
  "headers": {
    "Accept": "*/*",
    "Content-Length": "246",
    "Content-Type": "multipart/form-data; boundary=------------------------b8c9d0e1f2a3b4c5",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b4-af61b2cd890123456789012"
  },
  "json": null,
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

3. **Verifica la risposta del server:**
```bash
curl -X POST \
  -F "file=@test.txt" \
  -F "name=test-upload" \
  -w "Status: %{http_code}\nSize: %{size_upload} bytes\nTime: %{time_total}s\n" \
  https://httpbin.org/post > /dev/null
```

**Output atteso:**
```
Status: 200
Size: 246 bytes
Time: 0.485s
```

## 15. Casi d'Uso Avanzati

### Testing di Rate Limiting
```bash
# Test rapido di più richieste
for i in {1..5}; do
  echo "Request $i:"
  curl -w "Status: %{http_code} - Time: %{time_total}s\n" \
       -o /dev/null -s \
       https://httpbin.org/delay/1
done
```

**Output atteso:**
```
Request 1:
Status: 200 - Time: 1.234s
Request 2:
Status: 200 - Time: 1.187s
Request 3:
Status: 200 - Time: 1.201s
Request 4:
Status: 200 - Time: 1.156s
Request 5:
Status: 200 - Time: 1.243s
```

### Testing di Content Negotiation
```bash
# Richiedi JSON
curl -H "Accept: application/json" https://httpbin.org/json
```

**Output atteso:**
```json
{
  "slideshow": {
    "author": "Yours Truly",
    "date": "date of publication",
    "slides": [
      {
        "title": "Wake up to WonderWidgets!",
        "type": "all"
      },
      {
        "items": [
          "Why <em>WonderWidgets</em> are great",
          "Who <em>buys</em> WonderWidgets"
        ],
        "title": "Overview",
        "type": "all"
      }
    ],
    "title": "Sample Slide Show"
  }
}
```

```bash
# Richiedi XML
curl -H "Accept: application/xml" https://httpbin.org/xml
```

**Output atteso:**
```xml
<?xml version='1.0' encoding='us-ascii'?>
<slideshow 
    title="Sample Slide Show"
    date="Date of publication"
    author="Yours Truly"
    >
    <slide type="all">
      <title>Wake up to WonderWidgets!</title>
    </slide>
    <slide type="all">
        <title>Overview</title>
        <item>Why <em>WonderWidgets</em> are great</item>
        <item>Who <em>buys</em> WonderWidgets</item>
    </slide>
</slideshow>
```

### Testing di Compressione
```bash
# Richiedi compressione gzip
curl -H "Accept-Encoding: gzip" --compressed -v https://httpbin.org/gzip
```

**Output atteso (parte verbose):**
```
< HTTP/2 200 
< date: Thu, 07 Sep 2023 15:35:20 GMT
< content-type: application/json
< content-encoding: gzip
< server: gunicorn/19.9.0
```

**Corpo della risposta (decompressa automaticamente da --compressed):**
```json
{
  "gzipped": true,
  "headers": {
    "Accept": "*/*",
    "Accept-Encoding": "gzip",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b5-c072d3e4901234567890123"
  },
  "method": "GET",
  "origin": "203.0.113.42"
}
```

### Testing di CORS
```bash
# Preflight OPTIONS request
curl -X OPTIONS \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v \
  https://httpbin.org/post
```

**Output atteso (headers rilevanti):**
```
< HTTP/2 200 
< access-control-allow-origin: *
< access-control-allow-methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
< access-control-allow-headers: *
< access-control-max-age: 3600
```

## 16. Troubleshooting Comune

### Errori SSL/TLS
```bash
# Ignorare errori certificato (NON in produzione!)
curl -k https://self-signed.badssl.com/
```

**Output atteso:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>self-signed.badssl.com</title>
</head>
<body>
  <h1>self-signed.badssl.com</h1>
  <p>This domain has a self-signed certificate.</p>
</body>
</html>
```

**Senza -k (errore):**
```bash
curl https://self-signed.badssl.com/
```

**Output atteso:**
```
curl: (60) SSL certificate problem: self signed certificate
More details here: https://curl.haxx.se/docs/sslcerts.html
```

### Problemi di Encoding
```bash
# Test con caratteri speciali
curl -X POST \
  -H "Content-Type: application/json; charset=utf-8" \
  -d '{"messaggio": "Ciao, come stai? È tutto à posto!"}' \
  https://httpbin.org/post
```

**Output atteso:**
```json
{
  "args": {},
  "data": "{\"messaggio\": \"Ciao, come stai? È tutto à posto!\"}",
  "files": {},
  "form": {},
  "headers": {
    "Accept": "*/*",
    "Content-Length": "53",
    "Content-Type": "application/json; charset=utf-8",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.68.0",
    "X-Amzn-Trace-Id": "Root=1-64f8b2b6-d183e4f5a0123456789012"
  },
  "json": {
    "messaggio": "Ciao, come stai? È tutto à posto!"
  },
  "origin": "203.0.113.42",
  "url": "https://httpbin.org/post"
}
```

### Test di Connettività
```bash
# Test solo connessione (senza transfer)
curl --connect-timeout 5 -I --max-time 10 https://httpbin.org/delay/2
```

**Output atteso:**
```
HTTP/2 200 
date: Thu, 07 Sep 2023 15:45:12 GMT
content-type: application/json
content-length: 378
server: gunicorn/19.9.0
access-control-allow-origin: *
access-control-allow-credentials: true
```

## 17. Domande di Autovalutazione

**1. Quale opzione di curl permette di seguire automaticamente i redirect?**
a) `-r`
b) `-L` 
c) `--redirect`
d) `-f`

**2. Come si invia un JSON con curl?**
a) `-d '{"key":"value"}' -H "Content-Type: application/json"`
b) `--json '{"key":"value"}'`
c) `-j '{"key":"value"}'`
d) `--data-json '{"key":"value"}'`

**3. Quale opzione mostra gli headers della risposta insieme al body?**
a) `-h`
b) `-I`
c) `-i`
d) `--headers`

**4. Come si imposta un timeout di connessione di 10 secondi?**
a) `--timeout 10`
b) `--connect-timeout 10`
c) `-t 10`
d) `--wait 10`

**5. Qual è il metodo HTTP per eliminare una risorsa?**
a) REMOVE
b) DELETE
c) DROP
d) DESTROY

**6. Quale comando curl salva i cookies in un file?**
a) `-c cookies.txt`
b) `-b cookies.txt`
c) `--save-cookies cookies.txt`
d) `-s cookies.txt`

**7. Come si visualizza solo il codice di stato HTTP di una risposta?**
a) `curl --status-only URL`
b) `curl -I URL | grep HTTP`
c) `curl -o /dev/null -s -w "%{http_code}" URL`
d) `curl --code URL`

**8. Qual è l'header corretto per l'autenticazione Bearer Token?**
a) `Authorization: Token abc123`
b) `Authorization: Bearer abc123`
c) `Auth: Bearer abc123`
d) `Token: abc123`

**9. Come si carica un file con curl usando multipart/form-data?**
a) `-F "file=@filename"`
b) `-d @filename`
c) `--upload filename`
d) `-u filename`

**10. Quale opzione abilita la modalità verbose per il debugging?**
a) `-d`
b) `-v`
c) `--debug`
d) `-V`

## 18. Esercizi Pratici Aggiuntivi

### Esercizio 4: API GitHub (usando token personale)
```bash
# Ottenere informazioni utente
curl -H "Authorization: token YOUR_GITHUB_TOKEN" \
     https://api.github.com/user
```

**Output atteso (esempio):**
```json
{
  "login": "octocat",
  "id": 1,
  "node_id": "MDQ6VXNlcjE=",
  "avatar_url": "https://github.com/images/error/octocat_happy.gif",
  "gravatar_id": "",
  "url": "https://api.github.com/users/octocat",
  "html_url": "https://github.com/octocat",
  "type": "User",
  "site_admin": false,
  "name": "monalisa octocat",
  "company": "GitHub",
  "location": "San Francisco",
  "email": "octocat@github.com",
  "public_repos": 2,
  "public_gists": 1,
  "followers": 20,
  "following": 0,
  "created_at": "2008-01-14T04:33:35Z",
  "updated_at": "2008-01-14T04:33:35Z"
}
```

### Esercizio 5: Test di Performance
```bash
# Script per testare tempi di risposta
#!/bin/bash
for i in {1..10}; do
    time=$(curl -o /dev/null -s -w "%{time_total}" https://httpbin.org/delay/1)
    echo "Request $i: ${time}s"
done
```

**Output atteso:**
```
Request 1: 1.234s
Request 2: 1.187s
Request 3: 1.201s
Request 4: 1.156s
Request 5: 1.243s
Request 6: 1.189s
Request 7: 1.198s
Request 8: 1.167s
Request 9: 1.234s
Request 10: 1.201s
```

## 19. Risposte alle Domande di Autovalutazione

1. **b) `-L`** - L'opzione `-L` (o `--location`) dice a curl di seguire automaticamente i redirect HTTP.

2. **a) `-d '{"key":"value"}' -H "Content-Type: application/json"`** - È necessario sia specificare i dati con `-d` sia impostare l'header Content-Type appropriato.

3. **c) `-i`** - L'opzione `-i` include gli headers della risposta nel output insieme al body. `-I` mostra solo gli headers.

4. **b) `--connect-timeout 10`** - Questa opzione imposta specificamente il timeout per la fase di connessione.

5. **b) DELETE** - DELETE è il metodo HTTP standard per eliminare risorse secondo le specifiche REST.

6. **a) `-c cookies.txt`** - L'opzione `-c` salva i cookies ricevuti nel file specificato. `-b` li legge da un file esistente.

7. **c) `curl -o /dev/null -s -w "%{http_code}" URL`** - Questa combinazione scarta il body (`-o /dev/null`), elimina il progress (`-s`) e mostra solo il codice HTTP con `-w`.

8. **b) `Authorization: Bearer abc123`** - Il formato standard per Bearer Token è "Bearer" seguito da uno spazio e dal token.

9. **a) `-F "file=@filename"`** - L'opzione `-F` crea automaticamente una richiesta multipart/form-data, `@` indica un file.

10. **b) `-v`** - L'opzione `-v` (verbose) mostra dettagli della comunicazione HTTP per debugging.

---

## 20. Progetti di Approfondimento

### Progetto 1: Monitoraggio API
Crea uno script che testa periodicamente un'API e logga i risultati:

```bash
#!/bin/bash
LOG_FILE="api_monitor.log"
API_URL="https://httpbin.org/status/200"

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    response=$(curl -s -w "%{http_code}:%{time_total}" -o /dev/null "$API_URL")
    status_code=${response%:*}
    response_time=${response#*:}
    
    echo "$timestamp - Status: $status_code - Time: ${response_time}s" >> "$LOG_FILE"
    echo "$timestamp - Status: $status_code - Time: ${response_time}s"
    
    sleep 60  # Test ogni minuto
done
```

**Output atteso nel log:**
```
2023-09-07 16:00:01 - Status: 200 - Time: 0.234s
2023-09-07 16:01:01 - Status: 200 - Time: 0.187s
2023-09-07 16:02:01 - Status: 200 - Time: 0.201s
```

### Progetto 2: Test Suite Automatizzata
```bash
#!/bin/bash
# Test suite per API REST

BASE_URL="https://jsonplaceholder.typicode.com"
PASS=0
FAIL=0

test_get() {
    echo "Testing GET /posts/1"
    response=$(curl -s -w "%{http_code}" "$BASE_URL/posts/1")
    status=${response: -3}
    
    if [ "$status" -eq 200 ]; then
        echo "✅ GET test passed"
        ((PASS++))
    else
        echo "❌ GET test failed (HTTP $status)"
        ((FAIL++))
    fi
}

test_post() {
    echo "Testing POST /posts"
    response=$(curl -s -w "%{http_code}" -X POST \
        -H "Content-Type: application/json" \
        -d '{"title":"Test","body":"Test body","userId":1}' \
        "$BASE_URL/posts")
    status=${response: -3}
    
    if [ "$status" -eq 201 ]; then
        echo "✅ POST test passed"
        ((PASS++))
    else
        echo "❌ POST test failed (HTTP $status)"
        ((FAIL++))
    fi
}

# Esegui tutti i test
test_get
test_post

echo ""
echo "=== RISULTATI ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Total: $((PASS + FAIL))"
```

**Output atteso:**
```
Testing GET /posts/1
✅ GET test passed
Testing POST /posts
✅ POST test passed

=== RISULTATI ===
Passed: 2
Failed: 0
Total: 2
```

Questa guida ti fornisce una base solida e completa per utilizzare curl efficacemente nel testing e nella comprensione del protocollo HTTP. Ogni esempio include sia il comando che l'output atteso, permettendoti di verificare immediatamente il comportamento e apprendere attraverso la pratica diretta.