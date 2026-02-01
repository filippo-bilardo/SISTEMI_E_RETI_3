# Policy firewall (alto livello)

> Supporto alla **Prima Parte – Punto 1 (connessione telecamere/dispositivi)** e **Punto 4 (continuità/sicurezza)**.

## Principi

- Default deny tra VLAN.
- Aperture per applicazione (porta + destinazione + identità).
- Logging su eventi critici (auth fallite, comandi IoT, accessi DMZ).

## DMZ

- Internet → DMZ reverse proxy: `TCP/443`
- DMZ reverse proxy → app ticketing (VLAN10): `TCP/443`
- DMZ reverse proxy → API IoT (VLAN30): `TCP/443`

## Videosorveglianza

- Telecamere (VPN `10.20.20.0/24`) → NVR (VLAN20): `TCP/554` (RTSP) + `TCP/443` (ONVIF/management, se necessario)
- VLAN20 → Internet: **bloccato** (salvo aggiornamenti via repository autorizzato)

## IoT

- Dispositivi (VPN `10.20.10.0/24`) → IoT API (VLAN30): `TCP/443`
- Dispositivi → MQTT broker (VLAN30): `TCP/8883` (MQTTS)

## Totem

- Totem (VPN `10.20.30.0/24`) → Ticketing API (DMZ): `TCP/443`
- Totem → PSP pagamenti: `TCP/443` solo verso FQDN/IP provider

## Management

- Solo bastion (VLAN40, `10.10.40.20`) può fare:
  - SSH `TCP/22` verso server
  - HTTPS `TCP/443` verso apparati
  - SNMP `UDP/161` verso apparati

## Protezioni consigliate

- WAF sul reverse proxy
- IDS/IPS su firewall
- Rate-limit sulle API IoT
- mTLS per dispositivi e totem
