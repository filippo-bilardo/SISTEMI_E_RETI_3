# DNS Interno in Reti Aziendali

## Introduzione

Nelle reti aziendali il DNS non si limita a risolvere nomi pubblici come `www.google.com`. Le organizzazioni tipicamente gestiscono anche un **DNS interno** (o privato) che conosce i nomi dei server, stampanti, NAS e servizi presenti nella rete locale. Questo documento spiega come funziona il DNS interno, perché è utile e come configurarlo in ambienti reali e simulati.

---

## DNS Interno vs DNS Pubblico

| Caratteristica | DNS Pubblico | DNS Interno |
|----------------|-------------|-------------|
| **Accessibilità** | Da ovunque su Internet | Solo dalla rete interna (LAN/VPN) |
| **Nomi gestiti** | Nomi registrati su Internet (es. `azienda.it`) | Nomi non pubblici (es. `azienda.local`, `server01.lan`) |
| **Esempi di server** | `8.8.8.8` (Google), `1.1.1.1` (Cloudflare) | Server in `192.168.x.x`, `10.x.x.x` |
| **Chi lo gestisce** | Registrar, ISP, provider DNS | L'azienda stessa |
| **Uso** | Navigazione web, servizi cloud | File server, stampanti, intranet, ERP |

### Quando serve un DNS interno?

Un DNS interno è utile quando:
- Hai server o dispositivi con nomi simbolici da risolvere internamente
- Vuoi che gli utenti usino `\\fileserver` invece di `\\192.168.10.50`
- Vuoi gestire nomi diversi per lo stesso servizio a seconda che l'accesso venga dall'interno o dall'esterno (**split-horizon**)
- Hai ambienti come Active Directory (Windows Server) che richiedono un DNS interno

---

## Domini e Zone Interne

### Scelta del suffisso di dominio

Per i DNS interni si utilizzano suffissi non registrati pubblicamente:

| Suffisso | Uso | Note |
|----------|-----|-------|
| `.local` | Reti piccole, laboratori | Standard comune; in macOS/iOS usato da mDNS — possibili conflitti |
| `.lan` | Reti locali generiche | Non standard ma molto diffuso |
| `.internal` | Reti aziendali | Raccomandato dalla RFC per uso interno |
| `.corp`, `.home`, `.office` | Uso aziendale generico | Evitare se possibile (ICANN ne ha assegnati alcuni) |
| Sottodominio reale | Es. `int.azienda.it` | Approccio più professionale, richiede il controllo del dominio pubblico |

> 💡 La raccomandazione attuale è usare un **sottodominio del proprio dominio registrato** per uso interno (es. `corp.azienda.it`), in modo da evitare conflitti futuri. Tuttavia per i laboratori scolastici `.local` è perfettamente adeguato.

### Struttura di una zona interna

```
Zona: azienda.local

Record A:
  router.azienda.local      → 192.168.1.1
  dns.azienda.local         → 192.168.1.10
  www.azienda.local         → 192.168.1.20
  mail.azienda.local        → 192.168.1.30
  fileserver.azienda.local  → 192.168.1.40
  printer01.azienda.local   → 192.168.1.50
```

---

## Split-Horizon DNS (Split-Brain DNS)

Lo **split-horizon DNS** (o split-brain DNS) è una tecnica per cui lo stesso nome di dominio viene risolto in modo **diverso a seconda da dove viene fatta la query**:

- **Query dall'interno** della rete → l'IP privato del server (es. `10.0.0.5`)
- **Query dall'esterno** di Internet → l'IP pubblico del server (es. `203.0.113.10`)

### Esempio pratico

L'azienda ha un sito web `www.azienda.it`:
- IP pubblico: `203.0.113.10` (raggiungibile da Internet)
- IP privato: `192.168.1.20` (il server fisico nella LAN)

Senza split-horizon, un utente interno che visita `www.azienda.it` deve uscire su Internet e rientrare (hairpinning NAT), il che è inefficiente e spesso non funziona.

Con split-horizon:

```
DNS Interno (solo per client interni):
  www.azienda.it. IN A 192.168.1.20    ← IP privato

DNS Pubblico (per tutti gli altri):
  www.azienda.it. IN A 203.0.113.10    ← IP pubblico
```

```
                    [Internet]
                        |
                  IP: 203.0.113.10
                        |
                   [Firewall/NAT]
                        |
              __________|__________
             |                     |
        [DNS Interno]          [Web Server]
        risponde con           192.168.1.20
        192.168.1.20               |
             |                     |
    [Client Interno] --------------|
    chiede www.azienda.it          |
    ottiene 192.168.1.20 ← raggiunge direttamente
```

### Vantaggi dello Split-Horizon

- ✅ Traffico interno non esce su Internet
- ✅ Latenza ridotta per gli utenti interni
- ✅ Funziona anche quando Internet è down
- ✅ Sicurezza: gli IP interni non sono esposti all'esterno

---

## DNS Forwarding

Il **DNS forwarding** consente a un DNS interno di delegare la risoluzione dei nomi **non presenti nella zona locale** a un altro server DNS (tipicamente un DNS pubblico).

### Senza forwarding

Il DNS interno non conosce `www.google.com` e non può risolverlo → gli utenti non riescono a navigare su Internet.

### Con forwarding

```
Client                DNS Interno           DNS Pubblico
  |                       |                     |
  |--- "Dove è google?" ->|                     |
  |                       |-- "Dove è google?" ->|
  |                       |<-- "142.250.180.x" --|
  |<-- "142.250.180.x" ---|
```

Il DNS interno:
1. Controlla se conosce il nome nella propria zona locale
2. Se sì → risponde direttamente con l'IP interno
3. Se no → inoltra (forward) la query al DNS pubblico configurato
4. Restituisce la risposta al client

### Configurazione forwarding (concetto)

In un DNS reale (es. **BIND9** su Linux):
```
# /etc/named.conf
options {
    forwarders {
        8.8.8.8;       // Google DNS
        1.1.1.1;       // Cloudflare DNS
    };
    forward only;
};
```

In **Windows Server (DNS Manager)**:
- DNS Manager → Properties del server → scheda **Forwarders** → aggiungere gli IP dei DNS pubblici

> 💡 In Cisco Packet Tracer non è possibile configurare il forwarding tramite GUI. Il server DNS in PT risponde solo ai nomi configurati nei suoi record, e non esegue query ricorsive verso Internet.

---

## DNS con Active Directory

Nelle reti Windows con **Active Directory**, il DNS è un componente fondamentale:

- Il domain controller (DC) è anche server DNS
- I record DNS di tipo **SRV** sono usati per localizzare i servizi AD (Kerberos, LDAP)
- Il dominio AD usa tipicamente un nome come `azienda.local` o `azienda.corp`

Esempio di record SRV generati da AD:
```
_ldap._tcp.azienda.local.              SRV   0 100 389  dc01.azienda.local.
_kerberos._tcp.azienda.local.          SRV   0 100 88   dc01.azienda.local.
_gc._tcp.azienda.local.                SRV   0 100 3268 dc01.azienda.local.
```

---

## Zone DNS: Diretta e Inversa

Una zona DNS completa per una rete aziendale include due parti:

### Zona Diretta (Forward Zone)
Traduce nomi → IP. È quella che configuriamo normalmente.
```
Zona: azienda.local
www.azienda.local.    A   192.168.1.20
mail.azienda.local.   A   192.168.1.30
```

### Zona Inversa (Reverse Zone)
Traduce IP → nomi. Necessaria per applicazioni che fanno reverse lookup.
```
Zona: 1.168.192.in-addr.arpa
20.1.168.192.in-addr.arpa.   PTR   www.azienda.local.
30.1.168.192.in-addr.arpa.   PTR   mail.azienda.local.
```

> 💡 In Packet Tracer non è necessario configurare la zona inversa per i test base. Viene usata solo da servizi avanzati.

---

## Ridondanza: DNS Primario e Secondario

Per garantire la continuità del servizio DNS si configurano almeno **due server DNS**:

| Ruolo | Funzione |
|-------|---------|
| **DNS Primario (Master)** | Contiene la copia "originale" della zona. Le modifiche vengono fatte qui. |
| **DNS Secondario (Slave)** | Copia la zona dal primario tramite **zone transfer** (trasferimento di zona). Solo lettura. |

### Zone Transfer

Il DNS secondario si sincronizza con il primario periodicamente:
1. Il secondario controlla il **serial number** nel record SOA del primario
2. Se il serial è aumentato, richiede il trasferimento della zona aggiornata
3. Il trasferimento avviene su **TCP porta 53**

```
DNS Primario           DNS Secondario
     |                       |
     |<--- SOA query --------|   (controllo serial)
     |---- SOA response ---->|
     |                       |   (serial cambiato!)
     |<--- AXFR request -----|   (richiesta trasferimento completo)
     |---- AXFR response --->|
```

**Configurazione client con DNS ridondante:**

| Campo | Valore |
|-------|--------|
| DNS Server preferito | `192.168.1.10` (primario) |
| DNS Server alternativo | `192.168.1.11` (secondario) |

Se il primario non risponde, il client prova automaticamente il secondario.

> 💡 In Packet Tracer la sincronizzazione automatica non è supportata. Configura manualmente gli stessi record su entrambi i server per simulare la ridondanza.

---

## Riepilogo Architettura DNS Aziendale

```
                        Internet
                            |
                    [DNS Pubblico: 8.8.8.8]
                            |
                       [Firewall]
                            |
                    [DNS Interno Primario]
                     192.168.1.10
                    /                \
                   /                  \
          [DNS Interno Secondario]    [Client interni]
           192.168.1.11              192.168.1.100-200

Il DNS Interno:
- Conosce: azienda.local (zona interna)
- Forwarda verso 8.8.8.8: tutto il resto (google.com, youtube.com...)
```
