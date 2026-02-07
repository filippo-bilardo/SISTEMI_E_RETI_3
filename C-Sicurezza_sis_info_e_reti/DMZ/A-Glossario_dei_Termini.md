# Appendice A - Glossario dei Termini

## A

**ACL (Access Control List)**  
Lista di regole che controllano l'accesso a risorse di rete, specificando quali utenti o sistemi possono accedere e con quali permessi.

**Antivirus Gateway**  
Sistema che scansiona il traffico di rete (email, web) per rilevare e bloccare malware prima che raggiunga la rete interna.

**API Gateway**  
Componente che funge da punto di ingresso unico per le API, gestendo autenticazione, autorizzazione, rate limiting e routing.

**Application Server**  
Server che esegue la logica di business di un'applicazione, separato dal web server che gestisce le richieste HTTP.

## B

**Bastion Host**  
Server fortificato posizionato in DMZ che funge da unico punto di accesso per amministratori che devono connettersi a server interni.

**BGP (Border Gateway Protocol)**  
Protocollo di routing utilizzato tra Autonomous Systems su Internet.

**BIND (Berkeley Internet Name Domain)**  
Software DNS server open source più diffuso, utilizzato per risolvere nomi di dominio.

## C

**CDN (Content Delivery Network)**  
Rete distribuita di server che fornisce contenuti web agli utenti basandosi sulla loro posizione geografica.

**Certificate Authority (CA)**  
Entità che emette certificati digitali per SSL/TLS, verificando l'identità del richiedente.

**Chroot**  
Tecnica di sicurezza Unix/Linux che confina un processo in una specifica directory, limitando l'accesso al filesystem.

**CIS Controls (Center for Internet Security)**  
Framework di best practice di cybersecurity organizzato in controlli prioritizzati.

**CSR (Certificate Signing Request)**  
Richiesta inviata a una CA contenente informazioni per generare un certificato SSL/TLS.

## D

**Defense in Depth**  
Strategia di sicurezza che implementa multiple barriere difensive, in modo che il fallimento di una non comprometta l'intera sicurezza.

**DDoS (Distributed Denial of Service)**  
Attacco che rende inaccessibile un servizio sommergendolo di traffico da molteplici sorgenti compromesse.

**DKIM (DomainKeys Identified Mail)**  
Standard di autenticazione email che permette di verificare che un messaggio non sia stato alterato durante il transito.

**DMARC (Domain-based Message Authentication, Reporting and Conformance)**  
Protocollo email che utilizza SPF e DKIM per prevenire spoofing e phishing.

**DMZ (Demilitarized Zone)**  
Segmento di rete isolato che ospita servizi accessibili dall'esterno, separato dalla rete interna.

**DNS (Domain Name System)**  
Sistema che traduce nomi di dominio leggibili (es. www.example.com) in indirizzi IP.

**DNSSEC (DNS Security Extensions)**  
Estensioni del protocollo DNS che aggiungono firma crittografica per prevenire manipolazione dei dati DNS.

## E

**EV Certificate (Extended Validation)**  
Certificato SSL/TLS con validazione estesa dell'identità dell'organizzazione (ora deprecato dai browser).

## F

**Fail2ban**  
Software che analizza log e ban automaticamente IP che mostrano comportamenti malevoli (es. troppi login falliti).

**Firewall**  
Dispositivo o software che filtra il traffico di rete basandosi su regole predefinite.

**Forward Proxy**  
Proxy che agisce per conto dei client, intercettando e inoltrando richieste verso Internet.

**FTPS (FTP over SSL/TLS)**  
FTP con crittografia SSL/TLS aggiunta per proteggere credenziali e dati.

## G

**GDPR (General Data Protection Regulation)**  
Regolamento europeo sulla protezione dei dati personali.

**GeoIP**  
Database che associa indirizzi IP a posizioni geografiche, usato per filtrare traffico per paese.

## H

**HA (High Availability)**  
Configurazione che garantisce continuità di servizio anche in caso di guasto di componenti.

**Hardening**  
Processo di rafforzamento della sicurezza di un sistema riducendo la superficie di attacco.

**HAProxy**  
Software open source per load balancing e reverse proxy ad alte prestazioni.

**HSTS (HTTP Strict Transport Security)**  
Header HTTP che forza i browser a usare solo HTTPS per comunicare con un sito.

**Honeypot**  
Sistema esca progettato per attirare attaccanti e studiarne le tecniche.

## I

**ICMP (Internet Control Message Protocol)**  
Protocollo di rete utilizzato per messaggi diagnostici (es. ping).

**IDS (Intrusion Detection System)**  
Sistema che monitora il traffico di rete per rilevare attività sospette, generando alert.

**IMAP (Internet Message Access Protocol)**  
Protocollo per recuperare email da un server, mantenendole sul server.

**IPsec (Internet Protocol Security)**  
Suite di protocolli per la sicurezza delle comunicazioni IP tramite autenticazione e crittografia.

**IPS (Intrusion Prevention System)**  
Sistema che non solo rileva ma blocca attivamente il traffico malevolo.

## J

**Jump Host**  
Server intermediario utilizzato per accedere ad altri server in reti separate (simile a bastion host).

## K

**Kerberos**  
Protocollo di autenticazione di rete che utilizza ticket per verificare l'identità degli utenti.

**Keepalived**  
Software che implementa VRRP per alta disponibilità IP failover.

**KSK (Key Signing Key)**  
Chiave DNSSEC utilizzata per firmare altre chiavi DNS.

## L

**LDAP (Lightweight Directory Access Protocol)**  
Protocollo per accedere e gestire servizi di directory (es. Active Directory).

**Least Privilege (Principio del minimo privilegio)**  
Principio secondo cui ogni utente/processo deve avere solo i permessi strettamente necessari.

**Let's Encrypt**  
Certificate Authority gratuita che fornisce certificati SSL/TLS automaticamente.

**Load Balancer**  
Dispositivo che distribuisce il traffico tra più server per bilanciare il carico ed aumentare disponibilità.

## M

**MFA (Multi-Factor Authentication)**  
Autenticazione che richiede due o più fattori di verifica (password + OTP, biometria, ecc.).

**Micro-segmentation**  
Approccio che divide la rete in segmenti molto piccoli con controlli granulari tra di essi.

**MTU (Maximum Transmission Unit)**  
Dimensione massima di un pacchetto che può essere trasmesso su una rete.

## N

**NAT (Network Address Translation)**  
Tecnica che traduce indirizzi IP privati in IP pubblici per accesso a Internet.

**NGFW (Next-Generation Firewall)**  
Firewall avanzato che integra IPS, application awareness, SSL inspection e threat intelligence.

**NIST (National Institute of Standards and Technology)**  
Agenzia USA che sviluppa standard e framework di cybersecurity.

**NTP (Network Time Protocol)**  
Protocollo per sincronizzare l'orario dei computer su una rete.

## O

**OCSP (Online Certificate Status Protocol)**  
Protocollo per verificare lo stato di revoca di un certificato SSL/TLS.

**OCSP Stapling**  
Tecnica in cui il server web include la risposta OCSP nella handshake TLS, migliorando performance.

**OpenVPN**  
Software open source per VPN SSL/TLS, supporta varie configurazioni e piattaforme.

**OV Certificate (Organization Validation)**  
Certificato SSL/TLS che valida l'organizzazione oltre al dominio.

## P

**PAT (Port Address Translation)**  
Variante di NAT che traduce anche le porte, permettendo a più host interni di condividere un IP pubblico.

**PCI-DSS (Payment Card Industry Data Security Standard)**  
Standard di sicurezza per organizzazioni che gestiscono informazioni di carte di pagamento.

**POP3 (Post Office Protocol 3)**  
Protocollo per scaricare email da un server al client locale.

**Proxy**  
Server intermediario che inoltra richieste tra client e server.

## R

**RADIUS (Remote Authentication Dial-In User Service)**  
Protocollo per autenticazione, autorizzazione e accounting centralizzati.

**Rate Limiting**  
Tecnica che limita il numero di richieste accettate in un periodo di tempo, prevenendo abusi.

**Reverse Proxy**  
Proxy che agisce per conto dei server, accettando richieste dai client e inoltrandole ai server backend.

**RBL (Real-time Blackhole List)**  
Lista di indirizzi IP noti per inviare spam, usata per filtrare email.

## S

**SASL (Simple Authentication and Security Layer)**  
Framework per autenticazione in protocolli Internet (es. SMTP).

**SDN (Software-Defined Networking)**  
Approccio alla gestione di rete che programma il controllo della rete a livello software.

**Segregation of Duties**  
Principio che richiede che compiti critici siano divisi tra più persone per prevenire frodi.

**SFTP (SSH File Transfer Protocol)**  
Protocollo sicuro per transfer file su SSH.

**SIEM (Security Information and Event Management)**  
Sistema che aggrega e analizza log da molteplici sorgenti per rilevare minacce.

**SMTP (Simple Mail Transfer Protocol)**  
Protocollo standard per invio email tra server.

**Snort**  
Sistema IDS/IPS open source molto diffuso.

**SPF (Sender Policy Framework)**  
Record DNS che specifica quali mail server sono autorizzati a inviare email per un dominio.

**Split DNS**  
Configurazione che fornisce risposte DNS diverse per query interne ed esterne.

**SSH (Secure Shell)**  
Protocollo per accesso remoto sicuro tramite crittografia.

**SSL (Secure Sockets Layer)**  
Protocollo di crittografia deprecato, sostituito da TLS.

**Stateful Firewall**  
Firewall che traccia lo stato delle connessioni di rete e filtra basandosi su stato e contesto.

**Stateless Firewall**  
Firewall che filtra pacchetti individualmente senza tracciare lo stato della connessione.

**Suricata**  
IDS/IPS open source multi-threaded, alternativa moderna a Snort.

**Syslog**  
Standard per logging di messaggi di sistema su una rete.

## T

**TLS (Transport Layer Security)**  
Protocollo crittografico che fornisce comunicazioni sicure su rete (successore di SSL).

**TOTP (Time-based One-Time Password)**  
Algoritmo che genera password temporanee basate su ora corrente (es. Google Authenticator).

**Trust Zone**  
Segmento di rete con un determinato livello di fiducia e relative policy di sicurezza.

## U

**Untrusted Zone**  
Zona di rete con minimo livello di fiducia (es. Internet pubblico).

## V

**VLAN (Virtual Local Area Network)**  
Rete locale virtuale che segmenta logicamente una rete fisica.

**VPN (Virtual Private Network)**  
Estensione di rete privata su una rete pubblica, con crittografia del traffico.

**VRRP (Virtual Router Redundancy Protocol)**  
Protocollo che fornisce alta disponibilità per router tramite failover automatico.

## W

**WAF (Web Application Firewall)**  
Firewall specializzato per proteggere applicazioni web da attacchi (SQL injection, XSS, ecc.).

**WireGuard**  
Moderno protocollo VPN semplice e veloce, integrato nel kernel Linux.

## Z

**Zero Trust**  
Modello di sicurezza che non presume fiducia implicita basata su posizione di rete, verificando ogni accesso.

**Zone Transfer**  
Operazione AXFR/IXFR che trasferisce dati DNS da primary a secondary DNS server.

**ZSK (Zone Signing Key)**  
Chiave DNSSEC utilizzata per firmare i record di una zona DNS.

---

*Fine glossario*
