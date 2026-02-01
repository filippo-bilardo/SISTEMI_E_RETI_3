# SOLUZIONE PROVA A038 - SESSIONE SUPPLETIVA 2024

## Indice
1. [Prima Parte - Punto 1: Schema generale del sistema](#1-schema-generale-del-sistema)
2. [Prima Parte - Punto 2: Comunicazione con personale in loco](#2-comunicazione-con-personale-in-loco)
3. [Prima Parte - Punto 3: Tecnologie di comunicazione con totem](#3-tecnologie-di-comunicazione-con-totem)
4. [Prima Parte - Punto 4: Continuità di servizio](#4-continuità-di-servizio)
5. [Seconda Parte - Quesito I: Gestione filmati e immagini](#quesito-i---gestione-filmati-e-immagini)
6. [Seconda Parte - Quesito II: Gestione dispositivi remoti HTTP](#quesito-ii---gestione-dispositivi-remoti-http)

> **Nota (scelta quesiti seconda parte)**: come richiesto dal testo (*"due tra i quesiti proposti nella seconda parte"*), in questa soluzione vengono svolti **Quesito I** e **Quesito II**.

📌 **Guida rapida operativa**: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

---

# PRIMA PARTE

## 1. Schema generale del sistema

> **Riferimento al testo**: *"Sviluppi una descrizione di massima, anche supportata da uno schema grafico che presenti il sistema (organizzazione della rete informatica della sede operativa, modalità di connessione con le telecamere per il monitoraggio e i dispositivi remoti e loro attivazione e gestione), e ne ponga in evidenza i vari componenti hardware e software necessari, motivando le scelte effettuate."*

### 1.1 Ipotesi Aggiuntive

Per la progettazione del sistema, assumiamo le seguenti ipotesi:

1. **Dimensione evento**: fino a 50.000 partecipanti
2. **Area geografica**: circa 5 km² (centro storico + area evento)
3. **Totem informativi**: 15-20 unità distribuite nel territorio comunale
4. **Telecamere di monitoraggio**: 30-40 telecamere IP ad alta risoluzione
5. **Dispositivi remoti azionabili**: 25-30 (semafori, barriere, pannelli LED)
6. **Personale sede operativa**: 20 operatori (primo piano) + 10 addetti sala controllo (secondo piano)
7. **Personale in loco**: 50-80 addetti con dispositivi mobili
8. **Banda Internet**: connessione principale in fibra ottica 1 Gbps + backup 4G/5G

### 1.2 Architettura di Rete della Sede Operativa

📁 **File correlati:**
- [Diagramma di rete](diagrammi/schema_rete_sede.md)
- [Schema indirizzamento (mindmap)](diagrammi/schema_indirizzamento.mmd)
- [Piano di indirizzamento IP](configurazioni/piano_indirizzamento.md)
- [Configurazione VLAN](configurazioni/vlan_config.md)
- [Policy firewall (alto livello)](configurazioni/firewall_policy.md)

#### Struttura a due livelli della sede operativa:

**PRIMO PIANO - Area Assistenza Biglietteria**
- 20 postazioni operatore con PC desktop
- Server ticketing per gestione biglietti
- Connessione alla rete aziendale via switch managed
- VLAN dedicata (VLAN 10 - Ticketing)

**SECONDO PIANO - Sala Controllo**
- 10 postazioni con monitor multipli per videosorveglianza
- Server NVR (Network Video Recorder) per registrazione
- Workstation per gestione dispositivi remoti
- VLAN dedicata (VLAN 20 - Videosorveglianza)

#### Componenti Hardware della Sede Operativa

| Componente | Quantità | Descrizione | Motivazione |
|------------|----------|-------------|-------------|
| **Router Firewall** | 2 | Cisco ASA 5516-X (cluster HA) | Alta disponibilità, IPS integrato |
| **Switch Core** | 2 | Cisco Catalyst 9300 (stack) | Ridondanza, supporto PoE++, 10GbE |
| **Switch Access** | 4 | Cisco Catalyst 2960X | PoE per telefoni IP e access point |
| **Access Point** | 8 | Cisco Aironet 2802i | WiFi 6 per copertura interna |
| **Server Rack** | 1 | Dell PowerEdge R750 | Virtualizzazione VMware/Proxmox |
| **NAS Storage** | 1 | Synology RS3621xs+ (48TB) | Storage videosorveglianza |
| **UPS** | 2 | APC Smart-UPS 3000VA | Continuità elettrica |

#### Componenti Software

| Software | Funzione | Motivazione |
|----------|----------|-------------|
| **VMware vSphere** | Virtualizzazione | Consolidamento server, alta disponibilità |
| **Milestone XProtect** | VMS (Video Management) | Gestione telecamere IP, recording |
| **Custom Ticketing App** | Gestione biglietteria | Integrazione con totem e validazione |
| **Zabbix** | Network Monitoring | Monitoraggio proattivo infrastruttura |
| **OpenVPN/WireGuard** | VPN | Connessione sicura dispositivi remoti |
| **MQTT Broker (Mosquitto)** | IoT Communication | Gestione dispositivi azionabili |

### 1.3 Connessione Telecamere e Dispositivi Remoti

📁 **File correlati:**
- [Configurazione VPN](configurazioni/vpn_config.md)
- [Configurazione MQTT](configurazioni/mqtt_config.md)
- [Linee guida TLS/mTLS](configurazioni/tls_mtls.md)
- [Reverse proxy / API gateway (DMZ)](configurazioni/http_reverse_proxy.md)

#### Architettura di connessione per telecamere:

```
[Telecamere IP] --WiFi/4G--> [Gateway Edge] --VPN--> [Sede Operativa]
                                   |
                              [Storage locale]
                              (buffer 24h)
```

**Tecnologie utilizzate:**
1. **Telecamere IP con SIM 4G/5G**: per aree senza cablaggio
2. **Telecamere cablate PoE**: per postazioni fisse permanenti
3. **Gateway Edge Computing**: aggregazione flussi locali, riduzione banda

#### Architettura per dispositivi azionabili:

```
[Dispositivo Remoto] --HTTPS/MQTT--> [Gateway IoT] --VPN--> [Server Controllo]
     (Semaforo, Barriera, Pannello)
```

**Protocolli utilizzati:**
- **HTTPS** (porta 443): per comandi diretti via REST API
- **MQTT** (porta 8883 TLS): per comunicazione bidirezionale real-time
- **VPN WireGuard**: tunnel sicuro per tutto il traffico

### 1.4 Schema Grafico del Sistema

📁 **Visualizza il diagramma completo**: [schema_rete_sede.md](diagrammi/schema_rete_sede.md)

---

## 2. Comunicazione con personale in loco

> **Riferimento al testo**: *"Descriva in modo dettagliato le possibili modalità di comunicazione tra la sede operativa ed il personale in loco dedicato alla gestione del flusso delle persone partecipanti all'evento, anche in relazione alla validazione dei biglietti di ingresso."*

### 2.1 Modalità di Comunicazione

📁 **File correlati:**
- [Architettura App Mobile](configurazioni/app_mobile_arch.md)
- [API Validazione Biglietti](configurazioni/api_validazione.md)

#### A) Comunicazione Voce/Video

| Tecnologia | Utilizzo | Vantaggi |
|------------|----------|----------|
| **Push-to-Talk (PTT) su 4G/LTE** | Comunicazione istantanea gruppo | Latenza <500ms, gruppi dinamici |
| **VoIP (SIP)** | Chiamate punto-punto | Qualità audio superiore |
| **Video call** | Situazioni critiche | Verifica visiva in tempo reale |

**Soluzione consigliata**: App dedicata con funzionalità PTT (es. Zello, WAVE PTT) integrata con sistema VoIP aziendale.

#### B) Messaggistica e Notifiche

```
[Server Centrale] --Push Notification--> [App Mobile Operatori]
        |
        +--Firebase Cloud Messaging (Android)
        +--Apple Push Notification (iOS)
```

**Tipi di notifiche:**
- **Alert critici**: sovraffollamento, emergenze (priorità massima)
- **Aggiornamenti stato**: cambio stato dispositivi remoti
- **Comunicazioni operative**: turni, assegnazioni zone

#### C) Validazione Biglietti

📁 **Vedi configurazione completa**: [api_validazione.md](configurazioni/api_validazione.md)
📁 **Diagramma di sequenza**: [sequence_validazione.md](diagrammi/sequence_validazione.md)

**Flusso di validazione:**

```
1. Operatore scansiona QR/Barcode biglietto
2. App invia richiesta API al server centrale
3. Server verifica: validità, non già utilizzato, evento corretto
4. Server risponde: OK/ERRORE + dettagli partecipante
5. App mostra esito + registra ingresso
```

**Tecnologie per scansione:**
- **QR Code**: biglietti digitali su smartphone
- **Barcode 1D/2D**: biglietti cartacei
- **NFC**: per braccialetti/card RFID (eventi premium)

**Gestione offline:**
- Cache locale degli ultimi biglietti validati
- Sincronizzazione al ripristino connessione
- Firma crittografica biglietti per validazione locale

### 2.2 Dispositivi per Personale in Loco

| Dispositivo | Caratteristiche | Utilizzo |
|-------------|-----------------|----------|
| **Smartphone rugged** | IP68, Android Enterprise | Validazione, comunicazione |
| **Tablet 8"** | Schermo più grande | Supervisori, mappe zone |
| **Auricolare Bluetooth** | Mani libere | Comunicazione continua |

---

## 3. Tecnologie di comunicazione con totem

> **Riferimento al testo**: *"Definisca le tecnologie di comunicazione tra la sede operativa e i punti di informazione (totem) dislocati sull'intera area del comune."*

### 3.1 Architettura di Connessione Totem

📁 **File correlati:**
- [Configurazione Totem](configurazioni/totem_config.md)
- [Linee guida TLS/mTLS](configurazioni/tls_mtls.md)

#### Opzioni di connettività:

| Tecnologia | Copertura | Banda | Latenza | Costo | Affidabilità |
|------------|-----------|-------|---------|-------|--------------|
| **Fibra FTTH** | Fissa | 1 Gbps | <5ms | Alto (installazione) | Molto alta |
| **4G/LTE** | Mobile | 50-150 Mbps | 30-50ms | Medio | Alta |
| **5G** | Mobile | 1+ Gbps | <10ms | Alto | Alta |
| **WiFi Mesh** | Locale | 300+ Mbps | <20ms | Medio | Media |

#### Soluzione proposta: Approccio ibrido

```
[Totem Zona A] --Fibra--> [Router sede] ---> [Server Centrale]
    (Centro storico - cablatura esistente)

[Totem Zona B] --4G/LTE--> [APN Privato] --VPN--> [Server Centrale]
    (Aree periferiche - connessione mobile)

[Totem Zona C] --WiFi Mesh--> [Gateway PoP] --Fibra--> [Server Centrale]
    (Area evento - rete dedicata temporanea)
```

### 3.2 Specifiche Tecniche Totem

**Hardware:**
- Display touch 32-55" (esterno: IP65, antivandalico)
- PC embedded (Intel NUC o ARM)
- Lettore carte di pagamento (PCI DSS compliant)
- Stampante termica per biglietti
- Webcam (assistenza remota opzionale)

**Software:**
- Sistema operativo: Linux embedded (Ubuntu Core/Yocto)
- Applicazione kiosk: Electron o Web app (Chrome Kiosk mode)
- Gestione remota: RMM (Remote Monitoring Management)

**Protocolli:**
- **HTTPS** (TLS 1.3): comunicazione con server
- **WebSocket**: aggiornamenti real-time disponibilità
- **MQTT**: heartbeat e telemetria

### 3.3 Sicurezza Comunicazioni Totem

| Misura | Descrizione |
|--------|-------------|
| **VPN** | Tunnel IPsec o WireGuard verso sede |
| **Certificati client** | Autenticazione mutua TLS |
| **Firewall locale** | Solo porte necessarie aperte |
| **Crittografia storage** | LUKS per dati sensibili |
| **Aggiornamenti OTA** | Firmware firmati digitalmente |

---

## 4. Continuità di servizio

> **Riferimento al testo**: *"Descriva la modalità attraverso le quali sarà possibile evitare interruzioni di servizio."*

### 4.1 Strategie di Alta Disponibilità (HA)

📁 **File correlati:**
- [Configurazione HA](configurazioni/high_availability.md)
- [Piano Disaster Recovery](configurazioni/disaster_recovery.md)

#### A) Ridondanza Hardware

| Componente | Strategia | RTO | RPO |
|------------|-----------|-----|-----|
| **Firewall** | Cluster Active/Standby | <30s | 0 |
| **Switch Core** | Stack con failover | <5s | 0 |
| **Server** | VMware HA Cluster | <2min | 0 |
| **Storage** | RAID 6 + replica offsite | <1h | 15min |
| **Connettività** | Dual WAN (Fibra + 4G) | <10s | 0 |

#### B) Ridondanza Software/Servizi

```
                    [Load Balancer]
                    (HAProxy/Nginx)
                         |
            +------------+------------+
            |            |            |
        [App Server 1] [App Server 2] [App Server 3]
            |            |            |
            +------------+------------+
                         |
                    [Database Cluster]
                    (PostgreSQL HA)
                    Primary + 2 Replica
```

#### C) Continuità Elettrica

| Livello | Dispositivo | Autonomia | Carico |
|---------|-------------|-----------|--------|
| **UPS Online** | APC Smart-UPS 3000VA | 30 min | Server/Switch critici |
| **Gruppo elettrogeno** | 50 kVA diesel | 24+ ore | Intera sede |
| **PDU ridondanti** | APC Metered | N/A | Rack server |

### 4.2 Piano di Backup

📁 **Vedi script**: [script/backup_script.sh](script/backup_script.sh)

| Dato | Frequenza | Retention | Destinazione |
|------|-----------|-----------|--------------|
| **Database ticketing** | Ogni 15 min | 30 giorni | NAS locale + Cloud |
| **Configurazioni rete** | Giornaliero | 90 giorni | Git + NAS |
| **Video sorveglianza** | Continuo | 30 giorni | NAS dedicato |
| **VM server** | Snapshot giornalieri | 7 giorni | Storage secondario |

### 4.3 Monitoraggio Proattivo

📁 **Vedi configurazione**: [configurazioni/monitoring.md](configurazioni/monitoring.md)

**Sistema di monitoraggio: Zabbix**

Metriche monitorate:
- Stato servizi (HTTP, database, VPN)
- Utilizzo risorse (CPU, RAM, disco, banda)
- Latenza e packet loss verso dispositivi remoti
- Temperatura e stato UPS
- Validità certificati SSL

**Alert e escalation:**
```
Livello 1 (Warning) --> Email + Slack
Livello 2 (Critical) --> SMS + Chiamata
Livello 3 (Disaster) --> Attivazione DR + Chiamata manager
```

### 4.4 Procedure di Disaster Recovery

| Scenario | Azione | Tempo Ripristino |
|----------|--------|------------------|
| Guasto singolo server | Failover automatico HA | <2 minuti |
| Guasto storage | Attivazione replica | <15 minuti |
| Guasto connettività principale | Failover su 4G backup | <30 secondi |
| Disastro sede (incendio) | Attivazione sito DR | <4 ore |

---

# SECONDA PARTE

## Quesito I - Gestione filmati e immagini

> **Riferimento al testo**: *"In relazione al tema proposto nella prima parte, si consideri la gestione dei filmati e delle immagini che vengono trasmessi dalle telecamere per il monitoraggio, e si propongano soluzioni per il relativo salvataggio all'interno dell'infrastruttura della sede centrale oppure nel cloud, definendone vantaggi e svantaggi."*

### Soluzione 1: Storage On-Premise (Sede Centrale)

📁 **File correlati:**
- [Configurazione NVR](configurazioni/nvr_config.md)

#### Architettura

```
[Telecamere IP] --RTSP/ONVIF--> [NVR Server] --> [NAS Storage]
                                     |              (RAID 6)
                                     |
                              [VMS Software]
                              (Milestone XProtect)
```

#### Dimensionamento Storage

| Parametro | Valore |
|-----------|--------|
| N° telecamere | 40 |
| Risoluzione | 4K (8 Mpx) |
| FPS | 15 |
| Compressione | H.265 |
| Bitrate medio | 4 Mbps |
| Retention | 30 giorni |

**Calcolo:**
- Storage giornaliero per camera: 4 Mbps × 86400s / 8 = 43.2 GB/giorno
- Storage totale 30 giorni: 40 × 43.2 × 30 = **51.84 TB**
- Con RAID 6 (8 dischi): circa **72 TB raw** necessari

#### Vantaggi On-Premise

| Vantaggio | Descrizione |
|-----------|-------------|
| ✅ Latenza minima | Accesso immediato ai filmati |
| ✅ Controllo totale | Dati sempre sotto gestione diretta |
| ✅ Nessun costo banda | No upload verso cloud |
| ✅ Privacy | Dati non escono dalla sede |
| ✅ Costo prevedibile | No costi variabili mensili |

#### Svantaggi On-Premise

| Svantaggio | Descrizione |
|------------|-------------|
| ❌ Investimento iniziale | Hardware costoso |
| ❌ Manutenzione | Responsabilità gestione HW |
| ❌ Scalabilità limitata | Espansione richiede nuovo HW |
| ❌ Vulnerabilità fisica | Rischio danni sede (incendio, furto) |

---

### Soluzione 2: Storage Cloud

#### Architettura

```
[Telecamere IP] --RTSP--> [Gateway Edge] --HTTPS--> [Cloud Storage]
                               |                     (AWS S3/Azure Blob)
                          [Cache locale]                   |
                          (buffer 24h)              [Cloud VMS]
                                                   (AWS Kinesis Video)
```

#### Provider e servizi consigliati

| Provider | Servizio | Utilizzo |
|----------|----------|----------|
| **AWS** | Kinesis Video Streams | Ingest e playback |
| **AWS** | S3 Glacier | Archiviazione lungo termine |
| **Azure** | Media Services | Transcoding e streaming |
| **Google** | Cloud Storage | Archiviazione economica |

#### Vantaggi Cloud

| Vantaggio | Descrizione |
|-----------|-------------|
| ✅ Scalabilità infinita | Aumento storage on-demand |
| ✅ No manutenzione HW | Gestito dal provider |
| ✅ Geo-ridondanza | Dati replicati in più regioni |
| ✅ Disaster recovery | Resistenza a disastri locali |
| ✅ Accesso ovunque | Visualizzazione da qualsiasi luogo |

#### Svantaggi Cloud

| Svantaggio | Descrizione |
|------------|-------------|
| ❌ Costi ricorrenti | Pagamento mensile storage + banda |
| ❌ Dipendenza banda | Richiede upload costante elevato |
| ❌ Latenza | Ritardo accesso rispetto a locale |
| ❌ Privacy/GDPR | Dati su server terzi (compliance) |
| ❌ Lock-in vendor | Difficoltà cambio provider |

---

### Soluzione 3: Approccio Ibrido (Raccomandato)

#### Architettura

```
[Telecamere] --> [NVR Locale] --> [Storage Locale]
                      |               (ultimi 7 giorni)
                      |
                      +--> [Sync notturno] --> [Cloud Archive]
                                               (storico 30+ giorni)
```

#### Strategia consigliata

| Periodo | Storage | Accesso |
|---------|---------|---------|
| 0-7 giorni | On-premise (NAS) | Immediato, alta qualità |
| 7-30 giorni | Cloud (S3 Standard) | 2-5 secondi |
| 30+ giorni | Cloud (S3 Glacier) | 3-5 ore (archivio) |

**Vantaggi approccio ibrido:**
- Accesso rapido ai filmati recenti
- Costi cloud contenuti (solo archiviazione)
- Protezione da disastri locali
- Compliance GDPR (dati critici in Italia, archiviazione EU)

---

## Quesito II - Gestione dispositivi remoti HTTP

> **Riferimento al testo**: *"In relazione al tema proposto nella prima parte, si discuta come possono essere attivati e gestiti i dispositivi remoti dotati di server HTTP interno, utilizzando i metodi propri di questo protocollo, fornendo opportune esemplificazioni."*

### Architettura di Gestione Dispositivi

📁 **File correlati:**
- [API Dispositivi Remoti](configurazioni/api_dispositivi.md)
- [Script Controllo Dispositivi](script/controllo_dispositivi.sh)
- [Logging e audit](configurazioni/logging_audit.md)

#### Schema di comunicazione

```
[Operatore Sala Controllo]
         |
         v
[Applicazione Web Gestione]
         |
         v (REST API interna)
[Server Backend]
         |
         v (HTTPS + Autenticazione)
[VPN Gateway]
         |
         v (Tunnel sicuro)
[Dispositivo Remoto con HTTP Server]
   - Semaforo
   - Barriera
   - Pannello LED
```

### Metodi HTTP per Gestione Dispositivi

#### 1. GET - Lettura stato dispositivo

```http
GET /api/v1/status HTTP/1.1
Host: semaforo-zona-a.local
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# Risposta
HTTP/1.1 200 OK
Content-Type: application/json

{
    "device_id": "SEM-001",
    "type": "traffic_light",
    "status": "active",
    "current_state": "green",
    "timestamp": "2024-07-15T14:30:00Z",
    "battery_level": 95,
    "last_command": "set_green",
    "uptime_seconds": 86400
}
```

#### 2. POST - Invio comando al dispositivo

```http
POST /api/v1/command HTTP/1.1
Host: semaforo-zona-a.local
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
    "action": "set_state",
    "parameters": {
        "state": "red",
        "duration": 300,
        "flash": false
    },
    "operator_id": "OP-042",
    "reason": "Sovraffollamento zona A"
}

# Risposta
HTTP/1.1 200 OK
Content-Type: application/json

{
    "success": true,
    "command_id": "CMD-2024071514300001",
    "executed_at": "2024-07-15T14:30:01Z",
    "previous_state": "green",
    "new_state": "red"
}
```

#### 3. PUT - Aggiornamento configurazione

```http
PUT /api/v1/config HTTP/1.1
Host: pannello-info-01.local
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
Content-Type: application/json

{
    "display_message": "EVENTO IN CORSO - Seguire indicazioni",
    "scroll_speed": "medium",
    "brightness": 80,
    "language": "it"
}

# Risposta
HTTP/1.1 200 OK
Content-Type: application/json

{
    "success": true,
    "config_updated": true,
    "effective_from": "2024-07-15T14:31:00Z"
}
```

#### 4. DELETE - Reset/Disattivazione

```http
DELETE /api/v1/schedule/123 HTTP/1.1
Host: barriera-ingresso-b.local
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

# Risposta
HTTP/1.1 204 No Content
```

### Esempi Pratici di Gestione

#### Esempio 1: Gestione Semaforo Pedonale

📁 **Script completo**: [script/controllo_semaforo.py](script/controllo_semaforo.py)

#### Esempio 2: Controllo Barriera Automatica

📁 **Esempio via shell/curl**: [script/controllo_dispositivi.sh](script/controllo_dispositivi.sh)

#### Esempio 3: Aggiornamento Pannello Informativo

📁 **Nota**: la stessa logica (PUT su `/api/v1/config`) è descritta in [api_dispositivi.md](configurazioni/api_dispositivi.md) ed è normalmente orchestrata dalla dashboard/Backend (non dal device mobile).

### Sicurezza delle Comunicazioni HTTP

| Misura | Implementazione |
|--------|-----------------|
| **HTTPS obbligatorio** | TLS 1.3, certificati Let's Encrypt |
| **Autenticazione** | JWT Token con scadenza 1h |
| **Autorizzazione** | RBAC (Role-Based Access Control) |
| **Rate limiting** | Max 100 req/min per dispositivo |
| **Logging** | Ogni comando registrato con timestamp e operatore |
| **VPN** | Tutto il traffico passa per tunnel WireGuard |

### Dashboard di Controllo

L'interfaccia web per gli operatori permette di:
- Visualizzare mappa con stato real-time di tutti i dispositivi
- Inviare comandi singoli o di gruppo
- Programmare azioni temporizzate
- Consultare storico comandi e audit log
- Ricevere alert su malfunzionamenti

---

## Riferimenti ai File Creati

| File | Descrizione |
|------|-------------|
| [diagrammi/schema_rete_sede.md](diagrammi/schema_rete_sede.md) | Schema grafico della rete |
| [diagrammi/schema_indirizzamento.mmd](diagrammi/schema_indirizzamento.mmd) | Mindmap piano indirizzamento |
| [diagrammi/sequence_validazione.md](diagrammi/sequence_validazione.md) | Sequenza validazione biglietto |
| [configurazioni/piano_indirizzamento.md](configurazioni/piano_indirizzamento.md) | Piano IP completo |
| [configurazioni/vlan_config.md](configurazioni/vlan_config.md) | Configurazione VLAN |
| [configurazioni/firewall_policy.md](configurazioni/firewall_policy.md) | Policy firewall (alto livello) |
| [configurazioni/vpn_config.md](configurazioni/vpn_config.md) | Configurazione VPN WireGuard |
| [configurazioni/mqtt_config.md](configurazioni/mqtt_config.md) | Configurazione broker MQTT |
| [configurazioni/tls_mtls.md](configurazioni/tls_mtls.md) | Linee guida TLS/mTLS |
| [configurazioni/http_reverse_proxy.md](configurazioni/http_reverse_proxy.md) | Policy reverse proxy / API gateway |
| [configurazioni/logging_audit.md](configurazioni/logging_audit.md) | Logging e audit |
| [configurazioni/api_validazione.md](configurazioni/api_validazione.md) | API validazione biglietti |
| [configurazioni/api_dispositivi.md](configurazioni/api_dispositivi.md) | API dispositivi remoti |
| [configurazioni/totem_config.md](configurazioni/totem_config.md) | Configurazione totem |
| [configurazioni/high_availability.md](configurazioni/high_availability.md) | Configurazione HA |
| [configurazioni/disaster_recovery.md](configurazioni/disaster_recovery.md) | Piano DR |
| [configurazioni/monitoring.md](configurazioni/monitoring.md) | Configurazione monitoraggio |
| [configurazioni/nvr_config.md](configurazioni/nvr_config.md) | Configurazione NVR |
| [configurazioni/cloud_storage_video.md](configurazioni/cloud_storage_video.md) | Linee guida salvataggio video su cloud |
| [configurazioni/app_mobile_arch.md](configurazioni/app_mobile_arch.md) | Architettura app mobile |
| [script/backup_script.sh](script/backup_script.sh) | Script backup automatico |
| [script/controllo_dispositivi.sh](script/controllo_dispositivi.sh) | Script controllo dispositivi |
| [script/controllo_semaforo.py](script/controllo_semaforo.py) | Esempio Python controllo semaforo |
| [script/README.md](script/README.md) | Note e prerequisiti script |
| [QUICK_REFERENCE.md](QUICK_REFERENCE.md) | Guida rapida operativa |
