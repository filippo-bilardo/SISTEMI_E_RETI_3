# QUESITI SECONDA PARTE - Soluzioni Dettagliate

## Riferimento al Testo

**Testo**: "Il candidato svolga la prima parte della prova e **due tra i quesiti proposti nella seconda parte**."

In questo documento sono risolti:
- **Quesito III**: Web server accessibile da Internet
- **Quesito IV**: Troubleshooting connettività Internet

(I quesiti I e II sono già risolti nel documento SOLUZIONE_COMPLETA.md)

---

## QUESITO III: Web Server Accessibile da Internet

**Testo**: "Una piccola azienda dispone di un normale collegamento ad Internet a banda larga, con un router a cui è assegnato un solo indirizzo IP pubblico statico. Nella rete interna alla piccola azienda esiste un web server locale che si vuole rendere accessibile da Internet sia tramite protocollo HTTP che HTTPS, e si vuole rendere gestibile da remoto tramite protocollo SSH. Il candidato descriva la configurazione del router necessaria per raggiungere lo scopo, motivando nel dettaglio le scelte fatte ed elencando i comandi utilizzabili."

---

### Analisi del Problema

**Scenario**:
- 1 IP pubblico statico (es: 203.0.113.50)
- 1 router di accesso Internet
- 1 web server interno (es: 192.168.0.10)
- Servizi richiesti: HTTP (80), HTTPS (443), SSH (22)

**Requisiti**:
- Accessibilità dall'esterno via HTTP/HTTPS
- Gestione remota via SSH
- Sicurezza delle connessioni

**Soluzione**: **Port Forwarding (DNAT - Destination NAT)**

---

### Architettura della Soluzione

```
Internet                 Router                    LAN Interna
   │                  (1 IP Pubblico)                   │
   │                203.0.113.50                        │
   │                      │                             │
   │  HTTP:80         ┌───┴────┐                        │
   ├─────────────────>│        │   Port Forward         │
   │                  │        │   HTTP:80 → 192.168.0.10:80
   │                  │ Router │───────────────────────>│
   │  HTTPS:443       │  NAT   │                    ┌───┴────┐
   ├─────────────────>│        │   Port Forward     │  Web   │
   │                  │        │   HTTPS:443 → :443 │ Server │
   │                  │        │───────────────────>│192.168.│
   │  SSH:2222        │        │                    │  0.10  │
   ├─────────────────>│        │   Port Forward     │        │
   │                  │        │   SSH:2222 → :22   │        │
   │                  └────────┘───────────────────>└────────┘
```

**Motivazioni delle Scelte**:

1. **Port Forwarding**: Necessario perché con 1 solo IP pubblico, il router deve "instradare" il traffico verso il server interno usando DNAT.

2. **SSH su Porta Non Standard (2222)**: Per sicurezza, si usa porta 2222 esterna invece della standard 22, riducendo attacchi automatizzati.

3. **Firewall Rules**: Limitare accessi solo alle porte necessarie.

4. **HTTPS Obbligatorio**: Traffico cifrato per proteggere dati sensibili.

---

### Configurazione Router - Cisco IOS

```cisco
! ============================================
! Configurazione Port Forwarding - Cisco IOS
! ============================================

! Definizione server interno
ip host webserver 192.168.0.10

! ============================================
! STATIC NAT (Port Forwarding)
! ============================================

! Port Forward HTTP (80)
ip nat inside source static tcp 192.168.0.10 80 interface GigabitEthernet0/0 80

! Port Forward HTTPS (443)
ip nat inside source static tcp 192.168.0.10 443 interface GigabitEthernet0/0 443

! Port Forward SSH (porta esterna 2222 → interna 22)
ip nat inside source static tcp 192.168.0.10 22 interface GigabitEthernet0/0 2222

! ============================================
! INTERFACCE
! ============================================

! WAN Interface (Internet)
interface GigabitEthernet0/0
 description WAN-Internet
 ip address 203.0.113.50 255.255.255.252
 ip nat outside
 ip access-group FIREWALL-IN in
 no shutdown
!

! LAN Interface
interface GigabitEthernet0/1
 description LAN-Interna
 ip address 192.168.0.1 255.255.255.0
 ip nat inside
 no shutdown
!

! ============================================
! FIREWALL ACL
! ============================================

! ACL in ingresso su WAN (permetti solo servizi pubblicati)
ip access-list extended FIREWALL-IN
 ! Permetti traffico established/related
 permit tcp any any established
 !
 ! Permetti HTTP verso web server
 permit tcp any host 203.0.113.50 eq 80
 !
 ! Permetti HTTPS verso web server
 permit tcp any host 203.0.113.50 eq 443
 !
 ! Permetti SSH (porta 2222) verso web server
 ! Opzionale: Limitare a specifici IP sorgente per maggiore sicurezza
 permit tcp any host 203.0.113.50 eq 2222
 !
 ! Permetti ICMP (ping) per troubleshooting
 permit icmp any any echo
 permit icmp any any echo-reply
 permit icmp any any time-exceeded
 permit icmp any any unreachable
 !
 ! Nega tutto il resto e logga
 deny ip any any log
!

! Applica ACL su interfaccia WAN
interface GigabitEthernet0/0
 ip access-group FIREWALL-IN in
!

! ============================================
! ROUTING
! ============================================

! Default route verso ISP
ip route 0.0.0.0 0.0.0.0 203.0.113.49

! ============================================
! DNS
! ============================================

! DNS pubblici (es: Google, Cloudflare)
ip name-server 8.8.8.8
ip name-server 1.1.1.1

! ============================================
! SICUREZZA AGGIUNTIVA
! ============================================

! Rate limiting per SSH (anti brute-force)
ip access-list extended RATE-LIMIT-SSH
 permit tcp any host 203.0.113.50 eq 2222
!
class-map match-all SSH-CLASS
 match access-group name RATE-LIMIT-SSH
!
policy-map SSH-RATE-LIMIT
 class SSH-CLASS
  police 8000 1500 1500 conform-action transmit exceed-action drop
!
interface GigabitEthernet0/0
 service-policy input SSH-RATE-LIMIT
!

! Logging
logging buffered 51200
logging console warnings
logging host 192.168.0.100
!

! ============================================
! VERIFICA CONFIGURAZIONE
! ============================================

! Mostra traduzioni NAT
show ip nat translations

! Mostra statistiche NAT
show ip nat statistics

! Mostra ACL
show access-lists FIREWALL-IN

! Test da esterno:
! curl http://203.0.113.50
! curl https://203.0.113.50
! ssh -p 2222 admin@203.0.113.50

end
write memory
```

---

### Configurazione Router - Linux iptables

```bash
#!/bin/bash
################################################################################
# Configurazione Port Forwarding con iptables (Linux)
################################################################################

# Variabili
WAN_IF="eth0"              # Interfaccia WAN
LAN_IF="eth1"              # Interfaccia LAN
WAN_IP="203.0.113.50"      # IP pubblico
WEBSERVER_IP="192.168.0.10" # IP web server interno

# ============================================
# Abilita IP Forwarding
# ============================================
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# Rendi persistente
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# ============================================
# Flush regole esistenti
# ============================================
iptables -F
iptables -t nat -F
iptables -X

# ============================================
# Policy di Default (DROP)
# ============================================
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ============================================
# LOOPBACK
# ============================================
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ============================================
# INPUT Chain (traffico verso router stesso)
# ============================================

# Permetti traffico established/related
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permetti ICMP
iptables -A INPUT -p icmp -j ACCEPT

# Permetti SSH verso router da LAN
iptables -A INPUT -i $LAN_IF -p tcp --dport 22 -j ACCEPT

# Permetti DNS da LAN
iptables -A INPUT -i $LAN_IF -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i $LAN_IF -p tcp --dport 53 -j ACCEPT

# Drop tutto il resto
iptables -A INPUT -j DROP

# ============================================
# PORT FORWARDING (NAT DNAT)
# ============================================

# HTTP (80)
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 80 \
  -j DNAT --to-destination ${WEBSERVER_IP}:80

# HTTPS (443)
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 443 \
  -j DNAT --to-destination ${WEBSERVER_IP}:443

# SSH (porta esterna 2222 → interna 22)
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 2222 \
  -j DNAT --to-destination ${WEBSERVER_IP}:22

# ============================================
# FORWARD Chain (traffico attraverso router)
# ============================================

# Permetti traffico established/related
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Permetti HTTP verso web server
iptables -A FORWARD -i $WAN_IF -o $LAN_IF -p tcp -d $WEBSERVER_IP --dport 80 -j ACCEPT

# Permetti HTTPS verso web server
iptables -A FORWARD -i $WAN_IF -o $LAN_IF -p tcp -d $WEBSERVER_IP --dport 443 -j ACCEPT

# Permetti SSH verso web server (porta 22 interna)
iptables -A FORWARD -i $WAN_IF -o $LAN_IF -p tcp -d $WEBSERVER_IP --dport 22 \
  -m state --state NEW -m recent --set --name SSH_LIMIT

# Rate limiting SSH (max 3 connessioni in 60 secondi)
iptables -A FORWARD -i $WAN_IF -o $LAN_IF -p tcp -d $WEBSERVER_IP --dport 22 \
  -m state --state NEW -m recent --update --seconds 60 --hitcount 4 --name SSH_LIMIT -j DROP

iptables -A FORWARD -i $WAN_IF -o $LAN_IF -p tcp -d $WEBSERVER_IP --dport 22 -j ACCEPT

# Permetti traffico da LAN verso Internet
iptables -A FORWARD -i $LAN_IF -o $WAN_IF -j ACCEPT

# Drop tutto il resto
iptables -A FORWARD -j DROP

# ============================================
# MASQUERADE (SNAT per LAN)
# ============================================
iptables -t nat -A POSTROUTING -o $WAN_IF -j MASQUERADE

# ============================================
# Logging (opzionale)
# ============================================
# Log dropped packets
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables INPUT DROP: " --log-level 7
iptables -A FORWARD -m limit --limit 5/min -j LOG --log-prefix "iptables FORWARD DROP: " --log-level 7

# ============================================
# Salva configurazione
# ============================================
# Debian/Ubuntu
iptables-save > /etc/iptables/rules.v4

# CentOS/RHEL
# service iptables save

echo "Port Forwarding configurato con successo!"
echo ""
echo "Servizi pubblicati:"
echo "  - HTTP:  http://${WAN_IP}"
echo "  - HTTPS: https://${WAN_IP}"
echo "  - SSH:   ssh -p 2222 user@${WAN_IP}"
echo ""
echo "Verifica NAT:"
echo "  iptables -t nat -L -n -v"
echo ""
echo "Verifica FORWARD:"
echo "  iptables -L FORWARD -n -v"
```

---

### Configurazione Router - MikroTik

```mikrotik
# ============================================
# Port Forwarding - MikroTik RouterOS
# ============================================

# Variabili
:local WANIF "ether1"
:local LANIF "ether2"
:local WANIP "203.0.113.50"
:local WEBSERVER "192.168.0.10"

# ============================================
# DNAT (Port Forwarding)
# ============================================

# HTTP (80)
/ip firewall nat add chain=dstnat in-interface=$WANIF protocol=tcp dst-port=80 \
  action=dst-nat to-addresses=$WEBSERVER to-ports=80 comment="Port Forward HTTP"

# HTTPS (443)
/ip firewall nat add chain=dstnat in-interface=$WANIF protocol=tcp dst-port=443 \
  action=dst-nat to-addresses=$WEBSERVER to-ports=443 comment="Port Forward HTTPS"

# SSH (2222 → 22)
/ip firewall nat add chain=dstnat in-interface=$WANIF protocol=tcp dst-port=2222 \
  action=dst-nat to-addresses=$WEBSERVER to-ports=22 comment="Port Forward SSH"

# ============================================
# FIREWALL FORWARD Rules
# ============================================

# Permetti established/related
/ip firewall filter add chain=forward connection-state=established,related action=accept \
  comment="Allow Established"

# Permetti HTTP
/ip firewall filter add chain=forward in-interface=$WANIF dst-address=$WEBSERVER \
  protocol=tcp dst-port=80 action=accept comment="Allow HTTP to Webserver"

# Permetti HTTPS
/ip firewall filter add chain=forward in-interface=$WANIF dst-address=$WEBSERVER \
  protocol=tcp dst-port=443 action=accept comment="Allow HTTPS to Webserver"

# Permetti SSH con rate limiting
/ip firewall filter add chain=forward in-interface=$WANIF dst-address=$WEBSERVER \
  protocol=tcp dst-port=22 connection-state=new limit=3,5:packet action=accept \
  comment="Allow SSH with rate limit"

/ip firewall filter add chain=forward in-interface=$WANIF dst-address=$WEBSERVER \
  protocol=tcp dst-port=22 action=drop comment="Drop SSH brute-force"

# Drop tutto il resto
/ip firewall filter add chain=forward action=drop comment="Drop all other"

# ============================================
# MASQUERADE (per LAN)
# ============================================
/ip firewall nat add chain=srcnat out-interface=$WANIF action=masquerade \
  comment="Masquerade LAN"

# ============================================
# Verifica
# ============================================
/ip firewall nat print
/ip firewall filter print
```

---

### Sicurezza Aggiuntive Consigliate

#### 1. Fail2Ban (Anti Brute-Force SSH)

```bash
# Installa fail2ban
apt-get install fail2ban

# Configura /etc/fail2ban/jail.local
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

# Riavvia
systemctl restart fail2ban
```

#### 2. Certificato SSL/TLS (Let's Encrypt)

```bash
# Installa certbot
apt-get install certbot python3-certbot-nginx

# Ottieni certificato
certbot --nginx -d example.com -d www.example.com

# Auto-renewal
certbot renew --dry-run
```

#### 3. Web Application Firewall (ModSecurity)

```bash
# Installa ModSecurity
apt-get install libapache2-mod-security2

# Abilita e configura
a2enmod security2
systemctl restart apache2
```

#### 4. Limitazione Accesso SSH per IP

```cisco
! Solo da specifici IP
ip access-list extended SSH-ALLOW
 permit tcp host 198.51.100.10 host 203.0.113.50 eq 2222
 permit tcp 198.51.100.0 0.0.0.255 host 203.0.113.50 eq 2222
 deny tcp any host 203.0.113.50 eq 2222 log
!
```

---

### Test e Verifica

#### Test da Internet (esterno)

```bash
# Test HTTP
curl http://203.0.113.50
wget http://203.0.113.50

# Test HTTPS
curl https://203.0.113.50
openssl s_client -connect 203.0.113.50:443

# Test SSH
ssh -p 2222 admin@203.0.113.50

# Scan porte (da macchina esterna)
nmap -p 80,443,2222 203.0.113.50
```

#### Test da LAN (interno)

```bash
# Verifica web server attivo
curl http://192.168.0.10
curl https://192.168.0.10

# Verifica SSH locale
ssh admin@192.168.0.10

# Verifica NAT
# Su router Cisco:
show ip nat translations
show ip nat statistics

# Su Linux:
iptables -t nat -L -n -v
conntrack -L
```

---

### Documentazione

**File di configurazione salvati**:
- `/etc/iptables/rules.v4` (Linux)
- `startup-config` (Cisco)
- Backup via `/system backup save` (MikroTik)

**Diagramma di flusso**:
```
Client Internet → WAN IP:80/443/2222 → Router (DNAT) → 192.168.0.10:80/443/22
```

**Monitoraggio**:
- Logs: `/var/log/syslog`, `/var/log/auth.log`
- Connessioni attive: `netstat -an | grep ESTABLISHED`
- Traffico: `iftop`, `nethogs`

---

## QUESITO IV: Troubleshooting Connettività Internet

**Testo**: "All'interno di una azienda con una propria LAN, un tecnico di help-desk riceve la segnalazione di un utente circa l'impossibilità di 'navigare su Internet'. Si descrivano i passi e gli opportuni strumenti da utilizzare per individuare tre possibili cause del problema."

---

### Metodologia di Troubleshooting

**Approccio Sistematico - Modello OSI Bottom-Up**:

```
Layer 7 - Application     →  Browser, DNS
Layer 6 - Presentation    →  (generalmente non causa problemi)
Layer 5 - Session         →  (generalmente non causa problemi)
Layer 4 - Transport       →  TCP/UDP, porte, firewall
Layer 3 - Network         →  IP, routing, gateway
Layer 2 - Data Link       →  Switch, VLAN, MAC
Layer 1 - Physical        →  Cavi, connettori, LED
```

**Strategia**:
1. Raccogliere informazioni dall'utente
2. Verificare Layer 1-2 (fisico)
3. Verificare Layer 3 (rete)
4. Verificare Layer 4-7 (applicazione)
5. Identificare e risolvere il problema

---

### PASSO 1: Raccolta Informazioni

**Domande all'utente**:

```
1. Da quanto tempo ha il problema?
2. È sempre stato così o funzionava prima?
3. Può accedere ad altre risorse locali (server aziendali, stampanti)?
4. Altri colleghi hanno lo stesso problema?
5. Quale browser sta usando?
6. Può aprire qualche sito oppure nessuno?
7. Ha fatto modifiche recenti al PC?
8. Messaggio di errore specifico visualizzato?
```

**Informazioni da annotare**:
- Nome utente: _______
- Nome PC: _______
- Indirizzo IP: _______
- Ubicazione fisica: _______
- Timestamp problema: _______

---

### CAUSA 1: Problema Fisico/Data Link (Layer 1-2)

#### Sintomi

- Nessuna connettività, nemmeno locale
- Icona rete Windows: "Nessuna connessione"
- LED switch/NIC spenti o lampeggianti rossi

#### Strumenti e Verifica

**A) Verifica Fisica**

```bash
# Windows
ipconfig /all
# Cerca: "Media disconnected" o "Cable unplugged"

# Linux
ip link show
ethtool eth0
# Cerca: "Link detected: no"

# Output normale (OK):
# eth0: <BROADCAST,MULTICAST,UP,LOWER_UP>
# Link detected: yes
```

**LED NIC/Switch**:
- 🔴 Rosso/Spento → Cavo non collegato o difettoso
- 🟢 Verde fisso → Connessione OK
- 🟡 Giallo lampeggiante → Traffico di rete

**B) Test Cavo Ethernet**

```bash
# Linux - Verifica duplex e velocità
ethtool eth0
# Output atteso:
#   Speed: 1000Mb/s
#   Duplex: Full
#   Link detected: yes

# Se Speed: Unknown o Duplex: Half → Problema cavo o porta switch
```

**C) Verifica Porta Switch**

```bash
# Su switch (Cisco)
show interfaces GigabitEthernet0/12 status
show interfaces GigabitEthernet0/12

# Cerca errori:
show interfaces GigabitEthernet0/12 | include error
# CRC errors, collisions, runts, giants → Cavo difettoso

# Reset porta se necessario
interface GigabitEthernet0/12
 shutdown
 no shutdown
```

**D) Verifica Indirizzo MAC**

```bash
# Windows
ipconfig /all
getmac

# Linux
ip link show eth0
# Cerca: "link/ether XX:XX:XX:XX:XX:XX"

# Verifica MAC su switch
show mac address-table | include <mac-address>
```

#### Soluzione Causa 1

- ✅ Controllare cavo Ethernet (sostituire se necessario)
- ✅ Verificare cavo collegato bene (click)
- ✅ Testare su altra porta switch
- ✅ Verificare porta switch non disabilitata
- ✅ Controllare VLAN assignment corretta
- ✅ Verificare port-security non ha bloccato porta

---

### CAUSA 2: Problema Configurazione IP/Gateway (Layer 3)

#### Sintomi

- Connessione fisica OK (LED verdi)
- Può pingare se stesso ma non gateway
- IP address 169.254.x.x (APIPA) o IP errato
- "Gateway non raggiungibile"

#### Strumenti e Verifica

**A) Verifica Indirizzo IP**

```bash
# Windows
ipconfig /all
# Verifica:
#   - IP Address: 192.168.1.x (nella subnet corretta?)
#   - Subnet Mask: 255.255.255.0
#   - Default Gateway: 192.168.1.1 (configurato?)
#   - DHCP Enabled: Yes (o No se IP statico)
#   - IP Autoconfiguration: 169.254.x.x → DHCP FAIL!

# Linux
ip addr show eth0
ip route show
# Verifica route default via <gateway>
```

**B) Test Connettività Locale**

```bash
# Ping se stesso (test stack TCP/IP)
ping 127.0.0.1          # Loopback
ping 192.168.1.x        # Proprio IP

# Ping gateway
ping 192.168.1.1
# Se fallisce → Problema Layer 3

# Ping altro PC sulla stessa subnet
ping 192.168.1.20
# Se OK ma gateway fail → Problema gateway

# Traceroute
tracert www.google.com  # Windows
traceroute www.google.com # Linux
# Verifica dove si ferma
```

**C) Verifica DHCP**

```bash
# Windows - Rilascia e rinnova IP
ipconfig /release
ipconfig /renew
# Errore: "Unable to contact DHCP server" → DHCP down

# Linux
sudo dhclient -r eth0   # Release
sudo dhclient eth0      # Renew

# Verifica lease DHCP
ipconfig /all           # Windows
cat /var/lib/dhcp/dhclient.eth0.leases  # Linux
```

**D) Verifica ARP (Gateway MAC address)**

```bash
# Verifica ARP table
arp -a                  # Windows/Linux
ip neigh show           # Linux

# Cerca gateway:
# 192.168.1.1  00:1a:2b:3c:4d:5e  REACHABLE
# Se incomplete o nessuna entry → Gateway non risponde ARP
```

**E) Verifica Routing**

```bash
# Windows
route print

# Linux
ip route show
netstat -rn

# Verifica default route presente:
# default via 192.168.1.1 dev eth0
```

#### Soluzione Causa 2

**Se IP APIPA (169.254.x.x)**:
1. DHCP server down o non raggiungibile
2. Configura IP statico temporaneamente
3. Verifica server DHCP funzionante

```bash
# Configurazione IP statica temporanea (Windows)
netsh interface ip set address "Ethernet" static 192.168.1.100 255.255.255.0 192.168.1.1

# Linux
sudo ip addr add 192.168.1.100/24 dev eth0
sudo ip route add default via 192.168.1.1
```

**Se IP corretto ma gateway non raggiungibile**:
1. Gateway/router down o malfunzionante
2. Firewall blocca ICMP
3. Problema routing su gateway

**Se gateway raggiungibile ma no Internet**:
1. Problema DNS (vedi Causa 3)
2. Routing su router errato
3. ISP down

---

### CAUSA 3: Problema DNS (Layer 7)

#### Sintomi

- Può pingare IP pubblici (es: 8.8.8.8)
- Non può navigare siti web (per nome)
- Messaggio: "Server DNS non risponde" o "DNS_PROBE_FINISHED_NXDOMAIN"
- `ping www.google.com` → "could not find host"
- `ping 8.8.8.8` → OK

#### Strumenti e Verifica

**A) Test DNS Resolution**

```bash
# Test ping con nome
ping www.google.com
# Errore: "Ping request could not find host"
# → Problema DNS

# Test ping con IP diretto
ping 8.8.8.8
# Se OK → Connettività Internet OK, solo DNS problematico

# Windows - nslookup
nslookup www.google.com
# Server: UnKnown → DNS server non configurato o errato
# Non-existent domain → DNS non riesce a risolvere

# Linux - dig
dig www.google.com
# ANSWER SECTION vuoto → DNS fail

# Test DNS specifico
nslookup www.google.com 8.8.8.8
# Testa DNS Google direttamente
```

**B) Verifica Configurazione DNS**

```bash
# Windows
ipconfig /all
# Cerca: DNS Servers: 192.168.1.1 o 8.8.8.8

# Se vuoto o 0.0.0.0 → DNS non configurato

# Linux
cat /etc/resolv.conf
# nameserver 192.168.1.1
# nameserver 8.8.8.8

# Se vuoto → DNS non configurato
```

**C) Test DNS Server Raggiungibilità**

```bash
# Ping DNS server
ping 192.168.1.1        # DNS interno
ping 8.8.8.8            # Google DNS

# Test porta DNS (53 UDP)
nslookup - 8.8.8.8      # Test DNS Google
```

**D) Flush DNS Cache**

```bash
# Windows
ipconfig /flushdns
ipconfig /displaydns    # Mostra cache

# Linux
sudo systemd-resolve --flush-caches    # systemd-resolved
sudo service nscd restart               # nscd

# macOS
sudo dscacheutil -flushcache
```

**E) Test Hosts File**

```bash
# Windows
notepad C:\Windows\System32\drivers\etc\hosts

# Linux/macOS
cat /etc/hosts

# Verifica voci che potrebbero interferire
# Es: 127.0.0.1 www.google.com → rimuovere
```

#### Soluzione Causa 3

**Configurazione DNS Manuale**:

```bash
# Windows - GUI
# Control Panel → Network Connections → Properties → TCP/IPv4 → Properties
# DNS: 8.8.8.8, 8.8.4.4 (Google) o 1.1.1.1, 1.0.0.1 (Cloudflare)

# Windows - CLI
netsh interface ip set dns "Ethernet" static 8.8.8.8
netsh interface ip add dns "Ethernet" 8.8.4.4 index=2

# Linux (temporaneo)
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf

# Linux (persistente - NetworkManager)
nmcli con mod "Wired connection 1" ipv4.dns "8.8.8.8 8.8.4.4"
nmcli con up "Wired connection 1"
```

**Verifica DNS dopo fix**:
```bash
nslookup www.google.com
ping www.google.com
# Dovrebbe funzionare ora
```

---

### Riepilogo delle 3 Cause Principali

| Causa | Layer | Sintomi | Test | Soluzione |
|-------|-------|---------|------|-----------|
| **1. Cavo/Fisica** | L1-L2 | LED spenti, "no cable" | `ethtool`, LED, `ipconfig` | Sostituire cavo, verificare porta switch |
| **2. IP/Gateway** | L3 | IP APIPA, gateway unreachable | `ping gateway`, `ipconfig`, `arp` | Rinnova DHCP, configura IP statico, verifica gateway |
| **3. DNS** | L7 | Ping IP OK, nomi FAIL | `nslookup`, `dig`, `ping 8.8.8.8` vs `ping google.com` | Configura DNS pubblici (8.8.8.8), flush cache |

---

### Script di Troubleshooting Automatico

```bash
#!/bin/bash
################################################################################
# Script di Troubleshooting Connettività Internet
################################################################################

echo "=== Troubleshooting Connettività Internet ==="
echo ""

# 1. Verifica interfaccia fisica
echo "[1] Verifica Interfaccia Fisica..."
ip link show | grep -E "^[0-9]|state UP"
if [ $? -eq 0 ]; then
    echo "✅ Interfaccia UP"
else
    echo "❌ Interfaccia DOWN - Controllare cavo"
fi
echo ""

# 2. Verifica IP address
echo "[2] Verifica Indirizzo IP..."
IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [[ $IP == 169.254.* ]]; then
    echo "❌ IP APIPA: $IP - DHCP non funzionante"
elif [ -n "$IP" ]; then
    echo "✅ IP Assegnato: $IP"
else
    echo "❌ Nessun IP assegnato"
fi
echo ""

# 3. Test Gateway
echo "[3] Test Gateway..."
GW=$(ip route | grep default | awk '{print $3}')
if [ -n "$GW" ]; then
    echo "Gateway: $GW"
    ping -c 2 -W 2 $GW > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ Gateway raggiungibile"
    else
        echo "❌ Gateway NON raggiungibile"
    fi
else
    echo "❌ Nessun gateway configurato"
fi
echo ""

# 4. Test Connettività Internet (IP)
echo "[4] Test Connettività Internet (IP)..."
ping -c 2 -W 2 8.8.8.8 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Internet raggiungibile (IP)"
else
    echo "❌ Internet NON raggiungibile (IP)"
fi
echo ""

# 5. Test DNS
echo "[5] Test DNS..."
nslookup www.google.com > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ DNS funzionante"
else
    echo "❌ DNS NON funzionante"
    echo "DNS configurati:"
    cat /etc/resolv.conf | grep nameserver
fi
echo ""

# 6. Test HTTP
echo "[6] Test HTTP..."
curl -s -o /dev/null -w "%{http_code}" http://www.google.com > /tmp/http_test
HTTP_CODE=$(cat /tmp/http_test)
if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "301" ]; then
    echo "✅ HTTP funzionante (Code: $HTTP_CODE)"
else
    echo "❌ HTTP NON funzionante (Code: $HTTP_CODE)"
fi
echo ""

echo "=== Troubleshooting Completato ==="
```

---

### Documentazione del Problema

**Template Ticket**:

```
Ticket #: _______
Data/Ora: _______
Utente: _______
PC: _______

Problema Riportato:
[X] No Internet
[ ] Internet lento
[ ] Alcuni siti non raggiungibili

Test Eseguiti:
[ ] Verifica fisica (LED, cavi)
[ ] ipconfig /all
[ ] ping gateway
[ ] ping 8.8.8.8
[ ] nslookup google.com

Causa Identificata:
[ ] Cavo/Porta switch
[ ] Configurazione IP
[ ] DNS
[ ] Gateway
[ ] Firewall
[ ] Altro: _______

Soluzione Applicata:
_______________________________

Stato: [ ] Risolto [ ] Escalato
```

---

### Conclusione

Le 3 cause più comuni di "impossibilità di navigare su Internet" sono state analizzate con:
- ✅ Sintomi specifici
- ✅ Strumenti di diagnosi
- ✅ Comandi di test
- ✅ Soluzioni passo-passo

Il tecnico help-desk può seguire questo approccio sistematico per risolvere il 90% dei problemi di connettività in modo rapido ed efficace.

---

**Fine Quesiti Seconda Parte**
