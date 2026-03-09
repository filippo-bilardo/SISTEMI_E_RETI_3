# Guida Creazione Topologia VLAN2 in Packet Tracer
![alt text](img/image1.png)

## Dispositivi Necessari

### Router (2x)
- Tipo: **Cisco 2901**
- Quantità: 2
- Nomi: Router0, Router1

### Switch (2x)
- Tipo: **Cisco 2960-24TT**
- Quantità: 2
- Nomi: Switch0, Switch1

### PC (4x)
- Tipo: **PC-PT**
- Quantità: 4
- Nomi: PC0, PC1, PC2, PC3

### Server (1x)
- Tipo: **Server-PT**
- Quantità: 1
- Nome: Server0

---

## STEP 1: Posizionamento Dispositivi

### Istruzioni:

1. Apri **Cisco Packet Tracer**
2. Dal pannello dispositivi in basso:
   - Seleziona **Routers** → **2900 Series** → trascina **2901** (x2)
   - Seleziona **Switches** → **2960** → trascina **2960-24TT** (x2)
   - Seleziona **End Devices** → trascina **PC** (x4)
   - Seleziona **End Devices** → trascina **Server** (x1)

3. **Layout suggerito:**
```
                Router0 ------(Serial)------ Router1
                   |                            |
              (Gi0/0)                        (Gi0/0)
                   |                            |
              [Switch0]                    [Switch1]
                /    \                      /   |   \
               /      \                    /    |    \
             PC0      PC1               PC2  Server0  PC3
          (VLAN10) (VLAN20)          (VLAN10)(VLAN10)(VLAN20)
```

4. **Rinomina dispositivi** (click → Display Name):
   - Router0, Router1
   - Switch0, Switch1
   - PC0, PC1, PC2, PC3
   - Server0

---
Allegare screenshot del layout finale dopo posizionamento dispositivi.

## STEP 2: Collegamento Cavi

### Collegamento Switch0

| Da Dispositivo | Porta | Tipo Cavo | A Dispositivo | Porta |
|----------------|-------|-----------|---------------|-------|
| PC0 | FastEthernet0 | Copper Straight-Through | Switch0 | FastEthernet0/1 |
| PC1 | FastEthernet0 | Copper Straight-Through | Switch0 | FastEthernet0/2 |
| Switch0 | GigabitEthernet0/1 | Copper Straight-Through | Router0 | GigabitEthernet0/0 |

### Collegamento Switch1

| Da Dispositivo | Porta | Tipo Cavo | A Dispositivo | Porta |
|----------------|-------|-----------|---------------|-------|
| PC2 | FastEthernet0 | Copper Straight-Through | Switch1 | FastEthernet0/1 |
| Server0 | FastEthernet0 | Copper Straight-Through | Switch1 | FastEthernet0/2 |
| PC3 | FastEthernet0 | Copper Straight-Through | Switch1 | FastEthernet0/3 |
| Switch1 | GigabitEthernet0/1 | Copper Straight-Through | Router1 | GigabitEthernet0/0 |

### Collegamento Backbone Router0-Router1

| Da Dispositivo | Porta | Tipo Cavo | A Dispositivo | Porta |
|----------------|-------|-----------|---------------|-------|
| Router0 | Serial0/0/0 | **Serial DCE** | Router1 | Serial0/0/0 |

**IMPORTANTE**: Usare cavo **Serial DCE** da Router0 a Router1!

---
Allegare screenshot del layout finale dopo collegamento cavi.

## STEP 3: Configurazione PC e Server

### PC0 (VLAN 10 - subnet1)

1. Click su **PC0** → tab **Desktop** → **IP Configuration**
2. Seleziona **Static**
3. Inserisci:
   - **IP Address**: `192.168.10.10`
   - **Subnet Mask**: `255.255.255.224`
   - **Default Gateway**: `192.168.10.1`

### PC1 (VLAN 20 - subnet2)

1. Click su **PC1** → tab **Desktop** → **IP Configuration**
2. Seleziona **Static**
3. Inserisci:
   - **IP Address**: `192.168.10.42`
   - **Subnet Mask**: `255.255.255.224`
   - **Default Gateway**: `192.168.10.33`

### PC2 (VLAN 10 - subnet3)

1. Click su **PC2** → tab **Desktop** → **IP Configuration**
2. Seleziona **Static**
3. Inserisci:
   - **IP Address**: `192.168.10.74`
   - **Subnet Mask**: `255.255.255.224`
   - **Default Gateway**: `192.168.10.65`

### PC3 (VLAN 20 - subnet4)

1. Click su **PC3** → tab **Desktop** → **IP Configuration**
2. Seleziona **Static**
3. Inserisci:
   - **IP Address**: `192.168.10.106`
   - **Subnet Mask**: `255.255.255.224`
   - **Default Gateway**: `192.168.10.97`

### Server0 (VLAN 10 - subnet3)

1. Click su **Server0** → tab **Desktop** → **IP Configuration**
2. Seleziona **Static**
3. Inserisci:
   - **IP Address**: `192.168.10.75`
   - **Subnet Mask**: `255.255.255.224`
   - **Default Gateway**: `192.168.10.65`

---

## STEP 4: Configurazione Router0

1. Click su **Router0** → tab **CLI**
2. Premi **Enter** (salta auto-install)
3. Copia e incolla la seguente configurazione:

```cisco
enable
configure terminal
hostname Router0

! Configurazione interfaccia seriale verso Router1 (subnet5)
interface Serial0/0/0
ip address 192.168.10.129 255.255.255.224
clock rate 64000
no shutdown
exit

! Configurazione subinterface per VLAN10 (subnet1)
interface GigabitEthernet0/0.10
encapsulation dot1Q 10
ip address 192.168.10.1 255.255.255.224
description Gateway VLAN10 - subnet1
exit

! Configurazione subinterface per VLAN20 (subnet2)
interface GigabitEthernet0/0.20
encapsulation dot1Q 20
ip address 192.168.10.33 255.255.255.224
description Gateway VLAN20 - subnet2
exit

! Attivazione interfaccia fisica
interface GigabitEthernet0/0
no shutdown
exit

! Routing statico verso subnet3 e subnet4 (via Router1)
ip route 192.168.10.64 255.255.255.224 192.168.10.130
ip route 192.168.10.96 255.255.255.224 192.168.10.130

end
write memory
```

4. Attendi "OK" per la conferma

---

## STEP 5: Configurazione Router1

1. Click su **Router1** → tab **CLI**
2. Premi **Enter** (salta auto-install)
3. Copia e incolla la seguente configurazione:

```cisco
enable
configure terminal
hostname Router1

! Configurazione interfaccia seriale verso Router0 (subnet5)
interface Serial0/0/0
ip address 192.168.10.130 255.255.255.224
no shutdown
exit

! Configurazione subinterface per VLAN10 (subnet3)
interface GigabitEthernet0/0.10
encapsulation dot1Q 10
ip address 192.168.10.65 255.255.255.224
description Gateway VLAN10 - subnet3
exit

! Configurazione subinterface per VLAN20 (subnet4)
interface GigabitEthernet0/0.20
encapsulation dot1Q 20
ip address 192.168.10.97 255.255.255.224
description Gateway VLAN20 - subnet4
exit

! Attivazione interfaccia fisica
interface GigabitEthernet0/0
no shutdown
exit

! Routing statico verso subnet1 e subnet2 (via Router0)
ip route 192.168.10.0 255.255.255.224 192.168.10.129
ip route 192.168.10.32 255.255.255.224 192.168.10.129

end
write memory
```

4. Attendi "OK" per la conferma

---

## STEP 6: Configurazione Switch0

1. Click su **Switch0** → tab **CLI**
2. Premi **Enter**
3. Copia e incolla la seguente configurazione:

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
exit

! Configurazione porta per PC0 (VLAN10)
interface FastEthernet0/1
switchport mode access
switchport access vlan 10
description PC0 - VLAN10
no shutdown
exit

! Configurazione porta per PC1 (VLAN20)
interface FastEthernet0/2
switchport mode access
switchport access vlan 20
description PC1 - VLAN20
no shutdown
exit

end
write memory
```

4. Attendi "OK" per la conferma

---

## STEP 7: Configurazione Switch1

1. Click su **Switch1** → tab **CLI**
2. Premi **Enter**
3. Copia e incolla la seguente configurazione:

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
exit

! Configurazione porta per PC2 (VLAN10)
interface FastEthernet0/1
switchport mode access
switchport access vlan 10
description PC2 - VLAN10
no shutdown
exit

! Configurazione porta per Server0 (VLAN10)
interface FastEthernet0/2
switchport mode access
switchport access vlan 10
description Server0 - VLAN10
no shutdown
exit

! Configurazione porta per PC3 (VLAN20)
interface FastEthernet0/3
switchport mode access
switchport access vlan 20
description PC3 - VLAN20
no shutdown
exit

end
write memory
```

4. Attendi "OK" per la conferma

---

## STEP 8: Verifica Configurazione

### Test 1: Verifica Interfacce

**Router0:**
```cisco
show ip interface brief
```

Output atteso:
```
Interface              IP-Address      Status    Protocol
GigabitEthernet0/0     unassigned      up        up
GigabitEthernet0/0.10  192.168.10.1    up        up
GigabitEthernet0/0.20  192.168.10.33   up        up
Serial0/0/0            192.168.10.129  up        up
```

**Switch0:**
```cisco
show vlan brief
```

Output atteso:
```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------
1    default                          active    Fa0/3-24, Gi0/2
10   VLAN10_subnet1                   active    Fa0/1
20   VLAN20_subnet2                   active    Fa0/2
```

### Test 2: Ping Locale (Gateway)

Da **PC0** → Desktop → Command Prompt:
```
ping 192.168.10.1
```
**Risultato atteso**: Success (Reply from...)

### Test 3: Ping Inter-VLAN stesso Switch

Da **PC0**:
```
ping 192.168.10.42
```
(PC0 VLAN10 → PC1 VLAN20)
**Risultato atteso**: Success

### Test 4: Ping Inter-VLAN tra Switch

Da **PC0**:
```
ping 192.168.10.74
```
(PC0 → PC2, entrambi VLAN10 ma su switch diversi)
**Risultato atteso**: Success

### Test 5: Ping verso Server

Da **PC0**:
```
ping 192.168.10.75
```
**Risultato atteso**: Success

### Test 6: Traceroute

Da **PC0**:
```
tracert 192.168.10.106
```
(PC0 → PC3, attraverso entrambi i router)

**Risultato atteso**:
```
1   192.168.10.1    (Router0 - Gateway VLAN10)
2   192.168.10.130  (Router1 - Serial)
3   192.168.10.106  (PC3 - Destinazione)
```

---

Allegare screenshot dei comandi di verifica.

## STEP 9: Salvataggio File

Salva il file Packet Tracer con nome `VLAN2.pkt` e allegalo alla consegna.
---

## Troubleshooting Rapido

### Problema: Link rosso

- Verifica tipo cavo corretto
- Verifica che le interfacce siano `no shutdown`
- Sui router, verifica che interfaccia fisica Gi0/0 sia attiva

### Problema: Ping fallisce

**Ping al gateway fallisce:**
- Verifica IP e subnet mask del PC
- Verifica porta switch sia nella VLAN corretta
- Verifica subinterface router configurata

**Ping inter-VLAN fallisce:**
- Verifica routing statico sui router
- Verifica trunk tra switch e router
- Controllare `show ip route` sui router

### Problema: Serial link down

- Verifica `clock rate` su Router0 (DCE side)
- Verifica cavo sia tipo **Serial DCE**
- Verifica entrambe le interfacce serial siano `no shutdown`

---

## Comandi Utili per Debug

### Router
```cisco
show ip interface brief          ! Stato interfacce
show ip route                     ! Tabella routing
show running-config               ! Configurazione corrente
show interfaces GigabitEthernet0/0.10  ! Dettagli subinterface
```

### Switch
```cisco
show vlan brief                   ! VLAN e porte
show interfaces trunk             ! Stato trunk
show running-config               ! Configurazione corrente
show interfaces status            ! Stato tutte le porte
```

### PC/Server
```
ipconfig                          ! Configurazione IP (Windows mode)
ping <IP>                         ! Test connettività
tracert <IP>                      ! Tracciamento percorso
```

---

## Note Finali

✅ **Clock rate** su Router0 Serial0/0/0: necessario perché è il lato DCE
✅ **Encapsulation dot1Q**: necessario per subinterface VLAN
✅ **Routing statico**: configurato per comunicazione tra le 5 subnet
✅ **Trunk allowed VLAN**: limitato a VLAN 10,20 per sicurezza
✅ **Access mode**: tutte le porte verso PC/Server

## Schema Colorazione (opzionale)

Per migliorare la visualizzazione in Packet Tracer:

- **VLAN 10**: Colore **Viola/Rosa**
- **VLAN 20**: Colore **Ciano**
- **Backbone**: Colore **Rosso**

Click destro su cavo → **Color** → seleziona colore appropriato
