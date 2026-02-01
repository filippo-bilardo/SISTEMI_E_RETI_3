#!/bin/bash
# ========================================
# FIREWALL CONFIGURATION SCRIPT (iptables)
# Prova A038_ORD24
# Data: 30 Gennaio 2026
# ========================================

set -e

echo "===================================="
echo "CONFIGURAZIONE FIREWALL - iptables"
echo "Prova A038_ORD24"
echo "===================================="

# Backup configurazione esistente
echo "[*] Backup configurazione esistente..."
if [ -f /etc/iptables/rules.v4 ]; then
    cp /etc/iptables/rules.v4 /etc/iptables/rules.v4.backup.$(date +%Y%m%d_%H%M%S)
fi

# ========================================
# FLUSH REGOLE ESISTENTI
# ========================================

echo "[*] Flush regole esistenti..."
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# ========================================
# POLICY DI DEFAULT (DENY ALL)
# ========================================

echo "[*] Impostazione policy di default..."
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ========================================
# LOOPBACK
# ========================================

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ========================================
# CONNESSIONI ESTABLISHED/RELATED
# ========================================

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# ========================================
# PROTEZIONI ANTI-ATTACCO
# ========================================

echo "[*] Configurazione protezioni anti-attacco..."

# Anti-SYN Flood
iptables -A INPUT -p tcp --syn -m limit --limit 20/s --limit-burst 50 -j ACCEPT
iptables -A INPUT -p tcp --syn -j DROP

# Anti-Port Scanning
iptables -N port-scanning
iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
iptables -A port-scanning -j DROP
iptables -A INPUT -j port-scanning

# Anti-Spoofing (blocca pacchetti con IP sorgente invalido)
iptables -A INPUT -s 10.0.0.0/8 -i eth0 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -i eth0 -j DROP
iptables -A INPUT -s 192.168.0.0/16 -i eth0 -j DROP
iptables -A INPUT -s 127.0.0.0/8 -i eth0 -j DROP
iptables -A INPUT -s 169.254.0.0/16 -i eth0 -j DROP

# Blocca pacchetti malformati
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
iptables -A FORWARD -m conntrack --ctstate INVALID -j DROP

# Blocca NULL packets
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Blocca XMAS packets
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

# ========================================
# INPUT - SERVIZI PUBBLICI
# ========================================

echo "[*] Configurazione servizi pubblici..."

# SSH (solo da LAN Admin)
iptables -A INPUT -p tcp --dport 22 -s 10.50.30.0/24 -j ACCEPT

# DNS (UDP/TCP)
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# HTTP/HTTPS
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# SMTP/Submission/IMAPS
iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --dport 587 -j ACCEPT
iptables -A INPUT -p tcp --dport 993 -j ACCEPT

# OpenVPN
iptables -A INPUT -p udp --dport 1194 -j ACCEPT

# PING (rate limited)
iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 5/s -j ACCEPT

# ========================================
# NAT/PAT
# ========================================

echo "[*] Configurazione NAT..."

# Abilita IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

# NAT Masquerading per LAN verso Internet
iptables -t nat -A POSTROUTING -s 10.50.0.0/16 -o eth0 -j MASQUERADE

# Port Forwarding HTTP/HTTPS → Web Server DMZ
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 10.50.100.10:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j DNAT --to-destination 10.50.100.10:443

# Port Forwarding Mail → Mail Server DMZ
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 25 -j DNAT --to-destination 10.50.100.11:25
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 587 -j DNAT --to-destination 10.50.100.11:587
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 993 -j DNAT --to-destination 10.50.100.11:993

# ========================================
# FORWARD - REGOLE DMZ
# ========================================

echo "[*] Configurazione DMZ..."

# Internet → DMZ (solo porte pubbliche)
iptables -A FORWARD -i eth0 -o eth1 -d 10.50.100.0/26 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -d 10.50.100.0/26 -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -d 10.50.100.11 -p tcp --dport 25 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -d 10.50.100.11 -p tcp --dport 587 -j ACCEPT
iptables -A FORWARD -i eth0 -o eth1 -d 10.50.100.11 -p tcp --dport 993 -j ACCEPT

# DMZ → Internet (per aggiornamenti)
iptables -A FORWARD -i eth1 -o eth0 -s 10.50.100.0/26 -j ACCEPT

# DMZ → LAN: BLOCCATO (isolamento completo)
iptables -A FORWARD -s 10.50.100.0/26 -d 10.50.0.0/16 -j DROP

# LAN Admin → DMZ (amministrazione)
iptables -A FORWARD -s 10.50.30.0/24 -d 10.50.100.0/26 -j ACCEPT

# ========================================
# FORWARD - REGOLE LAN
# ========================================

echo "[*] Configurazione LAN..."

# LAN → Internet
iptables -A FORWARD -s 10.50.10.0/24 -o eth0 -j ACCEPT
iptables -A FORWARD -s 10.50.30.0/24 -o eth0 -j ACCEPT

# LAN → Server LAN2
iptables -A FORWARD -s 10.50.10.0/24 -d 10.50.20.0/24 -j ACCEPT
iptables -A FORWARD -s 10.50.30.0/24 -d 10.50.20.0/24 -j ACCEPT

# VPN → LAN
iptables -A FORWARD -i tun0 -s 10.50.200.0/26 -j ACCEPT

# ========================================
# LOGGING (opzionale)
# ========================================

# Log dropped packets (rate limited)
iptables -N LOGGING
iptables -A INPUT -j LOGGING
iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPT-DROP-INPUT: " --log-level 4
iptables -A LOGGING -j DROP

# ========================================
# SALVATAGGIO PERSISTENTE
# ========================================

echo "[*] Salvataggio configurazione..."
iptables-save > /etc/iptables/rules.v4

echo ""
echo "===================================="
echo "CONFIGURAZIONE COMPLETATA!"
echo "===================================="
echo ""
echo "Riepilogo regole attive:"
iptables -L -n -v --line-numbers | head -50

echo ""
echo "Regole NAT:"
iptables -t nat -L -n -v

echo ""
echo "[√] Firewall configurato con successo!"
echo "[√] Configurazione salvata in /etc/iptables/rules.v4"
echo ""
echo "Per verificare:"
echo "  iptables -L -n -v"
echo "  iptables -t nat -L -n -v"
echo ""
