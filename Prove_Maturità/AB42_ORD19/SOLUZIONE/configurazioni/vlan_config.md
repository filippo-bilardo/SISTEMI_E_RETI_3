# VLAN config (esempio)

> Riferimento: **Prima Parte – Punto 1.a**.

## Creazione VLAN (estratto)

```text
vlan 110 name CED_DMZ
vlan 120 name CED_APP
vlan 130 name CED_DB
vlan 140 name CED_MEDIA
vlan 150 name AAA
vlan 160 name MON
vlan 210 name INFOPOINT
vlan 310 name POI_01
vlan 311 name POI_02
...
vlan 329 name POI_20
vlan 900 name MGMT
```

## Routing inter-VLAN

- Solo sul core/edge del CED.
- Default deny fra VLAN; aperture solo per servizi.
