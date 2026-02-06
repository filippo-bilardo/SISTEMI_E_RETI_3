# Lab 7: Headscale - VPN Mesh Network Self-Hosted

## Obiettivi

- Installare e configurare un server Headscale (alternativa open-source a Tailscale)
- Configurare client Windows con Tailscale client
- Configurare client Linux (VM o container)
- Comprendere il funzionamento delle VPN mesh basate su WireGuard
- Gestire utenti, namespace e ACL
- Implementare routing mesh tra tutti i nodi

## Introduzione a Headscale

**Headscale** è un'implementazione open-source del server di controllo di Tailscale, che permette di creare reti VPN mesh self-hosted basate su WireGuard. A differenza di Tailscale (che usa server cloud proprietari), Headscale consente il controllo completo dell'infrastruttura.

### Vantaggi
- **Self-hosted**: Controllo totale dei dati
- **Zero-trust networking**: Ogni connessione è autenticata
- **NAT traversal**: Connessioni dirette peer-to-peer quando possibile
- **Multi-platform**: Windows, Linux, macOS, Android, iOS
- **ACL granulari**: Controllo accessi dettagliato

## Topologia di Rete

```
                    Headscale Server
                    (VM Linux/Container)
                    192.168.1.50:8080
                    100.64.0.1 (mesh IP)
                            |
            +---------------+---------------+
            |                               |
    Windows Client                    Linux Client
    (Tailscale)                       (VM/Container)
    100.64.0.2                        100.64.0.3
            |                               |
            +----------- Mesh VPN -----------+
                   (Direct P2P via WireGuard)
```

## Prerequisiti

- **Server**: VM Linux (Ubuntu 22.04 LTS) o container Docker (per Headscale self-hosted)
- **Client Windows**: Windows 10/11
- **Client Linux**: VM Ubuntu o container Docker
- Connettività Internet su tutti i nodi
- Porte aperte: 8080 (HTTP/HTTPS), 41641 (DERP relay - opzionale) - solo per Headscale

## Scelta: Headscale (Self-Hosted) vs Tailscale (Cloud)

Questo lab offre **due percorsi alternativi**:

### 🏠 Percorso A: Headscale Self-Hosted
- **Vantaggio**: Controllo completo, privacy totale, nessun costo
- **Svantaggio**: Richiede manutenzione server, setup più complesso
- **Ideale per**: Ambienti aziendali, compliance strict, apprendimento
- **Segui**: Parte 1A → Parte 2 → Parte 3 → Testing

### ☁️ Percorso B: Tailscale Cloud (Gestito)
- **Vantaggio**: Setup immediato, zero manutenzione, app mobile integrate, DERP globali
- **Svantaggio**: Dati di controllo su server Tailscale (traffico P2P comunque criptato)
- **Ideale per**: Uso personale, team piccoli (fino a 100 dispositivi gratis), prototipazione rapida
- **Segui**: Parte 1B → Parte 2 → Parte 3 → Testing

**💡 Nota**: I client Tailscale sono identici per entrambi i percorsi. La differenza è solo nel **control plane** (server di coordinamento).

---

## Parte 1A: Installazione Headscale Server (Self-Hosted)

### Opzione A: Installazione su VM Linux

#### Step 1.1: Download e Installazione

```bash
# Update sistema
sudo apt update && sudo apt upgrade -y

# Scarica Headscale (ultima versione)
HEADSCALE_VERSION="0.23.0"
wget https://github.com/juanfont/headscale/releases/download/v${HEADSCALE_VERSION}/headscale_${HEADSCALE_VERSION}_linux_amd64.deb

# Installa
sudo dpkg -i headscale_${HEADSCALE_VERSION}_linux_amd64.deb

# Verifica installazione
headscale version
```

#### Step 1.2: Configurazione Base

```bash
# Directory configurazione
sudo mkdir -p /etc/headscale

# Configurazione
sudo tee /etc/headscale/config.yaml > /dev/null <<EOF
server_url: http://192.168.1.50:8080
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 127.0.0.1:9090

# IP prefix per la rete mesh
ip_prefixes:
  - 100.64.0.0/10

# Database
db_type: sqlite3
db_path: /var/lib/headscale/db.sqlite

# DERP (relay) configuration
derp:
  server:
    enabled: false
  urls:
    - https://controlplane.tailscale.com/derpmap/default

# DNS
dns_config:
  nameservers:
    - 1.1.1.1
    - 8.8.8.8
  magic_dns: true
  base_domain: vpn.local

# ACL (Access Control List)
acl_policy_path: /etc/headscale/acl.yaml

# Logging
log_level: info

# Unix socket
unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"
EOF

# Crea directory database
sudo mkdir -p /var/lib/headscale

# ACL Policy (permetti tutto per iniziare)
sudo tee /etc/headscale/acl.yaml > /dev/null <<EOF
acls:
  - action: accept
    src:
      - "*"
    dst:
      - "*:*"
EOF
```

#### Step 1.3: Avvio Servizio

```bash
# Abilita e avvia
sudo systemctl enable headscale
sudo systemctl start headscale

# Verifica status
sudo systemctl status headscale

# Check logs
sudo journalctl -u headscale -f
```

### Opzione B: Installazione con Docker

#### Step 1.4: Docker Compose Setup

```bash
# Crea directory progetto
mkdir -p ~/headscale
cd ~/headscale

# docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  headscale:
    image: headscale/headscale:0.23.0
    container_name: headscale
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "9090:9090"  # Metrics
    volumes:
      - ./config:/etc/headscale
      - ./data:/var/lib/headscale
    command: serve
    networks:
      - headscale-net

networks:
  headscale-net:
    driver: bridge
EOF

# Crea directories
mkdir -p config data

# Configurazione (come sopra)
cat > config/config.yaml <<'EOF'
server_url: http://192.168.1.50:8080
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 0.0.0.0:9090

ip_prefixes:
  - 100.64.0.0/10

db_type: sqlite3
db_path: /var/lib/headscale/db.sqlite

derp:
  server:
    enabled: false
  urls:
    - https://controlplane.tailscale.com/derpmap/default

dns_config:
  nameservers:
    - 1.1.1.1
    - 8.8.8.8
  magic_dns: true
  base_domain: vpn.local

acl_policy_path: /etc/headscale/acl.yaml

log_level: info
unix_socket: /var/run/headscale/headscale.sock
EOF

# ACL
cat > config/acl.yaml <<EOF
acls:
  - action: accept
    src:
      - "*"
    dst:
      - "*:*"
EOF

# Avvia container
docker-compose up -d

# Verifica
docker-compose logs -f
```

#### Step 1.5: Creazione Namespace e Utente

```bash
# Se installazione nativa
sudo headscale namespaces create default

# Se Docker
docker exec headscale headscale namespaces create default

# Lista namespaces
sudo headscale namespaces list
# oppure
docker exec headscale headscale namespaces list
```

**Nota**: Per semplicità, da ora useremo comandi nativi. Per Docker, anteporre `docker exec headscale`.

---

## Parte 1B: Setup con Tailscale Cloud (Alternativa Gestita)

**Se preferisci usare Tailscale invece di Headscale**, salta la Parte 1A e segui questi step:

### Step 1B.1: Registrazione Account Tailscale

```bash
# Apri browser e vai a:
# https://login.tailscale.com/start

# Registrati con:
# - Google Account
# - Microsoft Account
# - GitHub Account
# - Email (SSO aziendale)

# Piano gratuito include:
# - 100 dispositivi
# - 3 utenti
# - Subnet routing
# - Exit nodes
# - MagicDNS
```

### Step 1B.2: Verifica Dashboard

```
# Accedi alla dashboard:
https://login.tailscale.com/admin/machines

# La dashboard mostra:
# - Tutti i dispositivi connessi
# - Indirizzi IP mesh (100.x.y.z)
# - Stato online/offline
# - ACL policies
# - DNS settings
```

### Step 1B.3: Differenze Chiave Tailscale vs Headscale

| Caratteristica | Headscale | Tailscale |
|----------------|-----------|-----------|
| Hosting | Self-hosted | Cloud gestito |
| Setup iniziale | Complesso (server + DB) | Immediato (solo account) |
| Costo | Gratis (solo infra) | Gratis fino 100 dev |
| DERP relay | Opzionale/custom | Globale incluso |
| Control plane | Tuo server | Server Tailscale |
| Traffico dati | P2P diretto | P2P diretto |
| Privacy metadati | Completa | Metadati su Tailscale |
| Manutenzione | Tua responsabilità | Zero |
| App mobile | Client generico | App native ottimizzate |
| Support | Community | Ufficiale (paid) |

**Quando usare Tailscale Cloud**:
- Team piccoli (< 100 dispositivi)
- Vuoi zero manutenzione
- Serve supporto app mobile integrate
- Prototipazione rapida

**Quando usare Headscale**:
- Requisiti privacy/compliance strict
- Ambiente enterprise on-premise
- Apprendimento self-hosting
- Più di 100 dispositivi gratis

**💡 Importante**: Con Tailscale, **non serve alcun server**. Vai direttamente alla Parte 2 per configurare i client.

---

## Parte 2: Configurazione Client Windows

### Step 2.1: Installazione Tailscale Client

```powershell
# Download Tailscale per Windows
# https://tailscale.com/download/windows

# Oppure con winget
winget install tailscale.tailscale
```

### Step 2.2: Configurazione Control Server

**Per Headscale (self-hosted)**: Configura custom control server

```powershell
# Apri PowerShell come Amministratore

# Naviga alla directory Tailscale
cd "C:\Program Files\Tailscale"

# Configura control server HEADSCALE
.\tailscale.exe up --login-server=http://192.168.1.50:8080

# Output mostrerà URL per registrazione:
# To authenticate, visit:
# http://192.168.1.50:8080/register?key=nodekey:xxxxxxxxxxxxx
```

**Per Tailscale Cloud**: Setup diretto senza server custom

```powershell
# Avvia Tailscale da Start Menu
# oppure da PowerShell
cd "C:\Program Files\Tailscale"
.\tailscale.exe up

# Si aprirà browser per login
# Autenticati con account creato in Parte 1B

# Dopo login, il dispositivo appare automaticamente nella dashboard
# https://login.tailscale.com/admin/machines
```

### Step 2.3A: Registrazione Nodo su Headscale Server (Solo Self-Hosted)

**⚠️ Salta questo step se usi Tailscale Cloud** (registrazione automatica via browser)

**Sul server Headscale**, copia la chiave dalla richiesta del client e registra:

```bash
# Registra il nodo (copia nodekey dall'output precedente)
sudo headscale nodes register --namespace default --key nodekey:xxxxxxxxxxxxx

# Verifica nodi registrati
sudo headscale nodes list

# Output esempio:
# ID | Hostname      | Namespace | IP addresses | Status | Last seen
# 1  | WIN-CLIENT    | default   | 100.64.0.2   | online | 2024-02-06 10:30:00
```

### Step 2.3B: Verifica Registrazione su Tailscale Cloud (Solo Cloud)

**⚠️ Usa questo step solo se hai scelto Tailscale Cloud**

```powershell
# Apri dashboard Tailscale
# https://login.tailscale.com/admin/machines

# Dovresti vedere il dispositivo Windows nella lista:
# Nome: WIN-CLIENT (o hostname del tuo PC)
# IP: 100.x.y.z
# Status: Connected
# Last seen: pochi secondi fa

# Opzionale: Rinomina dispositivo dalla dashboard
# Click sul dispositivo → Edit → Cambia nome
```

### Step 2.4: Verifica Connessione Windows

```powershell
# Verifica status
tailscale.exe status

# Ping server Headscale (mesh IP)
ping 100.64.0.1

# Mostra IP mesh assegnato
tailscale.exe ip -4
```

---

## Parte 3: Configurazione Client Linux

### Opzione A: Client su VM Linux

#### Step 3.1: Installazione Tailscale

```bash
# Aggiungi repository Tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarch.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.list | sudo tee /etc/apt/sources.list.d/tailscale.list

# Installa
sudo apt update
sudo apt install -y tailscale

# Verifica
tailscale version
```

#### Step 3.2: Connessione al Control Server

**Per Headscale (self-hosted)**:

```bash
# Up con custom control server
sudo tailscale up --login-server=http://192.168.1.50:8080

# Copia l'URL di registrazione dall'output
```

**Per Tailscale Cloud**:

```bash
# Up con server Tailscale ufficiale (default)
sudo tailscale up

# Si aprirà link per autenticazione
# https://login.tailscale.com/a/xxxxxx

# Copia URL e aprilo in browser per completare login
# Il nodo apparirà automaticamente nella dashboard
```

#### Step 3.3A: Registrazione su Headscale Server (Solo Self-Hosted)

**⚠️ Salta questo step se usi Tailscale Cloud**

```bash
# Sul server Headscale
sudo headscale nodes register --namespace default --key nodekey:yyyyyyyyyyyyy

# Verifica
sudo headscale nodes list

# Output:
# ID | Hostname      | Namespace | IP addresses | Status | Last seen
# 1  | WIN-CLIENT    | default   | 100.64.0.2   | online | 2024-02-06 10:30:00
# 2  | LINUX-VM      | default   | 100.64.0.3   | online | 2024-02-06 10:35:00
```

#### Step 3.3B: Verifica su Tailscale Dashboard (Solo Cloud)

**⚠️ Usa questo solo con Tailscale Cloud**

```bash
# Controlla dashboard web:
# https://login.tailscale.com/admin/machines

# Verifica che il nodo Linux sia presente:
# - Nome: LINUX-VM (o hostname)
# - IP: 100.x.y.z
# - Status: Connected
```

#### Step 3.4: Verifica Connessione Linux

```bash
# Status
tailscale status

# Ping Windows client (usa IP dalla dashboard o da 'tailscale status')
ping 100.64.0.2

# Con Headscale: ping anche il server
ping 100.64.0.1

# Traceroute (connessione diretta peer-to-peer)
traceroute 100.64.0.2
```

**Nota differenze**:
- **Headscale**: Il server ha un IP mesh (100.64.0.1) pingabile
- **Tailscale Cloud**: Non c'è server da pingare, solo peer devices
```

### Opzione B: Client in Container Docker

#### Step 3.5: Container Tailscale

```yaml
# docker-compose-client.yml
version: '3.8'

services:
  tailscale-client:
    image: tailscale/tailscale:latest
    container_name: tailscale-client
    restart: unless-stopped
    network_mode: host
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    volumes:
      - /dev/net/tun:/dev/net/tun
      - ./ts-data:/var/lib/tailscale
      - ./ts-state:/state
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/state
      - TS_EXTRA_ARGS=--login-server=http://192.168.1.50:8080
    command: sh -c "tailscaled --state=/state/tailscaled.state & sleep 5 && tailscale up --login-server=http://192.168.1.50:8080 && tail -f /dev/null"
```

**Nota**: Per container è necessario usare auth key pre-approvate (vedi sezione avanzata).

---

## Parte 4: Testing e Verifica

### Test 1: Connettività Mesh

**Da Windows Client**:
```powershell
# Ping tutti i nodi
ping 100.64.0.1   # Server
ping 100.64.0.3   # Linux client

# Traceroute
tracert 100.64.0.3  # Dovrebbe essere direct P2P
```

**Da Linux Client**:
```bash
# Ping
ping 100.64.0.2   # Windows
ping 100.64.0.1   # Server

# Test bandwidth tra client
iperf3 -s   # Su Linux

# Su Windows (installa iperf3)
iperf3 -c 100.64.0.3
```

### Test 2: Verifica Routing Diretto (Peer-to-Peer)

**Per Headscale**:

```bash
# Sul server Headscale, verifica connessioni
sudo headscale nodes list

# Dettagli nodo
sudo headscale nodes show 2

# Output mostra:
# - Direct endpoints (connessione P2P)
# - Relay in uso (se non P2P)
```

**Per Tailscale Cloud**:

```powershell
# Su qualsiasi client, verifica connettività P2P
tailscale status

# Dettagli connessione
tailscale netcheck

# Output mostra:
# - DERP latency per ogni region
# - UDP: true (se P2P diretto possibile)
# - Relay: derp-XX se usando relay
```

### Test 3: DNS Magic

**Per Headscale** (se configurato `magic_dns: true`):

```bash
# Usa hostname con dominio configurato
ping WIN-CLIENT.vpn.local
ping LINUX-VM.vpn.local
```

**Per Tailscale Cloud** (MagicDNS abilitato di default):

```bash
# Usa solo hostname (senza dominio)
ping WIN-CLIENT
ping LINUX-VM

# Oppure con dominio tailnet
ping WIN-CLIENT.tailXXXXX.ts.net
```

### Test 4: Accesso Risorse

**Scenario**: Esponi servizio web su Linux client, accedi da Windows

```bash
# Su Linux client, avvia web server
python3 -m http.server 8000
```

```powershell
# Su Windows, accedi via mesh IP
curl http://100.64.0.3:8000
# oppure apri browser: http://100.64.0.3:8000
```

---

## Parte 5: Configurazioni Avanzate

### 5.1 Pre-Authentication Keys

**Per Headscale**: Utili per registrazione automatica (es. container, CI/CD):

```bash
# Genera pre-auth key
sudo headscale preauthkeys create --namespace default --expiration 24h --reusable

# Output: preauthkey:xxxxxxxxxxxxx

# Usa con client
sudo tailscale up --login-server=http://192.168.1.50:8080 --authkey=preauthkey:xxxxxxxxxxxxx
```

**Per Tailscale Cloud**: Auth keys dalla dashboard

```bash
# Vai a: https://login.tailscale.com/admin/settings/keys
# Click "Generate auth key"
# Opzioni:
# - Reusable: Sì/No
# - Ephemeral: Dispositivo eliminato alla disconnessione
# - Pre-approved: Skip admin approval
# - Expires: 1h, 1d, 7d, 30d, 90d, Never

# Usa con client
sudo tailscale up --authkey=tskey-auth-xxxxxx

# Perfetto per automation/scripting
```

### 5.2 ACL Granulari

**Per Headscale**: File YAML locale

```yaml
# /etc/headscale/acl.yaml
groups:
  group:admins:
    - WIN-CLIENT
  group:servers:
    - LINUX-VM

acls:
  # Admins possono accedere a tutto
  - action: accept
    src:
      - group:admins
    dst:
      - "*:*"
  
  # Servers solo SSH e HTTP
  - action: accept
    src:
      - "*"
    dst:
      - group:servers:22,80,443

  # Blocca tutto il resto
  - action: deny
    src:
      - "*"
    dst:
      - "*:*"
```

Applica ACL:
```bash
sudo headscale policy update /etc/headscale/acl.yaml
```

**Per Tailscale Cloud**: ACL dalla dashboard con editor visuale

```bash
# Vai a: https://login.tailscale.com/admin/acls
# Editor JSON con syntax highlighting e validazione

# Esempio ACL Tailscale (formato HuJSON):
{
  "groups": {
    "group:admins": ["user@example.com"],
    "group:developers": ["dev@example.com"]
  },
  
  "acls": [
    // Admins → tutto
    {
      "action": "accept",
      "src": ["group:admins"],
      "dst": ["*:*"]
    },
    
    // Developers → solo porte dev
    {
      "action": "accept",
      "src": ["group:developers"],
      "dst": ["*:22,80,443,3000-4000"]
    }
  ]
}

# Click "Save" per applicare
# Validazione automatica prima di salvare
```

### 5.3 Subnet Routing (Exit Node)

Esponi subnet interna via un nodo.

**Per Headscale**:

```bash
# Su nodo Linux che deve fare routing
sudo tailscale up --login-server=http://192.168.1.50:8080 --advertise-routes=192.168.1.0/24

# Sul server Headscale, approva
sudo headscale routes list
sudo headscale routes enable -r 1

# Abilita IP forwarding sul nodo router
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Ora tutti i client mesh possono accedere 192.168.1.0/24
```

**Per Tailscale Cloud**:

```bash
# Su nodo Linux router
sudo tailscale up --advertise-routes=192.168.1.0/24

# Abilita IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Approva dalla dashboard:
# https://login.tailscale.com/admin/machines
# Click sul dispositivo → Edit route settings
# Toggle ON "192.168.1.0/24"

# Altri client ricevono automaticamente la route
```

### 5.4 Exit Node (VPN Internet)

Usa un nodo come gateway Internet.

**Per Headscale**:

```bash
# Nodo Linux come exit node
sudo tailscale up --login-server=http://192.168.1.50:8080 --advertise-exit-node

# Abilita NAT sul nodo
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1

# Su server Headscale, approva
sudo headscale routes enable -r 2

# Client Windows, usa exit node
tailscale.exe set --exit-node=100.64.0.3

# Verifica IP pubblico
curl ifconfig.me  # Dovrebbe mostrare IP del exit node
```

**Per Tailscale Cloud**:

```bash
# Su nodo Linux exit node
sudo tailscale up --advertise-exit-node

# Abilita forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Approva dalla dashboard:
# https://login.tailscale.com/admin/machines
# Click dispositivo → Edit route settings → "Use as exit node" ON

# Su client Windows
tailscale.exe set --exit-node=linux-vm

# Oppure dalla GUI: Click icona Tailscale → Exit node → Seleziona nodo

# Test
curl ifconfig.me  # IP pubblico del exit node
```

### 5.5 HTTPS con Reverse Proxy (Solo Headscale)

**⚠️ Applicabile solo a Headscale self-hosted** (Tailscale Cloud usa già HTTPS)

Produzione: Headscale dietro reverse proxy con TLS:

```nginx
# /etc/nginx/sites-available/headscale
server {
    listen 443 ssl http2;
    server_name headscale.example.com;

    ssl_certificate /etc/letsencrypt/live/headscale.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/headscale.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Aggiorna `config.yaml`:
```yaml
server_url: https://headscale.example.com
```

---

## Troubleshooting

### Problema 1: Nodo non si registra

**Sintomi**: URL registrazione non funziona

```bash
# Verifica Headscale listening
sudo netstat -tlnp | grep 8080

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp

# Logs
sudo journalctl -u headscale -n 50
```

### Problema 2: No connettività P2P (solo relay)

**Sintomi**: `tailscale status` mostra "relay" invece di IP diretto

```bash
# Verifica NAT traversal
# Apri porta UDP 41641 su firewall

# DERP relay info
tailscale netcheck

# Forza direct connection
tailscale ping 100.64.0.2 --until-direct
```

### Problema 3: DNS non funziona

```bash
# Verifica Magic DNS config
sudo headscale namespaces list

# Su client
tailscale status --json | grep DNS

# Reset DNS su Windows
tailscale.exe set --accept-dns=true
```

### Problema 4: Windows Firewall blocca traffico

```powershell
# Aggiungi eccezione Tailscale
New-NetFirewallRule -DisplayName "Tailscale" -Direction Inbound -Program "C:\Program Files\Tailscale\tailscale.exe" -Action Allow
```

### Problema 5: Container non riesce ad avviare tunnel

```bash
# Verifica modulo TUN
lsmod | grep tun

# Se mancante, carica
sudo modprobe tun

# Persistent
echo "tun" | sudo tee /etc/modules-load.d/tun.conf
```

---

## Monitoring e Gestione

### Dashboard Nodi

**Per Headscale**:

```bash
# Lista nodi con dettagli
sudo headscale nodes list -o json | jq

# Traffico nodo
sudo headscale nodes show 1

# Rimuovi nodo
sudo headscale nodes delete 2
```

**Per Tailscale Cloud**:

```bash
# Dashboard web completa
# https://login.tailscale.com/admin/machines

# Features dashboard:
# - Lista tutti dispositivi con status real-time
# - Grafico connessioni P2P vs DERP relay
# - Bandwidth usage per device
# - Logs accessi e eventi
# - Metrics latenza tra nodi
# - Audit log completo

# CLI per info
tailscale status --json | jq

# Network quality
tailscale netcheck
```

### Prometheus Metrics

**Solo Headscale** (Tailscale Cloud non espone metriche raw):

Headscale espone metriche Prometheus su porta 9090:

```bash
curl http://localhost:9090/metrics
```

Integra con Grafana per dashboard visuali.

### Logs Centralizzati

**Per Headscale**:

```bash
# Headscale logs
sudo journalctl -u headscale -f

# Client logs (Linux)
sudo journalctl -u tailscaled -f

# Windows client logs
# Event Viewer → Applications and Services Logs → Tailscale
```

**Per Tailscale Cloud**:

```bash
# Dashboard web > Logs
# https://login.tailscale.com/admin/logs

# Activity log mostra:
# - Device connections/disconnections
# - Auth key usage
# - ACL changes
# - Route approvals
# - Admin actions

# Client logs locali (Linux)
sudo journalctl -u tailscaled -f

# Windows: Event Viewer come sopra
```

---

## Esercizi Aggiuntivi

### Esercizio 1: Namespace Multipli (Solo Headscale)
Crea namespace separati per dipartimenti (IT, HR) con ACL che prevengono comunicazione cross-namespace.

**Nota**: Con Tailscale Cloud, i "namespaces" sono gestiti come "tailnets" separati (account diversi).

### Esercizio 2: Mobile Client
Installa Tailscale su smartphone Android/iOS e connetti alla rete mesh.

**Per Headscale**: Usa app Tailscale generica con custom login server (richiede configurazione manuale URL).

**Per Tailscale Cloud**: App native dedicate, login con un tap, notifiche push, key management integrato.

### Esercizio 3: High Availability (Solo Headscale)
Deploy 2 server Headscale in HA con database PostgreSQL condiviso invece di SQLite.

### Esercizio 4: Kubernetes Integration
**Headscale**: Deploy in cluster K8s con StatefulSet.
**Tailscale**: Usa Tailscale Kubernetes Operator per subnet routing automatico.

### Esercizio 5: Automation
**Headscale**: Script Ansible per deploy server + client con pre-auth keys.
**Tailscale**: Terraform provider ufficiale per gestione dispositivi e ACL:
```hcl
resource "tailscale_tailnet_key" "example" {
  reusable      = true
  ephemeral     = false
  preauthorized = true
}
```

### Esercizio 6: Confronto Performance
Testa latenza e throughput Headscale vs Tailscale Cloud usando stessi client in entrambe le configurazioni. Documenta differenze DERP relay.

---

## Domande di Verifica

1. Qual è la differenza principale tra Headscale (self-hosted) e Tailscale Cloud?
2. Quale protocollo VPN usa sia Headscale che Tailscale sotto il cofano?
3. Cosa significa "connessione peer-to-peer" nel contesto di VPN mesh?
4. Quando viene usato il DERP relay invece di connessioni P2P dirette?
5. Come si implementa un exit node con entrambe le soluzioni?
6. Perché è importante avere ACL granulari in una rete mesh?
7. Come si espone una subnet interna tramite subnet routing?
8. Quali sono i vantaggi di usare Tailscale Cloud vs self-hosting Headscale?
9. In quali scenari è preferibile Headscale rispetto a Tailscale?
10. Come differiscono le procedure di registrazione nodi tra le due soluzioni?

---

## Confronto Finale: Headscale vs Tailscale

### Scegli Headscale se:
- ✅ Hai requisiti di compliance strict (GDPR, HIPAA)
- ✅ Vuoi controllo completo su dati e metadati
- ✅ Necessiti di on-premise totale
- ✅ Hai esperienza Linux/Docker
- ✅ Vuoi personalizzare DERP relay
- ✅ Più di 100 dispositivi senza costi

### Scegli Tailscale Cloud se:
- ✅ Vuoi setup in 5 minuti
- ✅ Team < 100 dispositivi
- ✅ Serve supporto ufficiale
- ✅ Vuoi app mobile native ottimizzate
- ✅ Zero manutenzione infrastruttura
- ✅ Features avanzate (Tailscale SSH, Funnel, etc.)

### 🏆 Soluzione Ibrida
Usa entrambi: **Headscale per produzione**, **Tailscale Cloud per testing/staging**.

---

## Riferimenti

### Headscale
- **GitHub**: https://github.com/juanfont/headscale
- **Documentation**: https://headscale.net/
- **Community**: Discord server (link in README)

### Tailscale
- **Website**: https://tailscale.com/
- **Documentation**: https://tailscale.com/kb/
- **Blog**: https://tailscale.com/blog/ (eccellenti spiegazioni tecniche)
- **Dashboard**: https://login.tailscale.com/admin/

### Protocolli e Tecnologie
- **WireGuard**: https://www.wireguard.com/
- **DERP Protocol**: https://tailscale.com/blog/how-tailscale-works/
- **NAT Traversal**: https://tailscale.com/blog/how-nat-traversal-works/

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 6: WireGuard con Docker](Lab6_WireGuard_Docker_Windows.md)
