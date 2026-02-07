# Sicurezza a Livello Applicativo e di Trasporto

## Indice

### Prefazione
- A chi è rivolta questa guida
- Prerequisiti
- Convenzioni utilizzate nel testo

---

## PARTE I - FONDAMENTI DI SICUREZZA DI RETE

### Capitolo 1 - Il Modello ISO/OSI e TCP/IP
- 1.1 I sette livelli del modello ISO/OSI
- 1.2 Il modello TCP/IP
- 1.3 Livello di trasporto: TCP e UDP
- 1.4 Livello applicativo: HTTP, FTP, SMTP, DNS
- 1.5 Dove si colloca la sicurezza
- Domande di autovalutazione

### Capitolo 2 - Concetti Base di Crittografia
- 2.1 Crittografia simmetrica vs asimmetrica
- 2.2 Algoritmi di cifratura (AES, RSA, ECC)
- 2.3 Funzioni hash (SHA-256, SHA-3)
- 2.4 Firma digitale
- 2.5 Certificati digitali e PKI
- 2.6 Perfect Forward Secrecy (PFS)
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 3 - Minacce e Vulnerabilità
- 3.1 Man-in-the-Middle (MITM)
- 3.2 Packet sniffing e eavesdropping
- 3.3 Session hijacking
- 3.4 Replay attacks
- 3.5 Denial of Service (DoS) e DDoS
- 3.6 SQL Injection e XSS
- 3.7 CSRF (Cross-Site Request Forgery)
- 3.8 Il modello STRIDE per l'analisi delle minacce
- Casi studio
- Domande di autovalutazione

---

## PARTE II - SICUREZZA A LIVELLO DI TRASPORTO

### Capitolo 4 - SSL/TLS: Fondamenti
- 4.1 Storia: da SSL a TLS 1.3
- 4.2 Architettura del protocollo TLS
- 4.3 TLS Handshake: passo dopo passo
- 4.4 Record Protocol
- 4.5 Cipher suites
- 4.6 Versioni di TLS: differenze e sicurezza
  - 4.6.1 TLS 1.0 e 1.1 (deprecati)
  - 4.6.2 TLS 1.2
  - 4.6.3 TLS 1.3: novità e miglioramenti
- 4.7 SNI (Server Name Indication)
- 4.8 ALPN (Application-Layer Protocol Negotiation)
- Esercizi con Wireshark: analisi handshake TLS
- Domande di autovalutazione

### Capitolo 5 - Certificati Digitali
- 5.1 Struttura di un certificato X.509
- 5.2 Certificate Authority (CA) e catena di fiducia
- 5.3 Tipi di certificati (DV, OV, EV)
- 5.4 Wildcard e SAN certificates
- 5.5 Let's Encrypt e automazione
- 5.6 Gestione del ciclo di vita dei certificati
- 5.7 Certificate Pinning
- 5.8 Certificate Transparency
- Esercizi pratici: generare e installare certificati
- Domande di autovalutazione

### Capitolo 6 - Implementare TLS
- 6.1 Configurare HTTPS su Apache
- 6.2 Configurare HTTPS su Nginx
- 6.3 Configurare HTTPS su IIS
- 6.4 TLS in applicazioni Python (ssl module)
- 6.5 TLS in applicazioni Java (JSSE)
- 6.6 TLS in applicazioni Node.js
- 6.7 TLS in applicazioni C# (.NET)
- 6.8 Best practices per la configurazione
- 6.9 Testing: SSL Labs, testssl.sh
- Esercizi guidati
- Domande di autovalutazione

### Capitolo 7 - DTLS (Datagram Transport Layer Security)
- 7.1 TLS su UDP: motivazioni
- 7.2 Differenze tra TLS e DTLS
- 7.3 Casi d'uso: VoIP, WebRTC, VPN
- 7.4 Implementazione DTLS
- Esempi di codice
- Domande di autovalutazione

### Capitolo 8 - QUIC e HTTP/3
- 8.1 Limiti di TCP e TLS 1.2
- 8.2 Il protocollo QUIC
- 8.3 Sicurezza integrata in QUIC
- 8.4 HTTP/3 su QUIC
- 8.5 Vantaggi prestazionali
- 8.6 Adozione e supporto
- Domande di autovalutazione

---

## PARTE III - SICUREZZA A LIVELLO APPLICATIVO

### Capitolo 9 - HTTPS e Sicurezza Web
- 9.1 Da HTTP a HTTPS
- 9.2 HSTS (HTTP Strict Transport Security)
- 9.3 Cookie sicuri: Secure e HttpOnly flags
- 9.4 SameSite cookies
- 9.5 Content Security Policy (CSP)
- 9.6 X-Frame-Options e Clickjacking
- 9.7 X-Content-Type-Options
- 9.8 Referrer-Policy
- 9.9 Permissions Policy
- 9.10 CORS (Cross-Origin Resource Sharing)
- Esercizi: configurare header di sicurezza
- Domande di autovalutazione

### Capitolo 10 - Autenticazione e Autorizzazione
- 10.1 Basic Authentication (sconsigliata)
- 10.2 Digest Authentication
- 10.3 Token-based authentication
- 10.4 JWT (JSON Web Tokens)
  - 10.4.1 Struttura di un JWT
  - 10.4.2 Algoritmi di firma
  - 10.4.3 Vulnerabilità comuni
  - 10.4.4 Best practices
- 10.5 OAuth 2.0
  - 10.5.1 Flussi di autorizzazione
  - 10.5.2 Scope e permissions
  - 10.5.3 Implementazione sicura
- 10.6 OpenID Connect
- 10.7 SAML 2.0
- 10.8 API Keys
- 10.9 Multi-Factor Authentication (MFA)
- Esercizi pratici: implementare OAuth 2.0
- Domande di autovalutazione

### Capitolo 11 - API REST Sicure
- 11.1 Principi di design sicuro
- 11.2 Autenticazione API
- 11.3 Rate limiting e throttling
- 11.4 Input validation e sanitization
- 11.5 Output encoding
- 11.6 Versionamento API
- 11.7 HTTPS obbligatorio
- 11.8 Logging e monitoring
- 11.9 OWASP API Security Top 10
- 11.10 GraphQL: considerazioni di sicurezza
- Esempi di implementazione
- Domande di autovalutazione

### Capitolo 12 - Web Application Firewall (WAF)
- 12.1 Cos'è un WAF
- 12.2 ModSecurity
- 12.3 OWASP Core Rule Set
- 12.4 Configurazione e tuning
- 12.5 WAF cloud: Cloudflare, AWS WAF, Azure WAF
- 12.6 Limitazioni dei WAF
- Esercizi di configurazione
- Domande di autovalutazione

### Capitolo 13 - Email Security
- 13.1 SMTP e vulnerabilità
- 13.2 STARTTLS
- 13.3 SPF (Sender Policy Framework)
- 13.4 DKIM (DomainKeys Identified Mail)
- 13.5 DMARC (Domain-based Message Authentication)
- 13.6 S/MIME
- 13.7 PGP/GPG per email
- 13.8 MTA-STS e TLS-RPT
- Configurazione pratica
- Domande di autovalutazione

### Capitolo 14 - DNS Security
- 14.1 DNS vulnerabilities
- 14.2 DNSSEC (DNS Security Extensions)
- 14.3 DNS over HTTPS (DoH)
- 14.4 DNS over TLS (DoT)
- 14.5 DNS filtering e blacklisting
- 14.6 Protezione da DNS poisoning
- Esercizi di configurazione DNSSEC
- Domande di autovalutazione

### Capitolo 15 - Sicurezza nei Protocolli di Messaggistica
- 15.1 XMPP e TLS
- 15.2 Signal Protocol
- 15.3 End-to-End Encryption (E2EE)
- 15.4 WebSocket Security
- 15.5 MQTT e sicurezza IoT
- Esempi di implementazione
- Domande di autovalutazione

### Capitolo 16 - VPN e Tunneling
- 16.1 IPsec
  - 16.1.1 AH e ESP
  - 16.1.2 IKEv2
  - 16.1.3 Configurazione strongSwan
- 16.2 OpenVPN
  - 16.2.1 Architettura
  - 16.2.2 Certificati e PKI
  - 16.2.3 Configurazione server/client
- 16.3 WireGuard
  - 16.3.1 Design moderno
  - 16.3.2 Cryptokey routing
  - 16.3.3 Configurazione
- 16.4 Tailscale e Headscale
- 16.5 SSH Tunneling
- 16.6 Confronto tra soluzioni VPN
- Esercizi guidati
- Domande di autovalutazione

---

## PARTE IV - SVILUPPO SICURO

### Capitolo 17 - Secure Coding Practices
- 17.1 OWASP Top 10
- 17.2 Input validation
- 17.3 Parametrized queries (prevenire SQL injection)
- 17.4 Output encoding (prevenire XSS)
- 17.5 Gestione sicura delle password
  - 17.5.1 Hashing: bcrypt, scrypt, Argon2
  - 17.5.2 Salt
  - 17.5.3 Pepper
- 17.6 Gestione sicura delle sessioni
- 17.7 Generazione numeri casuali crittografici
- 17.8 Gestione sicura dei segreti
- 17.9 Dependency scanning
- 17.10 SAST e DAST
- Esempi di codice vulnerabile e corretto
- Domande di autovalutazione

### Capitolo 18 - Sicurezza nei Container
- 18.1 Immagini Docker sicure
- 18.2 Scanning vulnerabilità (Trivy, Clair)
- 18.3 Docker secrets
- 18.4 Network isolation
- 18.5 Kubernetes security
  - 18.5.1 RBAC
  - 18.5.2 Network policies
  - 18.5.3 Pod Security Standards
  - 18.5.4 Secrets management
- 18.6 Service mesh: Istio, Linkerd
- 18.7 mTLS (mutual TLS)
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 19 - Secrets Management
- 19.1 Perché non hardcodare secrets
- 19.2 Variabili d'ambiente
- 19.3 HashiCorp Vault
- 19.4 AWS Secrets Manager
- 19.5 Azure Key Vault
- 19.6 Google Secret Manager
- 19.7 Sealed Secrets per Kubernetes
- 19.8 SOPS (Secrets OPerationS)
- 19.9 Rotation automatica
- Implementazioni pratiche
- Domande di autovalutazione

### Capitolo 20 - Zero Trust Architecture
- 20.1 Principi fondamentali
- 20.2 "Never trust, always verify"
- 20.3 Micro-segmentation
- 20.4 Identity-centric security
- 20.5 Implementare Zero Trust
- 20.6 BeyondCorp (Google)
- 20.7 Software-Defined Perimeter (SDP)
- Casi studio
- Domande di autovalutazione

---

## PARTE V - TESTING E COMPLIANCE

### Capitolo 21 - Security Testing
- 21.1 Penetration testing
- 21.2 Vulnerability scanning
- 21.3 Strumenti open source
  - 21.3.1 Nmap
  - 21.3.2 Wireshark
  - 21.3.3 Burp Suite
  - 21.3.4 OWASP ZAP
  - 21.3.5 Metasploit
- 21.4 Bug bounty programs
- 21.5 Red team vs Blue team
- Esercizi in ambiente di laboratorio
- Domande di autovalutazione

### Capitolo 22 - Logging, Monitoring e Incident Response
- 22.1 Security logging best practices
- 22.2 SIEM (Security Information and Event Management)
- 22.3 ELK Stack per security
- 22.4 Splunk
- 22.5 Alerting e anomaly detection
- 22.6 Incident response plan
- 22.7 Forensics digitale
- 22.8 Post-mortem analysis
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 23 - Compliance e Normative
- 23.1 GDPR e privacy
- 23.2 PCI DSS (Payment Card Industry)
- 23.3 HIPAA (Healthcare)
- 23.4 SOC 2
- 23.5 ISO 27001
- 23.6 NIST Cybersecurity Framework
- 23.7 CIS Controls
- 23.8 Audit e certificazioni
- Checklist di conformità
- Domande di autovalutazione

---

## PARTE VI - ARGOMENTI AVANZATI

### Capitolo 24 - Post-Quantum Cryptography
- 24.1 Minaccia dei computer quantistici
- 24.2 Algoritmi post-quantum
- 24.3 NIST standardization
- 24.4 Migrazione verso crittografia quantum-resistant
- Domande di autovalutazione

### Capitolo 25 - Blockchain e Distributed Ledger
- 25.1 Sicurezza nella blockchain
- 25.2 Smart contract security
- 25.3 Consensus mechanisms
- 25.4 Wallet security
- 25.5 DeFi security risks
- Domande di autovalutazione

### Capitolo 26 - AI/ML per la Security
- 26.1 Machine learning per threat detection
- 26.2 Anomaly detection con AI
- 26.3 Adversarial attacks su modelli ML
- 26.4 Security dei sistemi AI
- Domande di autovalutazione

### Capitolo 27 - Edge Computing e IoT Security
- 27.1 Sfide specifiche dell'IoT
- 27.2 Protocolli lightweight (CoAP, MQTT)
- 27.3 Constrained devices e crittografia
- 27.4 Firmware security
- 27.5 OTA updates sicuri
- Domande di autovalutazione

---

## APPENDICI

### Appendice A - Riferimenti Crittografici
- A.1 Lunghezze chiavi raccomandate
- A.2 Algoritmi deprecati
- A.3 Cipher suites raccomandate

### Appendice B - Porte e Protocolli
- B.1 Porte standard sicure
- B.2 Mapping protocolli/porte

### Appendice C - Tool e Risorse
- C.1 Strumenti open source
- C.2 Online testing tools
- C.3 Risorse per approfondimenti
- C.4 Certificazioni professionali

### Appendice D - Laboratorio Pratico
- D.1 Setup ambiente di test
- D.2 Virtual machines e container
- D.3 Esercitazioni complete end-to-end

### Appendice E - Checklist di Sicurezza
- E.1 Web application security checklist
- E.2 API security checklist
- E.3 Infrastructure security checklist
- E.4 Code review security checklist

---

## Risposte alle Domande di Autovalutazione

### Capitolo 1 - Risposte
### Capitolo 2 - Risposte
### ...
### Capitolo 27 - Risposte

---

## Bibliografia

## Indice Analitico