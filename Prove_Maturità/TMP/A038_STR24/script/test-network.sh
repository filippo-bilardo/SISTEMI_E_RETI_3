#!/bin/bash
# Script di Test Completo della Rete
# File: test-network.sh
# Riferimento Prova: Testing e validazione dell'infrastruttura

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

test_ping() {
    local host=$1
    local name=$2
    
    if ping -c 3 -W 2 "$host" &>/dev/null; then
        echo -e "${GREEN}✓${NC} $name ($host) raggiungibile"
        return 0
    else
        echo -e "${RED}✗${NC} $name ($host) NON raggiungibile"
        return 1
    fi
}

test_http() {
    local url=$1
    local expected_code=${2:-200}
    
    local code=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$code" -eq "$expected_code" ]; then
        echo -e "${GREEN}✓${NC} HTTP $url -> $code"
        return 0
    else
        echo -e "${RED}✗${NC} HTTP $url -> $code (atteso: $expected_code)"
        return 1
    fi
}

test_smtp() {
    local host=$1
    
    if echo "QUIT" | nc -w 3 "$host" 25 2>/dev/null | grep -q "220"; then
        echo -e "${GREEN}✓${NC} SMTP $host:25 funzionante"
        return 0
    else
        echo -e "${RED}✗${NC} SMTP $host:25 NON funzionante"
        return 1
    fi
}

test_dns() {
    local domain=$1
    
    if nslookup "$domain" 172.16.2.10 &>/dev/null; then
        local ip=$(nslookup "$domain" 172.16.2.10 | grep "Address:" | tail -1 | awk '{print $2}')
        echo -e "${GREEN}✓${NC} DNS: $domain -> $ip"
        return 0
    else
        echo -e "${RED}✗${NC} DNS: $domain non risolvibile"
        return 1
    fi
}

echo "=== Test di Rete ==="
echo

echo "--- Test Connettività Interna ---"
test_ping "172.16.1.1" "Gateway LAN1"
test_ping "172.16.2.1" "Gateway LAN2"
test_ping "172.16.10.10" "Web Server"
test_ping "172.16.10.11" "Mail Server"
echo

echo "--- Test Connettività Esterna ---"
test_ping "8.8.8.8" "Google DNS"
test_ping "www.google.com" "Google Web"
echo

echo "--- Test DNS ---"
test_dns "web.azienda.local"
test_dns "mail.azienda.local"
echo

echo "--- Test HTTP/HTTPS ---"
test_http "http://172.16.10.10"
test_http "https://172.16.10.10"
echo

echo "--- Test Mail ---"
test_smtp "172.16.10.11"
echo

echo "=== Test Completati ==="
