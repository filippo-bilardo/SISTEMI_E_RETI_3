# Quick Reference - A038_STR24

## 🎯 Informazioni Rapide

### Piano IP - Schema Veloce

```
LAN1 (Utenti):      172.16.1.0/24    - VLAN 10 - Gateway .1.1
LAN2 (Server):      172.16.2.0/24    - VLAN 20 - Gateway .2.1
LAN3 (Admin):       172.16.3.0/24    - VLAN 30 - Gateway .3.1
DMZ (Pubblico):     172.16.10.0/26   - VLAN 40 - Gateway .10.1
VPN (Client):       172.16.20.0/26   - N/A     - Server .20.1
Management:         172.16.30.0/28   - VLAN 50 - Gateway .30.1
```

### Server Principali

```
DNS:        172.16.2.10
DHCP:       172.16.2.11
File:       172.16.2.12
Database:   172.16.2.13
Web (DMZ):  172.16.10.10
Mail (DMZ): 172.16.10.11
```

## 📝 Comandi Rapidi

### Cisco Router
```cisco
enable
show running-config
show ip interface brief
show ip route
show ip nat translations
copy running-config startup-config
```

### Cisco Switch
```cisco
enable
show vlan brief
show interfaces trunk
show spanning-tree
show mac address-table
show port-security
```

### Linux Firewall
```bash
# Visualizza regole
iptables -L -n -v
iptables -t nat -L -n -v

# Salva regole
iptables-save > /etc/iptables/rules.v4

# Ripristina regole
iptables-restore < /etc/iptables/rules.v4
```

### Test Connettività
```bash
# Ping
ping -c 4 172.16.10.10

# DNS
nslookup web.azienda.local 172.16.2.10

# Porta
nc -zv 172.16.10.10 80

# Traceroute
traceroute 8.8.8.8
```

### Servizi
```bash
# Status
systemctl status apache2
systemctl status postfix
systemctl status bind9

# Restart
systemctl restart apache2

# Logs
journalctl -u apache2 -f
tail -f /var/log/apache2/error.log
```

## 🔧 Troubleshooting Veloce

### Problema: Nessuna connettività Internet
```bash
1. ping 172.16.1.1        # Test gateway
2. ping 8.8.8.8           # Test Internet IP
3. ping www.google.com    # Test DNS
4. ip route show          # Verifica route
```

### Problema: DHCP non funziona
```bash
1. systemctl status isc-dhcp-server
2. tail -f /var/log/syslog | grep dhcp
3. dhcp-lease-list
4. Verifica /etc/dhcp/dhcpd.conf
```

### Problema: Web server non raggiungibile
```bash
1. systemctl status apache2
2. netstat -tlnp | grep :80
3. iptables -L -n | grep 80
4. curl http://localhost
5. tail -f /var/log/apache2/error.log
```

## 📋 Checklist Pre-Produzione

- [ ] Piano IP documentato
- [ ] Router configurato e testato
- [ ] Switch configurati con VLAN
- [ ] Firewall con regole testate
- [ ] DNS risolve tutti i nomi
- [ ] DHCP assegna IP correttamente
- [ ] Web server raggiungibile
- [ ] Mail server funzionante
- [ ] VPN testata
- [ ] Backup configurato
- [ ] Monitoring attivo
- [ ] Documentazione completa

## 🚨 Porte Pubbliche Esposte

| Porta | Servizio | Destinazione | Note |
|-------|----------|--------------|------|
| 80    | HTTP     | 172.16.10.10 | Redirect a HTTPS |
| 443   | HTTPS    | 172.16.10.10 | Web sicuro |
| 25    | SMTP     | 172.16.10.11 | Mail in entrata |
| 587   | Submit   | 172.16.10.11 | Mail autenticato |
| 993   | IMAPS    | 172.16.10.11 | Accesso mail |
| 1194  | OpenVPN  | 172.16.10.13 | VPN UDP |

## 🔐 Password Policy

```
Lunghezza minima:      12 caratteri
Complessità:           Maiusc + minusc + numeri + simboli
Scadenza:              90 giorni
Storico:               5 password
Tentativi:             3 prima del blocco
Timeout sessione:      15 minuti
```

## 📞 Contatti Emergenza

```
IT Manager:         +39 XXX XXX XXXX
Network Admin:      +39 XXX XXX XXXX
ISP Support:        +39 XXX XXX XXXX
Vendor Cisco:       https://www.cisco.com/support
```

## 📂 File Importanti

```
Router Config:      /tftp/router-backup.conf
Switch Config:      /tftp/switch-backup.conf
Firewall Rules:     /etc/iptables/rules.v4
Apache Config:      /etc/apache2/sites-available/
DNS Zones:          /etc/bind/
DHCP Config:        /etc/dhcp/dhcpd.conf
VPN Certs:          /etc/openvpn/
```

## 🔄 Comandi Backup Rapido

```bash
# Router (da PC admin)
scp admin@172.16.0.1:running-config router-backup-$(date +%Y%m%d).conf

# Server configs
tar -czf configs-backup-$(date +%Y%m%d).tar.gz /etc/apache2 /etc/postfix /etc/bind

# Database
mysqldump -u root -p --all-databases | gzip > db-backup-$(date +%Y%m%d).sql.gz
```

---

**Quick Reference Guide**  
**Progetto**: A038_STR24  
**Ultimo aggiornamento**: 30 Gennaio 2026
