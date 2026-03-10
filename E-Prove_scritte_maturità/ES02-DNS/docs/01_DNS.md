# DNS — Domain Name System

## Introduzione

Il **DNS (Domain Name System)** è il sistema che consente di tradurre i nomi simbolici degli host (come `www.google.com`) in indirizzi IP (come `142.250.180.46`) e viceversa. È spesso definito come la "rubrica telefonica di Internet": invece di ricordare indirizzi IP numerici, usiamo nomi facili da memorizzare.

Senza DNS ogni applicazione dovrebbe conoscere l'indirizzo IP esatto del servizio che vuole raggiungere. Il DNS rende trasparente questa traduzione, lavorando in background ogni volta che apriamo un browser, inviamo una mail o usiamo qualsiasi altro servizio di rete.

---

## Cos'è il DNS e a Cosa Serve

Il DNS svolge principalmente le seguenti funzioni:

- **Risoluzione diretta**: traduce un nome di dominio (FQDN) in un indirizzo IP
- **Risoluzione inversa**: traduce un indirizzo IP in un nome di dominio
- **Localizzazione dei servizi**: indica quali server gestiscono la posta elettronica (record MX), i nameserver di una zona (record NS), ecc.
- **Distribuzione del carico**: può associare più indirizzi IP a un unico nome (DNS round-robin)

> 💡 **FQDN** (Fully Qualified Domain Name) è il nome completo di un host, es. `mail.azienda.it.` — il punto finale indica la root della gerarchia DNS.

---

## Gerarchia DNS

Il DNS è organizzato come un albero gerarchico distribuito su milioni di server nel mondo.

```
                         . (root)
                         |
    _____________________|_____________________
    |          |         |         |          |
  .com        .it       .org      .net       .edu
    |          |
 google.com  azienda.it
    |              |
mail.google.com  www.azienda.it
```

### Livelli della gerarchia

| Livello | Nome | Esempi | Gestito da |
|---------|------|--------|-----------|
| 0 | Root (`.`) | `.` | IANA / Root Server Operators |
| 1 | TLD (Top-Level Domain) | `.com`, `.it`, `.org`, `.edu` | Registrar nazionali/internazionali |
| 2 | SLD (Second-Level Domain) | `google.com`, `azienda.it` | Singole organizzazioni |
| 3+ | Sottodomini | `www.azienda.it`, `mail.azienda.it` | Singole organizzazioni |

### Root Servers

Esistono 13 gruppi di root server nel mondo (nominati da `a.root-servers.net` a `m.root-servers.net`). In realtà sono centinaia di macchine fisiche distribuite globalmente tramite **anycast**, ma logicamente si comportano come 13.

---

## Processo di Risoluzione DNS

### Attori della risoluzione

| Componente | Ruolo |
|------------|-------|
| **Client/Resolver stub** | Il dispositivo che fa la query (PC, smartphone) |
| **Recursive Resolver** | Server DNS del provider/azienda che esegue le query per conto del client |
| **Root Server** | Conosce i TLD, indirizza verso i server autoritativi del TLD |
| **TLD Name Server** | Conosce i domini del suo TLD, indirizza verso il name server del dominio |
| **Authoritative Name Server** | Conosce tutti i record del dominio specifico, risponde con il dato finale |

### Risoluzione Ricorsiva

Nel processo ricorsivo, il **client fa una sola richiesta** al suo resolver, che si occupa di tutto:

```
Client                Recursive Resolver        Root    .com NS   google.com NS
  |                          |                    |         |           |
  |--- "Dammi l'IP di www.google.com" ---------->|         |           |
  |                          |--- "Chi gestisce .com?" --->|           |
  |                          |<-- "Vai da a.gtld-servers.net" ---------|
  |                          |--- "Chi gestisce google.com?" ---->|    |
  |                          |<-- "Vai da ns1.google.com" --------|    |
  |                          |--- "Qual è l'IP di www.google.com?" --->|
  |                          |<-- "142.250.180.46" ------------------- |
  |<--- "142.250.180.46" ----|
```

### Risoluzione Iterativa

Nel processo iterativo, il **server risponde solo con un riferimento** (punta al prossimo server), e il resolver deve fare le domande da solo:

```
Client               Resolver
  |--- Query "www.google.com" -----> |
  |                                  |--- Query root servers
  |                                  |<-- "Chiedi a .com NS"
  |                                  |--- Query .com NS
  |                                  |<-- "Chiedi a google.com NS"
  |                                  |--- Query google.com NS
  |                                  |<-- "142.250.180.46"
  |<--- "142.250.180.46" ------------|
```

> 💡 In pratica: il client usa la risoluzione **ricorsiva** verso il proprio resolver; il resolver usa la risoluzione **iterativa** verso i server autoritativi.

---

## Tipi di Record DNS

| Tipo | Nome | Funzione | Esempio |
|------|------|---------|---------|
| **A** | Address | Mappa nome → IPv4 | `www.azienda.it. A 93.184.216.34` |
| **AAAA** | IPv6 Address | Mappa nome → IPv6 | `www.azienda.it. AAAA 2606:2800:220:1:248:1893:25c8:1946` |
| **CNAME** | Canonical Name | Alias di un altro nome | `ftp IN CNAME www` |
| **MX** | Mail Exchange | Server di posta per il dominio | `azienda.it. MX 10 mail.azienda.it.` |
| **PTR** | Pointer | Risoluzione inversa IP → nome | `34.216.184.93.in-addr.arpa. PTR www.azienda.it.` |
| **NS** | Name Server | Name server autoritativo per la zona | `azienda.it. NS ns1.azienda.it.` |
| **SOA** | Start of Authority | Record principale di una zona DNS | vedi dettaglio sotto |
| **TXT** | Text | Testo libero (usato per SPF, DKIM, verifica dominio) | `azienda.it. TXT "v=spf1 mx ~all"` |
| **SRV** | Service | Localizzazione di servizi specifici | `_http._tcp.azienda.it. SRV 10 5 80 www.azienda.it.` |

### Record SOA — Dettaglio

Il record SOA (Start of Authority) è presente all'inizio di ogni zona DNS e contiene informazioni amministrative:

```
azienda.it. IN SOA ns1.azienda.it. admin.azienda.it. (
    2024010101  ; Serial number (data + progressivo)
    3600        ; Refresh (ogni quanto il secondario controlla aggiornamenti)
    900         ; Retry (ogni quanto riprova se refresh fallisce)
    604800      ; Expire (dopo quanto il secondario smette di rispondere senza aggiornamento)
    300         ; Minimum TTL
)
```

---

## DNS Interno vs DNS Pubblico

| Caratteristica | DNS Pubblico | DNS Interno |
|----------------|-------------|-------------|
| Accessibilità | Da ovunque su Internet | Solo dalla rete interna |
| Nomi registrati | Sì (es. `azienda.it`) | No (es. `azienda.local`, non registrato) |
| Risolve nomi privati | No | Sì |
| Esempio | `8.8.8.8` (Google DNS) | Server DNS su `192.168.1.10` |
| Uso | Navigazione web pubblica | Risorse interne aziendali |

> 💡 Il suffisso `.local` è una convenzione per i domini DNS interni non routable su Internet. Non richiede registrazione.

---

## Configurazione DNS in Cisco Packet Tracer

### Attivare il servizio DNS su un Server

1. Doppio clic sul **Server**
2. Scheda **Services** → voce **DNS** nel menu laterale sinistro
3. Impostare **DNS Service** su **ON**

### Aggiungere un record A

Nella sezione **Resource Records**:

| Campo | Valore da inserire |
|-------|--------------------|
| **Name** | `www.azienda.local` |
| **Type** | `A Record` |
| **Address** | `192.168.1.20` |

Poi cliccare **Add**.

### Verificare i record inseriti

I record appariranno nella tabella sotto i campi di inserimento. Ogni riga mostra: nome, tipo, indirizzo.

### Impostare il DNS Server sui Client

Per ogni PC in PT:
- Doppio clic → **Desktop** → **IP Configuration**
- Campo **DNS Server**: inserire l'IP del server DNS (es. `192.168.1.10`)

> ⚠️ Senza questa impostazione, il PC non userà il DNS interno anche se è correttamente configurato.

### Tipi di Record supportati in PT

Cisco Packet Tracer (versione 8.x) supporta nella GUI DNS i seguenti tipi:
- **A Record** (IPv4)
- **AAAA Record** (IPv6)
- **CNAME Record** (alias)
- **NS Record** (name server)
- **MX Record** (mail)
- **SOA Record** (solo visualizzazione)

---

## Comandi di Verifica e Troubleshooting

### Dal Prompt dei Comandi (PC in Packet Tracer)

**Verificare la configurazione IP e DNS:**
```
C:\> ipconfig /all
```

Cerca le righe:
```
DNS Servers . . . . . . . . : 192.168.1.10
```

**Testare la risoluzione DNS:**
```
C:\> nslookup www.azienda.local
```

Output atteso:
```
Server:  dns.azienda.local
Address: 192.168.1.10

Name:    www.azienda.local
Address: 192.168.1.20
```

**Ping per nome (verifica risoluzione + raggiungibilità):**
```
C:\> ping www.azienda.local
```

Se nella prima riga appare l'IP tra parentesi quadre, significa che la risoluzione ha avuto successo:
```
Pinging www.azienda.local [192.168.1.20] with 32 bytes of data:
```

**nslookup con server specifico:**
```
C:\> nslookup www.azienda.local 192.168.1.10
```

---

## Best Practices

✅ **Usa sempre nomi di dominio consistenti** per la rete interna (es. sempre `.local` o sempre `.intranet`)

✅ **Imposta il DNS Server su tutti i dispositivi**, compresi i server stessi

✅ **Configura un DNS secondario** per garantire la disponibilità del servizio in caso di guasto

✅ **Usa nomi descrittivi** per i record DNS (es. `mail` invece di `server1`)

✅ **Documenta i record DNS** in una tabella o file di testo aggiornato

⚠️ **Non usare indirizzi IP "a caso"** nei record DNS: devono corrispondere agli IP effettivamente assegnati ai dispositivi

⚠️ **Verifica sempre dopo ogni modifica** con `nslookup` o `ping` per nome

❌ **Non usare nomi già registrati pubblicamente** per il DNS interno (es. non creare `www.google.com` internamente)
