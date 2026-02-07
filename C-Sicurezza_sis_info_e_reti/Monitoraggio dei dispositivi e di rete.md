# Monitoraggio dei Dispositivi e di Rete

## Indice

### Prefazione
- A chi è rivolta questa guida
- Prerequisiti consigliati
- Struttura del libro
- Convenzioni utilizzate nel testo
- Ambiente di laboratorio e risorse online

---

## PARTE I - FONDAMENTI DEL MONITORAGGIO

### Capitolo 1 - Introduzione al Network Monitoring
- 1.1 Cos'è il monitoraggio di rete
- 1.2 Perché monitorare
  - 1.2.1 Performance management
  - 1.2.2 Troubleshooting
  - 1.2.3 Capacity planning
  - 1.2.4 Security monitoring
  - 1.2.5 Compliance e auditing
- 1.3 Cosa monitorare
  - 1.3.1 Availability (uptime)
  - 1.3.2 Performance (latenza, throughput)
  - 1.3.3 Errors e packet loss
  - 1.3.4 Utilizzo risorse (CPU, RAM, bandwidth)
  - 1.3.5 Eventi e log
- 1.4 Metriche vs Logs vs Traces
- 1.5 Observability vs Monitoring
- 1.6 Il ciclo OODA (Observe, Orient, Decide, Act)
- Domande di autovalutazione

### Capitolo 2 - Modello OSI e TCP/IP per il Monitoraggio
- 2.1 Ripasso dei livelli OSI
- 2.2 Cosa monitorare per livello
  - 2.2.1 Livello 1 (Fisico): cavi, segnali, errori
  - 2.2.2 Livello 2 (Data Link): switch, MAC, VLAN
  - 2.2.3 Livello 3 (Network): router, routing, IP
  - 2.2.4 Livello 4 (Transport): TCP/UDP, porte
  - 2.2.5 Livello 7 (Application): HTTP, DNS, servizi
- 2.3 Stack TCP/IP
- 2.4 Troubleshooting bottom-up vs top-down
- Domande di autovalutazione

### Capitolo 3 - Metriche Fondamentali
- 3.1 The Four Golden Signals (Google SRE)
  - 3.1.1 Latency
  - 3.1.2 Traffic
  - 3.1.3 Errors
  - 3.1.4 Saturation
- 3.2 RED Method (Rate, Errors, Duration)
- 3.3 USE Method (Utilization, Saturation, Errors)
- 3.4 KPI (Key Performance Indicators)
- 3.5 SLA, SLO, SLI
  - 3.5.1 Service Level Agreement
  - 3.5.2 Service Level Objective
  - 3.5.3 Service Level Indicator
- 3.6 Error budgets
- 3.7 MTBF, MTTR, MTTA, MTTF
- Esercizi: definire SLO per servizi reali
- Domande di autovalutazione

### Capitolo 4 - Architetture di Monitoraggio
- 4.1 Pull vs Push model
- 4.2 Agent-based vs Agentless
- 4.3 Centralized vs Distributed
- 4.4 In-band vs Out-of-band monitoring
- 4.5 Active vs Passive monitoring
- 4.6 Componenti di un sistema di monitoraggio
  - 4.6.1 Data collectors
  - 4.6.2 Storage (TSDB - Time Series Database)
  - 4.6.3 Processing e aggregazione
  - 4.6.4 Visualization
  - 4.6.5 Alerting
- 4.7 Scalabilità e high availability
- Domande di autovalutazione

---

## PARTE II - PROTOCOLLI E TECNICHE DI MONITORAGGIO

### Capitolo 5 - SNMP (Simple Network Management Protocol)
- 5.1 Cos'è SNMP
- 5.2 Architettura SNMP
  - 5.2.1 SNMP Manager
  - 5.2.2 SNMP Agent
  - 5.2.3 MIB (Management Information Base)
- 5.3 Versioni SNMP
  - 5.3.1 SNMPv1 (obsoleto)
  - 5.3.2 SNMPv2c
  - 5.3.3 SNMPv3 (sicuro)
- 5.4 Operazioni SNMP
  - 5.4.1 GET
  - 5.4.2 GETNEXT
  - 5.4.3 GETBULK
  - 5.4.4 SET
  - 5.4.5 TRAP
  - 5.4.6 INFORM
- 5.5 OID (Object Identifier)
- 5.6 MIB standard e vendor-specific
- 5.7 Configurare SNMP
  - 5.7.1 Su Linux (net-snmp)
  - 5.7.2 Su Windows
  - 5.7.3 Su router/switch Cisco
  - 5.7.4 Community strings
- 5.8 SNMPwalk e query
- 5.9 Limitazioni di SNMP
- 5.10 Sicurezza SNMP
- Esercizi pratici: configurare e interrogare SNMP
- Domande di autovalutazione

### Capitolo 6 - NetFlow, sFlow, IPFIX
- 6.1 Flow monitoring
- 6.2 NetFlow (Cisco)
  - 6.2.1 NetFlow v5
  - 6.2.2 NetFlow v9
  - 6.2.3 Flexible NetFlow
  - 6.2.4 Flow records
  - 6.2.5 Exporter e Collector
- 6.3 sFlow (InMon)
  - 6.3.1 Sampling
  - 6.3.2 Differenze con NetFlow
- 6.4 IPFIX (IP Flow Information Export)
- 6.5 jFlow (Juniper)
- 6.6 Use cases
  - 6.6.1 Traffic analysis
  - 6.6.2 Capacity planning
  - 6.6.3 DDoS detection
  - 6.6.4 Security forensics
- 6.7 Flow collectors e analyzers
  - 6.7.1 nfdump/nfsen
  - 6.7.2 ntopng
  - 6.7.3 Elastiflow
  - 6.7.4 SolarWinds
- Esercizi pratici: configurare NetFlow
- Domande di autovalutazione

### Capitolo 7 - Packet Capture e Deep Packet Inspection
- 7.1 Packet sniffing
- 7.2 Wireshark
  - 7.2.1 Interface e capture filters
  - 7.2.2 Display filters
  - 7.2.3 Protocol analysis
  - 7.2.4 Statistics e graphs
  - 7.2.5 Export e reporting
- 7.3 tcpdump
  - 7.3.1 Sintassi e filtri BPF
  - 7.3.2 Esempi pratici
- 7.4 tshark (Wireshark CLI)
- 7.5 SPAN/Mirror ports
- 7.6 TAP (Test Access Point)
- 7.7 Deep Packet Inspection (DPI)
- 7.8 Network Packet Brokers
- 7.9 Considerazioni legali ed etiche
- Esercizi: analizzare traffico con Wireshark
- Domande di autovalutazione

### Capitolo 8 - ICMP e Ping Monitoring
- 8.1 Internet Control Message Protocol
- 8.2 Ping
  - 8.2.1 Echo Request/Reply
  - 8.2.2 RTT (Round Trip Time)
  - 8.2.3 Packet loss
  - 8.2.4 Opzioni avanzate
- 8.3 Traceroute/Tracert
  - 8.3.1 Come funziona
  - 8.3.2 ICMP vs UDP vs TCP traceroute
  - 8.3.3 Interpretare i risultati
- 8.4 MTR (My Traceroute)
- 8.5 Pathping (Windows)
- 8.6 ICMP types utili per monitoring
  - 8.6.1 Destination Unreachable
  - 8.6.2 Time Exceeded
  - 8.6.3 Redirect
- 8.7 Ping sweeps e discovery
- 8.8 Limitazioni: firewall e rate limiting
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 9 - Syslog e Centralized Logging
- 9.1 Cos'è Syslog
- 9.2 RFC 5424 (Syslog Protocol)
- 9.3 Severity levels
- 9.4 Facilities
- 9.5 Formato messaggi Syslog
- 9.6 Transport: UDP vs TCP vs TLS
- 9.7 Syslog server
  - 9.7.1 rsyslog
  - 9.7.2 syslog-ng
  - 9.7.3 Configurazione
- 9.8 Centralizzazione dei log
- 9.9 Log retention e rotation
- 9.10 Parsing e structured logging
- 9.11 Syslog in dispositivi di rete
- Esercizi: configurare rsyslog
- Domande di autovalutazione

### Capitolo 10 - WMI e Windows Monitoring
- 10.1 Windows Management Instrumentation
- 10.2 WMI architecture
- 10.3 WMI namespaces e classes
- 10.4 WQL (WMI Query Language)
- 10.5 Query con PowerShell
- 10.6 Performance Counters
- 10.7 Event Logs
  - 10.7.1 Application, Security, System
  - 10.7.2 Event IDs
  - 10.7.3 Event Viewer
- 10.8 Windows Performance Monitor (perfmon)
- 10.9 Monitoring remoto via WMI
- 10.10 Sicurezza WMI
- Esercizi pratici
- Domande di autovalutazione

---

## PARTE III - STRUMENTI DI MONITORAGGIO OPEN SOURCE

### Capitolo 11 - Nagios e Derivati
- 11.1 Nagios Core
  - 11.1.1 Architettura
  - 11.1.2 Installazione
  - 11.1.3 Configurazione
  - 11.1.4 Host e service definitions
  - 11.1.5 Commands e check scripts
  - 11.1.6 Notifications
  - 11.1.7 Web interface
- 11.2 Plugin Nagios
  - 11.2.1 check_ping, check_http, check_snmp
  - 11.2.2 Scrivere plugin personalizzati
  - 11.2.3 NRPE (Nagios Remote Plugin Executor)
  - 11.2.4 NCPA
- 11.3 Icinga2
  - 11.3.1 Miglioramenti rispetto a Nagios
  - 11.3.2 Director
  - 11.3.3 Icinga Web 2
- 11.4 Naemon
- 11.5 Shinken
- 11.6 Centreon
- Esercizi: setup e configurazione Nagios
- Domande di autovalutazione

### Capitolo 12 - Zabbix
- 12.1 Panoramica Zabbix
- 12.2 Architettura
  - 12.2.1 Zabbix Server
  - 12.2.2 Zabbix Agent (passive/active)
  - 12.2.3 Zabbix Proxy
  - 12.2.4 Database backend
  - 12.2.5 Web frontend
- 12.3 Installazione
- 12.4 Concetti fondamentali
  - 12.4.1 Hosts e host groups
  - 12.4.2 Items
  - 12.4.3 Triggers
  - 12.4.4 Actions
  - 12.4.5 Templates
  - 12.4.6 Graphs e screens
- 12.5 Discovery automatico
  - 12.5.1 Network discovery
  - 12.5.2 Auto-registration
  - 12.5.3 Low-level discovery (LLD)
- 12.6 Monitoring agentless (SNMP, IPMI, JMX)
- 12.7 Distributed monitoring
- 12.8 Zabbix API
- 12.9 Alerting e notifications
- 12.10 Maintenance windows
- 12.11 Maps e visualizzazioni
- Progetto pratico: monitorare infrastruttura con Zabbix
- Domande di autovalutazione

### Capitolo 13 - Prometheus
- 13.1 Prometheus overview
- 13.2 Architettura time-series
- 13.3 Data model
  - 13.3.1 Metrics e labels
  - 13.3.2 Metric types: Counter, Gauge, Histogram, Summary
- 13.4 PromQL (Prometheus Query Language)
  - 13.4.1 Selettori
  - 13.4.2 Operatori
  - 13.4.3 Funzioni
  - 13.4.4 Aggregations
- 13.5 Exporters
  - 13.5.1 Node Exporter (Linux)
  - 13.5.2 Windows Exporter
  - 13.5.3 Blackbox Exporter
  - 13.5.4 SNMP Exporter
  - 13.5.5 Exporter personalizzati
- 13.6 Service discovery
- 13.7 Scraping e targets
- 13.8 Recording rules
- 13.9 Alerting rules
- 13.10 Alertmanager
  - 13.10.1 Routing
  - 13.10.2 Grouping e throttling
  - 13.10.3 Silences e inhibition
  - 13.10.4 Receivers (email, Slack, PagerDuty)
- 13.11 Federation
- 13.12 Remote storage
- 13.13 Prometheus Operator (Kubernetes)
- Esercizi pratici: deployment e query Prometheus
- Domande di autovalutazione

### Capitolo 14 - Grafana
- 14.1 Cos'è Grafana
- 14.2 Installazione
- 14.3 Data sources
  - 14.3.1 Prometheus
  - 14.3.2 InfluxDB
  - 14.3.3 Elasticsearch
  - 14.3.4 CloudWatch, Azure Monitor
  - 14.3.5 Altri
- 14.4 Dashboards
  - 14.4.1 Panels e visualizations
  - 14.4.2 Variables
  - 14.4.3 Templating
  - 14.4.4 Annotations
- 14.5 Query editor
- 14.6 Alerting in Grafana
- 14.7 Grafana Loki (logging)
- 14.8 Grafana Tempo (tracing)
- 14.9 Grafana Mimir (Prometheus long-term storage)
- 14.10 Plugins e estensibilità
- 14.11 Provisioning e Infrastructure as Code
- 14.12 Grafana Cloud
- Esercizi: creare dashboards avanzate
- Domande di autovalutazione

### Capitolo 15 - ELK/Elastic Stack
- 15.1 Panoramica dello stack
- 15.2 Elasticsearch
  - 15.2.1 Architettura distribuita
  - 15.2.2 Indices, shards, replicas
  - 15.2.3 Document model
  - 15.2.4 Query DSL
  - 15.2.5 Aggregations
- 15.3 Logstash
  - 15.3.1 Input, filter, output
  - 15.3.2 Grok patterns
  - 15.3.3 Parsing logs
  - 15.3.4 Pipeline configuration
- 15.4 Beats
  - 15.4.1 Filebeat (log shipping)
  - 15.4.2 Metricbeat (metrics)
  - 15.4.3 Packetbeat (network)
  - 15.4.4 Heartbeat (uptime)
  - 15.4.5 Auditbeat (security)
- 15.5 Kibana
  - 15.5.1 Discover
  - 15.5.2 Visualize
  - 15.5.3 Dashboards
  - 15.5.4 Canvas
  - 15.5.5 Alerting
- 15.6 Elastic APM
- 15.7 Elastic Security (SIEM)
- 15.8 Use cases per network monitoring
- 15.9 Scalabilità e performance tuning
- Progetto: pipeline completa con ELK
- Domande di autovalutazione

### Capitolo 16 - InfluxDB e TICK Stack
- 16.1 InfluxDB (Time Series Database)
  - 16.1.1 Data model
  - 16.1.2 InfluxQL
  - 16.1.3 Flux language
  - 16.1.4 Retention policies
- 16.2 Telegraf (data collector)
  - 16.2.1 Input plugins
  - 16.2.2 Output plugins
  - 16.2.3 Processor e aggregator plugins
- 16.3 Chronograf (visualization)
- 16.4 Kapacitor (alerting e processing)
- 16.5 Confronto con Prometheus
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 17 - LibreNMS
- 17.1 Panoramica LibreNMS
- 17.2 Auto-discovery
- 17.3 SNMP monitoring
- 17.4 Device support
- 17.5 Alerting
- 17.6 API
- 17.7 Billing
- Esercizi: installazione e configurazione
- Domande di autovalutazione

### Capitolo 18 - Observium
- 18.1 Community vs Professional
- 18.2 Auto-discovery
- 18.3 Device monitoring
- 18.4 Bills e accounting
- 18.5 Alerting
- Domande di autovalutazione

### Capitolo 19 - PRTG Network Monitor
- 19.1 Panoramica PRTG (commerciale con free tier)
- 19.2 Sensors
- 19.3 Auto-discovery
- 19.4 Templates
- 19.5 Maps e dashboards
- 19.6 Notifications
- Domande di autovalutazione

### Capitolo 20 - Cacti
- 20.1 RRDtool e round-robin databases
- 20.2 Data sources e graph templates
- 20.3 SNMP monitoring
- 20.4 Plugin architecture
- 20.5 Spine (poller)
- Domande di autovalutazione

---

## PARTE IV - MONITORAGGIO DI DISPOSITIVI SPECIFICI

### Capitolo 21 - Monitoraggio di Router e Switch
- 21.1 Metriche chiave
  - 21.1.1 Interface statistics (errors, discards)
  - 21.1.2 Bandwidth utilization
  - 21.1.3 CPU e memory
  - 21.1.4 Temperature
  - 21.1.5 Fan status
  - 21.1.6 Power supply
- 21.2 SNMP su Cisco devices
- 21.3 SNMP su Juniper
- 21.4 SNMP su HP/Aruba
- 21.5 Syslog da network devices
- 21.6 NetFlow/sFlow configuration
- 21.7 Monitoring BGP, OSPF, spanning tree
- 21.8 RMON (Remote Monitoring)
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 22 - Monitoraggio di Firewall
- 22.1 Metriche specifiche
  - 22.1.1 Connection count
  - 22.1.2 Throughput
  - 22.1.3 Dropped packets
  - 22.1.4 VPN tunnels
  - 22.1.5 IPS/IDS events
- 22.2 pfSense monitoring
- 22.3 Fortinet FortiGate
- 22.4 Palo Alto Networks
- 22.5 Cisco ASA/Firepower
- 22.6 Log analysis per security
- Domande di autovalutazione

### Capitolo 23 - Monitoraggio di Access Point e WiFi
- 23.1 Metriche WiFi
  - 23.1.1 Client count
  - 23.1.2 Signal strength (RSSI)
  - 23.1.3 Channel utilization
  - 23.1.4 Interference
  - 23.1.5 Retransmissions
- 23.2 SNMP su access points
- 23.3 Controller-based WiFi (UniFi, Meraki, Aruba)
- 23.4 WiFi site surveys
- 23.5 Roaming e handoff monitoring
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 24 - Monitoraggio di Server Linux
- 24.1 Metriche di sistema
  - 24.1.1 CPU usage
  - 24.1.2 Memory e swap
  - 24.1.3 Disk I/O e space
  - 24.1.4 Network interfaces
  - 24.1.5 Load average
  - 24.1.6 Process monitoring
- 24.2 Strumenti nativi
  - 24.2.1 top, htop
  - 24.2.2 vmstat, iostat, netstat
  - 24.2.3 sar (sysstat)
  - 24.2.4 dstat, glances
- 24.3 /proc filesystem
- 24.4 systemd journal
- 24.5 Monitoraggio remoto
  - 24.5.1 SSH-based checks
  - 24.5.2 SNMP (net-snmp)
  - 24.5.3 Agents (Telegraf, Node Exporter, Zabbix Agent)
- 24.6 Service monitoring
- 24.7 Log monitoring
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 25 - Monitoraggio di Server Windows
- 25.1 Performance Monitor
- 25.2 Resource Monitor
- 25.3 Task Manager avanzato
- 25.4 Event Logs
- 25.5 PowerShell per monitoring
- 25.6 WMI queries
- 25.7 Performance counters via SNMP
- 25.8 Windows Exporter per Prometheus
- 25.9 Active Directory monitoring
- 25.10 Exchange monitoring
- 25.11 SQL Server monitoring
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 26 - Monitoraggio di Virtualizzazione
- 26.1 VMware vSphere
  - 26.1.1 vCenter monitoring
  - 26.1.2 ESXi host metrics
  - 26.1.3 VM performance
  - 26.1.4 Resource pools
  - 26.1.5 Datastore utilization
  - 26.1.6 vSphere API
- 26.2 Hyper-V monitoring
- 26.3 KVM/QEMU monitoring
- 26.4 Proxmox VE
- 26.5 Overcommitment e resource contention
- Domande di autovalutazione

### Capitolo 27 - Monitoraggio di Storage
- 27.1 Storage metrics
  - 27.1.1 IOPS
  - 27.1.2 Latency
  - 27.1.3 Throughput
  - 27.1.4 Capacity
  - 27.1.5 Queue depth
- 27.2 RAID monitoring
- 27.3 SAN monitoring
- 27.4 NAS monitoring
- 27.5 S.M.A.R.T. monitoring (hard disk health)
- 27.6 NetApp, EMC, Pure Storage
- 27.7 Object storage (S3, Ceph)
- Domande di autovalutazione

### Capitolo 28 - Monitoraggio di Database
- 28.1 MySQL/MariaDB
  - 28.1.1 Performance Schema
  - 28.1.2 Slow query log
  - 28.1.3 SHOW STATUS
  - 28.1.4 Replication monitoring
- 28.2 PostgreSQL
  - 28.2.1 pg_stat views
  - 28.2.2 Log analysis
  - 28.2.3 pgBadger
- 28.3 Oracle Database
- 28.4 Microsoft SQL Server
- 28.5 MongoDB
- 28.6 Redis
- 28.7 Connection pools
- 28.8 Query performance
- Domande di autovalutazione

### Capitolo 29 - Monitoraggio di Web Server
- 29.1 Apache
  - 29.1.1 mod_status
  - 29.1.2 Access e error logs
  - 29.1.3 Performance tuning
- 29.2 Nginx
  - 29.2.1 stub_status
  - 29.2.2 Amplify
  - 29.2.3 Access logs
- 29.3 IIS
- 29.4 Application Performance Monitoring (APM)
- 29.5 Synthetic monitoring
- Domande di autovalutazione

---

## PARTE V - MONITORAGGIO CLOUD E CONTAINERIZZATO

### Capitolo 30 - Monitoraggio AWS
- 30.1 CloudWatch
  - 30.1.1 Metrics
  - 30.1.2 Logs
  - 30.1.3 Alarms
  - 30.1.4 Dashboards
  - 30.1.5 Events/EventBridge
- 30.2 CloudWatch Agent
- 30.3 VPC Flow Logs
- 30.4 CloudTrail (audit)
- 30.5 X-Ray (tracing)
- 30.6 EC2 monitoring
- 30.7 RDS monitoring
- 30.8 ELB/ALB monitoring
- 30.9 Lambda monitoring
- 30.10 S3 metrics
- 30.11 Cost monitoring
- 30.12 Integrare con Prometheus/Grafana
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 31 - Monitoraggio Azure
- 31.1 Azure Monitor
  - 31.1.1 Metrics
  - 31.1.2 Logs (Log Analytics)
  - 31.1.3 Alerts
  - 31.1.4 Workbooks
- 31.2 Application Insights
- 31.3 Network Watcher
- 31.4 Azure Monitor Agent
- 31.5 VM monitoring
- 31.6 AKS monitoring
- 31.7 SQL Database monitoring
- 31.8 Cost Management
- Domande di autovalutazione

### Capitolo 32 - Monitoraggio Google Cloud Platform
- 32.1 Cloud Monitoring (ex Stackdriver)
- 32.2 Cloud Logging
- 32.3 Cloud Trace
- 32.4 Cloud Profiler
- 32.5 GCE monitoring
- 32.6 GKE monitoring
- 32.7 Cloud SQL monitoring
- 32.8 Load balancer monitoring
- Domande di autovalutazione

### Capitolo 33 - Monitoraggio Container e Docker
- 33.1 Docker stats
- 33.2 cAdvisor (Container Advisor)
- 33.3 Docker logging drivers
- 33.4 Monitoring Docker daemon
- 33.5 Container resource limits
- 33.6 Health checks
- 33.7 Docker Swarm monitoring
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 34 - Monitoraggio Kubernetes
- 34.1 Architettura Kubernetes monitoring
- 34.2 Metrics Server
- 34.3 kube-state-metrics
- 34.4 Node Exporter
- 34.5 cAdvisor integrato
- 34.6 Prometheus Operator
- 34.7 Monitoring control plane
  - 34.7.1 API server
  - 34.7.2 etcd
  - 34.7.3 Scheduler
  - 34.7.4 Controller manager
- 34.8 Monitoring nodes
- 34.9 Monitoring pods e containers
- 34.10 Resource requests e limits
- 34.11 HPA (Horizontal Pod Autoscaler) metrics
- 34.12 Network policies monitoring
- 34.13 Logging con EFK/Loki
- 34.14 Distributed tracing (Jaeger, Zipkin)
- 34.15 Service mesh monitoring (Istio, Linkerd)
- 34.16 Managed Kubernetes (EKS, AKS, GKE)
- Progetto: stack completo di monitoring K8s
- Domande di autovalutazione

---

## PARTE VI - APPLICATION PERFORMANCE MONITORING

### Capitolo 35 - APM Fundamentals
- 35.1 Cos'è APM
- 35.2 Real User Monitoring (RUM)
- 35.3 Synthetic monitoring
- 35.4 Transaction tracing
- 35.5 Code-level visibility
- 35.6 Dependency mapping
- 35.7 Error tracking
- Domande di autovalutazione

### Capitolo 36 - Distributed Tracing
- 36.1 Microservices e distributed systems
- 36.2 Spans e traces
- 36.3 Context propagation
- 36.4 OpenTelemetry
  - 36.4.1 Traces
  - 36.4.2 Metrics
  - 36.4.3 Logs
  - 36.4.4 SDKs e auto-instrumentation
- 36.5 Jaeger
- 36.6 Zipkin
- 36.7 Grafana Tempo
- 36.8 AWS X-Ray
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 37 - APM Commerciali
- 37.1 New Relic
- 37.2 Datadog
- 37.3 AppDynamics (Cisco)
- 37.4 Dynatrace
- 37.5 Splunk APM
- 37.6 Elastic APM
- 37.7 Confronto e scelta
- Domande di autovalutazione

### Capitolo 38 - Synthetic Monitoring e Uptime Checks
- 38.1 Cos'è synthetic monitoring
- 38.2 HTTP/HTTPS checks
- 38.3 Multi-step transactions
- 38.4 Browser-based monitoring (Selenium)
- 38.5 API monitoring
- 38.6 Monitoring geograficamente distribuito
- 38.7 Strumenti
  - 38.7.1 Pingdom
  - 38.7.2 UptimeRobot
  - 38.7.3 StatusCake
  - 38.7.4 Blackbox Exporter (Prometheus)
- Esercizi pratici
- Domande di autovalutazione

---

## PARTE VII - ALERTING E INCIDENT MANAGEMENT

### Capitolo 39 - Progettare un Sistema di Alerting
- 39.1 Alert fatigue e come evitarlo
- 39.2 Actionable alerts
- 39.3 Alert severity levels
- 39.4 Thresholds statici vs dinamici
- 39.5 Anomaly detection
- 39.6 Alert aggregation e grouping
- 39.7 Escalation policies
- 39.8 On-call rotations
- 39.9 Runbooks e playbooks
- Best practices
- Domande di autovalutazione

### Capitolo 40 - Canali di Notifica
- 40.1 Email
- 40.2 SMS
- 40.3 Phone calls
- 40.4 Slack, Microsoft Teams
- 40.5 PagerDuty
- 40.6 Opsgenie
- 40.7 VictorOps (Splunk On-Call)
- 40.8 Webhooks personalizzati
- 40.9 Mobile apps
- 40.10 ChatOps
- Configurazioni pratiche
- Domande di autovalutazione

### Capitolo 41 - Incident Management
- 41.1 Incident lifecycle
- 41.2 Detection e alerting
- 41.3 Triage e prioritization
- 41.4 Investigation e diagnosis
- 41.5 Resolution
- 41.6 Post-mortem analysis
- 41.7 Status pages
- 41.8 Communication durante incident
- 41.9 Incident Commander role
- 41.10 Blameless post-mortems
- 41.11 Continuous improvement
- Template e checklist
- Domande di autovalutazione

### Capitolo 42 - Chaos Engineering
- 42.1 Principi del chaos engineering
- 42.2 Fault injection
- 42.3 Chaos Monkey (Netflix)
- 42.4 Gremlin
- 42.5 Litmus (Kubernetes)
- 42.6 Chaos Mesh
- 42.7 Monitoring durante chaos experiments
- Domande di autovalutazione

---

## PARTE VIII - SICUREZZA E COMPLIANCE

### Capitolo 43 - Security Monitoring
- 43.1 Differenze con network monitoring tradizionale
- 43.2 SIEM (Security Information and Event Management)
  - 43.2.1 Splunk
  - 43.2.2 Elastic Security
  - 43.2.3 QRadar (IBM)
  - 43.2.4 ArcSight
  - 43.2.5 Wazuh (open source)
- 43.3 IDS/IPS monitoring
  - 43.3.1 Snort
  - 43.3.2 Suricata
  - 43.3.3 Zeek (ex Bro)
- 43.4 Firewall log analysis
- 43.5 DDoS detection e mitigation
- 43.6 Anomaly detection con ML
- 43.7 Threat intelligence feeds
- 43.8 SOC (Security Operations Center)
- Domande di autovalutazione

### Capitolo 44 - Compliance Monitoring
- 44.1 Audit logging
- 44.2 Compliance frameworks
  - 44.2.1 PCI-DSS
  - 44.2.2 HIPAA
  - 44.2.3 GDPR
  - 44.2.4 SOC 2
  - 44.2.5 ISO 27001
- 44.3 Log retention policies
- 44.4 Tamper-proof logging
- 44.5 Reporting automatico
- 44.6 Access monitoring
- Domande di autovalutazione

### Capitolo 45 - Network Security Monitoring (NSM)
- 45.1 Full packet capture
- 45.2 Session data
- 45.3 Statistical data
- 45.4 Alert data
- 45.5 Security Onion
- 45.6 RITA (Real Intelligence Threat Analytics)
- 45.7 Hunting vs Detection
- Domande di autovalutazione

---

## PARTE IX - ANALISI E OTTIMIZZAZIONE

### Capitolo 46 - Capacity Planning
- 46.1 Trend analysis
- 46.2 Growth forecasting
- 46.3 Resource utilization patterns
- 46.4 Peak vs average load
- 46.5 Seasonality
- 46.6 Scalability testing
- 46.7 Cost optimization
- Strumenti e metodologie
- Domande di autovalutazione

### Capitolo 47 - Performance Troubleshooting
- 47.1 Metodologia sistematica
- 47.2 Correlation analysis
- 47.3 Root cause analysis
- 47.4 Bottleneck identification
- 47.5 Network path analysis
- 47.6 Latency breakdown
- 47.7 Packet loss investigation
- 47.8 Bandwidth saturation
- 47.9 Application vs network issues
- Casi studio pratici
- Domande di autovalutazione

### Capitolo 48 - Baseline e Anomaly Detection
- 48.1 Creare baseline
- 48.2 Normal behavior profiling
- 48.3 Statistical anomaly detection
- 48.4 Machine learning per anomalie
- 48.5 Time series forecasting
- 48.6 Seasonal decomposition
- 48.7 Alert su deviazioni
- Implementazioni pratiche
- Domande di autovalutazione

### Capitolo 49 - Reporting e Dashboarding
- 49.1 Design di dashboard efficaci
- 49.2 KPI dashboards
- 49.3 Executive summaries
- 49.4 Technical reports
- 49.5 SLA reporting
- 49.6 Automated reports
- 49.7 Data visualization best practices
- 49.8 Tools: Grafana, Kibana, Power BI, Tableau
- Esempi di dashboard
- Domande di autovalutazione

---

## PARTE X - AUTOMAZIONE E INTEGRAZIONE

### Capitolo 50 - Infrastructure as Code per Monitoring
- 50.1 Configuration management
  - 50.1.1 Ansible
  - 50.1.2 Puppet
  - 50.1.3 Chef
  - 50.1.4 SaltStack
- 50.2 Terraform per monitoring stack
- 50.3 Git per configurazioni
- 50.4 CI/CD per monitoring
- 50.5 Testing monitoring configurations
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 51 - API e Programmabilità
- 51.1 REST APIs per monitoring
- 51.2 Prometheus API
- 51.3 Grafana API
- 51.4 Zabbix API
- 51.5 CloudWatch API
- 51.6 Scripting con Python
  - 51.6.1 requests library
  - 51.6.2 prometheus_client
  - 51.6.3 Custom exporters
- 51.7 Automation workflows
- Progetti pratici
- Domande di autovalutazione

### Capitolo 52 - Event-Driven Monitoring
- 52.1 Webhooks
- 52.2 Message queues (RabbitMQ, Kafka)
- 52.3 Serverless monitoring (Lambda, Cloud Functions)
- 52.4 Event correlation
- 52.5 Self-healing systems
- Domande di autovalutazione

### Capitolo 53 - AIOps e Machine Learning
- 53.1 Cos'è AIOps
- 53.2 Predictive analytics
- 53.3 Anomaly detection con ML
- 53.4 Root cause analysis automatizzato
- 53.5 Auto-remediation
- 53.6 Platforms: Moogsoft, BigPanda
- 53.7 Implementare ML per monitoring
- Domande di autovalutazione

---

## PARTE XI - CASI D'USO E SCENARI

### Capitolo 54 - Monitoring per Piccole Imprese
- 54.1 Budget limitati
- 54.2 Soluzioni cloud-based
- 54.3 Free tier services
- 54.4 Setup semplificato
- 54.5 Managed services
- Architettura di riferimento
- Domande di autovalutazione

### Capitolo 55 - Monitoring Enterprise
- 55.1 Multi-site monitoring
- 55.2 Scalabilità
- 55.3 Alta disponibilità
- 55.4 Distributed teams
- 55.5 Compliance requirements
- 55.6 Integration con ITSM (ServiceNow, Jira)
- Architettura enterprise
- Domande di autovalutazione

### Capitolo 56 - ISP e Service Provider Monitoring
- 56.1 Subscriber monitoring
- 56.2 SLA management
- 56.3 Billing integration
- 56.4 Multi-tenant architecture
- 56.5 Large-scale NetFlow
- 56.6 BGP monitoring
- 56.7 Peering monitoring
- Domande di autovalutazione

### Capitolo 57 - Data Center Monitoring
- 57.1 Environmental monitoring (temperatura, umidità)
- 57.2 Power monitoring (UPS, PDU)
- 57.3 Cooling systems
- 57.4 Physical security (access control)
- 57.5 Rack-level monitoring
- 57.6 DCIM (Data Center Infrastructure Management)
- Domande di autovalutazione

### Capitolo 58 - SD-WAN Monitoring
- 58.1 Overlay networks
- 58.2 Path selection monitoring
- 58.3 Application-aware routing
- 58.4 VeloCloud, Cisco Viptela, Fortinet
- 58.5 Performance metrics
- Domande di autovalutazione

### Capitolo 59 - IoT e Edge Monitoring
- 59.1 Constraint devices
- 59.2 Lightweight protocols (MQTT, CoAP)
- 59.3 Edge computing monitoring
- 59.4 Sensor data aggregation
- 59.5 Long-range connectivity (LoRaWAN, NB-IoT)
- 59.6 Battery monitoring
- Domande di autovalutazione

---

## PARTE XII - BEST PRACTICES E FUTURO

### Capitolo 60 - Best Practices Generali
- 60.1 Start simple, iterate
- 60.2 Monitor what matters
- 60.3 Avoid alert fatigue
- 60.4 Document everything
- 60.5 Regular reviews e tuning
- 60.6 Training del team
- 60.7 Disaster recovery per monitoring
- 60.8 Security del monitoring stack
- 60.9 Cost management
- Checklist completa
- Domande di autovalutazione

### Capitolo 61 - SRE (Site Reliability Engineering)
- 61.1 Principi SRE
- 61.2 Error budgets
- 61.3 Toil reduction
- 61.4 Blameless post-mortems
- 61.5 SLI/SLO/SLA framework
- 61.6 On-call practices
- 61.7 Monitoring SRE workload
- Domande di autovalutazione

### Capitolo 62 - Observability vs Monitoring
- 62.1 I tre pilastri: metrics, logs, traces
- 62.2 High cardinality data
- 62.3 Structured logging
- 62.4 Context propagation
- 62.5 OpenTelemetry ecosystem
- 62.6 Observability-driven development
- Domande di autovalutazione

### Capitolo 63 - Tendenze Future
- 63.1 AIOps evolution
- 63.2 Autonomous networks (self-configuring, self-healing)
- 63.3 eBPF per monitoring
- 63.4 5G e network slicing
- 63.5 Edge computing challenges
- 63.6 Quantum-safe monitoring
- 63.7 Zero Trust monitoring
- 63.8 Sustainability e green IT monitoring
- Domande di autovalutazione

---

## APPENDICI

### Appendice A - Glossario
- Termini tecnici dalla A alla Z

### Appendice B - Protocolli e Porte
- B.1 Porte comuni per monitoring
- B.2 SNMP OIDs utili
- B.3 MIB reference

### Appendice C - Comandi Utili
- C.1 Linux commands
- C.2 Windows commands
- C.3 Network device commands (Cisco, Juniper)
- C.4 Docker/Kubernetes commands

### Appendice D - Tool Comparison Matrix
- D.1 Open source vs commercial
- D.2 Feature comparison
- D.3 Use case mapping

### Appendice E - Laboratorio Pratico
- E.1 Setup ambiente virtuale
  - E.1.1 GNS3
  - E.1.2 EVE-NG
  - E.1.3 Vagrant
  - E.1.4 Docker Compose
- E.2 Progetti guidati
  - E.2.1 Lab 1: Nagios basic setup
  - E.2.2 Lab 2: Prometheus + Grafana
  - E.2.3 Lab 3: ELK Stack
  - E.2.4 Lab 4: Zabbix deployment
  - E.2.5 Lab 5: Kubernetes monitoring
  - E.2.6 Lab 6: Multi-site monitoring
  - E.2.7 Lab 7: Security monitoring con Wazuh
  - E.2.8 Lab 8: NetFlow analysis

### Appendice F - Checklist Operative
- F.1 Deployment checklist
- F.2 Security hardening checklist
- F.3 Troubleshooting checklist
- F.4 Maintenance checklist

### Appendice G - Template e Script
- G.1 Grafana dashboard templates
- G.2 Prometheus alerting rules
- G.3 Python monitoring scripts
- G.4 Bash monitoring scripts
- G.5 Ansible playbooks

### Appendice H - Risorse Online
- H.1 Documentazione ufficiale
- H.2 Community forums
- H.3 Blog e newsletter
- H.4 Video tutorials
- H.5 Certificazioni professionali

---

## Risposte alle Domande di Autovalutazione

### Capitolo 1 - Risposte
### Capitolo 2 - Risposte
### ...
### Capitolo 63 - Risposte

---

## Bibliografia

## Indice Analitico