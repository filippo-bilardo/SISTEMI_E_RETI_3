# PIANO DI INDIRIZZAMENTO DETTAGLIATO

## Riferimento alla Prova

**Testo**: "...un piano di indirizzamento che permetta di connettere un numero di strutture sanitarie private convenzionate che si stima essere **intorno alle 2000 in regione**, assegnando a ciascuna di esse la disponibilità di un **minimo di 8 indirizzi complessivi**."

**Sottorete assegnata**: `10.100.0.0/16`

---

## Analisi dei Requisiti

### Requisiti Quantitativi
- **Numero strutture**: ~2000 (con margine per crescita futura)
- **Indirizzi per struttura**: Minimo 8 (30 raccomandati)
- **Isolamento**: Ogni struttura deve essere isolata dalle altre

### Requisiti Tecnici
- Subnetting della rete 10.100.0.0/16
- Routing statico o dinamico verso data-center
- Gateway per ogni subnet
- Indirizzi riservati per gestione

---

## Soluzione Proposta: Subnetting /27

### Calcoli Base

**Subnet Mask**: `/27`
- **Bit di rete**: 27
- **Bit di host**: 5 (32 - 27)
- **Indirizzi totali per subnet**: 2^5 = 32
- **Indirizzi utilizzabili**: 32 - 2 = 30 (esclusi network e broadcast)

**Numero di Subnet disponibili in 10.100.0.0/16**:
```
Bit disponibili per subnetting = 27 - 16 = 11 bit
Numero subnet = 2^11 = 2048 subnet
```

✅ **2048 subnet > 2000 strutture richieste** ✅

### Vantaggi della Soluzione /27

1. **Scalabilità**: Permette fino a 2048 strutture (margine di 48 per crescita)
2. **Abbondanza IP**: 30 indirizzi utilizzabili per struttura (vs. 8 richiesti)
3. **Semplicità**: Incremento fisso di 32 per ogni subnet successiva
4. **Isolamento**: Facile implementazione di firewall rules tra subnet

---

## Schema di Allocazione

### Formula per Calcolo Subnet

Per la struttura N (dove N va da 0 a 2047):

```
Network Address = 10.100.0.0 + (N × 32)

Esempio:
Struttura #0:   10.100.0.0/27    → Range: 10.100.0.0 - 10.100.0.31
Struttura #1:   10.100.0.32/27   → Range: 10.100.0.32 - 10.100.0.63
Struttura #2:   10.100.0.64/27   → Range: 10.100.0.64 - 10.100.0.95
...
Struttura #2047: 10.100.255.224/27 → Range: 10.100.255.224 - 10.100.255.255
```

### Tabella Allocazione (Prime 20 Strutture)

| ID | Nome Struttura | Network | Range IP | Gateway | Broadcast | Indirizzi Utilizzabili |
|----|----------------|---------|----------|---------|-----------|----------------------|
| 0 | Struttura #0 (Riservato Gestione) | 10.100.0.0/27 | 10.100.0.0 - 10.100.0.31 | 10.100.0.1 | 10.100.0.31 | 10.100.0.2 - 10.100.0.30 |
| 1 | Clinica Privata "San Marco" | 10.100.0.32/27 | 10.100.0.32 - 10.100.0.63 | 10.100.0.33 | 10.100.0.63 | 10.100.0.34 - 10.100.0.62 |
| 2 | Centro Diagnostico "Salute+" | 10.100.0.64/27 | 10.100.0.64 - 10.100.0.95 | 10.100.0.65 | 10.100.0.95 | 10.100.0.66 - 10.100.0.94 |
| 3 | Poliambulatorio "Vita" | 10.100.0.96/27 | 10.100.0.96 - 10.100.0.127 | 10.100.0.97 | 10.100.0.127 | 10.100.0.98 - 10.100.0.126 |
| 4 | Casa di Cura "Montefiore" | 10.100.0.128/27 | 10.100.0.128 - 10.100.0.159 | 10.100.0.129 | 10.100.0.159 | 10.100.0.130 - 10.100.0.158 |
| 5 | Centro Riabilitazione "Aurora" | 10.100.0.160/27 | 10.100.0.160 - 10.100.0.191 | 10.100.0.161 | 10.100.0.191 | 10.100.0.162 - 10.100.0.190 |
| 6 | Laboratorio Analisi "BioLab" | 10.100.0.192/27 | 10.100.0.192 - 10.100.0.223 | 10.100.0.193 | 10.100.0.223 | 10.100.0.194 - 10.100.0.222 |
| 7 | Clinica Odontoiatrica "SmileCenter" | 10.100.0.224/27 | 10.100.0.224 - 10.100.0.255 | 10.100.0.225 | 10.100.0.255 | 10.100.0.226 - 10.100.0.254 |
| 8 | Centro Oculistico "Vista Chiara" | 10.100.1.0/27 | 10.100.1.0 - 10.100.1.31 | 10.100.1.1 | 10.100.1.31 | 10.100.1.2 - 10.100.1.30 |
| 9 | Poliambulatorio "San Giuseppe" | 10.100.1.32/27 | 10.100.1.32 - 10.100.1.63 | 10.100.1.33 | 10.100.1.63 | 10.100.1.34 - 10.100.1.62 |
| 10 | Clinica Pediatrica "Arcobaleno" | 10.100.1.64/27 | 10.100.1.64 - 10.100.1.95 | 10.100.1.65 | 10.100.1.95 | 10.100.1.66 - 10.100.1.94 |
| 11 | Centro Cardiologico "Cuore Sano" | 10.100.1.96/27 | 10.100.1.96 - 10.100.1.127 | 10.100.1.97 | 10.100.1.127 | 10.100.1.98 - 10.100.1.126 |
| 12 | Laboratorio Radiologico "ImagineMedica" | 10.100.1.128/27 | 10.100.1.128 - 10.100.1.159 | 10.100.1.129 | 10.100.1.159 | 10.100.1.130 - 10.100.1.158 |
| 13 | Casa di Cura "Villa Verde" | 10.100.1.160/27 | 10.100.1.160 - 10.100.1.191 | 10.100.1.161 | 10.100.1.191 | 10.100.1.162 - 10.100.1.190 |
| 14 | Centro Fisioterapia "Movimento" | 10.100.1.192/27 | 10.100.1.192 - 10.100.1.223 | 10.100.1.193 | 10.100.1.223 | 10.100.1.194 - 10.100.1.222 |
| 15 | Clinica Dermatologica "Pelle Sana" | 10.100.1.224/27 | 10.100.1.224 - 10.100.1.255 | 10.100.1.225 | 10.100.1.255 | 10.100.1.226 - 10.100.1.254 |
| 16 | Poliambulatorio "Salus" | 10.100.2.0/27 | 10.100.2.0 - 10.100.2.31 | 10.100.2.1 | 10.100.2.31 | 10.100.2.2 - 10.100.2.30 |
| 17 | Centro Ortopedico "OrthoClinic" | 10.100.2.32/27 | 10.100.2.32 - 10.100.2.63 | 10.100.2.33 | 10.100.2.63 | 10.100.2.34 - 10.100.2.62 |
| 18 | Clinica Neurologica "NeuroCare" | 10.100.2.64/27 | 10.100.2.64 - 10.100.2.95 | 10.100.2.65 | 10.100.2.95 | 10.100.2.66 - 10.100.2.94 |
| 19 | Centro Diabetologico "Diabetes Center" | 10.100.2.96/27 | 10.100.2.96 - 10.100.2.127 | 10.100.2.97 | 10.100.2.127 | 10.100.2.98 - 10.100.2.126 |
| 20 | Casa di Cura "Felicità" | 10.100.2.128/27 | 10.100.2.128 - 10.100.2.159 | 10.100.2.129 | 10.100.2.159 | 10.100.2.130 - 10.100.2.158 |

---

## Allocazione Indirizzi per Struttura Tipo

### Esempio: Clinica Privata "San Marco" (10.100.0.32/27)

| Dispositivo/Funzione | Indirizzo IP | Note |
|---------------------|--------------|------|
| **Network Address** | 10.100.0.32 | Non utilizzabile |
| **Gateway/CPE Router (WAN)** | 10.100.0.33 | Porta WAN del CPE verso rete regionale |
| **CPE Router (LAN)** | 192.168.1.1 | Porta LAN verso rete interna (NAT) |
| **Server FSE Locale** | 10.100.0.34 | Server locale per cache/buffer dati |
| **Workstation Medico #1** | 10.100.0.35 | PC primario medico |
| **Workstation Medico #2** | 10.100.0.36 | PC secondario medico |
| **Workstation Amministrativa** | 10.100.0.37 | PC amministrazione |
| **Dispositivo Diagnostico #1** | 10.100.0.38 | Es: Ecografo connesso in rete |
| **Dispositivo Diagnostico #2** | 10.100.0.39 | Es: ECG digitale |
| **Access Point WiFi** | 10.100.0.40 | WiFi per dispositivi mobili medici |
| **Stampante di Rete** | 10.100.0.41 | Stampa referti |
| **Server Backup** | 10.100.0.42 | Backup locale |
| **Riservato Management** | 10.100.0.43 | Gestione remota società regionale |
| **DHCP Pool Start** | 10.100.0.44 | Pool DHCP per dispositivi temporanei |
| ... | ... | ... |
| **DHCP Pool End** | 10.100.0.62 | Fine pool DHCP |
| **Broadcast Address** | 10.100.0.63 | Non utilizzabile |

**Nota**: In realtà, per semplicità, la maggior parte dei dispositivi della LAN interna userà indirizzi privati (es: 192.168.1.x) con NAT sul CPE. Gli indirizzi 10.100.0.x sono per dispositivi che devono essere raggiungibili direttamente dalla rete regionale (es: server FSE locale).

---

## Riepilogo Allocazione Rete Regionale Completa

### Mappa Indirizzi 10.0.0.0/8

```
10.0.0.0/8 - Rete Regionale Completa
│
├── 10.1.0.0/24       → Data-Center (256 indirizzi)
│   ├── 10.1.0.1      → Core Router Data-Center
│   ├── 10.1.0.10-20  → Server FSE (cluster)
│   ├── 10.1.0.30-40  → Database servers
│   ├── 10.1.0.50-60  → Storage servers
│   ├── 10.1.0.100    → Firewall principale
│   └── 10.1.0.200    → Management server
│
├── 10.10.0.0/16      → Enti Locali (65.536 indirizzi)
│   └── Subnetting variabile per ogni ente
│
├── 10.20.0.0/16      → Scuole (65.536 indirizzi)
│   └── Subnetting variabile per ogni scuola
│
├── 10.30.0.0/16      → Strutture Sanitarie Pubbliche (65.536 indirizzi)
│   └── Subnetting variabile per ogni struttura
│
└── 10.100.0.0/16     → Strutture Sanitarie Private (65.536 indirizzi)
    ├── 10.100.0.0/27     → Struttura #0 (Gestione)
    ├── 10.100.0.32/27    → Struttura #1
    ├── 10.100.0.64/27    → Struttura #2
    ├── ...
    └── 10.100.255.224/27 → Struttura #2047
```

---

## Routing e Isolamento

### Routing Statico per Data-Center

Su **Core Router Regionale**:
```
# Route per strutture private verso Edge Router
ip route 10.100.0.0/16 via 10.1.0.2

# Route specifiche per isolamento (opzionale con firewall)
ip route 10.100.0.32/27 via 10.1.0.2   # Struttura #1
ip route 10.100.0.64/27 via 10.1.0.2   # Struttura #2
...
```

Su **Edge Router Strutture Private**:
```
# Default route verso data-center
ip route 0.0.0.0/0 via 10.1.0.1

# Route esplicite per evitare routing tra strutture
# (implementato tramite ACL/firewall invece di routing)
```

### Firewall Rules per Isolamento

Su **Edge Router** (tra strutture):
```
# Policy: DENY comunicazione inter-struttura
# Permetti solo comunicazione verso data-center 10.1.0.0/24

access-list 100 permit ip 10.100.0.32 0.0.0.31 10.1.0.0 0.0.0.255
access-list 100 deny ip 10.100.0.32 0.0.0.31 10.100.0.0 0.0.255.255
access-list 100 permit ip any any

# Applicato su interfaccia verso strutture
interface GigabitEthernet0/1
 ip access-group 100 in
```

Su **CPE Router** di ogni struttura:
```
# Permetti solo traffico verso data-center
iptables -A OUTPUT -d 10.1.0.0/24 -j ACCEPT
iptables -A OUTPUT -d 10.100.0.0/16 -j DROP    # Blocca altre strutture
iptables -A OUTPUT -j DROP                      # Blocca Internet
```

---

## VLSM (Variable Length Subnet Mask) - Alternativa

Se alcune strutture necessitano di più o meno indirizzi, si può adottare VLSM:

### Esempio VLSM

```
Strutture grandi (es: >100 dispositivi):    /26 (62 host)
Strutture medie (es: 20-50 dispositivi):    /27 (30 host) - Default
Strutture piccole (es: 5-10 dispositivi):   /28 (14 host)
Strutture micro (es: 2-3 dispositivi):      /29 (6 host)
```

**Allocazione VLSM Esempio**:
```
10.100.0.0/26     → Struttura Grande #1 (62 host)
10.100.0.64/26    → Struttura Grande #2 (62 host)
10.100.0.128/27   → Struttura Media #1 (30 host)
10.100.0.160/27   → Struttura Media #2 (30 host)
10.100.0.192/28   → Struttura Piccola #1 (14 host)
10.100.0.208/28   → Struttura Piccola #2 (14 host)
10.100.0.224/29   → Struttura Micro #1 (6 host)
10.100.0.232/29   → Struttura Micro #2 (6 host)
...
```

**Nota**: VLSM complica la gestione. Si raccomanda uniformità con /27 per semplicità operativa.

---

## Script Calcolo Subnet

```python
#!/usr/bin/env python3
"""
Script per calcolo subnet /27 da 10.100.0.0/16
"""
import ipaddress

def calcola_subnet(struttura_id):
    """
    Calcola la subnet /27 per una data struttura
    """
    base_network = ipaddress.IPv4Network('10.100.0.0/16')
    subnet_size = 32  # /27 = 32 indirizzi
    
    # Calcola offset
    offset = struttura_id * subnet_size
    
    # Calcola indirizzo di rete
    network_int = int(base_network.network_address) + offset
    network_addr = ipaddress.IPv4Address(network_int)
    
    # Crea subnet
    subnet = ipaddress.IPv4Network(f'{network_addr}/27', strict=False)
    
    return {
        'id': struttura_id,
        'network': str(subnet.network_address),
        'netmask': str(subnet.netmask),
        'cidr': str(subnet),
        'gateway': str(subnet.network_address + 1),
        'first_usable': str(subnet.network_address + 2),
        'last_usable': str(subnet.broadcast_address - 1),
        'broadcast': str(subnet.broadcast_address),
        'total_hosts': subnet.num_addresses,
        'usable_hosts': subnet.num_addresses - 2
    }

def main():
    print("PIANO DI INDIRIZZAMENTO - Strutture Sanitarie Private")
    print("=" * 80)
    print(f"{'ID':<6} {'Network':<18} {'Gateway':<16} {'Usable Range':<30}")
    print("-" * 80)
    
    # Stampa prime 20 strutture
    for i in range(20):
        info = calcola_subnet(i)
        usable_range = f"{info['first_usable']} - {info['last_usable']}"
        print(f"{info['id']:<6} {info['cidr']:<18} {info['gateway']:<16} {usable_range:<30}")
    
    print("-" * 80)
    print(f"\nTotale subnet disponibili con /27: 2048")
    print(f"Indirizzi per subnet: 30 (utilizzabili)")
    
    # Verifica ultima subnet
    last_subnet = calcola_subnet(2047)
    print(f"\nUltima subnet disponibile:")
    print(f"  ID: {last_subnet['id']}")
    print(f"  Network: {last_subnet['cidr']}")
    print(f"  Gateway: {last_subnet['gateway']}")
    print(f"  Range: {last_subnet['first_usable']} - {last_subnet['last_usable']}")

if __name__ == '__main__':
    main()
```

**Output**:
```
PIANO DI INDIRIZZAMENTO - Strutture Sanitarie Private
================================================================================
ID     Network            Gateway          Usable Range                  
--------------------------------------------------------------------------------
0      10.100.0.0/27      10.100.0.1       10.100.0.2 - 10.100.0.30      
1      10.100.0.32/27     10.100.0.33      10.100.0.34 - 10.100.0.62     
2      10.100.0.64/27     10.100.0.65      10.100.0.66 - 10.100.0.94     
3      10.100.0.96/27     10.100.0.97      10.100.0.98 - 10.100.0.126    
...
--------------------------------------------------------------------------------

Totale subnet disponibili con /27: 2048
Indirizzi per subnet: 30 (utilizzabili)

Ultima subnet disponibile:
  ID: 2047
  Network: 10.100.255.224/27
  Gateway: 10.100.255.225
  Range: 10.100.255.226 - 10.100.255.254
```

---

## DNS e Naming Convention

### DNS Naming

```
Struttura #N: struttura-N.priv.fse.regione.it

Esempi:
struttura-1.priv.fse.regione.it   → 10.100.0.33
struttura-2.priv.fse.regione.it   → 10.100.0.65
struttura-3.priv.fse.regione.it   → 10.100.0.97

CPE dispositivi:
cpe-1.priv.fse.regione.it         → 10.100.0.33
cpe-2.priv.fse.regione.it         → 10.100.0.65
```

### Zone DNS

```
; Zone file per 100.10.in-addr.arpa (Reverse DNS)
$TTL 86400
@   IN  SOA dns1.regione.it. admin.regione.it. (
        2024013001  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400 )     ; Minimum TTL

; Name servers
    IN  NS  dns1.regione.it.
    IN  NS  dns2.regione.it.

; PTR Records
33.0    IN  PTR cpe-1.priv.fse.regione.it.
65.0    IN  PTR cpe-2.priv.fse.regione.it.
97.0    IN  PTR cpe-3.priv.fse.regione.it.
...
```

---

## Documentazione Allocazioni

**Database Gestione Allocazioni**:

```sql
CREATE TABLE strutture_allocazioni (
    id INT PRIMARY KEY,
    nome_struttura VARCHAR(255),
    network_address VARCHAR(18),
    gateway VARCHAR(15),
    netmask VARCHAR(15),
    broadcast VARCHAR(15),
    vlan_id INT,
    cpe_serial VARCHAR(50),
    data_attivazione DATE,
    contatto_referente VARCHAR(255),
    telefono VARCHAR(20),
    email VARCHAR(255),
    stato ENUM('attiva', 'sospesa', 'disattivata'),
    note TEXT
);

-- Esempio record
INSERT INTO strutture_allocazioni VALUES (
    1,
    'Clinica Privata San Marco',
    '10.100.0.32/27',
    '10.100.0.33',
    '255.255.255.224',
    '10.100.0.63',
    101,
    'CPE-SM-001-2024',
    '2024-03-15',
    'Dr. Mario Rossi',
    '+39 0123 456789',
    'admin@clinicasanmarco.it',
    'attiva',
    'Connessione attivata, test completati con successo'
);
```

---

## Verifica e Testing

### Checklist Verifica Subnet

- [ ] Network address corretto (multiplo di 32)
- [ ] Subnet mask = 255.255.255.224 (/27)
- [ ] Gateway = Network + 1
- [ ] 30 indirizzi utilizzabili verificati
- [ ] Broadcast address = Network + 31
- [ ] Nessuna sovrapposizione con altre subnet
- [ ] Routing configurato correttamente
- [ ] Firewall rules per isolamento attive
- [ ] DNS forward e reverse configurati
- [ ] Test di connettività verso data-center OK

### Comandi Test

```bash
# Test ping al gateway
ping -c 4 10.100.0.33

# Test ping al data-center
ping -c 4 10.1.0.1

# Verifica routing
ip route get 10.1.0.10

# Verifica non raggiungibilità altre strutture (deve fallire)
ping -c 2 10.100.0.65  # Struttura #2 - dovrebbe timeout

# Traceroute verso data-center
traceroute 10.1.0.10
```

---

## Conclusioni

Il piano di indirizzamento proposto con **subnet /27**:

✅ Soddisfa tutti i requisiti (2000+ strutture, 8+ indirizzi ciascuna)  
✅ Fornisce abbondante spazio (30 IP utilizzabili per struttura)  
✅ Semplifica gestione (incremento fisso di 32)  
✅ Permette scalabilità futura (48 subnet di margine)  
✅ Facilita isolamento tra strutture  
✅ Compatible con routing statico e dinamico  

**Raccomandazione finale**: Adottare schema /27 uniforme per tutte le strutture, con eventuale VLSM solo per casi eccezionali che richiedano più di 30 host.
