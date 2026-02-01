# CONFIGURAZIONE CPE ROUTER - Strutture Sanitarie Private

## Riferimento alla Prova

**Testo**: Punto 2 - "Indichi la tipologia e le caratteristiche hardware... nonché i dettagli relativi alla eventuale configurazione di rete delle sue porte; espliciti anche i servizi..."

---

## Dispositivo: CPE Router Enterprise

**Modello di riferimento**: Cisco ISR 1100-4G / MikroTik RB4011 / Ubiquiti EdgeRouter

---

## CONFIGURAZIONE ESEMPIO: Struttura #1 "Clinica San Marco"

### Informazioni Struttura
- **Nome**: Clinica Privata San Marco
- **ID Struttura**: 1
- **Subnet assegnata**: 10.100.0.32/27
- **Gateway**: 10.100.0.33
- **Range utilizzabile**: 10.100.0.34 - 10.100.0.62
- **Serial CPE**: CPE-SM-001-2024

---

## 1. CONFIGURAZIONE BASE (Cisco IOS Style)

```cisco
! ============================================
! CPE Router Configurazione
! Struttura: Clinica San Marco
! Data: 2024-01-30
! ============================================

! Hostname e parametri base
hostname CPE-Struttura-001
!
! Banner login
banner login ^C
*****************************************************
* CPE Router - Regione - Rete Sanitaria            *
* Accesso Riservato                                 *
* Struttura: Clinica San Marco                     *
*****************************************************
^C
!
! Configurazione password e sicurezza
enable secret 5 $1$mERr$hx5rVt7rPNoS4wqbXKX7m0
service password-encryption
!
! Disabilita servizi non necessari
no ip http server
no ip http secure-server
no service config
no service pad
!
! Logging
logging buffered 51200
logging console warnings
!
! Timezone
clock timezone CET 1 0
clock summer-time CEST recurring last Sun Mar 2:00 last Sun Oct 3:00
!
! ============================================
! INTERFACCE
! ============================================

! WAN Interface - Verso Rete Regionale
interface GigabitEthernet0/0/0
 description Uplink-Rete-Regionale-Fibra
 ip address 10.100.0.33 255.255.255.224
 ip nat outside
 ip access-group WAN-IN in
 no shutdown
!

! LAN Interface - Verso Rete Interna
interface GigabitEthernet0/0/1
 description LAN-Interna-Struttura
 ip address 192.168.1.1 255.255.255.0
 ip nat inside
 no shutdown
!

! LAN Interface - Bridge con G0/0/1
interface GigabitEthernet0/0/2
 description LAN-Port-2
 switchport mode access
 switchport access vlan 1
 no shutdown
!

interface GigabitEthernet0/0/3
 description LAN-Port-3
 switchport mode access
 switchport access vlan 1
 no shutdown
!

! Management Interface (opzionale)
interface GigabitEthernet0/0/4
 description Management-Port
 ip address 10.100.0.34 255.255.255.224
 no shutdown
!

! ============================================
! ROUTING
! ============================================

! Default route verso core router regionale
ip route 0.0.0.0 0.0.0.0 10.100.0.1
!
! Route specifica per data-center
ip route 10.1.0.0 255.255.255.0 10.100.0.1
!
! Blocca routing verso altre subnet strutture
! (gestito da firewall/ACL)

! ============================================
! NAT CONFIGURATION
! ============================================

! NAT per LAN interna verso WAN
ip nat inside source list NAT-ALLOWED interface GigabitEthernet0/0/0 overload
!
! ACL per traffico da NATtare
ip access-list standard NAT-ALLOWED
 permit 192.168.1.0 0.0.0.255
!

! ============================================
! FIREWALL / ACCESS CONTROL LISTS
! ============================================

! ACL in ingresso su WAN (protezione)
ip access-list extended WAN-IN
 ! Permetti traffico stabilito/correlato
 permit tcp any any established
 permit udp any any established
 !
 ! Permetti SSH da IP gestione regionale
 permit tcp host 10.1.0.200 host 10.100.0.33 eq 22
 !
 ! Permetti ICMP (ping) per monitoring
 permit icmp 10.1.0.0 0.0.0.255 any echo
 permit icmp 10.1.0.0 0.0.0.255 any echo-reply
 !
 ! Permetti IPsec VPN
 permit udp any host 10.100.0.33 eq isakmp
 permit udp any host 10.100.0.33 eq non500-isakmp
 permit esp any host 10.100.0.33
 !
 ! Nega tutto il resto
 deny ip any any log
!

! ACL in uscita da LAN (restrizioni)
ip access-list extended LAN-OUT
 ! Permetti solo verso data-center FSE
 permit tcp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255 eq 443
 permit tcp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255 eq 22
 !
 ! Permetti DNS
 permit udp 192.168.1.0 0.0.0.255 10.1.0.10 eq domain
 permit udp 192.168.1.0 0.0.0.255 10.1.0.11 eq domain
 !
 ! Permetti ICMP per troubleshooting
 permit icmp 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255
 !
 ! BLOCCA traffico verso altre strutture
 deny ip 192.168.1.0 0.0.0.255 10.100.0.0 0.0.255.255 log
 !
 ! BLOCCA accesso generico Internet
 deny ip 192.168.1.0 0.0.0.255 any log
!

! Applica ACL su interfaccia LAN
interface GigabitEthernet0/0/1
 ip access-group LAN-OUT in
!

! ============================================
! DHCP SERVER
! ============================================

! DHCP Pool per LAN interna
ip dhcp excluded-address 192.168.1.1 192.168.1.10
ip dhcp excluded-address 192.168.1.251 192.168.1.254
!
ip dhcp pool LAN-POOL
 network 192.168.1.0 255.255.255.0
 default-router 192.168.1.1
 dns-server 10.1.0.10 10.1.0.11
 domain-name clinicasanmarco.local
 lease 7
!

! ============================================
! DNS
! ============================================

! DNS servers del data-center regionale
ip name-server 10.1.0.10
ip name-server 10.1.0.11
ip domain-lookup
!

! ============================================
! NTP (Sincronizzazione Orario)
! ============================================

ntp server 10.1.0.1
ntp update-calendar
!

! ============================================
! IPsec VPN CONFIGURATION
! ============================================

! Crypto ISAKMP Policy (IKE Phase 1)
crypto isakmp policy 10
 encryption aes 256
 hash sha256
 authentication pre-share
 group 14
 lifetime 86400
!

! Pre-shared key per VPN
crypto isakmp key SuperSecretKey123! address 10.1.0.1
!

! IPsec Transform Set (IKE Phase 2)
crypto ipsec transform-set VPN-TRANSFORM esp-aes 256 esp-sha256-hmac
 mode tunnel
!

! Crypto Map
crypto map VPN-MAP 10 ipsec-isakmp
 set peer 10.1.0.1
 set transform-set VPN-TRANSFORM
 set pfs group14
 match address VPN-TRAFFIC
!

! ACL per traffico da cifrare in VPN
ip access-list extended VPN-TRAFFIC
 permit ip 192.168.1.0 0.0.0.255 10.1.0.0 0.0.0.255
!

! Applica crypto map su WAN interface
interface GigabitEthernet0/0/0
 crypto map VPN-MAP
!

! ============================================
! QoS (Quality of Service)
! ============================================

! Class-map per traffico FSE (priorità alta)
class-map match-any FSE-TRAFFIC
 match access-group name FSE-ACL
!

! Policy-map per QoS
policy-map QOS-POLICY
 class FSE-TRAFFIC
  priority percent 70
  set dscp ef
 class class-default
  fair-queue
  random-detect
!

! ACL per identificare traffico FSE
ip access-list extended FSE-ACL
 permit tcp any 10.1.0.0 0.0.0.255 eq 443
!

! Applica QoS su WAN
interface GigabitEthernet0/0/0
 service-policy output QOS-POLICY
!

! ============================================
! LOGGING E MONITORING
! ============================================

! Syslog remoto verso server gestione
logging host 10.1.0.201
logging trap informational
logging facility local7
!

! SNMP per monitoring
snmp-server community RegioneSNMP RO
snmp-server location "Clinica San Marco - Via Roma 123"
snmp-server contact "admin@clinicasanmarco.it"
snmp-server host 10.1.0.202 version 2c RegioneSNMP
!

! NetFlow per analisi traffico
ip flow-export version 9
ip flow-export destination 10.1.0.202 2055
!
interface GigabitEthernet0/0/0
 ip flow ingress
 ip flow egress
!

! ============================================
! SSH SERVER (Gestione Remota)
! ============================================

! Genera chiavi RSA
crypto key generate rsa modulus 2048
!
! Abilita SSH v2
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
! VTY lines (SSH)
line vty 0 4
 transport input ssh
 login local
 exec-timeout 15 0
 logging synchronous
 access-class SSH-ACCESS in
!

! ACL per limitare accesso SSH
ip access-list standard SSH-ACCESS
 permit 10.1.0.200
 permit 10.1.0.0 0.0.0.255
 deny any log
!

! Utente amministratore locale (backup)
username admin privilege 15 secret SuperAdminPassword123!
username regione-admin privilege 15 secret RegionAdminPass456!
!

! ============================================
! SICUREZZA AGGIUNTIVA
! ============================================

! Login banner
banner login ^C
Unauthorized access is prohibited!
All activities are logged and monitored.
^C
!
banner motd ^C
===========================================
CPE Router - Clinica San Marco
Managed by Regione IT Services
Support: +39 XXX XXXXXXX
===========================================
^C
!

! Disabilita console password (solo local user)
line con 0
 login local
 exec-timeout 10 0
 logging synchronous
!

! TCP/UDP small servers disabilitati
no service tcp-small-servers
no service udp-small-servers
!

! IP Source routing disabilitato
no ip source-route
!

! IP redirects disabilitato
interface GigabitEthernet0/0/0
 no ip redirects
 no ip proxy-arp
!

! ============================================
! BACKUP CONFIGURATION
! ============================================

! Archive per backup configurazione
archive
 path tftp://10.1.0.203/backups/CPE-001-$h-$t
 time-period 10080
!

! ============================================
! ALIAS E SHORTCUT
! ============================================

alias exec sr show ip route
alias exec si show ip interface brief
alias exec sc show crypto isakmp sa
alias exec sv show crypto ipsec sa
alias exec sl show logging
!

! ============================================
! FINE CONFIGURAZIONE
! ============================================

end
!
write memory
```

---

## 2. CONFIGURAZIONE ALTERNATIVA (MikroTik RouterOS)

```mikrotik
# ============================================
# MikroTik RouterOS Configuration
# Struttura: Clinica San Marco
# ============================================

# System Identity
/system identity
set name=CPE-Struttura-001

# ============================================
# INTERFACES
# ============================================

# WAN Interface
/interface ethernet
set [ find default-name=ether1 ] name=ether1-wan comment="Uplink Rete Regionale"

# LAN Interfaces
set [ find default-name=ether2 ] name=ether2-lan comment="LAN Interna"
set [ find default-name=ether3 ] name=ether3-lan
set [ find default-name=ether4 ] name=ether4-lan

# Bridge per LAN
/interface bridge
add name=bridge-lan comment="LAN Bridge"

/interface bridge port
add bridge=bridge-lan interface=ether2-lan
add bridge=bridge-lan interface=ether3-lan
add bridge=bridge-lan interface=ether4-lan

# ============================================
# IP ADDRESSES
# ============================================

# WAN IP
/ip address
add address=10.100.0.33/27 interface=ether1-wan network=10.100.0.32 comment="WAN Rete Regionale"

# LAN IP
add address=192.168.1.1/24 interface=bridge-lan network=192.168.1.0 comment="LAN Interna"

# ============================================
# ROUTING
# ============================================

# Default gateway
/ip route
add dst-address=0.0.0.0/0 gateway=10.100.0.1 comment="Default via Core Router"

# Route specifica data-center
add dst-address=10.1.0.0/24 gateway=10.100.0.1 comment="Data-Center FSE"

# ============================================
# NAT
# ============================================

# Source NAT (masquerade)
/ip firewall nat
add chain=srcnat out-interface=ether1-wan action=masquerade comment="NAT LAN -> WAN"

# ============================================
# FIREWALL
# ============================================

# INPUT Chain (protezione router stesso)
/ip firewall filter

# Permetti traffico established/related
add chain=input connection-state=established,related action=accept comment="Allow Established"

# Permetti ICMP
add chain=input protocol=icmp action=accept comment="Allow ICMP"

# Permetti SSH da IP gestione
add chain=input src-address=10.1.0.200 protocol=tcp dst-port=22 action=accept comment="SSH da Gestione"
add chain=input src-address=10.1.0.0/24 protocol=tcp dst-port=22 action=accept comment="SSH da DC"

# Permetti traffico da LAN
add chain=input in-interface=bridge-lan action=accept comment="Allow from LAN"

# Drop tutto il resto
add chain=input action=drop log=yes log-prefix="FW-INPUT-DROP" comment="Drop all other"

# FORWARD Chain (traffico attraverso router)
# Permetti established/related
add chain=forward connection-state=established,related action=accept comment="Allow Established Forward"

# Permetti LAN -> Data-Center FSE (HTTPS)
add chain=forward src-address=192.168.1.0/24 dst-address=10.1.0.0/24 protocol=tcp dst-port=443 action=accept comment="Allow FSE HTTPS"

# Permetti DNS
add chain=forward src-address=192.168.1.0/24 dst-address=10.1.0.10 protocol=udp dst-port=53 action=accept comment="DNS 1"
add chain=forward src-address=192.168.1.0/24 dst-address=10.1.0.11 protocol=udp dst-port=53 action=accept comment="DNS 2"

# Blocca LAN -> Altre strutture
add chain=forward src-address=192.168.1.0/24 dst-address=10.100.0.0/16 action=drop log=yes log-prefix="BLOCK-INTER-STRUTT" comment="Block altre strutture"

# Blocca LAN -> Internet
add chain=forward src-address=192.168.1.0/24 action=drop log=yes log-prefix="BLOCK-INTERNET" comment="Block Internet"

# ============================================
# DHCP SERVER
# ============================================

# DHCP Pool
/ip pool
add name=dhcp-pool ranges=192.168.1.10-192.168.1.250

# DHCP Server
/ip dhcp-server
add address-pool=dhcp-pool interface=bridge-lan name=dhcp-lan disabled=no

# DHCP Network
/ip dhcp-server network
add address=192.168.1.0/24 gateway=192.168.1.1 dns-server=10.1.0.10,10.1.0.11 domain=clinicasanmarco.local

# ============================================
# DNS
# ============================================

/ip dns
set servers=10.1.0.10,10.1.0.11 allow-remote-requests=yes

# ============================================
# NTP
# ============================================

/system ntp client
set enabled=yes primary-ntp=10.1.0.1

/system clock
set time-zone-name=Europe/Rome

# ============================================
# IPsec VPN
# ============================================

# IPsec Peer
/ip ipsec peer
add address=10.1.0.1/32 name=peer-datacenter exchange-mode=ike2 auth-method=pre-shared-key secret="SuperSecretKey123!"

# IPsec Policy
/ip ipsec policy
add src-address=192.168.1.0/24 dst-address=10.1.0.0/24 peer=peer-datacenter tunnel=yes action=encrypt

# IPsec Proposal
/ip ipsec proposal
set [ find default=yes ] enc-algorithms=aes-256-cbc auth-algorithms=sha256 pfs-group=modp2048

# ============================================
# QoS / QUEUE
# ============================================

# Queue Tree per prioritizzare traffico FSE
/queue tree
add name=queue-wan parent=ether1-wan max-limit=100M

add name=queue-fse parent=queue-wan priority=1 limit-at=50M max-limit=70M packet-mark=fse-traffic comment="Traffico FSE prioritario"

add name=queue-other parent=queue-wan priority=8 limit-at=10M max-limit=30M comment="Altro traffico"

# Mangle per marcare traffico FSE
/ip firewall mangle
add chain=prerouting dst-address=10.1.0.0/24 protocol=tcp dst-port=443 action=mark-packet new-packet-mark=fse-traffic passthrough=yes comment="Mark FSE traffic"

# ============================================
# LOGGING
# ============================================

# Syslog remoto
/system logging action
add name=remote target=remote remote=10.1.0.201 remote-port=514

/system logging
add action=remote topics=info,warning,error

# ============================================
# SNMP
# ============================================

/snmp
set enabled=yes contact="admin@clinicasanmarco.it" location="Clinica San Marco"

/snmp community
add name=RegioneSNMP addresses=10.1.0.202/32 security=read-only

# ============================================
# SSH & USER
# ============================================

# Utenti
/user
add name=admin group=full password="SuperAdminPassword123!" comment="Amministratore locale"
add name=regione-admin group=full password="RegionAdminPass456!" comment="Admin regionale"

# SSH service
/ip service
set ssh port=22 address=10.1.0.0/24

# Disabilita servizi non necessari
set telnet disabled=yes
set ftp disabled=yes
set www disabled=yes
set api disabled=yes
set winbox address=10.1.0.0/24

# ============================================
# BACKUP
# ============================================

# Backup automatico settimanale
/system scheduler
add name=weekly-backup interval=7d on-event="/system backup save name=backup-auto; /tool fetch address=10.1.0.203 upload=yes src-path=backup-auto.backup user=backup password=backup123"

# ============================================
# BANNER
# ============================================

/system note
set note="CPE Router - Clinica San Marco\nManaged by Regione IT Services\nSupport: +39 XXX XXXXXXX"

# ============================================
# FINE CONFIGURAZIONE
# ============================================
```

---

## 3. CHECKLIST POST-CONFIGURAZIONE

### Verifica Connettività

```bash
# Test 1: Ping gateway
ping -c 4 10.100.0.1

# Test 2: Ping data-center
ping -c 4 10.1.0.1

# Test 3: Verifica DNS
nslookup fse.regione.it 10.1.0.10

# Test 4: Verifica VPN IPsec
show crypto isakmp sa
show crypto ipsec sa

# Test 5: Test HTTPS verso FSE
curl -k https://fse.regione.it/api/health

# Test 6: Verifica routing
show ip route
traceroute 10.1.0.10

# Test 7: Verifica NAT
show ip nat translations

# Test 8: Verifica firewall (deve bloccare)
ping 10.100.0.65  # Altra struttura - deve fallire
curl http://google.com  # Internet - deve fallire
```

### Verifica Sicurezza

```bash
# Test 9: Tentativi accesso SSH non autorizzato
ssh admin@10.100.0.33 (da IP non autorizzato) # Deve essere bloccato

# Test 10: Verifica logging
show logging | include BLOCK

# Test 11: Verifica SNMP
snmpwalk -v2c -c RegioneSNMP 10.100.0.33

# Test 12: Verifica QoS
show policy-map interface GigabitEthernet0/0/0
```

### Verifica Servizi

```bash
# Test 13: DHCP
# Connetti dispositivo alla LAN, verifica assegnazione IP 192.168.1.x

# Test 14: NTP
show ntp status
show ntp associations

# Test 15: Syslog
# Verifica ricezione log su server 10.1.0.201
```

---

## 4. MANUTENZIONE E AGGIORNAMENTI

### Backup Configurazione

```bash
# Cisco
copy running-config tftp://10.1.0.203/backups/CPE-001-2024-01-30.cfg

# MikroTik
/system backup save name=backup-2024-01-30
/tool fetch address=10.1.0.203 upload=yes src-path=backup-2024-01-30.backup
```

### Update Firmware

```bash
# Cisco
copy tftp://10.1.0.203/firmware/c1100-universalk9.17.06.05.SPA.bin flash:
reload in 10
boot system flash:c1100-universalk9.17.06.05.SPA.bin

# MikroTik
/system package update check-for-updates
/system package update download
/system reboot
```

### Monitoring Commands

```bash
# CPU & Memory
show processes cpu sorted
show memory statistics

# Interface stats
show interface GigabitEthernet0/0/0
show interface GigabitEthernet0/0/1

# VPN status
show crypto session

# Logs recenti
show logging last 50
```

---

## 5. TROUBLESHOOTING COMUNI

### Problema: VPN non si stabilisce

```bash
# Debug IPsec
debug crypto isakmp
debug crypto ipsec

# Verifica:
# 1. Pre-shared key corretta
# 2. Raggiungibilità peer (10.1.0.1)
# 3. Firewall permette UDP 500, 4500 ed ESP
# 4. Orario sincronizzato (NTP)
```

### Problema: Nessuna connettività verso FSE

```bash
# Verifica routing
ping 10.1.0.1
traceroute 10.1.0.10

# Verifica NAT
show ip nat translations
clear ip nat translation *

# Verifica ACL
show access-lists LAN-OUT
```

### Problema: DHCP non funziona

```bash
# Verifica DHCP pool
show ip dhcp pool
show ip dhcp binding

# Verifica interfaccia
show ip interface brief

# Clear DHCP bindings
clear ip dhcp binding *
```

---

## DOCUMENTAZIONE

File correlati:
- [Piano Indirizzamento](piano_indirizzamento.md)
- [Diagramma Rete](diagramma_rete.md)
- [Script Configurazione](script_configurazione_cpe.sh)
- [Quick Reference](QUICK_REFERENCE.md)
