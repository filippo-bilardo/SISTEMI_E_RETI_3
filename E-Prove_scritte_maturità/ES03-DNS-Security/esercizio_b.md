# Esercizio B — Piano di Sicurezza DNS per SecureNet S.r.l.

**Tipo**: Progetto autonomo  
**Difficoltà**: ★★★★☆  
**Tempo stimato**: 120–150 minuti  
**File da consegnare**: `es03b_securenet.pkt` + documento PDF/Word del piano di sicurezza

---

## 🎯 Obiettivi

Al termine di questo progetto lo studente sarà in grado di:
- Progettare una rete con subnet separate per reparti diversi
- Identificare i rischi DNS specifici di una rete aziendale multi-reparto
- Configurare ACL per prevenire attacchi DNS amplification
- Documentare un piano di sicurezza DNS professionale
- Testare e validare le misure di sicurezza implementate

---

## 🏢 Scenario Aziendale

**SecureNet S.r.l.** è un'azienda di consulenza informatica con 3 reparti organizzati su subnet separate:

| Reparto | Subnet | Range IP |
|---------|--------|----------|
| IT | 10.10.0.0/27 | 10.10.0.1 – 10.10.0.30 |
| Finance | 10.10.0.32/27 | 10.10.0.33 – 10.10.0.62 |
| HR | 10.10.0.64/27 | 10.10.0.65 – 10.10.0.94 |

La rete backbone è `10.10.0.0/24`. Il CISO (Chief Information Security Officer) ha richiesto una protezione specifica contro:

1. **DNS Cache Poisoning** — qualcuno potrebbe avvelenare la cache del resolver interno
2. **DNS Amplification Attack** — il resolver interno non deve essere usabile come amplificatore DDoS
3. **DNS Hijacking** — i client non devono poter usare DNS server non autorizzati

---

## STEP 1 — Piano di Indirizzamento Completo

### 1.1 Calcolo subnet /27

> 💡 **Ricorda**: una subnet /27 ha 32 indirizzi totali, di cui 30 utilizzabili (escludendo network e broadcast).

**Completa la tabella** (alcuni campi sono già compilati come riferimento):

| Subnet | Reparto | Network | Broadcast | Gateway (primo IP) | Range host |
|--------|---------|---------|-----------|-------------------|------------|
| 10.10.0.0/27 | IT | 10.10.0.0 | 10.10.0.31 | 10.10.0.1 | .2 – .30 |
| 10.10.0.32/27 | Finance | _________ | _________ | _________ | _________ |
| 10.10.0.64/27 | HR | _________ | _________ | _________ | _________ |

### 1.2 Piano dispositivi

**Compila la tabella dei dispositivi**:

| Dispositivo | Tipo | Reparto | IP | Subnet Mask | Gateway | DNS |
|------------|------|---------|-----|-------------|---------|-----|
| Router-Core | Cisco 2901 | — | 10.10.0.1 (Fa0/0) | 255.255.255.224 | — | — |
| SW-IT | Cisco 2960 | IT | — | — | — | — |
| SW-Finance | Cisco 2960 | Finance | — | — | — | — |
| SW-HR | Cisco 2960 | HR | — | — | — | — |
| DNS-Primary | Server | IT | 10.10.0.10 | _________ | _________ | _________ |
| DNS-Secondary | Server | IT | 10.10.0.11 | _________ | _________ | _________ |
| PC-IT-1 | PC | IT | 10.10.0.20 | _________ | _________ | _________ |
| PC-Finance-1 | PC | Finance | 10.10.0.50 | _________ | _________ | _________ |
| PC-HR-1 | PC | HR | 10.10.0.80 | _________ | _________ | _________ |

---

## STEP 2 — Topologia in Cisco Packet Tracer

### 2.1 Schema topologico

```
                    [Router-Core]
                   /      |      \
             Fa0/0      Fa0/1    Fa0/2
               |          |        |
           [SW-IT]   [SW-Finance] [SW-HR]
           /    \         |         |
     DNS-Prim  DNS-Sec  PC-Fin1   PC-HR1
     PC-IT1
```

### 2.2 Istruzioni topologia

1. Crea la topologia in Packet Tracer seguendo lo schema
2. Il router Cisco 2901 ha bisogno di un modulo aggiuntivo per la terza interfaccia:
   - Spegni il router → aggiungi modulo **NM-1FE-TX** → riaccendi
3. Cabla tutti i dispositivi con **Copper Straight-Through**
4. Assegna IP a tutte le interfacce del router (sub-interfacce o interfacce separate)

### 2.3 Configurazione Router-Core

```ios
Router> enable
Router# configure terminal
Router(config)# hostname Router-Core

! Interfaccia verso subnet IT (10.10.0.0/27)
Router-Core(config)# interface FastEthernet0/0
Router-Core(config-if)# ip address 10.10.0.1 255.255.255.224
Router-Core(config-if)# no shutdown
Router-Core(config-if)# description "LAN-IT"
Router-Core(config-if)# exit

! Interfaccia verso subnet Finance (10.10.0.32/27)
Router-Core(config)# interface FastEthernet0/1
Router-Core(config-if)# ip address 10.10.0.33 255.255.255.224
Router-Core(config-if)# no shutdown
Router-Core(config-if)# description "LAN-Finance"
Router-Core(config-if)# exit

! Interfaccia verso subnet HR (10.10.0.64/27)
Router-Core(config)# interface FastEthernet1/0
Router-Core(config-if)# ip address 10.10.0.65 255.255.255.224
Router-Core(config-if)# no shutdown
Router-Core(config-if)# description "LAN-HR"
Router-Core(config-if)# exit

Router-Core(config)# end
Router-Core# write memory
```

### 2.4 Configurazione DNS-Primary

Clicca su `DNS-Primary` → **Services** → **DNS** → `ON`

Record DNS da configurare:

| Nome | Tipo | Valore |
|------|------|--------|
| `intranet.securenet.local` | A Record | `10.10.0.15` |
| `mail.securenet.local` | A Record | `10.10.0.16` |
| `files.securenet.local` | A Record | `10.10.0.17` |
| `erp.securenet.local` | A Record | `10.10.0.18` |
| `vpn.securenet.local` | A Record | `10.10.0.19` |

---

## STEP 3 — Configurazione ACL Anti-Amplification

### 3.1 Teoria dell'attacco DNS amplification

In un attacco **DNS amplification**:
1. L'attaccante invia query DNS con **IP sorgente falsificato** (quello della vittima)
2. Il resolver risponde alla vittima con risposte molto più grandi delle query (amplification factor: fino a 70x)
3. Un resolver **aperto** (che risponde a tutti) può essere usato come amplificatore

**Soluzione**: configurare il resolver come **closed resolver** — risponde solo alle query provenienti dalla rete interna.

### 3.2 ACL anti-amplification sul Router-Core

```ios
Router-Core# configure terminal

! ACL per permettere query DNS solo dalle subnet interne
Router-Core(config)# ip access-list extended ANTI-DNS-AMPLIFICATION
Router-Core(config-ext-nacl)# remark === ANTI DNS AMPLIFICATION ===
Router-Core(config-ext-nacl)# remark Permetti query DNS dalla subnet IT
Router-Core(config-ext-nacl)# permit udp 10.10.0.0 0.0.0.31 host 10.10.0.10 eq 53
Router-Core(config-ext-nacl)# permit udp 10.10.0.0 0.0.0.31 host 10.10.0.11 eq 53
Router-Core(config-ext-nacl)# remark Permetti query DNS dalla subnet Finance
Router-Core(config-ext-nacl)# permit udp 10.10.0.32 0.0.0.31 host 10.10.0.10 eq 53
Router-Core(config-ext-nacl)# permit udp 10.10.0.32 0.0.0.31 host 10.10.0.11 eq 53
Router-Core(config-ext-nacl)# remark Permetti query DNS dalla subnet HR
Router-Core(config-ext-nacl)# permit udp 10.10.0.64 0.0.0.31 host 10.10.0.10 eq 53
Router-Core(config-ext-nacl)# permit udp 10.10.0.64 0.0.0.31 host 10.10.0.11 eq 53
Router-Core(config-ext-nacl)# remark Blocca qualsiasi altra query DNS (previene uso come open resolver)
Router-Core(config-ext-nacl)# deny udp any any eq 53
Router-Core(config-ext-nacl)# remark Permetti tutto il resto
Router-Core(config-ext-nacl)# permit ip any any
Router-Core(config-ext-nacl)# exit

! ACL anti-hijacking: i client non possono usare DNS esterni
Router-Core(config)# ip access-list extended ANTI-DNS-HIJACKING
Router-Core(config-ext-nacl)# remark Blocca query DNS verso IP non autorizzati
Router-Core(config-ext-nacl)# deny udp 10.10.0.0 0.0.0.255 any eq 53
Router-Core(config-ext-nacl)# deny tcp 10.10.0.0 0.0.0.255 any eq 53
Router-Core(config-ext-nacl)# permit ip any any
Router-Core(config-ext-nacl)# exit

Router-Core(config)# end
Router-Core# write memory
```

> ⚠️ **Nota**: in Packet Tracer le ACL estese potrebbero avere supporto limitato. Applica l'ACL e documenta il comportamento osservato.

### 3.3 Checklist configurazione ACL

Dopo aver configurato le ACL, verifica:

- [ ] `show access-lists` mostra entrambe le ACL create
- [ ] Un PC interno può fare `nslookup` verso `10.10.0.10` ✅
- [ ] Un PC non può fare query DNS verso IP non autorizzati ✅
- [ ] Il traffico normale (HTTP, ping) non è bloccato ✅
- [ ] Il router non risponde a query DNS provenienti da indirizzi esterni ✅

---

## STEP 4 — Documentazione del Piano di Sicurezza

### 4.1 Struttura del documento richiesto

Redigi un documento di **2–3 pagine** con la seguente struttura:

---

**PIANO DI SICUREZZA DNS — SecureNet S.r.l.**  
*Data: ___/___/______  
Autore: _______________________*

**1. Executive Summary** (5 righe)  
Descrizione sintetica del piano, obiettivi e benefici attesi.

**2. Analisi delle Minacce**  
Compila la tabella:

| Minaccia | Probabilità (B/M/A) | Impatto (B/M/A) | Misura di mitigazione |
|----------|--------------------|-----------------|-----------------------|
| DNS Cache Poisoning | | | |
| DNS Amplification | | | |
| DNS Hijacking | | | |
| DNS Spoofing | | | |

**3. Architettura DNS**  
- Schema dell'architettura (disegno o descrizione)
- Motivazione scelta DNS primario + secondario
- Separazione delle subnet per reparto

**4. Misure di Sicurezza Implementate**  
Per ciascuna misura: descrizione, motivazione tecnica, configurazione applicata.

**5. Test e Validazione**  
Risultati dei test eseguiti in Packet Tracer.

**6. Limitazioni e Sviluppi Futuri**  
Cosa non è possibile implementare in PT e come si procederebbe in ambiente reale (DNSSEC, DoH, SIEM).

---

### 4.2 Tabelle da compilare nel documento

**Tabella Rischi DNS:**

| Scenario | Senza difese | Con difese implementate |
|----------|-------------|------------------------|
| Attaccante sulla rete interna usa DNS malevolo | PC reindirizzati | ACL blocca query verso DNS non autorizzati |
| Server DNS usato come amplificatore DDoS | ________________ | ________________ |
| Cache DNS avvelenata da record falsi | ________________ | ________________ |
| DNS primario offline | ________________ | ________________ |

---

## STEP 5 — Test e Verifica

### 5.1 Test funzionali

Esegui e documenta i risultati di ogni test:

**Test 1 — Risoluzione nomi base**
```
nslookup intranet.securenet.local   (da PC-IT-1)
nslookup mail.securenet.local       (da PC-Finance-1)
nslookup erp.securenet.local        (da PC-HR-1)
```

| Test | Risultato atteso | Risultato ottenuto | ✅/❌ |
|------|-----------------|-------------------|-------|
| nslookup intranet (da IT) | 10.10.0.15 | | |
| nslookup mail (da Finance) | 10.10.0.16 | | |
| nslookup erp (da HR) | 10.10.0.18 | | |

**Test 2 — Ping per nome**
```
ping intranet.securenet.local   (da ciascun reparto)
```

**Test 3 — Failover DNS**
1. Spegni `DNS-Primary`
2. Verifica che i PC configurati con DNS secondario risolvano ancora

**Test 4 — Verifica ACL**
```
! Da un PC, prova a contattare un DNS non autorizzato
! (In PT: cambia il DNS del PC a un IP non autorizzato e verifica timeout)
```

### 5.2 Checklist finale

- [ ] Subnet IT correttamente configurata (`10.10.0.0/27`)
- [ ] Subnet Finance correttamente configurata (`10.10.0.32/27`)
- [ ] Subnet HR correttamente configurata (`10.10.0.64/27`)
- [ ] DNS-Primary risponde a tutti i record configurati
- [ ] DNS-Secondary configurato con gli stessi record
- [ ] ACL anti-amplification configurata e verificata
- [ ] Ping per nome funzionante da tutti i reparti
- [ ] Documento del piano di sicurezza redatto
- [ ] File `.pkt` salvato con nome `es03b_securenet.pkt`

---

## STEP 6 — Estensione Avanzata (opzionale)

### 6.1 Split-horizon DNS

Il **split-horizon DNS** restituisce risposte diverse a seconda di chi fa la query: dalla rete interna risponde con IP privati, dall'esterno con IP pubblici (o nessuna risposta).

**Scenario**: aggiungi un server `web.securenet.com`:
- Query dalla rete interna → risponde con `10.10.0.15` (IP privato)
- Query da reti esterne → non deve ottenere risposta (protezione da information leakage)

In Packet Tracer non è implementabile completamente, ma documenta come funzionerebbe in un ambiente reale con BIND9 o Windows DNS Server.

### 6.2 VLAN per isolamento reparti (se hai già fatto ES01)

Se hai completato ES01, puoi integrare le VLAN:
- VLAN 10: reparto IT
- VLAN 20: reparto Finance
- VLAN 30: reparto HR
- Il DNS-Primary è accessibile da tutte le VLAN tramite routing inter-VLAN

---

## STEP 7 — Consegna

### 7.1 File da consegnare

| File | Descrizione |
|------|-------------|
| `es03b_securenet.pkt` | File Packet Tracer con topologia completa |
| `piano_sicurezza_dns.pdf` (o .docx) | Documento del piano di sicurezza (min 2 pagine) |
| Screenshot 1–5 | Topologia, DNS configurati, ACL, test nslookup, test failover |

### 7.2 Rubrica di Valutazione

| Criterio | Punti | Descrizione |
|----------|-------|-------------|
| **Piano di indirizzamento** | 15 pt | Subnet /27 corrette, tabella completa e senza errori |
| **Topologia PT** | 15 pt | Tutti i dispositivi presenti, cablaggio corretto, IP assegnati |
| **Configurazione DNS** | 15 pt | DNS primario e secondario con record corretti |
| **ACL anti-amplification** | 20 pt | ACL configurata, applicata, documentata e verificata |
| **Documento piano sicurezza** | 20 pt | Struttura completa, analisi rischi, misure documentate |
| **Test e verifica** | 10 pt | Tabella test compilata con risultati reali |
| **Totale** | **95 pt** | |

**Bonus:**
| Bonus | Punti | Descrizione |
|-------|-------|-------------|
| Split-horizon documentato | +3 pt | Spiegazione tecnica corretta |
| Integrazione VLAN (ES01) | +5 pt | Topologia funzionante con VLAN |
| Piano incident response | +2 pt | Sezione aggiuntiva nel documento |

**Soglie di valutazione:**

| Punteggio | Voto |
|-----------|------|
| 90–100+ | 10/10 |
| 80–89 | 9/10 |
| 70–79 | 8/10 |
| 60–69 | 7/10 |
| 50–59 | 6/10 |
| < 50 | Insufficiente |
