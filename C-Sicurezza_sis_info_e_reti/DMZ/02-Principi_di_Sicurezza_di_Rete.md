# Capitolo 2 - Principi di Sicurezza di Rete

## 2.1 Il modello di difesa a strati (Defense in Depth)

Il **Defense in Depth** è una strategia di sicurezza che implementa multiple barriere di protezione, in modo che se una barriera fallisce, le altre possano ancora proteggere la risorsa.

### Origini del concetto
Il termine deriva dalla strategia militare che prevede di rallentare l'avanzata del nemico attraverso linee difensive successive. Applicato alla sicurezza informatica, significa non affidarsi mai a un singolo meccanismo di protezione.

### I layer di difesa in una rete con DMZ

#### Layer 1: Perimetro fisico
- Controllo accessi ai datacenter
- Videosorveglianza
- Sistemi di allarme

#### Layer 2: Perimetro di rete
- Firewall perimetrali
- IDS/IPS
- Anti-DDoS

#### Layer 3: Segmentazione interna (DMZ)
- Separazione tra zone di fiducia
- Firewall interni
- VLAN e ACL

#### Layer 4: Host-level security
- Firewall locali
- Antivirus/antimalware
- Host-based IDS

#### Layer 5: Applicativo
- Web Application Firewall (WAF)
- Input validation
- Autenticazione e autorizzazione

#### Layer 6: Dati
- Crittografia at rest
- Crittografia in transit
- Data Loss Prevention (DLP)

### Implementazione nella DMZ
```
Internet
    ↓
Firewall perimetrale (Layer 1)
    ↓
DMZ - Segmentazione (Layer 2)
    ↓
Host hardening (Layer 3)
    ↓
Application security (Layer 4)
    ↓
Rete interna protetta
```

## 2.2 Principio del minimo privilegio

Il **principio del minimo privilegio** (Least Privilege) stabilisce che ogni utente, processo o sistema deve avere solo i permessi strettamente necessari per svolgere le proprie funzioni legittime.

### Applicazione alle DMZ

#### Regole firewall
- Aprire **solo** le porte necessarie
- Consentire **solo** i protocolli richiesti
- Limitare l'accesso alle **specifiche** sorgenti autorizzate

**Esempio - Web server in DMZ:**
```
# CORRETTO - Minimo privilegio
Permettere: TCP porta 80, 443 da Internet → Web server
Permettere: TCP porta 443 da Web server → Application server interno
Negare: Tutto il resto

# SBAGLIATO - Troppo permissivo
Permettere: Qualsiasi porta da Internet → Web server
Permettere: Qualsiasi connessione da Web server → Rete interna
```

#### Permessi di sistema
- Account di servizio con privilegi minimi
- Nessun accesso root/administrator se non necessario
- Disabilitazione di servizi non utilizzati

#### Accesso ai dati
- Database: read-only quando possibile
- File system: permessi ristretti
- API: autenticazione e autorizzazione granulare

### Best practice
1. **Documentare** ogni eccezione al principio
2. **Rivedere periodicamente** i permessi concessi
3. **Monitorare** l'utilizzo effettivo dei privilegi
4. **Revocare** immediatamente i privilegi non più necessari

## 2.3 Separazione dei compiti e segmentazione

### Separazione dei compiti (Segregation of Duties)

Il principio della **separazione dei compiti** prevede che nessuna singola persona o sistema abbia il controllo completo su un processo critico.

#### Esempi nella gestione DMZ:
- **Configurazione firewall**: una persona configura, un'altra approva
- **Deploy di servizi**: sviluppatori non hanno accesso alla produzione
- **Backup e restore**: ruoli separati per backup e recovery

### Segmentazione di rete

La **segmentazione** divide la rete in zone logiche o fisiche separate, limitando la propagazione di un attacco.

#### Modelli di segmentazione

**Segmentazione a 3 tier:**
```
Internet ←→ DMZ ←→ Rete Interna
```

**Segmentazione a 4 tier:**
```
Internet ←→ DMZ Esterna ←→ DMZ Interna ←→ Rete Interna
```

**Segmentazione per servizio:**
```
Internet
   ↓
Firewall
   ├→ DMZ Web (Web servers)
   ├→ DMZ Mail (Mail servers)
   ├→ DMZ DNS (DNS servers)
   └→ Rete Interna
```

#### VLAN e micro-segmentazione
- **VLAN**: segmentazione a livello 2 (data link)
- **Micro-segmentazione**: controllo granulare del traffico tra workload
- **Software-Defined Networking (SDN)**: segmentazione dinamica

### Vantaggi della segmentazione
1. **Contenimento**: limita l'impatto di una compromissione
2. **Compliance**: soddisfa requisiti normativi
3. **Performance**: riduce il traffico broadcast
4. **Gestione**: semplifica le policy di sicurezza

## 2.4 Zone di fiducia (Trust Zones)

Le **zone di fiducia** classificano le reti in base al livello di sicurezza richiesto e al grado di fiducia che riponiamo in esse.

### Classificazione delle zone

#### Zona non fidata (Untrusted Zone)
- **Internet pubblico**
- **Reti di terze parti non verificate**
- Livello di fiducia: **ZERO**
- Policy: Blocca tutto di default, permetti solo traffico esplicitamente autorizzato

#### DMZ (Low Trust Zone)
- **Servizi pubblici**
- **Proxy e gateway**
- Livello di fiducia: **BASSO**
- Policy: Accesso controllato da/verso Internet e rete interna

#### Rete interna (Trusted Zone)
- **Workstation utenti**
- **Server interni**
- **Database**
- Livello di fiducia: **MEDIO-ALTO**
- Policy: Accesso protetto, nessun accesso diretto da Internet

#### Management Network (Secure Zone)
- **Console amministrative**
- **Backup infrastructure**
- **Monitoring systems**
- Livello di fiducia: **MASSIMO**
- Policy: Accesso ristretto, multi-factor authentication

### Flussi di traffico tra zone

**Regole generali:**
1. Il traffico da zona a **MINOR** fiducia è generalmente permesso
2. Il traffico da zona a **MAGGIOR** fiducia deve essere **strettamente controllato**
3. Il traffico **laterale** (dentro la stessa zona) deve essere valutato caso per caso

**Esempio pratico:**
```
Internet (Untrusted) → DMZ (Low Trust): Permesso con restrizioni
DMZ → Internet: Permesso per aggiornamenti e servizi esterni
DMZ → Rete Interna (Trusted): Molto limitato, solo connessioni specifiche
Rete Interna → DMZ: Permesso per amministrazione
Internet → Rete Interna: NEGATO (deve passare per DMZ o VPN)
```

## 2.5 Best practice di base

### 1. Default Deny
- **Regola base**: negare tutto il traffico non esplicitamente permesso
- Applicare sia in ingresso che in uscita
- Documentare ogni eccezione

### 2. Principio di sicurezza additiva
- Non rimuovere controlli di sicurezza per "velocizzare" le cose
- Ogni nuovo servizio deve rispettare gli standard di sicurezza
- La sicurezza non è negoziabile

### 3. Hardening di sistema
- Disabilitare servizi non necessari
- Applicare patch di sicurezza tempestivamente
- Usare configurazioni sicure di default

### 4. Autenticazione e autorizzazione robuste
- Multi-factor authentication (MFA) per accessi critici
- Password policy stringenti
- Gestione centralizzata delle identità

### 5. Crittografia
- TLS/SSL per traffico web
- SSH per amministrazione remota
- VPN per connessioni site-to-site

### 6. Logging e monitoring
- Log centralizzato
- Monitoring 24/7
- Alert automatici per eventi sospetti
- Retention dei log secondo policy di compliance

### 7. Backup e disaster recovery
- Backup regolari e testati
- Piano di disaster recovery documentato
- Backup off-site o su cloud
- Test periodici di restore

### 8. Security awareness
- Formazione del personale
- Policy di sicurezza chiare e comunicate
- Incident response plan
- Security champion in ogni team

## 2.6 Autovalutazione

### Domande a risposta multipla

**1. Cosa significa "Defense in Depth"?**
- a) Usare password molto complesse
- b) Implementare multiple barriere di sicurezza
- c) Avere un firewall molto costoso
- d) Crittografare tutti i dati

**2. Il principio del minimo privilegio implica:**
- a) Dare accesso di amministratore a tutti
- b) Dare solo i permessi strettamente necessari
- c) Non dare nessun permesso a nessuno
- d) Permettere tutto temporaneamente

**3. Quale zona ha il livello di fiducia più basso?**
- a) Rete interna
- b) DMZ
- c) Internet
- d) Management network

**4. La policy "Default Deny" significa:**
- a) Permettere tutto tranne ciò che è esplicitamente negato
- b) Negare tutto tranne ciò che è esplicitamente permesso
- c) Non configurare nessuna regola
- d) Negare solo il traffico dannoso

**5. Quale affermazione sul traffico tra zone di fiducia è corretta?**
- a) Il traffico da zona a MAGGIOR fiducia deve essere strettamente controllato
- b) Il traffico deve essere sempre permesso in tutte le direzioni
- c) Solo il traffico HTTPS deve essere controllato
- d) Le zone di fiducia non influenzano le regole di traffico

### Domande a risposta aperta

1. Spiega come il principio del Defense in Depth si applica alla progettazione di una DMZ. Fornisci esempi concreti di almeno 4 layer di difesa.

2. Descrivi una situazione in cui il principio del minimo privilegio è stato violato e quali rischi ne derivano. Come risolveresti la situazione?

3. Perché è importante segmentare la rete in multiple DMZ per servizi diversi? Quali vantaggi porta questa approccio?

### Esercizio pratico

**Analisi di configurazione**

Esamina la seguente configurazione firewall e identifica le violazioni dei principi di sicurezza:

```
# Regole Firewall
1. ALLOW ANY from Internet to DMZ
2. ALLOW ANY from DMZ to Internal Network  
3. ALLOW TCP 22 from ANY to DMZ-SSH-Server
4. ALLOW ICMP from ANY to ANY
5. ALLOW TCP 3389 from Internet to Internal-Server
```

Per ogni regola problematica:
- Spiega quale principio di sicurezza viene violato
- Fornisci una versione corretta della regola
- Motiva le tue scelte

---

*[Le risposte alle domande di autovalutazione si trovano nell'appendice del manuale]*
