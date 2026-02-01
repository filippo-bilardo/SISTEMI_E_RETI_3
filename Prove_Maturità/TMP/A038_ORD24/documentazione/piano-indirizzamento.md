# PIANO DI INDIRIZZAMENTO IP
## Prova A038_ORD24

**Rete Aziendale Principale**: 10.50.0.0/16  
**Standard**: RFC 1918 - Rete Privata Classe A

---

## Tabella Riepilogativa Sottoreti

| Sottorete | Network | CIDR | Subnet Mask | Gateway | Range IP | Hosts | VLAN | Utilizzo |
|-----------|---------|------|-------------|---------|----------|-------|------|----------|
| LAN1-Utenti | 10.50.10.0 | /24 | 255.255.255.0 | 10.50.10.1 | .10 - .254 | 254 | 10 | Postazioni utenti uffici |
| LAN2-Server | 10.50.20.0 | /24 | 255.255.255.0 | 10.50.20.1 | .1 - .254 | 254 | 20 | Server applicativi |
| LAN3-Admin | 10.50.30.0 | /24 | 255.255.255.0 | 10.50.30.1 | .1 - .254 | 254 | 30 | Amministrazione IT |
| DMZ | 10.50.100.0 | /26 | 255.255.255.192 | 10.50.100.1 | .1 - .62 | 62 | 100 | Server pubblici web/mail |
| VPN | 10.50.200.0 | /26 | 255.255.255.192 | 10.50.200.1 | .10 - .60 | 50 | - | Client VPN remoti |
| Management | 10.50.1.0 | /24 | 255.255.255.0 | 10.50.1.1 | .1 - .254 | 254 | 1 | Management dispositivi |

---

## Assegnazioni IP Statici

### Dispositivi di Rete
```
10.50.0.1       Router Gateway (GW principale)
10.50.0.2       Firewall/UTM
10.50.1.2       Switch Core Layer 3
```

### Server DMZ (10.50.100.0/26)
```
10.50.100.1     Gateway DMZ
10.50.100.10    Web Server (Apache)
10.50.100.11    Mail Server (Postfix/Dovecot)
10.50.100.12    FTP Server (opzionale)
```

### Server Interni LAN2 (10.50.20.0/24)
```
10.50.20.1      Gateway LAN2
10.50.20.10     DNS Server (BIND9) - ns1.azienda.local
10.50.20.11     DHCP Server (ISC DHCP)
10.50.20.12     File Server / Syslog Server
10.50.20.13     Database Server (MySQL/PostgreSQL)
10.50.20.14     Application Server
10.50.20.15     VPN Server (OpenVPN)
```

### DHCP Pool Dinamici

**LAN1 - Utenti (10.50.10.0/24)**
- Range dinamico: 10.50.10.50 - 10.50.10.200 (151 IP)
- IP riservati (10-49): Stampanti, AP WiFi, dispositivi fissi

**LAN3 - Admin (10.50.30.0/24)**
- Range dinamico: 10.50.30.50 - 10.50.30.150 (101 IP)
- IP riservati (10-49): Workstation admin, management console

---

## Calcolo Subnetting

### LAN 1, 2, 3 (/24)
- **Host disponibili**: 2^8 - 2 = 254
- **Network ID**: .0
- **Broadcast**: .255
- **Gateway**: .1
- **Host utilizzabili**: .2 - .254

### DMZ e VPN (/26)
- **Host disponibili**: 2^6 - 2 = 62
- **Network ID**: .0
- **Broadcast**: .63 (DMZ) / .63 (VPN)
- **Gateway**: .1
- **Host utilizzabili**: .2 - .62

---

## Record DNS Principali

```dns
ns1.azienda.local       IN A 10.50.20.10
web.azienda.local       IN A 10.50.100.10
mail.azienda.local      IN A 10.50.100.11
db.azienda.local        IN A 10.50.20.13
vpn.azienda.local       IN A 10.50.20.15
router.azienda.local    IN A 10.50.0.1
```

---

## Port Forwarding (NAT)

| Servizio | Porta Esterna | IP Destinazione | Porta Interna | Protocollo |
|----------|---------------|-----------------|---------------|------------|
| HTTP | 80 | 10.50.100.10 | 80 | TCP |
| HTTPS | 443 | 10.50.100.10 | 443 | TCP |
| SMTP | 25 | 10.50.100.11 | 25 | TCP |
| Submission | 587 | 10.50.100.11 | 587 | TCP |
| IMAPS | 993 | 10.50.100.11 | 993 | TCP |
| OpenVPN | 1194 | 10.50.20.15 | 1194 | UDP |

---

## Flussi di Traffico Consentiti

### Da Internet
- → DMZ (porte 80, 443, 25, 587, 993): ✓ CONSENTITO
- → LAN interna: ✗ BLOCCATO

### Da DMZ
- → Internet: ✓ CONSENTITO (aggiornamenti)
- → LAN interna: ✗ BLOCCATO (isolamento)

### Da LAN1/LAN3 (Utenti/Admin)
- → Internet: ✓ CONSENTITO (con NAT)
- → LAN2 (Server): ✓ CONSENTITO
- → DMZ: ✓ CONSENTITO solo LAN3 (admin)

### Da VPN
- → LAN1, LAN2, LAN3: ✓ CONSENTITO
- → DMZ: ✓ CONSENTITO
- → Internet: ✓ CONSENTITO

---

## Riepilogo Utilizzo Indirizzi

| Subnet | Totale IP | Utilizzati | Disponibili | Percentuale Uso |
|--------|-----------|------------|-------------|-----------------|
| LAN1 | 254 | ~80 | 174 | 31% |
| LAN2 | 254 | 6 | 248 | 2% |
| LAN3 | 254 | ~20 | 234 | 8% |
| DMZ | 62 | 3 | 59 | 5% |
| VPN | 62 | ~10 | 52 | 16% |
| **Totale** | **886** | **~119** | **767** | **13%** |

**Scalabilità**: Ampio margine per espansione futura.
