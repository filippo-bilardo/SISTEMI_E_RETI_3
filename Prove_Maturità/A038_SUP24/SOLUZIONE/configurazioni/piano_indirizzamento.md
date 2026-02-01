# Piano di indirizzamento IP

> Supporto alla **Prima Parte – Punto 1 (organizzazione rete sede)** e **Punto 3 (totem sul territorio)**.

## Obiettivi

- Separare i domini di broadcast e limitare movimento laterale (segmentazione).
- Rendere semplice il troubleshooting (schema ripetibile, indirizzi “parlanti”).
- Prevedere crescita (nuove telecamere/totem/dispositivi).

## Spazi di indirizzamento

- **Sede operativa (LAN interne)**: `10.10.0.0/16`
- **DMZ**: `10.10.60.0/24`
- **VPN Remoti (città/campo)**: `10.20.0.0/16`

## VLAN e subnet

| VLAN | Nome | Subnet | Gateway (SVI) | Note |
|------|------|--------|----------------|------|
| 10 | Ticketing | `10.10.10.0/24` | `10.10.10.1` | 1° piano: operatori e ticketing |
| 20 | Videosorveglianza | `10.10.20.0/24` | `10.10.20.1` | 2° piano: VMS, NVR, console |
| 30 | IoT/Remoti | `10.10.30.0/24` | `10.10.30.1` | server controllo dispositivi + broker |
| 40 | Management | `10.10.40.0/24` | `10.10.40.1` | monitoring, bastion, mgmt switch |
| 50 | WiFi Staff | `10.10.50.0/24` | `10.10.50.1` | WiFi interno sede per staff |
| 60 | DMZ | `10.10.60.0/24` | `10.10.60.1` | reverse proxy, API gateway, WAF |

## Pool DHCP (esempio)

- VLAN 10: `10.10.10.100-10.10.10.199` (postazioni operatori)
- VLAN 50: `10.10.50.50-10.10.50.250` (WiFi staff)

Statici consigliati:
- `10.10.60.10` Reverse proxy / API Gateway
- `10.10.20.10` VMS
- `10.10.20.20` NVR
- `10.10.30.10` IoT Control Server
- `10.10.30.20` MQTT Broker
- `10.10.40.10` Zabbix
- `10.10.40.20` Bastion

## Reti VPN remoti (campo/città)

| Ambito | Subnet | Gateway (WG) | Note |
|--------|--------|--------------|------|
| Dispositivi azionabili | `10.20.10.0/24` | `10.20.10.1` | semafori, barriere, pannelli |
| Telecamere | `10.20.20.0/24` | `10.20.20.1` | cam IP + gateway edge |
| Totem | `10.20.30.0/24` | `10.20.30.1` | connettività mista fibra/4G |
| Staff mobile | `10.20.40.0/24` | `10.20.40.1` | app mobile (MDM) |

## DNS e naming (best practice)

- DNS interno: `corp.evento.local`
- Pattern hostname:
  - Totem: `totem-<zona>-<nn>` (es. `totem-a-01`)
  - Cam: `cam-<zona>-<nn>`
  - Dispositivi: `iot-<tipo>-<zona>-<nn>` (es. `iot-semaforo-a-01`)

## ACL di alto livello (principio del minimo privilegio)

- VLAN10 (Ticketing) → DMZ: solo `HTTPS 443` verso API
- VLAN20 (Video) → NVR/VMS: `RTSP 554` solo verso recorder + `HTTPS 443` verso console
- VLAN30 (IoT) → VPN remoti: `HTTPS 443` + `MQTTS 8883` (solo broker)
- VLAN50 (WiFi staff) → DMZ: `HTTPS 443` verso API + PTT verso provider
- VLAN40 (Mgmt) → tutti: solo protocolli gestione (SSH/HTTPS/SNMP) da bastion
