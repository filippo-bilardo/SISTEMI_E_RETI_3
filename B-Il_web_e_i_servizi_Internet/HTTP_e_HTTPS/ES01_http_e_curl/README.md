# Esercitazione: HTTP e curl

## 📚 Obiettivi dell'Esercitazione

In questa esercitazione imparerai a:
- Utilizzare `curl` per effettuare richieste HTTP
- Analizzare header HTTP di richiesta e risposta
- Comprendere i metodi HTTP (GET, POST, PUT, DELETE)
- Gestire autenticazione e cookies
- Debuggare comunicazioni HTTP

## 🛠️ Prerequisiti

### Installazione curl

```bash
# Ubuntu/Debian
sudo apt-get install curl

# macOS
brew install curl

# Verifica installazione
curl --version
```

---

## 📝 Parte 1: Richieste GET Base

### Esercizio 1.1 - Prima richiesta GET

**Obiettivo:** Effettuare una semplice richiesta GET e visualizzare la risposta.

```bash
curl https://httpbin.org/get
```

**Domande:**
1. Cosa restituisce il server?
2. Quali informazioni vedi nella risposta JSON?

---

### Esercizio 1.2 - Visualizzare gli header di risposta

**Obiettivo:** Vedere gli header HTTP della risposta.

```bash
# Mostra solo gli header (-I o --head)
curl -I https://httpbin.org/get

# Mostra header E corpo della risposta (-i)
curl -i https://httpbin.org/get
```

**Domande:**
1. Qual è il codice di stato HTTP?
2. Quale header indica il tipo di contenuto?
3. Trova l'header `Content-Length`. Cosa indica?
4. C'è un header che indica la data/ora della risposta?

---

### Esercizio 1.3 - Verbose mode per debugging

**Obiettivo:** Vedere tutti i dettagli della comunicazione HTTP.

```bash
# Modalità verbose (-v)
curl -v https://httpbin.org/get
```

**Domande:**
1. Quali header vengono inviati dal client?
2. Quale versione HTTP viene utilizzata?
3. Cosa indica il simbolo `>` e cosa indica `<`?

**Sfida:** Salva l'output verbose in un file chiamato `debug.txt`:
```bash
curl -v https://httpbin.org/get > debug.txt 2>&1
```

---

### Esercizio 1.4 - Query parameters

**Obiettivo:** Inviare parametri nella URL (query string).

```bash
# Singolo parametro
curl "https://httpbin.org/get?name=Mario"

# Multipli parametri
curl "https://httpbin.org/get?name=Mario&age=25&city=Roma"
```

**Domande:**
1. Dove vedi i parametri nella risposta JSON?
2. Come vengono codificati i caratteri speciali nella URL?

**Sfida:** Invia una richiesta con parametri che contengono spazi:
```bash
curl "https://httpbin.org/get?name=Mario%20Rossi&city=Roma"
```

---

## 📝 Parte 2: Custom Headers

### Esercizio 2.1 - Aggiungere header personalizzati

**Obiettivo:** Inviare header HTTP personalizzati.

```bash
# Singolo header (-H)
curl -H "X-Custom-Header: MioValore" https://httpbin.org/headers

# Multipli header
curl -H "X-Nome: Mario" \
     -H "X-Cognome: Rossi" \
     -H "X-Eta: 25" \
     https://httpbin.org/headers
```

**Domande:**
1. Dove appaiono gli header personalizzati nella risposta?
2. Gli header sono case-sensitive?

---

### Esercizio 2.2 - User-Agent

**Obiettivo:** Modificare l'header User-Agent.

```bash
# User-Agent di default
curl https://httpbin.org/user-agent

# User-Agent personalizzato
curl -H "User-Agent: MioBrowser/1.0" https://httpbin.org/user-agent

# User-Agent abbreviato (-A)
curl -A "Firefox/100.0" https://httpbin.org/user-agent
```

**Domande:**
1. Qual è lo User-Agent di default di curl?
2. Perché un server potrebbe controllare lo User-Agent?

---

### Esercizio 2.3 - Accept header

**Obiettivo:** Specificare il tipo di contenuto desiderato.

```bash
# Richiedi JSON
curl -H "Accept: application/json" https://httpbin.org/get

# Richiedi XML (httpbin restituisce comunque JSON)
curl -H "Accept: application/xml" https://httpbin.org/get

# Richiedi HTML
curl -H "Accept: text/html" https://httpbin.org/html
```

**Domande:**
1. Cosa indica l'header `Accept`?
2. Il server è obbligato a rispettare l'header Accept?

---

## 📝 Parte 3: Metodi HTTP POST

### Esercizio 3.1 - POST con dati form-urlencoded

**Obiettivo:** Inviare dati con il metodo POST (formato form).

```bash
# POST con dati form (-d)
curl -X POST https://httpbin.org/post \
     -d "name=Mario" \
     -d "age=25"

# POST con dati inline
curl -X POST https://httpbin.org/post \
     -d "name=Mario&age=25&city=Roma"
```

**Domande:**
1. Quale `Content-Type` viene impostato automaticamente?
2. Dove appaiono i dati inviati nella risposta?

---

### Esercizio 3.2 - POST con JSON

**Obiettivo:** Inviare dati in formato JSON.

```bash
# POST JSON
curl -X POST https://httpbin.org/post \
     -H "Content-Type: application/json" \
     -d '{"name":"Mario","age":25,"city":"Roma"}'

# POST JSON da file
echo '{"name":"Luigi","age":30}' > user.json
curl -X POST https://httpbin.org/post \
     -H "Content-Type: application/json" \
     -d @user.json
```

**Domande:**
1. Perché è necessario specificare `Content-Type: application/json`?
2. Come si invia il contenuto di un file con curl?

---

### Esercizio 3.3 - POST multipart (file upload)

**Obiettivo:** Simulare l'upload di un file.

```bash
# Crea un file di test
echo "Contenuto del file di test" > test.txt

# Upload file
curl -X POST https://httpbin.org/post \
     -F "file=@test.txt" \
     -F "description=File di test"

# Upload multipli file
curl -X POST https://httpbin.org/post \
     -F "file1=@test.txt" \
     -F "file2=@user.json"
```

**Domande:**
1. Quale Content-Type viene usato per l'upload?
2. Cosa indica il simbolo `@` prima del nome del file?

**Sfida:** Crea un'immagine fittizia e caricala:
```bash
echo "fake image data" > image.jpg
curl -X POST https://httpbin.org/post \
     -F "image=@image.jpg" \
     -F "title=La mia immagine"
```

---

## 📝 Parte 4: Altri Metodi HTTP

### Esercizio 4.1 - PUT request

**Obiettivo:** Utilizzare il metodo PUT per aggiornare una risorsa.

```bash
# PUT con JSON
curl -X PUT https://httpbin.org/put \
     -H "Content-Type: application/json" \
     -d '{"id":1,"name":"Mario Aggiornato"}'
```

**Domande:**
1. Qual è la differenza tra POST e PUT?
2. PUT è idempotente?

---

### Esercizio 4.2 - DELETE request

**Obiettivo:** Utilizzare il metodo DELETE.

```bash
# DELETE semplice
curl -X DELETE https://httpbin.org/delete

# DELETE con parametri
curl -X DELETE "https://httpbin.org/delete?id=123"
```

**Domande:**
1. DELETE può avere un body?
2. Quando si usa DELETE invece di POST?

---

### Esercizio 4.3 - PATCH request

**Obiettivo:** Utilizzare PATCH per aggiornamenti parziali.

```bash
# PATCH
curl -X PATCH https://httpbin.org/patch \
     -H "Content-Type: application/json" \
     -d '{"age":26}'
```

**Domande:**
1. Differenza tra PATCH e PUT?
2. Quando preferire PATCH a PUT?

---

## 📝 Parte 5: Autenticazione

### Esercizio 5.1 - Basic Authentication

**Obiettivo:** Utilizzare autenticazione HTTP Basic.

```bash
# Basic auth (-u user:password)
curl -u mario:secret123 https://httpbin.org/basic-auth/mario/secret123

# Credenziali errate
curl -u mario:wrong https://httpbin.org/basic-auth/mario/secret123
```

**Domande:**
1. Quale codice di stato ritorna se le credenziali sono errate?
2. Come vengono codificate le credenziali in Basic Auth?

**Sfida:** Visualizza l'header Authorization in verbose mode:
```bash
curl -v -u mario:secret123 https://httpbin.org/basic-auth/mario/secret123
```

---

### Esercizio 5.2 - Bearer Token Authentication

**Obiettivo:** Utilizzare token di autenticazione.

```bash
# Bearer token
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" \
     https://httpbin.org/bearer

# Token invalido
curl -H "Authorization: Bearer invalid_token" \
     https://httpbin.org/bearer
```

**Domande:**
1. Cosa rappresenta un Bearer token?
2. Differenza tra Basic Auth e Bearer Token?

---

## 📝 Parte 6: Cookies

### Esercizio 6.1 - Gestione cookies

**Obiettivo:** Salvare e inviare cookies.

```bash
# Imposta un cookie
curl -c cookies.txt https://httpbin.org/cookies/set?session=abc123

# Visualizza il file cookies
cat cookies.txt

# Usa i cookies salvati
curl -b cookies.txt https://httpbin.org/cookies

# Imposta e usa cookie in una richiesta
curl -b "session=xyz789" https://httpbin.org/cookies
```

**Domande:**
1. Cosa contiene il file cookies.txt?
2. Differenza tra `-c` (cookie jar) e `-b` (cookie)?

---

### Esercizio 6.2 - Seguire redirect con cookies

**Obiettivo:** Gestire redirect mantenendo i cookies.

```bash
# Senza seguire redirect
curl https://httpbin.org/redirect/3

# Segui redirect (-L)
curl -L https://httpbin.org/redirect/3

# Segui redirect con cookies
curl -L -c cookies.txt -b cookies.txt https://httpbin.org/cookies/set?test=value
```

**Domande:**
1. Cosa fa l'opzione `-L`?
2. Quanti redirect seguirà curl di default?

---

## 📝 Parte 7: Timeout e Retry

### Esercizio 7.1 - Timeout

**Obiettivo:** Impostare timeout per le richieste.

```bash
# Timeout connessione (5 secondi)
curl --connect-timeout 5 https://httpbin.org/delay/2

# Timeout risposta massimo (3 secondi - fallirà)
curl --max-time 3 https://httpbin.org/delay/5

# Timeout risposta (successo)
curl --max-time 10 https://httpbin.org/delay/2
```

**Domande:**
1. Differenza tra `--connect-timeout` e `--max-time`?
2. Cosa succede se il timeout scade?

---

### Esercizio 7.2 - Retry automatico

**Obiettivo:** Configurare retry automatici.

```bash
# Retry 3 volte se fallisce
curl --retry 3 https://httpbin.org/status/500

# Retry con delay tra tentativi
curl --retry 3 --retry-delay 2 https://httpbin.org/status/500
```

**Domande:**
1. Quando è utile il retry automatico?
2. Quali codici di stato triggerano un retry?

---

## 📝 Parte 8: Download e Upload

### Esercizio 8.1 - Download file

**Obiettivo:** Scaricare file da internet.

```bash
# Download con nome automatico (-O)
curl -O https://httpbin.org/image/png

# Download con nome personalizzato (-o)
curl -o myimage.png https://httpbin.org/image/png

# Download con progress bar
curl -# -O https://httpbin.org/image/png

# Continua download interrotto (-C -)
curl -C - -O https://httpbin.org/image/png
```

**Domande:**
1. Differenza tra `-O` e `-o`?
2. Come funziona il resume di download?

---

### Esercizio 8.2 - Download multipli

**Obiettivo:** Scaricare più file in una volta.

```bash
# Download multipli
curl -O https://httpbin.org/image/png \
     -O https://httpbin.org/image/jpeg \
     -O https://httpbin.org/image/webp
```

**Sfida:** Scarica 3 diversi formati di immagine e verifica con `file`:
```bash
curl -o img1.png https://httpbin.org/image/png
curl -o img2.jpg https://httpbin.org/image/jpeg
curl -o img3.webp https://httpbin.org/image/webp
file img*
```

---

## 📝 Parte 9: HTTP/2 e HTTP/3

### Esercizio 9.1 - HTTP/2

**Obiettivo:** Utilizzare HTTP/2.

```bash
# Forza HTTP/2
curl --http2 -I https://www.google.com

# Verbose con HTTP/2
curl --http2 -v https://www.google.com
```

**Domande:**
1. Quali vantaggi offre HTTP/2?
2. Tutti i server supportano HTTP/2?

---

### Esercizio 9.2 - Confronto HTTP/1.1 vs HTTP/2

**Obiettivo:** Confrontare performance.

```bash
# HTTP/1.1
time curl --http1.1 -I https://www.google.com

# HTTP/2
time curl --http2 -I https://www.google.com
```

**Domande:**
1. Quale è più veloce?
2. Perché HTTP/2 può essere più performante?

---

## 📝 Parte 10: API REST Complete

### Esercizio 10.1 - CRUD Operations

**Obiettivo:** Simulare operazioni CRUD complete su una API.

Utilizzeremo l'API pubblica JSONPlaceholder: https://jsonplaceholder.typicode.com

```bash
# CREATE - Crea nuovo post
curl -X POST https://jsonplaceholder.typicode.com/posts \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Mio Post",
       "body": "Contenuto del post",
       "userId": 1
     }'

# READ - Leggi tutti i post
curl https://jsonplaceholder.typicode.com/posts

# READ - Leggi un post specifico
curl https://jsonplaceholder.typicode.com/posts/1

# UPDATE - Aggiorna post (PUT completo)
curl -X PUT https://jsonplaceholder.typicode.com/posts/1 \
     -H "Content-Type: application/json" \
     -d '{
       "id": 1,
       "title": "Post Aggiornato",
       "body": "Contenuto aggiornato",
       "userId": 1
     }'

# UPDATE - Aggiorna parziale (PATCH)
curl -X PATCH https://jsonplaceholder.typicode.com/posts/1 \
     -H "Content-Type: application/json" \
     -d '{
       "title": "Solo titolo aggiornato"
     }'

# DELETE - Elimina post
curl -X DELETE https://jsonplaceholder.typicode.com/posts/1
```

**Domande:**
1. Quali codici di stato ricevi per ogni operazione?
2. Cosa restituisce la DELETE?

---

### Esercizio 10.2 - Filtri e Paginazione

**Obiettivo:** Utilizzare query parameters per filtrare e paginare.

```bash
# Filtra per userId
curl "https://jsonplaceholder.typicode.com/posts?userId=1"

# Limita risultati
curl "https://jsonplaceholder.typicode.com/posts?_limit=5"

# Paginazione
curl "https://jsonplaceholder.typicode.com/posts?_page=2&_limit=10"

# Ordinamento
curl "https://jsonplaceholder.typicode.com/posts?_sort=title&_order=desc"

# Filtri multipli
curl "https://jsonplaceholder.typicode.com/posts?userId=1&_limit=3"
```

**Sfida:** Combina più filtri per ottenere:
- Post dell'utente 2
- Ordinati per titolo
- Massimo 5 risultati

---

## 📝 Parte 11: Debugging Avanzato

### Esercizio 11.1 - Trace completo

**Obiettivo:** Analizzare completamente una richiesta HTTP.

```bash
# Trace ASCII
curl --trace trace.txt https://httpbin.org/get

# Trace ASCII human-readable
curl --trace-ascii trace-ascii.txt https://httpbin.org/get

# Visualizza il trace
cat trace-ascii.txt
```

**Domande:**
1. Cosa contiene il file trace?
2. Differenza tra `--trace` e `--trace-ascii`?

---

### Esercizio 11.2 - Timing dettagliato

**Obiettivo:** Misurare performance dettagliate.

Crea un file `curl-format.txt`:
```
     time_namelookup:  %{time_namelookup}s\n
        time_connect:  %{time_connect}s\n
     time_appconnect:  %{time_appconnect}s\n
    time_pretransfer:  %{time_pretransfer}s\n
       time_redirect:  %{time_redirect}s\n
  time_starttransfer:  %{time_starttransfer}s\n
                     ----------\n
          time_total:  %{time_total}s\n
```

Usa il formato:
```bash
curl -w "@curl-format.txt" -o /dev/null -s https://www.google.com
```

**Domande:**
1. Quale fase impiega più tempo?
2. Cosa indica `time_namelookup`?

---

## 📝 Parte 12: Esercizi Avanzati

### Esercizio 12.1 - Script Bash con curl

**Obiettivo:** Creare uno script che monitora un API.

Crea `monitor.sh`:
```bash
#!/bin/bash

URL="https://httpbin.org/status/200"
MAX_RETRIES=3

for i in $(seq 1 $MAX_RETRIES); do
    echo "Tentativo $i..."
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" $URL)
    
    if [ $HTTP_CODE -eq 200 ]; then
        echo "✓ Server OK (HTTP $HTTP_CODE)"
        exit 0
    else
        echo "✗ Server ERROR (HTTP $HTTP_CODE)"
        sleep 2
    fi
done

echo "Server non disponibile dopo $MAX_RETRIES tentativi"
exit 1
```

Esegui:
```bash
chmod +x monitor.sh
./monitor.sh
```

---

### Esercizio 12.2 - Test API con JSON output

**Obiettivo:** Parse JSON con jq.

```bash
# Installa jq se necessario
# sudo apt-get install jq

# Estrai solo i titoli
curl -s https://jsonplaceholder.typicode.com/posts | jq '.[].title'

# Estrai primo post
curl -s https://jsonplaceholder.typicode.com/posts | jq '.[0]'

# Filtra per userId
curl -s https://jsonplaceholder.typicode.com/posts | jq '.[] | select(.userId == 1)'

# Conta post
curl -s https://jsonplaceholder.typicode.com/posts | jq 'length'
```

---

### Esercizio 12.3 - Load Testing semplice

**Obiettivo:** Testare performance con richieste multiple.

```bash
# 100 richieste sequenziali
for i in {1..100}; do
    curl -s -o /dev/null -w "Request $i: %{time_total}s\n" https://httpbin.org/get
done

# Richieste parallele (background)
for i in {1..10}; do
    curl -s https://httpbin.org/get > /dev/null &
done
wait
echo "Tutte le richieste completate"
```

---

## 📝 Parte 13: Troubleshooting

### Esercizio 13.1 - Codici di stato HTTP

Testa vari codici di stato:

```bash
# 200 OK
curl -I https://httpbin.org/status/200

# 301 Redirect permanente
curl -I https://httpbin.org/status/301

# 400 Bad Request
curl -I https://httpbin.org/status/400

# 401 Unauthorized
curl -I https://httpbin.org/status/401

# 403 Forbidden
curl -I https://httpbin.org/status/403

# 404 Not Found
curl -I https://httpbin.org/status/404

# 500 Internal Server Error
curl -I https://httpbin.org/status/500

# 503 Service Unavailable
curl -I https://httpbin.org/status/503
```

**Sfida:** Crea una tabella con tutti i codici testati e il loro significato.

---

### Esercizio 13.2 - Gestione errori

**Obiettivo:** Gestire correttamente errori e fallimenti.

```bash
# Fallisce silenziosamente se errore (-f)
curl -f https://httpbin.org/status/404

# Mostra solo errori
curl -sS https://httpbin.org/status/404

# Exit code in base al risultato
curl -f https://httpbin.org/status/200 && echo "Successo!" || echo "Errore!"

# Cattura HTTP code
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://httpbin.org/status/404)
echo "Codice HTTP: $HTTP_CODE"
```

---

## 🎯 Progetto Finale: API Client Completo

Crea uno script bash `api-client.sh` che:

1. **Legge configurazione** da file `.env`
2. **Gestisce autenticazione** (API key o token)
3. **Implementa CRUD** completo
4. **Gestisce errori** con retry
5. **Logga** tutte le operazioni
6. **Formatta output** JSON con jq

### Template iniziale:

```bash
#!/bin/bash

# Carica configurazione
source .env

API_URL="${API_URL:-https://jsonplaceholder.typicode.com}"
LOG_FILE="api-client.log"

# Funzione log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Funzione GET
api_get() {
    local endpoint=$1
    log "GET $API_URL$endpoint"
    
    curl -s \
        -H "Content-Type: application/json" \
        "$API_URL$endpoint" | jq '.'
}

# Funzione POST
api_post() {
    local endpoint=$1
    local data=$2
    log "POST $API_URL$endpoint"
    
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$data" \
        "$API_URL$endpoint" | jq '.'
}

# Esempi di utilizzo
case "$1" in
    get-posts)
        api_get "/posts"
        ;;
    create-post)
        api_post "/posts" '{"title":"Test","body":"Content","userId":1}'
        ;;
    *)
        echo "Uso: $0 {get-posts|create-post}"
        exit 1
        ;;
esac
```

### File `.env`:
```bash
API_URL=https://jsonplaceholder.typicode.com
API_KEY=your_api_key_here
```

**Sfida:** Estendi lo script con:
- Comando `update` (PUT/PATCH)
- Comando `delete`
- Gestione retry su errori
- Validazione input
- Progress bar per operazioni lunghe

---

## 📋 Checklist Completamento

- [ ] Completati esercizi Parte 1 (GET base)
- [ ] Completati esercizi Parte 2 (Headers)
- [ ] Completati esercizi Parte 3 (POST)
- [ ] Completati esercizi Parte 4 (Altri metodi HTTP)
- [ ] Completati esercizi Parte 5 (Autenticazione)
- [ ] Completati esercizi Parte 6 (Cookies)
- [ ] Completati esercizi Parte 7 (Timeout e Retry)
- [ ] Completati esercizi Parte 8 (Download/Upload)
- [ ] Completati esercizi Parte 9 (HTTP/2)
- [ ] Completati esercizi Parte 10 (API REST)
- [ ] Completati esercizi Parte 11 (Debugging)
- [ ] Completati esercizi Parte 12 (Avanzati)
- [ ] Completati esercizi Parte 13 (Troubleshooting)
- [ ] Completato progetto finale

---

## 📚 Risorse Aggiuntive

### Documentazione
- Man page curl: `man curl`
- Guida online: https://curl.se/docs/manual.html
- HTTP status codes: https://httpstatuses.com/

### API di test
- httpbin.org - Testing HTTP requests
- jsonplaceholder.typicode.com - Fake REST API
- reqres.in - Another test API

### Tools correlati
- `jq` - JSON processor
- `httpie` - User-friendly HTTP client
- `wget` - Alternative a curl
- Postman - GUI per API testing

---

## 🏆 Sfide Extra (Opzionali)

### Sfida 1: Rate Limiting
Implementa uno script che rispetta rate limiting (max 10 richieste al minuto).

### Sfida 2: Concurrent Requests
Fai 50 richieste parallele e misura il tempo totale.

### Sfida 3: API Key Rotation
Gestisci multiple API key con rotazione automatica.

### Sfida 4: Cache Layer
Implementa caching locale delle risposte con timeout.

### Sfida 5: GraphQL
Usa curl per interrogare un endpoint GraphQL.

---

## ✅ Valutazione

Per superare l'esercitazione:
- ✅ Completa almeno 80% degli esercizi base (Parti 1-8)
- ✅ Completa almeno 50% degli esercizi avanzati (Parti 9-13)
- ✅ Implementa il progetto finale con almeno 3 operazioni CRUD
- ✅ Documenta il tuo lavoro con commenti e log

**Bonus:**
- 🌟 Completa tutte le sfide extra
- 🌟 Crea un client API per un servizio reale (GitHub, Twitter, etc.)
- 🌟 Scrivi test automatici per il tuo script

---

**Buon lavoro! 🚀**
