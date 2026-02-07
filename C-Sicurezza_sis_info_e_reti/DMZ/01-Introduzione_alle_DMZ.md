# Capitolo 1 - Introduzione alle DMZ

## 1.1 Cos'è una DMZ

Una **DMZ (Demilitarized Zone)**, o zona demilitarizzata, è un segmento di rete isolato che funge da buffer tra la rete interna (protetta) e la rete esterna (Internet). Il termine deriva dal concetto militare di "zona demilitarizzata", un'area neutrale tra due entità che potrebbero essere in conflitto.

Nel contesto delle reti informatiche, una DMZ ospita i servizi che devono essere accessibili dall'esterno (come web server, mail server, DNS pubblici) mantenendoli separati dalla rete interna aziendale. Questo approccio limita l'esposizione della rete interna alle minacce provenienti da Internet.

### Caratteristiche principali di una DMZ:
- **Isolamento**: separazione fisica o logica dalla rete interna
- **Accessibilità controllata**: regole firewall specifiche per il traffico in ingresso e uscita
- **Contenimento**: in caso di compromissione, limita i danni alla sola DMZ
- **Monitoraggio**: logging e monitoring centralizzato del traffico

## 1.2 Perché le DMZ sono necessarie

Le DMZ sono fondamentali per diverse ragioni:

### Protezione della rete interna
Senza una DMZ, i server pubblici sarebbero posizionati direttamente nella rete interna o completamente esposti su Internet. Entrambe le soluzioni presentano gravi rischi:
- **Server nella LAN interna**: un attacco riuscito potrebbe compromettere l'intera rete aziendale
- **Server completamente esposti**: maggiore vulnerabilità senza protezioni adeguate

### Conformità normativa
Molti standard di sicurezza richiedono la segmentazione della rete:
- **PCI-DSS**: per sistemi che gestiscono carte di pagamento
- **GDPR**: per la protezione dei dati personali
- **ISO 27001**: per la gestione della sicurezza delle informazioni

### Gestione del rischio
La DMZ implementa il principio di **defense in depth** (difesa a strati), creando multiple barriere tra gli attaccanti e le risorse critiche.

### Flessibilità operativa
Permette di:
- Applicare policy di sicurezza differenziate
- Monitorare efficacemente il traffico
- Gestire separatamente i servizi pubblici e privati
- Facilitare gli aggiornamenti e la manutenzione

## 1.3 Evoluzione storica delle architetture di rete

### Anni '80-'90: Reti senza protezione
- Poche organizzazioni collegate a Internet
- Fiducia implicita nelle connessioni
- Assenza di firewall e segmentazione

### Anni '90: Nascita dei firewall
- Introduzione dei primi firewall commerciali
- Concetto di perimetro di rete
- Separazione basilare interno/esterno

### Fine anni '90 - Inizio 2000: Emergere delle DMZ
- Aumento degli attacchi informatici
- Necessità di esporre servizi web
- Sviluppo di architetture a tre zone (Internet - DMZ - LAN interna)

### 2000-2010: DMZ complesse
- Multiple DMZ per servizi differenti
- Introduzione di IDS/IPS
- VLAN e segmentazione avanzata

### 2010-2020: Virtualizzazione
- DMZ virtuali in ambienti VMware, Hyper-V
- Software-defined networking (SDN)
- Firewall di nuova generazione (NGFW)

### 2020-oggi: Cloud e micro-segmentazione
- DMZ in ambienti cloud (AWS, Azure, GCP)
- Zero Trust Architecture
- Container security e micro-segmentazione
- Cloud-native security

## 1.4 Scenari di utilizzo tipici

### E-commerce
Un sito di e-commerce necessita di:
- **Web server** in DMZ per il frontend
- **Application server** per la logica di business
- **Database server** nella rete interna (non in DMZ)
- **Gateway di pagamento** con connessioni sicure verso l'interno

### Servizi email aziendali
- **Mail server SMTP** in DMZ per ricevere email dall'esterno
- **Mail server interni** protetti nella LAN
- **Relay SMTP** per filtraggio antispam/antivirus
- **Webmail** accessibile dall'esterno

### Servizi web pubblici
- **Web server** per siti istituzionali o applicazioni web
- **Reverse proxy** per protezione e load balancing
- **API gateway** per servizi REST/SOAP
- **CDN** per contenuti statici

### Accesso remoto
- **VPN gateway** in DMZ per connessioni remote
- **Jump server/Bastion host** per accesso amministrativo
- **Remote Desktop Gateway**

### DNS e infrastruttura
- **DNS pubblici** in DMZ per risoluzione esterna
- **DNS interni** separati nella LAN
- **NTP server** per sincronizzazione oraria
- **Syslog server** per centralizzazione log

## 1.5 Autovalutazione

### Domande a risposta multipla

**1. Qual è lo scopo principale di una DMZ?**
- a) Aumentare la velocità della rete
- b) Separare i servizi pubblici dalla rete interna
- c) Ridurre i costi dell'infrastruttura
- d) Eliminare completamente i rischi di sicurezza

**2. Quale principio di sicurezza implementa una DMZ?**
- a) Autenticazione a due fattori
- b) Crittografia end-to-end
- c) Defense in depth (difesa a strati)
- d) Single sign-on

**3. Quale tipo di server è tipicamente posizionato in una DMZ?**
- a) File server aziendale
- b) Controller di dominio Active Directory
- c) Web server pubblico
- d) Workstation degli utenti

**4. Cosa succede se un server in DMZ viene compromesso?**
- a) L'intera rete aziendale è immediatamente compromessa
- b) Il danno è contenuto alla DMZ grazie all'isolamento
- c) Internet smette di funzionare
- d) Tutti i firewall si disattivano automaticamente

**5. Quale standard di conformità richiede la segmentazione della rete per i sistemi di pagamento?**
- a) HTTP/2
- b) PCI-DSS
- c) TCP/IP
- d) IEEE 802.11

### Domande a risposta aperta

1. Spiega la differenza tra posizionare un web server direttamente su Internet, nella rete interna, o in una DMZ. Quali sono i vantaggi e gli svantaggi di ciascun approccio?

2. Descrivi tre scenari reali in cui una DMZ sarebbe necessaria e spiega quali servizi ospiteresti in ciascuna DMZ.

3. Come è evoluta l'architettura delle DMZ dagli anni '90 ad oggi? Quali fattori hanno guidato questa evoluzione?

### Esercizio pratico

**Progetta una DMZ base**

Disegna un diagramma di rete che mostri:
- La rete Internet
- Un firewall perimetrale
- Una DMZ contenente almeno 3 servizi
- La rete interna aziendale
- Le connessioni e i flussi di traffico principali

Indica per ciascun servizio:
- Quale protocollo utilizza
- Quali porte devono essere aperte
- La direzione del traffico (inbound/outbound)

---

*[Le risposte alle domande di autovalutazione si trovano nell'appendice del manuale]*
