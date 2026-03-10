# Esercizio B — Progetto Autonomo
## Piano di Sicurezza Web per "SafeWeb S.r.l."

**Tipo**: Progetto autonomo  
**Durata stimata**: 4–6 ore  
**Strumento**: Cisco Packet Tracer 8.x + documento di analisi (Word/PDF)  
**File da consegnare**: `es05b_safeweb.pkt` + `report_sicurezza.pdf`

---

## 📋 Scenario

**SafeWeb S.r.l.** è una società di consulenza informatica che gestisce un **portale web aziendale** accessibile sia ai dipendenti interni che ai clienti esterni. L'azienda ha recentemente subito un audit di sicurezza che ha evidenziato gravi vulnerabilità nella loro infrastruttura di rete.

Il CTO (Chief Technology Officer) ti ha incaricato di:
1. **Progettare** una nuova architettura di rete sicura
2. **Implementarla** in Cisco Packet Tracer
3. **Documentare** le minacce identificate e le contromisure adottate
4. **Produrre** un report finale con raccomandazioni

### Rete da progettare: `10.0.0.0/24` divisa in 3 subnet `/26`

| Subnet | Indirizzo | Broadcast | Range host | Zona | Dispositivi |
|--------|-----------|-----------|------------|------|-------------|
| Subnet 1 | `10.0.0.0/26` | `10.0.0.63` | `.1` – `.62` | **DMZ** | Web Server, Reverse Proxy |
| Subnet 2 | `10.0.0.64/26` | `10.0.0.127` | `.65` – `.126` | **LAN Interna** | PC dipendenti |
| Subnet 3 | `10.0.0.128/26` | `10.0.0.191` | `.129` – `.190` | **Server Farm** | Database, App Server |

---

## STEP 1 — Piano di Indirizzamento Completo

### 1.1 Calcolo subnet (da compilare)

Completa la seguente tabella:

| Campo | Subnet DMZ | Subnet LAN | Subnet Server Farm |
|-------|-----------|------------|--------------------|
| Indirizzo di rete | `10.0.0.0` | `10.0.0.64` | `10.0.0.128` |
| Prefix length | `/26` | `/26` | `/26` |
| Subnet Mask | `255.255.255.192` | _____________ | _____________ |
| Indirizzo broadcast | `10.0.0.63` | _____________ | _____________ |
| Primo host utilizzabile | `10.0.0.1` | _____________ | _____________ |
| Ultimo host utilizzabile | `10.0.0.62` | _____________ | _____________ |
| Host totali disponibili | 62 | _____________ | _____________ |

### 1.2 Tabella IP dei dispositivi (da completare)

| Dispositivo | Subnet | Indirizzo IP | Mask | Gateway | Ruolo |
|-------------|--------|--------------|------|---------|-------|
| Router (GW DMZ) | DMZ | `10.0.0.1` | `255.255.255.192` | — | Default GW DMZ |
| Router (GW LAN) | LAN | `10.0.0.65` | _____________ | — | Default GW LAN |
| Router (GW Server) | Server | `10.0.0.129` | _____________ | — | Default GW Server |
| Web Server | DMZ | `10.0.0.10` | _____________ | `10.0.0.1` | Portale web HTTPS |
| Reverse Proxy | DMZ | `10.0.0.11` | _____________ | `10.0.0.1` | Proxy inverso |
| PC Dipendente 1 | LAN | `10.0.0.70` | _____________ | _____________ | Workstation |
| PC Dipendente 2 | LAN | `10.0.0.71` | _____________ | _____________ | Workstation |
| PC Dipendente 3 | LAN | `10.0.0.72` | _____________ | _____________ | Workstation |
| Database Server | Server | `10.0.0.140` | _____________ | _____________ | MySQL / MariaDB |
| App Server | Server | `10.0.0.141` | _____________ | _____________ | Backend applicativo |

> 💡 **Suggerimento**: Il router in questa topologia ha **3 interfacce** (o usa sub-interfacce su un router con un'interfaccia e uno switch L3). In PT, usa un **Router 2911** che ha 3 porte Gi.

---

## STEP 2 — Topologia Packet Tracer con Firewall/ACL

### 2.1 Dispositivi richiesti

| Dispositivo | Modello PT | Qtà | Zona |
|-------------|-----------|-----|------|
| Router | Cisco 2911 | 1 | Perimetro |
| Switch DMZ | Cisco 2960 | 1 | DMZ |
| Switch LAN | Cisco 2960 | 1 | LAN |
| Switch Server | Cisco 2960 | 1 | Server Farm |
| Web Server | Server-PT | 1 | DMZ |
| Reverse Proxy | Server-PT | 1 | DMZ |
| PC Dipendenti | PC-PT | 3 | LAN |
| Database Server | Server-PT | 1 | Server Farm |
| App Server | Server-PT | 1 | Server Farm |

### 2.2 Schema topologia da realizzare

```
Internet (simulato)
        |
   [Router 2911]
   /      |      \
[SW-DMZ] [SW-LAN] [SW-SERVER]
 /  \      |  |  |    |    |
WS  RP   PC1 PC2 PC3  DB  APP
```

### 2.3 Configurazione router (3 interfacce)

```
Router(config)# hostname FW-ROUTER
FW-ROUTER(config)# interface GigabitEthernet0/0
FW-ROUTER(config-if)# description "DMZ"
FW-ROUTER(config-if)# ip address 10.0.0.1 255.255.255.192
FW-ROUTER(config-if)# no shutdown

FW-ROUTER(config)# interface GigabitEthernet0/1
FW-ROUTER(config-if)# description "LAN-Interna"
FW-ROUTER(config-if)# ip address 10.0.0.65 255.255.255.192
FW-ROUTER(config-if)# no shutdown

FW-ROUTER(config)# interface GigabitEthernet0/2
FW-ROUTER(config-if)# description "Server-Farm"
FW-ROUTER(config-if)# ip address 10.0.0.129 255.255.255.192
FW-ROUTER(config-if)# no shutdown
FW-ROUTER(config)# end
FW-ROUTER# write memory
```

### ✅ Checklist STEP 2

- [ ] Topologia realizzata in PT con tutti i dispositivi
- [ ] 3 switch separati per DMZ, LAN, Server Farm
- [ ] Router 2911 con 3 interfacce configurate
- [ ] Tutti gli IP assegnati correttamente
- [ ] Ping tra tutti i dispositivi funzionante

---

## STEP 3 — HTTPS Obbligatorio su Tutti i Server Web

### 3.1 Configurazione Web Server (DMZ)

Apri **WS → Services → HTTP**:
- HTTP: **OFF**
- HTTPS: **ON**

Crea una pagina `index.html` per il portale SafeWeb (puoi personalizzarla):

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <title>SafeWeb S.r.l. — Portale Clienti</title>
</head>
<body>
  <h1>🔒 Benvenuti su SafeWeb S.r.l.</h1>
  <p>Portale sicuro — Connessione protetta da TLS 1.3</p>
  <p>Tutti i servizi sono accessibili esclusivamente via HTTPS.</p>
</body>
</html>
```

### 3.2 Configurazione Reverse Proxy (DMZ)

Il **reverse proxy** riceve le connessioni HTTPS dall'esterno e le inoltrano internamente ai server applicativi. In PT, configura anche il Reverse Proxy con HTTPS abilitato.

> 💡 **Teoria**: In produzione, il reverse proxy (es. Nginx, HAProxy) gestisce i certificati TLS e bilancia il carico tra i server interni. I server interni possono usare HTTP (solo sulla rete interna sicura) o HTTPS (double-encryption per ambienti ad alta sicurezza).

### 3.3 Verifica HTTPS

Da ogni PC LAN, verifica che:
- `https://10.0.0.10` → risponde correttamente ✅
- `http://10.0.0.10` → non risponde (servizio disattivato) ✅

### ✅ Checklist STEP 3

- [ ] Web Server con solo HTTPS attivo (HTTP disattivato)
- [ ] Reverse Proxy con HTTPS attivo
- [ ] Browser da PC LAN raggiunge `https://10.0.0.10`
- [ ] HTTP (porta 80) non risponde sul Web Server

---

## STEP 4 — Documentazione Minacce (OWASP Top 10)

Compila la seguente tabella analizzando **almeno 4 minacce** dall'OWASP Top 10. Per ciascuna:
- Descrivi il meccanismo dell'attacco
- Indica come si manifesta nell'infrastruttura SafeWeb
- Proponi la contromisura specifica

### Tabella Analisi Minacce (da compilare)

| # | Minaccia OWASP | Meccanismo | Vettore in SafeWeb | Contromisura |
|---|---------------|-----------|-------------------|--------------|
| 1 | Injection (SQL, LDAP) | | | |
| 2 | Broken Authentication | | | |
| 3 | XSS (Cross-Site Scripting) | | | |
| 4 | _(a scelta)_ | | | |
| 5 | _(a scelta)_ | | | |
| 6 | _(a scelta, bonus)_ | | | |

### Esempio compilato (da usare come modello):

| # | Minaccia | Meccanismo | Vettore | Contromisura |
|---|----------|-----------|---------|--------------|
| 1 | SQL Injection | Inserimento di codice SQL in input non sanificato | Form di login su portale SafeWeb: `' OR 1=1 --` | Prepared statements, WAF, validazione input lato server |

---

## STEP 5 — ACL sul Router per Bloccare Traffico HTTP Non Autorizzato

Configura le seguenti ACL su **FW-ROUTER** per implementare la politica di sicurezza:

### 5.1 Politica di sicurezza da implementare

| Regola | Descrizione |
|--------|-------------|
| ✅ Permetti | HTTPS (TCP 443) da LAN verso DMZ |
| ✅ Permetti | HTTPS (TCP 443) da LAN verso Server Farm |
| ❌ Blocca | HTTP (TCP 80) da LAN verso DMZ |
| ❌ Blocca | Accesso diretto da LAN a Database (TCP 3306) |
| ✅ Permetti | App Server (Server Farm) verso Database |
| ✅ Permetti | ICMP (ping) per debug |
| ❌ Blocca | Tutto il resto |

### 5.2 Configurazione ACL (da completare e applicare)

```
FW-ROUTER(config)# ip access-list extended ACL-LAN-OUT

! Permetti HTTPS verso DMZ
FW-ROUTER(config-ext-nacl)# permit tcp 10.0.0.64 0.0.0.63 10.0.0.0 0.0.0.63 eq 443

! Blocca HTTP verso DMZ
FW-ROUTER(config-ext-nacl)# deny tcp 10.0.0.64 0.0.0.63 10.0.0.0 0.0.0.63 eq 80
FW-ROUTER(config-ext-nacl)# remark Blocca HTTP non cifrato

! Blocca accesso diretto a DB
FW-ROUTER(config-ext-nacl)# deny tcp 10.0.0.64 0.0.0.63 host 10.0.0.140 eq 3306
FW-ROUTER(config-ext-nacl)# remark Blocca MySQL diretto dalla LAN

! Permetti ICMP
FW-ROUTER(config-ext-nacl)# permit icmp any any

! Permetti resto del traffico
FW-ROUTER(config-ext-nacl)# permit ip any any
FW-ROUTER(config-ext-nacl)# exit

! Applica sulla interfaccia LAN (traffico in uscita dalla LAN verso il router)
FW-ROUTER(config)# interface GigabitEthernet0/1
FW-ROUTER(config-if)# ip access-group ACL-LAN-OUT in
FW-ROUTER(config-if)# exit
FW-ROUTER(config)# end
FW-ROUTER# write memory
```

### 5.3 Verifica ACL

```
FW-ROUTER# show access-lists
FW-ROUTER# show ip interface GigabitEthernet0/1
```

### ✅ Checklist STEP 5

- [ ] ACL configurata e applicata sull'interfaccia LAN
- [ ] Test: HTTPS da LAN verso DMZ → funziona
- [ ] Test: HTTP da LAN verso DMZ → bloccato
- [ ] Test: accesso MySQL diretto → bloccato
- [ ] `show access-lists` mostra i match counter incrementarsi

---

## STEP 6 — Tabella dei Test di Sicurezza

Esegui i seguenti test e documenta i risultati nella tabella:

| # | Test | Da | Verso | Porta | Metodo | Risultato atteso | Risultato effettivo | ✅/❌ |
|---|------|-----|------|-------|--------|-----------------|---------------------|-------|
| T01 | Accesso HTTPS portale | PC1 (LAN) | WS (DMZ) | 443 | Browser | ✅ Pagina carica | | |
| T02 | Accesso HTTP bloccato | PC1 (LAN) | WS (DMZ) | 80 | Browser | ❌ Timeout/rifiuto | | |
| T03 | Ping DMZ da LAN | PC1 | WS | ICMP | Ping | ✅ Risposta OK | | |
| T04 | Ping Server Farm da LAN | PC1 | DB | ICMP | Ping | ✅ Risposta OK | | |
| T05 | MySQL bloccato dalla LAN | PC1 | DB | 3306 | — | ❌ Bloccato da ACL | | |
| T06 | HTTPS da PC2 a WS | PC2 | WS | 443 | Browser | ✅ Funziona | | |
| T07 | Traffico HTTPS cifrato | PC3 | WS | 443 | Sim.Mode | ✅ Payload cifrato | | |
| T08 | Show access-lists counter | Router CLI | — | — | `show access-lists` | Match counter > 0 | | |

---

## STEP 7 — Report Finale con Raccomandazioni

Produci un documento (Word o PDF) con le seguenti sezioni:

### Struttura del Report

```
1. SOMMARIO ESECUTIVO (max 1 pagina)
   - Obiettivo del progetto
   - Architettura implementata
   - Risultati principali

2. ARCHITETTURA DI RETE
   - Schema topologico (screenshot da PT)
   - Tabella IP completa
   - Descrizione delle zone (DMZ, LAN, Server Farm)

3. ANALISI DELLE MINACCE
   - Tabella OWASP (almeno 4 voci compilate dal STEP 4)
   - Threat model: chi attacca, cosa attacca, come

4. CONTROMISURE IMPLEMENTATE
   - HTTPS obbligatorio (configurazione PT)
   - ACL perimetrali (configurazione + screenshot)
   - Separazione delle zone (DMZ, LAN, Server Farm)

5. RISULTATI DEI TEST
   - Tabella test compilata (STEP 6)
   - Screenshot significativi

6. RACCOMANDAZIONI FUTURE
   - Almeno 5 raccomandazioni (es: IDS/IPS, WAF, MFA, log monitoring, penetration test annuale)
   - Per ciascuna: costo stimato (basso/medio/alto), priorità (1-5)

7. CONCLUSIONI
```

### ✅ Checklist STEP 7

- [ ] Documento strutturato con tutte le 7 sezioni
- [ ] Schema topologico incluso
- [ ] Tabella IP completa
- [ ] Almeno 4 minacce OWASP documentate
- [ ] Tabella test compilata con risultati reali
- [ ] Almeno 5 raccomandazioni con priorità

---

## 📊 Rubrica di Valutazione (100 punti)

| Criterio | Descrizione | Punti |
|----------|-------------|-------|
| **Piano di indirizzamento** | Subnet /26 corrette, tabella IP completa | 10 |
| **Topologia PT** | 3 switch separati, router con 3 interfacce, cablaggio corretto | 15 |
| **HTTPS obbligatorio** | HTTP disabilitato, HTTPS attivo su tutti i server web | 10 |
| **Analisi minacce** | Almeno 4 minacce OWASP documentate correttamente | 15 |
| **Configurazione ACL** | ACL corrette e applicate, politica di sicurezza rispettata | 15 |
| **Test di sicurezza** | Tabella test compilata con risultati verificabili | 15 |
| **Report finale** | Struttura completa, chiarezza espositiva, raccomandazioni sensate | 20 |
| **BONUS: Analisi approfondita** | Più di 6 minacce OWASP con esempi di codice/URL | +5 |
| **BONUS: Diagrammi** | Diagramma threat model disegnato a mano o digitale | +5 |
| **BONUS: Standard OWASP** | Confronto con OWASP Testing Guide o ASVS | +5 |

**Soglie di valutazione**:
- 90–100 pt → Eccellente
- 75–89 pt → Buono
- 60–74 pt → Sufficiente
- < 60 pt → Insufficiente

---

> ⚔️ **Sfida avanzata**: Configura un secondo set di ACL per la Server Farm che impedisca al Database di iniziare connessioni verso la DMZ o la LAN (solo il server applicativo deve poter interrogare il DB). Documenta la configurazione nel report.
