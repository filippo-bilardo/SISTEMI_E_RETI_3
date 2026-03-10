# 02 — DNSSEC: Autenticazione del DNS

> 🔒 **Guida teorica** | ES03 — Sicurezza DNS  
> Livello: Scuola superiore, 4a/5a anno  
> Prerequisiti: crittografia asimmetrica (chiavi pubblica/privata), firma digitale, PKI

---

## 1. Cos'è DNSSEC e Perché Esiste

### 1.1 Il problema che risolve

Come abbiamo visto nella guida sulle minacce, il DNS classico non ha modo di verificare che una risposta provenga davvero dall'authoritative server legittimo. **DNSSEC** (*DNS Security Extensions*) risolve questo problema aggiungendo **firme digitali** ai record DNS.

### 1.2 Cosa fa DNSSEC

✅ DNSSEC **garantisce**:
- **Autenticità** — la risposta proviene davvero dal detentore della zona DNS
- **Integrità** — i dati non sono stati modificati in transito
- **Prova di non esistenza** — se un dominio non esiste, anche questo fatto è firmato (impossibile falsificare un NXDOMAIN)

### 1.3 Cosa NON fa DNSSEC

❌ DNSSEC **non garantisce**:
- **Riservatezza** — le query DNS rimangono in chiaro (usa DoH/DoT per questo)
- **Disponibilità** — non protegge da attacchi DDoS
- **Sicurezza del canale** — non cifra la comunicazione
- **Sicurezza del contenuto dei siti** — DNSSEC autentica l'indirizzo IP, non il sito web

> 💡 **Analogia**: DNSSEC è come un sigillo d'autenticità su una busta. Puoi verificare che la busta non sia stata aperta e che provenga dal mittente dichiarato, ma il contenuto della busta è comunque leggibile da chiunque la intercetti.

---

## 2. Fondamenti Crittografici

### 2.1 Firma Digitale (ripasso)

DNSSEC usa la **crittografia asimmetrica**:
- Il detentore della zona ha una **chiave privata** (segreta) e una **chiave pubblica** (distribuita)
- I record DNS vengono **firmati** con la chiave privata
- Chiunque può **verificare** la firma usando la chiave pubblica
- È computazionalmente impossibile generare una firma valida senza la chiave privata

Algoritmi supportati da DNSSEC: RSA/SHA-256, RSA/SHA-512, ECDSA/P-256 (raccomandato), Ed25519.

### 2.2 Hash

Le firme DNSSEC coprono un **hash** crittografico del record, non il record stesso. Questo garantisce efficienza (firme piccole) e che qualsiasi modifica al record invalidi la firma.

---

## 3. Le Chiavi DNSSEC: ZSK e KSK

DNSSEC usa **due coppie di chiavi** per ogni zona, per motivi di sicurezza e praticità operativa:

### 3.1 ZSK — Zone Signing Key

| Proprietà | Dettaglio |
|-----------|-----------|
| **Scopo** | Firma i record della zona (A, MX, CNAME, ecc.) |
| **Dimensione** | Tipicamente 1024–2048 bit RSA o 256 bit ECDSA |
| **Rotazione** | Frequente (ogni 1–3 mesi) |
| **Motivo rotazione frequente** | Esposta online, usata spesso → maggior rischio |

### 3.2 KSK — Key Signing Key

| Proprietà | Dettaglio |
|-----------|-----------|
| **Scopo** | Firma **solo** la ZSK (tramite il record DNSKEY) |
| **Dimensione** | Tipicamente 2048–4096 bit RSA o 384 bit ECDSA |
| **Rotazione** | Rara (ogni 1–2 anni) |
| **Motivo rotazione rara** | Hash pubblicato nella zona padre (DS record) → cambiarla richiede coordinazione |

### 3.3 Perché due chiavi?

La separazione serve a limitare il rischio:
- Se la ZSK viene compromessa, si può ruotare senza coinvolgere la zona padre
- La KSK è usata raramente e può essere conservata offline (HSM, Hardware Security Module)
- Un cambiamento della KSK richiede aggiornamento del record DS nella zona padre (operazione più costosa)

---

## 4. I Record DNSSEC

### 4.1 DNSKEY — La Chiave Pubblica

Il record **DNSKEY** pubblica la chiave pubblica della zona. Ce ne sono due: uno per la ZSK e uno per la KSK.

```dns
; Esempio record DNSKEY
example.com.  3600  IN  DNSKEY  256 3 13 (
    base64encodedPublicKey==
)
; 256 = Zone Signing Key (flag 256 = ZSK, 257 = KSK)
; 3   = protocollo DNS
; 13  = algoritmo ECDSA/P-256
```

### 4.2 RRSIG — La Firma Digitale

Il record **RRSIG** (*Resource Record Signature*) contiene la firma digitale per un set di record DNS. Ogni resource record set (RRset) ha il proprio RRSIG.

```dns
; Esempio: firma del record A di www.example.com
www.example.com.  3600  IN  A      93.184.216.34
www.example.com.  3600  IN  RRSIG  A 13 3 3600 (
    20241231000000    ; expiration
    20241201000000    ; inception
    12345             ; key tag (identifica la ZSK usata)
    example.com.      ; signer
    base64Signature== ; firma in Base64
)
```

### 4.3 DS — Delegation Signer

Il record **DS** (*Delegation Signer*) è pubblicato nella **zona padre** e contiene l'hash della KSK della zona figlia. Questo è il "ponte" che costruisce la catena di fiducia.

```dns
; Nella zona .com (zona padre), riferito a example.com:
example.com.  3600  IN  DS  12345 13 2 (
    sha256hashOfKSK==
)
; 12345 = key tag della KSK di example.com
; 13    = algoritmo (ECDSA/P-256)
; 2     = tipo di hash (SHA-256)
```

### 4.4 NSEC e NSEC3 — Prova di Non Esistenza

Il record **NSEC** (*Next Secure*) elenca il prossimo nome nella zona in ordine alfabetico, permettendo di dimostrare crittograficamente che un dominio non esiste.

```dns
; Se qualcuno chiede "esiste alpha.example.com?"
; Il server risponde con il NSEC che mostra che non c'è nulla tra:
a.example.com.   IN  NSEC  z.example.com. A MX RRSIG NSEC
; Firmato: prova che non esiste nulla tra "a" e "z"
```

⚠️ **Problema NSEC**: permette la **zone enumeration** — un attaccante può scoprire tutti i nomi presenti nella zona percorrendo la catena NSEC.

**NSEC3** risolve questo problema usando hash dei nomi invece dei nomi in chiaro:
```dns
; Hash di "a.example.com" → appare nella zona come hash
H(a.example.com).example.com.  IN  NSEC3  ...
```

---

## 5. La Catena di Fiducia

### 5.1 Struttura gerarchica

La catena di fiducia DNSSEC segue la gerarchia del DNS:

```
ROOT ZONE (.)
    │
    ├── DS record per .com
    │
    .com
        │
        ├── DS record per example.com
        │
        example.com
            │
            ├── DNSKEY (ZSK + KSK)
            ├── RRSIG per ogni record
            └── NSEC/NSEC3
```

### 5.2 Trust Anchor

Il punto di partenza della validazione è il **trust anchor** della root zone: la chiave pubblica della root zone (KSK della root) è distribuita con i resolver DNSSEC-aware e aggiornata raramente tramite RFC 5011 (rollover automatico).

La root zone è firmata dal **2010** (root DNSSEC key signing ceremony).

### 5.3 Processo di validazione

Quando un resolver DNSSEC-aware riceve una risposta:

```
1. Riceve record A per www.example.com
2. Riceve RRSIG del record A (firmato con ZSK di example.com)
3. Recupera DNSKEY di example.com (ZSK pubblica)
4. Verifica: la firma RRSIG è valida con questa ZSK? ✅
5. Ma da dove viene la ZSK? Recupera DS di example.com dal .com TLD
6. Verifica: l'hash della KSK corrisponde al DS in .com? ✅
7. Ma .com è fidato? Recupera DS di .com dalla root (.)
8. Verifica: DS di .com corrisponde alla KSK di root? ✅
9. La root è il trust anchor → VALIDAZIONE COMPLETATA ✅
```

Se uno dei link della catena è rotto o mancante → risposta **SERVFAIL** (l'utente non ottiene la risposta).

---

## 6. Come Verificare DNSSEC

### 6.1 Con il comando `dig`

```bash
# Query base con DNSSEC
dig +dnssec www.cloudflare.com

# Query con trace della catena di validazione
dig +trace +dnssec www.cloudflare.com

# Verificare il record DS di un dominio nella zona padre
dig DS cloudflare.com @8.8.8.8

# Verificare le chiavi DNSKEY
dig DNSKEY cloudflare.com

# Controllare la firma (RRSIG)
dig A cloudflare.com +dnssec | grep RRSIG

# Query con validazione DNSSEC abilitata (bit AD = Authentic Data)
dig +dnssec @1.1.1.1 cloudflare.com
# Se nella risposta compare "ad" nei flag, la risposta è DNSSEC-validata
```

**Interpretare l'output**:
```
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2
```
- `ad` = **Authentic Data** — il resolver ha validato con DNSSEC ✅
- Se manca `ad` → il resolver non valida DNSSEC, o la zona non è firmata

### 6.2 Tool online

- **DNSViz** (`dnsviz.net`): visualizzazione grafica della catena di fiducia
- **Verisign DNSSEC Analyzer** (`dnssec-analyzer.verisignlabs.com`)
- **DNSSEC Debugger** di Sandia (`dnssec-debugger.verisignlabs.com`)

### 6.3 Verifica rapida

```bash
# Controlla se un dominio usa DNSSEC
dig +short DS google.com
# Se restituisce qualcosa → DNSSEC abilitato
# Se non restituisce nulla → DNSSEC non configurato

# Verifica che il resolver usi DNSSEC
dig +dnssec sigfail.verteiltesysteme.net
# Questo dominio ha DNSSEC ROTTO di proposito:
# - Un resolver che valida → SERVFAIL (blocca)
# - Un resolver che NON valida → risponde normalmente (pericoloso!)
```

---

## 7. Limitazioni di DNSSEC

### 7.1 Complessità operativa

La gestione di DNSSEC richiede:
- Rotazione periodica delle chiavi (ZSK ogni mese, KSK ogni anno)
- Coordinazione con il registro della zona padre per i DS record
- Monitoraggio della scadenza delle firme (RRSIG ha una data di scadenza)
- Un errore nella rotazione delle chiavi può rendere il dominio irraggiungibile

### 7.2 Aumento delle dimensioni delle risposte

I record RRSIG e DNSKEY aggiungono **centinaia di byte** a ogni risposta DNS. Questo può causare:
- **Frammentazione UDP**: risposte > 512 byte richiedono il fallback a TCP
- Latenza aumentata (TCP più lento di UDP per query singole)
- Possibili problemi con firewall che bloccano UDP frammentato o TCP/53

### 7.3 Zone Enumeration con NSEC

Come descritto, NSEC permette di enumerare tutti i nomi in una zona. NSEC3 mitiga ma non elimina completamente il problema (attacchi offline su hash).

### 7.4 Adozione parziale

DNSSEC è inutile se la catena di fiducia si spezza:
- Se il dominio padre non pubblica il DS della zona figlia → impossibile validare
- Molti TLD e domini non hanno DNSSEC configurato
- Non tutti i resolver validano DNSSEC

**Statistiche di adozione (2024)**: circa il 20–30% dei nomi sotto .com ha DNSSEC; circa il 90% delle zone TLD è firmato; circa il 30–40% delle query viene validato dai resolver.

### 7.5 DNSSEC non cifra

Come sottolineato all'inizio: DNSSEC **non cifra** le query DNS. Le query rimangono in chiaro e intercettabili. Per la riservatezza serve **DoH o DoT** (vedi guida 03).

---

## 8. Configurazione Concettuale

### 8.1 Abilitare DNSSEC su BIND9 (Linux)

```bash
# Generare ZSK
dnssec-keygen -a ECDSAP256SHA256 -b 256 -n ZONE example.com
# Genera: Kexample.com.+013+12345.key e .private

# Generare KSK
dnssec-keygen -a ECDSAP256SHA256 -b 256 -n ZONE -f KSK example.com

# Includere le chiavi nel file di zona
# In /etc/bind/zones/example.com:
# $INCLUDE Kexample.com.+013+12345.key
# $INCLUDE Kexample.com.+013+54321.key   (KSK)

# Firmare la zona
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) \
    -N INCREMENT -o example.com -t example.com.zone

# Riavviare BIND
systemctl restart bind9
```

### 8.2 Abilitare la validazione DNSSEC su BIND9 (resolver)

Nel file `named.conf.options`:
```
options {
    // Abilita validazione DNSSEC
    dnssec-validation auto;  // usa trust anchor automatico
    // oppure:
    // dnssec-validation yes;   // richiede trust anchor manuale
};
```

---

## 9. Best Practices DNSSEC

| Best Practice | Motivazione |
|--------------|-------------|
| Usare **ECDSA P-256** invece di RSA | Chiavi più piccole, stessa sicurezza, risposte più compatte |
| Automatizzare la rotazione ZSK | Riduce il rischio di chiavi compromesse, evita dimenticanze |
| Monitorare la scadenza delle RRSIG | Firma scaduta = dominio irraggiungibile per chi valida |
| Usare un **HSM** per la KSK | Hardware Security Module protegge la chiave più importante |
| Testare con DNSViz prima del deploy | Visualizza la catena di fiducia e rileva errori |
| Implementare **NSEC3** con salt | Protegge dall'enumerazione della zona |
| Mantenere **key rollover** documentato | La procedura di cambio chiave deve essere scritta e testata |
| Abilitare **dnssec-validation** sui resolver | I resolver interni devono validare le risposte DNSSEC |
