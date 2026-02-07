# Indice - Guida alle DMZ (Demilitarized Zone)

## Prefazione

## Capitolo 1 - Introduzione alle DMZ
1.1 Cos'è una DMZ
1.2 Perché le DMZ sono necessarie
1.3 Evoluzione storica delle architetture di rete
1.4 Scenari di utilizzo tipici
1.5 Autovalutazione

## Capitolo 2 - Principi di Sicurezza di Rete
2.1 Il modello di difesa a strati (Defense in Depth)
2.2 Principio del minimo privilegio
2.3 Separazione dei compiti e segmentazione
2.4 Zone di fiducia (Trust Zones)
2.5 Best practice di base
2.6 Autovalutazione

## Capitolo 3 - Architetture DMZ
3.1 DMZ a singolo firewall (screened subnet)
3.2 DMZ a doppio firewall (back-to-back)
3.3 DMZ a tre interfacce
3.4 DMZ multiple
3.5 Confronto tra le architetture
3.6 Esempi pratici di design
3.7 Tip and tricks per la scelta dell'architettura
3.8 Autovalutazione

## Capitolo 4 - Componenti della DMZ
4.1 Firewall perimetrali
4.2 Web server e application server
4.3 Mail server (SMTP, POP3, IMAP)
4.4 DNS server
4.5 Proxy e reverse proxy
4.6 Load balancer
4.7 VPN gateway
4.8 IDS/IPS (Intrusion Detection/Prevention Systems)
4.9 Esempi di configurazione
4.10 Autovalutazione

## Capitolo 5 - Regole di Firewall per DMZ
5.1 Principi di configurazione firewall
5.2 Regole in ingresso dalla rete pubblica
5.3 Regole in uscita verso Internet
5.4 Regole tra DMZ e rete interna
5.5 Gestione del traffico ICMP
5.6 Logging e monitoring
5.7 Esempi di ruleset completi
5.8 Best practice e errori comuni
5.9 Esercizi di configurazione
5.10 Autovalutazione

## Capitolo 6 - Protocolli e Servizi in DMZ
6.1 HTTP/HTTPS
6.2 FTP e SFTP
6.3 SSH
6.4 SMTP, POP3, IMAP
6.5 DNS
6.6 NTP
6.7 Gestione certificati SSL/TLS
6.8 Esempi di hardening dei servizi
6.9 Tip and tricks per la sicurezza dei protocolli
6.10 Autovalutazione

## Capitolo 7 - Implementazione Pratica
7.1 Pianificazione della DMZ
7.2 Scelta dell'hardware e del software
7.3 Configurazione passo-passo di una DMZ base
7.4 Configurazione di un web server in DMZ
7.5 Configurazione di un mail server in DMZ
7.6 Implementazione NAT e PAT
7.7 Esempi completi di deployment
7.8 Esercizi guidati
7.9 Autovalutazione

## Capitolo 8 - Hardening e Sicurezza Avanzata
8.1 Hardening dei server in DMZ
8.2 Patch management
8.3 Gestione delle vulnerabilità
8.4 Configurazione di IDS/IPS
8.5 SIEM e log correlation
8.6 Honeypot e deception technology
8.7 Best practice di hardening
8.8 Checklist di sicurezza
8.9 Esercizi pratici
8.10 Autovalutazione

## Capitolo 9 - Monitoraggio e Manutenzione
9.1 Strumenti di monitoring
9.2 Analisi dei log
9.3 Network traffic analysis
9.4 Performance monitoring
9.5 Gestione degli incidenti
9.6 Backup e disaster recovery
9.7 Procedure di manutenzione ordinaria
9.8 Esempi di dashboard e alert
9.9 Tip and tricks per il monitoring efficace
9.10 Autovalutazione

## Capitolo 10 - DMZ in Ambienti Virtualizzati e Cloud
10.1 DMZ in ambienti VMware
10.2 DMZ in Hyper-V
10.3 DMZ in AWS
10.4 DMZ in Azure
10.5 DMZ in Google Cloud Platform
10.6 Software-Defined Networking (SDN) e DMZ
10.7 Micro-segmentazione
10.8 Esempi di architetture cloud
10.9 Best practice per ambienti ibridi
10.10 Esercizi di progettazione cloud
10.11 Autovalutazione

## Capitolo 11 - Conformità e Standard
11.1 PCI-DSS e DMZ
11.2 GDPR e protezione dati
11.3 ISO 27001
11.4 NIST Framework
11.5 CIS Controls
11.6 Best practice di compliance
11.7 Esempi di audit
11.8 Autovalutazione

## Capitolo 12 - Casi Studio e Troubleshooting
12.1 Caso studio: E-commerce
12.2 Caso studio: Banking
12.3 Caso studio: Healthcare
12.4 Caso studio: PA e istituzioni
12.5 Problemi comuni e soluzioni
12.6 Tecniche di troubleshooting
12.7 Esercizi di analisi
12.8 Autovalutazione

## Capitolo 10bis - Container e Microsegmentazione
10bis.1 Container e Sicurezza
10bis.2 Kubernetes e DMZ
10bis.3 Network Policies per Microsegmentazione
10bis.4 Service Mesh e Sicurezza
10bis.5 Microsegmentazione Avanzata
10bis.6 Container Runtime Security
10bis.7 Best Practices per Container DMZ
10bis.8 Esempi Pratici
10bis.9 Monitoring e Observability
10bis.10 Autovalutazione

---

## 📚 Laboratori Pratici
**[Indice Completo dei Laboratori](Laboratori.md)**

### Laboratori con Packet Tracer 🌐
- LAB 1.1-1.3: Architetture DMZ Base
- LAB 2.1-2.3: Servizi in DMZ (Web, Mail, DNS)
- LAB 3.1-3.3: ACL e Firewall Rules
- LAB 4.1-4.2: IDS/IPS e Monitoraggio

### Laboratori con VirtualBox/VMware 💻
- LAB 5.1-5.4: pfSense, Snort IDS, HAProxy, Mail Server

### Laboratori con Docker/Kubernetes 🐳
- LAB 6.1-6.3: Docker Networks, Docker Compose, Security Scanning
- LAB 7.1-7.3: K8s DMZ, Istio Service Mesh, Cilium Policies

### Laboratori Cloud ☁️
- LAB 8.1-8.3: AWS VPC, Azure NSG, GCP Firewall

### Scenari Avanzati 🎯
- LAB 9.1-9.5: Honeypot, WAF, VPN, Zero Trust, Incident Response

### Progetti Finali 🏆
- LAB 10.1-10.2: Enterprise DMZ, Cloud Migration

---

## Appendice A - Glossario dei Termini
## Appendice B - Comandi Utili
## Appendice C - Template di Configurazione
## Appendice D - Checklist di Sicurezza
## Appendice E - Risorse e Riferimenti

## Risposte alle Domande di Autovalutazione

## Bibliografia e Sitografia