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

### 10. [Tailscale e VPN Mesh di Nuova Generazione](10.Tailscale_e_VPN_Mesh_di_Nuova_Generazione.md)
- 10.1 Introduzione alle VPN Mesh
- 10.2 Tailscale
- 10.3 Headscale
- 10.4 ZeroTier
- 10.5 Nebula (by Slack)
- 10.6 NetBird
- 10.7 Altre Soluzioni Emergenti
- 10.8 Confronto tra Soluzioni Mesh
- 10.9 Casi d'Uso Specifici
- 10.10 Vantaggi e Limitazioni

### 11. VPN e Networking
- 11.1 VPN e NAT
- 11.2 VPN e firewall
- 11.3 VPN e routing
- 11.4 VPN e VLAN
- 11.5 Integrazione con Active Directory

### 12. VPN Cloud e Servizi Commerciali
- 12.1 AWS VPN
- 12.2 Azure VPN Gateway
- 12.3 Google Cloud VPN
- 12.4 Servizi VPN commerciali
  - Valutazione e scelta
  - Privacy e logging policies
- 12.5 VPN aziendali vs consumer

### 13. Troubleshooting e Diagnostica
- 13.1 Problemi comuni e soluzioni
- 13.2 Strumenti di diagnostica
  - tcpdump, Wireshark
  - Log analysis
- 13.3 Test di connettività
- 13.4 Debug dei protocolli VPN

### 14. Aspetti Legali e Privacy
- 14.1 Normative sulla privacy (GDPR)
- 14.2 Logging e data retention
- 14.3 Giurisdizione e ubicazione server
- 14.4 VPN e attività illegali

### 15. Futuro delle VPN
- 15.1 Zero Trust Network Access (ZTNA)
- 15.2 SD-WAN e VPN
- 15.3 VPN e 5G
- 15.4 Tendenze emergenti
- 15.5 VPN Mesh e overlay networks

### 16. Laboratori ed Esercitazioni
- 16.1 Lab 1: Configurare una VPN Site-to-Site con IPsec
- 16.2 Lab 2: Installare e configurare OpenVPN
- 16.3 Lab 3: Configurare WireGuard
- 16.4 Lab 4: Analizzare il traffico VPN con Wireshark
- 16.5 Lab 5: Configurare VPN remote access
- 16.6 Lab 6: WireGuard con Docker e client Windows
- 16.7 Lab 7: Headscale - VPN mesh self-hosted
- 16.8 Lab 8: Linux gateway con WireGuard e Tailscale
- 16.9 Lab 9: VPN IPsec con Router Cisco in Packet Tracer

### 17. Risorse e Riferimenti
- 17.1 RFC e standard
- 17.2 Documentazione ufficiale
  - OpenVPN, WireGuard, strongSwan
  - Tailscale, Headscale, ZeroTier
- 17.3 Tool e software
- 17.4 Libri e articoli consigliati
- 17.5 Community e forum
- 17.6 Repository GitHub rilevanti

### 18. Servizi VPN Commerciali - Approfondimento
- 18.1 Come Funzionano le VPN Commerciali
- 18.2 Vantaggi dei Servizi VPN Commerciali
- 18.3 Svantaggi e Limitazioni
- 18.4 Provider VPN: Analisi Dettagliata
  - Top Tier: Mullvad, ProtonVPN, IVPN
  - Mainstream: NordVPN, ExpressVPN, Surfshark
  - Provider da evitare
- 18.5 Confronto: VPN Commerciale vs Self-Hosted
- 18.6 Aspetti Tecnici Avanzati
  - Kill Switch, Split Tunneling, DNS Leak, WebRTC Leak
- 18.7 Considerazioni sulla Privacy e Giurisdizione
  - Five/Nine/Fourteen Eyes
  - No-Log Policy e audit
- 18.8 Funzionalità Avanzate dei Provider
  - Multi-Hop, Offuscamento, Onion over VPN
- 18.9 Guida Pratica: Configurazione e Test
- 18.10 Scenari di Utilizzo Reali
- 18.11 FAQ e Miti sulle VPN Commerciali
- 18.12 Esercizi e Verifiche

### Appendici
- A. Glossario dei termini
- B. Comandi principali
- C. Checklist configurazione VPN
- D. Esempi di file di configurazione