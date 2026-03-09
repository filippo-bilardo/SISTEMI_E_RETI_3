# Esercitazione Configurazione Topologia di rete con VLAN e Inter-VLAN Routing
![rete](img/image1.png)

## Obiettivo
L'obiettivo di questa esercitazione è configurare una rete con VLAN (Virtual Local Area Network) e consentire la comunicazione tra le reti VLAN utilizzando router Cisco. In particolare, si configureranno due VLAN (VLAN 10 e VLAN 20) e si abiliterà la comunicazione tra di esse tramite routing inter-VLAN. 

**Compito**: Suddividere la rete 192.168.10.0/24 in 5 sottoreti e configurare le VLAN per ciascuna sottorete come da immagine sopra.

## Architettura

### Dispositivi
- 2x Router Cisco 2901 (Router0 e Router1)
- 2x Switch Cisco 2960-24TT (Switch0 e Switch1)
- 4x PC Client (PC0, PC1, PC2, PC3)
- 1x Server (Server0)

### Topologia
- **Switch0** (lato sinistro): collega PC0 (VLAN10) e PC1 (VLAN20) → collegato a Router0
- **Switch1** (lato destro): collega PC2 (VLAN10), PC3 (VLAN20) e Server0 (VLAN10) → collegato a Router1
- **Backbone centrale**: Router0 e Router1 collegati tramite interfacce seriali

### VLAN Configurate
- **VLAN 10** (viola/rosa): PC0, PC2, Server0
- **VLAN 20** (ciano): PC1, PC3

--- 

## STEP 1: Suddivisione della rete in sottoreti

Per suddividere la rete **192.168.10.0/24** in **5 sottoreti**, utilizziamo il subnetting con maschera **/27** (255.255.255.224), che fornisce 32 indirizzi IP per sottorete (30 utilizzabili).

### Schema delle 5 Sottoreti

| Sottorete | Indirizzo Rete | Range Host Utilizzabili | Indirizzo Broadcast | Dispositivi | VLAN |
|-----------|----------------|-------------------------|---------------------|-------------|------|
| **subnet1** | 192.168.10.0/27 | 192.168.10.1 - 192.168.10.30 | **192.168.10.31** | PC0 | VLAN10 |
| **subnet2** | 192.168.10.32/27 | 192.168.10.33 - 192.168.10.62 | **192.168.10.63** | PC1 | VLAN20 |
| **subnet3** | 192.168.10.64/27 | 192.168.10.65 - 192.168.10.94 | **192.168.10.95** | PC2, Server0 | VLAN10 |
| **subnet4** | 192.168.10.96/27 | 192.168.10.97 - 192.168.10.126 | **192.168.10.127** | PC3 | VLAN20 |
| **subnet5** | 192.168.10.128/27 | 192.168.10.129 - 192.168.10.158 | **192.168.10.159** | Backbone Router0-Router1 | - |

### Piano di Indirizzamento Dettagliato

| Dispositivo | Interfaccia | Indirizzo IP | Subnet Mask | Gateway | VLAN | Sottorete |
|-------------|-------------|--------------|-------------|---------|------|-----------|
| **PC0** | FastEthernet0 | 192.168.10.10 | 255.255.255.224 | 192.168.10.1 | VLAN10 | subnet1 |
| **PC1** | FastEthernet0 | 192.168.10.42 | 255.255.255.224 | 192.168.10.33 | VLAN20 | subnet2 |
| **PC2** | FastEthernet0 | 192.168.10.74 | 255.255.255.224 | 192.168.10.65 | VLAN10 | subnet3 |
| **PC3** | FastEthernet0 | 192.168.10.106 | 255.255.255.224 | 192.168.10.97 | VLAN20 | subnet4 |
| **Server0** | FastEthernet0 | 192.168.10.75 | 255.255.255.224 | 192.168.10.65 | VLAN10 | subnet3 |
| **Router0** | Gi0/0.10 (VLAN10) | 192.168.10.1 | 255.255.255.224 | - | VLAN10 | subnet1 |
| **Router0** | Gi0/0.20 (VLAN20) | 192.168.10.33 | 255.255.255.224 | - | VLAN20 | subnet2 |
| **Router0** | Serial0/0/0 | 192.168.10.129 | 255.255.255.224 | - | - | subnet5 |
| **Router1** | Gi0/0.10 (VLAN10) | 192.168.10.65 | 255.255.255.224 | - | VLAN10 | subnet3 |
| **Router1** | Gi0/0.20 (VLAN20) | 192.168.10.97 | 255.255.255.224 | - | VLAN20 | subnet4 |
| **Router1** | Serial0/0/0 | 192.168.10.130 | 255.255.255.224 | - | - | subnet5 |

---

## Configurazione Dispositivi

### PC e Server - Configurazione IP

#### PC0 (subnet1 - VLAN10)
```
IP Address: 192.168.10.10
Subnet Mask: 255.255.255.224
Default Gateway: 192.168.10.1
```

#### PC1 (subnet2 - VLAN20)
```
IP Address: 192.168.10.42
Subnet Mask: 255.255.255.224
Default Gateway: 192.168.10.33
```

#### PC2 (subnet3 - VLAN10)
```
IP Address: 192.168.10.74
Subnet Mask: 255.255.255.224
Default Gateway: 192.168.10.65
```

#### PC3 (subnet4 - VLAN20)
```
IP Address: 192.168.10.106
Subnet Mask: 255.255.255.224
Default Gateway: 192.168.10.97
```

#### Server0 (subnet3 - VLAN10)
```
IP Address: 192.168.10.75
Subnet Mask: 255.255.255.224
Default Gateway: 192.168.10.65
```

### Router0 - Configurazione Completa

```cisco
enable
configure terminal
hostname Router0

! Configurazione interfaccia seriale verso Router1 (subnet5)
interface Serial0/0/0
ip address 192.168.10.129 255.255.255.224
clock rate 64000
no shutdown

! Configurazione subinterface per VLAN10 (subnet1)
interface GigabitEthernet0/0.10
encapsulation dot1Q 10
ip address 192.168.10.1 255.255.255.224

! Configurazione subinterface per VLAN20 (subnet2)
interface GigabitEthernet0/0.20
encapsulation dot1Q 20
ip address 192.168.10.33 255.255.255.224

! Attivazione interfaccia fisica
interface GigabitEthernet0/0
no shutdown

! Routing statico verso subnet3 e subnet4 (via Router1)
ip route 192.168.10.64 255.255.255.224 192.168.10.130
ip route 192.168.10.96 255.255.255.224 192.168.10.130

end
write memory
```

### Router1 - Configurazione Completa

```cisco
enable
configure terminal
hostname Router1

! Configurazione interfaccia seriale verso Router0 (subnet5)
interface Serial0/0/0
ip address 192.168.10.130 255.255.255.224
no shutdown

! Configurazione subinterface per VLAN10 (subnet3)
interface GigabitEthernet0/0.10
encapsulation dot1Q 10
ip address 192.168.10.65 255.255.255.224

! Configurazione subinterface per VLAN20 (subnet4)
interface GigabitEthernet0/0.20
encapsulation dot1Q 20
ip address 192.168.10.97 255.255.255.224

! Attivazione interfaccia fisica
interface GigabitEthernet0/0
no shutdown

! Routing statico verso subnet1 e subnet2 (via Router0)
ip route 192.168.10.0 255.255.255.224 192.168.10.129
ip route 192.168.10.32 255.255.255.224 192.168.10.129

end
write memory
```

### Switch0 - Configurazione Completa

```cisco
enable
configure terminal
hostname Switch0

! Creazione VLAN
vlan 10
name VLAN10_subnet1
exit
vlan 20
name VLAN20_subnet2
exit

! Configurazione porta trunk verso Router0
interface GigabitEthernet0/1
switchport mode trunk
switchport trunk allowed vlan 10,20
no shutdown

! Configurazione porta per PC0 (VLAN10)
interface FastEthernet0/1
switchport mode access
switchport access vlan 10
no shutdown

! Configurazione porta per PC1 (VLAN20)
interface FastEthernet0/2
switchport mode access
switchport access vlan 20
no shutdown

end
write memory
```

### Switch1 - Configurazione Completa

```cisco
enable
configure terminal
hostname Switch1

! Creazione VLAN
vlan 10
name VLAN10_subnet3
exit
vlan 20
name VLAN20_subnet4
exit

! Configurazione porta trunk verso Router1
interface GigabitEthernet0/1
switchport mode trunk
switchport trunk allowed vlan 10,20
no shutdown

! Configurazione porta per PC2 (VLAN10)
interface FastEthernet0/1
switchport mode access
switchport access vlan 10
no shutdown

! Configurazione porta per Server0 (VLAN10)
interface FastEthernet0/2
switchport mode access
switchport access vlan 10
no shutdown

! Configurazione porta per PC3 (VLAN20)
interface FastEthernet0/3
switchport mode access
switchport access vlan 20
no shutdown

end
write memory
```

---

## Verifica e Test della Configurazione

Dopo aver completato tutte le configurazioni, eseguire i seguenti test:

### 1. Test Connettività Locale
- **PC0** → ping 192.168.10.1 (gateway VLAN10 su Router0) ✓
- **PC1** → ping 192.168.10.33 (gateway VLAN20 su Router0) ✓
- **PC2** → ping 192.168.10.65 (gateway VLAN10 su Router1) ✓
- **PC3** → ping 192.168.10.97 (gateway VLAN20 su Router1) ✓

### 2. Test Inter-VLAN (stesso switch)
- **PC0** (VLAN10) → ping **PC1** (VLAN20): 192.168.10.42 ✓

### 3. Test Inter-VLAN (switch diversi)
- **PC0** (VLAN10) → ping **PC2** (VLAN10): 192.168.10.74 ✓
- **PC0** (VLAN10) → ping **PC3** (VLAN20): 192.168.10.106 ✓
- **PC1** (VLAN20) → ping **PC3** (VLAN20): 192.168.10.106 ✓

### 4. Test Connettività Server
- **PC0** → ping **Server0**: 192.168.10.75 ✓
- **PC1** → ping **Server0**: 192.168.10.75 ✓

### 5. Verifica Routing
- Da **PC0** eseguire `tracert 192.168.10.106` (verso PC3)
  - Dovrebbe passare per: 192.168.10.1 → 192.168.10.130 → 192.168.10.106

### Comandi di Verifica sui Router

```cisco
! Verifica interfacce
show ip interface brief

! Verifica routing table
show ip route

! Verifica VLAN (sui router con subinterface)
show ip interface

! Verifica connettività backbone
ping 192.168.10.130  (da Router0 a Router1)
```

### Comandi di Verifica sugli Switch

```cisco
! Verifica VLAN create
show vlan brief

! Verifica porte trunk
show interfaces trunk

! Verifica assegnazione porte
show vlan id 10
show vlan id 20
```

---

## Note Tecniche

- **Encapsulation dot1Q**: Utilizzata per il tagging delle VLAN sui trunk (802.1Q)
- **Clock rate**: Impostato su Router0 (DCE side) per sincronizzare la connessione seriale
- **Routing statico**: Configurato manualmente per permettere comunicazione tra le sottoreti
- **Subnet mask /27**: Fornisce 32 indirizzi (30 host utilizzabili) per sottorete
