# SOLUZIONE COMPLETA - PROVA A038_ORD24

## 📋 Indice

1. [Prima Parte - Infrastruttura di Rete Regionale](#prima-parte)
   - [1. Infrastruttura di Rete e Schema](#punto-1)
   - [2. Dispositivo per Strutture Private](#punto-2)
   - [3. Connessione alla LAN Esistente](#punto-3)
   - [4. Sicurezza dei Dati](#punto-4)
2. [Seconda Parte - Quesiti](#seconda-parte)
   - [Quesito I - Strategie contro perdita dati](#quesito-i)
   - [Quesito II - Autenticazione qualificata cittadini](#quesito-ii)
   - [Quesito III - Web Server con IP Pubblico Singolo](#quesito-iii)
   - [Quesito IV - Troubleshooting Connettività Internet](#quesito-iv)
3. [File di Supporto](#file-supporto)
4. [Quick Reference](#quick-reference)

---

## PRIMA PARTE - Infrastruttura di Rete Regionale

### Contesto di Riferimento

**Riferimento al testo**: Sezione "PRIMA PARTE - Contesto"

La Regione ha creato un'infrastruttura in fibra ottica che attualmente connette:
- Enti locali
- Scuole
- Strutture sanitarie pubbliche

Con un data-center centrale che gestisce il **Fascicolo Sanitario Elettronico (FSE)** dei cittadini.

**Estensione richiesta**: Connettere anche le ~2000 strutture sanitarie private convenzionate alla sottorete **10.100.0.0/16**.

---

## PUNTO 1: Infrastruttura di Rete e Schema {#punto-1}

**Riferimento al testo**: Punto 1 - "Sviluppi una descrizione di massima, anche supportata da uno schema grafico..."

### Descrizione dell'Infrastruttura

#### 1.1 Infrastruttura Pre-esistente

La rete in fibra ottica regionale è strutturata come segue:

```
Rete Regionale 10.0.0.0/8
│
├─ Enti locali:          10.10.0.0/16   (es: 65.536 indirizzi)
├─ Scuole:               10.20.0.0/16   (es: 65.536 indirizzi)
├─ Strutture Sanitarie   
│  Pubbliche:            10.30.0.0/16   (es: 65.536 indirizzi)
└─ Data-Center:          10.1.0.0/24    (256 indirizzi per server e servizi)
```

**Architettura**:
- **Core Network**: Rete in fibra ottica backbone regionale
- **Edge Routers**: Router di accesso presso ogni sede
- **Data-Center**: Hub centrale con server FSE, database, storage

#### 1.2 Nuova Infrastruttura per Strutture Private

**Sottorete assegnata**: 10.100.0.0/16

**Requisiti**:
- ~2000 strutture sanitarie private convenzionate
- Minimo 8 indirizzi per struttura
- Isolamento tra strutture
- Accesso esclusivo al data-center (no Internet generico)

### Piano di Subnetting

**Riferimento completo**: [Piano di Indirizzamento Dettagliato](piano_indirizzamento.md)

Utilizzo **subnetting con /27**:
- Ogni subnet /27 fornisce: **32 indirizzi IP** (30 utilizzabili)
- Indirizzi disponibili per struttura: 30 (ben oltre il minimo di 8)
- Numero massimo di subnet /27 in 10.100.0.0/16: **2048 subnet**

**Schema di allocazione**:
```
10.100.0.0/27    → Struttura Privata #1    (10.100.0.1 - 10.100.0.30)
10.100.0.32/27   → Struttura Privata #2    (10.100.0.33 - 10.100.0.62)
10.100.0.64/27   → Struttura Privata #3    (10.100.0.65 - 10.100.0.94)
...
10.100.255.224/27 → Struttura Privata #2048 (10.100.255.225 - 10.100.255.254)
```

### Schema Grafico dell'Infrastruttura

**Riferimento completo**: [Diagramma di Rete](diagramma_rete.md)

```
                        ┌─────────────────────────┐
                        │   DATA-CENTER REGIONALE │
                        │     10.1.0.0/24         │
                        │  ┌──────────────────┐   │
                        │  │ Server FSE       │   │
                        │  │ Database Cluster │   │
                        │  │ Storage          │   │
                        │  │ Firewall         │   │
                        │  └──────────────────┘   │
                        └───────────┬─────────────┘
                                    │
                        ┌───────────┴─────────────┐
                        │  CORE ROUTER REGIONALE  │
                        │   Multi-Layer Switch    │
                        └───┬───┬───┬─────────┬───┘
                            │   │   │         │
         ┌──────────────────┘   │   │         └──────────────────┐
         │                      │   │                            │
    ┌────┴────┐          ┌─────┴───┴─────┐              ┌───────┴────────┐
    │  Enti   │          │ Scuole        │              │ Strutture San. │
    │  Locali │          │               │              │ Pubbliche      │
    │10.10/16 │          │ 10.20.0.0/16  │              │ 10.30.0.0/16   │
    └─────────┘          └───────────────┘              └────────────────┘

         
                        ┌─────────────────────────────────┐
                        │  EDGE ROUTER STRUTTURE PRIVATE  │
                        │    (con VLAN & Firewall)        │
                        └──┬──────┬──────┬──────┬────┬───┘
                           │      │      │      │    │
                    ┌──────┘      │      │      │    └──────────┐
                    │             │      │      │               │
              ┌─────┴─────┐  ┌───┴───┐  │   ┌──┴────┐    ┌─────┴─────┐
              │CPE Router │  │CPE    │  │   │CPE    │    │CPE Router │
              │Struttura#1│  │Strutt.│  │   │Strutt.│    │Struttura  │
              │10.100.0/27│  │#2     │  │   │#3     │    │#2048      │
              └─────┬─────┘  └───┬───┘  │   └───┬───┘    └─────┬─────┘
                    │            │      │       │              │
              ┌─────┴─────┐      │  ... │       │        ┌─────┴─────┐
              │LAN Privata│      │      │       │        │LAN Privata│
              │Struttura#1│      │      │       │        │Struttura  │
              └───────────┘      └──────┘       └────────┘#2048      │
                                                           └───────────┘
```

### Caratteristiche Tecniche

**Core Network**:
- Fibra ottica monomodale (SMF) per backbone
- Protocollo: MPLS per isolamento traffico
- Ridondanza: Doppio anello in fibra
- Velocità: 10 Gbps o superiore

**Edge Network**:
- Router aggregazione con VLAN support
- Firewall integrato o dedicato
- QoS per prioritizzare traffico sanitario
- VPN IPsec per sicurezza

---

## PUNTO 2: Dispositivo per Strutture Private {#punto-2}

**Riferimento al testo**: Punto 2 - "Indichi la tipologia e le caratteristiche hardware..."

### Specifiche del CPE (Customer Premises Equipment)

**Riferimento completo**: [Configurazione CPE Router](configurazione_cpe.md)

#### Tipologia Dispositivo

**Router Industriale/Enterprise** con funzionalità:
- Routing multi-WAN
- Firewall stateful
- VPN IPsec hardware accelerated
- Gestione remota sicura
- Supporto VLAN

**Modello di riferimento**: Cisco ISR 1100, MikroTik RB4011, o equivalente

#### Caratteristiche Hardware

**Porte di Rete**:
1. **WAN Port** (1x):
   - Porta Ethernet 1 Gbps (RJ45) o SFP per fibra
   - Connessione alla rete regionale in fibra
   - Configurazione: IP statico dalla subnet assegnata

2. **LAN Ports** (4x - 8x):
   - Porte Ethernet 1 Gbps (RJ45)
   - Connessione alla LAN interna della struttura
   - Configurazione: Bridged o routing interno

3. **Management Port** (1x):
   - Porta console seriale (RJ45 o USB)
   - Per configurazione locale in emergenza

**Altre Caratteristiche**:
- CPU: Multi-core per gestione firewall e VPN
- RAM: Minimo 1 GB
- Storage: Flash memory per firmware e configurazioni
- Alimentazione: Doppia PSU ridondante o UPS integrato

#### Configurazione Porte

**WAN Port (eth0)**:
```
Interface: eth0
IP Address: 10.100.X.1/27 (X varia per struttura)
Gateway: 10.100.X.30 (gateway subnet)
DNS: 10.1.0.10, 10.1.0.11 (DNS data-center)
MTU: 1500
```

**LAN Port (eth1-eth4)**:
```
Interface: eth1 (bridge con eth2-eth4)
IP Address: 192.168.X.1/24 (LAN privata struttura)
DHCP Server: Enabled (192.168.X.10 - 192.168.X.250)
```

#### Servizi Configurati

1. **NAT (Network Address Translation)**
   - Source NAT: LAN privata → WAN (10.100.X.X)
   - Permette a dispositivi interni di comunicare con data-center

2. **Firewall**
   - **Regole in uscita** (LAN → WAN):
     - Permetti: HTTPS (443) verso data-center FSE
     - Permetti: SSH (22) gestione remota da IP autorizzati
     - Blocca: Tutto il resto (incluso Internet generico)
   
   - **Regole in ingresso** (WAN → LAN):
     - Permetti: SSH da IP gestione società regionale
     - Permetti: ICMP (ping) per monitoraggio
     - Blocca: Tutto il resto

3. **VPN IPsec**
   - Tunnel VPN site-to-site verso data-center
   - Cifratura: AES-256
   - Autenticazione: Pre-shared key o certificati

4. **QoS (Quality of Service)**
   - Priorità alta: Traffico FSE (porta 443)
   - Priorità media: Gestione remota (SSH)
   - Limitazione banda per altri servizi

5. **Logging e Monitoring**
   - Syslog remoto verso server di gestione
   - SNMP per monitoraggio stato dispositivo
   - NetFlow/sFlow per analisi traffico

6. **Gestione Remota**
   - SSH su porta non standard
   - Accesso solo da IP società regionale
   - Autenticazione con chiavi pubbliche

**Riferimento**: [Script configurazione CPE](script_configurazione_cpe.sh)

---

## PUNTO 3: Connessione alla LAN Esistente {#punto-3}

**Riferimento al testo**: Punto 3 - "Considerando le caratteristiche della LAN pre-esistente..."

### Scenario Esempio: Clinica Privata "San Marco"

#### LAN Pre-esistente

**Caratteristiche**:
- Rete LAN: 192.168.1.0/24
- Switch principale: 24 porte managed (VLAN capable)
- Access Points WiFi: 3 dispositivi
- Server locali: 2 server (file server, applicazioni)
- Workstation: 20 PC medici/amministrativi
- Dispositivi medicali: 5 apparecchiature con connettività
- Router Internet esistente: connessione ADSL/Fibra per Internet

#### Integrazione con Rete Regionale

**Riferimento completo**: [Schema Connessione LAN](schema_connessione_lan.md)

##### Opzione A: Configurazione Dual-WAN (Consigliata)

**Apparati Aggiuntivi**:
1. **CPE Router fornito dalla Regione** (nuovo)
2. **Nessuna modifica** al router Internet esistente

**Schema di Connessione**:
```
Internet (ADSL/Fibra)
        │
        ├─────────> [Router Internet Esistente]
        │                    │ LAN: 192.168.2.1/24
        │                    │
        │           [Switch Principale]
        │                    │
        ├───[CPE Regionale]──┤
        │    10.100.5.1/27   │
        │                    │
        └───> LAN Devices: PCs, Server, WiFi APs, Dispositivi Medicali
```

**Configurazione Switch Principale**:

Creare **2 VLAN**:
- **VLAN 10** (Internet generico): Navigazione web, email
- **VLAN 20** (FSE Regionale): Accesso FSE tramite CPE regionale

```
VLAN 10 - Internet
├─ Porta 1-15: Workstation amministrative
├─ Porta 20-22: WiFi APs
└─ Uplink: Porta 23 → Router Internet

VLAN 20 - FSE
├─ Porta 16-19: Workstation mediche
├─ Porta 24: Uplink → CPE Regionale
└─ Accesso solo a FSE data-center
```

**Routing Policy**:
- Policy-based routing sui PC medici
- Traffico verso 10.1.0.0/24 (FSE) → CPE Regionale
- Traffico verso Internet → Router Internet

##### Opzione B: Configurazione con Firewall Interno

**Apparati Aggiuntivi**:
1. **CPE Router fornito dalla Regione**
2. **Firewall/Router interno** (es: pfSense, Sophos)

**Schema**:
```
[CPE Regionale] ──┐
                  │
[Internet] ───────┤──> [Firewall/Router] ──> [Switch] ──> LAN Devices
                  │        (Dual-WAN)
```

Il firewall gestisce:
- Load balancing tra le due WAN
- Regole di routing per destinazioni FSE
- Firewall policies per segmentazione rete

#### Riconfigurazioni Necessarie

1. **Switch Principale**:
   ```
   - Abilitare VLAN support
   - Configurare porte trunk per CPE
   - Assegnare VLAN a porte access
   ```

2. **Workstation Mediche**:
   ```
   - Installare client VPN (se necessario)
   - Configurare DNS per risolvere FSE
   - Aggiungere rotte statiche (opzionale)
   ```

3. **Server Locali**:
   ```
   - Configurare backup automatico verso data-center
   - Sincronizzazione dati FSE
   ```

**Esempio Configurazione Switch (Cisco-like)**:
```
! Creazione VLAN
vlan 10
 name Internet
vlan 20
 name FSE-Regionale

! Porta verso CPE Regionale (trunk)
interface GigabitEthernet0/24
 description Uplink-CPE-Regionale
 switchport mode trunk
 switchport trunk allowed vlan 20

! Porte workstation mediche (access VLAN 20)
interface range GigabitEthernet0/16-19
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast
```

**Riferimento**: [Configurazione Switch](configurazione_switch.txt)

---

## PUNTO 4: Sicurezza dei Dati {#punto-4}

**Riferimento al testo**: Punto 4 - "Data la natura sensibile dei dati trattati..."

### Misure di Sicurezza

**Riferimento completo**: [Piano di Sicurezza](piano_sicurezza.md)

#### 4.1 Sicurezza in Archiviazione

**Nel Data-Center Regionale**:

1. **Cifratura a riposo (Encryption at Rest)**:
   - Database: Transparent Data Encryption (TDE)
   - File system: LUKS/dm-crypt (Linux) o BitLocker (Windows)
   - Storage: Cifratura hardware su SAN/NAS
   - Algoritmo: AES-256

2. **Controllo Accessi**:
   - Autenticazione forte: Multi-factor authentication (MFA)
   - RBAC (Role-Based Access Control)
   - Audit logging di tutti gli accessi
   - Principle of Least Privilege

3. **Backup e Disaster Recovery**:
   - Backup giornaliero incrementale
   - Backup settimanale completo
   - Replica geografica in data-center secondario
   - Test di ripristino trimestrale
   - Retention: 7 anni (normativa sanitaria)

4. **Sicurezza Fisica**:
   - Data-center certificato ISO 27001
   - Accesso biometrico
   - Videosorveglianza 24/7
   - Sistema antincendio e controllo temperatura

**Nelle Strutture Private**:

1. **Cifratura Dispositivi Locali**:
   - Hard disk cifrati (BitLocker/FileVault)
   - Database locali con TDE
   - Chiavi di cifratura custodite in safe

2. **Policy di Sicurezza**:
   - Password complesse (minimo 12 caratteri)
   - Cambio password ogni 90 giorni
   - Blocco automatico workstation dopo 5 minuti
   - Antivirus enterprise aggiornato

#### 4.2 Sicurezza in Trasmissione

**Protocolli di Cifratura**:

1. **VPN IPsec Site-to-Site**:
   - Fase 1 (IKE): 
     - Algoritmo: AES-256
     - Hash: SHA-256
     - Diffie-Hellman Group: 14 o superiore
   - Fase 2 (ESP):
     - Cifratura: AES-256-GCM
     - Perfect Forward Secrecy (PFS)

2. **TLS 1.3 per Applicazioni Web**:
   - Certificati SSL/TLS da CA riconosciuta
   - Cipher suite: TLS_AES_256_GCM_SHA384
   - HSTS (HTTP Strict Transport Security)
   - Certificate pinning

3. **Integrità Dati**:
   - Hash SHA-256 per verifica integrità file
   - Firma digitale per documenti sensibili

**Segregazione Rete**:
- Firewall stateful tra segmenti
- IDS/IPS per rilevazione intrusioni
- Network segmentation con VLAN
- DMZ per servizi esposti

#### 4.3 Modalità di Trasferimento Dati

**Riferimento al testo**: "...specifichi le modalità e la schedulazione temporale..."

##### Modalità di Trasferimento

**1. Push Automatico (Consigliato)**:

Le strutture private inviano automaticamente i dati al data-center.

```
Struttura Privata                    Data-Center
     │                                    │
     │  1. Prestazione completata         │
     │  2. Dati validati localmente       │
     │  3. Cifratura TLS/VPN              │
     │  ────────> HTTPS POST ────────>    │
     │                                    │  4. Validazione
     │                                    │  5. Inserimento DB
     │  <────── ACK/Conferma ─────────    │
     │                                    │
```

**API REST per Invio Dati**:
- Endpoint: `https://fse.regione.it/api/v1/prestazioni`
- Autenticazione: OAuth 2.0 + Client Certificate
- Formato dati: JSON o HL7 FHIR
- Max dimensione payload: 100 MB

**2. Trasferimento File Batch**:

Per dati di grandi dimensioni (immagini diagnostiche, video):

```
- Protocollo: SFTP over SSH
- Server: sftp.fse.regione.it
- Autenticazione: Chiave pubblica/privata
- Cifratura: SSH-2, AES-256
```

##### Schedulazione Temporale

**Trasferimenti Real-Time** (Priorità Alta):
- **Dati clinici urgenti**: Immediato (< 1 minuto)
  - Es: Risultati esami critici, referti urgenti
- **Orario**: 24/7
- **Retry**: In caso di fallimento, retry ogni 5 minuti per 1 ora

**Trasferimenti Near Real-Time** (Priorità Media):
- **Prestazioni ordinarie**: Ogni 15 minuti
  - Es: Visite specialistiche, esami di routine
- **Orario**: 7:00 - 23:00
- **Batch**: Accumulazione in coda locale, invio ogni 15 min

**Trasferimenti Batch Notturni** (Priorità Bassa):
- **File di grandi dimensioni**: 01:00 - 05:00
  - Es: Immagini diagnostiche ad alta risoluzione, video
- **Orario**: Finestra notturna (carico rete minimo)
- **Compressione**: ZIP con cifratura AES

**Schedulazione di Esempio**:

| Orario | Attività | Tipo Dati | Protocollo |
|--------|----------|-----------|------------|
| 00:00-01:00 | Backup DB locale | Tutti | SFTP |
| 01:00-05:00 | Trasferimento immagini/video | File grandi | SFTP batch |
| 07:00-23:00 | Invio prestazioni ordinarie | Dati clinici | HTTPS (ogni 15 min) |
| 24/7 | Dati urgenti | Critici | HTTPS (real-time) |
| 03:00 | Sincronizzazione anagrafiche | Master data | HTTPS |

**Script Schedulazione**: [Script Cron Jobs](script_schedulazione.sh)

#### 4.4 Gestione Eventi di Sicurezza

**Logging e Audit**:
- Log centralizzato (SIEM)
- Retention log: 1 anno
- Alert per eventi sospetti
- Dashboard monitoring in tempo reale

**Incident Response**:
- Team di risposta 24/7
- Procedura di escalation
- Comunicazione obbligatoria breach entro 72h (GDPR)
- Piano di disaster recovery

**Conformità Normativa**:
- GDPR (Regolamento UE 2016/679)
- Codice Privacy italiano (D.Lgs. 196/2003)
- Linee guida AgID per FSE
- ISO 27001 (certificazione data-center)

---

## SECONDA PARTE - Quesiti {#seconda-parte}

### QUESITO I: Strategie contro perdita dati {#quesito-i}

**Riferimento al testo**: Seconda Parte - Quesito I

#### Strategie per Malfunzionamenti in Trasmissione

**1. Affidabilità del Trasferimento**

**Retry Automatico con Backoff Esponenziale**:
```python
# Pseudocodice
max_retries = 5
base_delay = 2  # secondi

for attempt in range(max_retries):
    try:
        result = send_data_to_datacenter(data)
        if result.success:
            log_success()
            return
    except NetworkError as e:
        if attempt < max_retries - 1:
            delay = base_delay ** attempt
            wait(delay)
        else:
            queue_for_later_retry(data)
            alert_administrator()
```

**2. Coda Locale Persistente (Message Queue)**

```
┌─────────────────┐
│ Applicazione    │
│ Struttura       │
└────────┬────────┘
         │ produce
         ▼
┌─────────────────┐      ┌──────────────┐
│ Local Queue     │◄─────┤ Persistent   │
│ (RabbitMQ/      │      │ Storage      │
│  Redis)         │      │ (Disk)       │
└────────┬────────┘      └──────────────┘
         │ consume
         ▼
┌─────────────────┐
│ Data Transfer   │──────> Data-Center
│ Agent           │
└─────────────────┘
```

**Vantaggi**:
- Dati non persi anche se data-center irraggiungibile
- Retry automatico in background
- Persistenza su disco locale

**3. Checksum e Verifica Integrità**

```
Invio:
1. Calcola SHA-256 del file
2. Invia file + hash
3. Attendi conferma ricezione

Ricezione Data-Center:
1. Ricevi file + hash
2. Ricalcola SHA-256
3. Confronta hash
4. Se match → Salva, altrimenti → Richiedi reinvio
```

**4. Trasferimento Multi-Part per File Grandi**

```
File grande (es: 500 MB di immagini diagnostiche)
        │
        ├─ Chunk 1 (50 MB) → Trasferisci → Verifica → OK
        ├─ Chunk 2 (50 MB) → Trasferisci → Verifica → OK
        ├─ Chunk 3 (50 MB) → Trasferisci → Fail → Retry Chunk 3
        ├─ ...
        └─ Chunk 10 (50 MB) → Trasferisci → Verifica → OK
                │
        Riassembla nel data-center
```

**Protocollo**: rsync con opzione `--partial` o AWS S3 Multipart Upload

**5. Monitoring e Alerting**

```
Monitoraggio:
- Connettività VPN (ping ogni 30s)
- Latenza < 100ms
- Packet loss < 1%
- Banda disponibile > 10 Mbps

Alert se:
- VPN down per > 5 minuti
- Coda locale > 1000 messaggi
- Età messaggio più vecchio > 4 ore
```

**Notifiche**:
- Email a responsabile tecnico
- SMS per situazioni critiche
- Dashboard di monitoring web

#### Strategie per Malfunzionamenti Storage

**1. Ridondanza a Livello Storage**

**RAID (Redundant Array of Independent Disks)**:

Nel Data-Center:
- **RAID 10** (1+0): Mirror + Striping
  - Minimo 4 dischi
  - Tolleranza: Perdita fino a 1 disco per mirror
  - Prestazioni: Eccellenti in lettura/scrittura

Nelle Strutture Private:
- **RAID 1**: Mirroring
  - 2 dischi identici
  - Tolleranza: Perdita 1 disco

**2. Backup Multi-Livello (3-2-1 Rule)**

```
3 copie dei dati
2 media diversi
1 copia off-site

Esempio:
1. Produzione: Data-center primario (RAID 10)
2. Backup primario: NAS locale data-center
3. Backup secondario: Data-center geograficamente distante
```

**Schedulazione Backup**:
```
Backup Incrementale: Ogni 6 ore (04:00, 10:00, 16:00, 22:00)
Backup Differenziale: Giornaliero (02:00)
Backup Completo: Settimanale (Domenica 01:00)
```

**3. Snapshot Storage**

```
Volume Storage con Snapshot ZFS/Btrfs:
- Snapshot ogni ora (retention: 24h)
- Snapshot giornalieri (retention: 30 giorni)
- Snapshot settimanali (retention: 1 anno)

In caso di corruzione:
→ Ripristino da snapshot più recente valido
```

**4. Replica in Tempo Reale**

**Database Replication**:
```
                Master DB
              (Data-Center A)
                    │
        ┌───────────┴───────────┐
        │                       │
   Slave DB 1            Slave DB 2
(Data-Center A)      (Data-Center B)
   (Hot Standby)      (Disaster Recovery)
```

- **Sincrona**: Per transazioni critiche (ACID compliance)
- **Asincrona**: Per dati non critici (prestazioni migliori)

**5. Controlli di Integrità Periodici**

```bash
# Script controllo integrità (eseguito settimanalmente)
#!/bin/bash

# Verifica integrità database
pg_dump --data-only | shasum -a 256 > db_checksum.txt
compare_with_previous_checksum()

# Verifica integrità file system
find /data/fse -type f -exec shasum -a 256 {} \; > fs_checksum.txt

# Verifica RAID status
cat /proc/mdstat | grep -i "fail"

# Se anomalie → Alert amministratore
```

**6. Test di Disaster Recovery**

**Procedura Trimestrale**:
1. Simulazione guasto hardware
2. Ripristino da backup
3. Verifica integrità dati ripristinati
4. Tempo di ripristino target (RTO): < 4 ore
5. Punto di ripristino target (RPO): < 15 minuti
6. Documentazione risultati

**7. Archiviazione a Lungo Termine**

Per conformità normativa (7 anni):
```
Anno 0-1: Storage veloce (SSD)
Anno 1-3: Storage standard (HDD)
Anno 3-7: Cold storage (Tape/Cloud Glacier)
         + Verifica annuale leggibilità
```

---

### QUESITO II: Autenticazione qualificata cittadini {#quesito-ii}

**Riferimento al testo**: Seconda Parte - Quesito II

#### Autenticazione Multi-Fattore per Accesso FSE

**Sistema di Autenticazione a 3 Fattori**:

```
Factor 1: Qualcosa che CONOSCI (Knowledge)
Factor 2: Qualcosa che HAI (Possession)
Factor 3: Qualcosa che SEI (Inherence)
```

### 1. Factor 1 - Credenziali di Conoscenza

**Opzione A: SPID (Sistema Pubblico Identità Digitale)**

```
Cittadino                    Identity Provider              FSE Portal
   │                                │                           │
   │  1. Richiesta accesso FSE      │                           │
   │  ───────────────────────────────────────────────────────> │
   │                                │                           │
   │  2. Redirect SPID              │                           │
   │  <────────────────────────────────────────────────────────│
   │                                │                           │
   │  3. Autenticazione (user/pwd)  │                           │
   │  ─────────────────────────────>│                           │
   │                                │  4. Verifica credenziali  │
   │                                │                           │
   │  5. Richiesta OTP              │                           │
   │  <──────────────────────────── │                           │
   │                                │                           │
   │  6. Inserimento OTP            │                           │
   │  ─────────────────────────────>│                           │
   │                                │                           │
   │                                │  7. Token SAML            │
   │                                │  ────────────────────────>│
   │                                │                           │
   │  8. Accesso autorizzato        │                           │
   │  <────────────────────────────────────────────────────────│
```

**Livelli SPID**:
- **SPID Livello 2**: Username/Password + OTP (minimo richiesto)
- **SPID Livello 3**: Smartcard/Token USB + PIN

**Opzione B: CIE (Carta d'Identità Elettronica)**

```
- Lettura chip CIE con lettore NFC/smartcard
- PIN CIE (8 cifre)
- Autenticazione tramite CNS (Carta Nazionale Servizi)
```

**Opzione C: CNS (Carta Nazionale Servizi)**

```
- Smartcard con certificato digitale
- Lettore smartcard USB
- PIN di autenticazione
```

### 2. Factor 2 - Possesso Dispositivo

**OTP (One-Time Password)**:

**SMS OTP**:
```
1. Numero cellulare registrato
2. Codice a 6 cifre
3. Validità: 5 minuti
4. Max 3 tentativi errati
```

**Authenticator App (TOTP)**:
```
- App: Google Authenticator, Microsoft Authenticator, Authy
- Algoritmo: TOTP (Time-based OTP)
- Codice a 6 cifre
- Refresh ogni 30 secondi
- Sincronizzazione temporale con server
```

**Push Notification**:
```
1. Notifica su smartphone registrato
2. Approva/Rifiuta login
3. Verifica geolocalizzazione (opzionale)
4. Device fingerprinting
```

**Hardware Token**:
```
- Token USB (es: YubiKey)
- Generazione OTP offline
- Più sicuro di SMS (no SIM swap attack)
```

### 3. Factor 3 - Biometria (Opzionale)

**Impronta Digitale**:
```
- Lettore biometrico su smartphone/tablet
- Validazione locale (no invio impronta)
- Sblocco fattore 2 (Authenticator App)
```

**Riconoscimento Facciale**:
```
- Face ID (iOS) / Face Unlock (Android)
- Liveness detection (anti-spoofing)
- Validazione locale
```

**Riconoscimento Vocale**:
```
- Verifica identità tramite voce
- Utile per utenti con disabilità visive
```

### Flusso di Autenticazione Completo

**Scenario: Accesso FSE via Web**

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. ACCESSO INIZIALE                                             │
├─────────────────────────────────────────────────────────────────┤
│ Cittadino accede a: https://fse.regione.it                      │
│ Click "Accedi con SPID" / "Accedi con CIE"                      │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. AUTENTICAZIONE PRIMARIA (Factor 1)                           │
├─────────────────────────────────────────────────────────────────┤
│ • Redirect a Identity Provider SPID                             │
│ • Inserimento Username e Password                               │
│ • Verifica credenziali                                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. AUTENTICAZIONE SECONDARIA (Factor 2)                         │
├─────────────────────────────────────────────────────────────────┤
│ • Invio SMS con codice OTP a cellulare registrato               │
│ • Oppure: Richiesta codice da Authenticator App                 │
│ • Inserimento codice OTP                                        │
│ • Validazione codice (max 3 tentativi)                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. VERIFICA AGGIUNTIVA (Opzionale)                              │
├─────────────────────────────────────────────────────────────────┤
│ • Risk-based authentication:                                    │
│   - Nuovo dispositivo? → Richiesta biometria/email verifica     │
│   - IP sospetto? → Challenge aggiuntiva                         │
│   - Orario insolito? → Notifica push conferma                   │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. SESSIONE AUTENTICATA                                         │
├─────────────────────────────────────────────────────────────────┤
│ • Token JWT con durata 30 minuti                                │
│ • Refresh token con durata 8 ore                                │
│ • Logout automatico dopo 15 min inattività                      │
│ • Log accesso con IP, timestamp, dispositivo                    │
└─────────────────────────────────────────────────────────────────┘
```

### Implementazione Tecnica

**Protocollo**: OAuth 2.0 + OpenID Connect

**Esempio Integrazione SPID**:
```python
from flask import Flask, redirect, session
from spid_python import SpidClient

app = Flask(__name__)
spid = SpidClient(
    entity_id='https://fse.regione.it',
    acs_url='https://fse.regione.it/acs',
    sp_key='private.key',
    sp_cert='public.crt'
)

@app.route('/login')
def login():
    # Redirect a Identity Provider SPID
    auth_url = spid.get_login_url(
        idp='PosteID',
        level=2  # SPID Level 2
    )
    return redirect(auth_url)

@app.route('/acs', methods=['POST'])
def assertion_consumer_service():
    # Ricezione asserzione SAML
    saml_response = request.form['SAMLResponse']
    user_data = spid.validate_response(saml_response)
    
    if user_data:
        # Autenticazione riuscita
        session['user_id'] = user_data['fiscal_number']
        session['name'] = user_data['name']
        
        # Richiesta OTP (Factor 2)
        send_otp_sms(user_data['mobile'])
        return redirect('/verify_otp')
    else:
        return 'Autenticazione fallita', 401
```

### Gestione Privacy e Consensi

**GDPR Compliance**:

```
Al primo accesso:
1. Informativa privacy (dettagliata)
2. Consenso trattamento dati
3. Consenso condivisione dati con medici
4. Scelta visibilità storico prestazioni

Diritti utente:
- Visualizzazione dati personali
- Scarico FSE completo (portabilità)
- Richiesta cancellazione (diritto oblio - limitazioni sanitarie)
- Opposizione trattamento (con eccezioni legali)
```

### Sicurezza Aggiuntiva

**Anomaly Detection**:
```
- Login da paese estero → Alert
- Cambio IP frequente → Challenge
- Tentativi accesso multipli falliti → Blocco temporaneo (15 min)
- Accesso da 2 dispositivi contemporaneamente → Notifica
```

**Session Management**:
```
- Cookie HttpOnly, Secure, SameSite
- Token JWT con short expiration
- Device fingerprinting
- Concurrent session limit: 1 (solo un dispositivo alla volta)
```

---

## FILE DI SUPPORTO {#file-supporto}

### Documentazione Tecnica

1. **[Piano di Indirizzamento](piano_indirizzamento.md)** - Dettaglio subnetting completo
2. **[Diagramma di Rete](diagramma_rete.md)** - Schema grafico dettagliato dell'infrastruttura
3. **[Configurazione CPE Router](configurazione_cpe.md)** - Config completa CPE con esempi
4. **[Schema Connessione LAN](schema_connessione_lan.md)** - Integrazione LAN esistenti
5. **[Piano di Sicurezza](piano_sicurezza.md)** - Misure di sicurezza dettagliate
6. **[Configurazione Switch](configurazione_switch.txt)** - Comandi configurazione switch
7. **[Quesiti Seconda Parte](QUESITI_SECONDA_PARTE.md)** - Soluzioni complete quesiti III e IV

### Script e Automazione

8. **[Script Configurazione CPE](script_configurazione_cpe.sh)** - Bash script per setup CPE
9. **[Script Schedulazione](script_schedulazione.sh)** - Cron jobs per trasferimenti dati
10. **[Script Monitoring](script_monitoring.sh)** - Script verifica connettività

---

## QUESITO III: Web Server con IP Pubblico Singolo {#quesito-iii}

**Riferimento al testo**: "Una piccola azienda dispone di un normale collegamento ad Internet a banda larga, con un router a cui è assegnato un solo indirizzo IP pubblico statico..."

**Soluzione Dettagliata**: [QUESITI_SECONDA_PARTE.md - Quesito III](QUESITI_SECONDA_PARTE.md#quesito-iii-web-server-accessibile-da-internet)

### Sintesi Soluzione

**Problema**: Rendere accessibile un web server interno (HTTP/HTTPS/SSH) con 1 solo IP pubblico.

**Soluzione**: Port Forwarding (DNAT) sul router.

#### Configurazioni Fornite

1. **Cisco IOS**: Port forwarding con `ip nat inside source static tcp`
2. **Linux iptables**: DNAT con regole di FORWARD
3. **MikroTik**: Regole DNAT e firewall filter

#### Porte Mappate

```
Pubblico → Privato
80    → 192.168.0.10:80   (HTTP)
443   → 192.168.0.10:443  (HTTPS)
2222  → 192.168.0.10:22   (SSH - porta non standard per sicurezza)
```

#### Sicurezza

- Rate limiting su SSH (anti brute-force)
- Firewall ACL su WAN
- Fail2Ban opzionale
- Certificati SSL/TLS con Let's Encrypt

**File Completo**: [QUESITI_SECONDA_PARTE.md](QUESITI_SECONDA_PARTE.md#quesito-iii-web-server-accessibile-da-internet)

---

## QUESITO IV: Troubleshooting Connettività Internet {#quesito-iv}

**Riferimento al testo**: "All'interno di una azienda con una propria LAN, un tecnico di help-desk riceve la segnalazione di un utente circa l'impossibilità di 'navigare su Internet'..."

**Soluzione Dettagliata**: [QUESITI_SECONDA_PARTE.md - Quesito IV](QUESITI_SECONDA_PARTE.md#quesito-iv-troubleshooting-connettività-internet)

### Le 3 Cause Principali

#### 1. Problema Fisico/Data Link (Layer 1-2)

**Sintomi**: LED spenti, "no cable", nessuna connettività.

**Test**:
```bash
ipconfig /all              # Windows - cerca "Media disconnected"
ip link show              # Linux - cerca "Link detected: no"
ethtool eth0              # Verifica cavo
```

**Soluzione**: Sostituire cavo, verificare porta switch.

#### 2. Problema IP/Gateway (Layer 3)

**Sintomi**: IP APIPA (169.254.x.x), gateway non raggiungibile.

**Test**:
```bash
ipconfig                  # Verifica IP
ping <gateway>            # Test gateway
arp -a                    # Verifica ARP
ipconfig /renew           # Rinnova DHCP
```

**Soluzione**: Rinnovare DHCP, configurare IP statico, verificare gateway funzionante.

#### 3. Problema DNS (Layer 7)

**Sintomi**: Ping IP pubblici OK (8.8.8.8), ma nomi FAIL (www.google.com).

**Test**:
```bash
ping 8.8.8.8              # Test connettività IP
ping www.google.com       # Test risoluzione DNS
nslookup google.com       # Test DNS
ipconfig /flushdns        # Flush cache DNS
```

**Soluzione**: Configurare DNS pubblici (8.8.8.8, 1.1.1.1), flush cache.

### Approccio Sistematico

1. **Raccolta info** dall'utente
2. **Layer 1-2**: Verifica fisica (cavi, LED)
3. **Layer 3**: Verifica IP, gateway, routing
4. **Layer 4-7**: Verifica DNS, HTTP, applicazioni

**Script automatico** e **template ticket** forniti nel documento completo.

**File Completo**: [QUESITI_SECONDA_PARTE.md](QUESITI_SECONDA_PARTE.md#quesito-iv-troubleshooting-connettività-internet)

---

## QUICK REFERENCE {#quick-reference}

**Riferimento completo**: [Guida Quick Reference](QUICK_REFERENCE.md)

### Comandi Utili

```bash
# Verifica connettività data-center
ping -c 4 10.1.0.1

# Verifica tunnel VPN
ipsec status

# Verifica routing
ip route show

# Test DNS
nslookup fse.regione.it

# Monitoraggio banda
iftop -i eth0

# Log VPN
tail -f /var/log/ipsec.log
```

### Checklist Pre-Produzione

- [ ] CPE configurato e testato
- [ ] VPN IPsec attiva e funzionante
- [ ] Firewall rules applicate
- [ ] VLAN configurate su switch
- [ ] DNS configurato correttamente
- [ ] Certificati SSL/TLS installati
- [ ] Test di trasferimento dati completato
- [ ] Backup locale configurato
- [ ] Monitoring attivo
- [ ] Documentazione consegnata

### Porte Pubbliche Esposte

| Servizio | Porta | Protocollo | Accesso |
|----------|-------|------------|---------|
| HTTPS FSE | 443 | TCP | Pubblico (autenticato) |
| SSH Gestione | 22 | TCP | Solo IP autorizzati |
| IPsec | 500, 4500 | UDP | VPN |

### Contatti Emergenza

- **NOC Regionale**: +39 XXX XXXXXXX (24/7)
- **Email Supporto**: support@regione-fibra.it
- **Ticketing**: https://helpdesk.regione-fibra.it

---

**Documento redatto il**: 30 Gennaio 2026  
**Versione**: 1.0  
**Autore**: Soluzione Esame A038_ORD24
