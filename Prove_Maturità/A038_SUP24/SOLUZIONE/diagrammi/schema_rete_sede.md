# Schema di rete (sede operativa + campo + totem)

> Usare questo schema per la **Prima Parte – Punto 1 (schema generale del sistema)**.

## Diagramma logico (alto livello)

```mermaid
flowchart TB
  Internet((Internet))
  Cloud[(Cloud Storage/Archive)]

  subgraph Sede[SEDE OPERATIVA]
    FW1[Firewall/Router HA]
    LB[Reverse Proxy / Load Balancer]
    Core[Core Switch (stack)]

    subgraph VLAN10[VLAN 10 - Ticketing (1° piano)]
      Ops[Postazioni operatori]
      Ticket[App Ticketing]
    end

    subgraph VLAN20[VLAN 20 - Sala controllo (2° piano)]
      VMS[VMS / Console controllo]
      NVR[NVR / Storage locale]
    end

    subgraph VLAN30[VLAN 30 - IoT/Remoti]
      IoT[IoT Control Server]
      MQTT[MQTT Broker (TLS)]
    end

    subgraph VLAN40[VLAN 40 - Mgmt]
      Zbx[Monitoring (Zabbix)]
      Bastion[Bastion/Jump host]
      AD[Directory/IdP]
    end

    FW1 --- Core
    Core --- LB
    Core --- VLAN10
    Core --- VLAN20
    Core --- VLAN30
    Core --- VLAN40
  end

  subgraph Campo[AREA EVENTO / CITTA']
    subgraph RemoteCams[Telecamere]
      Cam1[Cam IP PoE]
      Cam2[Cam IP 4G/5G]
      Edge[Gateway Edge (buffer 24h)]
      Cam2 --> Edge
    end

    subgraph Remotes[Dispositivi azionabili]
      Sem[Semaforo smart (HTTP+MQTT)]
      Bar[Barriera (HTTP)]
      Pan[Pannello LED (HTTP)]
    end

    subgraph Staff[Personale in loco]
      App[App mobile (validazione + PTT)]
    end

    subgraph Totem[Totem informativi]
      T1[Totem (fibra)]
      T2[Totem (4G/5G)]
    end
  end

  Internet --- FW1
  FW1 --- Cloud

  %% Canali protetti
  Edge -. VPN WireGuard/IPsec .-> FW1
  Sem -. VPN + mTLS .-> FW1
  Bar -. VPN + mTLS .-> FW1
  Pan -. VPN + mTLS .-> FW1
  App -. HTTPS/VPN .-> FW1
  T1 -. HTTPS/mTLS .-> FW1
  T2 -. HTTPS/mTLS .-> FW1

  %% Flussi applicativi
  LB --> Ticket
  VMS --> NVR
  IoT --> MQTT
```

## Note di lettura

- **Segmentazione**: VLAN separate per ticketing, videosorveglianza, IoT, management.
- **Accesso remoto**: tutto ciò che è in città/campo passa in **VPN** verso sede (o APN privato) e usa **TLS/mTLS**.
- **Gestione**: i server di controllo (ticketing, VMS, IoT) sono dietro reverse proxy e policy di firewall.
