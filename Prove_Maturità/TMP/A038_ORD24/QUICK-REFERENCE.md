# QUICK REFERENCE GUIDE
## Prova A038_ORD24 - Guida Rapida

**Data**: 30 Gennaio 2026  
**Versione**: 1.0

---

## 📋 INDICE RAPIDO

1. [Comandi Utili](#comandi-utili)
2. [Checklist Pre-Produzione](#checklist-pre-produzione)
3. [Porte Pubbliche Esposte](#porte-pubbliche-esposte)
4. [Policy Password e Sicurezza](#policy-password-e-sicurezza)
5. [Contatti di Emergenza](#contatti-di-emergenza)
6. [File Importanti](#file-importanti)

---

## 🔧 COMANDI UTILI

### Router Cisco
```cisco
# Accesso
ssh admin@10.50.0.1

# Verifica configurazione
show running-config
show ip interface brief
show ip nat translations
show ip route
show access-lists

# Salvataggio
copy running-config startup-config
write memory

# Backup config
copy running-config tftp://10.50.20.12/router-backup.cfg

# Debug NAT
debug ip nat
show ip nat statistics
```

### Switch Core
```cisco
# Accesso
ssh admin@10.50.1.2

# Verifica VLAN
show vlan brief
show interfaces trunk
show interfaces status

# Verifica STP
show spanning-tree summary
show spanning-tree vlan 10

# Sicurezza Layer 2
show port-security
show ip dhcp snooping
show ip arp inspection

# Routing
show ip route
show ip interface brief
```

### Firewall (iptables)
```bash
# Verifica regole attive
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Salvataggio
sudo iptables-save > /etc/iptables/rules.v4

# Ripristino
sudo iptables-restore < /etc/iptables/rules.v4

# Riesecuzione script
sudo ./script/firewall-setup.sh

# Log in tempo reale
sudo tail -f /var/log/syslog | grep IPT-DROP
```

### DNS Server (BIND9)
```bash
# Verifica configurazione
sudo named-checkconf
sudo named-checkzone azienda.local /etc/bind/zones/db.azienda.local

# Ricarica configurazione
sudo rndc reload
sudo systemctl reload bind9

# Status
sudo systemctl status bind9

# Test query
dig @10.50.20.10 web.azienda.local
nslookup mail.azienda.local 10.50.20.10

# Log
sudo tail -f /var/log/syslog | grep named
```

### DHCP Server
```bash
# Status
sudo systemctl status isc-dhcp-server

# Lease attivi
sudo dhcp-lease-list
cat /var/lib/dhcp/dhcpd.leases

# Riavvio
sudo systemctl restart isc-dhcp-server

# Log
sudo tail -f /var/log/syslog | grep dhcpd

# Test da client
sudo dhclient -r eth0  # Release
sudo dhclient eth0     # Renew
```

### Web Server (Apache)
```bash
# Test configurazione
sudo apache2ctl configtest
sudo apache2ctl -S  # Virtual hosts

# Ricarica
sudo systemctl reload apache2

# Status
sudo systemctl status apache2

# Log in tempo reale
sudo tail -f /var/log/apache2/azienda-access.log
sudo tail -f /var/log/apache2/azienda-error.log

# Test da CLI
curl -I http://10.50.100.10
curl -k -I https://10.50.100.10
```

### Mail Server (Postfix)
```bash
# Test configurazione
sudo postfix check

# Ricarica
sudo postfix reload

# Coda mail
mailq
postqueue -p

# Flush coda
postqueue -f

# Cancella coda
postsuper -d ALL

# Log
sudo tail -f /var/log/mail.log

# Test SMTP
telnet 10.50.100.11 25
openssl s_client -connect 10.50.100.11:587 -starttls smtp
```

### VPN Server (OpenVPN)
```bash
# Avvio/Status
sudo systemctl start openvpn@server
sudo systemctl status openvpn@server

# Client connessi
sudo cat /var/log/openvpn/openvpn-status.log

# Log in tempo reale
sudo tail -f /var/log/openvpn/openvpn.log

# Gestione PKI (certificati)
cd /etc/openvpn/easy-rsa
./easyrsa build-client-full <nome> nopass
./easyrsa revoke <nome>
./easyrsa gen-crl
```

### Monitoring e Test
```bash
# Test connettività
ping -c 3 10.50.0.1         # Gateway
ping -c 3 10.50.20.10       # DNS
ping -c 3 8.8.8.8           # Internet

# Traceroute
traceroute 8.8.8.8

# Port test
nc -zv 10.50.100.10 80      # HTTP
nc -zv 10.50.100.11 25      # SMTP

# DNS test
nslookup web.azienda.local

# Esegui script monitoring
sudo ./script/network-monitor.sh
```

---

## ✅ CHECKLIST PRE-PRODUZIONE

### Dispositivi di Rete
- [ ] Router configurato e testato (NAT, routing, ACL)
- [ ] Switch configurato (VLAN, trunking, port security)
- [ ] Firewall attivo con regole testate
- [ ] Backup configurazioni salvato su TFTP/File Server
- [ ] Password cambiate (no password di default)
- [ ] SSH abilitato, Telnet disabilitato
- [ ] SNMP configurato per monitoring
- [ ] NTP configurato per sincronizzazione oraria
- [ ] Logging verso syslog centralizzato

### Servizi di Rete
- [ ] DNS risolve tutti i nomi correttamente
- [ ] DHCP assegna IP in tutti i range
- [ ] Web server accessibile da Internet e LAN
- [ ] Certificati SSL installati (non self-signed)
- [ ] Mail server invia e riceve email
- [ ] VPN testata con client remoto
- [ ] Tutti i servizi con TLS/SSL dove applicabile

### Sicurezza
- [ ] Policy firewall testata (DMZ isolata)
- [ ] Port forwarding funzionante
- [ ] Anti-spoofing attivo
- [ ] Rate limiting configurato
- [ ] Banner di login configurati
- [ ] Utenti con privilegi minimi
- [ ] Audit log abilitato
- [ ] Password policy applicata (8+ caratteri, complessità)

### Backup e Monitoring
- [ ] Script backup testato
- [ ] Backup automatico schedulato (cron)
- [ ] Monitoring script funzionante
- [ ] Alert email configurati
- [ ] Log centralizzati su syslog server
- [ ] Retention policy definita (30 giorni)
- [ ] Procedura di ripristino testata

### Documentazione
- [ ] Piano IP completo e aggiornato
- [ ] Diagrammi di rete creati
- [ ] Credenziali documentate (vault sicuro)
- [ ] Procedure operative documentate
- [ ] Contatti di emergenza aggiornati

---

## 🌐 PORTE PUBBLICHE ESPOSTE

### Da Internet Verso DMZ

| Porta | Protocollo | Servizio | Server Destinazione | Note |
|-------|------------|----------|---------------------|------|
| **80** | TCP | HTTP | 10.50.100.10 | Redirect a HTTPS |
| **443** | TCP | HTTPS | 10.50.100.10 | Web Server |
| **25** | TCP | SMTP | 10.50.100.11 | Mail in entrata |
| **587** | TCP | Submission | 10.50.100.11 | Mail autenticata |
| **993** | TCP | IMAPS | 10.50.100.11 | Accesso caselle mail |
| **1194** | UDP | OpenVPN | 10.50.20.15 | VPN remota |

### Porte Aperte Solo Internamente

| Porta | Protocollo | Servizio | Server | Note |
|-------|------------|----------|--------|------|
| 22 | TCP | SSH | Tutti | Solo da LAN Admin (10.50.30.0/24) |
| 53 | UDP/TCP | DNS | 10.50.20.10 | Solo LAN interna |
| 3306 | TCP | MySQL | 10.50.20.13 | Solo LAN interna |
| 445 | TCP | SMB | 10.50.20.12 | File sharing interno |
| 7505 | TCP | OpenVPN Mgmt | 10.50.20.15 | Solo localhost |

---

## 🔐 POLICY PASSWORD E SICUREZZA

### Requisiti Password

**Lunghezza Minima**: 12 caratteri  
**Complessità Richiesta**:
- Almeno 1 maiuscola (A-Z)
- Almeno 1 minuscola (a-z)
- Almeno 1 numero (0-9)
- Almeno 1 carattere speciale (!@#$%^&*)

**Scadenza**: 90 giorni  
**Riutilizzo**: Non riutilizzare le ultime 5 password  
**Tentativi Falliti**: Blocco dopo 5 tentativi errati (10 minuti)

### Account di Default da Cambiare

```
Router:   admin / <nuova-password-complessa>
Switch:   admin / <nuova-password-complessa>
Servers:  root / <DISABILITATO - usare sudo>
```

### Best Practices Sicurezza

1. **Accesso SSH**:
   - Usare chiavi SSH invece di password
   - Disabilitare root login (`PermitRootLogin no`)
   - Usare fail2ban per protezione brute-force

2. **Gestione Password**:
   - Usare password manager (KeePass, 1Password)
   - Mai password in plain-text
   - Cambiare password dopo incident

3. **Monitoring Sicurezza**:
   - Controllare log giornalmente
   - Alert su login falliti multipli
   - Monitorare traffico anomalo

4. **Aggiornamenti**:
   - Applicare security patch mensili
   - Testare in ambiente di test prima
   - Backup prima di aggiornamenti maggiori

---

## 📞 CONTATTI DI EMERGENZA

### Team IT Interno

| Ruolo | Nome | Telefono | Email | Disponibilità |
|-------|------|----------|-------|---------------|
| **IT Manager** | Mario Rossi | +39 333 1234567 | m.rossi@azienda.local | H24 |
| **Network Admin** | Luigi Bianchi | +39 333 2345678 | l.bianchi@azienda.local | Lun-Ven 8-18 |
| **Security Admin** | Sara Verdi | +39 333 3456789 | s.verdi@azienda.local | H24 (emergenze) |
| **System Admin** | Paolo Neri | +39 333 4567890 | p.neri@azienda.local | Lun-Ven 8-18 |

### Fornitori Esterni

| Servizio | Azienda | Telefono | Email | Contratto |
|----------|---------|----------|-------|-----------|
| **ISP** | TIM Business | 187 | support@tim.it | #TIM-2024-001 |
| **Firewall** | Fortinet | +39 02 1234567 | support@fortinet.com | Premium Support |
| **Cloud Backup** | AWS Support | +1 866 9999999 | - | Business Plan |

### Escalation Path

1. **Livello 1**: Network Admin (risposta entro 30 min)
2. **Livello 2**: IT Manager (escalation dopo 2 ore)
3. **Livello 3**: Fornitore Esterno (incident critici)

### Numeri Utili

- **Polizia Postale**: 02-XXX-XXXX
- **CERT Nazionale**: cert@agid.gov.it
- **Supporto Hardware**: +39 800-XXXXX

---

## 📁 FILE IMPORTANTI

### File di Configurazione

```
📂 configurazioni/
├── router-config.txt              # Router Cisco IOS config
├── switch-config.txt              # Switch L3 config
├── dhcp-server.conf               # ISC DHCP Server
├── dns-named.conf.local           # BIND9 zone definitions
├── dns-db.azienda.local           # DNS zone file
├── apache-virtualhost.conf        # Apache vhost
├── postfix-main.cf                # Mail server config
└── openvpn-server.conf            # VPN server config
```

### Script di Automazione

```
📂 script/
├── firewall-setup.sh              # Setup completo firewall
├── network-monitor.sh             # Monitoring (da creare)
├── backup-network.sh              # Backup automatico (da creare)
└── test-network.sh                # Test suite (da creare)
```

### Documentazione

```
📂 documentazione/
├── piano-indirizzamento.md        # Piano IP dettagliato
├── architettura-rete.md           # Diagrammi e architettura
└── changelog.md                   # Log modifiche (da creare)
```

### Backup Locations

```
/backup/network/daily/             # Backup giornalieri (30 giorni)
/backup/network/weekly/            # Backup settimanali (3 mesi)
/backup/network/monthly/           # Backup mensili (1 anno)
```

### Log Files Critici

```
/var/log/syslog                    # System log generale
/var/log/auth.log                  # Autenticazioni
/var/log/apache2/access.log        # Web server access
/var/log/mail.log                  # Mail server log
/var/log/openvpn/openvpn.log       # VPN log
/var/log/iptables.log              # Firewall dropped packets
```

---

## 🚨 PROCEDURE DI EMERGENZA

### Disconnessione Rete (Incident Critico)

```bash
# Isolare completamente la rete da Internet
sudo iptables -P FORWARD DROP
sudo iptables -F
sudo iptables -A INPUT -s 10.50.30.0/24 -j ACCEPT  # Solo admin
```

### Ripristino da Backup

```bash
# Router
copy tftp://10.50.20.12/router-backup.cfg running-config
write memory

# Firewall
sudo iptables-restore < /backup/iptables-rules.v4

# Servizi
sudo systemctl stop apache2 postfix bind9
sudo tar -xzf /backup/services-YYYYMMDD.tar.gz -C /
sudo systemctl start apache2 postfix bind9
```

### Reset Password di Emergenza

```bash
# Linux server (recovery mode)
# Boot in single-user mode, poi:
passwd root

# Router Cisco (password recovery)
# Interrompere boot, poi:
rommon> confreg 0x2142
rommon> reset
Router(config)# no enable secret
Router(config)# enable secret <nuova-password>
Router(config)# config-register 0x2102
```

---

## 📊 KPI E METRICHE

### Performance Target

- **Uptime**: 99.9% (max 8.76h downtime/anno)
- **Latenza LAN**: < 2ms
- **Latenza Internet**: < 50ms
- **Packet Loss**: < 0.1%
- **Throughput WAN**: min 100 Mbps

### Monitoring Alerts

- CPU Router/Switch > 80%
- Memoria > 90%
- Disco > 85%
- Connessioni anomale > 1000/min
- Tentativi login falliti > 10/min

---

**Versione**: 1.0 - 30 Gennaio 2026  
**Ultimo Aggiornamento**: 2026-01-30  
**Prossima Revisione**: 2026-04-30
