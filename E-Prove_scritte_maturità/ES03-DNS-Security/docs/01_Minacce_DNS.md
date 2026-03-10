# 01 — Minacce al Protocollo DNS

> 🛡️ **Guida teorica** | ES03 — Sicurezza DNS  
> Livello: Scuola superiore, 4a/5a anno  
> Prerequisiti: ES02 (DNS base), TCP/IP, UDP vs TCP

---

## 1. Perché il DNS è Vulnerabile

### 1.1 Il contesto storico

Il DNS fu progettato nel **1983** (RFC 882/883, poi RFC 1034/1035 nel 1987) da Paul Mockapetris in un'epoca in cui Internet era una rete accademica e militare con poche centinaia di host. I progettisti operarono con un assunto fondamentale: **gli utenti della rete sono fidati**.

Questo assunto non regge più. Oggi Internet connette miliardi di dispositivi, molti dei quali controllati da attori malevoli.

### 1.2 Vulnerabilità strutturali del DNS

#### 🔓 Nessuna autenticazione delle risposte
Quando un resolver riceve una risposta DNS, **non ha modo di verificare** che provenga davvero dall'authoritative server legittimo. Chiunque possa inviare un pacchetto UDP con l'IP sorgente corretto e il transaction ID giusto può "vincere la gara" e far accettare una risposta falsa.

#### 🔓 Uso di UDP
Il DNS usa **UDP porta 53** per la maggior parte delle query. UDP è un protocollo *connectionless*:
- Non c'è handshake (come il SYN-SYN/ACK-ACK di TCP)
- Non c'è verifica dell'identità del mittente
- L'**IP spoofing** è banale: si può inviare un pacchetto UDP con qualsiasi IP sorgente

#### 🔓 Transaction ID troppo corto
Ogni query DNS è identificata da un **Transaction ID a 16 bit** (0–65535). Un attaccante che vuole inserire una risposta falsa deve indovinare questo valore: con 65.536 possibilità e un attacco automatizzato, è fattibile in pochi secondi.

#### 🔓 Cache distribuita non verificata
I resolver DNS **memorizzano in cache** le risposte per ridurre il traffico (durata determinata dal TTL). Una risposta falsa viene memorizzata e servita a **tutti i client** di quel resolver per tutta la durata del TTL — potenzialmente ore o giorni.

#### 🔓 Query in chiaro
Le query DNS viaggiano in chiaro su UDP/TCP. Chiunque sia in posizione di intercettare il traffico (ISP, attaccante sulla stessa rete, nodo intermedio) può:
- **Leggere** quali siti visita un utente
- **Modificare** le risposte (man-in-the-middle)
- **Iniettare** risposte false

### 1.3 Riepilogo vulnerabilità

| Vulnerabilità | Causa | Conseguenza |
|--------------|-------|-------------|
| No autenticazione | Design originale | Risposte false accettate |
| UDP senza connessione | Design originale | IP spoofing, forgery |
| Transaction ID 16 bit | Design originale | Brute-force dell'ID |
| Cache condivisa | Ottimizzazione prestazioni | Avvelenamento scalabile |
| Query in chiaro | No cifratura | Intercettazione, modifica |

---

## 2. DNS Cache Poisoning

### 2.1 Definizione

Il **DNS cache poisoning** (avvelenamento della cache DNS) è un attacco in cui un agente malevolo inserisce record DNS falsi nella cache di un resolver. Tutti i client che usano quel resolver verranno reindirizzati verso destinazioni errate finché il record rimane in cache (fino alla scadenza del TTL).

### 2.2 Meccanismo passo per passo

```
1. Client → Resolver:  "Qual è l'IP di www.banca.it?"
2. Resolver → Root NS: query iterativa
3. Root NS → Resolver: "chiedi a .it TLD"
4. Resolver → .it TLD: "Qual è il NS di banca.it?"
5. .it TLD → Resolver:  "ns1.banca.it" (IP autentico)

   [in questo momento l'attaccante interviene]

6. Resolver → ns1.banca.it: "Qual è l'IP di www.banca.it?"
7. ATTACCANTE → Resolver: risposta falsa con IP malevolo
                          (prima della risposta legittima)
8. Resolver: accetta la risposta falsa (ID giusto!) → la mette in cache
9. Client ← Resolver:  IP falso (es. 10.0.0.99)
10. Client si connette a 10.0.0.99 (sito phishing)
```

### 2.3 L'attacco di Kaminsky (2008)

Nel luglio 2008, il ricercatore **Dan Kaminsky** rivelò una vulnerabilità critica nel DNS, oggi nota come **Kaminsky Attack**.

**Il problema**: gli attaccanti potevano avvelenare non solo il record richiesto, ma l'**intera zona** del resolver, iniettando record fasulli per l'authoritative nameserver stesso.

**Il meccanismo**:
1. L'attaccante invia in loop migliaia di query per subdomain casuali (es. `random1234.banca.it`, `random5678.banca.it`...)
2. Per ogni query, invia centinaia di risposte fasulle con ID diversi, sperando di indovinare quello corretto
3. Nelle risposte false include anche un record "Additional" per `ns1.banca.it` con IP malevolo
4. Quando indovina l'ID giusto, il resolver memorizza il nameserver falso per tutta la zona

**Impatto**: praticamente **ogni resolver DNS** su Internet era vulnerabile. La patch d'emergenza fu la **randomizzazione della source port** (aggiungendo 16 bit di entropia all'ID effettivo: 16+16 = 32 bit da indovinare). La soluzione definitiva è DNSSEC.

> ⚠️ La vulnerabilità fu mantenuta segreta per mesi mentre i vendor sviluppavano patch coordinate per tutti i sistemi operativi e i resolver DNS contemporaneamente — uno dei più grandi sforzi coordinati di patch management della storia.

---

## 3. DNS Spoofing

### 3.1 Differenza con il Cache Poisoning

Spesso i termini **DNS spoofing** e **DNS cache poisoning** sono usati in modo intercambiabile, ma c'è una distinzione:

| | DNS Spoofing | DNS Cache Poisoning |
|--|-------------|---------------------|
| **Target** | Singolo client o singola query | Cache del resolver (impatto su tutti i client) |
| **Metodo** | Intercettazione + risposta falsa (MITM) | Iniezione in cache del resolver |
| **Persistenza** | Solo per quella query | Fino a scadenza TTL (ore/giorni) |
| **Posizionamento** | Serve accesso al percorso rete | Basta poter inviare pacchetti UDP al resolver |

### 3.2 DNS Spoofing via Man-in-the-Middle

In una rete locale, un attaccante può usare tecniche come **ARP poisoning** per intercettare il traffico tra il client e il resolver, quindi:
1. Intercetta la query DNS del client
2. Invia una risposta falsa prima che arrivi quella legittima
3. Il client usa l'IP falso

Strumenti comunemente usati in test di penetrazione (esclusivamente in ambienti autorizzati): Ettercap, Bettercap, dnsspoof.

---

## 4. DNS Hijacking

### 4.1 Definizione

Il **DNS hijacking** (dirottamento DNS) avviene quando un attaccante modifica la configurazione DNS del client o del router in modo persistente. A differenza del cache poisoning, non richiede di "vincere una gara": la modifica è permanente finché non viene corretta.

### 4.2 Hijacking Locale (sul client)

**Metodo**: malware installato sul PC modifica le impostazioni DNS del sistema operativo o il file `hosts`.

**File hosts** (`C:\Windows\System32\drivers\etc\hosts` su Windows, `/etc/hosts` su Linux):
```
# Esempio di modifica malevola nel file hosts
192.168.1.200    www.banca.it
192.168.1.200    paypal.com
192.168.1.200    google.com
```
Il file hosts ha **priorità massima** rispetto al DNS: qualsiasi IP elencato qui viene usato senza consultare il DNS.

**Sintomo**: solo quel PC è affetto; gli altri computer della rete funzionano normalmente.

### 4.3 Hijacking Remoto (sul router)

**Metodo**: l'attaccante compromette il router (tramite vulnerabilità firmware, credenziali default, UPnP) e modifica i server DNS distribuiti via DHCP a tutti i client.

**Esempio reale**: nel 2018 e 2019, attacchi diffusi a **router domestici** di vari brand (D-Link, TP-Link, Asus, Linksys) cambiarono il DNS DHCP per reindirizzare le query verso resolver malevoli che servivano pagine di phishing bancario. Milioni di utenti furono colpiti in tutto il mondo.

**Sintomo**: tutti i dispositivi della rete sono affetti; il problema persiste dopo il reboot dei client.

### 4.4 Hijacking a Livello ISP

**Metodo**: l'ISP stesso modifica le risposte DNS dei propri utenti, reindirizzando i domini richiesti verso le proprie pagine (pubblicità, censura, sequestri giudiziari).

**Esempi legittimi**: sequestro giudiziario di siti pirata (il DNS restituisce la pagina della Polizia Postale).  
**Esempi problematici**: alcuni ISP reindirizzavano NXDOMAIN (dominio inesistente) verso pagine pubblicitarie invece di restituire un errore.

---

## 5. DNS Amplification / Reflection DDoS

### 5.1 Cos'è un attacco DDoS tramite DNS

Il **DNS Amplification Attack** sfrutta due proprietà:
1. **Reflection**: IP spoofing per far rispondere i resolver alla vittima invece che all'attaccante
2. **Amplification**: le risposte DNS possono essere molto più grandi delle query

### 5.2 Meccanismo

```
ATTACCANTE                    OPEN RESOLVER           VITTIMA
    |                              |                     |
    |-- Query DNS (IP src: VITTIMA) -->                  |
    |   (es. ANY isc.org?)         |                     |
    |                              |-- Risposta (3000B) ->|
    |                              |-- Risposta (3000B) ->|
    |                              |-- Risposta (3000B) ->|
    |   [continua con botnet]      |   [×1000 resolver]   |
    |                              |                     |
    |                              |              [SATURAZIONE]
```

### 5.3 Fattore di amplificazione

Il query DNS per il record `ANY` di un dominio con molti record può essere molto piccola (60 byte) e generare una risposta di 3000+ byte:

```
Amplification Factor = dimensione_risposta / dimensione_query
Esempio: 3000 / 60 = 50x
```

Tipi di query ad alto amplification factor:
| Query Type | Query size | Response size | Factor |
|-----------|-----------|--------------|--------|
| ANY | ~42 byte | 2000–4000 byte | ~70x |
| TXT (lunga) | ~45 byte | 500–1000 byte | ~20x |
| DNSKEY (DNSSEC) | ~45 byte | 1000–2000 byte | ~40x |

### 5.4 Open Resolver: il problema

Un **open resolver** è un server DNS che risponde a query ricorsive da qualsiasi indirizzo IP su Internet. Questo è il requisito fondamentale per essere sfruttati come amplificatori.

Strumenti come il [Open Resolver Project](https://openresolverproject.org/) monitorano quanti resolver aperti esistono su Internet. Sono stati rilevati decine di milioni di open resolver nel mondo.

---

## 6. DNS Tunneling

### 6.1 Cos'è

Il **DNS tunneling** è una tecnica che utilizza il protocollo DNS per **trasmettere dati arbitrari** codificandoli nei nomi di dominio delle query e nelle risposte. Poiché il traffico DNS è quasi sempre permesso dai firewall aziendali (le aziende hanno bisogno di risolvere nomi!), questo canale è difficile da bloccare.

### 6.2 Come funziona

**Codifica dei dati in query DNS**:
```
# Dati da inviare: "ciao_mondo"
# Codificati in Base64: "Y2lhb19tb25kbw=="
# Query DNS: Y2lhb19tb25kbw==.tunnel.attacker.com

# Il server DNS dell'attaccante riceve la query e decodifica i dati
# La risposta (TXT, CNAME, A) contiene i dati di risposta codificati
```

**Schema di comunicazione**:
```
CLIENT (malware)          FIREWALL        DNS RESOLVER    ATTACKER SERVER
     |                       |                 |                |
     |-- DNS query: data.x.evil.com -->        |                |
     |                       |-- DNS query: ----------------->  |
     |                       |                 |     decodifica |
     |                       |<-- DNS resp: encode -----------  |
     |<-- DNS resp: data ----                  |                |
```

### 6.3 Tool noti

- **iodine**: tunneling completo TCP/IP su DNS, crea una interfaccia di rete virtuale
- **dnscat2**: shell remota cifrata su DNS, usato per C2 (command and control) di malware
- **dns2tcp**: tunneling TCP tramite DNS

### 6.4 Rilevamento

Indicatori di DNS tunneling:
- Subdomain molto lunghi e con alta entropia (caratteri casuali)
- Alto volume di query DNS verso lo stesso dominio
- Record TXT o NULL insoliti nelle risposte
- Trasferimento dati insolito su porta 53

---

## 7. Altri Attacchi DNS

### 7.1 Phantom Domain Attack

L'attaccante crea molti **domini fantasma** che non rispondono o rispondono lentamente alle query. Il resolver, attendendo le risposte, esaurisce le sue connessioni disponibili e diventa irresponsivo per i client legittimi.

### 7.2 NXDOMAIN Attack

Bombardamento del resolver con query per **domini inesistenti** (NXDOMAIN responses). Il resolver deve comunque fare il lavoro di risoluzione completa prima di rispondere NXDOMAIN, causando sovraccarico.

### 7.3 Random Subdomain Attack (Water Torture)

Variante del NXDOMAIN attack: query per subdomain casuali di un dominio legittimo (es. `aaaa1234.google.com`, `bbbx5678.google.com`). Tenta di sovraccaricare sia il resolver che l'authoritative server del dominio vittima.

---

## 8. Tabella Riassuntiva degli Attacchi

| Attacco | Meccanismo | Impatto | Difficoltà difesa | Contromisura principale |
|---------|-----------|---------|------------------|------------------------|
| **Cache Poisoning** | Iniezione risposta falsa in cache resolver | Tutti i client del resolver reindirizzati | Alta | DNSSEC, source port randomization |
| **DNS Spoofing** | MITM intercetta e sostituisce risposta | Singolo client reindirizzato | Media | DNSSEC, HTTPS (cert validation) |
| **DNS Hijacking** | Modifica configurazione DNS persistente | Intera rete o singolo host | Bassa (rilevamento) | Monitoraggio, hardening router |
| **Amplification DDoS** | Open resolver amplifica traffico verso vittima | DDoS volumetrico | Media | RRL, closed resolver, BCP38 |
| **DNS Tunneling** | Dati codificati nelle query DNS | Esfiltrazione dati, C2 malware | Alta | DNS inspection, anomaly detection |
| **Phantom Domain** | Domini lenti esauriscono connessioni resolver | Resolver irresponsivo | Media | Timeout aggressivi, rate limiting |
| **NXDOMAIN Attack** | Query per domini inesistenti | Overhead resolver | Media | RRL, filtering |
| **Random Subdomain** | Subdomain casuali su dominio legittimo | Sovraccarico resolver e authNS | Media | RRL, anycast, ACL |

---

## 9. Risorse di Approfondimento

- RFC 1034/1035 — Domain Names (il DNS originale)
- RFC 4033/4034/4035 — DNSSEC
- [Kaminsky Attack (2008)](https://www.blackhat.com/presentations/bh-jp-08/bh-jp-08-Kaminsky/BlackHat-Japan-08-Kaminsky-DNS08-Japan.pdf) — presentazione originale
- CVE-2008-1447 — vulnerabilità Kaminsky
- OWASP: DNS Security Cheat Sheet
