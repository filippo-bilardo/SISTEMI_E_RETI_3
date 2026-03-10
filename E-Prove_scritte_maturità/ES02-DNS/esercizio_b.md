# Esercitazione DNS — Rete Aziendale MediaCorp

**Tempo stimato:** 3–4 ore  
**Difficoltà:** ⭐⭐⭐ (Intermedia)  
**Modalità:** Individuale

---

## 📋 Scenario

Sei il network administrator di **MediaCorp**, un'azienda editoriale di medie dimensioni. L'azienda dispone di due reparti principali:

- **Reparto Redazione** — giornalisti, editor e fotografi
- **Reparto Amministrazione** — contabilità, HR e direzione

I due reparti si trovano sullo stesso edificio ma su subnet IP separate. Il tuo compito è progettare e configurare l'intera infrastruttura DNS interna, con un **server DNS primario** e un **server DNS secondario** per garantire la ridondanza, e creare i record necessari per almeno **5 servizi interni** (portale web, posta elettronica, FTP, VPN e intranet).

---

## 🗺️ Schema di Rete

```
                        [Router-GW]
                      Gi0/0: 192.168.10.1
                            |
                       [Switch-Core]
                    __________|__________
                   /                     \
          [Switch-RED]               [Switch-AMM]
          Redazione                  Amministrazione
          192.168.10.0/26            192.168.10.64/26
          (.1 → .62)                 (.65 → .126)
```

---

## STEP 1: Subnetting e Piano di Indirizzamento (30 min)

### Schema Subnet

La rete aziendale è `192.168.10.0/24`. Sono state assegnate le seguenti subnet con maschera `/26`:

| Subnet | Indirizzo Rete | Range Host | Broadcast | Reparto |
|--------|----------------|------------|-----------|---------|
| Subnet-RED | 192.168.10.0/26 | .1 — .62 | .63 | Redazione |
| Subnet-AMM | 192.168.10.64/26 | .65 — .126 | .127 | Amministrazione |
| Subnet-SRV | 192.168.10.128/26 | .129 — .190 | .191 | Server Farm |
| Subnet-MGMT | 192.168.10.192/26 | .193 — .254 | .255 | Management |

### Piano di Indirizzamento da Completare

Compila la tabella con gli indirizzi IP che assegnerai ai dispositivi:

| Dispositivo | Ruolo | Indirizzo IP | Subnet Mask | Gateway | Subnet |
|-------------|-------|--------------|-------------|---------|--------|
| Router-GW | Gateway principale | 192.168.10.1 | 255.255.255.0 | — | — |
| Server-DNS1 | DNS primario | 192.168.10.130 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-DNS2 | DNS secondario | 192.168.10.131 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-Web | Web server (`www`) | 192.168.10.132 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-Mail | Mail server | 192.168.10.133 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-FTP | FTP server | 192.168.10.134 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-VPN | VPN gateway | 192.168.10.135 | 255.255.255.192 | 192.168.10.129 | SRV |
| Server-Intranet | Intranet portal | 192.168.10.136 | 255.255.255.192 | 192.168.10.129 | SRV |
| PC-RED1 | Client Redazione | ___________ | 255.255.255.192 | 192.168.10.1 | RED |
| PC-RED2 | Client Redazione | ___________ | 255.255.255.192 | 192.168.10.1 | RED |
| PC-AMM1 | Client Amministrazione | ___________ | 255.255.255.192 | 192.168.10.65 | AMM |
| PC-AMM2 | Client Amministrazione | ___________ | 255.255.255.192 | 192.168.10.65 | AMM |

> 💡 Scegli indirizzi IP validi all'interno del range di ciascuna subnet. Ricorda di non usare l'indirizzo di rete (.0) né il broadcast (.63/.127).

### Record DNS da Creare (minimo 5)

Compila la tabella dei record DNS:

| FQDN | Tipo Record | Indirizzo IP | Servizio |
|------|-------------|--------------|---------|
| `www.mediacorp.local` | A | 192.168.10.132 | Portale web aziendale |
| `mail.mediacorp.local` | A | 192.168.10.133 | Server posta elettronica |
| `ftp.mediacorp.local` | A | 192.168.10.134 | Server FTP condivisione file |
| `vpn.mediacorp.local` | A | 192.168.10.135 | Gateway VPN per accesso remoto |
| `intranet.mediacorp.local` | A | 192.168.10.136 | Portale intranet aziendale |
| `dns1.mediacorp.local` | A | 192.168.10.130 | DNS primario |
| `dns2.mediacorp.local` | A | 192.168.10.131 | DNS secondario |
| `router.mediacorp.local` | A | 192.168.10.1 | Gateway principale |

---

## STEP 2: Costruzione Topologia Packet Tracer (20 min)

Costruisci la topologia in Cisco Packet Tracer seguendo lo schema di rete.

### Dispositivi necessari

| Tipo | Modello | Quantità | Nome in PT |
|------|---------|----------|-----------|
| Router | Cisco 2901 | 1 | Router-GW |
| Switch | Cisco 2960-24TT | 3 | Switch-Core, Switch-RED, Switch-AMM |
| Server | Generic Server | 7 | DNS1, DNS2, Web, Mail, FTP, VPN, Intranet |
| PC | Generic PC | 4 | PC-RED1, PC-RED2, PC-AMM1, PC-AMM2 |

### Cablaggio

- Usa **Copper Straight-Through** per tutti i collegamenti host-switch
- Usa **Copper Cross-Over** per switch-switch (o lascia scegliere Auto-MDI-X a PT)
- Collega Router-GW → Switch-Core → Switch-RED / Switch-AMM in cascata

### ☑️ Checklist Topologia

- [ ] Router-GW con almeno 2 interfacce attive (una per subnet o subinterface)
- [ ] Switch-Core connesso a Router-GW, Switch-RED e Switch-AMM
- [ ] Tutti i server nella subnet SRV (connessi direttamente a Switch-Core o aggiungendo uno switch server)
- [ ] PC-RED1, PC-RED2 connessi a Switch-RED
- [ ] PC-AMM1, PC-AMM2 connessi a Switch-AMM
- [ ] Tutti i link verdi ✅

---

## STEP 3: Configurazione IP e Router (30 min)

### Configurazione Router-GW

Il router deve avere un'interfaccia (o subinterface) per ogni subnet:

```
Router-GW> enable
Router-GW# configure terminal

! Interfaccia verso Switch-Core (usa una singola interfaccia Gi0/0)
Router-GW(config)# interface GigabitEthernet0/0
Router-GW(config-if)# ip address 192.168.10.1 255.255.255.0
Router-GW(config-if)# no shutdown
Router-GW(config-if)# description Gateway-MediaCorp
Router-GW(config-if)# exit

Router-GW(config)# end
Router-GW# write memory
```

> 💡 Per semplicità in questa esercitazione puoi usare una singola interfaccia con la rete `192.168.10.0/24`. La separazione in subnet è logica (piano di indirizzamento) ma non richiede configurazione VLAN aggiuntiva.

### Configurazione IP dei Server e dei PC

Configura ciascun dispositivo con i valori della tabella compilata allo STEP 1.

Ricorda di impostare su **tutti** i dispositivi:
- IP Address corretto per la propria subnet
- Subnet Mask `/26` (255.255.255.192) per i dispositivi nelle subnet /26
- Default Gateway: l'interfaccia del router per quella subnet
- DNS Server: `192.168.10.130` (DNS primario)

### ☑️ Checklist Configurazione IP

- [ ] Router-GW — interfaccia Gi0/0 attiva con IP `192.168.10.1`
- [ ] Server-DNS1 — IP `192.168.10.130`, gateway `192.168.10.129`
- [ ] Server-DNS2 — IP `192.168.10.131`
- [ ] Server-Web — IP `192.168.10.132`
- [ ] Server-Mail — IP `192.168.10.133`
- [ ] Server-FTP — IP `192.168.10.134`
- [ ] Server-VPN — IP `192.168.10.135`
- [ ] Server-Intranet — IP `192.168.10.136`
- [ ] PC-RED1, PC-RED2 — IP nel range `192.168.10.1–62`
- [ ] PC-AMM1, PC-AMM2 — IP nel range `192.168.10.65–126`
- [ ] DNS Server impostato a `192.168.10.130` su tutti i client

---

## STEP 4: Configurazione DNS Primario (Server-DNS1) (30 min)

1. Apri **Server-DNS1** → scheda **Services** → **DNS**
2. Imposta DNS Service su **ON**
3. Inserisci tutti i record della tabella compilata allo STEP 1

### ☑️ Checklist Record DNS (minimo 5 obbligatori + bonus)

- [ ] `www.mediacorp.local` → 192.168.10.132
- [ ] `mail.mediacorp.local` → 192.168.10.133
- [ ] `ftp.mediacorp.local` → 192.168.10.134
- [ ] `vpn.mediacorp.local` → 192.168.10.135
- [ ] `intranet.mediacorp.local` → 192.168.10.136
- [ ] `dns1.mediacorp.local` → 192.168.10.130 *(bonus)*
- [ ] `dns2.mediacorp.local` → 192.168.10.131 *(bonus)*
- [ ] `router.mediacorp.local` → 192.168.10.1 *(bonus)*

---

## STEP 5: Configurazione DNS Secondario (Server-DNS2) (20 min)

> ⚠️ In Cisco Packet Tracer la replica automatica tra DNS primario e secondario **non è supportata**. Devi configurare manualmente gli stessi record anche su Server-DNS2.

1. Apri **Server-DNS2** → scheda **Services** → **DNS**
2. Imposta DNS Service su **ON**
3. Inserisci **tutti gli stessi record** che hai configurato su Server-DNS1

### Vantaggi del DNS Secondario

In un ambiente reale, il DNS secondario:
- Garantisce la **continuità del servizio** se il DNS primario si guasta
- Distribuisce il **carico** delle query DNS
- Può essere configurato per rispondere a query da una subnet specifica

> 💡 Per testare il DNS secondario, prova a impostare il campo DNS Server di un PC a `192.168.10.131` invece di `.130` e verifica che `nslookup` funzioni ugualmente.

---

## STEP 6: Configurazione Servizi Web e FTP (20 min)

### Web Server (`www.mediacorp.local`)

1. Apri **Server-Web** → **Services** → **HTTP** → **ON**
2. Modifica `index.html` con una pagina personalizzata per MediaCorp
3. Aggiungi almeno titolo, nome azienda e link ai reparti

### FTP Server (`ftp.mediacorp.local`)

1. Apri **Server-FTP** → **Services** → **FTP** → **ON**
2. Aggiungi un utente FTP:
   - Username: `redazione`
   - Password: `media2024`
   - Permessi: Read + Write
3. Testa la connessione FTP da un PC:
   ```
   C:\> ftp ftp.mediacorp.local
   ```

### ☑️ Checklist Servizi

- [ ] HTTP attivo su Server-Web con pagina personalizzata
- [ ] FTP attivo su Server-FTP con almeno un utente
- [ ] Accesso al sito via browser `http://www.mediacorp.local` funzionante
- [ ] Connessione FTP via nome `ftp.mediacorp.local` funzionante

---

## STEP 7: Test e Verifica Finale (30 min)

### Test da PC-RED1

Da **PC-RED1** → Desktop → Command Prompt:

```
C:\> ipconfig /all
C:\> ping www.mediacorp.local
C:\> ping mail.mediacorp.local
C:\> ping ftp.mediacorp.local
C:\> ping vpn.mediacorp.local
C:\> ping intranet.mediacorp.local
C:\> nslookup www.mediacorp.local
C:\> nslookup mail.mediacorp.local
```

### Test da PC-AMM1

Da **PC-AMM1** → Desktop → Command Prompt:

```
C:\> ping www.mediacorp.local
C:\> nslookup ftp.mediacorp.local
```

### Apertura Browser

Da **PC-RED1** → Desktop → Web Browser:
- Apri `http://www.mediacorp.local` → verifica la pagina
- Apri `http://intranet.mediacorp.local` → verifica la pagina

### Tabella Verifiche da Compilare

| Test | Da | Comando | Risultato atteso | ✅/❌ |
|------|----|---------|-----------------|------|
| Ping per nome | PC-RED1 | `ping www.mediacorp.local` | Reply da 192.168.10.132 | |
| Ping per nome | PC-AMM1 | `ping mail.mediacorp.local` | Reply da 192.168.10.133 | |
| nslookup | PC-RED1 | `nslookup ftp.mediacorp.local` | Address: 192.168.10.134 | |
| Browser | PC-RED2 | `http://www.mediacorp.local` | Pagina HTML caricata | |
| DNS secondario | PC-AMM2 | `nslookup vpn.mediacorp.local` | Address: 192.168.10.135 | |
| FTP per nome | PC-RED1 | `ftp ftp.mediacorp.local` | Connessione FTP aperta | |

---

## 📦 Consegna Finale

**File da consegnare:**

1. `Cognome_Nome_MediaCorp.pkt` — file Packet Tracer completo
2. `Piano_Indirizzamento.pdf` — tabella IP compilata (STEP 1)
3. `Tabella_Record_DNS.pdf` — elenco record DNS configurati
4. `Test_Connettivita.pdf` — tabella verifiche con screenshot

**Scadenza:** _______________

---

## ⚖️ Criteri di Valutazione

| Criterio | Peso | Punti |
|----------|------|-------|
| Piano di indirizzamento corretto (STEP 1) | 15% | /15 |
| Topologia PT costruita correttamente | 10% | /10 |
| Configurazione IP di tutti i dispositivi | 15% | /15 |
| DNS primario con ≥ 5 record corretti | 20% | /20 |
| DNS secondario configurato e funzionante | 10% | /10 |
| Servizi Web e FTP attivi e raggiungibili | 10% | /10 |
| Test di verifica superati (tabella compilata) | 15% | /15 |
| Documentazione e consegna | 5% | /5 |
| **TOTALE** | **100%** | **/100** |

**Bonus:**
- +5 punti per ogni record DNS aggiuntivo oltre i 5 richiesti (max +10)
- +5 punti per configurazione FTP con più utenti e permessi differenziati
- +5 punti per pagina intranet con contenuto differente dalla home page web

---

## 📚 Risorse

- [`docs/01_DNS.md`](docs/01_DNS.md) — Teoria DNS completa
- [`docs/02_Record_DNS.md`](docs/02_Record_DNS.md) — Guida ai tipi di record
- [`docs/03_DNS_Interno.md`](docs/03_DNS_Interno.md) — DNS aziendale e split-horizon
- [`docs/04_Troubleshooting_DNS.md`](docs/04_Troubleshooting_DNS.md) — Risoluzione problemi
