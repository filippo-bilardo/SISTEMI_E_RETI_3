# Capitolo 6 - Protocolli e Servizi in DMZ

## 6.1 HTTP/HTTPS

### HTTP (Hypertext Transfer Protocol)

**Porta**: 80 (TCP)  
**Uso**: Traffico web non crittografato  
**Raccomandazione**: **DEPRECATO** - usare solo per redirect a HTTPS

#### Configurazione redirect HTTP → HTTPS

**Apache:**
```apache
<VirtualHost *:80>
    ServerName www.example.com
    Redirect permanent / https://www.example.com/
</VirtualHost>
```

**Nginx:**
```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 https://$server_name$request_uri;
}
```

### HTTPS (HTTP over TLS/SSL)

**Porta**: 443 (TCP)  
**Protocollo di sicurezza**: TLS 1.2 / TLS 1.3  
**Raccomandazione**: **OBBLIGATORIO** per tutto il traffico web

#### Configurazione sicura TLS

**Apache con mod_ssl:**
```apache
<VirtualHost *:443>
    ServerName www.example.com
    
    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.com.crt
    SSLCertificateKeyFile /etc/ssl/private/example.com.key
    SSLCertificateChainFile /etc/ssl/certs/chain.pem
    
    # Protocolli sicuri (no SSLv2, SSLv3, TLS 1.0, TLS 1.1)
    SSLProtocol -all +TLSv1.2 +TLSv1.3
    
    # Cipher suite sicure
    SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder on
    
    # HSTS (HTTP Strict Transport Security)
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    
    # OCSP Stapling
    SSLUseStapling on
    SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"
    
</VirtualHost>
```

**Nginx:**
```nginx
server {
    listen 443 ssl http2;
    server_name www.example.com;
    
    # Certificati
    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;
    
    # Protocolli
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Cipher
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    
    # Session cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/nginx/ssl/chain.pem;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### Gestione certificati

#### Let's Encrypt (gratuito, automatizzato)
```bash
# Installazione certbot
apt-get install certbot python3-certbot-apache  # Per Apache
apt-get install certbot python3-certbot-nginx   # Per Nginx

# Ottenere certificato
certbot --apache -d www.example.com -d example.com  # Apache
certbot --nginx -d www.example.com -d example.com   # Nginx

# Rinnovo automatico (crontab)
0 3 * * * certbot renew --quiet
```

#### Certificati wildcard
```bash
certbot certonly --manual --preferred-challenges dns -d "*.example.com" -d example.com
```

### Test configurazione SSL/TLS

**SSL Labs test:**  
https://www.ssllabs.com/ssltest/

**Command line:**
```bash
# Test con openssl
openssl s_client -connect www.example.com:443

# Test protocolli supportati
nmap --script ssl-enum-ciphers -p 443 www.example.com

# Verificare certificato
echo | openssl s_client -servername www.example.com -connect www.example.com:443 2>/dev/null | openssl x509 -noout -dates
```

## 6.2 FTP e SFTP

### FTP (File Transfer Protocol)

**Porte**: 21 (control), 20 (data in active mode)  
**Sicurezza**: **INSICURO** - credenziali in chiaro  
**Raccomandazione**: **EVITARE** - usare SFTP o FTPS

#### Problemi di FTP

1. **Credenziali non crittografate**: username e password in chiaro
2. **Dati non crittografati**: file trasferiti senza protezione
3. **Problemi con firewall**: modalità attiva/passiva complica il firewalling
4. **Multiple connessioni**: richiede apertura range di porte

#### Se proprio necessario: FTP Passivo

**vsftpd configurazione base:**
```conf
# /etc/vsftpd.conf

# Disabilita anonymous
anonymous_enable=NO

# Abilita local users
local_enable=YES
write_enable=YES

# Chroot users
chroot_local_user=YES
allow_writeable_chroot=YES

# Passive mode
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
pasv_address=203.0.113.10  # IP pubblico

# Logging
xferlog_enable=YES
```

**Regole firewall per FTP passivo:**
```bash
# Control connection
iptables -A FORWARD -p tcp --dport 21 -d $FTP_SERVER -j ACCEPT

# Passive data ports
iptables -A FORWARD -p tcp --dport 40000:40100 -d $FTP_SERVER -j ACCEPT
```

### SFTP (SSH File Transfer Protocol)

**Porta**: 22 (TCP)  
**Sicurezza**: **SICURO** - tutto crittografato tramite SSH  
**Raccomandazione**: **PREFERIRE** a FTP

#### Configurazione SFTP-only user

**sshd_config:**
```conf
# Subsystem sftp
Subsystem sftp internal-sftp

# Match group per SFTP-only users
Match Group sftponly
    ChrootDirectory /home/%u
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
```

#### Creazione utente SFTP-only

```bash
# Creare gruppo
groupadd sftponly

# Creare utente
useradd -g sftponly -s /bin/false -d /home/sftpuser sftpuser
passwd sftpuser

# Configurare chroot directory
chown root:root /home/sftpuser
chmod 755 /home/sftpuser
mkdir /home/sftpuser/uploads
chown sftpuser:sftponly /home/sftpuser/uploads
```

#### Client SFTP

```bash
# Command line
sftp user@server.example.com

# Con chiave SSH
sftp -i /path/to/private_key user@server.example.com

# Comandi SFTP
sftp> put localfile.txt           # Upload
sftp> get remotefile.txt          # Download
sftp> ls                          # List
sftp> cd directory                # Change dir
```

### FTPS (FTP over SSL/TLS)

Alternativa a SFTP, usa SSL/TLS per crittografare FTP.

**vsftpd con SSL:**
```conf
ssl_enable=YES
rsa_cert_file=/etc/ssl/certs/vsftpd.pem
rsa_private_key_file=/etc/ssl/private/vsftpd.key

force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
```

## 6.3 SSH

**Porta**: 22 (TCP)  
**Uso**: Amministrazione remota sicura, SFTP, tunneling  
**Sicurezza**: **SICURO** se configurato correttamente

### Hardening SSH

**sshd_config:**
```conf
# Porta personalizzata (optional, security through obscurity)
Port 2222

# Protocollo
Protocol 2

# Disabilita root login
PermitRootLogin no

# Disabilita password login (solo chiavi)
PasswordAuthentication no
PubkeyAuthentication yes

# Limita utenti
AllowUsers admin deploy

# Disabilita forwarding inutile
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no

# Timeout
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Limita authentication tentativi
MaxAuthTries 3
MaxSessions 2

# Host keys moderni
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key

# Ciphers sicure (solo moderne)
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
```

### Autenticazione con chiave pubblica

```bash
# Generare chiave SSH (client)
ssh-keygen -t ed25519 -C "admin@example.com"

# Copiare chiave pubblica al server
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server

# Oppure manualmente
cat ~/.ssh/id_ed25519.pub | ssh user@server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"

# Impostare permessi corretti sul server
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### SSH Jump Host (Bastion)

Per accedere a server DMZ tramite bastion host in DMZ:

```bash
# Metodo 1: ProxyJump (OpenSSH 7.3+)
ssh -J bastion_user@bastion.example.com target_user@target_server

# Metodo 2: SSH config
# ~/.ssh/config
Host bastion
    HostName bastion.example.com
    User bastion_user
    IdentityFile ~/.ssh/id_bastion

Host dmz-server
    HostName 192.168.100.10
    User admin
    ProxyJump bastion
    IdentityFile ~/.ssh/id_dmz
```

### Fail2ban per protezione SSH

```bash
# Installazione
apt-get install fail2ban

# /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

## 6.4 SMTP, POP3, IMAP

### SMTP (Simple Mail Transfer Protocol)

**Porte**:
- 25 (TCP) - SMTP standard (mail server to mail server)
- 587 (TCP) - SMTP Submission (client to server, con STARTTLS)
- 465 (TCP) - SMTPS (SMTP over SSL, deprecato ma ancora usato)

**Raccomandazione**: Usare porta 587 con STARTTLS per submission

#### Postfix configurazione TLS

```conf
# main.cf

# TLS per connessioni in ingresso (altri mail server)
smtpd_tls_security_level = may
smtpd_tls_cert_file = /etc/ssl/certs/mail.example.com.crt
smtpd_tls_key_file = /etc/ssl/private/mail.example.com.key
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_ciphers = high
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_ciphers = high

# TLS per connessioni in uscita
smtp_tls_security_level = may
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_ciphers = high

# Submission port
submission inet n       -       n       -       -       smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
```

### POP3 e IMAP

**POP3** (Post Office Protocol):
- Porta 110 (non sicura)
- Porta 995 (POP3S - con SSL/TLS)

**IMAP** (Internet Message Access Protocol):
- Porta 143 (non sicura)
- Porta 993 (IMAPS - con SSL/TLS)  

**Raccomandazione**: Usare **SOLO** porte sicure (995, 993)

#### Dovecot configurazione SSL

```conf
# /etc/dovecot/conf.d/10-ssl.conf

ssl = required
ssl_cert = </etc/ssl/certs/mail.example.com.crt
ssl_key = </etc/ssl/private/mail.example.com.key

ssl_protocols = !SSLv3 !TLSv1 !TLSv1.1
ssl_cipher_list = ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384
ssl_prefer_server_ciphers = yes

# Disabilita porte non sicure
service imap-login {
  inet_listener imap {
    port = 0  # Disabilita porta 143
  }
}

service pop3-login {
  inet_listener pop3 {
    port = 0  # Disabilita porta 110
  }
}
```

## 6.5 DNS

**Porta**: 53 (UDP per query, TCP per zone transfer e large responses)  
**Uso**: Risoluzione nomi dominio

### BIND configurazione sicura

```conf
options {
    directory "/var/named";
    
    # Limita ricorsione
    recursion no;  # NO su DNS autoritativo pubblico in DMZ
    
    # Limita query
    allow-query { any; };  # DNS pubblico
    allow-transfer { 203.0.113.50; };  # Solo secondary DNS
    
    # Nascondi versione
    version "Not disclosed";
    hostname "Not disclosed";
    server-id "Not disclosed";
    
    # DNSSEC
    dnssec-enable yes;
    dnssec-validation yes;
    
    # Rate limiting (anti-DDoS)
    rate-limit {
        responses-per-second 10;
        errors-per-second 5;
        window 5;
        log-only no;
    };
    
    # IPv4 only (se non serve IPv6)
    listen-on { 192.168.100.30; };
    listen-on-v6 { none; };
};

# Esempio zona
zone "example.com" IN {
    type master;
    file "example.com.zone";
    allow-update { none; };
    allow-transfer { 203.0.113.50; };  # Secondary DNS IP
    notify yes;
};
```

### DNSSEC

Firma crittografica delle zone DNS per prevenire cache poisoning.

```bash
# Generare chiavi
dnssec-keygen -a RSASHA256 -b 2048 -n ZONE example.com  # ZSK
dnssec-keygen -a RSASHA256 -b 4096 -n ZONE -f KSK example.com  # KSK

# Firmare zona
dnssec-signzone -A -3 $(head -c 1000 /dev/random | sha1sum | cut -b 1-16) \
    -N INCREMENT -o example.com -t example.com.zone
```

### Monitoring DNS

```bash
# Query test
dig @192.168.100.30 example.com

# Check DNSSEC
dig @192.168.100.30 example.com +dnssec

# Query latency
dig @192.168.100.30 example.com | grep "Query time"
```

## 6.6 NTP

**Porta**: 123 (UDP)  
**Uso**: Sincronizzazione oraria

### Importanza della sincronizzazione oraria

- **Logging accurato**: timestamp corretti nei log
- **Certificati SSL**: validità basata su ora
- **Autenticazione**: Kerberos, TOTP richiedono sync
- **Compliance**: audit trail accurati

### ntpd configurazione

```conf
# /etc/ntp.conf

# Server NTP pubblici (pool.ntp.org)
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# Restrict access
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Permettere solo query da LAN interna
restrict 10.0.0.0 mask 255.255.255.0 nomodify notrap

# Drift file
driftfile /var/lib/ntp/drift

# Log
logfile /var/log/ntp.log
```

### chrony (moderno, preferito)

```conf
# /etc/chrony/chrony.conf

# NTP servers
pool pool.ntp.org iburst

# Allow clients from LAN
allow 10.0.0.0/24

# Serve time anche se non sincronizzato con upstream
local stratum 10

# Log dir
logdir /var/log/chrony

# Drift file
driftfile /var/lib/chrony/drift
```

### Firewall rules per NTP

```bash
# DMZ server può queryare NTP pubblico
iptables -A OUTPUT -p udp --dport 123 -j ACCEPT

# LAN client possono queryare NTP in DMZ
iptables -A INPUT -p udp -s 10.0.0.0/24 --dport 123 -j ACCEPT
```

## 6.7 Gestione certificati SSL/TLS

### Tipi di certificati

1. **Domain Validation (DV)**: valida solo proprietà dominio (gratis con Let's Encrypt)
2. **Organization Validation (OV)**: valida anche organizzazione
3. **Extended Validation (EV)**: validazione estesa, barra verde browser (deprecato)

### Certificate Authority (CA)

#### Let's Encrypt (gratis, automatizzato)
- **Validità**: 90 giorni
- **Rinnovo**: automatico con certbot
- **Wildcard**: supportato (con DNS challenge)

#### Commercial CA
- Comodo, DigiCert, GlobalSign
- Certificati OV, EV
- Warranty inclusa

### Lifecycle gestione certificati

```bash
# 1. Generare CSR (Certificate Signing Request)
openssl req -new -newkey rsa:2048 -nodes \
    -keyout example.com.key \
    -out example.com.csr \
    -subj "/C=IT/ST=Lombardia/L=Milano/O=Example Inc/CN=www.example.com"

# 2. Submit CSR a CA (o Let's Encrypt)

# 3. Ricevere certificato firmato

# 4. Installare certificato sul web server
# (vedi sezioni precedenti Apache/Nginx)

# 5. Test con SSL Labs

# 6. Setup monitoring scadenza
echo "0 0 * * * /usr/bin/check_ssl_expiry.sh" | crontab -

# Script check_ssl_expiry.sh
#!/bin/bash
DOMAIN="www.example.com"
DAYS_LEFT=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -enddate | cut -d= -f2 | xargs -I{} date -d "{}" +%s)
CURRENT=$(date +%s)
DIFF=$(( ($DAYS_LEFT - $CURRENT) / 86400 ))

if [ $DIFF -lt 30 ]; then
    echo "Certificate expiring in $DIFF days!" | mail -s "SSL Alert" admin@example.com
fi
```

## 6.8 Esempi di hardening dei servizi

### Web server hardening checklist

- [ ] Disabilitare directory listing
- [ ] Nascondere versione server
- [ ] Impostare security headers
- [ ] Configurare TLS 1.2/1.3 solo
- [ ] Implementare HSTS
- [ ] Disabilitare metodi HTTP non necessari
- [ ] Limitare dimensione upload
- [ ] Configurare timeout appropriati
- [ ] Separare user/group non privilegiati
- [ ] Disabilitare moduli non necessari
- [ ] Log access e errors
- [ ] Implementare fail2ban
- [ ] WAF (Web Application Firewall)

### Mail server hardening checklist

- [ ] TLS obbligatorio
- [ ] SPF, DKIM, DMARC configurati
- [ ] Antispam (SpamAssassin)
- [ ] Antivirus (ClamAV)
- [ ] Rate limiting
- [ ] Blacklist RBL
- [ ] Disabilitare relay aperto
- [ ] SASL authentication
- [ ] Separazione mail gateway/storage
- [ ] Backup mailbox
- [ ] Monitoring queue

## 6.9 Tip and tricks per la sicurezza dei protocolli

### 1. Principle of least exposure
Non esporre servizi non strettamente necessari da Internet.

### 2. Disable legacy protocols
SSLv2, SSLv3, TLS 1.0, TLS 1.1 sono deprecati e insicuri.

### 3. Use strong authentication
- Password complesse + MFA
- Key-based authentication dove possibile
- Rotate credentials regolarmente

### 4. Monitor tutto
- Centralizza log (syslog server)
- Alert automatici per anomalie
- Retention policy conforme a normative

### 5. Keep updated
- Patch regolari
- Subscribe to security mailing list
- Test di vulnerabilità periodici (Nessus, OpenVAS)

### 6. Defense in depth
Non affidarsi a singola protezione, stack multiple layer:
- Firewall
- IDS/IPS  
- WAF
- Host hardening
- Application security

## 6.10 Autovalutazione

### Domande

**1. Perché HTTPS è preferibile a HTTP?**

**2. Qual è la differenza tra SFTP e FTPS?**

**3. Quali porte dovrebbero essere usate per SMTP submission con TLS?**

**4. Cos'è DNSSEC e perché è importante?**

**5. Perché la sincronizzazione NTP è critica in ambienti sicuri?**

### Esercizio

Configura un web server Nginx in DMZ con:
- Redirect HTTP → HTTPS
- TLS 1.2/1.3 only
- Certificato Let's Encrypt
- Security headers appropriati
- Rate limiting

Fornisci la configurazione completa e test di verifica.

---

*[Le risposte si trovano nell'appendice]*
