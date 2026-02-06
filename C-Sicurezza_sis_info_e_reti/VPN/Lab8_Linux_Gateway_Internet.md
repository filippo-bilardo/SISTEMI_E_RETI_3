# Lab 8: Server Linux come Gateway Internet per Client Windows

## Obiettivi

- Configurare un server Linux come gateway Internet per client Windows
- Implementare exit node con WireGuard nativo
- Implementare exit node con Tailscale/Headscale
- Confrontare le due soluzioni
- Verificare routing traffico Internet e sicurezza
- Testare prestazioni e latenza

## Introduzione

Questo lab mostra come usare un server Linux (VM o container) come **gateway Internet** per instradare tutto il traffico di un client Windows attraverso il tunnel VPN. Questo è utile per:

- 🔒 **Privacy**: Nascondere IP reale del client
- 🌍 **Geo-unlocking**: Accedere a contenuti con restrizioni geografiche
- 🏢 **Remote work**: Accedere a Internet come se fossi in ufficio
- 🛡️ **Sicurezza**: Proteggere traffico su reti WiFi pubbliche
- 📊 **Monitoring**: Centralizzare traffico per analisi

## Confronto Soluzioni

| Caratteristica | WireGuard Nativo | Tailscale/Headscale |
|----------------|------------------|---------------------|
| Setup | Manuale completo | Semi-automatico |
| NAT/Firewall | Configurazione manuale | Gestito automaticamente |
| Split tunneling | Manuale (AllowedIPs) | Integrato (--exit-node) |
| Cambio gateway | Riconnessione necessaria | Switch dinamico |
| Multi-gateway | Più configurazioni | Lista exit nodes |
| Mobile | Configurazione complessa | App nativa semplice |
| Performance | Leggermente migliore | Ottima (overhead minimo) |
| Complessità | Alta | Bassa |

## Topologia

```
                     Internet
                        ↑
                        | (IP pubblico server)
                        |
                  Linux Server
                  (Gateway VPN)
                  eth0: 203.0.113.50
                  wg0/tailscale0: 10.10.0.1
                        |
                   VPN Tunnel
                   (encrypted)
                        |
                  Windows Client
                  eth0: 192.168.1.100 (LAN locale)
                  wg0/tailscale0: 10.10.0.2
                        ↓
                  Tutto il traffico → Linux Server → Internet
```

## Prerequisiti

- **Server Linux**: VM Ubuntu 22.04+ con IP pubblico o NAT configurato
- **Client Windows**: Windows 10/11
- Accesso root su Linux
- Connettività Internet stabile su entrambi

---

## Parte 1: Soluzione con WireGuard Nativo

### Step 1.1: Installazione Server Linux

```bash
# Update sistema
sudo apt update && sudo apt upgrade -y

# Installa WireGuard
sudo apt install -y wireguard iptables

# Verifica installazione
wg --version
```

### Step 1.2: Generazione Chiavi

```bash
# Directory config
cd /etc/wireguard
sudo umask 077

# Genera chiavi server
sudo wg genkey | sudo tee server-private.key | sudo wg pubkey | sudo tee server-public.key

# Genera chiavi client Windows
sudo wg genkey | sudo tee client-windows-private.key | sudo wg pubkey | sudo tee client-windows-public.key

# Mostra chiavi
echo "Server Public Key: $(sudo cat server-public.key)"
echo "Client Public Key: $(sudo cat client-windows-public.key)"
```

### Step 1.3: Configurazione Server (Gateway)

```bash
# Crea configurazione server
sudo tee /etc/wireguard/wg0.conf > /dev/null <<EOF
[Interface]
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = $(sudo cat /etc/wireguard/server-private.key)

# Abilita IP forwarding al boot dell'interfaccia
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -A FORWARD -o %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Ripristina al down
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -D FORWARD -o %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Client Windows
[Peer]
PublicKey = $(sudo cat /etc/wireguard/client-windows-public.key)
AllowedIPs = 10.10.0.2/32
EOF

# Verifica configurazione
sudo cat /etc/wireguard/wg0.conf
```

**Nota importante**: Sostituisci `eth0` con l'interfaccia di rete reale del server:

```bash
# Trova interfaccia principale
ip route | grep default
# Output esempio: default via 192.168.1.1 dev ens33

# Se interfaccia è ens33 invece di eth0, modifica nel config:
# PostRouting ... -o ens33 -j MASQUERADE
```

### Step 1.4: Configurazione Firewall e Routing

```bash
# Abilita IP forwarding permanente
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Firewall: permetti WireGuard
sudo ufw allow 51820/udp

# Se usi iptables diretto
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Step 1.5: Avvio Server WireGuard

```bash
# Avvia WireGuard
sudo wg-quick up wg0

# Verifica status
sudo wg show

# Output atteso:
# interface: wg0
#   public key: <server-public-key>
#   private key: (hidden)
#   listening port: 51820
#
# peer: <client-public-key>
#   allowed ips: 10.10.0.2/32

# Abilita avvio automatico
sudo systemctl enable wg-quick@wg0
```

### Step 1.6: Configurazione Client Windows

#### Opzione A: File Config Manuale

```bash
# Sul server, crea config per Windows
sudo tee /tmp/windows-client.conf > /dev/null <<EOF
[Interface]
Address = 10.10.0.2/24
PrivateKey = $(sudo cat /etc/wireguard/client-windows-private.key)
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = $(sudo cat /etc/wireguard/server-public.key)
Endpoint = 203.0.113.50:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Mostra config (da copiare su Windows)
sudo cat /tmp/windows-client.conf
```

**⚠️ IMPORTANTE**: `AllowedIPs = 0.0.0.0/0` instrada **tutto** il traffico attraverso VPN!

#### Opzione B: QR Code (più veloce)

```bash
# Installa qrencode
sudo apt install -y qrencode

# Genera QR code
sudo qrencode -t ansiutf8 < /tmp/windows-client.conf
```

### Step 1.7: Import Config su Windows

**Su Windows**:

1. **Installa WireGuard GUI**:
   ```powershell
   # Download da: https://www.wireguard.com/install/
   # oppure via winget
   winget install WireGuard.WireGuard
   ```

2. **Import configurazione**:
   - Apri WireGuard GUI
   - Click "Add Tunnel" → "Add from file"
   - Seleziona `windows-client.conf` copiato dal server
   - Oppure: "Add Tunnel" → "Add from QR code" (scansiona con smartphone e trasferisci)

3. **Attiva tunnel**:
   - Click su "Activate"
   - Status dovrebbe mostrare "Active"

### Step 1.8: Verifica Gateway Funzionante

**Su Windows**:

```powershell
# Verifica IP pubblico (dovrebbe essere IP del server Linux)
curl ifconfig.me

# Test connettività
ping 10.10.0.1  # Ping server VPN

# Test DNS
nslookup google.com

# Traceroute
tracert google.com
# Primo hop dovrebbe essere 10.10.0.1 (server VPN)

# Verifica latenza
ping -n 10 10.10.0.1
```

**Sul server Linux**:

```bash
# Verifica peer connesso
sudo wg show

# Output dovrebbe mostrare:
# peer: <client-public-key>
#   endpoint: <client-ip>:random-port
#   allowed ips: 10.10.0.2/32
#   latest handshake: 30 seconds ago  ← Importante!
#   transfer: 123 KiB received, 456 KiB sent

# Verifica traffico NAT
sudo iptables -t nat -L POSTROUTING -v -n
```

### Step 1.9: Test Completo

```powershell
# Su Windows PowerShell

# 1. Verifica IP pubblico
Invoke-WebRequest -Uri "https://api.ipify.org" | Select-Object -ExpandProperty Content
# Dovrebbe mostrare IP del server Linux

# 2. Test geolocalizzazione
Invoke-WebRequest -Uri "https://ipinfo.io/json" | ConvertFrom-Json
# Location dovrebbe essere quella del server

# 3. Test DNS leak
# Visita: https://www.dnsleaktest.com/
# DNS servers dovrebbero essere quelli configurati (1.1.1.1, 8.8.8.8)

# 4. Bandwidth test
# Installa iperf3 su server
# sudo apt install -y iperf3
# sudo iperf3 -s

# Su Windows (installa iperf3):
# iperf3.exe -c 10.10.0.1

# 5. Test siti web
curl https://www.google.com -I
curl https://www.whatismyip.com
```

---

## Parte 2: Soluzione con Tailscale/Headscale

### Step 2.1: Setup Server come Exit Node

**Se usi Headscale** (riferimento al Lab 7):

```bash
# Sul server Linux con Tailscale client installato
sudo tailscale up --login-server=http://headscale-server:8080 --advertise-exit-node

# Registra su Headscale
# (Copia URL e registra come nel Lab 7)

# Sul server Headscale, approva exit node
sudo headscale routes list
sudo headscale routes enable -r <route-id>
```

**Se usi Tailscale Cloud**:

```bash
# Sul server Linux
sudo tailscale up --advertise-exit-node

# Approva dalla dashboard:
# https://login.tailscale.com/admin/machines
# Click sul server → Edit route settings
# Toggle ON "Use as exit node"
```

### Step 2.2: Configurazione NAT sul Server

```bash
# Abilita IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

# Configurazione NAT
INTERFACE=$(ip route | grep default | awk '{print $5}')
sudo iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

# Salva regole
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Step 2.3: Configurazione Client Windows

**Su Windows** (con Tailscale già installato dal Lab 7):

#### Via PowerShell:

```powershell
# Usa server Linux come exit node
tailscale.exe set --exit-node=<server-hostname>

# Oppure usa IP mesh
tailscale.exe status
# Trova IP del server (es. 100.64.0.5)

tailscale.exe set --exit-node=100.64.0.5

# Verifica
tailscale.exe status
# Dovrebbe mostrare: "Exit node: <server-name>"
```

#### Via GUI:

1. Click icona Tailscale nella system tray
2. Click "Exit node"
3. Seleziona il server Linux dalla lista
4. Status cambierà in "Using exit node: server-name"

### Step 2.4: Verifica Exit Node

```powershell
# Verifica IP pubblico
curl ifconfig.me
# Dovrebbe essere IP del server Linux

# Verifica routing Tailscale
tailscale.exe status

# Netcheck (info connessione)
tailscale.exe netcheck

# Ping server
ping 100.64.0.5
```

### Step 2.5: Disattivare Exit Node

```powershell
# Disattiva exit node (torna a routing normale)
tailscale.exe set --exit-node=""

# Oppure dalla GUI: Exit node → None
```

---

## Parte 3: Configurazioni Avanzate

### 3.1 Split Tunneling con WireGuard

**Scenario**: Instradare solo traffico specifico attraverso VPN, non tutto.

```ini
# Client Windows config modificato
[Interface]
Address = 10.10.0.2/24
PrivateKey = <client-private-key>
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = 203.0.113.50:51820
# Solo traffico per subnet specifiche
AllowedIPs = 192.168.10.0/24, 10.0.0.0/8
# NON 0.0.0.0/0 (tutto il traffico)
PersistentKeepalive = 25
```

### 3.2 Split Tunneling con Tailscale

```powershell
# Accetta routes specifiche
tailscale.exe set --accept-routes=true

# Usa exit node ma escludi subnet locali
tailscale.exe set --exit-node=server --exit-node-allow-lan-access=true
```

### 3.3 DNS Custom

**WireGuard** (già nel config):
```ini
[Interface]
DNS = 1.1.1.1, 8.8.8.8
# oppure DNS interno
DNS = 192.168.10.1
```

**Tailscale**:
```powershell
# Accetta DNS da Tailscale
tailscale.exe set --accept-dns=true

# Oppure configura DNS custom nella dashboard
# Settings → DNS → Add nameserver
```

### 3.4 Kill Switch (Blocca traffico se VPN cade)

#### WireGuard Kill Switch

**Su Windows**, usa firewall:

```powershell
# PowerShell come Amministratore

# Blocca tutto il traffico eccetto VPN
New-NetFirewallRule -DisplayName "Block Non-VPN" -Direction Outbound -Action Block -InterfaceAlias "Ethernet", "Wi-Fi"

# Permetti solo WireGuard
New-NetFirewallRule -DisplayName "Allow WireGuard" -Direction Outbound -Action Allow -Program "C:\Program Files\WireGuard\wireguard.exe"

# Permetti traffico su interfaccia WireGuard
New-NetFirewallRule -DisplayName "Allow VPN Tunnel" -Direction Outbound -Action Allow -InterfaceAlias "wg0"
```

**⚠️ Attenzione**: Disabilita regole quando non usi VPN o rimarrai offline!

```powershell
# Disabilita kill switch
Disable-NetFirewallRule -DisplayName "Block Non-VPN"
```

#### Tailscale Kill Switch

Tailscale non ha kill switch nativo, ma puoi usare routing:

```powershell
# Route tutto il traffico tramite Tailscale con priorità alta
route add 0.0.0.0 mask 0.0.0.0 100.64.0.5 metric 1

# Rimuovi dopo
route delete 0.0.0.0
```

### 3.5 Multiple Exit Nodes (Tailscale)

```powershell
# Lista exit nodes disponibili
tailscale.exe status | findstr "exit"

# Cambia exit node dinamicamente
tailscale.exe set --exit-node=server-us
# Attendi qualche secondo
tailscale.exe set --exit-node=server-eu

# Veloce per testare diversi server/location
```

### 3.6 Failover Automatico

#### Script PowerShell per Failover WireGuard

```powershell
# failover-vpn.ps1
$PrimaryServer = "10.10.0.1"
$BackupConfig = "C:\VPN\backup-tunnel.conf"

while ($true) {
    $ping = Test-Connection -ComputerName $PrimaryServer -Count 2 -Quiet
    
    if (-not $ping) {
        Write-Host "Primary VPN down, switching to backup..."
        
        # Disattiva tunnel corrente
        wireguard.exe /uninstalltunnelservice wg0
        
        # Attiva backup
        wireguard.exe /installtunnelservice $BackupConfig
        
        # Alert
        Write-EventLog -LogName Application -Source "VPN Failover" -EventId 1001 -Message "Switched to backup VPN"
    }
    
    Start-Sleep -Seconds 30
}
```

---

## Parte 4: Performance e Monitoring

### 4.1 Test Bandwidth

**Con WireGuard**:

```bash
# Sul server, avvia iperf3
sudo apt install -y iperf3
iperf3 -s

# Su Windows
iperf3.exe -c 10.10.0.1

# Test con traffico reale via Internet
iperf3.exe -c 10.10.0.1 --reverse
```

**Con Tailscale**:

```powershell
# Usa IP mesh del server
iperf3.exe -c 100.64.0.5

# Tailscale ha overhead minimo (~5-10% vs WireGuard puro)
```

### 4.2 Latenza Comparison

```powershell
# Senza VPN
ping google.com

# Con WireGuard
ping -n 50 10.10.0.1
# Latenza VPN = latenza ping

# Con Tailscale
ping -n 50 100.64.0.5
```

### 4.3 Monitoring Traffico

**WireGuard**:

```bash
# Sul server
watch -n 1 'sudo wg show'

# Mostra transfer real-time
sudo wg show all transfer
```

**Tailscale**:

```bash
# Sul server
tailscale status

# Dashboard web (solo Tailscale Cloud)
# https://login.tailscale.com/admin/machines
# Mostra bandwidth usage, device status
```

### 4.4 Logs

**WireGuard**:

```bash
# Linux server
sudo journalctl -u wg-quick@wg0 -f

# Windows client
# Event Viewer → Applications and Services Logs → WireGuard
```

**Tailscale**:

```bash
# Linux
sudo journalctl -u tailscaled -f

# Windows PowerShell
Get-EventLog -LogName Application -Source Tailscale -Newest 50
```

---

## Parte 5: Troubleshooting

### Problema 1: Cliente non naviga (DNS non funziona)

**WireGuard**:

```powershell
# Su Windows, verifica DNS
ipconfig /all
# Cerca "DNS Servers" dell'interfaccia WireGuard

# Test DNS
nslookup google.com 1.1.1.1

# Flush DNS cache
ipconfig /flushdns
```

**Tailscale**:

```powershell
# Verifica DNS Tailscale
tailscale.exe status

# Reset DNS
tailscale.exe set --accept-dns=false
tailscale.exe set --accept-dns=true
```

### Problema 2: Traffico non passa attraverso VPN

**Verifica routing**:

```powershell
# Windows
route print

# Cerca riga 0.0.0.0 (default route)
# Dovrebbe puntare a interfaccia VPN

# Se non presente
route add 0.0.0.0 mask 0.0.0.0 10.10.0.1 metric 1
```

**Verifica NAT sul server**:

```bash
# Linux server
sudo iptables -t nat -L POSTROUTING -v -n

# Dovrebbe mostrare regola MASQUERADE su interfaccia pubblica

# Se mancante
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### Problema 3: Performance scarsa

**WireGuard**:

```bash
# Verifica MTU
# Client Windows
netsh interface ipv4 show subinterfaces

# Riduce MTU se necessario (edit config)
[Interface]
MTU = 1420  # Invece di default 1500
```

**Tailscale**:

```powershell
# Verifica connessione P2P vs relay
tailscale.exe netcheck

# Se usa relay DERP invece di P2P diretto:
# - Apri porte UDP sul firewall
# - Verifica NAT type
```

### Problema 4: Connessione cade spesso

**WireGuard**:

```ini
# Aumenta keepalive nel config client
[Peer]
PersistentKeepalive = 15  # Invece di 25
```

**Tailscale**:

```powershell
# Logout e re-login
tailscale.exe down
tailscale.exe up
```

### Problema 5: IP leak (traffico bypassa VPN)

**Test leak**:

```powershell
# 1. IP leak test
curl ifconfig.me
# Dovrebbe mostrare IP server, non IP reale

# 2. DNS leak test
# Visita: https://www.dnsleaktest.com/
# DNS dovrebbero essere quelli configurati VPN

# 3. WebRTC leak test
# Visita: https://browserleaks.com/webrtc
# Disabilita WebRTC in browser se mostra IP reale
```

**Fix leak**:

- WireGuard: Verifica `AllowedIPs = 0.0.0.0/0` nel config
- Tailscale: Verifica exit node attivo con `tailscale status`
- Browser: Disabilita WebRTC (addon uBlock Origin o Privacy Badger)

---

## Parte 6: Scenari d'Uso

### Scenario 1: Remote Worker

**Obiettivo**: Lavorare da casa come se fossi in ufficio

```powershell
# Setup WireGuard con subnet ufficio
AllowedIPs = 0.0.0.0/0, 192.168.10.0/24

# Accedi a risorse interne ufficio
ping fileserver.office.local
\\192.168.10.50\shared
```

### Scenario 2: Viaggiatore Internazionale

**Obiettivo**: Accedere a servizi del paese di origine

```powershell
# Tailscale: Cambia exit node per paese
tailscale.exe set --exit-node=server-italy

# Verifica geolocation
Invoke-WebRequest "https://ipinfo.io/country"
# Output: IT
```

### Scenario 3: WiFi Pubblico Sicuro

**Obiettivo**: Proteggere traffico su WiFi hotel/aeroporto

```powershell
# Attiva VPN prima di connettersi a WiFi pubblico
# WireGuard: Activate tunnel
# Tailscale: Set exit node

# Tutto il traffico è criptato end-to-end
```

### Scenario 4: Bypass Censura

**Obiettivo**: Accedere a siti bloccati

```bash
# Server Linux in paese senza censura
# Client connette via VPN
# Accesso libero a Internet

# Importante: Verifica legalità nel tuo paese!
```

---

## Parte 7: Confronto Finale

### WireGuard Nativo

**Vantaggi** ✅:
- Massime performance
- Controllo completo configurazione
- Nessuna dipendenza da servizi esterni
- Più leggero (meno overhead)

**Svantaggi** ❌:
- Setup complesso
- Configurazione NAT/firewall manuale
- Cambio server richiede riconnessione
- Mobile complesso

**Ideale per**:
- Utenti avanzati
- Server dedicati VPN
- Massime prestazioni richieste
- Configurazioni statiche

### Tailscale/Headscale Exit Nodes

**Vantaggi** ✅:
- Setup semplicissimo
- Cambio exit node dinamico
- NAT traversal automatico
- App mobile native
- Multi-platform seamless

**Svantaggi** ❌:
- Overhead leggero (~5-10%)
- Dipendenza da control plane
- Meno configurabile

**Ideale per**:
- Utenti principianti
- Team distribuiti
- Dispositivi multipli
- Mobilità richiesta

### Tabella Comparativa

| Criterio | WireGuard | Tailscale |
|----------|-----------|-----------|
| Setup Time | 30-45 min | 5 min |
| Difficoltà | ⭐⭐⭐⭐ | ⭐⭐ |
| Performance | 100% | 90-95% |
| Flessibilità | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| Mobile | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| Multi-server | Complesso | Facile |
| Failover | Manuale | Automatico |
| Split tunnel | Manuale | Integrato |

---

## Esercizi Aggiuntivi

### Esercizio 1: Multi-Hop VPN
Configura cascata di 2 server (Client → Server1 → Server2 → Internet) per doppia crittografia.

### Esercizio 2: Location-Based Routing
Script che cambia exit node Tailscale automaticamente in base a geolocation target.

### Esercizio 3: Bandwidth Shaping
Implementa QoS sul server per limitare bandwidth per client specifico.

### Esercizio 4: VPN On-Demand
PowerShell script che attiva VPN solo per applicazioni specifiche (browser, etc).

### Esercizio 5: Monitoring Dashboard
Grafana dashboard per visualizzare stats WireGuard + Tailscale in tempo reale.

---

## Domande di Verifica

1. Cosa significa "exit node" nel contesto VPN?
2. Qual è la differenza tra `AllowedIPs = 10.0.0.0/8` e `AllowedIPs = 0.0.0.0/0`?
3. Perché è necessario NAT/MASQUERADE sul server gateway?
4. Come verificare se il traffico passa realmente attraverso la VPN?
5. Cosa causa un "DNS leak" e come prevenirlo?
6. Quali sono ivantaggi di split tunneling vs full tunnel?
7. Come funziona il kill switch e quando è necessario?
8. Perché Tailscale ha overhead maggiore di WireGuard puro?
9. In quali scenari è preferibile WireGuard nativo vs Tailscale?
10. Come testare la performance della VPN come gateway?

---

## Riferimenti

### WireGuard
- **Official Site**: https://www.wireguard.com/
- **Windows Client**: https://www.wireguard.com/install/
- **Configuration Guide**: https://www.wireguard.com/quickstart/

### Tailscale
- **Exit Nodes Documentation**: https://tailscale.com/kb/1103/exit-nodes/
- **Subnet Routing**: https://tailscale.com/kb/1019/subnets/
- **Performance**: https://tailscale.com/blog/more-throughput/

### Testing Tools
- **IP Leak Test**: https://ipleak.net/
- **DNS Leak Test**: https://www.dnsleaktest.com/
- **Speed Test**: https://www.speedtest.net/

### Security
- **VPN Security Best Practices**: https://www.wireguard.com/papers/wireguard.pdf
- **Kill Switch Guide**: https://www.comparitech.com/blog/vpn-privacy/vpn-kill-switch/

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 7: Headscale Mesh Network](Lab7_Headscale_Mesh_Network.md)
