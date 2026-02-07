# Capitolo 3 - Architetture DMZ

## 3.1 DMZ a singolo firewall (screened subnet)

### Descrizione
L'architettura a **singolo firewall** utilizza un unico dispositivo firewall con almeno tre interfacce di rete:
- **Interfaccia esterna**: collegata a Internet
- **Interfaccia DMZ**: collegata alla rete demilitarizzata
- **Interfaccia interna**: collegata alla LAN aziendale

### Diagramma
```
            Internet
                |
            [Router]
                |
         [Firewall 3-port]
           /    |    \
          /     |     \
    Internet   DMZ   LAN Interna
```

### Vantaggi
✅ **Costo contenuto**: richiede un solo firewall  
✅ **Gestione semplificata**: un unico punto di configurazione  
✅ **Adatta per piccole/medie realtà**: sufficiente per organizzazioni con esigenze moderate  

### Svantaggi
❌ **Single Point of Failure**: se il firewall fallisce, tutto il sistema è compromesso  
❌ **Rischio elevato**: un errore di configurazione può esporre la rete interna  
❌ **Performance**: tutto il traffico passa per un unico dispositivo  
❌ **Meno sicura**: compromissione del firewall = accesso completo  

### Quando usarla
- Piccole organizzazioni con budget limitato
- Ambiente di test o sviluppo
- Basso volume di traffico
- Requisiti di sicurezza non critici

### Esempio di configurazione base
```
# Interfacce firewall
eth0: Internet (Untrusted) - 203.0.113.1/24
eth1: DMZ (Low Trust) - 192.168.100.1/24
eth2: LAN (Trusted) - 10.0.0.1/24

# Regole base
# Permettere accesso web alla DMZ
ALLOW TCP 80,443 from Internet to DMZ-Web-Server

# Permettere DMZ a contattare DB interno (esempio app)  
ALLOW TCP 3306 from DMZ-App-Server to Internal-DB-Server

# Negare tutto il resto da DMZ verso interno
DENY ALL from DMZ to LAN

# Permettere amministrazione da LAN a DMZ
ALLOW TCP 22 from LAN-Admin to DMZ
```

## 3.2 DMZ a doppio firewall (back-to-back)

### Descrizione
L'architettura **back-to-back** utilizza **due firewall distinti**:
- **Firewall esterno (Front-end)**: filtra il traffico tra Internet e DMZ
- **Firewall interno (Back-end)**: filtra il traffico tra DMZ e rete interna

### Diagramma
```
        Internet
            |
     [Firewall esterno]
            |
    ========DMZ========
    [ Web ] [ Mail ]
    ========DMZ========
            |
     [Firewall interno]
            |
       LAN Interna
```

### Vantaggi
✅ **Sicurezza elevata**: doppio controllo del traffico  
✅ **Defense in Depth**: implementa realmente la difesa a strati  
✅ **Segregazione**: può usare vendor diversi per maggiore sicurezza  
✅ **Flessibilità**: policy differenziate su ciascun firewall  
✅ **Ridondanza**: possibile configurare HA su entrambi i firewall  

### Svantaggi
❌ **Costo doppio**: serve acquistare due firewall  
❌ **Gestione complessa**: due configurazioni da mantenere allineate  
❌ **Latenza**: il traffico attraversa due dispositivi  
❌ **Troubleshooting**: più difficile identificare problemi  

### Quando usarla
- Organizzazioni enterprise con requisiti di sicurezza elevati
- Conformità PCI-DSS, HIPAA, o altre normative stringenti
- Protezione di dati critici o sensibili
- Alta disponibilità richiesta

### Esempio di configurazione

**Firewall esterno:**
```
# Obiettivo: proteggere DMZ da Internet

# Web server pubblico
ALLOW TCP 80,443 from Internet to DMZ-Web-Server

# Mail server
ALLOW TCP 25 from Internet to DMZ-Mail-Server
ALLOW TCP 587,993 from Internet to DMZ-Mail-Server

# DNS pubblico
ALLOW UDP 53 from Internet to DMZ-DNS-Server

# NEGARE connessioni dirette verso LAN interna
DENY ALL from Internet to Internal-Network

# Log e monitor tutto il traffico
LOG ALL
```

**Firewall interno:**
```
# Obiettivo: proteggere LAN interna da DMZ

# Web server può accedere al database
ALLOW TCP 3306 from DMZ-Web-Server to Internal-DB-Server

# Mail relay verso mail server interno
ALLOW TCP 25 from DMZ-Mail-Server to Internal-Mail-Server

# Amministrazione da LAN a DMZ
ALLOW TCP 22 from Admin-Workstation to DMZ

# NEGARE tutto il resto
DENY ALL from DMZ to Internal-Network

# Log tutto
LOG ALL
```

## 3.3 DMZ a tre interfacce

### Descrizione
Simile al modello a singolo firewall, ma con firewall enterprise di classe superiore che supportano policy più complesse e throughput elevato.

### Caratteristiche distintive
- Firewall di nuova generazione (NGFW)
- Deep packet inspection
- Application-level filtering
- IPS integrato
- URL filtering
- Antimalware gateway

### Diagramma
```
              Internet
                  |
        [NGFW - 3 interfacce]
         /       |        \
        /        |         \
   Internet    DMZ-1      DMZ-2
    (WAN)    (Servers)  (Services)
                  |
             LAN Interna
```

### Vantaggi vs singolo firewall base
✅ **Performance**: hardware enterprise dedicato  
✅ **Funzionalità avanzate**: IPS, antivirus, application control  
✅ **Scalabilità**: supporta alto numero di connessioni  
✅ **Visibilità**: analytics e reporting avanzati  

## 3.4 DMZ multiple

### Descrizione
Utilizzo di **più DMZ separate** per servizi con requisiti di sicurezza differenti.

### Tipologie comuni

#### DMZ stratificate (Tiered DMZ)
```
Internet
    |
Firewall esterno
    |
DMZ Externa (Public-facing)
    - Web server pubblici
    - Load balancer
    |
Firewall intermedio  
    |
DMZ Intermedia (Application tier)
    - Application server
    - API gateway
    |
Firewall interno
    |
LAN Interna
    - Database
    - File server
```

#### DMZ categorizzate per servizio
```
                Internet
                    |
              [Core Firewall]
                    |
        ┌───────────┼───────────┐
        |           |           |
    DMZ-Web     DMZ-Mail    DMZ-VPN
    - Web       - SMTP      - VPN GW
    - Proxy     - IMAP      - Jump host
                - Webmail
```

### Vantaggi
✅ **Isolamento superiore**: compromissione di una DMZ non impatta le altre  
✅ **Policy granulari**: regole specifiche per ogni tipo di servizio  
✅ **Compliance**: facilita l'audit e la conformità normativa  
✅ **Performance**: traffico distribuito su segmenti dedicati  

### Svantaggi
❌ **Complessità**: gestione molto più articolata  
❌ **Costi**: richiede più hardware/risorse  
❌ **Overhead amministrativo**: più configurazioni da mantenere  

### Quando usarla
- Grandi organizzazioni o service provider
- Requisiti di conformità complessi
- Servizi critici che richiedono isolamento totale
- Architetture multi-tenant

## 3.5 Confronto tra le architetture

| Caratteristica | Singolo FW | Doppio FW | Tre Interfacce | DMZ Multiple |
|----------------|------------|-----------|----------------|--------------|
| **Sicurezza** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Costo** | € | €€€ | €€ | €€€€ |
| **Complessità** | Bassa | Alta | Media | Molto Alta |
| **Performance** | Media | Media-Bassa | Alta | Alta |
| **Scalabilità** | Limitata | Buona | Buona | Ottima |
| **Single Point Failure** | Sì | Parziale | Sì | No |
| **Adatta per** | PMI | Enterprise | Media impresa | Large Enterprise |

## 3.6 Esempi pratici di design

### Esempio 1: E-commerce piccola impresa
**Architettura consigliata**: DMZ a singolo firewall

```
Internet
    |
[Firewall 3-port]
    |
    ├─ DMZ: Web server + App server
    └─ LAN: Database, Admin
```

**Motivazione**: Costi contenuti, gestione semplice, adeguata per volume di transazioni limitato.

### Esempio 2: Banca o istituzione finanziaria
**Architettura consigliata**: DMZ multiple con doppio firewall

```
Internet
    |
Firewall esterno
    |
DMZ-Public (Web, Mobile banking)
    |
Firewall intermedio
    |
DMZ-Application (App servers, ESB)
    |
Firewall interno
    |
Core Banking Network
    - Database transazionali
    - Mainframe
```

**Motivazione**: Massima sicurezza, conformità PCI-DSS, protezione dati sensibili.

### Esempio 3: Startup tecnologica
**Architettura consigliata**: Cloud-native DMZ

```
Internet
    |
[Cloud WAF/CDN]
    |
[Security Group - DMZ]
    - Container web app
    - API gateway  
    |
[Security Group - Backend]
    - Microservizi
    - Database managed
```

**Motivazione**: Agilità, scalabilità, costi variabili, gestione semplificata.

## 3.7 Tip and tricks per la scelta dell'architettura

### 1. Valutare il budget realisticamente
- Non solo costo iniziale, ma anche TCO (Total Cost of Ownership)
- Considerare costi di gestione e manutenzione
- Licensing model (perpetual vs subscription)

### 2. Considerare le competenze interne
- Squadra IT ha esperienza con firewall enterprise?
- È disponibile supporto 24/7?
- Formazione necessaria?

### 3. Analisi del rischio
- Quale impatto ha un data breach?
- Requisiti di conformità  
- SLA e uptime required

### 4. Flessibilità futura
- L'architettura è scalabile?
- Si può aggiungere una seconda DMZ facilmente?
- Supporta virtualizzazione/cloud?

### 5. Non over-engineering
- "Perfect is the enemy of good"
- Iniziare con una soluzione adeguata e evolvere
- Troppa complessità = più errori di configurazione

### 6. Proof of Concept (PoC)
- Testare l'architettura in lab prima della produzione
- Simulare scenari di attacco
- Misurare performance reali

## 3.8 Autovalutazione

### Domande a risposta multipla

**1. Qual è il principale vantaggio di una DMZ a doppio firewall?**
- a) Costa meno
- b) È più veloce
- c) Offre defense in depth reale
- d) È più facile da configurare

**2. Quante interfacce di rete richiede minimo un firewall per implementare una DMZ a singolo firewall?**
- a) 1
- b) 2
- c) 3
- d) 4

**3. Quale architettura è più adatta per una grande banca?**
- a) DMZ a singolo firewall
- b) Nessuna DMZ
- c) DMZ multiple con firewall ridondanti
- d) Solo firewall software

**4. Il principale svantaggio del singolo firewall è:**
- a) Troppo costoso
- b) Single Point of Failure
- c) Non supporta HTTPS
- d) Troppo complesso

**5. Le DMZ stratificate (tiered) sono utili per:**
- a) Risparmiare denaro
- b) Separare diversi layer applicativi con requisiti diversi
- c) Aumentare la velocità della rete
- d) Eliminare la necessità di firewall

### Domande a risposta aperta

1. Confronta l'architettura a singolo firewall con quella a doppio firewall. In quali scenari sceglieresti l'una o l'altra?

2. Descrivi un'architettura DMZ adatta per un sito e-commerce di medie dimensioni che deve essere conforme PCI-DSS. Giustifica le tue scelte.

3. Spiega come le DMZ multiple migliorano la sicurezza rispetto a una singola DMZ. Fornisci un esempio concreto.

### Esercizio pratico

**Progetta un'architettura DMZ**

Una clinica medica ha bisogno di esporre i seguenti servizi:
- Portale web per prenotazioni online
- Sistema di webmail per il personale
- VPN per medici che lavorano da remoto
- Accesso a sistema gestionale (EMR - Electronic Medical Records)

Requisiti:
- Conformità HIPAA
- Protezione massima dei dati pazienti
- Separazione tra servizi pubblici e dati sensibili

**Compiti:**
1. Disegna il diagramma dell'architettura di rete
2. Specifica quanti firewall sono necessari e dove
3. Indica quali servizi vanno in DMZ e quali in rete interna
4. Elenca le regole firewall principali per ogni interfaccia
5. Giustifica le tue scelte architetturali

---

*[Le risposte alle domande di autovalutazione si trovano nell'appendice del manuale]*
