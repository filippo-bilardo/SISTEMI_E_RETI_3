# Lab 6: WireGuard con Container Docker e Client Windows

[Link al Lab 6 completo con tutti i dettagli >>](Lab6_WireGuard_Docker_Windows.md)

## Obiettivi
- Configurare un server WireGuard in un container Docker su una VM Linux
- Connettere un client Windows al server containerizzato
- Comprendere l'integrazione VPN con tecnologie container
- Verificare routing e accesso alle risorse

## Topology

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

## Prerequisiti

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

## Struttura Lab

Il laboratorio è suddiviso in 5 parti principali:

1. **Preparazione VM Linux** - Installazione Docker, verifica modulo kernel, configurazione firewall
2. **Configurazione Container WireGuard** - Docker Compose setup, avvio container, estrazione configurazioni client
3. **Configurazione Client Windows** - Installazione WireGuard GUI, import configurazione, connessione
4. **Test e Verifica** - Ping test, verifica IP, accesso risorse, DNS check, monitoring
5. **Configurazioni Avanzate** - Split tunneling, client multipli, backup, monitoring con Grafana

## Punti Salienti

- ✅ Deploy containerizzato con Docker Compose
- ✅ Generazione automatica chiavi e configurazioni
- ✅ QR code per import rapido su mobile
- ✅ Troubleshooting completo
- ✅ Esercizi avanzati inclusi

## Quick Start

```bash
# VM Linux
mkdir -p ~/wireguard-docker && cd ~/wireguard-docker
# [Crea docker-compose.yml]
docker-compose up -d
docker cp wireguard-server:/config/peer_client-windows/peer_client-windows.conf ./

# Windows
# Import configurazione in WireGuard GUI
# Activate tunnel
```

---

**Torna a**: [15. Laboratori ed Esercitazioni](15.Laboratori_ed_Esercitazioni.md)  
**Lab Precedente**: [Lab 5: VPN Failover](Lab5_VPN_Failover.md)

**Per la guida completa dettagliata, vai a**: [Lab 6 - Versione Completa](Lab6_WireGuard_Docker_Windows.md)
