# VPN (WireGuard) – configurazione di esempio

> Supporto a **Prima Parte – Punto 1** (connessione con telecamere/dispositivi) e **Punto 4** (continuità/sicurezza).

## Scopo

- Collegare **totem**, **telecamere**, **dispositivi azionabili** e **personale mobile** alla sede in modo cifrato.
- Fornire un piano IP coerente (subnet dedicate in `10.20.0.0/16`).

## Topologia

- **Hub**: sede operativa (firewall o server VPN dedicato) – `wg-hub`
- **Spoke**: ogni sito remoto o dispositivo (gateway edge, totem router, IoT device)

## Parametri

- Porta WireGuard: `51820/UDP`
- Cifratura: WireGuard (ChaCha20-Poly1305)
- Policy: split-tunnel (solo subnet corporate) oppure full-tunnel per device critici

## Esempio: Hub (sede)

File: `/etc/wireguard/wg0.conf`

```ini
[Interface]
Address = 10.20.255.1/24
ListenPort = 51820
PrivateKey = <HUB_PRIVATE_KEY>

# Abilita routing
PostUp = sysctl -w net.ipv4.ip_forward=1

# NAT verso LAN sede (se serve)
PostUp = iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 10.20.0.0/16 -o eth0 -j MASQUERADE

# Peer: gateway telecamere zona A
[Peer]
PublicKey = <EDGE_A_PUBLIC_KEY>
AllowedIPs = 10.20.20.10/32

# Peer: dispositivo IoT semaforo A-01
[Peer]
PublicKey = <SEM_A01_PUBLIC_KEY>
AllowedIPs = 10.20.10.11/32

# Peer: totem A-01
[Peer]
PublicKey = <TOTEM_A01_PUBLIC_KEY>
AllowedIPs = 10.20.30.11/32
```

## Esempio: Spoke (gateway edge telecamere)

```ini
[Interface]
Address = 10.20.20.10/32
PrivateKey = <EDGE_A_PRIVATE_KEY>

[Peer]
PublicKey = <HUB_PUBLIC_KEY>
Endpoint = vpn.sede.example:51820
AllowedIPs = 10.10.0.0/16
PersistentKeepalive = 25
```

## Hardening consigliato

- Chiavi per-peer, niente PSK condivisi.
- Filtrare su firewall: `UDP/51820` consentito solo da IP/APN attesi.
- Per dispositivi IoT/totem: usare un **gateway locale** (router 4G/5G) come peer, non ogni singolo device quando possibile.
- Logging accessi + alert su peer non raggiungibili.
