# Appendice D - Checklist di Sicurezza

## Pre-Deployment Checklist

### Design e Pianificazione
- [ ] Architettura DMZ definita e documentata
- [ ] Diagramma di rete completo e aggiornato
- [ ] Flussi di traffico identificati e documentati
- [ ] Matrice di comunicazione definita (chi→chi, quale porta)
- [ ] Risk assessment completato
- [ ] Budget approvato
- [ ] Change management process seguito
- [ ] Rollback plan definito

### Hardware e Infrastruttura
- [ ] Firewall dimensionati correttamente (throughput, connessioni)
- [ ] Ridondanza firewall implementata (HA)
- [ ] Switch VLAN-capable configurati
- [ ] Cablaggio di rete verificato e etichettato
- [ ] Power supply ridondante (UPS)
- [ ] Ambiente datacenter adeguato (temperatura, umidità)

### Configurazione Firewall

#### Policy Base
- [ ] Default deny policy implementata su tutte le chain
- [ ] Logging configurato per regole critiche
- [ ] Rate limiting implementato per protezione DDoS
- [ ] Anti-spoofing rules configurate
- [ ] Regole ordinate correttamente (specific → general)

#### Regole IN (Internet → DMZ)
- [ ] Solo porte necessarie aperte
- [ ] IP sorgente limitato quando possibile
- [ ] Geographic blocking implementato se applicabile
- [ ] Connection tracking abilitato (stateful)

#### Regole OUT (DMZ → Internet)
- [ ] Solo aggiornamenti e servizi necessari permessi
- [ ] Destinazioni limitate quando possibile
- [ ] DNS permesso solo verso server fidati
- [ ] NTP configurato e permesso

#### Regole DMZ ↔ LAN
- [ ] Traffico da DMZ a LAN **estremamente limitato**
- [ ] Solo connessioni DB specifiche permesse (IP + porta)
- [ ] Connessioni admin da LAN a DMZ controllate (solo da admin host)
- [ ] Nessuna connessione diretta DMZ → LAN workstation

#### NAT/PAT
- [ ] DNAT configurato per servizi pubblici
- [ ] SNAT/Masquerading per traffico uscente DMZ
- [ ] Port forwarding verificato
- [ ] NAT logging abilitato

## Server Hardening Checklist

### Sistema Operativo Base

#### Account e Autenticazione
- [ ] Root login diretto disabilitato (SSH)
- [ ] Account non necessari rimossi
- [ ] Password policy forte implementata
- [ ] Sudo configurato per amministratori
- [ ] Account di servizio con privilegi minimi
- [ ] MFA implementato dove possibile

#### Servizi e Demoni
- [ ] Solo servizi necessari in esecuzione
- [ ] Servizi non utilizzati disabilitati
- [ ] Boot services verificati (systemctl list-unit-files)
- [ ] Ogni servizio eseguito con utente non privilegiato

#### Filesystem e Permessi
- [ ] Permessi filesystem verificati (644 file, 755 directory)
- [ ] SUID/SGID bit verificati e documentati
- [ ] /tmp montato con noexec,nosuid,nodev
- [ ] Separate partition per /var, /tmp, /home
- [ ] Disk quotas configurate

#### Patch e Aggiornamenti
- [ ] Sistema operativo aggiornato all'ultima versione sicura
- [ ] Security patches applicati
- [ ] Processo di patch management definito
- [ ] Automatic security updates configurati (se appropriato)
- [ ] Repositori ufficiali verificati

#### Logging e Auditing
- [ ] rsyslog o syslog-ng configurato
- [ ] Log forwarding a server centralizzato
- [ ] Log rotation configurato
- [ ] auditd configurato per audit filesystem
- [ ] Log retention policy implementata

### Web Server Hardening

#### Apache
- [ ] Versione nascosta (ServerTokens Prod, ServerSignature Off)
- [ ] Directory listing disabilitato
- [ ] .htaccess access controllato
- [ ] Moduli non necessari disabilitati
- [ ] Timeout configurati appropriatamente
- [ ] Limiti richieste configurati (MaxClients, etc.)
- [ ] Security headers configurati (X-Frame-Options, CSP, etc.)
- [ ] SSL/TLS configurato correttamente

#### Nginx
- [ ] server_tokens off
- [ ] client_max_body_size limitato
- [ ] Timeout configurati
- [ ] Rate limiting configurato (limit_req)
- [ ] Security headers aggiunti
- [ ] SSL/TLS configurato correttamente
- [ ] Separate user/group (www-data)

### SSL/TLS Checklist

#### Certificati
- [ ] Certificati da CA fidato installati
- [ ] Chain completa di certificati configurata
- [ ] Certificati con scadenza > 30 giorni
- [ ] Monitoring scadenza certificati configurato
- [ ] Procedura rinnovo automatico configurata (se Let's Encrypt)
- [ ] Certificati wildcard evitati quando possibile

#### Configurazione TLS
- [ ] Solo TLS 1.2 e TLS 1.3 abilitati
- [ ] SSLv2, SSLv3, TLS 1.0, TLS 1.1 disabilitati
- [ ] Cipher suite sicure configurate
- [ ] Perfect Forward Secrecy abilitato (ECDHE)
- [ ] HSTS header configurato
- [ ] OCSP Stapling abilitato
- [ ] Session resumption configurato
- [ ] Test SSL Labs rating A o A+

### Mail Server Hardening

#### SMTP
- [ ] Open relay disabilitato
- [ ] SASL authentication configurato
- [ ] TLS obbligatorio per submission (port 587)
- [ ] Rate limiting implementato
- [ ] Blacklist RBL configurate
- [ ] SPF, DKIM, DMARC configurati
- [ ] Antispam/antivirus integrati

#### IMAP/POP3
- [ ] Solo connessioni SSL/TLS (993, 995)
- [ ] Porte non sicure (143, 110) disabilitate
- [ ] Login rate limiting
- [ ] Connessioni per IP limitate

### Database Hardening (se in DMZ - sconsigliato!)

- [ ] Binding solo su IP interno (non 0.0.0.0)
- [ ] Root access disabilitato da remoto
- [ ] Account applicazione con privilegi minimi
- [ ] Default accounts rimossi
- [ ] SSL/TLS per connessioni remote
- [ ] Query logging abilitato
- [ ] Backup regolari testati

### SSH Hardening

- [ ] PermitRootLogin no
- [ ] PasswordAuthentication no (solo key-based)
- [ ] Protocol 2
- [ ] AllowUsers o AllowGroups configurato
- [ ] Port personalizzata (optional)
- [ ] MaxAuthTries limitato (2-3)
- [ ] ClientAliveInterval configurato
- [ ] X11Forwarding no
- [ ] Ciphers, MACs, KexAlgorithms moderni
- [ ] fail2ban configurato

## Network Monitoring Checklist

### Monitoring Attivo
- [ ] Uptime monitoring servizi critici
- [ ] Synthetic transactions configurate
- [ ] Alert configurati per downtime
- [ ] Dashboard pubblico per status page (optional)

### Monitoring Passivo
- [ ] Bandwidth monitoring
- [ ] Connection tracking
- [ ] Packet loss monitoring
- [ ] Latency monitoring

### Log Monitoring
- [ ] SIEM o log aggregation configurato
- [ ] Alert per eventi critici
- [ ] Correlation rules configurate
- [ ] Dashboard per visualizzazione log
- [ ] Retention policy implementata

### IDS/IPS
- [ ] IDS/IPS deployato e configurato
- [ ] Signature database aggiornato
- [ ] Alert configurati
- [ ] False positive tuning eseguito
- [ ] Regular review delle detection

## Compliance Checklist

### PCI-DSS (se applicabile)
- [ ] Segmentazione rete implementata
- [ ] Firewall tra cardholder data environment e altre reti
- [ ] Default account/password cambiati
- [ ] Accesso cardholder data limitato a "need to know"
- [ ] Unique ID per ogni utente
- [ ] Physical access to data controllato
- [ ] Network access controllato
- [ ] Data encryption in transit e at rest
- [ ] Antivirus deployato e aggiornato
- [ ] Secure development practices
- [ ] Vulnerability scans regolari
- [ ] Penetration test annuali
- [ ] Security policy documentata
- [ ] Security awareness training

### GDPR (se applicabile)
- [ ] Data inventory completato
- [ ] Legal basis per processing definito
- [ ] Privacy by design implementato
- [ ] Data minimization applicato
- [ ] Encryption dati personali
- [ ] Access control per dati personali
- [ ] Audit trail per accessi
- [ ] Data breach notification procedure
- [ ] Privacy policy pubblicata
- [ ] Consent management (se necessario)
- [ ] Right to deletion implementato
- [ ] Data portability implementato
- [ ] DPO nominato (se richiesto)

## Backup e Disaster Recovery

### Backup
- [ ] Backup schedule definito e seguito
- [ ] Backup automatici configurati
- [ ] Multiple backup locations (onsite + offsite/cloud)
- [ ] Backup encryption abilitato
- [ ] Backup verification regolare
- [ ] Restore test eseguiti periodicamente
- [ ] Retention policy documentata e applicata
- [ ] Backup configuration files firewall/server

### Disaster Recovery
- [ ] DR plan documentato
- [ ] RTO e RPO definiti
- [ ] Hot spare hardware disponibile (se applicabile)
- [ ] Runbook per recovery procedure
- [ ] DR test eseguiti annualmente
- [ ] Emergency contact list aggiornata
- [ ] Alternate site identificato (se necessario)

## Operational Checklist

### Documentazione
- [ ] Network diagram aggiornato
- [ ] Firewall rules documentate con motivazioni
- [ ] Server configurations documentate
- [ ] Change log mantenuto
- [ ] Incident response plan documentato
- [ ] Escalation procedures documentate
- [ ] Knowledge base aggiornata

### Procedure
- [ ] Change management process definito
- [ ] Release management process definito
- [ ] Incident response process definito
- [ ] Problem management process definito
- [ ] Access request/approval process definito

### Training
- [ ] Staff IT formato su configurazione DMZ
- [ ] Security awareness training eseguito
- [ ] Incident response training eseguito
- [ ] Tabletop exercises eseguiti

## Regular Maintenance Checklist

### Giornaliero
- [ ] Review log critici
- [ ] Check monitoring alerts
- [ ] Verify backup completion

### Settimanale
- [ ] Review security alerts
- [ ] Check disk space
- [ ] Review performance metrics
- [ ] Update security signatures (IDS/IPS, AV)

### Mensile
- [ ] Review firewall rules per obsolescenza
- [ ] Patch non-critici
- [ ] Review user accounts
- [ ] Review ACLs
- [ ] Vulnerability scan

### Trimestrale
- [ ] Audit completo firewall rules
- [ ] Review security policies
- [ ] Test backup restore
- [ ] Review incident log
- [ ] Security awareness training refresh

### Annuale
- [ ] Penetration testing
- [ ] Disaster Recovery drill completo
- [ ] Audit di compliance completo
- [ ] Architecture review
- [ ] Risk assessment update
- [ ] Security policy review e update

## Pre-Go-Live Final Checklist

### Testing
- [ ] Connectivity testing completato
- [ ] Load testing eseguito
- [ ] Security testing completato
- [ ] Penetration test eseguito
- [ ] User acceptance testing passato
- [ ] Failover testing completato

### Documentation
- [ ] As-built documentation completa
- [ ] Runbooks finali pronti
- [ ] Contact list aggiornata
- [ ] SLA documentati
- [ ] Known issues documentati

### Training
- [ ] Operations team formato
- [ ] Support team formato
- [ ] Users informati di cambiamenti

### Approvals
- [ ] Security team sign-off
- [ ] IT management sign-off
- [ ] Project stakeholder sign-off
- [ ] Compliance team sign-off (se applicabile)

### Go-Live
- [ ] Maintenance window schedulata
- [ ] Communication plan eseguito
- [ ] Rollback plan ready
- [ ] War room configurata
- [ ] Monitoring intensificato per 24-48h post go-live

---

*Questa checklist dovrebbe essere adattata alle specifiche esigenze della tua organizzazione e ambiente*
