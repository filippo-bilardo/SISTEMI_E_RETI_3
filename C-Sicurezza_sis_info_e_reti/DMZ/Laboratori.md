# Indice Laboratori - Guida DMZ

## Introduzione

Questa sezione presenta una raccolta completa di esercitazioni pratiche per apprendere la progettazione, implementazione e gestione delle DMZ. I laboratori sono organizzati per difficoltà crescente e coprono diversi ambienti:

- **🌐 Packet Tracer**: Simulazioni di rete ideali per comprendere i concetti base
- **💻 VirtualBox/VMware**: Implementazioni realistiche con macchine virtuali
- **🐳 Docker/Kubernetes**: Laboratori su container e microsegmentazione
- **🔧 GNS3**: Simulazioni avanzate con appliance virtuali
- **⚙️ Hardware Reale**: Progetti avanzati su dispositivi fisici

---

## LAB 1 - Architetture DMZ Base (Packet Tracer)

### LAB 1.1 - DMZ con Singolo Firewall
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐ Base  
**Durata:** 2 ore  
**Capitoli correlati:** 1, 3

**Obiettivi:**
- Comprendere la topologia a tre zone (Internet - DMZ - LAN)
- Configurare un router come firewall con ACL
- Implementare NAT/PAT
- Testare la connettività

**Topologia:**
```
Internet --- [Router/Firewall] --- DMZ (Web Server)
                    |
                  [Switch]
                    |
                 LAN Interna
```

**Attività:**
1. Creare la topologia con 1 router, 2 switch, 1 web server in DMZ, 3 PC in LAN
2. Configurare interfacce e VLAN
3. Implementare ACL per:
   - Permettere HTTP/HTTPS da Internet verso Web Server
   - Bloccare traffico diretto da Internet verso LAN
   - Permettere LAN verso Internet
4. Configurare NAT overload (PAT)
5. Testare con ping e browser

**File Packet Tracer:** `lab1.1-dmz-singolo-firewall.pkt`

---

### LAB 1.2 - DMZ a Doppio Firewall (Back-to-Back)
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 3 ore  
**Capitoli correlati:** 3, 5

**Obiettivi:**
- Implementare architettura a doppio firewall
- Configurare regole su firewall perimetrale ed interno
- Applicare il principio di defense in depth

**Topologia:**
```
Internet --- [FW Esterno] --- DMZ --- [FW Interno] --- LAN
```

**Attività:**
1. Implementare 2 router (ASA o router con ACL) come firewall
2. Web Server e Mail Server in DMZ
3. Configurare FW Esterno:
   - Permettere HTTP/HTTPS verso Web Server
   - Permettere SMTP/POP3 verso Mail Server
   - Bloccare tutto il resto verso DMZ e LAN
4. Configurare FW Interno:
   - Permettere LAN verso Internet (con NAT)
   - Permettere LAN verso specifici servizi DMZ
   - Bloccare DMZ verso LAN
5. Test di connettività e sicurezza

**File Packet Tracer:** `lab1.2-dmz-doppio-firewall.pkt`

---

### LAB 1.3 - DMZ a Tre Interfacce
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2.5 ore  
**Capitoli correlati:** 3, 5

**Obiettivi:**
- Configurare firewall con tre interfacce (Outside, DMZ, Inside)
- Implementare security levels
- Ottimizzare il routing

**Topologia:**
```
                  [ASA Firewall]
                 /      |      \
            Outside    DMZ   Inside
               |        |       |
           Internet  Servers   LAN
```

**Attività:**
1. Configurare Cisco ASA con tre interfacce
2. Assegnare security levels (Outside=0, DMZ=50, Inside=100)
3. Configurare ACL e inspection
4. Implementare NAT per ogni zona
5. Deployare Web Server, Mail Server, DNS in DMZ
6. Test completi di sicurezza e funzionalità

**File Packet Tracer:** `lab1.3-dmz-tre-interfacce.pkt`

---

## LAB 2 - Servizi in DMZ (Packet Tracer)

### LAB 2.1 - Web Server in DMZ con HTTPS
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 4, 6

**Obiettivi:**
- Configurare web server HTTP/HTTPS
- Implementare port forwarding
- Testare accesso da Internet e LAN

**Attività:**
1. Setup web server in DMZ con pagina HTML personalizzata
2. Configurare HTTP (porta 80) e HTTPS (porta 443)
3. Implementare port forwarding su firewall
4. Configurare DNS interno per risoluzione nome
5. Test da client Internet e LAN

**File Packet Tracer:** `lab2.1-web-server-dmz.pkt`

---

### LAB 2.2 - Mail Server in DMZ
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2.5 ore  
**Capitoli correlati:** 4, 6

**Obiettivi:**
- Configurare mail server SMTP/POP3
- Implementare relay e filtraggio
- Configurare client email

**Attività:**
1. Installare mail server in DMZ
2. Configurare SMTP (porta 25) per ricezione da Internet
3. Configurare POP3 (porta 110) per accesso da LAN
4. Implementare ACL appropriate su firewall
5. Configurare client email e testare invio/ricezione

**File Packet Tracer:** `lab2.2-mail-server-dmz.pkt`

---

### LAB 2.3 - DNS Server Pubblico e Privato
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 4, 6

**Obiettivi:**
- Implementare split-brain DNS
- Configurare zone pubbliche e private
- Gestire forwarding e caching

**Topologia:**
```
Internet --- FW --- [DNS Pubblico (DMZ)] --- FW --- [DNS Privato (LAN)]
```

**Attività:**
1. DNS pubblico in DMZ con zone esterne
2. DNS privato in LAN con zone interne
3. Configurare forwarding condizionale
4. Implementare DNS views (split-brain)
5. Test di risoluzione da Internet e LAN

**File Packet Tracer:** `lab2.3-dns-split-brain.pkt`

---

## LAB 3 - ACL e Firewall Rules (Packet Tracer)

### LAB 3.1 - ACL Standard e Extended per DMZ
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 5

**Obiettivi:**
- Creare ACL standard per controllo base
- Implementare ACL extended per controllo granulare
- Applicare ACL alle interfacce corrette

**Scenari da implementare:**
1. Permettere HTTP/HTTPS da Internet verso Web Server DMZ
2. Permettere SSH solo da rete amministrazione verso DMZ
3. Bloccare ICMP da Internet
4. Permettere DNS queries da LAN verso DNS DMZ
5. Bloccare tutto il traffico non esplicitamente permesso

**File Packet Tracer:** `lab3.1-acl-dmz.pkt`

---

### LAB 3.2 - Stateful Inspection con Zone-Based Firewall
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 5, 8

**Obiettivi:**
- Configurare Zone-Based Policy Firewall (ZBPF)
- Implementare stateful inspection
- Creare policy maps per traffico

**Attività:**
1. Definire security zones (OUTSIDE, DMZ, INSIDE)
2. Creare class-maps per classificare traffico
3. Creare policy-maps con azioni (inspect, pass, drop)
4. Applicare zone-pairs
5. Test e troubleshooting

**File Packet Tracer:** `lab3.2-zbpf-dmz.pkt`

---

### LAB 3.3 - Ruleset Completo per Architettura Enterprise
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 4 ore  
**Capitoli correlati:** 5, 7

**Obiettivi:**
- Progettare ruleset completo per enterprise
- Implementare logging e monitoring
- Documentare le policy

**Topologia Enterprise:**
```
Internet --- FW1 --- DMZ1 (Web, Mail)
              |
            DMZ2 (DNS, Proxy)
              |
             FW2 --- LAN (multiple VLAN)
```

**File Packet Tracer:** `lab3.3-enterprise-ruleset.pkt`

---

## LAB 4 - IDS/IPS e Monitoraggio (Simulazione con Packet Tracer + VM)

### LAB 4.1 - Simulazione IDS con Syslog
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 8, 9

**Obiettivi:**
- Configurare logging su firewall e router
- Implementare syslog server
- Analizzare log di sicurezza

**Attività:**
1. Configurare syslog su tutti i dispositivi di rete
2. Setup syslog server in LAN
3. Generare eventi di sicurezza (tentativi di accesso negati)
4. Analizzare log e identificare pattern
5. Creare report di sicurezza

**File Packet Tracer:** `lab4.1-syslog-monitoring.pkt`

---

### LAB 4.2 - SNMP Monitoring della DMZ
**Piattaforma:** 🌐 Packet Tracer  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 9

**Obiettivi:**
- Configurare SNMP su dispositivi DMZ
- Implementare monitoring centralizzato
- Creare threshold e alert

**Attività:**
1. Abilitare SNMPv2c su router, switch, server
2. Configurare SNMP manager
3. Monitorare CPU, memoria, bandwidth
4. Configurare trap SNMP
5. Test con simulazione carico

**File Packet Tracer:** `lab4.2-snmp-monitoring.pkt`

---

## LAB 5 - DMZ con VirtualBox/VMware

### LAB 5.1 - DMZ con pfSense Firewall
**Piattaforma:** 💻 VirtualBox/VMware  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 4 ore  
**Capitoli correlati:** 3, 5, 7

**Obiettivi:**
- Installare e configurare pfSense
- Creare architettura DMZ realistica
- Implementare regole firewall avanzate

**Requisiti:**
- VirtualBox o VMware
- VM pfSense
- VM Kali Linux (simula Internet)
- VM Ubuntu Server (Web Server DMZ)
- VM Ubuntu Desktop (LAN Client)

**Topologia VM:**
```
[Kali Linux] --- (NAT Network) --- [pfSense]
                                      |
                             +--------+--------+
                             |                 |
                         [DMZ Net]        [LAN Net]
                             |                 |
                      [Ubuntu Server]   [Ubuntu Desktop]
```

**Attività:**
1. Installare pfSense con tre interfacce
2. Configurare WAN, DMZ, LAN
3. Setup Ubuntu Server come Web + SSH
4. Implementare regole firewall via WebGUI
5. Configurare NAT e port forwarding
6. Test di penetration testing da Kali

**Documentazione:** `lab5.1-pfsense-dmz-guide.pdf`

---

### LAB 5.2 - DMZ con IDS Snort
**Piattaforma:** 💻 VirtualBox/VMware  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 5 ore  
**Capitoli correlati:** 8, 9

**Obiettivi:**
- Installare Snort IDS
- Creare regole personalizzate
- Integrare con SIEM

**Attività:**
1. Installare Snort su VM in modalità IDS
2. Configurare monitoring interface (DMZ)
3. Creare regole custom per rilevare:
   - Port scanning
   - SQL injection attempts
   - Brute force SSH
4. Integrare con ELK Stack per visualizzazione
5. Simulare attacchi e analizzare alert

**Documentazione:** `lab5.2-snort-ids-setup.pdf`

---

### LAB 5.3 - Load Balancer HAProxy in DMZ
**Piattaforma:** 💻 VirtualBox/VMware  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 4, 7

**Obiettivi:**
- Configurare HAProxy come load balancer
- Implementare SSL termination
- Configurare health checks

**Topologia:**
```
Internet --- FW --- [HAProxy] --- [Web1]
                                   [Web2]
                                   [Web3]
```

**Attività:**
1. Setup 3 web server con contenuti distinti
2. Installare HAProxy in DMZ
3. Configurare backend pool
4. Implementare round-robin e least-connections
5. Configurare SSL/TLS termination
6. Test failover e load distribution

**Documentazione:** `lab5.3-haproxy-loadbalancer.pdf`

---

### LAB 5.4 - Mail Server Completo (Postfix + Dovecot)
**Piattaforma:** 💻 VirtualBox/VMware  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 6 ore  
**Capitoli correlati:** 4, 6, 8

**Obiettivi:**
- Configurare mail server enterprise in DMZ
- Implementare SPF, DKIM, DMARC
- Configurare anti-spam e anti-virus

**Attività:**
1. Installare Postfix (SMTP) e Dovecot (IMAP/POP3)
2. Configurare relay e virtual domains
3. Implementare TLS per SMTP e IMAP
4. Configurare SpamAssassin e ClamAV
5. Setup SPF, DKIM, DMARC records
6. Test invio/ricezione con client Thunderbird

**Documentazione:** `lab5.4-mail-server-enterprise.pdf`

---

## LAB 6 - Container DMZ con Docker

### LAB 6.1 - Docker Network DMZ
**Piattaforma:** 🐳 Docker  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Creare network DMZ con Docker
- Implementare isolamento tra container
- Configurare port mapping

**Attività:**
```bash
# Creare network DMZ e LAN
docker network create --driver bridge dmz_net
docker network create --driver bridge lan_net

# Container web in DMZ
docker run -d --name web --network dmz_net \
  -p 80:80 nginx:alpine

# Container app in LAN
docker run -d --name app --network lan_net \
  my-app:latest

# Firewall container (permette web->app)
docker run -d --name firewall \
  --network dmz_net --network lan_net \
  iptables-router:latest
```

**Documentazione:** `lab6.1-docker-dmz-networks.md`

---

### LAB 6.2 - Multi-tier Web App con Docker Compose
**Piattaforma:** 🐳 Docker Compose  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Deployare app multi-tier
- Implementare network isolation
- Configurare secrets e environment

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  # DMZ Zone
  nginx:
    image: nginx:alpine
    networks:
      - dmz
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api

  # Internal Zone
  api:
    build: ./api
    networks:
      - dmz
      - internal
    environment:
      DB_HOST: postgres
    secrets:
      - db_password

  # Data Zone
  postgres:
    image: postgres:14
    networks:
      - data
    secrets:
      - db_password
    volumes:
      - pgdata:/var/lib/postgresql/data

networks:
  dmz:
  internal:
  data:
    internal: true  # No external access

secrets:
  db_password:
    file: ./secrets/db_password.txt

volumes:
  pgdata:
```

**Documentazione:** `lab6.2-docker-compose-dmz.md`

---

### LAB 6.3 - Container Security Scanning
**Piattaforma:** 🐳 Docker + Trivy/Snyk  
**Difficoltà:** ⭐⭐ Intermedio  
**Durata:** 2 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Scansionare immagini per vulnerabilità
- Implementare security best practices
- Integrare scanning in CI/CD

**Attività:**
```bash
# Installare Trivy
apt-get install trivy

# Scan immagine
trivy image nginx:latest

# Scan con severità
trivy image --severity HIGH,CRITICAL nginx:latest

# Scan filesystem
trivy fs /path/to/project

# Creare policy per bloccare immagini vulnerabili
# OPA policy example
```

**Documentazione:** `lab6.3-container-security-scanning.md`

---

## LAB 7 - Kubernetes DMZ

### LAB 7.1 - Namespace-based DMZ in Minikube
**Piattaforma:** 🐳 Kubernetes (Minikube)  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Creare namespace per zone di sicurezza
- Implementare Network Policies
- Deployare applicazione multi-tier

**Attività:**
1. Installare Minikube con CNI Calico/Cilium
2. Creare namespace: dmz, internal, data
3. Deploy web frontend in namespace dmz
4. Deploy API backend in namespace internal
5. Deploy database in namespace data
6. Implementare Network Policies per isolamento
7. Test connettività e sicurezza

**File manifest:** `lab7.1-k8s-namespace-dmz/`

---

### LAB 7.2 - Istio Service Mesh per DMZ
**Piattaforma:** 🐳 Kubernetes + Istio  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 5 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Installare Istio service mesh
- Implementare mTLS automatico
- Configurare authorization policies
- Visualizzare traffico con Kiali

**Attività:**
1. Installare Istio su cluster K8s
2. Deploy bookinfo sample app
3. Configurare Ingress Gateway
4. Abilitare mTLS STRICT
5. Creare AuthorizationPolicy per:
   - Permettere solo traffic autenticato
   - Bloccare comunicazione laterale in DMZ
6. Visualizzare service graph con Kiali
7. Monitoring con Prometheus e Grafana

**File manifest:** `lab7.2-istio-service-mesh-dmz/`

---

### LAB 7.3 - Cilium Network Policies Avanzate
**Piattaforma:** 🐳 Kubernetes + Cilium  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 4 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Installare Cilium CNI
- Creare policy L7 (HTTP-aware)
- Implementare DNS-based policies
- Cluster mesh per multi-cluster

**Attività:**
1. Setup cluster con Cilium
2. Deploy app microservizi
3. Creare CiliumNetworkPolicy con:
   - HTTP method filtering (GET vs POST)
   - Path-based filtering
   - Header inspection
4. Implement FQDN-based egress policy
5. Visualizzare flow con Hubble UI

**File manifest:** `lab7.3-cilium-advanced-policies/`

---

## LAB 8 - Cloud DMZ

### LAB 8.1 - AWS VPC con DMZ Subnet
**Piattaforma:** ☁️ AWS  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 4 ore  
**Capitoli correlati:** 10

**Obiettivi:**
- Creare VPC con subnet pubbliche e private
- Configurare Internet Gateway e NAT Gateway
- Implementare Security Groups e NACLs
- Deploy applicazione in DMZ

**Architettura AWS:**
```
Internet Gateway
      |
  [Public Subnet - DMZ]
   - ALB
   - NAT Gateway
      |
  [Private Subnet - App]
   - EC2 instances
   - Auto Scaling Group
      |
  [Private Subnet - Data]
   - RDS Database
```

**Attività (con Terraform/CloudFormation):**
1. Creare VPC con CIDR 10.0.0.0/16
2. Public subnet (DMZ): 10.0.1.0/24
3. Private subnet (App): 10.0.10.0/24
4. Private subnet (Data): 10.0.20.0/24
5. Deploy ALB in DMZ
6. EC2 Auto Scaling in App subnet
7. RDS in Data subnet
8. Security Groups per ogni layer
9. NACLs per isolamento subnet
10. Test connettività e failover

**File IaC:** `lab8.1-aws-vpc-dmz/`

---

### LAB 8.2 - Azure Network Security Groups
**Piattaforma:** ☁️ Azure  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 10

**Obiettivi:**
- Creare Virtual Network con subnet
- Configurare NSG per DMZ
- Deploy Application Gateway
- Implementare Azure Firewall

**Attività:**
1. Creare VNet con 3 subnet (DMZ, App, Data)
2. Deploy VM in ciascuna subnet
3. Configurare NSG rules:
   - DMZ: allow HTTP/HTTPS from Internet
   - App: allow traffic only from DMZ
   - Data: allow traffic only from App
4. Deploy Azure Application Gateway in DMZ
5. Configurare Azure Firewall per egress filtering
6. Test e monitoring con Azure Monitor

**File ARM/Bicep:** `lab8.2-azure-nsg-dmz/`

---

### LAB 8.3 - GCP Firewall Rules e Load Balancing
**Piattaforma:** ☁️ Google Cloud Platform  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 10

**Obiettivi:**
- Creare VPC con subnet personalizzate
- Configurare Firewall Rules hierarchiche
- Deploy Global Load Balancer
- Implementare Cloud Armor WAF

**Attività:**
1. Creare custom VPC mode
2. Subnet DMZ, App, Data in diverse regions
3. Deploy GCE instances con MIG (Managed Instance Group)
4. Configurare Firewall Rules per ogni subnet
5. Setup HTTP(S) Load Balancer
6. Abilitare Cloud CDN
7. Configurare Cloud Armor security policies
8. Test geolocation e DDoS protection

**File Terraform:** `lab8.3-gcp-firewall-lb-dmz/`

---

## LAB 9 - Advanced & Real-World Scenarios

### LAB 9.1 - Honeypot in DMZ
**Piattaforma:** 💻 VirtualBox + 🐳 Docker  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 4 ore  
**Capitoli correlati:** 8

**Obiettivi:**
- Deployare honeypot per rilevare attacchi
- Analizzare comportamento attaccanti
- Integrare con SIEM

**Attività:**
1. Installare T-Pot (all-in-one honeypot platform)
2. Configurare servizi honeypot:
   - Cowrie (SSH/Telnet honeypot)
   - Dionaea (malware capture)
   - Mailoney (SMTP honeypot)
3. Posizionare in DMZ esposta
4. Raccogliere dati attacchi
5. Analizzare log con ELK
6. Creare signature IDS da pattern osservati

**Documentazione:** `lab9.1-honeypot-dmz.md`

---

### LAB 9.2 - WAF con ModSecurity
**Piattaforma:** 💻 VirtualBox/VMware  
**Difficoltà:** ⭐⭐⭐⭐ Esperto  
**Durata:** 4 ore  
**Capitoli correlati:** 8

**Obiettivi:**
- Installare ModSecurity WAF
- Configurare OWASP Core Rule Set
- Proteggere web application da:
   - SQL Injection
   - XSS
   - CSRF
   - Directory Traversal

**Attività:**
1. Setup nginx + ModSecurity
2. Installare OWASP CRS
3. Configurare anomaly scoring mode
4. Deploy vulnerable app (DVWA) dietro WAF
5. Simulare attacchi con OWASP ZAP
6. Tuning rules per ridurre false positive
7. Integrare log con SIEM

**Documentazione:** `lab9.2-modsecurity-waf.md`

---

### LAB 9.3 - VPN Gateway in DMZ
**Piattaforma:** 💻 VirtualBox + pfSense/OpenVPN  
**Difficoltà:** ⭐⭐⭐ Avanzato  
**Durata:** 3 ore  
**Capitoli correlati:** 4, 7

**Obiettivi:**
- Configurare VPN server in DMZ
- Implementare accesso remoto sicuro
- Gestire certificati e autenticazione

**Attività:**
1. Setup OpenVPN server in DMZ
2. Generare CA e certificati client
3. Configurare client-to-site VPN
4. Implementare 2FA con Google Authenticator
5. Configurare split-tunneling
6. Firewall rules per VPN users
7. Test connessione da client remoti

**Documentazione:** `lab9.3-vpn-gateway-dmz.md`

---

### LAB 9.4 - Zero Trust Architecture
**Piattaforma:** 🐳 Kubernetes + Istio + OPA  
**Difficoltà:** ⭐⭐⭐⭐⭐ Master  
**Durata:** 6 ore  
**Capitoli correlati:** 10bis

**Obiettivi:**
- Implementare architettura Zero Trust completa
- Identity-based access control
- Continuous verification
- Micro-segmentation estrema

**Componenti:**
- Istio per mTLS e AuthN/AuthZ
- OPA (Open Policy Agent) per policy enforcement
- Keycloak per identity management
- Falco per runtime security

**Attività:**
1. Setup cluster K8s con Istio
2. Deploy Keycloak IdP
3. Configurare Istio RequestAuthentication con JWT
4. Implementare AuthorizationPolicy per ogni servizio
5. Deploy OPA Gatekeeper per admission control
6. Falco rules per runtime monitoring
7. Test con simulazione attacco lateral movement
8. Visualizzare deny logs

**File manifest:** `lab9.4-zero-trust-architecture/`

---

### LAB 9.5 - Incident Response Simulation
**Piattaforma:** 💻 Cyber Range / Multiple VMs  
**Difficoltà:** ⭐⭐⭐⭐⭐ Master  
**Durata:** 8 ore (full day)  
**Capitoli correlati:** 8, 9, 12

**Obiettivi:**
- Simulare breach in DMZ
- Eseguire incident response completo
- Forensics e root cause analysis

**Scenario:**
Attaccante ha compromesso web server in DMZ attraverso vulnerabilità non patchata. Obiettivo è rilevare, contenere, eradicare e recuperare.

**Fasi:**
1. **Detection**: Analizzare alert IDS/IPS, log anomali
2. **Containment**: Isolare server compromesso
3. **Analysis**: Memory dump, disk imaging
4. **Eradication**: Identificare backdoor, rimuovere malware
5. **Recovery**: Restore da backup, hardening
6. **Lessons Learned**: Post-mortem report

**Strumenti:**
- SIEM (Splunk/ELK)
- Volatility (memory forensics)
- Autopsy (disk forensics)
- Wireshark (network analysis)
- TheHive (case management)

**Documentazione:** `lab9.5-incident-response-playbook.md`

---

## LAB 10 - Progetti Finali

### LAB 10.1 - Progetto Enterprise DMZ Completo
**Piattaforma:** 💻 + 🐳 Hybrid  
**Difficoltà:** ⭐⭐⭐⭐⭐ Master  
**Durata:** 20+ ore (progetto multi-week)  

**Obiettivi:**
Progettare e implementare DMZ enterprise-grade per azienda fittizia con:
- 500+ dipendenti
- E-commerce pubblico
- CRM interno
- Compliance PCI-DSS e GDPR

**Requisiti Architetturali:**
1. DMZ Pubblica:
   - Load balanced web servers (HA)
   - API Gateway con rate limiting
   - WAF (ModSecurity o cloud-based)
2. DMZ Semi-pubblica:
   - Mail server con anti-spam/AV
   - DNS authoritative servers
   - VPN gateway per partner
3. Internal Network:
   - Application servers
   - Database cluster (HA)
   - Active Directory
   - File servers
4. Sicurezza:
   - Dual firewall architecture
   - IDS/IPS con Snort/Suricata
   - SIEM centralizzato
   - Backup e disaster recovery
5. Monitoraggio:
   - Grafana dashboards
   - Alert automatici
   - Log retention 90 giorni

**Deliverables:**
- Diagramma architetturale completo
- Documentazione tecnica HLD/LLD
- Configuration files (firewall, router, switch)
- Runbooks per operazioni comuni
- Disaster Recovery Plan
- Security audit report
- Presentazione finale

**Valutazione:**
- Funzionalità: 30%
- Sicurezza: 30%
- Documentazione: 20%
- Presentazione: 20%

---

### LAB 10.2 - Migrazione Cloud da On-Prem DMZ
**Piattaforma:** ☁️ AWS/Azure/GCP  
**Difficoltà:** ⭐⭐⭐⭐⭐ Master  
**Durata:** 15+ ore  

**Obiettivi:**
Migrare DMZ on-premises esistente verso cloud con:
- Zero downtime
- Hybrid connectivity (VPN/Direct Connect)
- Gradual cutover

**Fasi Progetto:**
1. **Assessment**: Analisi infrastruttura esistente
2. **Planning**: Strategia migrazione (lift-and-shift vs re-architect)
3. **Pilot**: Migrazione ambiente di test
4. **Hybrid**: Setup VPN site-to-site
5. **Migration**: Cutover per servizio
6. **Optimization**: Cloud-native refactoring
7. **Decommission**: Shutdown on-prem

**Documentazione:** `lab10.2-cloud-migration-project/`

---

## Risorse Aggiuntive

### File Packet Tracer
Tutti i file `.pkt` sono disponibili nella cartella:
```
/laboratori/packet-tracer/
├── lab1.1-dmz-singolo-firewall.pkt
├── lab1.2-dmz-doppio-firewall.pkt
├── lab1.3-dmz-tre-interfacce.pkt
├── lab2.1-web-server-dmz.pkt
├── lab2.2-mail-server-dmz.pkt
├── lab2.3-dns-split-brain.pkt
├── lab3.1-acl-dmz.pkt
├── lab3.2-zbpf-dmz.pkt
├── lab3.3-enterprise-ruleset.pkt
├── lab4.1-syslog-monitoring.pkt
└── lab4.2-snmp-monitoring.pkt
```

### VM Templates
OVA/OVF templates pre-configurati:
```
/laboratori/vm-templates/
├── pfsense-firewall.ova
├── ubuntu-server-web.ova
├── kali-linux-attacker.ova
├── windows-server-ad.ova
└── security-onion-ids.ova
```

### Docker Images Custom
```
/laboratori/docker-images/
├── dmz-web/
├── dmz-api/
├── dmz-firewall/
└── monitoring-stack/
```

### Scripts e Automation
```
/laboratori/scripts/
├── setup-lab-environment.sh
├── reset-configurations.sh
├── generate-traffic.py
├── security-audit.sh
└── incident-simulator.py
```

### Video Tutorial
Link ai video walkthrough per ogni laboratorio disponibili su piattaforma e-learning.

---

## Guida all'Uso

### Prerequisiti Generali
- **Packet Tracer**: Versione 8.0 o superiore
- **VirtualBox/VMware**: Almeno 16GB RAM host, 100GB storage
- **Docker**: Docker Engine 20.10+, Docker Compose 2.0+
- **Cloud**: Account trial AWS/Azure/GCP
- **Conoscenze**: Networking TCP/IP, Linux command line, firewall basics

### Come Scegliere il Laboratorio
1. **Principianti**: Iniziare con LAB 1-2 (Packet Tracer)
2. **Intermedi**: LAB 3-5 (Packet Tracer + VM)
3. **Avanzati**: LAB 6-8 (Container + Cloud)
4. **Esperti**: LAB 9-10 (Progetti complessi)

### Struttura Tipica Laboratorio
1. **Preparazione**: Setup ambiente e download risorse
2. **Teoria**: Breve recap concetti correlati
3. **Implementazione**: Step-by-step guidato
4. **Testing**: Verifica funzionalità
5. **Challenge**: Esercizi di troubleshooting
6. **Cleanup**: Reset ambiente per prossimo lab

### Certificazione
Completando almeno 15 laboratori (inclusi 2 progetti finali), gli studenti possono richiedere il **Certificato DMZ Security Specialist**.

---

*Buon lavoro con i laboratori! Per domande o supporto, consultare il forum e-learning o contattare il docente.*
