# Autenticazione degli Utenti e dei Servizi

## Indice

### Prefazione
- A chi è rivolta questa guida
- Prerequisiti consigliati
- Struttura del libro
- Convenzioni utilizzate nel testo
- Codice sorgente e materiali online

---

## PARTE I - FONDAMENTI DI AUTENTICAZIONE

### Capitolo 1 - Concetti Base di Autenticazione
- 1.1 Autenticazione vs Autorizzazione vs Accounting (AAA)
- 1.2 Identificazione e identità digitale
- 1.3 I tre fattori di autenticazione
  - 1.3.1 Qualcosa che conosci (knowledge)
  - 1.3.2 Qualcosa che possiedi (possession)
  - 1.3.3 Qualcosa che sei (inherence)
- 1.4 Autenticazione Single-Factor vs Multi-Factor
- 1.5 Principio del minimo privilegio
- 1.6 Defense in depth
- 1.7 Threat modeling per l'autenticazione
- 1.8 Il ciclo di vita dell'identità
- Domande di autovalutazione

### Capitolo 2 - Gestione delle Password
- 2.1 Storia e evoluzione delle password
- 2.2 Politiche di password sicure
  - 2.2.1 Lunghezza vs complessità
  - 2.2.2 Password composition rules
  - 2.2.3 Password expiration: pro e contro
  - 2.2.4 Passphrase
- 2.3 Attacchi alle password
  - 2.3.1 Brute force
  - 2.3.2 Dictionary attacks
  - 2.3.3 Rainbow tables
  - 2.3.4 Credential stuffing
  - 2.3.5 Password spraying
  - 2.3.6 Phishing e social engineering
- 2.4 Storage sicuro delle password
  - 2.4.1 Mai salvare in chiaro
  - 2.4.2 Hashing: MD5, SHA (obsoleti)
  - 2.4.3 Salt: cos'è e perché è essenziale
  - 2.4.4 Pepper: layer aggiuntivo
  - 2.4.5 Key stretching
- 2.5 Algoritmi di hashing moderni
  - 2.5.1 bcrypt
  - 2.5.2 scrypt
  - 2.5.3 Argon2 (vincitore PHC)
  - 2.5.4 PBKDF2
  - 2.5.5 Confronto e scelta
- 2.6 Password reset sicuro
- 2.7 Account lockout e rate limiting
- 2.8 Have I Been Pwned e breach detection
- Esercizi pratici: implementare hashing sicuro
- Domande di autovalutazione

### Capitolo 3 - Password Manager
- 3.1 Perché usare un password manager
- 3.2 Password manager locali vs cloud
- 3.3 Soluzioni popolari
  - 3.3.1 1Password
  - 3.3.2 Bitwarden (open source)
  - 3.3.3 LastPass
  - 3.3.4 KeePass/KeePassXC
  - 3.3.5 Dashlane
- 3.4 Password manager aziendali
- 3.5 Master password: best practices
- 3.6 Generazione di password casuali
- 3.7 Auto-fill e sicurezza
- 3.8 Emergency access e recovery
- Esercizi: configurare e usare Bitwarden
- Domande di autovalutazione

### Capitolo 4 - Autenticazione Multi-Fattore (MFA)
- 4.1 Perché MFA è essenziale
- 4.2 Tipologie di secondo fattore
  - 4.2.1 SMS (sconsigliato)
  - 4.2.2 Email
  - 4.2.3 Authenticator apps (TOTP)
  - 4.2.4 Hardware tokens (FIDO2/WebAuthn)
  - 4.2.5 Push notifications
  - 4.2.6 Biometria
- 4.3 TOTP (Time-based One-Time Password)
  - 4.3.1 RFC 6238
  - 4.3.2 Algoritmo TOTP
  - 4.3.3 Google Authenticator
  - 4.3.4 Microsoft Authenticator
  - 4.3.5 Authy
- 4.4 HOTP (HMAC-based One-Time Password)
- 4.5 Backup codes
- 4.6 Adaptive authentication e risk-based MFA
- 4.7 MFA bypass e attacchi
  - 4.7.1 SIM swapping
  - 4.7.2 MFA fatigue
  - 4.7.3 Phishing-resistant MFA
- Esercizi: implementare TOTP
- Domande di autovalutazione

### Capitolo 5 - FIDO2 e WebAuthn
- 5.1 Limiti delle password e MFA tradizionale
- 5.2 FIDO Alliance e standard
- 5.3 FIDO U2F (Universal 2nd Factor)
- 5.4 FIDO2 e passwordless authentication
- 5.5 WebAuthn (W3C standard)
  - 5.5.1 Registration ceremony
  - 5.5.2 Authentication ceremony
  - 5.5.3 Attestation
  - 5.5.4 Assertion
- 5.6 Authenticator types
  - 5.6.1 Platform authenticators (Windows Hello, Touch ID)
  - 5.6.2 Roaming authenticators (YubiKey, Titan)
- 5.7 Passkeys
- 5.8 Implementazione WebAuthn
- 5.9 Vantaggi e limitazioni
- Esercizi pratici: integrare WebAuthn
- Domande di autovalutazione

---

## PARTE II - AUTENTICAZIONE BASATA SU TOKEN

### Capitolo 6 - Session-Based Authentication
- 6.1 HTTP è stateless
- 6.2 Cookie e sessioni
- 6.3 Session ID generation
- 6.4 Server-side session storage
  - 6.4.1 In-memory
  - 6.4.2 Database
  - 6.4.3 Redis/Memcached
- 6.5 Cookie attributes per la sicurezza
  - 6.5.1 HttpOnly
  - 6.5.2 Secure
  - 6.5.3 SameSite
  - 6.5.4 Domain e Path
- 6.6 Session fixation attacks
- 6.7 Session hijacking
- 6.8 CSRF (Cross-Site Request Forgery)
  - 6.8.1 Come funziona
  - 6.8.2 CSRF tokens
  - 6.8.3 Double submit cookies
- 6.9 Session timeout e idle timeout
- 6.10 Logout sicuro
- Esercizi: implementare sessioni sicure
- Domande di autovalutazione

### Capitolo 7 - Token-Based Authentication
- 7.1 Vantaggi rispetto alle sessioni
- 7.2 Stateless authentication
- 7.3 Token opachi vs self-contained
- 7.4 Bearer tokens
- 7.5 Token storage
  - 7.5.1 localStorage vs sessionStorage
  - 7.5.2 Cookies
  - 7.5.3 Memory
- 7.6 Token transmission
  - 7.6.1 Authorization header
  - 7.6.2 Query parameters (sconsigliato)
- 7.7 Token refresh
- 7.8 Token revocation
- 7.9 XSS e token security
- Domande di autovalutazione

### Capitolo 8 - JWT (JSON Web Tokens)
- 8.1 Cos'è un JWT
- 8.2 Struttura di un JWT
  - 8.2.1 Header
  - 8.2.2 Payload
  - 8.2.3 Signature
- 8.3 JWT vs JWS vs JWE
- 8.4 Algoritmi di firma
  - 8.4.1 HS256 (HMAC + SHA-256)
  - 8.4.2 RS256 (RSA + SHA-256)
  - 8.4.3 ES256 (ECDSA + SHA-256)
- 8.5 Claims standard
  - 8.5.1 iss (issuer)
  - 8.5.2 sub (subject)
  - 8.5.3 aud (audience)
  - 8.5.4 exp (expiration)
  - 8.5.5 iat (issued at)
  - 8.5.6 nbf (not before)
  - 8.5.7 jti (JWT ID)
- 8.6 Custom claims
- 8.7 JWT best practices
- 8.8 Vulnerabilità comuni
  - 8.8.1 None algorithm
  - 8.8.2 Algorithm confusion (RS256 vs HS256)
  - 8.8.3 Weak signing keys
  - 8.8.4 Missing signature verification
  - 8.8.5 Information disclosure
- 8.9 Access token vs Refresh token
- 8.10 JWT rotation
- 8.11 Librerie JWT
  - 8.11.1 Python: PyJWT
  - 8.11.2 JavaScript: jsonwebtoken
  - 8.11.3 Java: jjwt
  - 8.11.4 C#: System.IdentityModel.Tokens.Jwt
- Esercizi pratici: creare e validare JWT
- Domande di autovalutazione

### Capitolo 9 - API Keys
- 9.1 Quando usare API keys
- 9.2 Generazione sicura di API keys
- 9.3 Storage delle API keys
  - 9.3.1 Hashing (come password)
  - 9.3.2 Encryption at rest
- 9.4 Trasmissione sicura
- 9.5 API key rotation
- 9.6 API key scopes e permissions
- 9.7 Rate limiting per API key
- 9.8 Monitoring e audit
- 9.9 Limitazioni delle API keys
- 9.10 Alternative moderne
- Esercizi pratici
- Domande di autovalutazione

---

## PARTE III - PROTOCOLLI DI AUTENTICAZIONE STANDARD

### Capitolo 10 - OAuth 2.0
- 10.1 Cos'è OAuth 2.0
- 10.2 OAuth è per autorizzazione, non autenticazione
- 10.3 Ruoli in OAuth 2.0
  - 10.3.1 Resource Owner
  - 10.3.2 Client
  - 10.3.3 Authorization Server
  - 10.3.4 Resource Server
- 10.4 Grant types (flussi di autorizzazione)
  - 10.4.1 Authorization Code
  - 10.4.2 Authorization Code + PKCE
  - 10.4.3 Implicit (deprecato)
  - 10.4.4 Resource Owner Password Credentials (sconsigliato)
  - 10.4.5 Client Credentials
  - 10.4.6 Device Authorization Grant
  - 10.4.7 Refresh Token
- 10.5 Scopes e permissions
- 10.6 Access tokens e Refresh tokens
- 10.7 PKCE (Proof Key for Code Exchange)
- 10.8 State parameter (CSRF protection)
- 10.9 Redirect URI validation
- 10.10 OAuth 2.1 (work in progress)
- 10.11 Vulnerabilità e best practices
- 10.12 Implementare un OAuth 2.0 provider
- 10.13 Integrare OAuth 2.0 client
- Esercizi pratici: implementare Authorization Code flow
- Domande di autovalutazione

### Capitolo 11 - OpenID Connect (OIDC)
- 11.1 OAuth 2.0 + Authentication = OIDC
- 11.2 ID Token (JWT)
- 11.3 Standard claims
- 11.4 UserInfo endpoint
- 11.5 Discovery e metadata
- 11.6 OIDC flows
  - 11.6.1 Authorization Code Flow
  - 11.6.2 Implicit Flow
  - 11.6.3 Hybrid Flow
- 11.7 Session management
- 11.8 Single Sign-On (SSO) con OIDC
- 11.9 Single Logout
- 11.10 Provider popolari
  - 11.10.1 Google
  - 11.10.2 Microsoft Azure AD
  - 11.10.3 Okta
  - 11.10.4 Auth0
  - 11.10.5 Keycloak (open source)
- 11.11 Implementare OIDC
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 12 - SAML 2.0
- 12.1 Cos'è SAML
- 12.2 SAML vs OAuth/OIDC
- 12.3 Componenti SAML
  - 12.3.1 Identity Provider (IdP)
  - 12.3.2 Service Provider (SP)
  - 12.3.3 User
- 12.4 Assertions SAML
- 12.5 SAML flows
  - 12.5.1 SP-initiated flow
  - 12.5.2 IdP-initiated flow
- 12.6 Bindings
  - 12.6.1 HTTP Redirect
  - 12.6.2 HTTP POST
- 12.7 Metadata SAML
- 12.8 Firma e crittografia
- 12.9 Single Sign-On con SAML
- 12.10 Single Logout
- 12.11 Configurare un IdP (Shibboleth, SimpleSAMLphp)
- 12.12 Integrare un SP
- 12.13 Vulnerabilità SAML
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 13 - Kerberos
- 13.1 Storia e scopo di Kerberos
- 13.2 Componenti
  - 13.2.1 Key Distribution Center (KDC)
  - 13.2.2 Authentication Server (AS)
  - 13.2.3 Ticket Granting Server (TGS)
  - 13.2.4 Client
  - 13.2.5 Service Server
- 13.3 Tickets e authenticators
- 13.4 Il protocollo Kerberos passo-passo
- 13.5 Realms e trust
- 13.6 Kerberos in Active Directory
- 13.7 Attacchi a Kerberos
  - 13.7.1 Golden Ticket
  - 13.7.2 Silver Ticket
  - 13.7.3 Pass-the-Ticket
  - 13.7.4 Kerberoasting
- 13.8 Mitigazioni
- Domande di autovalutazione

### Capitolo 14 - LDAP e Active Directory
- 14.1 LDAP (Lightweight Directory Access Protocol)
- 14.2 Struttura gerarchica (DIT)
- 14.3 DN, RDN, objectClass
- 14.4 LDAP bind (autenticazione)
- 14.5 Simple bind vs SASL
- 14.6 LDAPS (LDAP over SSL/TLS)
- 14.7 Active Directory
  - 14.7.1 Domain Controllers
  - 14.7.2 Organizational Units
  - 14.7.3 Group Policy
- 14.8 LDAP injection
- 14.9 Integrazione applicazioni con LDAP/AD
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 15 - RADIUS e TACACS+
- 15.1 RADIUS (Remote Authentication Dial-In User Service)
- 15.2 Architettura RADIUS
- 15.3 RADIUS Attributes
- 15.4 RADIUS Accounting
- 15.5 TACACS+ (Terminal Access Controller Access-Control System Plus)
- 15.6 RADIUS vs TACACS+
- 15.7 Casi d'uso: network devices, VPN, WiFi
- 15.8 FreeRADIUS
- Esercizi di configurazione
- Domande di autovalutazione

---

## PARTE IV - SINGLE SIGN-ON E IDENTITY FEDERATION

### Capitolo 16 - Single Sign-On (SSO)
- 16.1 Cos'è SSO e perché è utile
- 16.2 Vantaggi e svantaggi
- 16.3 SSO patterns
  - 16.3.1 Central Authentication Service (CAS)
  - 16.3.2 Cookie-based SSO
  - 16.3.3 Token-based SSO
- 16.4 Enterprise SSO
- 16.5 Social login (Google, Facebook, GitHub)
- 16.6 SSO e sicurezza
- 16.7 Session management in SSO
- 16.8 Single Logout (SLO)
- Domande di autovalutazione

### Capitolo 17 - Identity Federation
- 17.1 Cos'è la federation
- 17.2 Trust relationships
- 17.3 Federated Identity Management (FIM)
- 17.4 Cross-domain authentication
- 17.5 WS-Federation
- 17.6 Shibboleth
- 17.7 eduGAIN e federazioni accademiche
- 17.8 B2B e B2C scenarios
- Domande di autovalutazione

### Capitolo 18 - Identity as a Service (IDaaS)
- 18.1 Cloud-based identity management
- 18.2 Provider principali
  - 18.2.1 Okta
  - 18.2.2 Auth0
  - 18.2.3 Azure AD / Entra ID
  - 18.2.4 Google Cloud Identity
  - 18.2.5 AWS Cognito
  - 18.2.6 Ping Identity
  - 18.2.7 OneLogin
- 18.3 Vantaggi di IDaaS
- 18.4 Integrazione applicazioni
- 18.5 Provisioning e deprovisioning
- 18.6 Directory sync
- 18.7 Adaptive authentication
- 18.8 Considerazioni di sicurezza
- Esercizi: configurare Auth0 o Keycloak
- Domande di autovalutazione

---

## PARTE V - AUTENTICAZIONE DEI SERVIZI

### Capitolo 19 - Service-to-Service Authentication
- 19.1 Machine-to-machine (M2M) authentication
- 19.2 Service accounts
- 19.3 Client credentials flow (OAuth 2.0)
- 19.4 API keys per servizi
- 19.5 Problemi di rotazione
- Domande di autovalutazione

### Capitolo 20 - Mutual TLS (mTLS)
- 20.1 TLS unidirezionale vs bidirezionale
- 20.2 Client certificates
- 20.3 Certificate-based authentication
- 20.4 Configurare mTLS
  - 20.4.1 Nginx
  - 20.4.2 Apache
  - 20.4.3 Applicazioni
- 20.5 Certificate management su larga scala
- 20.6 mTLS nei microservizi
- 20.7 Service mesh (Istio, Linkerd)
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 21 - SPIFFE e SPIRE
- 21.1 Secure Production Identity Framework For Everyone
- 21.2 SPIFFE ID
- 21.3 SVID (SPIFFE Verifiable Identity Document)
- 21.4 SPIRE (SPIFFE Runtime Environment)
- 21.5 Workload attestation
- 21.6 Use cases: Kubernetes, microservices
- 21.7 Integrazione con service mesh
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 22 - Service Mesh Authentication
- 22.1 Cos'è un service mesh
- 22.2 Istio
  - 22.2.1 Citadel (ora istiod)
  - 22.2.2 Automatic mTLS
  - 22.2.3 Authentication policies
  - 22.2.4 Authorization policies
- 22.3 Linkerd
  - 22.3.1 Identity
  - 22.3.2 Automatic mTLS
- 22.4 Consul Connect
- 22.5 AWS App Mesh
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 23 - Secrets Management per Servizi
- 23.1 Il problema dei secrets hardcoded
- 23.2 Variabili d'ambiente (limitazioni)
- 23.3 HashiCorp Vault
  - 23.3.1 Architettura
  - 23.3.2 Secrets engines
  - 23.3.3 Dynamic secrets
  - 23.3.4 Authentication methods
  - 23.3.5 Policies
  - 23.3.6 Seal/Unseal
- 23.4 AWS Secrets Manager
- 23.5 Azure Key Vault
- 23.6 Google Secret Manager
- 23.7 Kubernetes Secrets
  - 23.7.1 Limitazioni
  - 23.7.2 Encryption at rest
  - 23.7.3 External Secrets Operator
  - 23.7.4 Sealed Secrets
- 23.8 SOPS (Secrets OPerationS)
- 23.9 Secret rotation automatica
- 23.10 Secret zero problem
- Esercizi pratici: configurare Vault
- Domande di autovalutazione

---

## PARTE VI - AUTENTICAZIONE BIOMETRICA

### Capitolo 24 - Fondamenti di Biometria
- 24.1 Tipi di biometria
  - 24.1.1 Fingerprint
  - 24.1.2 Facial recognition
  - 24.1.3 Iris/Retina scan
  - 24.1.4 Voice recognition
  - 24.1.5 Behavioral biometrics
- 24.2 False Acceptance Rate (FAR) e False Rejection Rate (FRR)
- 24.3 Biometric templates
- 24.4 Liveness detection
- 24.5 Privacy concerns
- 24.6 GDPR e dati biometrici
- Domande di autovalutazione

### Capitolo 25 - Implementazione Biometrica
- 25.1 Windows Hello
- 25.2 Touch ID e Face ID (Apple)
- 25.3 Android Biometric APIs
- 25.4 Biometric authentication nei browser (WebAuthn)
- 25.5 Biometrics in mobile apps
- 25.6 Server-side vs device-side biometrics
- 25.7 Attacchi alla biometria
- 25.8 Multimodal biometrics
- Esercizi pratici
- Domande di autovalutazione

---

## PARTE VII - AUTENTICAZIONE IN CONTESTI SPECIFICI

### Capitolo 26 - Autenticazione Mobile
- 26.1 Sfide specifiche del mobile
- 26.2 OAuth 2.0 for Native Apps (RFC 8252)
- 26.3 App-to-app authorization
- 26.4 Deep linking e custom URL schemes
- 26.5 Universal Links (iOS) e App Links (Android)
- 26.6 Token storage su mobile
  - 26.6.1 iOS Keychain
  - 26.6.2 Android Keystore
- 26.7 Biometrics su mobile
- 26.8 Device binding
- 26.9 Certificate pinning
- 26.10 Jailbreak/Root detection
- Esercizi pratici: app mobile con OAuth
- Domande di autovalutazione

### Capitolo 27 - Autenticazione IoT
- 27.1 Constraint devices
- 27.2 Lightweight protocols
  - 27.2.1 MQTT authentication
  - 27.2.2 CoAP authentication
- 27.3 Pre-shared keys
- 27.4 Certificate-based authentication
- 27.5 Device provisioning
- 27.6 Firmware signing
- 27.7 Secure boot
- 27.8 OTA updates authentication
- 27.9 AWS IoT Core authentication
- 27.10 Azure IoT Hub authentication
- Domande di autovalutazione

### Capitolo 28 - Autenticazione in Blockchain
- 28.1 Wallet authentication
- 28.2 Public/private key pairs
- 28.3 Signing transactions
- 28.4 Web3 authentication
- 28.5 MetaMask e wallet connection
- 28.6 Sign-In with Ethereum
- 28.7 Decentralized Identity (DID)
- 28.8 Self-Sovereign Identity (SSI)
- Domande di autovalutazione

### Capitolo 29 - Autenticazione nei Container e Orchestrators
- 29.1 Docker Registry authentication
- 29.2 Kubernetes authentication
  - 29.2.1 Service accounts
  - 29.2.2 User accounts
  - 29.2.3 Authentication strategies
  - 29.2.4 X509 client certificates
  - 29.2.5 Bearer tokens
  - 29.2.6 OpenID Connect
- 29.3 RBAC (Role-Based Access Control)
- 29.4 Pod identity
- 29.5 Workload Identity (GKE)
- 29.6 IAM Roles for Service Accounts (EKS)
- 29.7 Azure AD Workload Identity
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 30 - Autenticazione SSH
- 30.1 Password-based authentication (sconsigliata)
- 30.2 Public key authentication
- 30.3 Generare chiavi SSH
- 30.4 ssh-agent
- 30.5 ssh-keygen best practices
- 30.6 SSH certificates
- 30.7 SSH Certificate Authority
- 30.8 Bastion hosts e jump servers
- 30.9 SSH hardening
- 30.10 Teleport per SSH access management
- Esercizi pratici
- Domande di autovalutazione

---

## PARTE VIII - GESTIONE DELL'IDENTITÀ

### Capitolo 31 - Identity and Access Management (IAM)
- 31.1 Cos'è IAM
- 31.2 Identity lifecycle management
  - 31.2.1 Provisioning
  - 31.2.2 Maintenance
  - 31.2.3 Deprovisioning
- 31.3 User directories
- 31.4 Role-Based Access Control (RBAC)
- 31.5 Attribute-Based Access Control (ABAC)
- 31.6 Policy-Based Access Control (PBAC)
- 31.7 Just-In-Time (JIT) access
- 31.8 Privileged Access Management (PAM)
- 31.9 Identity Governance and Administration (IGA)
- Domande di autovalutazione

### Capitolo 32 - Cloud IAM
- 32.1 AWS IAM
  - 32.1.1 Users, groups, roles
  - 32.1.2 Policies
  - 32.1.3 MFA enforcement
  - 32.1.4 IAM Identity Center (AWS SSO)
  - 32.1.5 AssumeRole
  - 32.1.6 Cross-account access
- 32.2 Azure IAM
  - 32.2.1 Azure AD (Entra ID)
  - 32.2.2 Managed identities
  - 32.2.3 RBAC
  - 32.2.4 Conditional Access
- 32.3 Google Cloud IAM
  - 32.3.1 Service accounts
  - 32.3.2 IAM policies
  - 32.3.3 Workload Identity
- 32.4 Multi-cloud IAM
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 33 - Provisioning e SCIM
- 33.1 System for Cross-domain Identity Management
- 33.2 SCIM 2.0 protocol
- 33.3 User provisioning automatico
- 33.4 Deprovisionamento
- 33.5 Group management
- 33.6 SCIM providers (Okta, Azure AD)
- 33.7 Implementare SCIM server/client
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 34 - Directory Services
- 34.1 Centralizzazione dell'identità
- 34.2 LDAP (approfondimento)
- 34.3 Active Directory
- 34.4 Azure AD / Entra ID
- 34.5 Google Workspace Directory
- 34.6 JumpCloud
- 34.7 FreeIPA
- 34.8 OpenLDAP
- 34.9 Directory synchronization
- Domande di autovalutazione

---

## PARTE IX - AUTENTICAZIONE AVANZATA E PASSWORDLESS

### Capitolo 35 - Passwordless Authentication
- 35.1 Il futuro senza password
- 35.2 Magic links via email
- 35.3 SMS OTP (limitazioni)
- 35.4 Push notifications
- 35.5 Biometrics
- 35.6 FIDO2/WebAuthn (approfondimento)
- 35.7 Passkeys
  - 35.7.1 Apple Passkeys
  - 35.7.2 Google Passkeys
  - 35.7.3 Microsoft Passkeys
- 35.8 Passwordless con hardware tokens
- 35.9 Implementazione passwordless
- 35.10 Adozione e user experience
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 36 - Risk-Based Authentication
- 36.1 Adaptive authentication
- 36.2 Context-aware authentication
- 36.3 Fattori di rischio
  - 36.3.1 Geolocation
  - 36.3.2 Device fingerprinting
  - 36.3.3 IP reputation
  - 36.3.4 Time of day
  - 36.3.5 Impossible travel
  - 36.3.6 User behavior analytics
- 36.4 Risk scoring
- 36.5 Step-up authentication
- 36.6 Machine learning per fraud detection
- 36.7 Implementare risk-based auth
- Domande di autovalutazione

### Capitolo 37 - Continuous Authentication
- 37.1 Beyond initial login
- 37.2 Behavioral biometrics
  - 37.2.1 Keystroke dynamics
  - 37.2.2 Mouse movements
  - 37.2.3 Gait analysis
- 37.3 Session monitoring
- 37.4 Anomaly detection
- 37.5 Zero Standing Privileges
- 37.6 Use cases enterprise
- Domande di autovalutazione

### Capitolo 38 - Decentralized Identity
- 38.1 Self-Sovereign Identity (SSI)
- 38.2 Decentralized Identifiers (DIDs)
- 38.3 Verifiable Credentials (VCs)
- 38.4 W3C standards
- 38.5 Blockchain e identity
- 38.6 Identity wallets
- 38.7 Use cases: educazione, sanità, finanza
- 38.8 Microsoft ION
- 38.9 Sovrin Network
- 38.10 Sfide e adozione
- Domande di autovalutazione

---

## PARTE X - SICUREZZA E COMPLIANCE

### Capitolo 39 - Threat Modeling per l'Autenticazione
- 39.1 STRIDE model
- 39.2 Attack trees
- 39.3 Scenari di attacco comuni
  - 39.3.1 Credential theft
  - 39.3.2 Account takeover
  - 39.3.3 Session hijacking
  - 39.3.4 Replay attacks
  - 39.3.5 Brute force
- 39.4 Mitigazioni
- 39.5 Defense in depth
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 40 - Account Security
- 40.1 Account enumeration prevention
- 40.2 Rate limiting e throttling
- 40.3 CAPTCHA e reCAPTCHA
- 40.4 Account lockout policies
- 40.5 Suspicious activity detection
- 40.6 Notification di login
- 40.7 Concurrent session management
- 40.8 Device management
- 40.9 Revoke access remotely
- Domande di autovalutazione

### Capitolo 41 - Logging e Auditing
- 41.1 Authentication logs
- 41.2 Cosa loggare
  - 41.2.1 Login attempts (success/failure)
  - 41.2.2 Password changes
  - 41.2.3 MFA events
  - 41.2.4 Permission changes
  - 41.2.5 Anomalies
- 41.3 Log retention policies
- 41.4 SIEM integration
- 41.5 Compliance requirements (GDPR, SOC2, PCI-DSS)
- 41.6 Audit trails
- 41.7 Forensics e incident response
- Esercizi pratici
- Domande di autovalutazione

### Capitolo 42 - Privacy e GDPR
- 42.1 Dati personali e autenticazione
- 42.2 Minimizzazione dei dati
- 42.3 Consenso
- 42.4 Right to be forgotten
- 42.5 Data portability
- 42.6 Privacy by design
- 42.7 Data Protection Impact Assessment (DPIA)
- 42.8 Biometric data e GDPR
- Domande di autovalutazione

### Capitolo 43 - Compliance e Standard
- 43.1 NIST Digital Identity Guidelines (SP 800-63)
  - 43.1.1 Identity Proofing (IAL)
  - 43.1.2 Authentication (AAL)
  - 43.1.3 Federation (FAL)
- 43.2 PCI-DSS requirements
- 43.3 SOC 2 Type II
- 43.4 ISO 27001
- 43.5 HIPAA
- 43.6 FedRAMP
- 43.7 Industry-specific requirements
- Checklist di compliance
- Domande di autovalutazione

---

## PARTE XI - IMPLEMENTAZIONE E BEST PRACTICES

### Capitolo 44 - Architetture di Autenticazione
- 44.1 Monolithic vs Microservices
- 44.2 API Gateway e authentication
- 44.3 Backend for Frontend (BFF) pattern
- 44.4 Token relay pattern
- 44.5 Sidecar pattern
- 44.6 Strangler Fig per migration
- 44.7 High availability
- 44.8 Geographic distribution
- Casi studio
- Domande di autovalutazione

### Capitolo 45 - Implementare un Identity Provider
- 45.1 Requisiti funzionali
- 45.2 Database schema
- 45.3 User registration
- 45.4 Login flow
- 45.5 Password reset
- 45.6 Email verification
- 45.7 MFA enrollment
- 45.8 OAuth 2.0 endpoints
- 45.9 OIDC support
- 45.10 Admin panel
- 45.11 Scalability considerations
- Progetto pratico completo
- Domande di autovalutazione

### Capitolo 46 - Testing dell'Autenticazione
- 46.1 Unit testing
- 46.2 Integration testing
- 46.3 End-to-end testing
- 46.4 Security testing
  - 46.4.1 Penetration testing
  - 46.4.2 Vulnerability scanning
- 46.5 Load testing
- 46.6 Chaos engineering
- 46.7 Bug bounty programs
- Strumenti e framework
- Domande di autovalutazione

### Capitolo 47 - User Experience e Autenticazione
- 47.1 Balance sicurezza vs usabilità
- 47.2 Progressive profiling
- 47.3 Social login UX
- 47.4 Error messages sicuri
- 47.5 Onboarding flows
- 47.6 Mobile-first authentication
- 47.7 Accessibilità
- 47.8 Localizzazione
- 47.9 Metrics e analytics
- Domande di autovalutazione

### Capitolo 48 - Migration e Legacy Systems
- 48.1 Strategie di migrazione
- 48.2 Dual-run approach
- 48.3 Password migration senza downtime
- 48.4 Legacy protocol support
- 48.5 Gradual rollout
- 48.6 Rollback plans
- 48.7 Communication con gli utenti
- Casi studio di migrazione
- Domande di autovalutazione

---

## PARTE XII - CASI D'USO E SCENARI REALI

### Capitolo 49 - Enterprise SSO
- 49.1 Scenario: multinazionale con migliaia di dipendenti
- 49.2 Active Directory + Azure AD
- 49.3 SAML per SaaS applications
- 49.4 SCIM provisioning
- 49.5 Conditional Access policies
- 49.6 Privileged Identity Management
- Caso studio completo
- Domande di autovalutazione

### Capitolo 50 - SaaS Multi-Tenant Authentication
- 50.1 B2B SaaS challenges
- 50.2 Tenant isolation
- 50.3 Custom domain SSO
- 50.4 Just-In-Time provisioning
- 50.5 Organization switching
- 50.6 Billing integration
- Architettura di riferimento
- Domande di autovalutazione

### Capitolo 51 - Consumer Applications
- 51.1 B2C authentication
- 51.2 Social login
- 51.3 Phone number authentication
- 51.4 Progressive profiling
- 51.5 Guest checkout
- 51.6 Scalabilità globale
- 51.7 Privacy regulations
- Esempi: e-commerce, streaming
- Domande di autovalutazione

### Capitolo 52 - Healthcare e Finance
- 52.1 Regulatory requirements
- 52.2 HIPAA compliance
- 52.3 PSD2 Strong Customer Authentication
- 52.4 Medical device authentication
- 52.5 Patient portals
- 52.6 Banking applications
- 52.7 Transaction signing
- Casi studio
- Domande di autovalutazione

---

## APPENDICI

### Appendice A - Protocolli e RFC
- A.1 RFC rilevanti
- A.2 Standard W3C
- A.3 IETF drafts
- A.4 FIDO specifications

### Appendice B - Tools e Librerie
- B.1 Librerie per linguaggio
  - B.1.1 Python
  - B.1.2 JavaScript/Node.js
  - B.1.3 Java
  - B.1.4 C# / .NET
  - B.1.5 Go
  - B.1.6 PHP
- B.2 Identity providers open source
  - B.2.1 Keycloak
  - B.2.2 ORY
  - B.2.3 Authelia
  - B.2.4 Gluu
- B.3 Testing tools
- B.4 Security scanners

### Appendice C - Checklist di Sicurezza
- C.1 Password security checklist
- C.2 OAuth 2.0 implementation checklist
- C.3 OIDC implementation checklist
- C.4 SAML security checklist
- C.5 API authentication checklist
- C.6 Mobile app authentication checklist

### Appendice D - Glossario
- Termini tecnici dalla A alla Z

### Appendice E - Laboratorio Pratico
- E.1 Setup ambiente di sviluppo
- E.2 Progetti pratici guidati
  - E.2.1 Implementare login con JWT
  - E.2.2 Integrare OAuth 2.0
  - E.2.3 Configurare Keycloak
  - E.2.4 Implementare MFA
  - E.2.5 Creare un passwordless flow
- E.3 Esercizi avanzati

### Appendice F - Risorse Online
- F.1 Documentazione ufficiale
- F.2 Blog e articoli
- F.3 Video e corsi
- F.4 Community e forum
- F.5 Conferenze e eventi

---

## Risposte alle Domande di Autovalutazione

### Capitolo 1 - Risposte
### Capitolo 2 - Risposte
### ...
### Capitolo 52 - Risposte

---

## Bibliografia

## Indice Analitico