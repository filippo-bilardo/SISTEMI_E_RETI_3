# Appendice B - Comandi Utili

## Analisi di Rete

### Informazioni interfacce di rete

```bash
# Visualizzare tutte le interfacce
ip addr show
ifconfig -a

# Solo interfacce attive
ip link show up

# Statistiche interfaccia
ip -s link show eth0

# Routing table
ip route show
route -n
netstat -rn
```

### Test connettività

```bash
# Ping base
ping google.com
ping -c 4 8.8.8.8

# Ping con dimensione pacchetto specifica
ping -s 1472 google.com

# Traceroute
traceroute google.com
tracepath google.com

# MTU discovery
ping -M do -s 1472 google.com

# Test porta TCP
nc -zv google.com 443
telnet google.com 443

# Test porta UDP
nc -zvu 8.8.8.8 53
```

### Analisi DNS

```bash
# Query DNS base
dig google.com
nslookup google.com
host google.com

# Query a server DNS specifico
dig @8.8.8.8 google.com

# Query record specifici
dig google.com A        # IPv4
dig google.com AAAA     # IPv6
dig google.com MX       # Mail
dig google.com TXT      # TXT records
dig google.com NS       # Name servers

# Reverse DNS
dig -x 8.8.8.8

# Trace DNS delegation
dig +trace google.com

# DNSSEC check
dig +dnssec google.com

# DNS query time
dig google.com | grep "Query time"
```

### Scan porte

```bash
# Nmap scan base
nmap 192.168.1.1

# Scan porte comuni
nmap -F 192.168.1.1

# Scan tutte le porte
nmap -p- 192.168.1.1

# Scan porte specifiche
nmap -p 22,80,443 192.168.1.1

# Scan con detection OS e versioni
nmap -A 192.168.1.1

# Scan SYN (richiede root)
nmap -sS 192.168.1.1

# Scan UDP
nmap -sU 192.168.1.1

# Scan range di rete
nmap 192.168.1.0/24

# Output in formato greppable
nmap -oG scan.txt 192.168.1.0/24
```

## Firewall iptables

### Visualizzazione regole

```bash
# Visualizza tutte le regole
iptables -L -v -n

# Visualizza con numeri di riga
iptables -L -n --line-numbers

# Visualizza solo INPUT chain
iptables -L INPUT -v -n

# Visualizza NAT rules
iptables -t nat -L -v -n

# Visualizza mangle table
iptables -t mangle -L -v -n
```

### Gestione regole

```bash
# Append regola
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Insert regola in posizione specifica
iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT

# Delete regola per numero
iptables -D INPUT 5

# Delete regola per match
iptables -D INPUT -p tcp --dport 22 -j ACCEPT

# Flush tutte le regole
iptables -F

# Flush chain specifica
iptables -F INPUT

# Set policy di default
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT
```

### Salvataggio/Ripristino

```bash
# Salvare regole (Debian/Ubuntu)
iptables-save > /etc/iptables/rules.v4

# Ripristinare regole
iptables-restore < /etc/iptables/rules.v4

# Salvare (RedHat/CentOS)
service iptables save

# Oppure con firewalld
firewall-cmd --runtime-to-permanent
```

## Monitoraggio Traffico

### tcpdump

```bash
# Catturare traffico su interfaccia
tcpdump -i eth0

# Salvare in file pcap
tcpdump -i eth0 -w capture.pcap

# Leggere da file pcap
tcpdump -r capture.pcap

# Filtrare per host
tcpdump -i eth0 host 192.168.1.10

# Filtrare per porta
tcpdump -i eth0 port 80

# Filtrare per protocollo
tcpdump -i eth0 tcp
tcpdump -i eth0 udp
tcpdump -i eth0 icmp

# Combinare filtri
tcpdump -i eth0 'tcp port 80 and host 192.168.1.10'

# Catturare solo SYN packets
tcpdump -i eth0 'tcp[tcpflags] & tcp-syn != 0'

# Verbose output con ASCII
tcpdump -i eth0 -vv -A

# Limitare numero pacchetti
tcpdump -i eth0 -c 100

# Timestamp leggibili
tcpdump -i eth0 -tttt
```

### netstat / ss

```bash
# Connessioni attive
netstat -tupn
ss -tupn

# Listening sockets
netstat -tuln
ss -tuln

# Statistiche per protocollo
netstat -s
ss -s

# Connessioni per processo
netstat -tulnp
ss -tulnp

# Visualizzare timers
ss -to

# Connessioni TCP in stato specifico
ss -t state established
ss -t state syn-sent
```

### lsof

```bash
# Porte in ascolto
lsof -i -P -n

# Porta specifica
lsof -i :80

# Protocollo specifico
lsof -i tcp
lsof -i udp

# Per processo specifico
lsof -p 1234

# File aperti da utente
lsof -u username

# Connessioni di rete per utente
lsof -u username -i
```

## SSL/TLS

### OpenSSL comandi

```bash
# Test connessione SSL
openssl s_client -connect google.com:443

# Con SNI
openssl s_client -servername google.com -connect google.com:443

# Visualizzare certificato
echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -text

# Visualizzare date validità
echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -dates

# Visualizzare issuer
echo | openssl s_client -connect google.com:443 2>/dev/null | openssl x509 -noout -issuer

# Test protocolli specifici
openssl s_client -connect google.com:443 -tls1_2
openssl s_client -connect google.com:443 -tls1_3

# Generare chiave privata
openssl genrsa -out private.key 2048
openssl genrsa -aes256 -out private.key 2048  # Con password

# Generare CSR
openssl req -new -key private.key -out request.csr

# Generare certificato self-signed
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes

# Verificare certificato
openssl x509 -in cert.pem -text -noout

# Verificare chiave privata
openssl rsa -in private.key -check

# Verificare CSR
openssl req -in request.csr -text -noout

# Verificare che cert e key corrispondano
openssl x509 -noout -modulus -in cert.pem | openssl md5
openssl rsa -noout -modulus -in key.pem | openssl md5
```

## Log Analysis

### grep per analisi log

```bash
# Cerca pattern in log
grep "error" /var/log/syslog

# Case insensitive
grep -i "error" /var/log/syslog

# Conta occorrenze
grep -c "error" /var/log/syslog

# Mostra contesto (3 righe before/after)
grep -C 3 "error" /var/log/syslog

# Cerca in tutti i file log
grep -r "error" /var/log/

# Inverti match (escludi pattern)
grep -v "debug" /var/log/syslog

# Multiple patterns
grep -E "error|warning" /var/log/syslog

# IP addresses
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' /var/log/syslog
```

### Analisi con awk

```bash
# Estrarre colonna specifica (spazio come delimitatore)
awk '{print $1}' file.txt

# Sommare valori di una colonna
awk '{sum+=$1} END {print sum}' file.txt

# Filtrare righe per condizione
awk '$3 > 100' file.txt

# Formattare output
awk '{printf "%-20s %d\n", $1, $2}' file.txt

# IP sources in log
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head
```

### Analisi Apache/Nginx logs

```bash
# Top 10 IP che accedono
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -10

# Top 10 URL richiesti
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head -10

# Status codes count
awk '{print $9}' access.log | sort | uniq -c

# Bandwidth per IP
awk '{ip[$1]+=$10} END {for (i in ip) print i, ip[i]}' access.log | sort -k2 -rn

# Requests per hour
awk '{print $4}' access.log | cut -c 14-15 | sort | uniq -c

# 404 errors
awk '$9 == 404 {print $7}' access.log | sort | uniq -c | sort -rn
```

## Performance e Benchmark

### Bandwidth test

```bash
# iperf server
iperf -s

# iperf client
iperf -c server_ip

# UDP test
iperf -c server_ip -u -b 100M

# Bi-directional test
iperf -c server_ip -d
```

### Apache benchmark

```bash
# Test base (100 requests)
ab -n 100 http://example.com/

# Test con concurrency
ab -n 1000 -c 10 http://example.com/

# Con keepalive
ab -n 1000 -c 10 -k http://example.com/

# POST request
ab -n 100 -p post.data -T application/x-www-form-urlencoded http://example.com/
```

### curl test

```bash
# GET request
curl http://example.com

# Con headers
curl -I http://example.com

# Follow redirects
curl -L http://example.com

# Salvare output
curl -o file.html http://example.com

# Timing dettagliato
curl -w "@curl-format.txt" -o /dev/null -s http://example.com

# curl-format.txt content:
#     time_namelookup:  %{time_namelookup}\n
#        time_connect:  %{time_connect}\n
#     time_appconnect:  %{time_appconnect}\n
#       time_redirect:  %{time_redirect}\n
#  time_starttransfer:  %{time_starttransfer}\n
#          time_total:  %{time_total}\n
```

## System Info

### Processo e risorse

```bash
# Processi
ps aux
ps -ef

# Top processi per CPU
ps aux --sort=-%cpu | head

# Top processi per memoria
ps aux --sort=-%mem | head

# Albero processi
pstree

# Info sistema
uname -a
hostnamectl

# Uptime
uptime

# Memoria
free -h

# Disk usage
df -h
du -sh /var/log/*

# CPU info
lscpu
cat /proc/cpuinfo
```

---

*Fine comandi utili*
