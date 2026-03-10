# Verifica Teorica — DNS e Risoluzione dei Nomi

**Tempo:** 45 minuti  
**Punteggio totale:** 70 punti  
**Modalità:** Individuale, libri chiusi

---

## Istruzioni

Rispondi a tutte le domande in modo chiaro e preciso. Usa elenchi puntati quando appropriato e supporta le risposte con esempi quando possibile. Non lasciare spazi vuoti: anche una risposta parziale può ricevere punti parziali.

---

## Sezione A — Concetti di DNS *(14 punti)*

### Domanda 1 — Cos'è il DNS? *(3 punti)*

**Spiega cos'è il DNS (Domain Name System), qual è la sua funzione principale e perché è considerato un componente fondamentale di Internet.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 2 — Gerarchia DNS *(4 punti)*

**Descrivi la struttura gerarchica del DNS, partendo dalla radice fino ai sottodomini. Indica almeno un esempio per ogni livello.**

Completa lo schema:

```
                          . (root)
                          |
         ______________________________________
        |          |           |              |
      [TLD]      [TLD]       [TLD]          [TLD]
      .com        .it       .org             .edu
        |
   [Dominio SLD]
   esempio.com
        |
   [Sottodominio]
   www.esempio.com
```

**Spazio risposta (descrizione dei livelli):**

```
Root (.):
_________________________________________________________________

TLD (Top-Level Domain):
_________________________________________________________________

SLD (Second-Level Domain):
_________________________________________________________________

Sottodominio:
_________________________________________________________________
```

---

### Domanda 3 — Risoluzione Ricorsiva vs Iterativa *(4 punti)*

**Qual è la differenza tra risoluzione DNS ricorsiva e risoluzione DNS iterativa? Descrivi il processo passo per passo per entrambe.**

| Caratteristica | Ricorsiva | Iterativa |
|----------------|-----------|-----------|
| Chi esegue il lavoro | | |
| Numero di query dal client | | |
| Usata tipicamente da | | |
| Carico sul resolver | | |

**Descrizione del processo ricorsivo:**

```
1. ____________________________________________________________
2. ____________________________________________________________
3. ____________________________________________________________
4. ____________________________________________________________
```

---

### Domanda 4 — DNS Cache *(3 punti)*

**Spiega cos'è la cache DNS e qual è il ruolo del TTL (Time To Live). Cosa succede se il TTL è molto basso? E se è molto alto?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione B — Tipi di Record DNS *(12 punti)*

### Domanda 5 — Record di tipo A e AAAA *(2 punti)*

**Qual è la differenza tra un record DNS di tipo A e uno di tipo AAAA? Fornisci un esempio per ciascuno.**

```
Record A:
_________________________________________________________________

Record AAAA:
_________________________________________________________________

Esempio A:    _____________________________________________________
Esempio AAAA: _____________________________________________________
```

---

### Domanda 6 — Record CNAME *(2 punti)*

**Cos'è un record CNAME e quando si usa? Fai un esempio pratico.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 7 — Record MX *(2 punti)*

**A cosa serve un record MX? Cosa indica il valore di priorità (priority) in un record MX?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 8 — Record PTR *(2 punti)*

**Cos'è un record PTR e in quale zona DNS si trova? Fornisci un esempio di utilizzo pratico.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 9 — Record NS e SOA *(2 punti)*

**Spiega la funzione del record NS e del record SOA. Perché sono importanti per la gestione di una zona DNS?**

```
Record NS:
_________________________________________________________________

Record SOA:
_________________________________________________________________
```

---

### Domanda 10 — Completamento Tabella Record *(2 punti)*

**Completa la tabella seguente:**

| Record | Tipo | Funzione |
|--------|------|---------|
| `www.azienda.it. IN A 93.184.216.34` | A | ______________ |
| `mail IN MX 10 smtp.azienda.it.` | MX | ______________ |
| `ftp IN CNAME www` | CNAME | ______________ |
| `34.216.184.93.in-addr.arpa. IN PTR www.azienda.it.` | PTR | ______________ |

---

## Sezione C — DNS in Reti Locali *(11 punti)*

### Domanda 11 — DNS Interno vs DNS Pubblico *(3 punti)*

**Qual è la differenza tra un DNS interno (privato) e un DNS pubblico? In quale scenario un'azienda ha bisogno di entrambi?**

```
DNS Interno:
_________________________________________________________________

DNS Pubblico:
_________________________________________________________________

Scenario con entrambi:
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 12 — Split-Horizon DNS *(4 punti)*

**Spiega il concetto di Split-Horizon DNS (o Split-Brain DNS). Fornisci un esempio pratico di un'azienda che utilizza questa tecnica e i vantaggi che ne derivano.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 13 — DNS Forwarding *(4 punti)*

**Cos'è il DNS forwarding? Spiega come un DNS interno aziendale può risolvere nomi pubblici (es. `google.com`) senza essere un full-resolver.**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione D — Protocolli e Porte *(10 punti)*

### Domanda 14 — UDP e TCP per DNS *(3 punti)*

**DNS usa UDP o TCP? In quali circostanze viene utilizzato TCP invece di UDP? Qual è la porta standard del DNS?**

```
Porta DNS: ___________

Protocollo principale: ___________

Quando si usa TCP:
_________________________________________________________________
_________________________________________________________________
```

---

### Domanda 15 — Struttura di una Query DNS *(4 punti)*

**Descrivi le fasi di una query DNS completa: dalla digitazione di un URL nel browser fino alla ricezione della risposta IP. Indica quali componenti entrano in gioco.**

```
1. Utente digita URL:   ____________________________________________
2. Controllo cache:     ____________________________________________
3. Richiesta al resolver: __________________________________________
4. Richiesta ai server autoritativi: ______________________________
5. Risposta e cache:    ____________________________________________
```

---

### Domanda 16 — DNSSEC *(3 punti)*

**Cos'è DNSSEC e quale problema di sicurezza risolve? È implementato nella versione base di Cisco Packet Tracer?**

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Sezione E — Troubleshooting DNS *(15 punti)*

### Domanda 17 — Comando nslookup *(5 punti)*

**Spiega come si usa il comando `nslookup`. Analizza l'output seguente e indica cosa significa ogni riga:**

```
> nslookup www.azienda.local
Server:  dns.azienda.local
Address: 192.168.1.10

Name:    www.azienda.local
Address: 192.168.1.20
```

| Riga | Significato |
|------|-------------|
| `Server: dns.azienda.local` | |
| `Address: 192.168.1.10` | |
| `Name: www.azienda.local` | |
| `Address: 192.168.1.20` | |

**Come si usa `nslookup` per interrogare un server DNS specifico (non quello configurato di default)?**

```
Comando: ___________________________________________________________
```

---

### Domanda 18 — Diagnosi Problemi DNS *(5 punti)*

**Un utente non riesce a raggiungere `www.azienda.local` per nome, ma il ping all'indirizzo IP `192.168.1.20` funziona. Descrivi almeno 3 possibili cause e come verificarle.**

```
Causa 1:
_________________________________________________________________
Verifica: _________________________________________________________

Causa 2:
_________________________________________________________________
Verifica: _________________________________________________________

Causa 3:
_________________________________________________________________
Verifica: _________________________________________________________
```

---

### Domanda 19 — Comandi di Diagnostica *(5 punti)*

**Per ciascuno dei seguenti comandi, spiega cosa fa e fornisci un esempio di output atteso in un sistema Windows (Packet Tracer):**

**`ipconfig /all`:**

```
Funzione: __________________________________________________________
Output chiave da cercare: __________________________________________
```

**`ping www.azienda.local`:**

```
Funzione: __________________________________________________________
Output se DNS funziona: ____________________________________________
Output se DNS non funziona: ________________________________________
```

**`nslookup mail.azienda.local`:**

```
Funzione: __________________________________________________________
Output atteso: _____________________________________________________
```

---

## Sezione F — Scenari Avanzati *(8 punti)*

### Domanda 20 — DNS Primario e Secondario *(4 punti)*

**Spiega la differenza tra un DNS primario (master) e un DNS secondario (slave). Quali sono i vantaggi di avere un DNS secondario in una rete aziendale? In Packet Tracer come si simula questa configurazione?**

```
DNS Primario:
_________________________________________________________________

DNS Secondario:
_________________________________________________________________

Vantaggi:
_________________________________________________________________
_________________________________________________________________

In Packet Tracer:
_________________________________________________________________
```

---

### Domanda 21 — TTL e DNS Caching *(4 punti)*

**Scenario:** Hai modificato il record A di `www.azienda.local` da `192.168.1.20` a `192.168.1.25`. Alcuni client continuano a ricevere il vecchio indirizzo. Spiega perché accade e come si risolve.

```
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## 📊 Griglia di Valutazione

| Sezione | Domande | Punti Disponibili | Punti Ottenuti |
|---------|---------|-------------------|----------------|
| A — Concetti DNS | 1–4 | 14 | |
| B — Tipi di Record | 5–10 | 12 | |
| C — DNS in reti locali | 11–13 | 11 | |
| D — Protocolli e porte | 14–16 | 10 | |
| E — Troubleshooting | 17–19 | 15 | |
| F — Scenari avanzati | 20–21 | 8 | |
| **TOTALE** | **21** | **70** | |

---

**Scala di valutazione:**

| Punteggio | Voto | Giudizio |
|-----------|------|---------|
| 63–70 | 9–10 | Ottimo |
| 52–62 | 7–8 | Buono |
| 42–51 | 6 | Sufficiente |
| 28–41 | 4–5 | Insufficiente |
| 0–27 | 2–3 | Gravemente insufficiente |

---

*Punteggio: _______ / 70 — Voto: _______*  
*Data: _______________ — Firma: ___________________________*
