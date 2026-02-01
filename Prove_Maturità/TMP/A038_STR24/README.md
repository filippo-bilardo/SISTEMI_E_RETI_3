# Prova d'Esame A038_STR24 - Sistemi e Reti

## 📋 Indice

1. [Descrizione](#descrizione)
2. [Struttura Repository](#struttura-repository)
3. [Contenuti](#contenuti)
4. [Come Utilizzare](#come-utilizzare)
5. [Requisiti](#requisiti)
6. [Riferimenti](#riferimenti)

---

## 📖 Descrizione

Questo repository contiene la **soluzione completa** della prova d'esame **A038_STR24** per la materia **Sistemi e Reti**, classe di concorso A038.

La prova riguarda la progettazione e implementazione di un'infrastruttura di rete aziendale completa, comprensiva di:
- Progettazione architettura di rete
- Piano di indirizzamento IP con subnetting
- Configurazione dispositivi di rete (Router, Switch, Firewall)
- Implementazione servizi (DNS, DHCP, Web, Mail, VPN)
- Sicurezza multi-livello
- Monitoring e troubleshooting
- Backup e disaster recovery

---

## 📁 Struttura Repository

```
A038_STR24/
├── README.md                          # Questo file
├── A038_STR24.pdf                     # Testo originale della prova
├── SOLUZIONE_A038_STR24.md            # Soluzione completa e dettagliata
│
├── configurazioni/                    # File di configurazione dispositivi
│   ├── router-config.txt              # Configurazione Router Cisco
│   ├── switch-config.txt              # Configurazione Switch Cisco
│   ├── dhcp-server.conf               # Configurazione DHCP Server
│   ├── dns-server-config/             # Configurazione BIND9
│   └── web-server-config/             # Configurazione Apache/Nginx
│
├── script/                            # Script di automazione
│   ├── firewall-setup.sh              # Setup completo firewall iptables
│   ├── network-monitor.sh             # Script di monitoring
│   ├── backup-network.sh              # Script di backup
│   └── test-network.sh                # Script di testing
│
├── documentazione/                    # Documentazione tecnica
│   ├── piano-indirizzamento.md        # Piano IP dettagliato
│   ├── architettura-rete.md           # Diagrammi architettura
│   ├── procedure-backup.md            # Procedure di backup
│   └── troubleshooting-guide.md       # Guida troubleshooting
│
└── diagrammi/                         # Diagrammi e schemi
    ├── topology.png                   # Topologia di rete
    ├── ip-schema.png                  # Schema indirizzamento
    └── vlan-diagram.png               # Schema VLAN
```

---

## 📚 Contenuti

### 1. Soluzione Principale
Il file **[SOLUZIONE_A038_STR24.md](SOLUZIONE_A038_STR24.md)** contiene:

- ✅ Analisi completa dei requisiti
- ✅ Progettazione architettura di rete
- ✅ Piano di subnetting e indirizzamento IP
- ✅ Configurazioni complete di tutti i dispositivi
- ✅ Setup dei servizi (DNS, DHCP, Web, Mail, VPN)
- ✅ Implementazione sicurezza (Firewall, ACL, VPN)
- ✅ Script di monitoring e troubleshooting
- ✅ Procedure di backup e disaster recovery
- ✅ Suite di testing completa

### 2. Configurazioni
Nella cartella **[configurazioni/](configurazioni/)** trovi:

- **Router Cisco**: Configurazione completa con NAT, routing, ACL
- **Switch Cisco**: VLAN, trunking, port security, spanning-tree
- **DHCP Server**: Pool, reservation, opzioni
- **DNS Server**: Zone file, record A, MX, CNAME
- **Web Server**: Virtual host, SSL/TLS, hardening
- **Mail Server**: Postfix, Dovecot, anti-spam

### 3. Script di Automazione
Nella cartella **[script/](script/)** trovi:

- **firewall-setup.sh**: Setup completo firewall con iptables
- **network-monitor.sh**: Monitoring automatico della rete
- **backup-network.sh**: Backup automatico configurazioni
- **test-network.sh**: Test di connettività e servizi

### 4. Documentazione
Nella cartella **[documentazione/](documentazione/)** trovi:

- **Piano di Indirizzamento**: Dettaglio completo IP/subnet
- **Architettura**: Diagrammi e spiegazioni
- **Procedure**: Guide operative step-by-step
- **Troubleshooting**: Guida alla risoluzione problemi

---

## 🚀 Come Utilizzare

### Per Studiare
1. Leggi il [testo della prova](A038_STR24.pdf)
2. Studia la [soluzione completa](SOLUZIONE_A038_STR24.md)
3. Analizza le [configurazioni](configurazioni/)
4. Rivedi il [piano di indirizzamento](documentazione/piano-indirizzamento.md)

### Per Implementare
1. Copia le configurazioni dai file nella cartella [configurazioni/](configurazioni/)
2. Adatta gli IP e i parametri al tuo ambiente
3. Esegui gli script di setup dalla cartella [script/](script/)
4. Verifica con gli script di testing

### Per Testare
```bash
# Test connettività
./script/test-network.sh

# Monitoring
./script/network-monitor.sh

# Setup firewall
sudo ./script/firewall-setup.sh
```

---

## 💻 Requisiti

### Hardware (Simulazione)
- Router Cisco (o GNS3/Packet Tracer)
- Switch Cisco Layer 3
- Server Linux (Ubuntu/Debian) per servizi
- Firewall Linux-based o appliance

### Software
- Cisco IOS (Router/Switch)
- Ubuntu Server 20.04+ / Debian 11+
- Apache 2.4+ / Nginx
- BIND9 (DNS)
- ISC DHCP Server
- Postfix + Dovecot (Mail)
- OpenVPN
- iptables

### Competenze
- Networking (TCP/IP, subnetting, routing)
- Configurazione dispositivi Cisco
- Amministrazione Linux
- Sicurezza informatica di base
- Scripting bash

---

## 📖 Riferimenti

### RFC e Standard
- RFC 1918 - Address Allocation for Private Internets
- RFC 2131 - Dynamic Host Configuration Protocol (DHCP)
- RFC 5321 - Simple Mail Transfer Protocol (SMTP)
- RFC 6749 - OAuth 2.0 Authorization Framework

### Documentazione Ufficiale
- [Cisco IOS Documentation](https://www.cisco.com/c/en/us/support/ios-nx-os-software/ios-15-4m-t/products-installation-and-configuration-guides-list.html)
- [BIND9 Documentation](https://bind9.readthedocs.io/)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [Postfix Documentation](http://www.postfix.org/documentation.html)
- [OpenVPN Documentation](https://openvpn.net/community-resources/)

### Guide e Tutorial
- [Cisco Networking Academy](https://www.netacad.com/)
- [Linux Network Administrators Guide](https://tldp.org/LDP/nag2/index.html)
- [OWASP Security Guidelines](https://owasp.org/)

---

## 🔐 Note di Sicurezza

⚠️ **IMPORTANTE**: 
- Questo materiale è fornito **a scopo didattico**
- Le password negli esempi sono **fittizie** e devono essere cambiate
- Non utilizzare queste configurazioni in produzione senza personalizzazione
- Segui sempre le best practice di sicurezza

---

## 📝 Licenza

Questo materiale è fornito per scopi educativi. 

---

## 👨‍💻 Autore

**Soluzione Esame A038_STR24**  
Data: 30 Gennaio 2026  
Versione: 1.0

---

## 📮 Contatti

Per domande o chiarimenti sulla soluzione:
- Consulta la [documentazione completa](SOLUZIONE_A038_STR24.md)
- Rivedi le [configurazioni](configurazioni/)
- Controlla il [piano di indirizzamento](documentazione/piano-indirizzamento.md)

---

## ✅ Checklist Implementazione

Usa questa checklist per verificare l'implementazione:

- [ ] Piano di indirizzamento definito
- [ ] Router configurato (routing, NAT, ACL)
- [ ] Switch configurato (VLAN, trunking, spanning-tree)
- [ ] Firewall configurato (iptables rules)
- [ ] DNS Server operativo
- [ ] DHCP Server operativo
- [ ] Web Server configurato e testato
- [ ] Mail Server configurato (SMTP/IMAP)
- [ ] VPN Server configurato
- [ ] Regole firewall testate
- [ ] Monitoring configurato
- [ ] Backup automatico configurato
- [ ] Test di connettività eseguiti
- [ ] Documentazione completata
- [ ] Disaster recovery testato

---

**Buono studio! 📚🎓**
