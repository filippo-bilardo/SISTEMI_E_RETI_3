# Piano di indirizzamento IP (proposta)

> Riferimento: **Prima Parte – Punto 1.a** (architettura rete) e vincolo “solo tablet” (segmentazione).

## Ipotesi

- 20 POI nel centro storico.
- 8 InfoPoint.
- 400 tablet in rotazione.

## Spazi IP

- Core/Backbone cittadino: `10.60.0.0/16`
- CED (server): `10.61.0.0/16`
- POI WiFi (per-POI): `10.62.0.0/16`
- Management: `10.63.0.0/16`

## VLAN (esempio)

| VLAN | Nome | Subnet | Note |
|------|------|--------|------|
| 110 | CED-DMZ | `10.61.10.0/24` | Reverse proxy/WAF |
| 120 | CED-APP | `10.61.20.0/24` | Web/App servers |
| 130 | CED-DB | `10.61.30.0/24` | DB + backup |
| 140 | CED-MEDIA | `10.61.40.0/24` | Object storage / NAS |
| 150 | AAA | `10.61.50.0/24` | RADIUS/MDM/DNS |
| 160 | MON | `10.61.60.0/24` | Logging/monitoring |
| 210 | INFOPOINT | `10.60.10.0/24` | Chioschi (backoffice) |
| 310-329 | POI-01..POI-20 | `10.62.<poi>.0/24` | SSID/VLAN dedicati ai POI |
| 900 | MGMT-NET | `10.63.0.0/24` | mgmt switch/AP |

## Perché VLAN per-POI

- Il vincolo “accesso al POI solo in prossimità” può essere implementato verificando:
  - SSID/VLAN di provenienza (source subnet → poiId), e/o
  - beacon BLE presente (opzionale).

## DHCP/DNS

- DHCP per reti POI: pool `10.62.X.100-10.62.X.250`.
- DNS interno: `poi.local` (es. `poi-01.poi.local`).
