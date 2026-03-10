# Verifica Teorica — Protocollo HTTP e HTTPS

**Tempo:** 45 minuti  
**Punteggio totale:** 70 punti  
**Modalità:** Individuale, libri chiusi

---

## Istruzioni

Rispondi a tutte le domande in modo chiaro e preciso. Usa elenchi puntati dove appropriato e supporta le risposte con esempi concreti. Non lasciare spazi vuoti: anche una risposta parziale può ricevere punti parziali.

---

## Sezione A — Fondamenti HTTP *(12 punti)*

### Domanda 1 — Cos'è HTTP e il modello client-server *(4 punti)*

**Spiega cos'è il protocollo HTTP, qual è il suo ruolo nel World Wide Web e descrivi il modello client-server su cui si basa. Chi avvia la comunicazione? Qual è il ruolo di ciascun attore?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 2 — Struttura di una richiesta HTTP *(4 punti)*

**Descrivi la struttura di una richiesta HTTP indicando le 4 parti principali (riga di richiesta, header, riga vuota, body). Per ciascuna parte, indica cosa contiene e fornisci un esempio concreto.**

Completa lo schema:

```
[RICHIESTA HTTP — Schema]

Riga di richiesta:  _______________________________________________
                    (metodo + URL + versione)

Header (esempi):    Host: ________________________________________
                    User-Agent: __________________________________
                    Accept: ______________________________________
                    ____________: ________________________________

Riga vuota:         (obbligatoria — separa header dal body)

Body:               _______________________________________________
                    (presente in: ________________________________)
                    (assente in:  ________________________________)
```

**Scrivi una richiesta HTTP GET completa per richiedere la pagina `/prodotti.html` dal server `www.negozio.it`:**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 3 — Struttura di una risposta HTTP *(4 punti)*

**Descrivi la struttura di una risposta HTTP. Quali sono le sue parti? Cosa indica la "status line"? Fornisci un esempio di risposta HTTP con codice 200 OK.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Esempio di risposta HTTP 200 OK (schema):**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione B — Metodi e Codici di Stato *(14 punti)*

### Domanda 4 — Metodi HTTP: GET vs POST vs PUT vs DELETE *(4 punti)*

**Spiega le differenze tra i 4 principali metodi HTTP. Per ciascuno indica: scopo, quando si usa, se i dati sono visibili nell'URL, se è idempotente.**

| Metodo | Scopo | Dati nell'URL | Idempotente | Esempio d'uso |
|--------|-------|---------------|-------------|---------------|
| GET | | | | |
| POST | | | | |
| PUT | | | | |
| DELETE | | | | |

---

### Domanda 5 — Codici di stato 2xx (successo) e 3xx (redirect) *(3 punti)*

**Descrivi il significato dei seguenti codici di stato HTTP. Per ciascuno indica quando il server lo invia:**

| Codice | Nome | Quando viene usato |
|--------|------|-------------------|
| `200` | | |
| `201` | | |
| `204` | | |
| `301` | | |
| `302` | | |
| `304` | | |

---

### Domanda 6 — Codici 4xx: errori del client *(4 punti)*

**Spiega la differenza tra i seguenti codici di errore lato client. Per ciascuno fornisci uno scenario reale in cui si verifica:**

**HTTP 404 — Not Found:**
```
_________________________________________________________________
_________________________________________________________________
Scenario: ______________________________________________________
```

**HTTP 403 — Forbidden:**
```
_________________________________________________________________
_________________________________________________________________
Scenario: ______________________________________________________
```

**HTTP 401 — Unauthorized:**
```
_________________________________________________________________
_________________________________________________________________
Scenario: ______________________________________________________
```

**Qual è la differenza principale tra 401 e 403?**
```
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 7 — Codici 5xx: errori del server *(3 punti)*

**Descrivi i seguenti errori lato server e indica una possibile causa per ciascuno:**

| Codice | Nome | Descrizione | Possibile causa |
|--------|------|-------------|----------------|
| `500` | Internal Server Error | | |
| `502` | Bad Gateway | | |
| `503` | Service Unavailable | | |

**Chi è "responsabile" di un errore 4xx? E di un errore 5xx?**
```
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione C — HTTP vs HTTPS *(12 punti)*

### Domanda 8 — Perché HTTP non è sicuro *(4 punti)*

**Spiega perché il protocollo HTTP trasmette i dati in modo non sicuro. Descrivi almeno 2 tipi di attacco possibili su una connessione HTTP e cosa può vedere un attaccante.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Cosa può "vedere" un attaccante che intercetta una connessione HTTP su una rete Wi-Fi pubblica?**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 9 — Come HTTPS aggiunge sicurezza *(4 punti)*

**Spiega come HTTPS risolve i problemi di sicurezza di HTTP. Descrivi brevemente: cos'è TLS, cosa garantisce (riservatezza, autenticazione, integrità), e cosa sono i certificati digitali X.509.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 10 — Differenze pratiche HTTP vs HTTPS *(4 punti)*

**Completa la tabella comparativa:**

| Caratteristica | HTTP | HTTPS |
|----------------|------|-------|
| Porta di default | | |
| Dati trasmessi | In chiaro | |
| Certificato richiesto | No | |
| Lucchetto nel browser | No | |
| Indicato per | Solo contenuti pubblici | |
| Prestazioni | Più leggero | |
| Protezione da MITM | No | |

**Un sito e-commerce che gestisce pagamenti dovrebbe usare HTTP o HTTPS? Motiva la risposta.**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione D — Header HTTP Importanti *(12 punti)*

### Domanda 11 — Header di richiesta principali *(4 punti)*

**Per ciascun header HTTP di richiesta, indica il suo scopo e un esempio di valore reale:**

| Header | Scopo | Esempio di valore |
|--------|-------|------------------|
| `Host` | | |
| `User-Agent` | | |
| `Accept` | | |
| `Cookie` | | |
| `Authorization` | | |
| `Content-Type` | | |

---

### Domanda 12 — Header di risposta principali *(4 punti)*

**Per ciascun header HTTP di risposta, indica il suo scopo e un esempio di valore reale:**

| Header | Scopo | Esempio di valore |
|--------|-------|------------------|
| `Content-Type` | | |
| `Set-Cookie` | | |
| `Location` | | |
| `Cache-Control` | | |
| `Server` | | |
| `Content-Length` | | |

---

### Domanda 13 — HTTP/1.1 vs HTTP/2 vs HTTP/3 *(4 punti)*

**Descrivi le principali differenze tra le tre versioni del protocollo HTTP, concentrandoti sui miglioramenti di ciascuna:**

**HTTP/1.1 (1997):**
```
_________________________________________________________________
_________________________________________________________________
```

**HTTP/2 (2015) — principali novità rispetto a HTTP/1.1:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**HTTP/3 (2022) — cosa cambia a livello di trasporto?**
```
_________________________________________________________________
_________________________________________________________________
```

**Cos'è il "multiplexing" e perché è importante in HTTP/2?**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione E — Sessioni, Cookie e Cache *(12 punti)*

### Domanda 14 — Come funzionano i cookie *(4 punti)*

**Spiega il meccanismo dei cookie in HTTP: come vengono creati, come vengono inviati, quali attributi di sicurezza esistono.**

**Meccanismo di funzionamento:**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

**Completa la tabella degli attributi cookie:**

| Attributo | Significato | Esempio |
|-----------|-------------|---------|
| `Domain` | | |
| `Path` | | |
| `Expires` / `Max-Age` | | |
| `HttpOnly` | | |
| `Secure` | | |
| `SameSite` | | |

---

### Domanda 15 — Session cookie vs Persistent cookie *(4 punti)*

**Spiega la differenza tra session cookie e persistent cookie. Fornisci un esempio d'uso per ciascun tipo.**

**Session cookie:**
```
_________________________________________________________________
_________________________________________________________________
Esempio d'uso: _________________________________________________
_________________________________________________________________
```

**Persistent cookie:**
```
_________________________________________________________________
_________________________________________________________________
Esempio d'uso: _________________________________________________
_________________________________________________________________
```

**Se chiudi il browser e lo riapri, quale tipo di cookie sopravvive? Perché?**
```
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 16 — Meccanismi di cache HTTP *(4 punti)*

**Spiega come funziona la cache HTTP. Descrivi il ruolo dei seguenti header di cache:**

| Header | Tipo | Funzione |
|--------|------|---------|
| `Cache-Control: max-age=3600` | Risposta | |
| `Cache-Control: no-cache` | Risposta | |
| `Cache-Control: no-store` | Risposta | |
| `ETag` | Risposta | |
| `Last-Modified` | Risposta | |
| `If-None-Match` | Richiesta | |
| `If-Modified-Since` | Richiesta | |

**Cosa significa il codice di stato `304 Not Modified` in relazione alla cache?**
```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione F — Scenari Applicativi e Troubleshooting *(8 punti)*

*Domande a risposta breve — max 4 righe per risposta*

### Domanda 17 — Browser DevTools e analisi HTTP *(2 punti)*

**Come si analizza il traffico HTTP con i DevTools del browser? Qual è la scheda da aprire e cosa si può vedere?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 18 — Redirect loop *(2 punti)*

**Cosa significa "redirect loop" (loop di reindirizzamento)? Come si manifesta per l'utente e qual è una causa tipica?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 19 — HTTP 301 vs 302 *(2 punti)*

**Qual è la differenza tra un redirect HTTP 301 e un redirect HTTP 302? Quando si usa l'uno e quando l'altro?**

| | 301 Moved Permanently | 302 Found (Temporary) |
|---|---|---|
| Tipo di redirect | | |
| I motori di ricerca... | | |
| Esempio d'uso tipico | | |

---

### Domanda 20 — Virtual Hosting *(2 punti)*

**Spiega come funziona il virtual hosting in HTTP. Come può un server con un solo indirizzo IP ospitare più siti web diversi? Quale header HTTP rende ciò possibile?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## 📊 Griglia di Valutazione

| Sezione | Descrizione | Punti max | Punti ottenuti |
|---------|-------------|-----------|---------------|
| **A** | Fondamenti HTTP | 12 | |
| **B** | Metodi e codici di stato | 14 | |
| **C** | HTTP vs HTTPS | 12 | |
| **D** | Header HTTP importanti | 12 | |
| **E** | Sessioni, Cookie e Cache | 12 | |
| **F** | Scenari e Troubleshooting | 8 | |
| | **TOTALE** | **70** | |

**Voto in decimi:**

| Punteggio | Voto |
|-----------|------|
| 63–70 | 10 |
| 56–62 | 9 |
| 49–55 | 8 |
| 42–48 | 7 |
| 35–41 | 6 |
| 28–34 | 5 |
| 21–27 | 4 |
| < 21 | 3 |

---

*Studente: __________________________________ Classe: _________ Data: __________*
