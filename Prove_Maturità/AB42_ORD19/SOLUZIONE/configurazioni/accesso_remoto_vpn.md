# Accesso remoto e VPN (Quesito IV)

> Riferimento: **Seconda parte – Quesito IV**.

## Tipologie di accesso remoto

- **Remote Desktop / GUI**
  - RDP (Windows), VNC
  - Pro: facile per utenti; Contro: superficie d’attacco elevata.

- **Shell remota**
  - SSH
  - Pro: sicuro e scriptabile; Contro: richiede competenze.

- **Accesso applicativo**
  - HTTPS verso applicazioni (portali web, API)
  - Pro: nessuna esposizione della LAN; Contro: richiede app ben progettata.

## VPN: scopo e benefici

- Crea un “tunnel” cifrato su rete pubblica.
- Permette routing sicuro tra sedi e/o verso utenti mobili.

### Tipi di VPN

- **Site-to-site**: collega due sedi (router ↔ router)
- **Remote-access**: collega utenti mobili a una sede (client ↔ concentratore)

### Protocolli comuni

- **IPsec** (IKEv2)
  - Standard enterprise, spesso su firewall.
- **SSL/TLS VPN**
  - Accesso remoto più semplice lato client.
- **WireGuard**
  - Moderno, veloce, configurazione snella.

## Esempio: azienda con 2 sedi + agenti commerciali

### Indirizzamento (esempio)

- Sede A: `10.10.0.0/16`
- Sede B: `10.20.0.0/16`
- Pool agenti VPN: `10.250.0.0/24`

### Site-to-site

- Tunnel IPsec tra firewall Sede A e Sede B.
- Rotte:
  - da A verso `10.20.0.0/16` via tunnel
  - da B verso `10.10.0.0/16` via tunnel

### Remote-access agenti

- Concentratore VPN in Sede A.
- Agenti ricevono IP dal pool `10.250.0.0/24`.
- Policy:
  - accesso solo a CRM/ERP e file server necessari
  - MFA obbligatorio
  - split-tunnel (solo traffico aziendale nel tunnel)

## Best practice

- MFA + certificati
- Least privilege (ACL per gruppi)
- Logging accessi e alert anomalie
- Postura device (MDM, patch level) per accesso
