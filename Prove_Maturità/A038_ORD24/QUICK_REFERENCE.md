# QUICK REFERENCE GUIDE
## Infrastruttura Rete Sanitaria Regionale FSE

**Versione**: 1.0  
**Data**: 30 Gennaio 2026  
**Per**: Strutture Sanitarie Private Convenzionate

---

## 📋 INDICE

1. [Informazioni Rete](#informazioni-rete)
2. [Comandi Utili](#comandi-utili)
3. [Checklist Pre-Produzione](#checklist-pre-produzione)
4. [Porte e Servizi](#porte-e-servizi)
5. [Credenziali e Accessi](#credenziali-e-accessi)
6. [Contatti Emergenza](#contatti-emergenza)
7. [Troubleshooting Rapido](#troubleshooting-rapido)
8. [File Importanti](#file-importanti)

---

## INFORMAZIONI RETE

### Indirizzamento

| Elemento | Indirizzo | Note |
|----------|-----------|------|
| **Rete Assegnata** | 10.100.0.0/16 | Tutte le strutture private |
| **Subnet per Struttura** | /27 (30 host utilizzabili) | Incremento di 32 |
| **Data-Center FSE** | 10.1.0.0/24 | Hub centrale |
| **Core Router** | 10.1.0.1 | Gateway principale |
| **DNS Primario** | 10.1.0.10 | |
| **DNS Secondario** | 10.1.0.11 | |
| **Server Backup** | 10.1.0.203 | SFTP/TFTP |
| **Server Monitoring** | 10.1.0.202 | Zabbix/SNMP |
| **Server Logging** | 10.1.0.201 | Syslog |

### Esempio Allocazione (Struttura #1)

```
Network:        10.100.0.32/27
Gateway:        10.100.0.33
Range:          10.100.0.34 - 10.100.0.62
Broadcast:      10.100.0.63
LAN Interna:    192.168.1.0/24
```

---

## COMANDI UTILI

### Verifica Connettività

```bash
# Ping data-center
ping -c 4 10.1.0.1

# Ping core router
ping -c 4 10.100.0.1

# Ping DNS
ping -c 4 10.1.0.10

# Traceroute verso FSE
traceroute 10.1.0.10

# Test DNS resolution
nslookup fse.regione.it
dig fse.regione.it @10.1.0.10
```

### Verifica VPN IPsec

```bash
# Cisco IOS
show crypto isakmp sa
show crypto ipsec sa
show crypto session
debug crypto isakmp
debug crypto ipsec

# Linux strongSwan
ipsec status
ipsec statusall
ip xfrm state
ip xfrm policy

# MikroTik
/ip ipsec active-peers print
/ip ipsec installed-sa print
```

### Verifica Routing

```bash
# Mostra tabella routing
ip route show          # Linux
show ip route          # Cisco
route print            # Windows

# Verifica route specifica
ip route get 10.1.0.10 # Linux

# Mostra interfacce
ip addr show           # Linux
show ip interface brief # Cisco
```

### Verifica NAT

```bash
# Cisco
show ip nat translations
show ip nat statistics
clear ip nat translation *

# Linux iptables
iptables -t nat -L -n -v
conntrack -L

# MikroTik
/ip firewall nat print
/ip firewall connection print
```

### Verifica Firewall

```bash
# Cisco ACL
show access-lists
show ip access-lists WAN-IN
show ip access-lists LAN-OUT

# Linux iptables
iptables -L -n -v
iptables -L INPUT -n -v
iptables -L FORWARD -n -v

# MikroTik
/ip firewall filter print
/ip firewall filter print stats
```

### Monitoraggio Banda

```bash
# Interfaccia real-time
iftop -i eth0                    # Linux
nload eth0                       # Linux

# Statistiche interfaccia
show interfaces GigabitEthernet0/0/0 # Cisco
ip -s link show eth0                 # Linux

# NetFlow/sFlow
show ip flow export                  # Cisco
```

### Verifica Servizi

```bash
# DHCP
show ip dhcp binding               # Cisco
cat /var/lib/dhcp/dhcpd.leases    # Linux

# DNS
nslookup fse.regione.it
dig @10.1.0.10 fse.regione.it

# NTP
show ntp status                    # Cisco
ntpq -p                           # Linux

# SNMP
snmpwalk -v2c -c RegioneSNMP localhost
```

### Logging e Debug

```bash
# Visualizza log
show logging                       # Cisco
tail -f /var/log/messages         # Linux
tail -f /var/log/syslog           # Linux

# Filtra log
show logging | include BLOCK      # Cisco
grep "BLOCK" /var/log/syslog      # Linux

# Debug (attenzione in produzione!)
debug ip packet                   # Cisco
tcpdump -i eth0 host 10.1.0.10   # Linux
```

### Configurazione

```bash
# Backup config
copy running-config startup-config           # Cisco
copy running-config tftp://10.1.0.203/backup # Cisco

# Restore config
copy tftp://10.1.0.203/backup running-config # Cisco

# Mostra config
show running-config                          # Cisco
show startup-config                          # Cisco
```

---

## CHECKLIST PRE-PRODUZIONE

### ☑️ Hardware

- [ ] CPE router installato fisicamente
- [ ] Alimentazione ridondante/UPS connesso
- [ ] Cavi di rete connessi correttamente
- [ ] LED interfacce WAN/LAN accesi
- [ ] Ventilazione adeguata

### ☑️ Connettività

- [ ] Fibra ottica WAN connessa e attiva
- [ ] Link WAN UP (verificare LED/status)
- [ ] Ping verso core router (10.100.0.1) OK
- [ ] Ping verso data-center (10.1.0.1) OK
- [ ] DNS resolution funzionante
- [ ] NTP sincronizzato

### ☑️ VPN IPsec

- [ ] Tunnel IPsec stabilito
- [ ] Fase 1 (ISAKMP) UP
- [ ] Fase 2 (ESP) UP
- [ ] Traffico cifrato verificato
- [ ] No errori in log VPN

### ☑️ Sicurezza

- [ ] Firewall ACL applicate
- [ ] Password default cambiate
- [ ] SSH configurato (no Telnet)
- [ ] Accesso SSH limitato a IP autorizzati
- [ ] Logging remoto attivo
- [ ] SNMP community configurata

### ☑️ Servizi

- [ ] NAT funzionante
- [ ] DHCP assegna IP correttamente
- [ ] DNS risolve nomi
- [ ] QoS configurato
- [ ] Backup automatico schedulato

### ☑️ Test Funzionali

- [ ] Accesso portale FSE da workstation
- [ ] Invio prestazione test completato
- [ ] Download documento da FSE completato
- [ ] Test velocità rete soddisfacente (>10 Mbps)
- [ ] Latenza accettabile (<100ms verso DC)

### ☑️ Documentazione

- [ ] Configurazione salvata su backup server
- [ ] Documentazione rete aggiornata
- [ ] Credenziali documentate (in safe)
- [ ] Procedura ripristino disponibile
- [ ] Contatti emergenza comunicati

---

## PORTE E SERVIZI

### Porte TCP/UDP Pubbliche

| Servizio | Porta | Protocollo | Accesso | Note |
|----------|-------|------------|---------|------|
| **HTTPS FSE** | 443 | TCP | Autenticato | Portale FSE e API |
| **SSH Management** | 22 | TCP | IP Autorizzati | Gestione remota CPE |
| **IPsec IKE** | 500 | UDP | VPN | Phase 1 |
| **IPsec NAT-T** | 4500 | UDP | VPN | NAT Traversal |
| **IPsec ESP** | - | Protocol 50 | VPN | Encrypted payload |
| **DNS** | 53 | UDP | Interno | Risoluzione nomi |
| **NTP** | 123 | UDP | Interno | Sincronizzazione orario |
| **SNMP** | 161 | UDP | Monitoring | Solo da 10.1.0.202 |
| **Syslog** | 514 | UDP | Logging | Verso 10.1.0.201 |
| **SFTP** | 22 | TCP | Backup | File grandi |

### Endpoint API FSE

```
Base URL: https://fse.regione.it/api/v1

POST   /auth/token              - Autenticazione OAuth2
POST   /prestazioni             - Invio prestazione
GET    /prestazioni/{id}        - Dettagli prestazione
POST   /files/upload            - Upload file allegato
GET    /files/{id}              - Download file
POST   /files/verify            - Verifica integrità
GET    /health                  - Health check
```

---

## CREDENZIALI E ACCESSI

### ⚠️ POLICY PASSWORD

**Requisiti Minimi**:
- Lunghezza: 12+ caratteri
- Complessità: Maiuscole, minuscole, numeri, simboli
- Scadenza: 90 giorni
- Storia: Ultimi 5 non riutilizzabili
- Tentativi: Max 3 errati → blocco 15 minuti

**Password Vietate**:
- Password banali (password123, admin, etc.)
- Dati personali (nome, cognome, date nascita)
- Parole da dizionario

### Gestione Chiavi SSH

```bash
# Generazione chiave per SFTP
ssh-keygen -t rsa -b 4096 -f ~/.ssh/fse_rsa -C "struttura@fse"

# Permessi corretti
chmod 700 ~/.ssh
chmod 600 ~/.ssh/fse_rsa
chmod 644 ~/.ssh/fse_rsa.pub

# Test connessione
ssh -i ~/.ssh/fse_rsa user@sftp.fse.regione.it
```

### Multi-Factor Authentication (MFA)

**Per accesso Portale FSE web**:
- Factor 1: SPID/CIE + Password
- Factor 2: OTP (SMS o Authenticator App)
- Factor 3: Biometria (opzionale)

**Configurazione Authenticator App**:
1. Scarica Google Authenticator / Microsoft Authenticator
2. Scansiona QR Code da portale FSE
3. Inserisci codice a 6 cifre per conferma
4. Backup recovery codes (stampa e custodisci)

---

## CONTATTI EMERGENZA

### 🚨 Centro Operativo Rete (NOC)

**Telefono**: +39 XXX XXXXXXX  
**Disponibilità**: 24/7/365  
**Email**: noc@regione-fibra.it

### Livelli di Escalation

**Livello 1 - Help Desk** (Primo Contatto):
- Telefono: +39 XXX XXXXXXX
- Email: support@regione-fibra.it
- Ticket: https://helpdesk.regione-fibra.it
- Orario: Lun-Ven 8:00-20:00, Sab 9:00-13:00

**Livello 2 - Supporto Tecnico**:
- Email: techsupport@regione-fibra.it
- Telefono: +39 YYY YYYYYYY
- Disponibilità: 24/7

**Livello 3 - Emergenze Critiche**:
- Telefono: +39 ZZZ ZZZZZZZ (Reperibilità H24)
- Solo per: Data breach, interruzione totale servizio, disaster

### Matrice Escalation

| Severità | Descrizione | Tempo Risposta | Contatto |
|----------|-------------|----------------|----------|
| **P1 - Critica** | Servizio completamente down | 15 minuti | NOC 24/7 |
| **P2 - Alta** | Servizio degradato, impatto significativo | 1 ora | Support L2 |
| **P3 - Media** | Problema localizzato, workaround disponibile | 4 ore | Support L1 |
| **P4 - Bassa** | Richiesta informazioni, piccoli bug | 1 giorno | Help Desk |

### Informazioni da Fornire in Caso di Ticket

```
1. ID Struttura: _______
2. Nome Struttura: _______
3. Descrizione Problema: _______
4. Quando è iniziato: _______
5. Impatto: [ ] Totale [ ] Parziale [ ] Minimo
6. Utenti Impattati: _______
7. Cosa hai già provato: _______
8. Log/Screenshot: [Allega]
```

### Status Page

**URL**: https://status.regione-fibra.it

Monitora in tempo reale:
- Stato servizi (FSE, VPN, DNS, etc.)
- Manutenzioni programmate
- Incident history

---

## TROUBLESHOOTING RAPIDO

### ❌ Problema: Nessuna Connettività

**Sintomo**: Impossibile pingare data-center

```bash
# 1. Verifica link fisico
show interfaces status            # LED accesi?

# 2. Verifica IP address
show ip interface brief           # IP configurato?

# 3. Verifica routing
show ip route                     # Default route presente?
ping 10.100.0.1                   # Gateway raggiungibile?

# 4. Verifica firewall
show access-lists                 # Traffico bloccato?

# 5. Contatta NOC se tutto OK sopra
```

### ❌ Problema: VPN IPsec Non Attiva

**Sintomo**: Tunnel VPN down

```bash
# 1. Verifica status
show crypto isakmp sa             # Phase 1 UP?
show crypto ipsec sa              # Phase 2 UP?

# 2. Verifica raggiungibilità peer
ping 10.1.0.1                     # Peer raggiungibile?

# 3. Verifica configurazione
show crypto isakmp policy         # Config corretta?
show crypto map                   # Crypto map applicata?

# 4. Verifica orario (NTP)
show clock                        # Orario sincronizzato?
show ntp status                   # NTP funzionante?

# 5. Check firewall
show access-lists WAN-IN          # UDP 500/4500 permesso?

# 6. Riavvia tunnel
clear crypto sa                   # Reset tunnel
clear crypto isakmp               # Reset IKE
```

### ❌ Problema: Accesso FSE Lento

**Sintomo**: Portale FSE carica lentamente

```bash
# 1. Verifica banda disponibile
show interfaces GigabitEthernet0/0/0 | include rate
iftop -i eth0                     # (Linux)

# 2. Verifica latenza
ping -c 10 10.1.0.10              # RTT accettabile (<100ms)?

# 3. Verifica QoS
show policy-map interface Gi0/0/0 # Traffico prioritizzato?

# 4. Verifica congestione
show interfaces | include drops   # Packet drops?

# 5. Traceroute
traceroute 10.1.0.10              # Hop anomali?

# 6. Apri ticket con dati latenza
```

### ❌ Problema: DHCP Non Funziona

**Sintomo**: Client non ottengono IP

```bash
# 1. Verifica DHCP server attivo
show ip dhcp pool                 # Pool configurato?
show ip dhcp binding              # Lease attivi?

# 2. Verifica esaurimento pool
show ip dhcp pool | include Available # IP disponibili?

# 3. Verifica conflitti
show ip dhcp conflict

# 4. Clear e restart
clear ip dhcp binding *
clear ip dhcp conflict *

# 5. Verifica interfaccia
show ip interface GigabitEthernet0/0/1 # Interface UP?
```

### ❌ Problema: DNS Non Risolve

**Sintomo**: nslookup fallisce

```bash
# 1. Verifica DNS server configurati
show running-config | include name-server

# 2. Test DNS manuale
nslookup fse.regione.it 10.1.0.10
dig @10.1.0.10 fse.regione.it

# 3. Verifica raggiungibilità DNS
ping 10.1.0.10                    # DNS server raggiungibile?

# 4. Verifica firewall
show access-lists LAN-OUT | include 53 # UDP 53 permesso?

# 5. Usa DNS alternativo temporaneamente
ip name-server 10.1.0.11          # Secondary DNS
```

### 🆘 Quando Contattare NOC

Contattare **immediatamente** il NOC per:

- ❗ Servizio FSE completamente inaccessibile da >30 minuti
- ❗ VPN down e non ripristinabile
- ❗ Sospetto data breach / accesso non autorizzato
- ❗ Errori critici nei log (crash, panic, etc.)
- ❗ Disastro hardware (fumo, incendio, allagamento)
- ❗ Perdita massiva di dati

---

## FILE IMPORTANTI

### Configurazioni

```
/etc/network/interfaces           # Config rete (Linux)
/etc/ipsec.conf                   # Config IPsec (strongSwan)
/etc/ipsec.secrets                # Pre-shared keys
~/.ssh/fse_rsa                    # Chiave SSH privata
/etc/dhcp/dhcpd.conf              # Config DHCP server
```

### Log Files

```
/var/log/syslog                   # Log sistema generale
/var/log/auth.log                 # Log autenticazione
/var/log/fse/                     # Log applicazione FSE
/var/log/fse/success.log          # Trasferimenti OK
/var/log/fse/errors.log           # Trasferimenti falliti
```

### Backup

```
/opt/fse/backups/                 # Backup locali
/opt/fse/archive/                 # Dati archiviati
tftp://10.1.0.203/backups/        # Backup remoti
```

### Script

```
/opt/fse/scripts/transfer_data.sh     # Trasferimento dati
/opt/fse/scripts/backup_db.sh         # Backup database
/etc/cron.d/fse                       # Schedulazione cron
```

### Documentazione Locale

```
/opt/fse/docs/README.md               # Documentazione principale
/opt/fse/docs/network_diagram.png     # Diagramma rete
/opt/fse/docs/config_cpe.txt          # Config CPE
/opt/fse/docs/quick_reference.pdf     # Questo documento
```

---

## 📚 RIFERIMENTI AGGIUNTIVI

### Documentazione Ufficiale

- **Manuale CPE Router**: [Link to vendor docs]
- **API FSE Reference**: https://docs.fse.regione.it/api/v1
- **Knowledge Base**: https://kb.regione-fibra.it
- **Video Tutorial**: https://training.regione-fibra.it

### Normative

- **GDPR**: Regolamento UE 2016/679
- **Codice Privacy**: D.Lgs. 196/2003
- **Linee Guida AgID FSE**: [Link]
- **ISO 27001**: Security Management

### Tools Consigliati

- **Monitoring**: Zabbix Agent, SNMP
- **Backup**: rsync, pg_dump
- **Network**: Wireshark, tcpdump, nmap
- **Security**: fail2ban, ClamAV

---

## 📝 CHANGELOG

| Versione | Data | Modifiche |
|----------|------|-----------|
| 1.0 | 2024-01-30 | Versione iniziale |

---

## 📄 NOTE FINALI

**Questo documento deve essere**:
- ✅ Stampato e tenuto fisicamente nel locale tecnico
- ✅ Salvato in formato digitale su server locale
- ✅ Condiviso con tutto il personale tecnico
- ✅ Aggiornato ad ogni modifica configurazione
- ✅ Revisionato almeno ogni 6 mesi

**In caso di dubbi**, contattare sempre il supporto tecnico.

**Non eseguire modifiche non documentate senza approvazione**.

---

**Fine Quick Reference Guide**
