# Esercizio C — Domande di Teoria: Sicurezza DNS

**Tipo**: Verifica teorica scritta  
**Tempo**: 60 minuti  
**Punteggio totale**: 70 punti  
**Materiale consentito**: nessuno (verifica chiusa)

---

> **Istruzioni**: Per ogni domanda scrivi una risposta **completa e motivata** nello spazio indicato. Le risposte in forma di elenco puntato sono accettate se esaustive. Utilizza terminologia tecnica appropriata.

---

## Sezione A — Vulnerabilità del Protocollo DNS `[12 punti]`

---

### A1. Perché il DNS è considerato "insicuro by design"? `[4 pt]`

Spiega le caratteristiche originali del protocollo DNS che lo rendono vulnerabile, facendo riferimento al contesto storico in cui è stato progettato e agli assunti di fiducia su cui si basa.

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: uso di UDP, assenza di autenticazione, cache distribuita non verificata, progettazione anni '80 su rete fiduciosa, transazioni identificate solo da ID a 16 bit.*

---

### A2. Quali caratteristiche del protocollo UDP rendono il DNS particolarmente esposto agli attacchi? `[4 pt]`

Descrivi le proprietà di UDP rilevanti per la sicurezza DNS, confrontandole brevemente con TCP.

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: connectionless (no handshake), IP spoofing facilitato, no stato di connessione, transaction ID 16 bit facilmente indovinabile, assenza di cifratura.*

---

### A3. Cos'è il "Kaminsky Attack" (2008)? Perché è stato considerato una scoperta critica? `[4 pt]`

Descrivi il meccanismo dell'attacco scoperto da Dan Kaminsky, spiegando perché rappresentò una svolta nella comprensione delle vulnerabilità DNS.

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: race condition su transaction ID, avvelenamento della cache del resolver, invio massivo di risposte false prima di quella legittima, impatto sistemico (tutti i resolver vulnerabili), necessità di randomizzazione della source port come mitigazione immediata.*

---

## Sezione B — Attacchi DNS `[16 punti]`

---

### B1. Descrivi in modo dettagliato il meccanismo del DNS Cache Poisoning. `[4 pt]`

Illustra passo per passo come un attaccante riesce ad avvelenare la cache di un resolver DNS. Puoi usare uno schema o elenco numerato.

**Risposta:**

```
Passo 1: ______________________________________________________
Passo 2: ______________________________________________________
Passo 3: ______________________________________________________
Passo 4: ______________________________________________________
Passo 5: ______________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: client fa query → resolver chiede all'authoritative → attaccante invia risposta falsa con ID corretto prima di quella legittima → resolver memorizza record falso in cache → tutti i client che interrogano quel resolver ricevono l'IP falso per tutta la durata del TTL.*

---

### B2. Quali sono le differenze tra DNS Hijacking locale, remoto e a livello ISP? `[4 pt]`

Per ciascuno dei tre livelli, descrivi il meccanismo di attacco e un esempio concreto.

**Risposta:**

| Tipo | Meccanismo | Esempio |
|------|-----------|---------|
| **Locale** | | |
| **Remoto** | | |
| **ISP-level** | | |

```
Note aggiuntive:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi — Locale: malware sul PC che modifica DNS nelle impostazioni di rete o nel file hosts; Remoto: compromissione del router/gateway con cambio DNS nel DHCP (es. attacchi a router domestici); ISP-level: l'ISP reindirizza query DNS per censura, monitoraggio o inserimento di pubblicità.*

---

### B3. Come funziona un attacco DNS Amplification/Reflection DDoS? Qual è il fattore di amplificazione tipico? `[4 pt]`

Descrivi il meccanismo completo, spiegando il ruolo del resolver aperto, dello spoofing IP e del volume di traffico generato.

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: attaccante usa botnet, invia query DNS con IP sorgente della vittima (spoofed), i resolver aperti rispondono alla vittima con risposte di grandi dimensioni (record ANY, TXT lunghi), amplification factor tipico 28x–70x, la vittima riceve traffico enorme che satura la connessione.*

---

### B4. Cos'è il DNS Tunneling? A cosa serve e perché è difficile da rilevare? `[4 pt]`

Spiega il concetto, descrivendo come vengono codificati i dati nelle query DNS e citando almeno un tool noto.

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: i dati vengono codificati nei nomi di dominio delle query DNS (es. Base64 nel subdomain), le risposte contengono dati codificati (TXT, CNAME, NULL records), il DNS è quasi sempre permesso dai firewall, difficile da rilevare senza deep packet inspection, tool: iodine, dnscat2, uso per command & control di malware o bypass captive portal.*

---

## Sezione C — DNSSEC `[14 punti]`

---

### C1. Cos'è DNSSEC e cosa garantisce (e cosa NON garantisce)? `[4 pt]`

Descrivi l'obiettivo di DNSSEC, specificando con precisione cosa autentica e cosa rimane al di fuori della sua protezione.

**Risposta:**

```
DNSSEC garantisce:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

DNSSEC NON garantisce:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi — Garantisce: autenticità e integrità dei dati DNS (non sono stati modificati), prova di non esistenza (NSEC/NSEC3), catena di fiducia verificabile; NON garantisce: riservatezza (query in chiaro), protezione da attacchi DDoS, sicurezza del client o del canale di comunicazione.*

---

### C2. Descrivi il meccanismo della catena di fiducia DNSSEC e il ruolo dei record DNSKEY e DS. `[6 pt]`

Spiega come si costruisce la catena di fiducia dalla root zone fino alla zona di destinazione, descrivendo i ruoli di ZSK, KSK, DNSKEY e DS.

**Risposta:**

```
Catena di fiducia (dal basso verso l'alto):
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Ruolo ZSK (Zone Signing Key):
_______________________________________________________________
_______________________________________________________________

Ruolo KSK (Key Signing Key):
_______________________________________________________________
_______________________________________________________________

Record DNSKEY:
_______________________________________________________________

Record DS (Delegation Signer):
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: la root zone è il trust anchor, ogni zona firma i propri record con ZSK, la ZSK è firmata dalla KSK, il DS record della zona figlia è pubblicato nella zona padre (delegazione sicura), la catena va da root → TLD → dominio; RRSIG contiene la firma digitale; validazione ricorsiva.*

---

### C3. Perché DNSSEC non è universalmente adottato? Elenca almeno 3 limitazioni concrete. `[4 pt]`

**Risposta:**

```
Limitazione 1: ________________________________________________
_______________________________________________________________

Limitazione 2: ________________________________________________
_______________________________________________________________

Limitazione 3: ________________________________________________
_______________________________________________________________

Limitazione 4 (bonus): ________________________________________
_______________________________________________________________
```

*Elementi attesi: complessità di gestione (rotazione chiavi), aumento dimensione risposte DNS (possibile frammentazione), zone enumeration con NSEC (mitigato da NSEC3), adozione parziale (se la catena si spezza la validazione fallisce), overhead computazionale, non risolve la confidenzialità.*

---

## Sezione D — DNS over HTTPS (DoH) e DNS over TLS (DoT) `[12 punti]`

---

### D1. Quali sono le differenze tecniche principali tra DoH e DoT? `[4 pt]`

Completa la tabella comparativa:

| Caratteristica | DNS Tradizionale | DoT | DoH |
|---------------|-----------------|-----|-----|
| Porta | 53 | | |
| Protocollo trasporto | UDP/TCP | | |
| Cifratura | Nessuna | | |
| RFC di riferimento | RFC 1035 | | |
| Visibilità al firewall | Query in chiaro | | |
| Supporto browser nativo | No | | |

```
Note sulla differenza principale DoT vs DoH:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

---

### D2. Quali vantaggi in termini di privacy offrono DoH e DoT rispetto al DNS tradizionale? `[4 pt]`

Descrivi i rischi della privacy con il DNS tradizionale e come DoH/DoT li mitigano.

**Risposta:**

```
Rischi del DNS tradizionale per la privacy:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Come DoH/DoT mitigano questi rischi:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Limiti della protezione offerta:
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi — Rischi: query in chiaro intercettabili da ISP/attaccanti MITM, profiling degli utenti, DNS hijacking facilitato; Mitigazione: cifratura end-to-end, impossibile intercettare in chiaro; Limiti: il resolver stesso vede ancora le query, non protegge da resolver malevolo, non impedisce la raccolta dati da parte del provider DoH.*

---

### D3. Quali implicazioni ha l'adozione di DoH per il monitoring e il filtering di sicurezza aziendale? `[4 pt]`

Spiega perché DoH è problematico per i team di sicurezza delle aziende e quali approcci si possono adottare.

**Risposta:**

```
Problema principale per la sicurezza aziendale:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Strategie di mitigazione per le aziende:
1. ____________________________________________________________
2. ____________________________________________________________
3. ____________________________________________________________

Considerazione sul bilanciamento sicurezza/privacy:
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi — Problema: il traffico DoH passa su porta 443 (HTTPS), è cifrato e indistinguibile dal normale traffico web, i sistemi di filtering/IDS non possono analizzare le query; Strategie: bloccare i resolver DoH pubblici noti (by IP/dominio), imporre l'uso del resolver interno, usare soluzioni di SSL inspection, TLS decryption proxy, configurare i browser per usare il resolver interno.*

---

## Sezione E — Difese Pratiche `[14 punti]`

---

### E1. Cos'è il Response Rate Limiting (RRL) e come previene gli attacchi di amplification? `[4 pt]`

**Risposta:**

```
Definizione di RRL:
_______________________________________________________________
_______________________________________________________________

Meccanismo di funzionamento:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Perché riduce l'efficacia dell'amplification:
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: RRL limita la frequenza con cui un server DNS risponde alle stesse query dallo stesso IP sorgente, le risposte in eccesso vengono scartate o troncate (TRUNCATE bit), riduce il volume di traffico amplificato verso la vittima, senza impatto significativo su client legittimi che raramente ripetono la stessa query.*

---

### E2. Cosa significa configurare un resolver come "closed" invece di "open"? Perché è una best practice fondamentale? `[3 pt]`

**Risposta:**

```
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: open resolver risponde a query ricorsive da qualsiasi sorgente Internet, closed resolver risponde solo a query provenienti da IP autorizzati (rete interna), implementazione tramite ACL, quasi tutti gli attacchi di amplification sfruttano open resolver, il numero di open resolver su Internet è ancora elevato.*

---

### E3. Come può essere usato il DNS split-horizon come misura di sicurezza? `[4 pt]`

Descrivi il concetto e fai un esempio concreto di come protegge la rete aziendale.

**Risposta:**

```
Definizione:
_______________________________________________________________
_______________________________________________________________

Esempio di implementazione:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Vantaggio di sicurezza:
_______________________________________________________________
_______________________________________________________________
```

---

### E4. Quali segnali nelle query DNS possono indicare un'attività anomala o malevola? Elencane almeno 4. `[3 pt]`

**Risposta:**

```
Segnale 1: ____________________________________________________
Indicatore di: ________________________________________________

Segnale 2: ____________________________________________________
Indicatore di: ________________________________________________

Segnale 3: ____________________________________________________
Indicatore di: ________________________________________________

Segnale 4: ____________________________________________________
Indicatore di: ________________________________________________
```

*Elementi attesi: alto tasso di NXDOMAIN (dominio inesistente) → DGA malware o ricognizione; query di tipo TXT/NULL insolite → DNS tunneling; query verso domini con entropia alta (random) → DGA; alto volume di query ANY → amplification prep; query verso stessi domini da molti host → botnet C2; subdomain molto lunghi → tunneling.*

---

## Sezione F — Scenari e Casi Reali `[12 punti]`

---

### F1. Nel 2018, una serie di router domestici di vari produttori fu vittima di attacchi che modificavano il server DNS configurato nel DHCP. Analizza questo scenario. `[4 pt]`

**a)** Come avveniva tecnicamente l'attacco?  
**b)** Quali erano le conseguenze per gli utenti?  
**c)** Come ci si poteva difendere?

**Risposta:**

```
a) Meccanismo tecnico:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

b) Conseguenze:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

c) Difese:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

---

### F2. Come si può rilevare che la cache DNS di un resolver è stata avvelenata (cache poisoning)? `[4 pt]`

Descrivi i sintomi che possono suggerire un avvelenamento della cache e le tecniche di verifica.

**Risposta:**

```
Sintomi visibili agli utenti:
_______________________________________________________________
_______________________________________________________________

Tecniche di verifica tecnica:
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________

Comandi utili (bash/dig/nslookup):
_______________________________________________________________
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi — Sintomi: reindirizzamento verso siti diversi da quelli attesi, certificati SSL non validi (se MITM), connessioni a IP inaspettati; Verifica: confrontare risposta del resolver interno con resolver esterno fidato (`dig @8.8.8.8` vs `dig @resolver_interno`), controllare il TTL residuo (valori anomali), usare `dig +trace` per seguire la catena di risoluzione.*

---

### F3. Elabora un piano di risposta a un incidente DNS (DNS Incident Response Plan) con almeno 5 passi. `[4 pt]`

**Risposta:**

```
PIANO DI RISPOSTA INCIDENTE DNS

Passo 1 — Rilevamento e Identificazione:
_______________________________________________________________
_______________________________________________________________

Passo 2 — Contenimento:
_______________________________________________________________
_______________________________________________________________

Passo 3 — Analisi:
_______________________________________________________________
_______________________________________________________________

Passo 4 — Ripristino:
_______________________________________________________________
_______________________________________________________________

Passo 5 — Post-Incident e Miglioramento:
_______________________________________________________________
_______________________________________________________________

Passo 6 (bonus):
_______________________________________________________________
_______________________________________________________________
```

*Elementi attesi: 1) Monitoraggio alert / segnalazioni utenti → conferma compromissione; 2) Svuotamento cache DNS (flush), isolamento del resolver compromesso, switch al secondario; 3) Analisi log DNS per identificare record modificati, scope dell'impatto; 4) Ripristino record corretti, aggiornamento TTL, verifica DNSSEC se presente; 5) Review delle misure di sicurezza, patch, documentazione, comunicazione agli stakeholder.*

---

## 📊 Griglia di Valutazione

| Sezione | Punti disponibili | Punti ottenuti |
|---------|-----------------|----------------|
| A — Vulnerabilità del protocollo | 12 | |
| B — Attacchi DNS | 16 | |
| C — DNSSEC | 14 | |
| D — DoH e DoT | 12 | |
| E — Difese pratiche | 14 | |
| F — Scenari e casi reali | 12 | |
| **TOTALE** | **70** | |

**Conversione voto:**

| Punteggio | Voto decimale | Giudizio |
|-----------|--------------|---------|
| 63–70 | 10/10 | Eccellente |
| 56–62 | 9/10 | Ottimo |
| 49–55 | 8/10 | Buono |
| 42–48 | 7/10 | Discreto |
| 35–41 | 6/10 | Sufficiente |
| 28–34 | 5/10 | Quasi suff. |
| < 28 | < 5/10 | Insufficiente |

---

*Nome e Cognome: _________________________________ Classe: _______ Data: ___/___/_____*
