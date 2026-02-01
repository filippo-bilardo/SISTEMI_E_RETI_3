# Piano di Indirizzamento IP - A038_STR24

## Architettura di Rete

```
Internet (WAN)
      |
  [Router/Gateway]
      |
  [Firewall]
      |
  [Switch Core L3]
      |
   +---------+---------+---------+
   |         |         |         |
LAN1      LAN2      LAN3      DMZ
Utenti    Server    Admin   Pubblico
```

## Schema di Subnetting

**Rete Principale**: 172.16.0.0/16  
**Classe**: B Privata (RFC 1918)  
**Totale indirizzi disponibili**: 65,536

## Dettaglio Sottoreti

### 1. LAN1 - Rete Utenti
- **Rete**: 172.16.1.0/24
- **Subnet Mask**: 255.255.255.0
- **Gateway**: 172.16.1.1
- **Broadcast**: 172.16.1.255
- **Range utilizzabile**: 172.16.1.1 - 172.16.1.254
- **Numero host**: 254
- **VLAN**: 10
- **Descrizione**: Postazioni di lavoro utenti
- **Servizi**: DHCP dinamico (range 172.16.1.50-250)

#### Assegnazioni Statiche LAN1
| IP | Hostname | Tipo | Descrizione |
|----|----------|------|-------------|
| 172.16.1.1 | gw-lan1 | Gateway | Gateway/Router VLAN 10 |
| 172.16.1.10 | printer-01 | Stampante | Stampante reparto amministrativo |
| 172.16.1.11 | printer-02 | Stampante | Stampante reparto vendite |
| 172.16.1.20 | voip-01 | VoIP Gateway | Gateway telefonia IP |
| 172.16.1.50-250 | dhcp-pool | DHCP | Range dinamico per client |

---

### 2. LAN2 - Rete Server
- **Rete**: 172.16.2.0/24
- **Subnet Mask**: 255.255.255.0
- **Gateway**: 172.16.2.1
- **Broadcast**: 172.16.2.255
- **Range utilizzabile**: 172.16.2.1 - 172.16.2.254
- **Numero host**: 254
- **VLAN**: 20
- **Descrizione**: Server farm interni
- **Servizi**: IP statici

#### Assegnazioni Server LAN2
| IP | Hostname | Tipo | Servizi |
|----|----------|------|---------|
| 172.16.2.1 | gw-lan2 | Gateway | Gateway/Router VLAN 20 |
| 172.16.2.10 | srv-dns | DNS Server | BIND9, resolver DNS interno |
| 172.16.2.11 | srv-dhcp | DHCP Server | ISC DHCP Server |
| 172.16.2.12 | srv-file | File Server | Samba/NFS, storage condiviso |
| 172.16.2.13 | srv-db | Database | MySQL/PostgreSQL |
| 172.16.2.14 | srv-backup | Backup Server | Bacula/rsync |
| 172.16.2.15 | srv-ad | Active Directory | Domain Controller |
| 172.16.2.16 | srv-app | Application Server | Server applicazioni interne |
| 172.16.2.20 | srv-monitoring | Monitoring | Nagios/Zabbix |
| 172.16.2.21 | srv-log | Log Server | Syslog/ELK Stack |
| 172.16.2.30 | nas-01 | NAS | Network Attached Storage |

---

### 3. LAN3 - Rete Amministrazione
- **Rete**: 172.16.3.0/24
- **Subnet Mask**: 255.255.255.0
- **Gateway**: 172.16.3.1
- **Broadcast**: 172.16.3.255
- **Range utilizzabile**: 172.16.3.1 - 172.16.3.254
- **Numero host**: 254
- **VLAN**: 30
- **Descrizione**: Postazioni IT/Amministratori
- **Servizi**: DHCP con reservation / IP statici

#### Assegnazioni LAN3
| IP | Hostname | Tipo | Descrizione |
|----|----------|------|-------------|
| 172.16.3.1 | gw-lan3 | Gateway | Gateway/Router VLAN 30 |
| 172.16.3.10 | admin-01 | Workstation | PC amministratore sistema |
| 172.16.3.11 | admin-02 | Workstation | PC amministratore rete |
| 172.16.3.12 | admin-03 | Workstation | PC amministratore sicurezza |
| 172.16.3.20 | jump-server | Jump Host | Bastion host per admin remoto |
| 172.16.3.50-200 | dhcp-pool | DHCP | Range per dispositivi temporanei |

---

### 4. DMZ - Demilitarized Zone
- **Rete**: 172.16.10.0/26
- **Subnet Mask**: 255.255.255.192
- **Gateway**: 172.16.10.1
- **Broadcast**: 172.16.10.63
- **Range utilizzabile**: 172.16.10.1 - 172.16.10.62
- **Numero host**: 62
- **VLAN**: 40
- **Descrizione**: Server pubblicamente accessibili
- **Servizi**: IP statici, isolamento dalla LAN

#### Assegnazioni DMZ
| IP | Hostname | Tipo | Servizi Esposti | Porte Pubbliche |
|----|----------|------|-----------------|-----------------|
| 172.16.10.1 | gw-dmz | Gateway | Gateway/Router VLAN 40 | - |
| 172.16.10.10 | srv-web | Web Server | Apache/Nginx, HTTPS | 80, 443 |
| 172.16.10.11 | srv-mail | Mail Server | Postfix, Dovecot | 25, 465, 587, 993 |
| 172.16.10.12 | srv-ftp | FTP Server | vsftpd, SFTP | 21, 22 |
| 172.16.10.13 | srv-vpn | VPN Server | OpenVPN | 1194 |
| 172.16.10.20 | proxy-01 | Reverse Proxy | HAProxy/Nginx | 80, 443 |
| 172.16.10.30 | waf-01 | Web App Firewall | ModSecurity | - |

---

### 5. VPN - Rete VPN Client
- **Rete**: 172.16.20.0/26
- **Subnet Mask**: 255.255.255.192
- **Gateway**: 172.16.20.1
- **Broadcast**: 172.16.20.63
- **Range utilizzabile**: 172.16.20.1 - 172.16.20.62
- **Numero host**: 62
- **Descrizione**: Pool IP per client VPN
- **Servizi**: OpenVPN dynamic assignment

#### Configurazione VPN
| Range | Tipo | Descrizione |
|-------|------|-------------|
| 172.16.20.1 | Server | Endpoint server VPN |
| 172.16.20.10-60 | Dynamic Pool | Assegnazione dinamica client VPN |

---

### 6. Management - Rete di Gestione
- **Rete**: 172.16.30.0/28
- **Subnet Mask**: 255.255.255.240
- **Gateway**: 172.16.30.1
- **Broadcast**: 172.16.30.15
- **Range utilizzabile**: 172.16.30.1 - 172.16.30.14
- **Numero host**: 14
- **VLAN**: 50
- **Descrizione**: Interfacce di management switch/router
- **Servizi**: Accesso SSH/Telnet dispositivi

#### Assegnazioni Management
| IP | Hostname | Tipo | Descrizione |
|----|----------|------|-------------|
| 172.16.30.1 | gw-mgmt | Gateway | Gateway management |
| 172.16.30.2 | sw-core | Switch | Switch Core Layer 3 |
| 172.16.30.3 | sw-lan1 | Switch | Switch LAN1 Utenti |
| 172.16.30.4 | sw-lan2 | Switch | Switch LAN2 Server |
| 172.16.30.5 | sw-dmz | Switch | Switch DMZ |
| 172.16.30.6 | fw-main | Firewall | Interfaccia management firewall |
| 172.16.30.7 | ap-01 | Access Point | Wireless AP gestione |

---

## Tabella Riepilogativa Sottoreti

| Sottorete | Indirizzo | CIDR | Mask | Gateway | Hosts | VLAN | Utilizzo |
|-----------|-----------|------|------|---------|-------|------|----------|
| LAN1-Utenti | 172.16.1.0 | /24 | 255.255.255.0 | 172.16.1.1 | 254 | 10 | Client workstation |
| LAN2-Server | 172.16.2.0 | /24 | 255.255.255.0 | 172.16.2.1 | 254 | 20 | Server interni |
| LAN3-Admin | 172.16.3.0 | /24 | 255.255.255.0 | 172.16.3.1 | 254 | 30 | Amministrazione |
| DMZ | 172.16.10.0 | /26 | 255.255.255.192 | 172.16.10.1 | 62 | 40 | Server pubblici |
| VPN | 172.16.20.0 | /26 | 255.255.255.192 | 172.16.20.1 | 62 | - | Client VPN |
| Management | 172.16.30.0 | /28 | 255.255.255.240 | 172.16.30.1 | 14 | 50 | Device management |

---

## Calcolo Subnetting

### Subnet /24 (Esempio: 172.16.1.0/24)
- **Bit di host**: 8 bit
- **Indirizzi totali**: 2^8 = 256
- **Indirizzi utilizzabili**: 254 (256 - 2)
- **Primo IP valido**: 172.16.1.1 (rete + 1)
- **Ultimo IP valido**: 172.16.1.254 (broadcast - 1)
- **Broadcast**: 172.16.1.255

### Subnet /26 (Esempio: 172.16.10.0/26)
- **Bit di host**: 6 bit
- **Indirizzi totali**: 2^6 = 64
- **Indirizzi utilizzabili**: 62 (64 - 2)
- **Primo IP valido**: 172.16.10.1
- **Ultimo IP valido**: 172.16.10.62
- **Broadcast**: 172.16.10.63

### Subnet /28 (Esempio: 172.16.30.0/28)
- **Bit di host**: 4 bit
- **Indirizzi totali**: 2^4 = 16
- **Indirizzi utilizzabili**: 14 (16 - 2)
- **Primo IP valido**: 172.16.30.1
- **Ultimo IP valido**: 172.16.30.14
- **Broadcast**: 172.16.30.15

---

## Routing tra Sottoreti

### Route principali sul Router/Firewall

```bash
# Route verso LAN1
ip route 172.16.1.0 255.255.255.0 172.16.0.2

# Route verso LAN2
ip route 172.16.2.0 255.255.255.0 172.16.0.2

# Route verso LAN3
ip route 172.16.3.0 255.255.255.0 172.16.0.2

# Route verso DMZ
ip route 172.16.10.0 255.255.255.192 172.16.0.2

# Route verso VPN
ip route 172.16.20.0 255.255.255.192 172.16.20.1

# Route di default verso Internet
ip route 0.0.0.0 0.0.0.0 [ISP_GATEWAY]
```

---

## DNS Records

### Zone: azienda.local

```dns
; Server
srv-dns.azienda.local.       IN  A  172.16.2.10
srv-dhcp.azienda.local.      IN  A  172.16.2.11
srv-file.azienda.local.      IN  A  172.16.2.12
srv-db.azienda.local.        IN  A  172.16.2.13

; DMZ
web.azienda.local.           IN  A  172.16.10.10
www.azienda.local.           IN  CNAME  web.azienda.local.
mail.azienda.local.          IN  A  172.16.10.11
ftp.azienda.local.           IN  A  172.16.10.12
vpn.azienda.local.           IN  A  172.16.10.13

; Mail
@                            IN  MX  10  mail.azienda.local.
```

---

## NAT/PAT Configuration

### Port Forwarding da Internet verso DMZ

| Servizio | Porta Esterna | IP Interno | Porta Interna | Protocollo |
|----------|---------------|------------|---------------|------------|
| HTTP | 80 | 172.16.10.10 | 80 | TCP |
| HTTPS | 443 | 172.16.10.10 | 443 | TCP |
| SMTP | 25 | 172.16.10.11 | 25 | TCP |
| SMTPS | 465 | 172.16.10.11 | 465 | TCP |
| Submission | 587 | 172.16.10.11 | 587 | TCP |
| IMAPS | 993 | 172.16.10.11 | 993 | TCP |
| OpenVPN | 1194 | 172.16.10.13 | 1194 | UDP |

### NAT Overload (PAT)
- **Reti interne che utilizzano PAT**: 
  - 172.16.1.0/24 (LAN1)
  - 172.16.2.0/24 (LAN2)
  - 172.16.3.0/24 (LAN3)
  - 172.16.10.0/26 (DMZ - traffico in uscita)
  - 172.16.20.0/26 (VPN)

---

## Riserva Indirizzi per Espansione Futura

Le seguenti sottoreti sono riservate per future espansioni:

| Range Riservato | Possibile Utilizzo |
|-----------------|-------------------|
| 172.16.4.0/24 | LAN4 - Nuova sede |
| 172.16.5.0/24 | LAN5 - Laboratorio/Testing |
| 172.16.11.0/24 | DMZ2 - Espansione servizi pubblici |
| 172.16.21.0/26 | VPN2 - Pool aggiuntivo |
| 172.16.40.0/22 | Riservato per datacenter esterno |
| 172.16.50.0/24 | Guest WiFi |
| 172.16.60.0/24 | IoT Devices |

---

## Note di Sicurezza

1. **Isolamento DMZ**: La DMZ è completamente isolata dalla LAN. Nessun traffico diretto DMZ → LAN è permesso.

2. **Accesso Amministrativo**: L'accesso SSH/management è limitato alla rete LAN3 (Admin) e Management VLAN.

3. **Segmentazione**: Ogni sottorete è in una VLAN separata per isolamento L2.

4. **IP Privati**: Tutti gli indirizzi rispettano RFC 1918 (reti private).

5. **Anti-Spoofing**: Il firewall deve bloccare pacchetti con IP sorgente 172.16.x.x provenienti da WAN.

---

**Documento creato**: 30 Gennaio 2026  
**Progetto**: A038_STR24  
**Versione**: 1.0
