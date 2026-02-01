# DIAGRAMMA DI RETE DETTAGLIATO

## Riferimento alla Prova

**Testo**: "Sviluppi una descrizione di massima, anche supportata da uno **schema grafico**, dell'infrastruttura di rete in fibra pre-esistente..."

---

## 1. SCHEMA GENERALE INFRASTRUTTURA REGIONALE

```
                    ╔═══════════════════════════════════════════╗
                    ║     DATA-CENTER REGIONALE - 10.1.0.0/24   ║
                    ╚═══════════════════════════════════════════╝
                                        │
                    ┌───────────────────┴───────────────────┐
                    │                                       │
         ╔══════════════════════════════╗     ╔═══════════════════════╗
         ║   CORE ROUTER PRIMARIO       ║◄───►║  CORE ROUTER BACKUP   ║
         ║   (Active)                   ║     ║  (Standby)            ║
         ║   VRRP: 10.1.0.1             ║     ║  VRRP: 10.1.0.2       ║
         ╚══════════════════════════════╝     ╚═══════════════════════╝
                    │
         ┌──────────┴──────────┬────────────────┬─────────────────┐
         │                     │                │                 │
    ┌────┴────┐          ┌────┴─────┐    ┌─────┴──────┐    ┌────┴──────┐
    │         │          │          │    │            │    │           │
┌───▼────────────┐  ┌───▼─────────────┐ ┌▼───────────────┐ ┌▼──────────────┐
│  ENTI LOCALI   │  │    SCUOLE       │ │ STRUTT. SAN.   │ │  STRUTT. SAN. │
│                │  │                 │ │ PUBBLICHE      │ │  PRIVATE      │
│ 10.10.0.0/16   │  │  10.20.0.0/16   │ │ 10.30.0.0/16   │ │ 10.100.0.0/16 │
└────────────────┘  └─────────────────┘ └────────────────┘ └───────────────┘
  ~500 sedi           ~300 sedi          ~100 strutture      ~2000 strutture
```

---

## 2. DATA-CENTER REGIONALE - Architettura Dettagliata

```
┌───────────────────────────────────────────────────────────────────────┐
│                    DATA-CENTER REGIONALE - 10.1.0.0/24                │
├───────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │              DMZ - Zona Demilitarizzata                       │   │
│  │                    10.1.0.100/28                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │   │
│  │  │  Web Server  │  │  API Gateway │  │ Load Balancer│       │   │
│  │  │  FSE Portal  │  │   REST API   │  │   (HAProxy)  │       │   │
│  │  │ 10.1.0.101   │  │ 10.1.0.102   │  │  10.1.0.100  │       │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘       │   │
│  └─────────────────────────┬──────────────────────────────────┘   │
│                            │                                        │
│  ┌─────────────────────────┴──────────────────────────────────┐   │
│  │                 FIREWALL LAYER                              │   │
│  │          ┌──────────────┐    ┌──────────────┐              │   │
│  │          │ Firewall #1  │◄──►│ Firewall #2  │              │   │
│  │          │  (Active)    │    │  (Standby)   │              │   │
│  │          │ 10.1.0.254   │    │ 10.1.0.253   │              │   │
│  │          └──────┬───────┘    └──────┬───────┘              │   │
│  └─────────────────┼────────────────────┼──────────────────────┘   │
│                    │                    │                           │
│  ┌─────────────────┴────────────────────┴──────────────────────┐   │
│  │              APPLICATION LAYER - 10.1.0.10/27              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │ App Server 1 │  │ App Server 2 │  │ App Server 3 │     │   │
│  │  │FSE Backend   │  │FSE Backend   │  │FSE Backend   │     │   │
│  │  │ 10.1.0.11    │  │ 10.1.0.12    │  │ 10.1.0.13    │     │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │   │
│  └──────────────────────────┬─────────────────────────────────┘   │
│                             │                                      │
│  ┌──────────────────────────┴─────────────────────────────────┐   │
│  │            DATABASE LAYER - 10.1.0.30/27                   │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │ DB Master    │  │  DB Slave 1  │  │  DB Slave 2  │     │   │
│  │  │ PostgreSQL   │──┤ (Read        │  │ (Disaster    │     │   │
│  │  │ Cluster      │  │  Replica)    │  │  Recovery)   │     │   │
│  │  │ 10.1.0.31    │  │ 10.1.0.32    │  │ 10.1.0.33    │     │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │   │
│  └──────────────────────────┬─────────────────────────────────┘   │
│                             │                                      │
│  ┌──────────────────────────┴─────────────────────────────────┐   │
│  │            STORAGE LAYER - 10.1.0.50/27                    │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │   │
│  │  │ SAN Storage  │  │  NAS Backup  │  │ Object Store │     │   │
│  │  │ (Primario)   │  │  (Backup)    │  │ (Immagini)   │     │   │
│  │  │ 10.1.0.51    │  │ 10.1.0.52    │  │ 10.1.0.53    │     │   │
│  │  │ RAID 10      │  │ RAID 6       │  │ S3-like      │     │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │        MANAGEMENT & MONITORING - 10.1.0.200/28             │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │   │
│  │  │  SIEM    │ │ Zabbix   │ │  Backup  │ │   DNS    │      │   │
│  │  │  Server  │ │Monitoring│ │  Server  │ │  Servers │      │   │
│  │  │10.1.0.201│ │10.1.0.202│ │10.1.0.203│ │10.1.0.10 │      │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │   │
│  └────────────────────────────────────────────────────────────┘   │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. INFRASTRUTTURA STRUTTURE SANITARIE PRIVATE

```
┌──────────────────────────────────────────────────────────────────────┐
│          EDGE ROUTER AGGREGAZIONE STRUTTURE PRIVATE                  │
│                     10.1.0.5 (interfaccia core)                      │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────┐     │
│  │            Multi-Layer Switch con VLAN Support             │     │
│  │                                                             │     │
│  │  VLAN 101-2148: Una VLAN per ogni struttura (2048 VLAN)    │     │
│  │  Firewall integrato per isolamento inter-VLAN              │     │
│  │  QoS per prioritizzare traffico FSE                        │     │
│  └────┬────────┬────────┬────────┬─────────────┬─────────────┘     │
└───────┼────────┼────────┼────────┼─────────────┼───────────────────┘
        │        │        │        │             │
   ┌────┘        │        │        │             └────┐
   │             │        │        │                  │
   │ Fibra       │        │        │                  │ Fibra
   │ Ottica      │        │        │                  │ Ottica
   │ 1Gbps       │        │        │                  │ 1Gbps
   │             │        │        │                  │

┌──▼────────┐ ┌─▼─────────┐  ...  ┌▼─────────┐  ┌───▼──────────┐
│CPE Router │ │CPE Router │       │CPE Router│  │ CPE Router   │
│Struttura#1│ │Struttura#2│       │Struttura │  │ Struttura    │
│           │ │           │       │#1000     │  │ #2000      │
│10.100.0.33│ │10.100.0.65│       │10.100.   │  │ 10.100.      │
└─────┬─────┘ └────┬──────┘       │125.1     │  │ 249.193      │
      │            │              └────┬─────┘  └──────┬───────┘
      │            │                   │               │
      │            │                   │               │
```

---

## 4. DETTAGLIO STRUTTURA SANITARIA PRIVATA TIPO

### Esempio: Clinica Privata "San Marco" - 10.100.0.32/27

```
┌─────────────────────────────────────────────────────────────────────┐
│                    RETE REGIONALE FIBRA OTTICA                      │
│                         10.1.0.0/24 ◄───► Internet                  │
└──────────────────────────┬──────────────────────────────────────────┘
                           │ Fibra Ottica 1Gbps
                           │
                ┌──────────▼────────────┐
                │   CPE ROUTER FORNITO  │
                │   DALLA REGIONE       │
                ├───────────────────────┤
                │ WAN: 10.100.0.33/27   │ ◄─── Porta verso rete regionale
                │ Gateway: 10.100.0.1   │
                │                       │
                │ LAN: 192.168.1.1/24   │ ◄─── Porta verso LAN interna
                ├───────────────────────┤
                │ Funzioni:             │
                │ • NAT                 │
                │ • Firewall            │
                │ • VPN IPsec           │
                │ • QoS                 │
                │ • DHCP Server         │
                └───────┬───────────────┘
                        │ Cat6 Ethernet
                        │
        ┌───────────────┴───────────────┐
        │                               │
┌───────▼────────┐              ┌───────▼────────┐
│ SWITCH GESTITO │              │ ROUTER INTERNET│
│   24 Porte     │              │   (Esistente)  │
│   Managed      │              │                │
│                │              │ WAN: ADSL/FTTH │
│ VLAN 10: FSE   │              │ LAN: 192.168.2.1│
│ VLAN 20: Admin │              └────────┬───────┘
│ VLAN 30: Guest │                       │
└───────┬────────┘              ┌────────▼────────┐
        │                       │ Switch 8 Porte  │
        │                       │ (Internet zone) │
   ┌────┴────┐                  └─────────────────┘
   │         │                           │
   │         │                           │
   │   ┌─────┴─────────────────────┬────┴────┬─────────┐
   │   │                           │         │         │
   │   │                           │         │         │
┌──▼───▼──────┐  ┌────────────┐ ┌─▼──────┐ ┌▼────────┐ ┌─────────┐
│ VLAN 10: FSE│  │ VLAN 20:   │ │Access  │ │  PC     │ │ PC      │
│             │  │ Admin      │ │Point   │ │ Admin   │ │ Admin   │
│             │  │            │ │WiFi    │ │         │ │         │
│ ┌─────────┐ │  │ ┌────────┐ │ │        │ │Internet │ │Internet │
│ │Workst.  │ │  │ │Server  │ │ │Guest   │ │         │ │         │
│ │Medico #1│ │  │ │Locale  │ │ │Network │ └─────────┘ └─────────┘
│ │         │ │  │ │File/   │ │ │        │
│ │FSE      │ │  │ │Backup  │ │ │SSID:   │
│ │Access   │ │  │ │        │ │ │Clinica │
│ └─────────┘ │  │ └────────┘ │ │Guest   │
│             │  │            │ └────────┘
│ ┌─────────┐ │  │ ┌────────┐ │
│ │Workst.  │ │  │ │Printer │ │
│ │Medico #2│ │  │ │Network │ │
│ └─────────┘ │  │ └────────┘ │
│             │  │            │
│ ┌─────────┐ │  └────────────┘
│ │Ecografo │ │
│ │Connesso │ │
│ │Rete     │ │
│ └─────────┘ │
│             │
│ ┌─────────┐ │
│ │ECG      │ │
│ │Digitale │ │
│ └─────────┘ │
└─────────────┘
```

### Tabella Dispositivi e Indirizzi

#### Zona FSE (VLAN 10 - Accesso a FSE Regionale)
| Dispositivo | Indirizzo IP LAN | VLAN | Accesso | Note |
|-------------|------------------|------|---------|------|
| CPE Router (LAN) | 192.168.1.1 | Trunk | Gateway | NAT verso 10.100.0.33 |
| Workstation Medico #1 | 192.168.1.11 | 10 | FSE | Accesso FSE via CPE |
| Workstation Medico #2 | 192.168.1.12 | 10 | FSE | Accesso FSE via CPE |
| Workstation Medico #3 | 192.168.1.13 | 10 | FSE | Accesso FSE via CPE |
| Ecografo Connesso | 192.168.1.21 | 10 | FSE | Invio immagini a FSE |
| ECG Digitale | 192.168.1.22 | 10 | FSE | Invio tracciati a FSE |
| Tablet Medici (DHCP) | 192.168.1.50-70 | 10 | FSE | Pool DHCP riservato |

#### Zona Amministrativa (VLAN 20 - Uso Interno)
| Dispositivo | Indirizzo IP LAN | VLAN | Accesso | Note |
|-------------|------------------|------|---------|------|
| Server File Locale | 192.168.1.100 | 20 | Interno | Backup locale dati |
| Server Backup | 192.168.1.101 | 20 | Interno | Backup giornaliero |
| Stampante di Rete | 192.168.1.110 | 20 | Interno | Stampa referti |
| NAS Storage | 192.168.1.111 | 20 | Interno | Archiviazione locale |

#### Zona Internet (Via Router Esistente)
| Dispositivo | Indirizzo IP LAN | Accesso | Note |
|-------------|------------------|---------|------|
| Router Internet | 192.168.2.1 | Internet | Router ADSL/FTTH esistente |
| PC Amministrativi | 192.168.2.10-30 | Internet | Email, navigazione web |
| Access Point Guest | 192.168.2.40 | Internet | WiFi per visitatori |

---

## 5. FLUSSO DATI - Invio Prestazione a FSE

```
┌──────────────────────────────────────────────────────────────────────┐
│  FLUSSO: Workstation Medico → FSE Data-Center                       │
└──────────────────────────────────────────────────────────────────────┘

  Workstation Medico #1                     CPE Router
  192.168.1.11                              192.168.1.1 (LAN)
       │                                    10.100.0.33 (WAN)
       │                                          │
       │  1. HTTP POST                            │
       │  https://fse.regione.it/api/prestazioni  │
       │  SRC: 192.168.1.11:54321                 │
       │  DST: 10.1.0.102:443                     │
       ├──────────────────────────────────────────►
       │                                          │
       │                              2. NAT      │
       │                         192.168.1.11 →   │
       │                         10.100.0.33      │
       │                                          │
       │                                          │
       │                              3. VPN IPsec Tunnel
       │                         Cifratura AES-256│
       │                                          │
       │                         SRC: 10.100.0.33:443
       │                         DST: 10.1.0.102:443
       │                                          │
                                                  │
                                                  ▼
                                    ┌─────────────────────────┐
                                    │  Edge Router Regionale  │
                                    │  Verifica Firewall      │
                                    │  - Allow 10.100.x → 10.1│
                                    │  - Deny 10.100.x → 10.100│
                                    └────────────┬────────────┘
                                                 │
                                                 │ 4. Routing
                                                 │
                                                 ▼
                                    ┌─────────────────────────┐
                                    │   Firewall Data-Center  │
                                    │   Inspect SSL/TLS       │
                                    │   IDS/IPS Check         │
                                    └────────────┬────────────┘
                                                 │
                                                 │ 5. Load Balancer
                                                 │
                                                 ▼
                                    ┌─────────────────────────┐
                                    │   API Gateway           │
                                    │   10.1.0.102            │
                                    │   - Autenticazione      │
                                    │   - Rate Limiting       │
                                    │   - Logging             │
                                    └────────────┬────────────┘
                                                 │
                                                 │ 6. Backend Call
                                                 │
                                                 ▼
                                    ┌─────────────────────────┐
                                    │  App Server FSE         │
                                    │  10.1.0.11              │
                                    │  - Validazione dati     │
                                    │  - Business Logic       │
                                    └────────────┬────────────┘
                                                 │
                                                 │ 7. Database Write
                                                 │
                                                 ▼
                                    ┌─────────────────────────┐
                                    │  Database PostgreSQL    │
                                    │  10.1.0.31              │
                                    │  - INSERT prestazione   │
                                    │  - Replica su slave     │
                                    └─────────────────────────┘
                                                 │
                                                 │ 8. Storage File
                                                 │ (se allegati)
                                                 ▼
                                    ┌─────────────────────────┐
                                    │  Object Storage         │
                                    │  10.1.0.53              │
                                    │  - Save immagini/PDF    │
                                    └─────────────────────────┘

       ◄────────────────── 9. Response 200 OK ────────────────────
       │                                          │
       │  Conferma inserimento prestazione        │
       │  Transaction ID: 123456789               │
       │                                          │
```

---

## 6. TOPOLOGIA FISICA - Fibra Ottica

```
                          DATA-CENTER CENTRALE
                                  │
                    ┌─────────────┴─────────────┐
                    │  BACKBONE FIBRA OTTICA    │
                    │  Anello Ridondante        │
                    │  10 Gbps                  │
                    └─────────┬─────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
         ┌────▼─────┐   ┌────▼─────┐   ┌─────▼────┐
         │ POP      │   │ POP      │   │ POP      │
         │ Nord     │   │ Centro   │   │ Sud      │
         │          │   │          │   │          │
         └────┬─────┘   └────┬─────┘   └─────┬────┘
              │              │                │
    ┌─────────┼──────┐       │        ┌───────┼────────┐
    │         │      │       │        │       │        │
┌───▼───┐ ┌──▼───┐  │   ┌───▼───┐ ┌──▼───┐ ┌▼────┐ ┌─▼────┐
│Strutt.│ │Strutt│  │   │Strutt.│ │Strutt│ │Stru │ │Strutt│
│#1-200 │ │#201- │  │   │#801-  │ │#1201-│ │#1601│ │#1801-│
│       │ │#400  │  │   │#1000  │ │#1400 │ │#1800│ │#2000 │
└───────┘ └──────┘  │   └───────┘ └──────┘ └─────┘ └──────┘
                    │
              ┌─────▼──────┐
              │ Strutture  │
              │ #401-#800  │
              └────────────┘

Legenda:
• POP = Point of Presence (Nodo distribuzione regionale)
• Ogni POP gestisce un gruppo di strutture della sua area
• Fibra dedicata 1 Gbps per ogni struttura
• Ridondanza: Doppio percorso in fibra per ogni POP
```

---

## 7. SCHEMA SICUREZZA MULTI-LAYER

```
┌─────────────────────────────────────────────────────────────────┐
│                      SECURITY LAYERS                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Layer 7: Application Security                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ • WAF (Web Application Firewall)                      │     │
│  │ • API Authentication (OAuth 2.0)                      │     │
│  │ • Input Validation                                    │     │
│  │ • SQL Injection Protection                            │     │
│  └───────────────────────────────────────────────────────┘     │
│                              │                                  │
│  Layer 4-6: Transport Security                                 │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ • TLS 1.3 Encryption                                  │     │
│  │ • Certificate Validation                              │     │
│  │ • Perfect Forward Secrecy                             │     │
│  └───────────────────────────────────────────────────────┘     │
│                              │                                  │
│  Layer 3: Network Security                                     │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ • IPsec VPN Tunnels                                   │     │
│  │ • Firewall ACLs                                       │     │
│  │ • IDS/IPS (Intrusion Detection/Prevention)           │     │
│  │ • Network Segmentation (VLAN)                         │     │
│  └───────────────────────────────────────────────────────┘     │
│                              │                                  │
│  Layer 2: Data Link Security                                   │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ • 802.1X Port Authentication                          │     │
│  │ • MAC Address Filtering                               │     │
│  │ • Private VLANs                                       │     │
│  └───────────────────────────────────────────────────────┘     │
│                              │                                  │
│  Layer 1: Physical Security                                    │
│  ┌───────────────────────────────────────────────────────┐     │
│  │ • Fibra Ottica Dedicata                               │     │
│  │ • Crittografia Quantistica (futuro)                   │     │
│  │ • Physical Access Control                             │     │
│  └───────────────────────────────────────────────────────┘     │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. SCHEMA BACKUP E DISASTER RECOVERY

```
                    ┌────────────────────────┐
                    │  PRODUZIONE            │
                    │  Data-Center Primario  │
                    │  10.1.0.0/24           │
                    └───────────┬────────────┘
                                │
                    ┌───────────┴────────────┐
                    │                        │
           ┌────────▼────────┐      ┌───────▼────────┐
           │  Database       │      │  File Storage  │
           │  PostgreSQL     │      │  SAN/NAS       │
           │  10.1.0.31      │      │  10.1.0.51     │
           └────────┬────────┘      └───────┬────────┘
                    │                       │
                    │ Replication           │ rsync
                    │ (Sincrona)            │ (Ogni 15min)
                    │                       │
           ┌────────▼────────┐      ┌───────▼────────┐
           │  Database       │      │  Backup NAS    │
           │  Slave          │      │  10.1.0.52     │
           │  10.1.0.32      │      │                │
           │  (Hot Standby)  │      │  Snapshot      │
           └────────┬────────┘      │  ogni 6h       │
                    │                └───────┬────────┘
                    │                        │
                    │ Async                  │
                    │ Replication            │ Daily
                    │                        │ Full Backup
                    │                        │
           ┌────────▼────────────────────────▼────────┐
           │       Data-Center Secondario             │
           │       (Disaster Recovery)                │
           │       Geograficamente Distante           │
           │       10.2.0.0/24                        │
           │                                          │
           │  • Database Replica (RPO: 15 min)       │
           │  • Storage Replica (RPO: 1 ora)         │
           │  • RTO Target: 4 ore                    │
           └──────────────────────────────────────────┘
                              │
                              │ Long-term
                              │ Archive
                              ▼
                    ┌─────────────────────┐
                    │  COLD STORAGE       │
                    │  Tape / Cloud Glacier│
                    │  Retention: 7 anni  │
                    └─────────────────────┘
```

---

## 9. MONITORAGGIO CENTRALIZZATO

```
┌──────────────────────────────────────────────────────────────────┐
│                   MONITORING DASHBOARD                           │
│                   10.1.0.202 (Zabbix)                            │
└──────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
   ┌────▼─────┐         ┌─────▼────┐         ┌─────▼─────┐
   │ SNMP     │         │ NetFlow  │         │ Syslog    │
   │ Polling  │         │ Analysis │         │ Collection│
   │          │         │          │         │           │
   │ Status:  │         │ Traffic: │         │ Events:   │
   │ • CPE    │         │ • Banda  │         │ • Errori  │
   │ • Switch │         │ • Top    │         │ • Alert   │
   │ • Server │         │   Talkers│         │ • Audit   │
   └────┬─────┘         └─────┬────┘         └─────┬─────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  Alert Manager     │
                    │                    │
                    │  Rules:            │
                    │  • VPN Down > 5min │
                    │  • CPU > 80%       │
                    │  • Disk > 90%      │
                    │  • Packet Loss>1%  │
                    └─────────┬──────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
              ┌─────▼─────┐        ┌─────▼─────┐
              │   Email   │        │    SMS    │
              │ Notification│      │ Alert     │
              └───────────┘        └───────────┘
```

---

## CONCLUSIONE

Questo diagramma illustra:

✅ **Topologia completa** dell'infrastruttura regionale  
✅ **Dettaglio data-center** con layer applicativi, database e storage  
✅ **Connessione strutture private** tramite CPE e fibra ottica  
✅ **Integrazione LAN esistenti** con separazione VLAN  
✅ **Flussi dati** per invio prestazioni a FSE  
✅ **Sicurezza multi-layer** da fisica ad applicativa  
✅ **Backup e DR** con replica geografica  
✅ **Monitoraggio centralizzato** con alerting  

La soluzione garantisce:
- **Isolamento** tra strutture (firewall + VLAN)
- **Alta disponibilità** (ridondanza core, DR)
- **Sicurezza** (VPN IPsec, TLS, firewall multi-layer)
- **Scalabilità** (2048 subnet disponibili)
- **Monitoraggio** (centralizzato 24/7)
