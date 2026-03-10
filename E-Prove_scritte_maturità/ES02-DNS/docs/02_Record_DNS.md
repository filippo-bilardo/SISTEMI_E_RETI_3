# Tipi di Record DNS — Guida Dettagliata

## Introduzione

I **record DNS** (o *Resource Records*, RR) sono le voci che compongono il database di una zona DNS. Ogni record ha un tipo specifico che indica la natura dell'informazione contenuta. Conoscere i tipi di record è fondamentale per configurare correttamente un server DNS e diagnosticare problemi.

### Struttura di un record DNS

```
<nome>   <TTL>   <classe>   <tipo>   <valore>
```

Esempio:
```
www.azienda.it.   3600   IN   A   93.184.216.34
```

| Campo | Significato |
|-------|------------|
| `www.azienda.it.` | Nome FQDN (il punto finale indica la root) |
| `3600` | TTL in secondi (quanto a lungo è valido nella cache) |
| `IN` | Classe Internet (praticamente sempre `IN`) |
| `A` | Tipo di record |
| `93.184.216.34` | Dato/valore del record |

---

## Record A — IPv4 Address

**Funzione:** Mappa un nome simbolico a un indirizzo IPv4.

**Sintassi:**
```
<nome>   IN   A   <indirizzo-IPv4>
```

**Esempi:**
```
www.azienda.it.      IN   A   93.184.216.34
mail.azienda.it.     IN   A   93.184.216.35
ftp.azienda.it.      IN   A   93.184.216.36
```

**Casi d'uso:**
- Associare un nome a un server web
- Creare record per ogni host con nome simbolico nella rete
- DNS Round-Robin: associare più IP allo stesso nome per bilanciare il carico

**DNS Round-Robin:**
```
www.azienda.it.   IN   A   10.0.0.1
www.azienda.it.   IN   A   10.0.0.2
www.azienda.it.   IN   A   10.0.0.3
```

In questo caso il resolver risponde con gli IP in ordine rotante, distribuendo le connessioni.

> ⚠️ In Packet Tracer, il Record A è il tipo più comunemente usato e l'unico indispensabile per le esercitazioni base.

---

## Record AAAA — IPv6 Address

**Funzione:** Come il record A, ma per indirizzi **IPv6** (128 bit invece di 32).

**Sintassi:**
```
<nome>   IN   AAAA   <indirizzo-IPv6>
```

**Esempi:**
```
www.azienda.it.   IN   AAAA   2606:2800:220:1:248:1893:25c8:1946
mail.azienda.it.  IN   AAAA   2001:db8::1
```

**Note:**
- Spesso configurato insieme al record A per supportare sia IPv4 che IPv6 (dual-stack)
- Gli indirizzi che iniziano con `2001:db8::` sono riservati alla documentazione (RFC 3849)

---

## Record CNAME — Canonical Name (Alias)

**Funzione:** Crea un alias (nome alternativo) che punta a un altro nome canonico.

**Sintassi:**
```
<alias>   IN   CNAME   <nome-canonico>
```

**Esempi:**
```
ftp.azienda.it.      IN   CNAME   www.azienda.it.
webmail.azienda.it.  IN   CNAME   mail.azienda.it.
blog.azienda.it.     IN   CNAME   www.azienda.it.
```

**Come funziona:**
Quando un client richiede `ftp.azienda.it`, il server risponde con "questo è un alias per `www.azienda.it`", e il client deve poi risolvere `www.azienda.it` separatamente.

**Vantaggi:**
- Se cambi l'IP del server, aggiorni solo il record A di `www` e tutti gli alias si aggiornano automaticamente
- Permette di avere più nomi che puntano allo stesso host

**Limitazioni:**
- ❌ Un CNAME **non può** coesistere con altri record sullo stesso nome (tranne NS e SOA)
- ❌ Un CNAME **non può** puntare a un altro CNAME (catene di CNAME da evitare)
- ❌ Il record apex del dominio (`azienda.it.` senza sottodominio) **non può** essere un CNAME

---

## Record MX — Mail Exchanger

**Funzione:** Indica il server di posta responsabile della ricezione delle email per un dominio.

**Sintassi:**
```
<dominio>   IN   MX   <priorità>   <hostname-server-mail>
```

**Esempi:**
```
azienda.it.   IN   MX   10   mail.azienda.it.
azienda.it.   IN   MX   20   mail2.azienda.it.
azienda.it.   IN   MX   30   mail3.azienda.it.
```

**Priorità:**
- Il valore numerico indica la priorità: **il numero più basso ha la priorità più alta**
- Se il server con priorità 10 non risponde, si prova con quello a priorità 20, poi 30, ecc.
- Permette la **ridondanza** del servizio di posta

**Come funziona:**
Quando il server di posta di `mittente.com` deve consegnare un'email a `utente@azienda.it`:
1. Fa una query DNS per il record MX di `azienda.it`
2. Ottiene la lista dei server mail con le loro priorità
3. Si connette al server con priorità più alta (numero più basso)

> ⚠️ Il record MX deve puntare a un **hostname** (che ha un record A), **non direttamente a un indirizzo IP**.

---

## Record PTR — Pointer (Risoluzione Inversa)

**Funzione:** Traduce un indirizzo IP in un nome di dominio (operazione inversa rispetto al record A).

**Sintassi:**
```
<IP-invertito>.in-addr.arpa.   IN   PTR   <nome-host>
```

**Esempi:**

Per l'IP `93.184.216.34` che corrisponde a `www.azienda.it`:
```
34.216.184.93.in-addr.arpa.   IN   PTR   www.azienda.it.
```

> 💡 L'IP viene **invertito** nella notazione PTR: `93.184.216.34` diventa `34.216.184.93.in-addr.arpa.`

**Zona DNS per la risoluzione inversa:**
La zona è nella forma `<network-invertito>.in-addr.arpa`. Per la rete `192.168.1.0/24`:
```
Zona: 1.168.192.in-addr.arpa

10.1.168.192.in-addr.arpa.   IN   PTR   server-dns.azienda.local.
20.1.168.192.in-addr.arpa.   IN   PTR   www.azienda.local.
```

**Utilizzi pratici:**
- Verifica anti-spam nei server di posta (molti rifiutano email da IP senza PTR)
- Logging leggibile: i log mostrano nomi invece di IP
- Autenticazione e sicurezza

---

## Record NS — Name Server

**Funzione:** Indica i nameserver autoritativi per una zona DNS.

**Sintassi:**
```
<zona>   IN   NS   <nameserver-hostname>
```

**Esempi:**
```
azienda.it.   IN   NS   ns1.azienda.it.
azienda.it.   IN   NS   ns2.azienda.it.
```

**Note:**
- Ogni zona deve avere **almeno 2 record NS** per ridondanza
- I nameserver elencati sono quelli **autoritativi** per la zona
- I record NS sono fondamentali per la delegazione DNS (sottodomini)

**Delegazione di sottodominio:**
```
! Nella zona azienda.it:
dev.azienda.it.   IN   NS   ns1.dev.azienda.it.
dev.azienda.it.   IN   NS   ns2.dev.azienda.it.

! Glue records (necessari per evitare dipendenza circolare):
ns1.dev.azienda.it.   IN   A   10.0.1.1
ns2.dev.azienda.it.   IN   A   10.0.1.2
```

---

## Record SOA — Start of Authority

**Funzione:** Primo record di ogni zona DNS, contiene informazioni amministrative sulla zona.

**Sintassi completa:**
```
azienda.it.   IN   SOA   ns1.azienda.it.   admin.azienda.it. (
    2024011501   ; Serial: versione del file di zona (formato YYYYMMDDNN)
    3600         ; Refresh: ogni quanto il secondario controlla aggiornamenti (secondi)
    900          ; Retry: ogni quanto riprova se il refresh fallisce
    604800       ; Expire: dopo quanto il secondario considera i dati scaduti (7 giorni)
    300          ; Minimum TTL: TTL minimo per i record negativi (NXDOMAIN)
)
```

| Campo | Descrizione |
|-------|-------------|
| `ns1.azienda.it.` | Primary Name Server della zona |
| `admin.azienda.it.` | Email del responsabile (la prima `.` = `@`) → `admin@azienda.it` |
| Serial | Numero di versione; va incrementato ad ogni modifica |
| Refresh | Frequenza con cui il DNS secondario controlla aggiornamenti |
| Retry | Intervallo tra tentativi in caso di errore nel refresh |
| Expire | Dopo questo tempo il secondario smette di rispondere |
| Minimum TTL | Durata minima dei record nella cache, specialmente per risposte negative |

---

## Record TXT — Text

**Funzione:** Contiene testo libero associato a un nome di dominio. Usato per vari scopi di configurazione e verifica.

**Sintassi:**
```
<nome>   IN   TXT   "<testo>"
```

**Utilizzi comuni:**

**SPF (Sender Policy Framework)** — indica quali server possono inviare email per il dominio:
```
azienda.it.   IN   TXT   "v=spf1 mx ip4:93.184.216.0/24 ~all"
```

**DKIM** — chiave pubblica per la firma delle email:
```
default._domainkey.azienda.it.   IN   TXT   "v=DKIM1; k=rsa; p=MIGfMA0GCSq..."
```

**Verifica del dominio** (es. Google Search Console, Azure AD):
```
azienda.it.   IN   TXT   "google-site-verification=abc123xyz"
```

---

## Record SRV — Service Locator

**Funzione:** Indica dove si trova un servizio specifico (porta, protocollo, host).

**Sintassi:**
```
_servizio._protocollo.dominio.   IN   SRV   <priorità> <peso> <porta> <target>
```

**Esempi:**
```
_sip._tcp.azienda.it.    IN   SRV   10 20 5060 sip.azienda.it.
_ldap._tcp.azienda.it.   IN   SRV   0  0  389  ldap.azienda.it.
_http._tcp.azienda.it.   IN   SRV   0  0  80   www.azienda.it.
```

---

## Riepilogo Comparativo

| Tipo | Da → A | Esempio |
|------|---------|---------|
| A | nome → IPv4 | `www.azienda.it → 93.184.216.34` |
| AAAA | nome → IPv6 | `www.azienda.it → 2606:2800:...` |
| CNAME | alias → nome canonico | `ftp → www.azienda.it` |
| MX | dominio → server mail | `azienda.it → mail.azienda.it (prio 10)` |
| PTR | IPv4 → nome (inverso) | `34.216.184.93.in-addr.arpa → www.azienda.it` |
| NS | zona → nameserver | `azienda.it → ns1.azienda.it` |
| SOA | zona → info amm. | parametri refresh, serial, admin |
| TXT | nome → testo | SPF, DKIM, verifica dominio |
| SRV | servizio → host:porta | `_sip._tcp → sip.azienda.it:5060` |

---

## Record DNS in Packet Tracer

In Cisco Packet Tracer la GUI del server DNS supporta i seguenti tipi tramite menu a tendina:

| Tipo in PT | Corrisponde a |
|-----------|---------------|
| `A Record` | Record A (IPv4) |
| `AAAA Record` | Record AAAA (IPv6) |
| `CNAME Record` | Record CNAME (alias) |
| `NS Record` | Record NS |
| `MX Record` | Record MX |
| `SOA Record` | Record SOA (visualizzazione) |

> 💡 Per l'esercitazione di base è sufficiente lavorare con i record **A**. Per scenari avanzati si possono aggiungere CNAME e MX direttamente dalla GUI.
