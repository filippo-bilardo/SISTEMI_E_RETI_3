# 01 — Vulnerabilità di HTTP: Fondamenti e Threat Model

> 🎯 **Obiettivo**: Comprendere perché HTTP è intrinsecamente insicuro, conoscere le principali categorie di attacchi web e saper costruire un threat model di base per un'applicazione web.

---

## 1. Perché HTTP è Insicuro "By Design"

Il protocollo **HTTP** (HyperText Transfer Protocol) fu progettato da Tim Berners-Lee nel 1989–1991 per scambiare documenti ipertestuali in una rete accademica ristretta e fidata. Le assunzioni iniziali — tutti gli utenti sono ricercatori onesti, la rete è piccola e controllata — sono completamente diverse dalla realtà del web moderno.

### 1.1 Tre Difetti Strutturali

#### ❌ Difetto 1: Testo in chiaro (no confidenzialità)

HTTP trasmette **tutto in chiaro**, senza alcuna cifratura. Chiunque sia in ascolto sulla rete (stesso Wi-Fi, ISP, nodo intermedio) può leggere:
- URL della richiesta (inclusi parametri con dati sensibili)
- Header HTTP (cookie di sessione, credenziali Basic Auth codificate in Base64)
- Corpo della richiesta (password in POST, dati personali)
- Contenuto della risposta (HTML, JSON con dati dell'utente)

```http
GET /login?username=mario&password=segreto123 HTTP/1.1
Host: www.example.com
Cookie: sessionid=abc123xyz
```
> 🔴 Tutto quanto sopra è visibile a chiunque intercetti il traffico.

#### ❌ Difetto 2: No integrità dei dati

HTTP non verifica che i dati ricevuti siano gli stessi inviati. Un attaccante **Man-in-the-Middle** può:
- Modificare il contenuto di una risposta HTML (iniettare script malevoli)
- Alterare i dati di un form prima che arrivino al server
- Cambiare link o immagini in una pagina

#### ❌ Difetto 3: No autenticazione dell'origine

HTTP non garantisce che il server con cui si comunica sia quello autentico. Senza certificati digitali, non si può sapere se `www.banca.it` è davvero la propria banca o un server malevolo.

### 1.2 Statelessness: Problema o Feature?

HTTP è **stateless** — ogni richiesta è indipendente dalle precedenti. Questo è efficiente per la scalabilità, ma crea problemi di sicurezza:

- Il server non "ricorda" l'utente tra una richiesta e l'altra → necessità di **cookie di sessione**
- I cookie di sessione diventano un bersaglio privilegiato degli attaccanti
- Meccanismi di sessione mal implementati → vulnerabilità (session fixation, hijacking)

### 1.3 Tabella Riassuntiva Difetti HTTP

| Proprietà di sicurezza | HTTP | HTTPS/TLS |
|------------------------|------|-----------|
| **Confidenzialità** (dati non leggibili da terzi) | ❌ No | ✅ Sì |
| **Integrità** (dati non modificati in transito) | ❌ No | ✅ Sì |
| **Autenticazione origine** (il server è chi dice di essere) | ❌ No | ✅ Sì (con certificati) |
| **Non ripudio** | ❌ No | ⚠️ Parziale |

---

## 2. OWASP Top 10 — Le 10 Vulnerabilità Più Critiche

L'**OWASP** (Open Web Application Security Project) è una fondazione no-profit che pubblica risorse gratuite sulla sicurezza web. La sua pubblicazione più nota è la **OWASP Top 10**: una classifica delle 10 categorie di vulnerabilità più pericolose e diffuse nelle applicazioni web.

Viene aggiornata periodicamente (ultima versione: 2021). È diventata uno **standard de facto** per sviluppatori, tester di sicurezza e auditor.

### OWASP Top 10 — Versione 2021

| # | Categoria | Descrizione breve | Esempio tipico |
|---|-----------|------------------|----------------|
| **A01** | Broken Access Control | Controllo accessi difettoso | Accedere ai dati di altri utenti cambiando l'ID nell'URL |
| **A02** | Cryptographic Failures | Crittografia assente o debole | Password in chiaro nel DB, HTTP invece di HTTPS |
| **A03** | Injection | Inserimento di codice malevolo | SQL Injection, Command Injection, XSS |
| **A04** | Insecure Design | Difetti nel design dell'applicazione | Nessun rate limiting sul login, nessun token CSRF |
| **A05** | Security Misconfiguration | Configurazione di sicurezza sbagliata | Header di sicurezza mancanti, debug mode attivo in produzione |
| **A06** | Vulnerable and Outdated Components | Librerie con vulnerabilità note | Framework JavaScript obsoleto con CVE noti |
| **A07** | Identification and Authentication Failures | Autenticazione difettosa | Password senza limiti di tentativi, session token prevedibili |
| **A08** | Software and Data Integrity Failures | Aggiornamenti non verificati | Librerie scaricate senza verifica firma, deserializzazione non sicura |
| **A09** | Security Logging and Monitoring Failures | Log insufficienti | Nessun alert su 1000 tentativi di login falliti |
| **A10** | Server-Side Request Forgery (SSRF) | Il server esegue richieste verso risorse interne | Il server accede a `http://169.254.169.254/` (AWS metadata) per conto dell'attaccante |

> 💡 **Nota didattica**: L'OWASP Top 10 non è una lista di "bug" specifici ma di **categorie di problemi**. Ogni categoria comprende decine di varianti concrete.

---

## 3. Categorie di Attacchi Web

Gli attacchi web si possono classificare in base al **livello** in cui agiscono:

### 3.1 Attacchi sul Canale (Network Layer)

Sfruttano il fatto che il traffico HTTP viaggia in chiaro o che il canale TLS può essere degradato.

| Attacco | Meccanismo | Cosa compromette |
|---------|-----------|-----------------|
| **Sniffing** | Intercettazione passiva del traffico | Confidenzialità |
| **MITM** | Inserimento nel canale di comunicazione | Confidenzialità + Integrità |
| **SSL Stripping** | Downgrade HTTPS→HTTP | Confidenzialità |
| **SSL/TLS Downgrade** | Forza versioni TLS obsolete (SSLv3, TLS 1.0) | Confidenzialità |

### 3.2 Attacchi sull'Applicazione (Application Layer)

Sfruttano difetti nel codice o nella logica dell'applicazione web (vulnerabilità A01–A10 OWASP).

| Attacco | Livello OSI | Obiettivo |
|---------|------------|-----------|
| SQL Injection | L7 (Applicazione) | Database |
| XSS | L7 (Applicazione) | Browser dell'utente |
| CSRF | L7 (Applicazione) | Azioni autorizzate della vittima |
| Directory Traversal | L7 (Applicazione) | File system del server |
| Broken Access Control | L7 (Applicazione) | Dati di altri utenti |

### 3.3 Attacchi sull'Utente (Social Engineering Layer)

Non attaccano il protocollo né l'applicazione direttamente, ma ingannano l'utente.

| Attacco | Meccanismo |
|---------|-----------|
| **Phishing** | Sito web clone che raccoglie credenziali |
| **Clickjacking** | Pulsante/link invisibile sovrapposto a un'azione legittima |
| **Typosquatting** | Dominio con nome simile (`paypa1.com` invece di `paypal.com`) |

---

## 4. Threat Model di un'Applicazione Web

Il **threat model** (modello delle minacce) è un processo sistematico per identificare:
- **Chi** potrebbe attaccare il sistema (gli attaccanti)
- **Cosa** potrebbe essere attaccato (gli asset)
- **Come** potrebbero attaccare (i vettori)
- **Perché** (la motivazione)

### 4.1 Asset da Proteggere

| Asset | Descrizione | Impatto se compromesso |
|-------|-------------|----------------------|
| Dati utenti | Nomi, email, indirizzi, dati di pagamento | GDPR violation, danno reputazionale |
| Credenziali | Password, token di sessione | Account takeover |
| Codice sorgente | Logica dell'applicazione | Esposizione di vulnerabilità, furto IP |
| Database | Tutti i dati aziendali | Data breach completo |
| Infrastruttura | Server, rete, DNS | Indisponibilità del servizio |

### 4.2 Profili degli Attaccanti

| Profilo | Motivazione | Competenza | Esempio |
|---------|------------|-----------|---------|
| **Script kiddie** | Curiosità, vandalismo | Bassa | Usa tool esistenti senza capirli |
| **Hacker opportunista** | Guadagno facile | Media | Scansiona Internet per vulnerabilità note |
| **Criminale organizzato** | Guadagno economico | Alta | Furto dati bancari, ransomware |
| **Concorrente** | Vantaggio competitivo | Media-alta | Spionaggio industriale |
| **Nation state** | Spionaggio, sabotaggio | Molto alta | APT (Advanced Persistent Threat) |
| **Insider** | Vendetta, guadagno | Variabile | Dipendente scontento con accesso privilegiato |

### 4.3 Vettori di Attacco Tipici

```
Internet
   │
   ├─── Porta 80/443 ──→ Web Server ──→ App Server ──→ Database
   │                          │
   │                    Form di login (SQL Injection?)
   │                    Upload file (Command Injection?)
   │                    URL parameters (XSS, Traversal?)
   │
   ├─── DNS ──→ Domain resolution (Typosquatting?)
   │
   └─── Email ──→ Utente ──→ Click link phishing (Credential theft?)
```

### 4.4 Metodologia STRIDE

Microsoft ha sviluppato **STRIDE** per classificare le minacce:

| Lettera | Minaccia | Descrizione | Proprietà violata |
|---------|---------|-------------|------------------|
| **S** | Spoofing | Falsificazione dell'identità | Autenticazione |
| **T** | Tampering | Modifica dei dati | Integrità |
| **R** | Repudiation | Negare di aver eseguito un'azione | Non ripudio |
| **I** | Information Disclosure | Divulgazione di informazioni | Confidenzialità |
| **D** | Denial of Service | Rendere il servizio indisponibile | Disponibilità |
| **E** | Elevation of Privilege | Ottenere più permessi del dovuto | Autorizzazione |

---

## 5. Terminologia Fondamentale

| Termine | Definizione | Esempio |
|---------|-------------|---------|
| **Vulnerability** | Debolezza nel sistema che può essere sfruttata | Input non sanificato che permette SQL Injection |
| **Exploit** | Tecnica/codice che sfrutta una vulnerabilità | Script Python che invia payload SQL malevolo |
| **Payload** | Il contenuto malevolo che viene eseguito | `' OR 1=1 --` nella query SQL |
| **CVE** | Common Vulnerabilities and Exposures — ID univoco per vulnerabilità note | CVE-2021-44228 (Log4Shell) |
| **CVSS** | Common Vulnerability Scoring System — punteggio da 0 a 10 | Log4Shell: 10.0 (critico) |
| **Zero-day** | Vulnerabilità non ancora pubblica né patchata | Attacco prima che il vendor rilasci la patch |
| **PoC** | Proof of Concept — dimostrazione che una vulnerabilità è sfruttabile | Codice minimo che dimostra l'attacco |

---

## 6. Strumenti di Analisi (Cenni Teorici)

> ⚠️ **Nota etica e legale**: questi strumenti possono essere usati **solo** su sistemi di cui si è proprietari o per cui si ha esplicita autorizzazione scritta. L'uso non autorizzato è un reato (in Italia: art. 615-ter C.P. — Accesso abusivo a sistema informatico).

### 6.1 Burp Suite

- **Tipo**: Proxy HTTP intercettante + scanner di vulnerabilità
- **Produttore**: PortSwigger
- **Uso**: Intercettare e modificare richieste HTTP/HTTPS, testare input per XSS/SQLi/CSRF
- **Versione gratuita**: Community Edition (funzionalità ridotte)
- **Usato da**: Penetration tester professionali, bug bounty hunter

### 6.2 OWASP ZAP (Zed Attack Proxy)

- **Tipo**: Scanner di sicurezza web open source
- **Produttore**: OWASP Foundation
- **Uso**: Scansione automatica delle vulnerabilità web, testing manuale
- **Vantaggi**: Gratuito, attivamente mantenuto, plugin estensibili
- **Adatto per**: Studenti, sviluppatori, team di sicurezza interni

### 6.3 Ambienti di Pratica Sicuri

| Ambiente | Descrizione | URL |
|----------|-------------|-----|
| **DVWA** | Damn Vulnerable Web Application — app volutamente vulnerabile | Installabile in locale |
| **OWASP WebGoat** | App didattica per imparare a testare vulnerabilità | Installabile in locale |
| **TryHackMe** | Piattaforma online con lab guidati | tryhackme.com |
| **HackTheBox** | Piattaforma online con sfide avanzate | hackthebox.com |

---

## 7. Tabella Riassuntiva Finale

| Attacco | Livello | Cosa compromette | Difficoltà | Impatto | Difesa principale |
|---------|---------|-----------------|-----------|---------|------------------|
| Sniffing HTTP | Rete (L2-L3) | Confidenzialità | 🟢 Bassa | 🔴 Alto | HTTPS/TLS |
| MITM | Rete (L3) | Conf. + Integrità | 🟡 Media | 🔴 Alto | HTTPS + HSTS |
| SSL Stripping | Rete (L7) | Confidenzialità | 🟡 Media | 🔴 Alto | HSTS + Preload |
| XSS | Applicazione (L7) | Utente (sessione) | 🟡 Media | 🟡 Medio | CSP + Output encoding |
| CSRF | Applicazione (L7) | Azioni utente | 🟡 Media | 🟡 Medio | Token anti-CSRF + SameSite |
| SQL Injection | Applicazione (L7) | Database | 🟡 Media | 🔴 Alto | Prepared statements |
| Directory Traversal | Applicazione (L7) | File system | 🟢 Bassa | 🔴 Alto | Validazione path |
| Clickjacking | Utente | Azioni utente | 🟢 Bassa | 🟡 Medio | X-Frame-Options / CSP |
| Broken Access Control | Applicazione (L7) | Dati riservati | 🟢 Bassa | 🔴 Alto | Autorizzazione server-side |
| Session Hijacking | Applicazione (L7) | Sessione utente | 🟡 Media | 🔴 Alto | HttpOnly + Secure cookie |
