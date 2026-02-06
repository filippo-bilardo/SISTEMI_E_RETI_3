# Guida alle VPN (Virtual Private Network)

## Indice

### 1. Introduzione alle VPN
- 1.1 Cos'è una VPN
- 1.2 Storia e evoluzione delle VPN
- 1.3 Perché utilizzare una VPN
- 1.4 Vantaggi e svantaggi

### 2. Concetti Fondamentali
- 2.1 Tunneling
- 2.2 Crittografia
- 2.3 Autenticazione
- 2.4 Incapsulamento
- 2.5 VPN Client e VPN Server

### 3. Tipologie di VPN
- 3.1 VPN Remote Access (Client-to-Site)
  - Caratteristiche
  - Scenari d'uso
- 3.2 VPN Site-to-Site
  - Caratteristiche
  - Scenari d'uso
- 3.3 VPN Host-to-Host
- 3.4 VPN SSL/TLS vs IPsec

### 4. Protocolli VPN
- 4.1 IPsec (Internet Protocol Security)
  - AH (Authentication Header)
  - ESP (Encapsulating Security Payload)
  - IKE (Internet Key Exchange)
  - Modalità Transport e Tunnel
- 4.2 SSL/TLS VPN
  - OpenVPN
  - Caratteristiche e vantaggi
- 4.3 PPTP (Point-to-Point Tunneling Protocol)
- 4.4 L2TP/IPsec (Layer 2 Tunneling Protocol)
- 4.5 WireGuard
- 4.6 SSTP (Secure Socket Tunneling Protocol)
- 4.7 Confronto tra i protocolli

### 5. Sicurezza nelle VPN
- 5.1 Algoritmi di crittografia
  - AES, 3DES, Blowfish
- 5.2 Protocolli di autenticazione
  - Pre-shared keys
  - Certificati digitali
  - RADIUS e TACACS+
- 5.3 Gestione delle chiavi
- 5.4 Perfect Forward Secrecy (PFS)
- 5.5 Vulnerabilità e minacce
- 5.6 Best practices di sicurezza

### 6. Architetture VPN
- 6.1 VPN Gateway
- 6.2 VPN Concentrator
- 6.3 Architetture ridondanti
- 6.4 Split tunneling vs Full tunneling
- 6.5 VPN in ambiente cloud

### 7. Configurazione e Implementazione
- 7.1 Pianificazione di una rete VPN
- 7.2 Requisiti hardware e software
- 7.3 Configurazione IPsec su router Cisco
- 7.4 Configurazione OpenVPN
  - Installazione server
  - Configurazione client
  - Gestione certificati
- 7.5 Configurazione WireGuard
- 7.6 VPN su Linux (strongSwan, OpenVPN)
- 7.7 VPN su Windows Server
- 7.8 VPN su dispositivi mobili

### 8. QoS e Performance
- 8.1 Impatto delle VPN sulle prestazioni
- 8.2 Latenza e throughput
- 8.3 MTU e frammentazione
- 8.4 Ottimizzazione delle performance
- 8.5 Monitoring e troubleshooting

### 9. Applicazioni Pratiche
- 9.1 Accesso remoto per smart working
- 9.2 Collegamento tra sedi aziendali
- 9.3 Bypassare geo-restriction
- 9.4 Protezione su reti WiFi pubbliche
- 9.5 VPN per IoT
- 9.6 VPN per streaming e P2P

### 10. VPN e Networking
- 10.1 VPN e NAT
- 10.2 VPN e firewall
- 10.3 VPN e routing
- 10.4 VPN e VLAN
- 10.5 Integrazione con Active Directory

### 11. VPN Cloud e Servizi Commerciali
- 11.1 AWS VPN
- 11.2 Azure VPN Gateway
- 11.3 Google Cloud VPN
- 11.4 Servizi VPN commerciali
  - Valutazione e scelta
  - Privacy e logging policies
- 11.5 VPN aziendali vs consumer

### 12. Troubleshooting e Diagnostica
- 12.1 Problemi comuni e soluzioni
- 12.2 Strumenti di diagnostica
  - tcpdump, Wireshark
  - Log analysis
- 12.3 Test di connettività
- 12.4 Debug dei protocolli VPN

### 13. Aspetti Legali e Privacy
- 13.1 Normative sulla privacy (GDPR)
- 13.2 Logging e data retention
- 13.3 Giurisdizione e ubicazione server
- 13.4 VPN e attività illegali

### 14. Futuro delle VPN
- 14.1 Zero Trust Network Access (ZTNA)
- 14.2 SD-WAN e VPN
- 14.3 VPN e 5G
- 14.4 Tendenze emergenti

### 15. Laboratori ed Esercitazioni
- 15.1 Lab 1: Configurare una VPN Site-to-Site con IPsec
- 15.2 Lab 2: Installare e configurare OpenVPN
- 15.3 Lab 3: Configurare WireGuard
- 15.4 Lab 4: Analizzare il traffico VPN con Wireshark
- 15.5 Lab 5: Configurare VPN remote access

### 16. Risorse e Riferimenti
- 16.1 RFC e standard
- 16.2 Documentazione ufficiale
- 16.3 Tool e software
- 16.4 Libri e articoli consigliati
- 16.5 Community e forum

### Appendici
- A. Glossario dei termini
- B. Comandi principali
- C. Checklist configurazione VPN
- D. Esempi di file di configurazione