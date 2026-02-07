# Lab 9: VPN IPsec Site-to-Site con Router Cisco in Packet Tracer

## Obiettivi del Laboratorio

Al termine di questo lab sarai in grado di:
- Configurare VPN IPsec site-to-site su router Cisco IOS
- Implementare IKEv1/IKEv2 con pre-shared key
- Configurare crypto map e access-list per traffico interessante
- Verificare i tunnel IPsec con comandi diagnostici Cisco
- Troubleshooting di problemi comuni VPN IPsec
- Salvare e caricare configurazioni in Packet Tracer

---

## Prerequisiti

### Software
- **Cisco Packet Tracer** (versione 8.0 o superiore)
  - Download: https://www.netacad.com/courses/packet-tracer
  - Account Cisco Networking Academy richiesto (gratuito)

### Conoscenze
- Configurazione base router Cisco (CLI)
- Concetti routing statico/dinamico
- NAT e PAT
- Fondamenti IPsec (AH, ESP, IKE)

### Tempo Stimato
- Setup topology: 20 minuti
- Configurazione VPN: 40 minuti
- Testing e troubleshooting: 30 minuti
- **Totale: ~90 minuti**

---

## Topologia di Rete

```
┌─────────────────────────────────────────────────────────────────┐
│                          INTERNET                               │
│                     (Simulato - Cloud PT)                       │
└────────────┬────────────────────────────────┬───────────────────┘
             │                                │
        200.1.1.1/30                    200.2.2.1/30
             │                                │
    ┌────────▼────────┐              ┌────────▼────────┐
    │   Router-HQ     │              │  Router-Branch  │
    │   (R1)          │══════════════│      (R2)       │
    │                 │   IPsec VPN  │                 │
    └────────┬────────┘              └────────┬────────┘
             │                                │
      192.168.1.1/24                   192.168.2.1/24
             │                                │
    ┌────────▼────────┐              ┌────────▼────────┐
    │   Switch-HQ     │              │  Switch-Branch  │
    └────────┬────────┘              └────────┬────────┘
             │                                │
       ┌─────┴─────┐                    ┌─────┴─────┐
       │           │                    │           │
    ┌──▼──┐    ┌──▼──┐              ┌──▼──┐    ┌──▼──┐
    │ PC1 │    │ PC2 │              │ PC3 │    │ PC4 │
    └─────┘    └─────┘              └─────┘    └─────┘
  .10/.24    .20/.24              .10/.24    .20/.24
```

### Piano di Indirizzamento

| Dispositivo | Interfaccia | Indirizzo IP | Subnet Mask | Gateway |
|-------------|-------------|--------------|-------------|---------|
| **Router-HQ (R1)** | Gi0/0 (WAN) | 200.1.1.1 | 255.255.255.252 | - |
| | Gi0/1 (LAN) | 192.168.1.1 | 255.255.255.0 | - |
| **Router-Branch (R2)** | Gi0/0 (WAN) | 200.2.2.1 | 255.255.255.252 | - |
| | Gi0/1 (LAN) | 192.168.2.1 | 255.255.255.0 | - |
| **PC1** | Eth | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 |
| **PC2** | Eth | 192.168.1.20 | 255.255.255.0 | 192.168.1.1 |
| **PC3** | Eth | 192.168.2.10 | 255.255.255.0 | 192.168.2.1 |
| **PC4** | Eth | 192.168.2.20 | 255.255.255.0 | 192.168.2.1 |
| **Internet Cloud** | - | Simulato | - | - |

---

## Parte 1: Creazione Topologia in Packet Tracer

### Step 1.1: Posizionamento Dispositivi

1. Apri Cisco Packet Tracer
2. Aggiungi dispositivi dalla barra in basso:
   - **2x Router 2911** (o 4321 se disponibile)
     - Category: Network Devices → Routers → 2911
   - **2x Switch 2960** (o qualsiasi Layer 2)
     - Category: Network Devices → Switches → 2960
   - **4x PC**
     - Category: End Devices → PC
   - **1x Cloud-PT** (per simulare Internet)
     - Category: Network Devices → WAN Emulation → Cloud-PT

3. Rinomina dispositivi:
   - Router1 → `Router-HQ`
   - Router2 → `Router-Branch`
   - Switch1 → `Switch-HQ`
   - Switch2 → `Switch-Branch`
   - PC-PT → `PC1`, `PC2`, `PC3`, `PC4`

### Step 1.2: Cablaggio

Utilizza cavi **Copper Straight-Through** per tutte le connessioni:

**Site HQ:**
```
Router-HQ Gi0/0 ──→ Cloud-PT Ethernet0
Router-HQ Gi0/1 ──→ Switch-HQ Gi0/1
Switch-HQ Fa0/1  ──→ PC1 FastEthernet
Switch-HQ Fa0/2  ──→ PC2 FastEthernet
```

**Site Branch:**
```
Router-Branch Gi0/0 ──→ Cloud-PT Ethernet1
Router-Branch Gi0/1 ──→ Switch-Branch Gi0/1
Switch-Branch Fa0/1  ──→ PC3 FastEthernet
Switch-Branch Fa0/2  ──→ PC4 FastEthernet
```

### Step 1.3: Configurazione Cloud (Simulazione Internet)

1. Click su **Cloud-PT**
2. Vai al tab **Config**
3. Nella sezione **DSL**, configura:
   - **Ethernet0**: 200.1.1.2
   - **Ethernet1**: 200.2.2.2

---

## Parte 2: Configurazione Base Router

### Step 2.1: Router-HQ (R1)

Entra in modalità CLI del router (click su Router-HQ → CLI):

```cisco
! Passaggio a modalità privilegiata (EXEC privilegiato)
! Questo livello permette l'accesso completo ai comandi di configurazione
enable

! Entra in modalità di configurazione globale
! Tutti i comandi di configurazione devono essere eseguiti da qui
configure terminal

!===============================================
! SEZIONE 1: Configurazione Identità e Sicurezza
!===============================================

! Imposta hostname del router (apparirà nel prompt)
! Utile per identificare il dispositivo nella rete
hostname Router-HQ

! Password cifrata per modalità enable (EXEC privilegiato)
! "secret" usa hash MD5, più sicuro di "password"
! In produzione: usa password complesse!
enable secret cisco123

! Configurazione accesso console (porta seriale/USB)
! L'accesso console è quello fisico diretto al router
line console 0
 password cisco          ! Password in chiaro (use secret in production)
 login                  ! Richiedi autenticazione
 logging synchronous    ! Evita che i log interrompano la digitazione
 exit

! Configurazione accesso remoto (Telnet/SSH)
! Abilita gestione da rete (line vty = virtual terminal)
line vty 0 4            ! 5 sessioni simultanee (0-4)
 password cisco
 login
 transport input ssh telnet  ! Permetti sia SSH che Telnet
                             ! In produzione: solo SSH!
exit

!===============================================
! SEZIONE 2: Configurazione Interfacce
!===============================================

! Interfaccia WAN (verso Internet/Cloud)
! Questa interfaccia si connette al "mondo esterno"
interface GigabitEthernet0/0
 ! Assegna IP pubblico (simulato) con subnet /30
 ! /30 = 255.255.255.252 = 4 IP tot (2 usabili + network + broadcast)
 ip address 200.1.1.1 255.255.255.252
 
 ! Attiva l'interfaccia (default è "shutdown" per sicurezza)
 ! IMPORTANTE: senza questo l'interfaccia resta DOWN
 no shutdown
 
 ! Nota: su questa interfaccia applicheremo la crypto map
 exit

! Interfaccia LAN (verso rete interna)
! Questa interfaccia connette la LAN aziendale
interface GigabitEthernet0/1
 ! Assegna IP privato con subnet /24 (254 host utilizzabili)
 ip address 192.168.1.1 255.255.255.0
 
 ! Questo IP sarà il default gateway per i PC della LAN
 no shutdown
 exit

!===============================================
! SEZIONE 3: Routing
!===============================================

! Route statica verso la rete remota Branch (192.168.2.0/24)
! Formato: ip route <rete-destinazione> <subnet-mask> <next-hop>
! Next-hop 200.1.1.2 = Cloud (simula Internet routing)
! 
! IMPORTANTE: Questa route dice "per raggiungere 192.168.2.0/24,
!             inoltra pacchetti a 200.1.1.2"
! Il traffico che matcha questa route E l'ACL 100 verrà cifrato!
ip route 192.168.2.0 255.255.255.0 200.1.1.2

!===============================================
! SEZIONE 4: Salvataggio
!===============================================

! Esce da config mode e torna a EXEC privilegiato
end

! Salva la running-config nella startup-config
! FONDAMENTALE: senza questo, al reboot si perde tutto!
! write memory = write mem = copy run start (equivalenti)
write memory
```

**Spiegazione aggiuntiva:**
- **enable secret vs password**: `secret` usa hash MD5, mentre `password` memorizza in chiaro (visibile con `show run`)
- **logging synchronous**: evita che messaggi di log (es: `%LINEPROTO-5-UPDOWN`) interrompano la digitazione
- **no shutdown**: comando CRITICO spesso dimenticato; senza, l'interfaccia resta admin down
- **IP /30 per WAN**: best practice per link point-to-point (spreca solo 2 IP)
- **Route statica**: alternativa a protocolli dinamici (OSPF/EIGRP); adatta per topologie semplici

### Step 2.2: Router-Branch (R2)

**Configurazione speculare al Router-HQ, ma con IP diversi:**

```cisco
enable
configure terminal

!===============================================
! Configurazione Router-Branch (identica logica di HQ)
!===============================================

hostname Router-Branch  ! Nome identifica la sede Branch
enable secret cisco123  ! DEVE essere uguale su tutti i router aziendali

line console 0
 password cisco
 login
 logging synchronous
 exit

line vty 0 4
 password cisco
 login
 transport input ssh telnet
 exit

!===============================================
! Interfacce - NOTA DIFFERENZE IP rispetto a HQ
!===============================================

! Interfaccia WAN
interface GigabitEthernet0/0
 ! IP pubblico Branch: 200.2.2.1/30 (diverso da HQ!)
 ! Questo IP sarà il "peer" nella configurazione crypto map di HQ
 ip address 200.2.2.1 255.255.255.252
 no shutdown
 exit

! Interfaccia LAN
interface GigabitEthernet0/1
 ! Rete LAN Branch: 192.168.2.0/24 (subnet diversa da HQ)
 ip address 192.168.2.1 255.255.255.0
 no shutdown
 exit

!===============================================
! Routing verso HQ (speculare)
!===============================================

! Route statica verso la rete remota HQ (192.168.1.0/24)
! Next-hop 200.2.2.2 = Cloud (simula route verso HQ via Internet)
! Speculare alla route configurata su HQ
ip route 192.168.1.0 255.255.255.0 200.2.2.2

end
write memory
```

**Concetto chiave: Simmetria della configurazione**
- Router-HQ punta a 192.168.2.0/24 via 200.1.1.2
- Router-Branch punta a 192.168.1.0/24 via 200.2.2.2
- Le configurazioni VPN devono essere speculari ma NON identiche
- Gli IP WAN (200.1.1.1 e 200.2.2.1) saranno i "peer" nelle crypto map

### Step 2.3: Configurazione PC

Per ogni PC, vai in **Desktop → IP Configuration**:

**PC1:**
- IP Address: `192.168.1.10`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.1.1`

**PC2:**
- IP Address: `192.168.1.20`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.1.1`

**PC3:**
- IP Address: `192.168.2.10`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.2.1`

**PC4:**
- IP Address: `192.168.2.20`
- Subnet Mask: `255.255.255.0`
- Default Gateway: `192.168.2.1`

### Step 2.4: Verifica Connettività Base

**IMPORTANTE: Prima di configurare la VPN, verifica che il routing base funzioni!**

Questo passaggio è FONDAMENTALE per il troubleshooting successivo:
- Se la VPN non funziona, saprai che il problema è nella config VPN, non nel routing
- Debugging regola d'oro: "prima fa funzionare il ping chiaro, poi cifra"

**Da PC1 (Desktop → Command Prompt):**
```bash
# Test 1: Gateway locale (verifica config IP e default gateway PC)
ping 192.168.1.1
# Risultato atteso: Reply from 192.168.1.1
# Se FALLISCE: controlla IP/gateway/subnet mask del PC1

# Test 2: Interfaccia WAN del router locale
ping 200.1.1.1
# Risultato atteso: Reply from 200.1.1.1
# Se FALLISCE: interfaccia Gi0/0 router potrebbe essere DOWN

# Test 3: Router remoto (attraverso Cloud/Internet)
ping 200.2.2.1
# Risultato atteso: Reply from 200.2.2.1
# Se FALLISCE: 
#   - Verifica config Cloud (IP 200.1.1.2 e 200.2.2.1)
#   - Verifica cablaggio router → cloud
#   - Esegui 'show ip route' sul router per vedere routing table

# Test 4: PC nella rete remota (end-to-end NON CIFRATO)
ping 192.168.2.10
# Risultato atteso: Reply from 192.168.2.10
# Questo traffico viaggia IN CHIARO (nessuna VPN ancora)
# Se FALLISCE:
#   - Controlla route statiche su entrambi i router
#   - Verifica che PC3 sia configurato correttamente
#   - Usa tracert per vedere il percorso
```

**Comando diagnostico sui router:**
```cisco
! Visualizza routing table
Router-HQ# show ip route
! Cerca la riga: S    192.168.2.0/24 [1/0] via 200.1.1.2
! "S" = static route, [1/0] = AD/metric

! Verifica stato interfacce
Router-HQ# show ip interface brief
! Tutte le interfacce usate devono mostrare Status=up, Protocol=up
! Se vedi "administratively down" → manca "no shutdown"

! Testa ping dal router stesso
Router-HQ# ping 200.2.2.1
! Deve funzionare (raggiungibilità WAN layer 3)

Router-HQ# ping 192.168.2.10 source 192.168.1.1
! Simula traffico dal PC (source IP = LAN)
```

> **Checkpoint Critico**: NON procedere alla configurazione VPN finché TUTTI questi ping non funzionano!
> 
> **Nota Sicurezza**: In questo momento, il traffico tra le LAN viaggia in CHIARO su Internet (simulato). Usiamo `tcpdump` o Wireshark (simulation mode) vedresti i dati non cifrati. La VPN risolverà questo problema.

---

## Parte 3: Configurazione VPN IPsec (IKEv1)

### Step 3.1: Configurazione ISAKMP Policy (Phase 1)

**Cos'è la Phase 1 (IKE Phase 1)?**
La fase 1 stabilisce un tunnel sicuro ISAKMP SA (Security Association) tra i due router.
Questo tunnel serve SOLO per negoziare la Phase 2 (dati utente).
- **Main Mode**: 6 messaggi, identità protetta (default)
- **Aggressive Mode**: 3 messaggi, più veloce ma identità in chiaro

**Router-HQ:**
```cisco
configure terminal

!===============================================
! ISAKMP POLICY - Phase 1 Configuration
!===============================================
! Definisce i parametri per negoziare il tunnel di controllo IKE
! I parametri DEVONO combaciare tra HQ e Branch!

! Crea policy con priorità 10 (numeri più bassi = priorità alta)
! Se un peer propone policy 10, 20, 30, si prova prima la 10
crypto isakmp policy 10
 
 ! --------------------------------------------------
 ! ENCRYPTION: algoritmo di cifratura simmetrica
 ! --------------------------------------------------
 ! aes 256 = AES con chiave 256-bit (molto sicuro)
 ! Alternative: aes 192, aes (128), 3des, des
 ! Raccomandazione: AES 256 per sicurezza massima
 encryption aes 256
 
 ! --------------------------------------------------
 ! AUTHENTICATION: metodo di autenticazione peer
 ! --------------------------------------------------
 ! pre-share = Pre-Shared Key (password condivisa)
 ! Alternative: rsa-sig (certificati digitali)
 ! In produzione: preferire certificati per scalabilità
 authentication pre-share
 
 ! --------------------------------------------------
 ! HASH: algoritmo per integrità e autenticazione
 ! --------------------------------------------------
 ! sha256 = SHA-2 con output 256-bit (robusto)
 ! Alternative: sha384, sha512, sha (SHA-1 deprecated), md5 (insicuro!)
 ! SHA-1 e MD5 sono vulnerabili, NON usare in produzione!
 hash sha256
 
 ! --------------------------------------------------
 ! DIFFIE-HELLMAN GROUP: per key exchange
 ! --------------------------------------------------
 ! group 5 = 1536-bit modulus (bilanciato sicurezza/performance)
 ! Alternative:
 !   group 1 = 768-bit (INSICURO, deprecato)
 !   group 2 = 1024-bit (deboluccio)
 !   group 14 = 2048-bit (raccomandato oggi)
 !   group 15/16 = 3072/4096-bit (massima sicurezza, lento)
 ! Nota: DH non cifra dati, genera chiavi condivise sicure
 group 5
 
 ! --------------------------------------------------
 ! LIFETIME: durata SA prima di rinegoziazione
 ! --------------------------------------------------
 ! 86400 secondi = 24 ore
 ! Dopo questo tempo, Phase 1 viene rinegoziata automaticamente
 ! Valori tipici: 86400 (1 giorno) o 28800 (8 ore)
 ! Trade-off: lifetime lungo = meno overhead, ma chiavi "vecchie"
 lifetime 86400
 
 exit

!===============================================
! PRE-SHARED KEY CONFIGURATION
!===============================================
! Definisce la password condivisa per autenticazione
! FONDAMENTALE: deve essere IDENTICA su entrambi i router!

! Sintassi: crypto isakmp key <password> address <ip-peer>
! <ip-peer> = IP WAN del router remoto (NON IP LAN!)
crypto isakmp key VPN_Secret_2024 address 200.2.2.1

! NOTA SICUREZZA:
! - La key è CASE-SENSITIVE: "Secret" ≠ "secret"
! - Visibile in chiaro in 'show run' (problema!)
! - In produzione: usare key più lunghe (>20 caratteri)
! - Best practice: usare certificati X.509 invece di PSK
```

**Spiegazione dettagliata parametri:**

| Parametro | Significato | Ruolo in Phase 1 |
|-----------|-------------|------------------|
| **encryption** | Cifra i messaggi IKE | Protegge la negoziazione stessa |
| **hash** | HMAC per integrità | Previene tampering dei messaggi |
| **authentication** | Come verificare identità peer | PSK (password) o RSA (certificato) |
| **group** | Dimensione modulo DH | Più grande = più sicuro ma lento |
| **lifetime** | Durata SA (secondi) | Dopo scadenza, automatico renegotiate |

**Processo di negoziazione Phase 1 (Main Mode):**
1. **Message 1-2**: Proposta algoritmi (encryption, hash, DH group)
2. **Message 3-4**: Scambio Diffie-Hellman (genera chiave condivisa)
3. **Message 5-6**: Autenticazione con pre-shared key (protetta da chiave DH)
4. **Risultato**: ISAKMP SA stabilita (tunnel di controllo sicuro)

**Router-Branch:**
```cisco
configure terminal

! IDENTICA policy di HQ (i parametri DEVONO combaciare!)
crypto isakmp policy 10
 encryption aes 256
 authentication pre-share
 hash sha256
 group 5
 lifetime 86400
 exit

! Pre-shared key: STESSA password, ma address punta a HQ
! Nota: l'address specifica con CHI usare questa key
crypto isakmp key VPN_Secret_2024 address 200.1.1.1
!                                          ^
!                                          |
!                                     IP WAN di HQ
```

**Test mentale**: Se i parametri non combaciano:
- HQ ha `encryption aes 256`, Branch ha `encryption 3des` → **Negoziazione FALLISCE**
- Soluzione: definire più policy con priorità diverse per fallback

### Step 3.2: Configurazione IPsec Transform Set (Phase 2)

Il transform set definisce come cifrare i dati utente.

**Router-HQ:**
```cisco
! Transform Set
crypto ipsec transform-set VPN-SET esp-aes 256 esp-sha256-hmac
 mode tunnel
 exit
```

**Router-Branch:**
```cisco
crypto ipsec transform-set VPN-SET esp-aes 256 esp-sha256-hmac
 mode tunnel
 exit
```

**Spiegazione:**
- **esp-aes 256**: crittografia ESP con AES-256
- **esp-sha256-hmac**: autenticazione/integrità con SHA-256 HMAC
- **mode tunnel**: incapsula tutto il pacchetto IP (vs transport mode)

### Step 3.3: Definizione Traffico Interessante (ACL)

**Cos'è il "Traffico Interessante" (Interesting Traffic)?**
In IPsec Cisco, una Access Control List (ACL) definisce quale traffico "innesca" e viene cifrato dal tunnel VPN.
- Traffico che matcha l'ACL = cifrato (passa per tunnel IPsec)
- Traffico che non matcha = instradato normalmente (in chiaro!)

**CONCETTO CRITICO: L'ACL NON è un firewall qui!**
- In questo contesto, l'ACL "match address" identifica traffico da cifrare
- Non blocca né permette traffico (quello lo fa il firewall/security-policy)
- È puramente un "selettore" di traffico

**Router-HQ:**
```cisco
!===============================================
! ACCESS LIST - Traffic Selector
!===============================================
! Definisce: "cifra il traffico dalla MIA LAN verso LAN REMOTA"

! ACL 100 = Extended IP ACL (permette match su src + dst IP)
! Formato: access-list <num> permit <protocol> <src> <wildcard> <dst> <wildcard>

access-list 100 permit ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
!                          |              |              |              |
!                          |              |              |              |
!                   LAN HQ (source)   wildcard      LAN Branch    wildcard
!                                      (= mask)      (destination)  (= mask)

! SPIEGAZIONE WILDCARD MASK:
! Wildcard 0.0.0.255 = /24 subnet
! - 0 = "must match exactly" (bit fisso)
! - 255 = "don't care" (bit qualunque)
! 
! Esempio: 192.168.1.0 0.0.0.255 matcha:
!   192.168.1.0 - 192.168.1.255 (tutti gli IP della /24)
! 
! Conversione subnet mask → wildcard:
!   Subnet mask:  255.255.255.0
!   Wildcard:     0.0.0.255  (inverti i bit: 255-mask)
```

**Cosa significa questa ACL in pratica:**
```
Traffic flow che verrà CIFRATO:
  Source:      qualsiasi host in 192.168.1.0/24 (LAN HQ)
  Destination: qualsiasi host in 192.168.2.0/24 (LAN Branch)
  Protocol:    qualsiasi (ip = tutti i protocolli IP)

Esempi di traffico CIFRATO:
  ✅ PC1 (192.168.1.10) → PC3 (192.168.2.10): ICMP ping
  ✅ PC2 (192.168.1.20) → PC4 (192.168.2.20): TCP port 80
  ✅ Server (192.168.1.50) → DB (192.168.2.100): TCP port 3306

Esempi di traffico NON cifrato (non matcha ACL):
  ❌ PC1 (192.168.1.10) → Internet (8.8.8.8)
  ❌ Router (200.1.1.1) → Router remoto (200.2.2.1): traffico IKE
  ❌ Traffico dentro stessa LAN: 192.168.1.10 → 192.168.1.20
```

**Router-Branch (ACL SPECULARE - FONDAMENTALE!):**
```cisco
!===============================================
! ACL SPECULARE - DEVE essere l'inverso di HQ
!===============================================
! HQ ha: src=192.168.1.0 dst=192.168.2.0
! Branch DEVE avere: src=192.168.2.0 dst=192.168.1.0
! 
! ERRORE COMUNE: copiare identica ACL su entrambi i router → FALLIMENTO!

access-list 100 permit ip 192.168.2.0 0.0.0.255 192.168.1.0 0.0.0.255
!                          |<--- LAN Branch -->|  |<--- LAN HQ ---->|
!                              (locale)               (remota)
```

**Visualizzazione grafica ACL speculari:**

```
Router-HQ ACL 100:
  permit ip 192.168.1.0/24 → 192.168.2.0/24
         (traffico in uscita da HQ verso Branch)

Router-Branch ACL 100:
  permit ip 192.168.2.0/24 → 192.168.1.0/24
         (traffico in uscita da Branch verso HQ)

Flow bidirezionale:
  PC1 (HQ) → PC3 (Branch):  matchato da ACL HQ   → cifrato
  PC3 (Branch) → PC1 (HQ):  matchato da ACL Branch → cifrato
```

**Errori fatali comuni:**

| Errore | Router HQ | Router Branch | Risultato |
|--------|-----------|---------------|----------|
| ❌ ACL identica | permit 192.168.1.0 → 192.168.2.0 | permit 192.168.1.0 → 192.168.2.0 | Traffico da Branch non cifrato! |
| ❌ ACL inversa | permit 192.168.1.0 → 192.168.2.0 | permit 192.168.1.0 → 192.168.2.0 | Tunnel non si stabilisce |
| ✅ ACL speculare | permit 192.168.1.0 → 192.168.2.0 | permit 192.168.2.0 → 192.168.1.0 | FUNZIONA |

**ACL avanzate (opzionali):**

Cifrare solo traffico specifico (es: solo HTTPS):
```cisco
access-list 101 permit tcp 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255 eq 443
```

Cifrare più subnet:
```cisco
access-list 100 permit ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
access-list 100 permit ip 10.0.1.0 0.0.0.255 192.168.2.0 0.0.0.255
! ↑ Anche la rete 10.0.1.0/24 può raggiungere Branch cifrato
```

> **Regola d'oro**: Le ACL devono essere SPECULARI (mirror), non identiche!

### Step 3.4: Creazione Crypto Map

**Cos'è una Crypto Map?**
La crypto map è il "collante" che unisce tutti i componenti VPN:
- **ACL**: quale traffico cifrare (traffic selector)
- **Peer**: con chi stabilire il tunnel
- **Transform set**: come cifrare (algoritmi)
- **ISAKMP policy**: parametri Phase 1 (già definiti prima)

La crypto map viene applicata all'interfaccia dove il traffico da cifrare entra/esce (tipicamente WAN).

**Router-HQ:**
```cisco
!===============================================
! CRYPTO MAP - Binding di tutti i componenti VPN
!===============================================
! Sintassi: crypto map <nome> <seq> ipsec-isakmp
! <seq> = numero di sequenza (come ACL, ordine di valutazione)

crypto map VPN-MAP 10 ipsec-isakmp
 
 ! --------------------------------------------------
 ! SET PEER: identifica il router VPN remoto
 ! --------------------------------------------------
 ! DEVE essere l'IP WAN pubblico del peer (NON IP LAN!)
 ! Questo è l'indirizzo a cui vengono inviati i pacchetti ESP cifrati
 set peer 200.2.2.1
 !          ^
 !          |
 !    IP WAN di Router-Branch
 
 ! --------------------------------------------------
 ! SET TRANSFORM-SET: riferimento al transform set
 ! --------------------------------------------------
 ! Nome "VPN-SET" deve corrispondere al transform set definito prima
 ! Puoi specificare più transform set per negoziazione (fallback)
 set transform-set VPN-SET
 
 ! --------------------------------------------------
 ! MATCH ADDRESS: ACL che definisce traffico interessante
 ! --------------------------------------------------
 ! Numero 100 = ACL extended definita precedentemente
 ! Traffico che matcha questa ACL verrà processato da questa crypto map
 match address 100
 
 exit

!===============================================
! APPLICAZIONE CRYPTO MAP ALL'INTERFACCIA
!===============================================
! FONDAMENTALE: la crypto map DEVE essere applicata all'interfaccia
! attraverso cui passa il traffico cifrato
!
! Regola: applica sulla WAN interface (outbound verso Internet/peer)

interface GigabitEthernet0/0
 
 ! Applica crypto map a questa interfaccia
 ! Quando un pacchetto esce da qui, il router controlla:
 ! 1. Matcha una crypto map ACL?
 ! 2. Se sì, cifra con transform set e invia a peer
 ! 3. Se no, inoltra normalmente (chiaro)
 crypto map VPN-MAP
 
 ! NOTA: solo UNA crypto map per interfaccia!
 ! (ma una crypto map può avere più entry con seq diverse)
 
 exit
```

**Cosa succede quando applichi la crypto map:**
```
Prima:
  Gi0/0: normale routing IP (tutto in chiaro)

Dopo "crypto map VPN-MAP":
  Gi0/0: ogni pacchetto outbound viene controllato
    - Matcha ACL 100? → Cifra e invia a peer 200.2.2.1
    - Non matcha? → Inoltra normalmente
```

**Router-Branch (configurazione speculare):**
```cisco
!===============================================
! Crypto map Branch - SPECULARE a HQ
!===============================================
! Stessi concetti, ma peer punta a HQ

crypto map VPN-MAP 10 ipsec-isakmp
 
 ! Peer = IP WAN di Router-HQ
 set peer 200.1.1.1
 !          ^
 !          |
 !    DIFFERENZA: punta a HQ invece di Branch
 
 ! Transform set: stesso nome
 set transform-set VPN-SET
 
 ! ACL: numero 100 (ma contenuto speculare!)
 match address 100
 
 exit

! Applica alla WAN interface
interface GigabitEthernet0/0
 crypto map VPN-MAP
 exit
```

**Struttura completa crypto map visualizzata:**

```
Router-HQ Crypto Map:
┌─────────────────────────────────────┐
│ VPN-MAP (sequence 10)               │
├─────────────────────────────────────┤
│ Peer:          200.2.2.1            │ ← Router-Branch
│ Transform Set: VPN-SET              │ ← AES-256 + SHA-256
│ ACL:           100                  │ ← 192.168.1.0 → 192.168.2.0
│ Interface:     Gi0/0                │ ← Dove applicata
└─────────────────────────────────────┘

Router-Branch Crypto Map:
┌─────────────────────────────────────┐
│ VPN-MAP (sequence 10)               │
├─────────────────────────────────────┤
│ Peer:          200.1.1.1            │ ← Router-HQ
│ Transform Set: VPN-SET              │ ← AES-256 + SHA-256
│ ACL:           100                  │ ← 192.168.2.0 → 192.168.1.0
│ Interface:     Gi0/0                │ ← Dove applicata
└─────────────────────────────────────┘
```

**Multiple crypto map entries (esempio avanzato):**
```cisco
! Se devi connettere a più siti, aggiungi entry con seq diverse
crypto map VPN-MAP 10 ipsec-isakmp  ! Tunnel verso Branch
 set peer 200.2.2.1
 set transform-set VPN-SET
 match address 100

crypto map VPN-MAP 20 ipsec-isakmp  ! Tunnel verso Site2
 set peer 200.3.3.1
 set transform-set VPN-SET
 match address 101  ! ACL diversa per Site2
```

### Step 3.5: NAT Exemption - Impedire NAT su Traffico VPN (Opzionale)

**Problema: NAT e VPN in conflitto**

Se il router HQ fa anche NAT/PAT per uscita Internet, si crea un conflitto:
- Il traffico verso Branch (192.168.2.0/24) NON deve essere NATtato
- Il traffico verso Internet pubblico DEVE essere NATtato

**Perché il traffico VPN non deve subire NAT?**
1. IPsec tunnel è basato su IP originali (ACL matcha IP privati)
2. NAT cambierebbe source IP prima della cifratura
3. Il peer remoto riceve pacchetti con IP sbagliato e li scarta

**Scenario senza NAT exemption:**
```
PC1 (192.168.1.10) ping PC3 (192.168.2.10)
  ↓
Router HQ riceve: src=192.168.1.10, dst=192.168.2.10
  ↓
NAT lo modifica: src=200.1.1.1, dst=192.168.2.10  ← PROBLEMA!
  ↓
ACL 100 non matcha più! (cerca src 192.168.1.0/24)
  ↓
Pacchetto inoltrato NON cifrato → FALLIMENTO
```

**Soluzione: NAT Exemption (Split NAT)**

```cisco
!===============================================
! NAT EXEMPTION per traffico VPN
!===============================================
! Questa configurazione è necessaria SOLO se hai NAT attivo

! ACL 110 definisce cosa NATtare:
access-list 110 deny ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
!                ^^^^                                             ^
!                |                                                |
!            DENY = NON nattare questo traffico (tunnel VPN)

access-list 110 permit ip 192.168.1.0 0.0.0.255 any
!                ^^^^^^                           ^^^
!                |                                |
!            PERMIT = natta questo (tutto il resto verso Internet)

! Applica NAT usando ACL 110
! "overload" = PAT (Port Address Translation, molti:1)
ip nat inside source list 110 interface GigabitEthernet0/0 overload

! Marca interfacce NAT
interface GigabitEthernet0/1  ! LAN
 ip nat inside
 exit

interface GigabitEthernet0/0  ! WAN
 ip nat outside
 exit
```

**Come funziona l'ACL 110:**

| Traffico | Source | Destination | ACL Match | Azione NAT |
|----------|--------|-------------|-----------|------------|
| Verso Branch | 192.168.1.10 | 192.168.2.10 | Line 1 (deny) | **Non NATta** → VPN cifra |
| Verso Internet | 192.168.1.10 | 8.8.8.8 | Line 2 (permit) | **NATta** → 200.1.1.1 |
| Verso Internet | 192.168.1.20 | 1.1.1.1 | Line 2 (permit) | **NATta** → 200.1.1.1 |

**Ordine di elaborazione pacchetto (con NAT exemption):**
```
1. Pacchetto arriva: src=192.168.1.10, dst=192.168.2.10
   ↓
2. Routing: trova route verso 192.168.2.0/24 via 200.1.1.2
   ↓
3. NAT (prima di uscire):
   - Controlla ACL 110
   - Matcha "deny" → NON nattare
   ↓
4. Crypto map (su Gi0/0 outbound):
   - Controlla ACL 100
   - Matcha "permit" → CIFRA con IPsec
   ↓
5. Pacchetto cifrato ESP inviato a peer 200.2.2.1
```

**Verifica NAT exemption:**
```cisco
! Mostra traduzioni NAT attive
show ip nat translations

! Dopo ping a PC3 (192.168.2.10):
! NON dovrebbe apparire nessuna traduzione per 192.168.1.x → 192.168.2.x

! Dopo ping a Internet (8.8.8.8):
! DOVREBBE apparire: 192.168.1.10 → 200.1.1.1:xxxxx
```

> **Nota**: Nel nostro lab base non abbiamo NAT configurato, quindi questo step è **opzionale** e serve come riferimento per scenari real-world.

### Step 3.6: Salvataggio Configurazione

**Entrambi i router:**
```cisco
end
write memory
```

---

## Parte 4: Testing e Verifica VPN

### Step 4.1: Generazione Traffico Interessante

**CONCETTO FONDAMENTALE: Tunnel IPsec "On-Demand"**

Differenza critica rispetto ad altre VPN:
- **OpenVPN/WireGuard**: tunnel sempre attivo (stabilito al boot)
- **IPsec Cisco**: tunnel si attiva SOLO quando serve (trigger: traffico interessante)

**Processo di attivazione tunnel:**

```
1. Nessun traffico VPN → Tunnel NON esiste
   Router HQ: show crypto isakmp sa → (vuoto)

2. PC1 fa ping a PC3 (192.168.2.10)
   ↓
3. Router HQ riceve pacchetto, controlla crypto map
   - Matcha ACL 100? SÌ (192.168.1.10 → 192.168.2.10)
   - Tunnel esiste? NO
   ↓
4. TRIGGER: inizia negoziazione IKE
   - Phase 1: scambio 6 messaggi (Main Mode)
   - Durata: ~1-3 secondi
   - Primo ping: TIMEOUT (perso durante negoziazione)
   ↓
5. Phase 1 completata (ISAKMP SA attiva)
   ↓
6. Phase 2: negozia IPsec SA
   - Quick Mode: 3 messaggi
   - Durata: ~0.5-1 secondo
   ↓
7. Tunnel IPsec ATTIVO
   - Ping successivi: FUNZIONANO
   - Traffico cifrato end-to-end
```

**Test pratico da PC1 (Desktop → Command Prompt):**
```bash
# IMPORTANTE: aspetta che i router abbiano salvato la config
# e che tutte le interfacce siano UP

ping 192.168.2.10
```

**Output atteso del primo ping:**
```
Pinging 192.168.2.10 with 32 bytes of data:

Request timed out.          ← Primo: perso (negoziazione Phase 1+2)
Reply from 192.168.2.10     ← Secondo: OK! Tunnel attivo
Reply from 192.168.2.10     ← Terzo: OK
Reply from 192.168.2.10     ← Quarto: OK

Ping statistics:
    Packets: Sent = 4, Received = 3, Lost = 1 (25% loss)
```

**Se TUTTI i ping falliscono (0% success):**

| Sintomo | Probabile causa | Debug |
|---------|-----------------|-------|
| Tutti timeout | Tunnel non si stabilisce | `show crypto isakmp sa` → vuoto |
| "Destination host unreachable" | Routing pre-VPN rotto | Testa ping senza VPN prima |
| Primo ok, poi falliscono | Phase 1 ok, Phase 2 fail | `show crypto ipsec sa` → check |

**Test completo - Sequenza consigliata:**

```bash
# Da PC1:

# 1. Ping verso PC3 (trigger tunnel)
ping 192.168.2.10 -n 10
# Atteso: primo miss, poi 9 reply

# 2. Ping verso PC4 (riusa tunnel esistente)
ping 192.168.2.20
# Atteso: tutti reply (tunnel già attivo)

# 3. Ping continuo per test stabilità
ping 192.168.2.10 -t
# Atteso: no packet loss
# Premi Ctrl+C per fermare

# 4. Traceroute per vedere percorso
tracert 192.168.2.10
# Atteso:
#   1    <1 ms   192.168.1.1  (gateway HQ)
#   2     *       *       *    (pacchetto cifrato, router intermedio non risponde)
#   3    ~50 ms  192.168.2.10 (destinazione)
```

**Da PC2 (verifica che anche altri PC usano VPN):**
```bash
ping 192.168.2.10
# Deve funzionare! Il tunnel è condiviso da tutti i PC della LAN
```

**Cosa sta succedendo "dietro le quinte":**

```
PC1 genera: ICMP Echo Request
  [IP: 192.168.1.10 → 192.168.2.10 | ICMP: type=8]
  ↓
Router HQ:
  1. Riceve su Gi0/1 (LAN)
  2. Routing: route verso 192.168.2.0/24 → forward verso Gi0/0
  3. Prima di uscire da Gi0/0: controlla crypto map
  4. ACL 100 matcha → cifra con IPsec
  5. Incapsula in ESP:
     [IP: 200.1.1.1 → 200.2.2.1 | ESP | {cifrato: IP orig + ICMP} | Auth]
  6. Invia via Internet (Cloud)
  ↓
Router Branch:
  1. Riceve su Gi0/0 (WAN): pacchetto ESP
  2. Riconosce SPI → identifica tunnel IPsec
  3. Decifra con chiave condivisa
  4. Estrae pacchetto originale: [192.168.1.10 → 192.168.2.10 | ICMP]
  5. Routing normale: forward verso Gi0/1 (LAN)
  6. Consegna a PC3
  ↓
PC3 risponde: ICMP Echo Reply
  [IP: 192.168.2.10 → 192.168.1.10 | ICMP: type=0]
  ↓
(Processo inverso: Branch cifra, HQ decifra)
  ↓
PC1 riceve risposta: "Reply from 192.168.2.10"
```

> **Checkpoint**: Prima di procedere, assicurati che il ping funzioni!
> Se fallisce, vai direttamente alla **Parte 5: Troubleshooting**.

### Step 4.2: Verifica Stato Tunnel IPsec

**Comandi diagnostici essenziali Cisco IPsec:**

**Router-HQ (CLI):**

```cisco
!===============================================
! COMANDO 1: Verifica Phase 1 (ISAKMP SA)
!===============================================
! Mostra lo stato del tunnel di controllo IKE

Router-HQ# show crypto isakmp sa

! OUTPUT ATTESO (tunnel attivo):
dst             src             state          conn-id slot status
200.2.2.1       200.1.1.1       QM_IDLE           1001    0 ACTIVE

! INTERPRETAZIONE CAMPI:
! - dst:        IP WAN del peer remoto (Branch)
! - src:        IP WAN locale (HQ)
! - state:      stato negoziazione (vedi tabella sotto)
! - conn-id:    ID unico connessione
! - status:     ACTIVE = funzionante
```

**Tabella Stati ISAKMP:**

| State | Significato | Diagnosi |
|-------|-------------|----------|
| **QM_IDLE** | ✅ Tunnel attivo, in idle (Quick Mode completato) | Perfetto! VPN funziona |
| **MM_NO_STATE** | ❌ Nessun tunnel | Negoziazione mai iniziata |
| **MM_SA_SETUP** | ⏳ Negoziazione Main Mode in corso | Attendere (~3 sec) |
| **MM_KEY_EXCH** | ⏳ Scambio chiavi Diffie-Hellman | Normale durante setup |
| **MM_KEY_AUTH** | ⏳ Autenticazione con PSK | Quasi completato |
| **AG_***| ⏳ Aggressive Mode (3 messaggi) | Alternativa a Main Mode |

```cisco
!===============================================
! COMANDO 2: Verifica Phase 2 (IPsec SA)
!===============================================
! Mostra i tunnel dati (dove viaggia traffico utente cifrato)

Router-HQ# show crypto ipsec sa

! OUTPUT ATTESO (esempio):
interface: GigabitEthernet0/0
    Crypto map tag: VPN-MAP, local addr 200.1.1.1

   protected vrf: (none)
   local  ident (addr/mask/prot/port): (192.168.1.0/255.255.255.0/0/0)
   remote ident (addr/mask/prot/port): (192.168.2.0/255.255.255.0/0/0)
   current_peer 200.2.2.1 port 500
     PERMIT, flags={origin_is_acl,}
    #pkts encaps: 50, #pkts encrypt: 50, #pkts digest: 50
    #pkts decaps: 48, #pkts decrypt: 48, #pkts verify: 48
    #pkts compressed: 0, #pkts decompressed: 0
    #pkts not compressed: 0, #pkts compr. failed: 0
    #send errors 0, #recv errors 0

     local crypto endpt.: 200.1.1.1, remote crypto endpt.: 200.2.2.1
     path mtu 1500, ip mtu 1500, ip mtu idb GigabitEthernet0/0
     current outbound spi: 0xABCD1234(2882400820)
     PFS (Y/N): N, DH group: none

     inbound esp sas:
      spi: 0x12345678(305419896)
        transform: esp-256-aes esp-sha256-hmac ,
        in use settings ={Tunnel, }
        conn id: 2001, flow_id: SW:1, sibling_flags 80004040, crypto map: VPN-MAP
        sa timing: remaining key lifetime (k/sec): (4500000/3528)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE

     outbound esp sas:
      spi: 0xABCD1234(2882400820)
        transform: esp-256-aes esp-sha256-hmac ,
        in use settings ={Tunnel, }
        conn id: 2002, flow_id: SW:2, sibling_flags 80004040, crypto map: VPN-MAP
        sa timing: remaining key lifetime (k/sec): (4500000/3528)
        IV size: 16 bytes
        replay detection support: Y
        Status: ACTIVE
```

**INTERPRETAZIONE OUTPUT PHASE 2 (punti chiave):**

```cisco
! 1. INTERFACCIA e CRYPTO MAP
interface: GigabitEthernet0/0        ← Dove applicata crypto map
Crypto map tag: VPN-MAP              ← Nome crypto map

! 2. TRAFFIC SELECTORS (da ACL)
local  ident: (192.168.1.0/24/0/0)   ← Traffico local (HQ)
remote ident: (192.168.2.0/24/0/0)   ← Traffico remote (Branch)
!                              ^ ^      (0/0 = any protocol/port)

! 3. CONTATORI PACCHETTI (ESSENZIALI per diagnostica!)
#pkts encaps: 50     ← Pacchetti ricevuti da LAN e processati per cifratura
#pkts encrypt: 50    ← Pacchetti effettivamente cifrati
#pkts digest: 50     ← Pacchetti autenticati (HMAC calcolato)
#pkts decaps: 48     ← Pacchetti cifrati ricevuti da peer
#pkts decrypt: 48    ← Pacchetti decifrati con successo
#pkts verify: 48     ← HMAC verificato OK

! ANALISI CONTATORI:
! - encaps ≈ decrypt: traffico bidirezionale bilanciato ✓
! - encrypt > 0: VPN sta cifrando! ✓
! - Se encrypt = 0 dopo ping: tunnel non funziona! ✗

! 4. SPI (Security Parameter Index)
spi: 0x12345678      ← ID univoco per questa SA (inbound)
spi: 0xABCD1234      ← ID univoco per SA opposta (outbound)
! Ogni direzione ha SPI diverso
! SPI identifica quale chiave/SA usare per decifrare

! 5. TRANSFORM IN USO
transform: esp-256-aes esp-sha256-hmac   ← Algoritmi negoziati
! Conferma che i parametri concordati sono corretti

! 6. LIFETIME RIMASTO
remaining key lifetime (k/sec): (4500000/3528)
!                                 |        |
!                                 |        +-- 3528 secondi = ~59 minuti
!                                 +----------- 4.5 MB di traffico
! Quando scade: rinegoziazione automatica Phase 2

! 7. STATUS
Status: ACTIVE       ← SA funzionante
```

```cisco
!===============================================
! COMANDO 3: Visualizza Crypto Map Applicata
!===============================================
! Verifica configurazione crypto map attiva

Router-HQ# show crypto map

! OUTPUT:
Crypto Map: "VPN-MAP" idb: GigabitEthernet0/0
Crypto Map "VPN-MAP" 10 ipsec-isakmp
        Peer = 200.2.2.1
        Extended IP access list 100
            access-list 100 permit ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
        Current peer: 200.2.2.1
        Security association lifetime: 4608000 kilobytes/3600 seconds
        PFS (Y/N): N
        Transform sets={
                VPN-SET:  { esp-256-aes esp-sha256-hmac  } , 
        }
        Interfaces using crypto map VPN-MAP:
                GigabitEthernet0/0

! PUNTI DI ATTENZIONE:
! - Peer: deve corrispondere a IP WAN remoto
! - ACL: verifica contenuto (src/dst corretti)
! - Transform sets: algoritmi configurati
! - Interfaces: su quale interfaccia applicata
```

**Comandi aggiuntivi utili:**

```cisco
! Riepilogo compatto di tutte le sessioni VPN
Router-HQ# show crypto session
! Output mostra: peer, status, IKE/IPsec SA attive

! Dettaglio specifico peer
Router-HQ# show crypto session detail

! Statistiche engine crypto (performance)
Router-HQ# show crypto engine connections active

! Solo contatori encaps/decaps (veloce)
Router-HQ# show crypto ipsec sa | include encaps|decaps
#pkts encaps: 150, #pkts encrypt: 150, #pkts digest: 150
#pkts decaps: 142, #pkts decrypt: 142, #pkts verify: 142
```

**Test iterativo (workflow raccomandato):**

```cisco
! 1. Genera traffico da PC1
PC1> ping 192.168.2.10

! 2. Verifica subito Phase 1
Router-HQ# show crypto isakmp sa
! Cerca state = QM_IDLE

! 3. Verifica Phase 2 e contatori
Router-HQ# show crypto ipsec sa | include encaps
! Numero deve incrementare ad ogni ping

! 4. Genera altro traffico
PC1> ping 192.168.2.10 -n 20

! 5. Ricontrolla contatori (devono essere aumentati)
Router-HQ# show crypto ipsec sa | include encaps
! Se encaps/encrypt non aumentano → tunnel NON cifra!
```

**Interpretazione stati ISAKMP:**
- `QM_IDLE`: tunnel attivo e funzionante ✓
- `MM_NO_STATE`: nessun tunnel (problema config)
- `MM_SA_SETUP`: negoziazione in corso

### Step 4.3: Test Completi e Validazione End-to-End

**Obiettivo**: Verificare che TUTTI i PC possano comunicare attraverso il tunnel VPN e che i contatori di cifratura aumentino correttamente.

> **Concetto chiave**: Il tunnel IPsec è **condiviso** da tutti i dispositivi nella LAN locale.
> Non serve un tunnel separato per ogni PC! Tutti i PC nella subnet 192.168.1.0/24 (HQ)
> possono comunicare con tutti i PC nella subnet 192.168.2.0/24 (Branch) attraverso
> lo stesso tunnel IPsec stabilito tra i due router.

**Sequenza Test Consigliata:**

**Test 1: Validazione PC1 → PC3 (test primario)**

```bash
# Da PC1 (Desktop → Command Prompt):
ping 192.168.2.10 -n 10

# OUTPUT ATTESO:
Pinging 192.168.2.10 with 32 bytes of data:

Request timed out.          ← Primo: perso (negoziazione in background)
Reply from 192.168.2.10     ← Secondo: OK! Tunnel attivo
Reply from 192.168.2.10     ← Tutti i successivi: OK
...

Ping statistics:
    Packets: Sent = 10, Received = 9, Lost = 1 (10% loss)
```

**Analisi risultato Test 1:**
- **Lost = 1 (10%)**: Normale! Primo pacchetto sacrificato per trigger Phase 1+2
- **Lost = 0 (0%)**: Eccellente! Tunnel era già up da test precedente
- **Lost > 2 (>20%)**: Problema! Tunnel instabile o route intermittenti

**Test 2: Validazione PC1 → PC4 (verifica connettività multipla)**

```bash
# Da PC1:
ping 192.168.2.20

# OUTPUT ATTESO:
Pinging 192.168.2.20 with 32 bytes of data:

Reply from 192.168.2.20     ← Tutti OK! Tunnel già attivo
Reply from 192.168.2.20
Reply from 192.168.2.20
Reply from 192.168.2.20

Ping statistics:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

**Perché 0% loss questa volta?**
- Il tunnel IPsec è già ATTIVO dal Test 1
- La SA (Security Association) copre TUTTA la subnet 192.168.2.0/24
- Non serve rinegoziare per ogni host destinazione nella stessa subnet

**Test 3: Validazione PC2 → PC3 (verifica sharing tunnel)**

```bash
# Da PC2 (altro PC nella LAN HQ):
ping 192.168.2.10

# OUTPUT ATTESO:
Reply from 192.168.2.10     ← Tutti OK!
Reply from 192.168.2.10
Reply from 192.168.2.10
Reply from 192.168.2.10
```

**Concetto fondamentale**: PC2 NON ha negoziato il tunnel (non ha VPN client!).
Il tunnel è tra **Router-HQ e Router-Branch**. PC2 semplicemente:
1. Invia pacchetto IP normale a router locale (192.168.1.1)
2. Router-HQ cifra il pacchetto con IPsec
3. Router-Branch decifra e consegna a PC3
4. Il ritorno avviene in modo speculare

**Test 4: Verifica traffico bidirezionale (reverse direction)**

```bash
# Da PC3 (LAN Branch) verso PC1 (LAN HQ):
ping 192.168.1.10

# OUTPUT ATTESO:
Reply from 192.168.1.10     ← Tutti OK!
...
```

**Questo conferma che l'ACL speculare è corretta!**
Router-Branch può cifrare traffico 192.168.2.0/24 → 192.168.1.0/24.

**Test 5: Test di stress (ping continuo per stabilità)**

```bash
# Da PC1:
ping 192.168.2.10 -t
# (-t = continuo, premi Ctrl+C per fermare)

# Lascia andare per 1-2 minuti, poi premi Ctrl+C

# OUTPUT ATTESO:
... centinaia di reply ...
^C
Ping statistics:
    Packets: Sent = 120, Received = 119, Lost = 1 (0.83% loss)
```

**Analisi stabilità:**
- **Loss < 1%**: Tunnel stabile ✓
- **Loss 1-5%**: Accettabile in ambiente simulato (Packet Tracer)
- **Loss > 10%**: Problema! Controlla lifetime SA, routing, o bug PT

**Test 6: Verifica contatori encryption/decryption (ESSENZIALE!)**

```cisco
# Su Router-HQ:
Router-HQ# show crypto ipsec sa | include encaps|decaps

# PRIMA dei test:
#pkts encaps: 0, #pkts encrypt: 0, #pkts digest: 0
#pkts decaps: 0, #pkts decrypt: 0, #pkts verify: 0

# DOPO Test 1-5 (esempio):
#pkts encaps: 150, #pkts encrypt: 150, #pkts digest: 150
#pkts decaps: 145, #pkts decrypt: 145, #pkts verify: 145
```

**Interpretazione contatori:**

```
encaps (150)  =  Pacchetti ricevuti da LAN da cifrare
   ↓
encrypt (150) =  Pacchetti effettivamente cifrati con AES
   ↓
digest (150)  =  HMAC calcolato per autenticazione
   ↓
[Invio su WAN come ESP]

[Ricezione ESP da WAN]
   ↓
decaps (145)  =  Pacchetti ESP ricevuti da peer
   ↓
decrypt (145) =  Pacchetti decifrati con successo
   ↓
verify (145)  =  HMAC verificato OK (no tampering)
   ↓
[Consegna a LAN come IP normale]
```

**Regole di validazione contatori:**

| Condizione | Significato | Azione |
|------------|-------------|--------|
| `encaps = encrypt = digest` | ✅ Cifratura perfetta | Tutto OK |
| `encaps > encrypt` | ⚠️ Alcuni pacchetti non cifrati | Controlla transform-set |
| `encrypt = 0` dopo ping | ❌ VPN NON funziona! | Traffico bypassa tunnel |
| `decaps ≈ encrypt` (±10%) | ✅ Traffico bidirezionale | Normale |
| `decrypt < decaps` | ⚠️ Alcuni decrypt falliti | Verifica chiavi/algoritmi |
| `verify < decrypt` | ⚠️ HMAC check falliti | Possibile tampering! |

**Test 7: Confronto con contatori peer (Router-Branch)**

```cisco
# Su Router-Branch:
Router-Branch# show crypto ipsec sa | include encaps|decaps

#pkts encaps: 145, #pkts encrypt: 145, #pkts digest: 145
#pkts decaps: 150, #pkts decrypt: 150, #pkts verify: 150
```

**I contatori devono essere INCROCIATI:**
```
Router-HQ encaps (150)  ≈  Router-Branch decaps (150)
Router-HQ decaps (145)  ≈  Router-Branch encaps (145)
```

**Se questa equivalenza NON vale:**
- Pacchetti persi in transito (problema WAN simulata)
- ACL asimmetriche (alcuni tipi traffico bloccati)
- NAT interferisce (controlla NAT exemption)

Se i contatori aumentano correttamente, **la VPN funziona al 100%**! ✓

### Step 4.4: Verifica Dettagliata (Debug)

> **Attenzione**: il debug può rallentare Packet Tracer. Usare con cautela.

```cisco
! Abilita debug temporaneamente
debug crypto isakmp
debug crypto ipsec

! Genera traffico (ping da PC)

! Disabilita debug
undebug all
```

Cerca messaggi come:
- `ISAKMP: Created a peer`: peer identificato
- `ISAKMP SA authenticated`: Phase 1 OK
- `IPsec: SA created`: Phase 2 OK

---

## Parte 5: Troubleshooting

### Problema 1: Tunnel Non Si Stabilisce

**Sintomi**: ping fallisce, nessuna SA in `show crypto isakmp sa`

**Checklist:**

```cisco
! 1. Verifica connettività WAN base
Router-HQ# ping 200.2.2.1
! Deve funzionare (senza VPN)

! 2. Verifica pre-shared key (case-sensitive!)
Router-HQ# show run | include crypto isakmp key
! Deve essere IDENTICA su entrambi i router

! 3. Verifica peer address corretto
Router-HQ# show crypto map
! Peer deve essere 200.2.2.1 (WAN IP remoto)

! 4. Verifica ISAKMP policy match
Router-HQ# show crypto isakmp policy
! Parametri devono combaciare (encryption, hash, group)

! 5. Controlla ACL applicata a crypto map
Router-HQ# show access-lists 100
! Deve matchare traffico corretto
```

### Problema 2: Tunnel Si Stabilisce ma Traffico Non Passa

**Sintomi**: `show crypto isakmp sa` mostra QM_IDLE, ma ping fallisce

**Cause comuni:**

```cisco
! 1. ACL speculare errata
Router-HQ# show access-lists 100
! access-list 100 permit ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255

Router-Branch# show access-lists 100
! access-list 100 permit ip 192.168.2.0 0.0.0.255 192.168.1.0 0.0.0.255
! ↑ Devono essere INVERSE (mirror)!

! 2. Routing mancante
Router-HQ# show ip route 192.168.2.0
! Deve esserci route (statica o dinamica)

! 3. Firewall o altra ACL in/out sulle interfacce
Router-HQ# show ip interface GigabitEthernet0/1 | include access list
! Non dovrebbero esserci ACL non volute
```

### Problema 3: Tunnel Funziona ma è Lento

In Packet Tracer la performance è simulata. Nel mondo reale:

```cisco
! Verifica packet drop
show crypto ipsec sa | include drop

! Se elevato:
! - MTU troppo grande (frammentazione)
! - CPU overload (riduci encryption strength per test)
```

### Problema 4: Tunnel Cade Dopo Timeout

**Sintomi**: tunnel funziona poi smette

```cisco
! Verifica lifetime
show crypto isakmp sa detail
show crypto ipsec sa | include remaining

! Se lifetime scaduto, il tunnel rinegozia automaticamente
! Genera traffico di nuovo per riattivare
```

### Comando Utility per Reset

```cisco
! Cancellare SA esistenti (forzare rinegoziazione)
clear crypto isakmp
clear crypto sa

! Poi genera traffico (ping) per ricreare tunnel
```

---

## Parte 6: Configurazioni Avanzate

### Opzione A: IKEv2 (se supportato dalla versione PT)

IKEv2 è più moderno e veloce:

```cisco
! Router-HQ
crypto ikev2 proposal IKEv2-PROP
 encryption aes-cbc-256
 integrity sha256
 group 14
 exit

crypto ikev2 policy IKEv2-POL
 proposal IKEv2-PROP
 exit

crypto ikev2 keyring IKEv2-KEYRING
 peer Router-Branch
  address 200.2.2.1
  pre-shared-key VPN_Secret_2024
  exit
 exit

crypto ikev2 profile IKEv2-PROFILE
 match identity remote address 200.2.2.1
 authentication remote pre-share
 authentication local pre-share
 keyring local IKEv2-KEYRING
 exit

! Modifica crypto map per usare IKEv2
crypto map VPN-MAP 10 ipsec-isakmp
 set peer 200.2.2.1
 set transform-set VPN-SET
 set ikev2-profile IKEv2-PROFILE
 match address 100
 exit
```

### Opzione B: VPN con NAT Traversal

Se uno dei router è dietro NAT (PAT), abilita NAT-T:

```cisco
crypto isakmp nat keepalive 20
```

### Opzione C: Logging Avanzato

```cisco
! Loggaree eventi crypto
logging buffered 51200 debugging
logging console informational

! Vedere log
show logging | include CRYPTO
```

### Opzione D: Multiple Crypto Maps (più tunnel)

Per connettere a più siti:

```cisco
! Tunnel verso Site2 (esempio)
crypto map VPN-MAP 20 ipsec-isakmp
 set peer 200.3.3.1  
 set transform-set VPN-SET
 match address 101
 exit

access-list 101 permit ip 192.168.1.0 0.0.0.255 192.168.3.0 0.0.0.255
```

---

## Parte 7: Scenari ed Esercizi

### Esercizio 1: Backup Tunnel (Ridondanza)

**Obiettivo**: Creare secondo tunnel VPN di backup

**Topology da aggiungere:**
- Aggiungi Router-Branch-Backup con IP WAN 200.3.3.1
- Configura VPN da HQ verso entrambi i branch
- Usa routing statico con administrative distance diversa

**Hint:**
```cisco
ip route 192.168.2.0 255.255.255.0 200.2.2.2 100  ! Primary (AD 100)
ip route 192.168.2.0 255.255.255.0 200.3.3.2 110  ! Backup (AD 110)
```

### Esercizio 2: Subnet Multiple

**Obiettivo**: HQ ha 2 LAN (192.168.1.0/24 e 192.168.10.0/24), entrambe devono accedere Branch

**Modifica ACL:**
```cisco
! Router-HQ
access-list 100 permit ip 192.168.1.0 0.0.0.255 192.168.2.0 0.0.0.255
access-list 100 permit ip 192.168.10.0 0.0.0.255 192.168.2.0 0.0.0.255

! Router-Branch (speculare)
access-list 100 permit ip 192.168.2.0 0.0.0.255 192.168.1.0 0.0.0.255
access-list 100 permit ip 192.168.2.0 0.0.0.255 192.168.10.0 0.0.0.255
```

### Esercizio 3: QoS su Traffico VPN

**Obiettivo**: Prioritizzare traffico VoIP cifrato

```cisco
! Class map per traffico VoIP (esempio RTP)
class-map match-any VOICE
 match access-group 110
 exit

access-list 110 permit udp any any range 16384 32767

! Policy map
policy-map QOS-VPN
 class VOICE
  priority percent 30
 exit

! Applica su interfaccia WAN outbound
interface GigabitEthernet0/0
 service-policy output QOS-VPN
 exit
```

### Esercizio 4: Monitoring con SNMP

**Obiettivo**: Monitorare tunnel VPN via SNMP

```cisco
snmp-server community public RO
snmp-server enable traps ipsec tunnel start
snmp-server enable traps ipsec tunnel stop
snmp-server host 192.168.1.100 version 2c public
```

Usa SNMP Manager (in PT: aggiungi server SNMP) per ricevere trap.

---

## Parte 8: Packet Capture e Analisi

### Step 8.1: Cattura Traffico in Packet Tracer

1. Click su **Simulation Mode** (icona cronometro in basso a destra)
2. Click su **Edit Filters**
3. Seleziona protocolli: **ICMP**, **ESP** (IPsec)
4. Genera ping da PC1 a PC3
5. Osserva pacchetti visuali:
   - Prima del tunnel: pacchetti ICMP normali
   - Dopo router HQ: pacchetti **ESP** (cifrati)
   - Dopo router Branch: pacchetti ICMP ripristinati

### Step 8.2: Verifica Cifratura

**Nell'ufbox del pacchetto ESP:**
- Source IP: 200.1.1.1 (WAN HQ)
- Dest IP: 200.2.2.1 (WAN Branch)
- Protocol: **50 (ESP)**
- Payload: **cifrato** (non leggibile)

**Confronto senza VPN:**

Temporaneamente rimuovi crypto map:
```cisco
interface GigabitEthernet0/0
 no crypto map VPN-MAP
 exit
```

Prova ping: vedrai pacchetto ICMP in chiaro con IP src 192.168.1.10 → dst 192.168.2.10.

Riapplica crypto map dopo test!

---

## Parte 9: Salvataggio e Condivisione

### Salvare Progetto Packet Tracer

1. **File → Save As**
2. Nome file: `Lab9-VPN-IPsec-YourName.pkt`
3. Salva in cartella laboratori

### Esportare Configurazioni

**Da CLI di ogni router:**
```cisco
show running-config
! Copia output in file .txt (es: Router-HQ-config.txt)
```

Oppure in Packet Tracer:
- Click router → Config tab → Export (se disponibile)

### Creare Template Riutilizzabile

Salva versione "pre-VPN" (solo base routing) come `Lab9-Base-Template.pkt` per riutilizzo rapido negli esercizi.

---

## Domande di Verifica

### Concettuali

1. Qual è la differenza tra Phase 1 e Phase 2 IPsec?
2. Perché usiamo "pre-shared key" invece di certificati in questo lab?
3. Cosa succede se le ACL non sono speculari tra i due router?
4. Perché il primo ping spesso fallisce quando attiviamo il tunnel?
5. Cos'è il "traffico interessante" (interesting traffic) nel contesto VPN?

### Pratiche

6. Come verifichi se il tunnel IPsec è attivo?
7. Quale comando mostra i pacchetti cifrati/decifrati?
8. Cosa significa lo stato ISAKMP `QM_IDLE`?
9. Come forzi la rinegoziazione del tunnel?
10. Dove applichi la crypto map: interfaccia LAN o WAN?

### Troubleshooting

11. Il tunnel non si stabilisce: quale comando usi per debuggare Phase 1?
12. Il tunnel si stabilisce ma il traffico non passa: quali sono le 3 cause più probabili?
13. Come verifichi che il pre-shared key sia configurato correttamente?
14. Perché è importante verificare la connettività WAN base prima di configurare VPN?

---

## Risorse Aggiuntive

### Comandi Quick Reference

```cisco
! === Configurazione ===
crypto isakmp policy <number>
crypto isakmp key <key> address <peer-ip>
crypto ipsec transform-set <name> <transforms>
crypto map <name> <seq> ipsec-isakmp

! === Verifica ===
show crypto isakmp sa          # Phase 1 status
show crypto ipsec sa           # Phase 2 status
show crypto map                # Configurazione crypto map

! === Troubleshooting ===
debug crypto isakmp            # Debug Phase 1
debug crypto ipsec             # Debug Phase 2
clear crypto isakmp            # Reset tunnel
clear crypto sa                # Reset SA

! === Monitoring ===
show crypto session            # Riepilogo sessioni
show crypto engine connections # Packet processing stats
```

### Link Utili

**Cisco Documentation:**
- IPsec Configuration Guide: https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/sec_conn_ipsec/configuration/
- Packet Tracer Tutorials: https://www.netacad.com/

**Video Tutorial:**
- YouTube: "Cisco IPsec VPN Configuration"
- Cisco Learning Network

**Community:**
- r/ccna (Reddit)
- Cisco Community Forums

---

## Conclusioni

In questo laboratorio hai imparato a:
- ✅ Creare topologia VPN site-to-site realistica in Packet Tracer
- ✅ Configurare IPsec con IKEv1 su router Cisco IOS
- ✅ Definire ISAKMP policy, transform set e crypto map
- ✅ Troubleshooting problemi comuni VPN
- ✅ Verificare tunnel con comandi diagnostici
- ✅ Analizzare traffico cifrato vs chiaro

**Prossimi step consigliati:**
1. Sperimentare con parametri crittografici diversi (AES-128, SHA-1, ecc.)
2. Aggiungere terzo sito (HQ ↔ Branch1 ↔ Branch2 mesh)
3. Implementare VPN remote access (client-to-site) con Easy VPN
4. Integrare dynamic routing (OSPF/EIGRP) con VPN
5. Configurare GRE over IPsec per supportare multicast

**Certificazioni correlate:**
- CCNA Security
- CCNP Security (SCOR, SVPN)

---

**Riferimenti ad altri laboratori:**
- [Lab 3: IPsec Site-to-Site con strongSwan](Lab3_IPsec_Site-to-Site.md) - IPsec su Linux
- [Lab 5: VPN Failover e HA](Lab5_VPN_Failover.md) - Ridondanza VPN avanzata

**Torna a**: [Indice Laboratori](16.Laboratori_ed_Esercitazioni.md) | [README VPN](README.md)
