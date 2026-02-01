#!/bin/bash

#############################################
# FIREWALL SETUP SCRIPT - A038_STR24
#############################################
# Data: 30 Gennaio 2026
# Scopo: Configurazione completa firewall iptables
# Sistema: Linux-based Firewall
#############################################

set -e  # Exit on error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione di log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verifica privilegi root
if [ "$EUID" -ne 0 ]; then 
    error "Questo script deve essere eseguito come root"
fi

log "Inizio configurazione firewall..."

#############################################
# VARIABILI DI CONFIGURAZIONE
#############################################

# Interfacce di rete
WAN_IF="eth0"           # Interfaccia verso Internet
LAN_IF="eth1"           # Interfaccia verso LAN
DMZ_IF="eth2"           # Interfaccia verso DMZ

# Reti interne
LAN1_NET="172.16.1.0/24"    # Utenti
LAN2_NET="172.16.2.0/24"    # Server
LAN3_NET="172.16.3.0/24"    # Admin
DMZ_NET="172.16.10.0/26"    # DMZ
VPN_NET="172.16.20.0/26"    # VPN

# Server in DMZ
WEB_SERVER="172.16.10.10"
MAIL_SERVER="172.16.10.11"

# DNS Server interni
DNS_SERVER="172.16.2.10"

#############################################
# BACKUP REGOLE ESISTENTI
#############################################

log "Backup regole esistenti..."
if [ -f /etc/iptables/rules.v4 ]; then
    cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S)
    log "Backup salvato"
fi

#############################################
# PULIZIA REGOLE ESISTENTI
#############################################

log "Pulizia regole esistenti..."

# Flush di tutte le regole
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -t raw -F
iptables -t raw -X

# Reset contatori
iptables -Z

log "Regole esistenti eliminate"

#############################################
# POLICY DI DEFAULT
#############################################

log "Impostazione policy di default..."

# Policy restrittive
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

log "Policy di default impostate (DROP)"

#############################################
# LOOPBACK
#############################################

log "Configurazione interfaccia loopback..."

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#############################################
# CONNESSIONI STABILITE E CORRELATE
#############################################

log "Configurazione connessioni stabilite..."

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Blocco pacchetti INVALID
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

#############################################
# PROTEZIONE CONTRO ATTACCHI
#############################################

log "Configurazione protezioni anti-attacco..."

# Protezione contro SYN flood
iptables -N syn_flood
iptables -A INPUT -p tcp --syn -j syn_flood
iptables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
iptables -A syn_flood -j DROP

# Protezione contro Port Scanning
iptables -N port-scanning
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A port-scanning -j DROP

# Blocco pacchetti con flag TCP invalidi
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

# Protezione contro IP Spoofing
iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -i $WAN_IF -j DROP
iptables -A INPUT -s 192.168.0.0/16 -i $WAN_IF -j DROP
iptables -A INPUT -s 127.0.0.0/8 -j DROP

# Protezione contro Ping of Death
iptables -A INPUT -p icmp --icmp-type echo-request -m length --length 60:65535 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

#############################################
# SERVIZI DI AMMINISTRAZIONE
#############################################

log "Configurazione accesso amministrativo..."

# SSH - Solo da rete Admin con rate limiting
iptables -A INPUT -p tcp -s $LAN3_NET --dport 22 -m conntrack --ctstate NEW -m recent --set --name SSH
iptables -A INPUT -p tcp -s $LAN3_NET --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
iptables -A INPUT -p tcp -s $LAN3_NET --dport 22 -j ACCEPT

#############################################
# ICMP (PING)
#############################################

log "Configurazione ICMP..."

# Permetti ping limitato
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 2 -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT

# Forward ICMP limitato
iptables -A FORWARD -p icmp --icmp-type echo-request -m limit --limit 1/s -j ACCEPT
iptables -A FORWARD -p icmp --icmp-type echo-reply -j ACCEPT

#############################################
# DMZ - SERVIZI PUBBLICI
#############################################

log "Configurazione DMZ..."

# Web Server (HTTP/HTTPS)
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $WEB_SERVER -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $WEB_SERVER -p tcp --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# Mail Server (SMTP, SMTPS, Submission)
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 25 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 465 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 587 -m conntrack --ctstate NEW -j ACCEPT

# Mail Server (IMAP, IMAPS, POP3, POP3S)
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 143 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 993 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 110 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i $WAN_IF -o $DMZ_IF -d $MAIL_SERVER -p tcp --dport 995 -m conntrack --ctstate NEW -j ACCEPT

# Blocco traffico da DMZ verso LAN (isolamento)
iptables -A FORWARD -i $DMZ_IF -d $LAN1_NET -j DROP
iptables -A FORWARD -i $DMZ_IF -d $LAN2_NET -j DROP
iptables -A FORWARD -i $DMZ_IF -d $LAN3_NET -j DROP

# Permetti DMZ verso Internet (per aggiornamenti)
iptables -A FORWARD -i $DMZ_IF -o $WAN_IF -j ACCEPT

#############################################
# LAN VERSO INTERNET
#############################################

log "Configurazione accesso Internet per LAN..."

# LAN1 (Utenti) verso Internet
iptables -A FORWARD -i $LAN_IF -s $LAN1_NET -o $WAN_IF -j ACCEPT

# LAN3 (Admin) verso Internet
iptables -A FORWARD -i $LAN_IF -s $LAN3_NET -o $WAN_IF -j ACCEPT

#############################################
# LAN VERSO SERVER INTERNI
#############################################

log "Configurazione accesso server interni..."

# LAN1 verso LAN2 (Server)
iptables -A FORWARD -i $LAN_IF -s $LAN1_NET -d $LAN2_NET -j ACCEPT

# LAN3 verso LAN2 (Server)
iptables -A FORWARD -i $LAN_IF -s $LAN3_NET -d $LAN2_NET -j ACCEPT

# LAN3 verso DMZ (per amministrazione)
iptables -A FORWARD -i $LAN_IF -s $LAN3_NET -d $DMZ_NET -j ACCEPT

#############################################
# DNS
#############################################

log "Configurazione DNS..."

# Permetti DNS dal firewall stesso
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p udp --sport 53 -j ACCEPT

# Forward DNS dalle LAN
iptables -A FORWARD -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -p tcp --dport 53 -j ACCEPT

#############################################
# VPN
#############################################

log "Configurazione VPN..."

# OpenVPN
iptables -A INPUT -i $WAN_IF -p udp --dport 1194 -j ACCEPT

# Traffico VPN
iptables -A INPUT -i tun+ -j ACCEPT
iptables -A FORWARD -i tun+ -j ACCEPT
iptables -A FORWARD -o tun+ -j ACCEPT

#############################################
# NAT CONFIGURATION
#############################################

log "Configurazione NAT..."

# Masquerading per LAN verso Internet
iptables -t nat -A POSTROUTING -o $WAN_IF -s $LAN1_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WAN_IF -s $LAN2_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WAN_IF -s $LAN3_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WAN_IF -s $DMZ_NET -j MASQUERADE
iptables -t nat -A POSTROUTING -o $WAN_IF -s $VPN_NET -j MASQUERADE

# Port Forwarding (DNAT) per DMZ
# HTTP -> Web Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 80 -j DNAT --to-destination $WEB_SERVER:80

# HTTPS -> Web Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 443 -j DNAT --to-destination $WEB_SERVER:443

# SMTP -> Mail Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 25 -j DNAT --to-destination $MAIL_SERVER:25

# SMTPS -> Mail Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 465 -j DNAT --to-destination $MAIL_SERVER:465

# Submission -> Mail Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 587 -j DNAT --to-destination $MAIL_SERVER:587

# IMAPS -> Mail Server
iptables -t nat -A PREROUTING -i $WAN_IF -p tcp --dport 993 -j DNAT --to-destination $MAIL_SERVER:993

#############################################
# LOGGING
#############################################

log "Configurazione logging..."

# Log connessioni droppate (limitato)
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A FORWARD -j LOGGING
iptables -A LOGGING -m limit --limit 5/min -j LOG --log-prefix "iptables-DROP: " --log-level 7
iptables -A LOGGING -j DROP

#############################################
# SALVATAGGIO REGOLE
#############################################

log "Salvataggio regole..."

# Creazione directory se non esiste
mkdir -p /etc/iptables

# Salvataggio
iptables-save > /etc/iptables/rules.v4

# Verifica salvataggio
if [ $? -eq 0 ]; then
    log "Regole salvate correttamente in /etc/iptables/rules.v4"
else
    error "Errore nel salvataggio delle regole"
fi

#############################################
# PERSISTENZA AL RIAVVIO
#############################################

log "Configurazione persistenza..."

# Installazione iptables-persistent (se non presente)
if ! dpkg -l | grep -q iptables-persistent; then
    warning "iptables-persistent non installato"
    log "Installazione iptables-persistent..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
fi

# Abilitazione servizio
systemctl enable netfilter-persistent

#############################################
# IP FORWARDING
#############################################

log "Abilitazione IP forwarding..."

# Temporaneo
echo 1 > /proc/sys/net/ipv4/ip_forward

# Permanente
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
fi

# Altre ottimizzazioni di sicurezza
cat >> /etc/sysctl.conf << EOF

# Protezione contro IP spoofing
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignora ICMP redirects
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Ignora source routed packets
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# Log Martian Packets
net.ipv4.conf.all.log_martians=1

# Ignora broadcast pings
net.ipv4.icmp_echo_ignore_broadcasts=1

# Protezione contro SYN cookies
net.ipv4.tcp_syncookies=1

# Ignora bad ICMP errors
net.ipv4.icmp_ignore_bogus_error_responses=1
EOF

# Applica modifiche sysctl
sysctl -p

#############################################
# VERIFICA FINALE
#############################################

log "Verifica configurazione..."

echo ""
echo "========================================="
echo "RIEPILOGO CONFIGURAZIONE FIREWALL"
echo "========================================="
echo ""
echo "Policy di default:"
iptables -L -n | grep "Chain"
echo ""
echo "Regole NAT attive:"
iptables -t nat -L -n --line-numbers | head -20
echo ""
echo "Numero totale regole:"
echo "  - Filter: $(iptables -L -n | grep -c "^Chain")"
echo "  - NAT: $(iptables -t nat -L -n | grep -c "^Chain")"
echo ""
echo "IP Forwarding: $(cat /proc/sys/net/ipv4/ip_forward)"
echo ""
echo "========================================="

log "Configurazione firewall completata con successo!"

echo ""
echo -e "${GREEN}Per visualizzare le regole:${NC}"
echo "  iptables -L -n -v"
echo "  iptables -t nat -L -n -v"
echo ""
echo -e "${GREEN}Per ripristinare le regole al riavvio:${NC}"
echo "  systemctl status netfilter-persistent"
echo ""
echo -e "${YELLOW}ATTENZIONE:${NC} Verifica la connettività prima di disconnetterti!"
echo ""

exit 0
