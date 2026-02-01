# Configurazione VLAN (esempio – Cisco-like)

> Supporto alla **Prima Parte – Punto 1 (organizzazione rete sede)**.

## Modello

- 2 switch core in stack (routing inter-VLAN su SVI).
- Access switch L2 con trunk verso core.

## VLAN

```text
vlan 10
 name TICKETING
vlan 20
 name VIDEO
vlan 30
 name IOT
vlan 40
 name MGMT
vlan 50
 name WIFI_STAFF
vlan 60
 name DMZ
```

## SVI (gateway VLAN)

```text
interface Vlan10
 ip address 10.10.10.1 255.255.255.0
 ip helper-address 10.10.40.30   # DHCP server (se centralizzato)

interface Vlan20
 ip address 10.10.20.1 255.255.255.0

interface Vlan30
 ip address 10.10.30.1 255.255.255.0

interface Vlan40
 ip address 10.10.40.1 255.255.255.0

interface Vlan50
 ip address 10.10.50.1 255.255.255.0
 ip helper-address 10.10.40.30

interface Vlan60
 ip address 10.10.60.1 255.255.255.0
```

## Porte access (esempi)

```text
interface GigabitEthernet1/0/10
 description Postazione operatore
 switchport mode access
 switchport access vlan 10
 spanning-tree portfast

interface GigabitEthernet1/0/20
 description Console sala controllo
 switchport mode access
 switchport access vlan 20
 spanning-tree portfast

interface GigabitEthernet1/0/30
 description AP WiFi Staff
 switchport mode access
 switchport access vlan 50
 spanning-tree portfast
```

## Trunk verso core

```text
interface TenGigabitEthernet1/1/1
 description Uplink to Core
 switchport trunk encapsulation dot1q
 switchport mode trunk
 switchport trunk allowed vlan 10,20,30,40,50,60
```

## Suggerimenti sicurezza L2

- `bpduguard` su access
- `dhcp snooping` su VLAN con DHCP
- `port-security` su postazioni fisse
- VLAN 40 (Mgmt) accessibile solo da bastion
