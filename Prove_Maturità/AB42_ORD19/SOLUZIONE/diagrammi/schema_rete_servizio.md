# Schema rete (alto livello) – servizio POI

> Riferimento: **Prima Parte – Punto 1.a/1.b/1.c** (architettura rete, server, comunicazione e vincolo prossimità).

```mermaid
flowchart TB
  Internet((Internet))

  subgraph DC[CED / Data Center comunale]
    FW[Firewall + WAF]
    LB[Reverse proxy / Load balancer]
    APP[Web/App servers]
    DB[(DB PostgreSQL)]
    OBJ[(Object storage media)]
    RADIUS[RADIUS/802.1X]
    MDM[MDM/Device management]
    DNS[DNS interno]
    LOG[Logging/Monitoring]

    FW --> LB --> APP
    APP --> DB
    APP --> OBJ
    FW --> RADIUS
    FW --> MDM
    FW --> LOG
  end

  subgraph City[Centro storico]
    subgraph InfoPoints[InfoPoint (chioschi)]
      K1[Chiosco 1]
      K2[Chiosco 2]
      K3[Chiosco N]
      SWI[Switch + Router]
    end

    subgraph POI[POI (luoghi di interesse)]
      AP1[AP POI-01 (SSID dedicato)]
      AP2[AP POI-02 (SSID dedicato)]
      APN[AP POI-N]
      BLE1[Beacon BLE (opz.)]
    end

    subgraph Tablets[Tablet forniti]
      T[Mini-tablet (certificato device)]
    end

    K1 --> SWI
    K2 --> SWI
    K3 --> SWI
  end

  %% collegamenti
  Internet --> FW
  SWI -. fibra/MPLS/VPN .-> FW
  AP1 -. fibra/MPLS/VPN .-> FW
  AP2 -. fibra/MPLS/VPN .-> FW
  APN -. fibra/MPLS/VPN .-> FW

  %% accesso utente
  T -->|WiFi 802.1X| AP1
  T -->|WiFi 802.1X| AP2
  T -->|WiFi 802.1X| APN

  %% autenticazione
  AP1 -->|EAP-TLS| RADIUS
  AP2 -->|EAP-TLS| RADIUS
  APN -->|EAP-TLS| RADIUS

  %% fruizione contenuti
  T -->|HTTPS| LB
```

## Idee chiave

- I contenuti (video/immagini) stanno su server/object storage, non sui tablet.
- I tablet sono gli unici device abilitati grazie a 802.1X/EAP-TLS (certificati) + MDM.
- Vincolo “solo vicino al POI”: SSID/VLAN per-POI + regole lato server (source network → poiId) e/o beacon BLE.
