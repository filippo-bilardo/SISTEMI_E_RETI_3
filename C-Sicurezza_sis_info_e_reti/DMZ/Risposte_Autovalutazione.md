# Risposte alle Domande di Autovalutazione

## Capitolo 1 - Introduzione alle DMZ

### Domande a risposta multipla

**1. Qual è lo scopo principale di una DMZ?**  
**Risposta: b) Separare i servizi pubblici dalla rete interna**

La DMZ serve proprio a creare una zona buffer tra Internet e la rete interna, ospitando i servizi che devono essere accessibili dall'esterno ma mantenendoli isolati dalle risorse interne critiche.

**2. Quale principio di sicurezza implementa una DMZ?**  
**Risposta: c) Defense in depth (difesa a strati)**

La DMZ è un'implementazione pratica del principio di defense in depth, creando multiple barriere tra gli attaccanti e le risorse critiche.

**3. Quale tipo di server è tipicamente posizionato in una DMZ?**  
**Risposta: c) Web server pubblico**

I web server pubblici devono essere accessibili da Internet e quindi sono candidati ideali per la DMZ. File server, domain controller e workstation dovrebbero rimanere nella rete interna.

**4. Cosa succede se un server in DMZ viene compromesso?**  
**Risposta: b) Il danno è contenuto alla DMZ grazie all'isolamento**

Questo è il vantaggio principale della DMZ: contenere i danni in caso di compromissione.

**5. Quale standard di conformità richiede la segmentazione della rete per i sistemi di pagamento?**  
**Risposta: b) PCI-DSS**

Il PCI-DSS (Payment Card Industry Data Security Standard) richiede esplicitamente la segmentazione della rete.

---

## Capitolo 2 - Principi di Sicurezza di Rete

### Domande a risposta multipla

**1. Cosa significa "Defense in Depth"?**  
**Risposta: b) Implementare multiple barriere di sicurezza**

Defense in depth significa non affidarsi a un singolo meccanismo di protezione, ma creare più layer difensivi.

**2. Il principio del minimo privilegio implica:**  
**Risposta: b) Dare solo i permessi strettamente necessari**

Ogni entità deve avere solo i permessi minimi richiesti per svolgere le proprie funzioni legittime.

**3. Quale zona ha il livello di fiducia più basso?**  
**Risposta: c) Internet**

Internet è considerato completamente untrusted (non fidato), con livello di fiducia zero.

**4. La policy "Default Deny" significa:**  
**Risposta: b) Negare tutto tranne ciò che è esplicitamente permesso**

Default Deny è il principio fondamentale: bloccare tutto di default e permettere solo il traffico specificatamente autorizzato.

**5. Quale affermazione sul traffico tra zone di fiducia è corretta?**  
**Risposta: a) Il traffico da zona a MAGGIOR fiducia deve essere strettamente controllato**

Il traffico che va da una zona meno fidata verso una più fidata (es. DMZ → LAN) deve essere rigorosamente controllato.

---

## Capitolo 3 - Architetture DMZ

### Domande a risposta multipla

**1. Qual è il principale vantaggio di una DMZ a doppio firewall?**  
**Risposta: c) Offre defense in depth reale**

Due firewall forniscono un vero doppio controllo, implementando correttamente il principio di defense in depth.

**2. Quante interfacce di rete richiede minimo un firewall per implementare una DMZ a singolo firewall?**  
**Risposta: c) 3**

Tre interfacce: WAN (Internet), DMZ, LAN (rete interna).

**3. Quale architettura è più adatta per una grande banca?**  
**Risposta: c) DMZ multiple con firewall ridondanti**

Per criticità e conformità richieste nel settore bancario, sono necessarie DMZ multiple e ridondanza.

**4. Il principale svantaggio del singolo firewall è:**  
**Risposta: b) Single Point of Failure**

Se il firewall unico fallisce, l'intera protezione viene meno.

**5. Le DMZ stratificate (tiered) sono utili per:**  
**Risposta: b) Separare diversi layer applicativi con requisiti diversi**

Permettono di isolare web tier, application tier, e data tier con policy differenziate.

---

## Capitolo 5 - Regole di Firewall per DMZ

### Domande

**1. Perché la policy "default deny" è preferibile a "default allow"?**

**Risposta:**
La policy "default deny" è fondamentale per la sicurezza perché:
- **Principio del minimo privilegio**: permette solo ciò che è strettamente necessario
- **Protezione contro l'ignoto**: blocca automaticamente nuove minacce non ancora identificate
- **Riduce la superficie di attacco**: solo i servizi esplicitamente autorizzati sono accessibili
- **Facilita l'audit**: è più facile verificare cosa è permesso piuttosto che cosa è vietato
- **Errore sicuro**: in caso di errore di configurazione, il sistema tende a bloccare piuttosto che permettere

Con "default allow" invece, tutto è permesso tranne ciò che è esplicitamente bloccato, rendendo molto difficile prevenire accessi non autorizzati.

**2. Qual è la differenza tra connessioni NEW, ESTABLISHED, e RELATED nel connection tracking?**

**Risposta:**
Nel connection tracking dei firewall stateful:

- **NEW**: Prima pacchetto di una nuova connessione. Es: SYN packet in TCP three-way handshake.
  
- **ESTABLISHED**: Connessione già stabilita e con traffico bidirezionale. Es: pacchetti successivi al handshake.
  
- **RELATED**: Nuova connessione correlata a una esistente. Es: FTP data channel aperto da un control channel esistente, o pacchetti ICMP error relativi a una connessione TCP.

Esempio pratico:
```bash
# Permettere connessioni stabilite e correlate (traffico di ritorno)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permettere nuove connessioni HTTP da Internet a web server
iptables -A FORWARD -m state --state NEW -p tcp --dport 80 -d $WEB_SERVER -j ACCEPT
```

**3. Perché è importante limitare il traffico da DMZ verso LAN interna?**

**Risposta:**
Limitare il traffico DMZ → LAN è cruciale perché:

- **Contenimento della compromissione**: Se un server in DMZ viene compromesso, l'attaccante non può facilmente accedere alla rete interna
- **Principio della DMZ**: La DMZ esiste proprio per essere una zona sacrificabile; se non limitiamo il traffico verso LAN, perdiamo questo vantaggio
- **Conformità**: Standard come PCI-DSS richiedono esplicitamente questa separazione
- **Lateral movement prevention**: Previene che un attaccante possa muoversi lateralmente dalla DMZ alla rete interna
- **Minimo privilegio**: I server DMZ dovrebbero accedere SOLO alle risorse interne strettamente necessarie (es. database specifico)

Regola generale: **negare tutto da DMZ a LAN, permettere SOLO connessioni specifiche documentate** (es. web server → database server porta 3306).

**4. Come proteggeresti un web server da attacchi DDoS usando regole firewall?**

**Risposta:**
Multiple tecniche di rate limiting e filtering:

```bash
# 1. Limitare connessioni per IP
iptables -A FORWARD -p tcp --dport 80 -m connlimit \
    --connlimit-above 20 --connlimit-mask 32 -j REJECT

# 2. Limitare SYN packets (protezione SYN flood)
iptables -A FORWARD -p tcp --syn -m limit \
    --limit 1/s --limit-burst 3 -j ACCEPT

# 3. Limitare rate di nuove connessioni
iptables -A FORWARD -p tcp --dport 80 -m state --state NEW \
    -m recent --set --name HTTP
iptables -A FORWARD -p tcp --dport 80 -m state --state NEW \
    -m recent --update --seconds 60 --hitcount 30 --name HTTP -j DROP

# 4. Bloccare invalid packets
iptables -A FORWARD -m state --state INVALID -j DROP

# 5. Protezione contro port scanning
iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP
iptables -A FORWARD -p tcp --tcp-flags ALL ALL -j DROP

# 6. Geographic blocking (se applicabile)
iptables -A FORWARD -m geoip --src-cc CN,RU -j DROP
```

Nota: Il firewall da solo non è sufficiente contro DDoS distribuiti massivi. Servono anche:
- CDN/DDoS protection service (Cloudflare, AWS Shield)
- Rate limiting a livello web server
- Load balancer con health checking

**5. Spiega l'importanza dell'ordine delle regole in un firewall.**

**Risposta:**
L'ordine delle regole è **critico** perché la maggior parte dei firewall applica il principio **first match wins** (prima corrispondenza vince):

**Esempio SBAGLIATO:**
```bash
iptables -A FORWARD -j DROP              # Regola 1: blocca tutto
iptables -A FORWARD -p tcp --dport 80 -j ACCEPT  # Regola 2: mai raggiunta!
```
La regola 2 non sarà mai valutata perché la regola 1 matcha per primo e droppa tutto.

**Esempio CORRETTO:**
```bash
# 1. Drop pacchetti palesemente malevoli
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP

# 2. Permetti traffico stabilito (performance)
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# 3. Permetti traffico legittimo specifico
iptables -A FORWARD -p tcp --dport 80 -d $WEB_SERVER -j ACCEPT
iptables -A FORWARD -p tcp --dport 443 -d $WEB_SERVER -j ACCEPT

# 4. Log e drop tutto il resto (catch-all)
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "FW-DROP: "
iptables -A FORWARD -j DROP
```

**Best practices per l'ordine:**
1. Drop/reject traffico palesemente invalido (top)
2. Allow traffico ESTABLISHED,RELATED (presto, per performance)
3. Allow traffico specifico (dal più specifico al più generico)
4. Log e deny-all finale (catch-all rule alla fine)

---

## Capitolo 6 - Protocolli e Servizi in DMZ

### Domande

**1. Perché HTTPS è preferibile a HTTP?**

**Risposta:**
HTTPS (HTTP over TLS) offre vantaggi fondamentali:

- **Confidenzialità**: Tutto il traffico è crittografato end-to-end. Nessuno può leggere username, password, dati trasmessi.
- **Integrità**: Garantisce che i dati non siano stati modificati in transito.
- **Autenticazione**: Il certificato SSL/TLS verifica l'identità del server (protezione da MITM attacks).
- **SEO e Trust**: Google favorisce siti HTTPS nel ranking. Browser moderni segnalano siti HTTP come "non sicuri".
- **Compliance**: GDPR, PCI-DSS richiedono crittografia dei dati in transito.
- **Protezione da eavesdropping**: Su reti WiFi pubbliche, HTTP è completamente leggibile.

**Oggi HTTP dovrebbe essere usato SOLO per redirect a HTTPS.**

**2. Qual è la differenza tra SFTP e FTPS?**

**Risposta:**

| Caratteristica | SFTP | FTPS |
|----------------|------|------|
| **Protocollo base** | SSH (port 22) | FTP (ports 21, 990, etc.) |
| **Crittografia** | SSH tunnel | SSL/TLS |
| **Complessità firewall** | Semplice (1 porta) | Complessa (multiple porte per passive mode) |
| **Autenticazione** | SSH keys, password | Username/password, certificati |
| **Standard** | SSH File Transfer Protocol | FTP + SSL/TLS |
| **Compatibilità** | Richiede SSH | Più client supportano FTP |

**Raccomandazione**: Preferire **SFTP** per semplicità e migliore supporto firewall.

**3. Quali porte dovrebbero essere usate per SMTP submission con TLS?**

**Risposta:**

- **Porta 587** (SMTP Submission) - **RACCOMANDATO**
  - Porta standard per submission client → server
  - Richiede autenticazione SASL
  - Usa STARTTLS per crittografia opportunistica
  - Definito in RFC 6409

- **Porta 465** (SMTPS)
  - SSL/TLS implicito (connessione SSL dall'inizio)
  - Deprecato in passato, ma ora riabilitato (RFC 8314)
  - Supportato da molti client

- **Porta 25** (SMTP standard)
  - **NON usare per submission client!**
  - Riservata per relay server-to-server
  - Spesso bloccata da ISP per prevenire spam

**Configurazione consigliata:**
```
Port 25: Server-to-server relay (no auth required)
Port 587: Client submission (auth required, STARTTLS)
Port 465: Client submission legacy (implicit TLS)
```

**4. Cos'è DNSSEC e perché è importante?**

**Risposta:**
**DNSSEC** (DNS Security Extensions) aggiunge firma crittografica ai record DNS per garantire integrità e autenticità.

**Problema che risolve:**
DNS standard non ha autenticazione. Un attaccante può:
- **Cache poisoning**: iniettare record DNS falsi nella cache di un resolver
- **MITM**: rispondere a query DNS con risposte false
- **Redirect**: dirottare utenti verso siti malevoli

**Come funziona DNSSEC:**
1. Ogni zona DNS è firmata con chiavi crittografiche (ZSK, KSK)
2. I resolver possono verificare la firma per confermare autenticità
3. Chain of trust dal root DNS fino alla zona specifica

**Vantaggi:**
- ✅ Protezione da cache poisoning
- ✅ Garantisce che la risposta DNS provenga dal server autoritativo
- ✅ Verifica che i dati non siano stati modificati

**Limitazioni:**
- ❌ Non crittografa le query (serve DNS over HTTPS/TLS per quello)
- ❌ Aggiunge overhead computazionale
- ❌ Configurazione complessa

**5. Perché la sincronizzazione NTP è critica in ambienti sicuri?**

**Risposta:**
Time sync preciso è essenziale per:

**1. Logging e Forensics**
- Correlazione eventi tra sistemi multipli
- Timeline accurate per incident response
- Log con timestamp errati sono inutilizzabili per audit

**2. Certificati SSL/TLS**
- Certificati hanno validità basata su data/ora
- Clock sbagliato = certificati validi considerati scaduti o non ancora validi
- Connessioni HTTPS falliscono

**3. Autenticazione time-based**
- **Kerberos**: tolleranza max 5 min di clock skew
- **TOTP** (Google Authenticator): basato su timestamp
- Clock drift = autenticazione fallisce

**4. Compliance e Audit**
- PCI-DSS, HIPAA richiedono timestamp accurati
- Audit trail deve essere provabile in tribunale
- Timestamp imprecisi invalidano le prove

**5. Scheduled tasks**
- Cron jobs, backup, certificate renewal
- Devono eseguire nei momenti corretti

**Best practice:**
- NTP server interni sincronizzati con fonti fidati (pool.ntp.org, GPS)
- Monitoring del clock drift
- Backup NTP sources multiple
- Protezione NTP amplification attacks (restrict access)

---

*Questo documento continua con le risposte per i capitoli rimanenti...*

*(In una guida completa, includere tutte le risposte di tutti i capitoli)*
