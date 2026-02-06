## Lab 6: WireGuard con Container Docker e Client Windows

### Obiettivi
- Configurare un server WireGuard in un container Docker su una VM Linux
- Connettere un client Windows al server containerizzato
- Comprendere l'integrazione VPN con tecnologie container
- Verificare routing e accesso alle risorse

### Topology

```
┌─────────────────────────────────────────────────────────┐
│                    Host Windows                         │
│                                                         │
│  ┌────────────────────────────────┐                     │
│  │   WireGuard Client Windows     │                     │
│  │   VPN IP: 10.10.0.2/24         │                     │
│  │   Interface: wg0               │                     │
│  └──────────────┬─────────────────┘                     │
│                 │                                       │
│                 │ Encrypted Tunnel                      │
│                 │ (UDP 51820)                           │
└─────────────────┼───────────────────────────────────────┘
                  │
            Internet/LAN
                  │
┌─────────────────▼───────────────────────────────────────┐
│              VM Linux (Ubuntu/Debian)                   │
│              Host IP: 192.168.1.100                     │
│                                                         │
│  ┌────────────────────────────────────────────┐         │
│  │   Docker Container: wireguard-server       │         │
│  │   ┌──────────────────────────────┐         │         │
│  │   │  WireGuard Server            │         │         │
│  │   │  VPN IP: 10.10.0.1/24        │         │         │
│  │   │  Listen: 0.0.0.0:51820       │         │         │
│  │   │  Interface: wg0              │         │         │
│  │   └──────────────────────────────┘         │         │
│  │                                            │         │
│  │   Network: host mode (accesso diretto)     │         │
│  └────────────────────────────────────────────┘         │
│                                                         │
│  Internal Resources: 192.168.1.0/24                     │
│  (Web server, File server, Database, etc.)              │
└─────────────────────────────────────────────────────────┘
```

### Prerequisiti

**VM Linux**:
- Ubuntu 22.04+ o Debian 11+
- Docker e Docker Compose installati
- Modulo kernel WireGuard abilitato
- IP statico o DDNS configurato
- Porta UDP 51820 aperta nel firewall

**Client Windows**:
- Windows 10/11
- WireGuard client installato
- Connettività di rete verso la VM

### Parte 1: Preparazione VM Linux

#### Step 1.1: Installazione Docker

```bash
# Update sistema
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install -y docker-compose

# Verifica installazione
docker --version
docker-compose --version

# Aggiungi utente al gruppo docker (opzionale)
sudo usermod -aG docker $USER
# Logout e login per applicare
```

#### Step 1.2: Verifica Modulo Kernel WireGuard

```bash
# Verifica se modulo è presente
lsmod | grep wireguard

# Se non presente, installa tools
sudo apt install -y wireguard-tools

# Carica modulo
sudo modprobe wireguard

# Verifica di nuovo
lsmod | grep wireguard
# Output: wireguard  81920  0
```

#### Step 1.3: Configurazione Firewall

```bash
# Apri porta WireGuard
sudo ufw allow 51820/udp comment 'WireGuard VPN'

# Abilita IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Rendi persistente
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.conf

# Applica
sudo sysctl -p

# Verifica status firewall
sudo ufw status numbered
```

### Parte 2: Configurazione Container WireGuard

#### Step 2.1: Creazione Struttura Directory

```bash
# Crea directory progetto
mkdir -p ~/wireguard-docker
cd ~/wireguard-docker

# Crea directory per configurazioni e chiavi
mkdir -p config
```

#### Step 2.2: Docker Compose Configuration

```bash
# Crea docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: "3.8"

services:
  wireguard:
    image: linuxserver/wireguard:latest
    container_name: wireguard-server
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Rome
      - SERVERURL=192.168.1.100      # IP pubblico o DDNS della VM
      - SERVERPORT=51820
      - PEERS=client-windows          # Nome del peer client
      - PEERDNS=8.8.8.8,1.1.1.1      # DNS per i client
      - INTERNAL_SUBNET=10.10.0.0    # Subnet VPN
      - ALLOWEDIPS=0.0.0.0/0,::/0    # Tutto il traffico via VPN
      - LOG_CONFS=true               # Log configurazioni generate
    volumes:
      - ./config:/config
      - /lib/modules:/lib/modules:ro
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv4.ip_forward=1
    restart: unless-stopped
    networks:
      - wireguard-net

networks:
  wireguard-net:
    driver: bridge
EOF

echo "docker-compose.yml creato"
```

#### Step 2.3: Avvio Container

```bash
# Avvia container
docker-compose up -d

# Verifica logs
docker-compose logs -f wireguard

# Output atteso:
# [cont-init.d] 30-config: executing...
# **** Generating wg0.conf ****
# **** Server mode is selected ****
# **** Internal subnet is set to 10.10.0.0 ****
# **** SERVERURL var is either not set or is set to "auto", setting external IP to auto detected value of 192.168.1.100 ****
# **** Peer Keys for client-windows ****
# [...]

# Attendi che container sia completamente avviato
sleep 10

# Verifica container in esecuzione
docker ps | grep wireguard
```

#### Step 2.4: Verifica Configurazione Server

```bash
# Entra nel container
docker exec -it wireguard-server bash

# All'interno del container:
# Verifica interfaccia WireGuard
wg show

# Output:
# interface: wg0
#   public key: <server-public-key>
#   private key: (hidden)
#   listening port: 51820
#
# peer: <client-windows-public-key>
#   allowed ips: 10.10.0.2/32

# Verifica interfaccia di rete
ip addr show wg0

# Exit dal container
exit
```

#### Step 2.5: Estrazione Configurazione Client

```bash
# Il container genera automaticamente QR code e file di configurazione
# Visualizza QR code (se hai terminale con supporto)
docker exec -it wireguard-server /app/show-peer client-windows

# Oppure copia la configurazione
docker cp wireguard-server:/config/peer_client-windows/peer_client-windows.conf ./client-windows.conf

# Mostra contenuto configurazione
cat ./client-windows.conf

# Output simile a:
# [Interface]
# Address = 10.10.0.2
# PrivateKey = <client-private-key>
# ListenPort = 51820
# DNS = 8.8.8.8,1.1.1.1
#
# [Peer]
# PublicKey = <server-public-key>
# Endpoint = 192.168.1.100:51820
# AllowedIPs = 0.0.0.0/0,::/0
# PersistentKeepalive = 25
```

### Parte 3: Configurazione Client Windows

#### Step 3.1: Installazione WireGuard Windows Client

1. **Download**:
   - Vai a: https://www.wireguard.com/install/
   - Download "Windows Installer"
   - File: `wireguard-installer.exe`

2. **Installazione**:
   ```powershell
   # Esegui installer come Administrator
   # Oppure da PowerShell:
   Start-Process -FilePath "wireguard-installer.exe" -Verb RunAs
   ```

3. **Verifica**:
   - Cerca "WireGuard" nel menu Start
   - Avvia l'applicazione

#### Step 3.2: Import Configurazione

**Metodo 1: Import File**
1. Trasferisci `client-windows.conf` dalla VM al PC Windows
   - Via USB, SCP, email, etc.

2. In WireGuard GUI:
   - Click "Import tunnel(s) from file"
   - Seleziona `client-windows.conf`
   - Configurazione importata come "client-windows"

**Metodo 2: Creazione Manuale**
1. In WireGuard GUI:
   - Click "Add Tunnel" → "Add empty tunnel"
   - Nome: "VPN-Lab-Server"

2. Copia/incolla contenuto da `client-windows.conf`
   ```ini
   [Interface]
   Address = 10.10.0.2/24
   PrivateKey = <copia-da-file-conf>
   DNS = 8.8.8.8, 1.1.1.1

   [Peer]
   PublicKey = <copia-da-file-conf>
   Endpoint = 192.168.1.100:51820
   AllowedIPs = 0.0.0.0/0, ::/0
   PersistentKeepalive = 25
   ```

3. Click "Save"

**Metodo 3: QR Code** (se disponibile)
1. Genera QR da VM:
   ```bash
   docker exec -it wireguard-server /app/show-peer client-windows
   ```

2. Usa app mobile WireGuard per scansionare e esportare config

#### Step 3.3: Connessione VPN

1. **Attiva tunnel**:
   - Seleziona "client-windows" nella lista
   - Click "Activate"

2. **Verifica status**:
   - Status cambia in "Active"
   - Mostra: "Latest handshake: just now"
   - Transfer: bytes sent/received

3. **Verifica IP**:
   ```powershell
   # PowerShell
   ipconfig /all | Select-String -Pattern "WireGuard"
   
   # Output:
   # Wireless LAN adapter WireGuard Tunnel client-windows:
   #   IPv4 Address. . . . . . : 10.10.0.2
   ```

### Parte 4: Test e Verifica

#### Test 4.1: Ping al Server VPN

```powershell
# Windows PowerShell
ping 10.10.0.1

# Output atteso:
# Pinging 10.10.0.1 with 32 bytes of data:
# Reply from 10.10.0.1: bytes=32 time=2ms TTL=64
# Reply from 10.10.0.1: bytes=32 time=1ms TTL=64
```

#### Test 4.2: Verifica IP Pubblico

```powershell
# Windows PowerShell
Invoke-RestMethod -Uri "https://ifconfig.me"

# Dovrebbe mostrare l'IP della VM (192.168.1.100)
# Se mostra il tuo IP originale, il tunnel non è attivo correttamente
```

#### Test 4.3: Accesso Risorse Interne VM

**Scenario**: Web server su VM Linux sulla porta 80

```bash
# Sulla VM, crea un semplice web server
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verifica che sia in ascolto
sudo ss -tlnp | grep :80
```

**Dal client Windows**:
```powershell
# Test connettività
Test-NetConnection -ComputerName 192.168.1.100 -Port 80

# Apri browser e visita
# http://192.168.1.100
# Dovresti vedere la pagina di default di nginx
```

#### Test 4.4: Verifica DNS

```powershell
# Windows PowerShell
nslookup google.com

# Verifica che usi i DNS configurati in WireGuard (8.8.8.8)
# Server:  dns.google
# Address:  8.8.8.8
```

#### Test 4.5: Traceroute

```powershell
# Windows CMD
tracert 8.8.8.8

# Output dovrebbe mostrare:
# 1    <1 ms    <1 ms    <1 ms  10.10.0.1  (VPN gateway)
# 2    2 ms     2 ms     2 ms  192.168.1.1
# [...]
```

#### Test 4.6: Monitoring sul Server

```bash
# Sulla VM, monitora connessioni WireGuard
docker exec -it wireguard-server wg show

# Output:
# interface: wg0
#   public key: ...
#   private key: (hidden)
#   listening port: 51820
#
# peer: <client-windows-public-key>
#   endpoint: <client-windows-ip>:random-port
#   allowed ips: 10.10.0.2/32
#   latest handshake: 45 seconds ago
#   transfer: 15.23 KiB received, 8.91 KiB sent
#   persistent keepalive: every 25 seconds

# Monitora logs in real-time
docker logs -f wireguard-server

# Verifica traffico su interfaccia
docker exec -it wireguard-server tcpdump -i wg0 -n
```

### Parte 5: Configurazioni Avanzate

#### 5.1: Split Tunneling (Solo Traffico Interno)

Modifica configurazione client per routare solo traffico verso la rete interna:

```ini
[Interface]
Address = 10.10.0.2/24
PrivateKey = <your-private-key>
DNS = 8.8.8.8

[Peer]
PublicKey = <server-public-key>
Endpoint = 192.168.1.100:51820
# Solo subnet VPN e interna VM
AllowedIPs = 10.10.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
```

**Verifica**:
- Traffico internet usa connessione diretta
- Traffico verso 192.168.1.0/24 passa per VPN

#### 5.2: Aggiungere Secondo Client

```bash
# Sulla VM, modifica docker-compose.yml
# Cambia: PEERS=client-windows
# In: PEERS=client-windows,client-mobile

# Riavvia container
cd ~/wireguard-docker
docker-compose down
docker-compose up -d

# Estrai configurazione secondo client
docker cp wireguard-server:/config/peer_client-mobile/peer_client-mobile.conf ./client-mobile.conf
```

#### 5.3: Persistence e Backup

```bash
# Backup configurazioni
cd ~/wireguard-docker
tar -czf wireguard-backup-$(date +%Y%m%d).tar.gz config/

# Copia backup in luogo sicuro
scp wireguard-backup-*.tar.gz user@backup-server:/backups/

# Restore (se necessario)
cd ~/wireguard-docker
docker-compose down
rm -rf config/
tar -xzf wireguard-backup-20260206.tar.gz
docker-compose up -d
```

#### 5.4: Monitoring con Grafana (Opzionale)

```bash
# Aggiungi Prometheus WireGuard exporter al docker-compose.yml
cat >> docker-compose.yml <<'EOF'

  wireguard-exporter:
    image: mindflavor/prometheus-wireguard-exporter:latest
    container_name: wireguard-exporter
    command:
      - -n
      - /config/wg0.conf
    volumes:
      - ./config:/config:ro
    ports:
      - 9586:9586
    depends_on:
      - wireguard
    restart: unless-stopped
    networks:
      - wireguard-net
EOF

# Restart stack
docker-compose up -d

# Verifica metrics
curl http://192.168.1.100:9586/metrics
```

### Troubleshooting

#### Problema: Client non si connette

**Verifica**:
```bash
# Sulla VM
# 1. Container in esecuzione?
docker ps | grep wireguard

# 2. Porta aperta?
sudo ss -ulnp | grep 51820

# 3. Firewall?
sudo ufw status | grep 51820

# 4. Logs container
docker logs wireguard-server | tail -50
```

**Windows Client**:
```powershell
# Verifica logs WireGuard
# WireGuard GUI → Log → View Log

# Test connettività UDP
Test-NetConnection -ComputerName 192.168.1.100 -Port 51820
```

#### Problema: Handshake fallisce

**Causa comune**: Chiavi non corrispondenti

**Soluzione**:
```bash
# Rigenera configurazione
docker-compose down
rm -rf config/*
docker-compose up -d

# Re-import nuova configurazione su Windows
```

#### Problema: Connesso ma nessun traffico

**Verifica routing**:
```bash
# Sulla VM, verifica IP forwarding
docker exec -it wireguard-server sysctl net.ipv4.ip_forward
# Deve essere = 1

# Verifica NAT
docker exec -it wireguard-server iptables -t nat -L POSTROUTING -v
```

### Esercizi Aggiuntivi

#### Esercizio 1: Port Forwarding
Configura port forwarding per esporre un servizio interno attraverso il tunnel

**Hint**: Usa `PostUp`/`PostDown` rules nel server config

#### Esercizio 2: IPv6 Support
Abilita dual-stack (IPv4 + IPv6) nel tunnel

**Hint**: Aggiungi `INTERNAL_SUBNET` con range IPv6

#### Esercizio 3: Multi-Site
Collega un secondo container WireGuard (site-to-site) su altra VM

#### Esercizio 4: Kill Switch
Implementa kill switch su Windows per bloccare traffico se VPN disconnette

**Hint**: Usa Windows Firewall rules o script PowerShell

#### Esercizio 5: Monitoring Dashboard
Implementa Grafana dashboard per monitorare:
- Client connessi
- Bandwidth per client
- Latency
- Packet loss

### Domande di Verifica

1. Quali vantaggi offre l'uso di un container per il server VPN?
2. Come verifica WireGuard l'identità dei peer?
3. Che differenza c'è tra `AllowedIPs = 0.0.0.0/0` e `AllowedIPs = 10.10.0.0/24`?
4. Perché è necessario abilitare `IP forwarding` sulla VM?
5. Come si comporta il traffico DNS con la configurazione di default?
6. Cosa succede se `PersistentKeepalive` è disabilitato?
7. Come si può implementare alta disponibilità per il server VPN containerizzato?

### Conclusioni Lab 6

In questo laboratorio hai appreso:
- ✅ Deploy di WireGuard server in container Docker
- ✅ Configurazione client Windows
- ✅ Test di connettività e verifica tunnel
- ✅ Monitoring e troubleshooting
- ✅ Integrazione VPN con infrastruttura containerizzata

Questa configurazione è ideale per:
- Ambienti di test e sviluppo
- Deployment rapidi
---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 5: VPN Failover](Lab5_VPN_Failover.md)
