#!/bin/bash

#############################################
# NETWORK MONITORING SCRIPT - A038_STR24
#############################################
# Monitora lo stato della rete e dei servizi
#############################################

LOG_FILE="/var/log/network-monitor.log"
ALERT_EMAIL="admin@azienda.local"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Funzioni
log_message() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

check_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
        log_message "OK: $2"
        return 0
    else
        echo -e "${RED}✗${NC} $2"
        log_message "ERROR: $2"
        return 1
    fi
}

# Verifica connettività Internet
check_internet() {
    ping -c 3 -W 2 8.8.8.8 &>/dev/null
    check_status $? "Connessione Internet"
}

# Verifica DNS
check_dns() {
    nslookup www.google.com 172.16.2.10 &>/dev/null
    check_status $? "DNS Server (172.16.2.10)"
}

# Verifica servizi
check_service() {
    systemctl is-active --quiet "$1"
    check_status $? "Servizio $1"
}

# Verifica porta
check_port() {
    nc -z -w3 "$1" "$2" &>/dev/null
    check_status $? "$3 ($1:$2)"
}

# CPU Usage
check_cpu() {
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "CPU Usage: ${cpu}%"
    log_message "CPU: ${cpu}%"
}

# Memory Usage
check_memory() {
    mem=$(free | grep Mem | awk '{printf("%.2f"), $3/$2 * 100.0}')
    echo "Memory Usage: ${mem}%"
    log_message "Memory: ${mem}%"
}

# Disk Usage
check_disk() {
    disk=$(df -h / | tail -1 | awk '{print $5}')
    echo "Disk Usage: ${disk}"
    log_message "Disk: ${disk}"
}

# Main
echo "=== Network Monitoring - $(date) ==="
echo

echo "--- Connettività ---"
check_internet
check_dns
echo

echo "--- Servizi ---"
check_service "apache2"
check_service "postfix"
check_service "dovecot"
check_service "bind9"
check_service "isc-dhcp-server"
echo

echo "--- Porte DMZ ---"
check_port "172.16.10.10" "80" "Web Server HTTP"
check_port "172.16.10.10" "443" "Web Server HTTPS"
check_port "172.16.10.11" "25" "Mail Server SMTP"
check_port "172.16.10.11" "993" "Mail Server IMAPS"
echo

echo "--- Risorse Sistema ---"
check_cpu
check_memory
check_disk
echo

echo "=== Monitoring Completato ==="
