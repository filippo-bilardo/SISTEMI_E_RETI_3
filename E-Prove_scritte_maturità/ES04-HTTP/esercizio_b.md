# Progetto Autonomo — Web Server per WebFactory S.r.l.

**Tempo stimato:** 3–4 ore  
**Difficoltà:** ⭐⭐⭐ (Intermedia)  
**Modalità:** Individuale (relazione scritta richiesta)

---

## Scenario

**WebFactory S.r.l.** è una piccola azienda di sviluppo web che gestisce tre ambienti distinti sulla propria rete interna: un sito pubblico aziendale, un pannello di amministrazione riservato e un ambiente di sviluppo/testing. Per ragioni di sicurezza e organizzazione, i tre ambienti si trovano su **subnet separate** nello spazio di indirizzamento privato `172.16.0.0/24`.

Il responsabile IT ti ha incaricato di progettare e implementare l'intera infrastruttura web interna in Cisco Packet Tracer.

---

## Architettura di Rete Richiesta

### Spazio di indirizzamento

**Rete principale:** `172.16.0.0/24`  
Divisa in **3 subnet /26**:

| Subnet | Indirizzo Rete | Range host | Broadcast | Uso |
|--------|---------------|------------|-----------|-----|
| Subnet 1 | `172.16.0.0/26` | `172.16.0.1` – `172.16.0.62` | `172.16.0.63` | Server farm (web, ftp, mail) |
| Subnet 2 | `172.16.0.64/26` | `172.16.0.65` – `172.16.0.126` | `172.16.0.127` | Uffici amministrativi |
| Subnet 3 | `172.16.0.128/26` | `172.16.0.129` – `172.16.0.190` | `172.16.0.191` | Reparto sviluppo |

> 💡 Una subnet /26 ha **subnet mask 255.255.255.192** e fornisce 62 host utilizzabili.

### Siti web da configurare

| Sito | Nome DNS | IP Proposto | Contenuto |
|------|----------|-------------|-----------|
| Sito pubblico | `www.webfactory.local` | `172.16.0.10` | Pagina aziendale con presentazione |
| Amministrazione | `admin.webfactory.local` | `172.16.0.11` | Pannello admin riservato |
| Sviluppo | `dev.webfactory.local` | `172.16.0.12` | Ambiente di test/sviluppo |

---

## Requisiti del Progetto

### Requisito 1 — Piano di Indirizzamento Completo *(15 pt)*

Completa la seguente tabella con **tutti i dispositivi** della topologia:

| Dispositivo | Ruolo | Subnet | Indirizzo IP | Subnet Mask | Default Gateway | DNS Server |
|-------------|-------|--------|--------------|-------------|-----------------|------------|
| Router0 | Gateway Subnet 1 | Subnet 1 | `172.16.0.1` | `255.255.255.192` | — | — |
| Router0 | Gateway Subnet 2 | Subnet 2 | `172.16.0.65` | `255.255.255.192` | — | — |
| Router0 | Gateway Subnet 3 | Subnet 3 | `172.16.0.128` | `255.255.255.192` | — | — |
| Server-DNS | DNS Interno | Subnet 1 | `172.16.0.5` | `255.255.255.192` | `172.16.0.1` | `172.16.0.5` |
| Server-WWW | Web pubblico | Subnet 1 | _(da compilare)_ | | | |
| Server-Admin | Web admin | Subnet 1 | _(da compilare)_ | | | |
| Server-Dev | Web sviluppo | Subnet 1 | _(da compilare)_ | | | |
| Switch-Farm | Switch Subnet 1 | — | — | — | — | — |
| Admin-PC1 | Client amm. 1 | Subnet 2 | _(da compilare)_ | | | |
| Admin-PC2 | Client amm. 2 | Subnet 2 | _(da compilare)_ | | | |
| Dev-PC1 | Client sviluppo 1 | Subnet 3 | _(da compilare)_ | | | |
| Dev-PC2 | Client sviluppo 2 | Subnet 3 | _(da compilare)_ | | | |

> ⚠️ **Prima di procedere:** fai verificare il piano di indirizzamento dal docente o confrontalo con un compagno.

---

### Requisito 2 — Topologia Packet Tracer *(15 pt)*

Crea la topologia in PT con i seguenti elementi:

**Dispositivi obbligatori:**
- 1× Router Cisco 2901 (con 3 interfacce attive per le 3 subnet)
- 1× Switch Cisco 2960-24TT per la server farm (Subnet 1)
- 1× Switch Cisco 2960-24TT per gli uffici (Subnet 2) + 1× per lo sviluppo (Subnet 3)
- 4× Generic Server: DNS, WWW, Admin, Dev
- 4× PC: 2 per Subnet 2, 2 per Subnet 3

**Schema topologico atteso:**

```
                         [Router0]
                        /    |    \
                Gi0/0  /  Gi0/1  \ Gi0/2
                      /           \         \
                [Switch-Farm]  [Switch-Adm] [Switch-Dev]
               /    |    |  \       |    |      |    |
          [DNS][WWW][Adm][Dev] [AdmPC1][AdmPC2] [DevPC1][DevPC2]
          .5   .10  .11  .12   .70    .71        .135   .136
```

> 💡 Un router Cisco 2901 ha di default solo 2 interfacce GigabitEthernet. Per la terza subnet, usa un modulo aggiuntivo: clicca sul router → onglet **Physical** → aggiungi il modulo **HWIC-1GE** nel primo slot vuoto (a router spento).

**Checklist topologia:**
- [ ] Router con 3 interfacce configurate
- [ ] Switch separato per ogni subnet
- [ ] Server farm collegata allo Switch-Farm
- [ ] PC amministrativi collegati allo Switch-Adm
- [ ] PC sviluppo collegati allo Switch-Dev
- [ ] Tutti i link verdi in Realtime Mode

---

### Requisito 3 — Configurazione IP e Routing *(10 pt)*

1. Configura tutti gli indirizzi IP secondo il piano di indirizzamento
2. Sul Router0, abilita il routing inter-subnet (le interfacce devono essere in `no shutdown`)
3. Verifica la connettività di base con **ping** tra subnet diverse

**Test di connettività inter-subnet (da compilare):**

| Test | Sorgente | Destinazione | Risultato |
|------|----------|-------------|-----------|
| Ping 1 | Admin-PC1 (`.70`) | Server-WWW (`.10`) | ✅ / ❌ |
| Ping 2 | Dev-PC1 (`.135`) | Server-DNS (`.5`) | ✅ / ❌ |
| Ping 3 | Dev-PC2 (`.136`) | Admin-PC2 (`.71`) | ✅ / ❌ |

---

### Requisito 4 — Configurazione DNS *(15 pt)*

Sul server **Server-DNS** (`172.16.0.5`):

1. Abilita il servizio DNS (**Services → DNS → ON**)
2. Aggiungi tutti i record A necessari:

| Record da creare | Tipo | IP |
|-----------------|------|-----|
| `www.webfactory.local` | A Record | `172.16.0.10` |
| `admin.webfactory.local` | A Record | `172.16.0.11` |
| `dev.webfactory.local` | A Record | `172.16.0.12` |
| `dns.webfactory.local` | A Record | `172.16.0.5` |

3. Imposta `172.16.0.5` come DNS Server su **tutti** i dispositivi della rete (server e PC).

---

### Requisito 5 — Pagine HTML Personalizzate *(20 pt)*

Ogni sito web deve avere una pagina `index.html` **completamente diversa** e riconoscibile, con contenuto appropriato al suo scopo.

#### 5.1 Server-WWW — Sito pubblico (`www.webfactory.local`)

Requisiti minimi per la pagina:
- Titolo: "WebFactory S.r.l. — Soluzioni Web su Misura"
- Logo testuale ASCII dell'azienda
- Sezione "Chi siamo" con testo descrittivo
- Sezione "Servizi" con almeno 4 voci (es: sviluppo web, e-commerce, hosting, consulenza)
- Footer con contatti (inventati)

Esempio di struttura minima:

```html
<!DOCTYPE html>
<html lang="it">
<head>
  <title>WebFactory S.r.l.</title>
</head>
<body>
  <h1>WebFactory S.r.l.</h1>
  <pre>
 __    __     _     __    __
 \ \  / /    / \    \ \  / /
  \ \/ /    / _ \    \ \/ /
   \  /    / ___ \    \  /
    \/    /_/   \_\    \/
  WebFactory S.r.l.
  </pre>
  <!-- Completa con il contenuto richiesto -->
</body>
</html>
```

#### 5.2 Server-Admin — Pannello amministrativo (`admin.webfactory.local`)

Requisiti minimi:
- Titolo: "Pannello Amministrazione — ACCESSO RISERVATO"
- Messaggio di avviso (accesso solo personale autorizzato)
- Lista di aree amministrative (es: gestione utenti, backup, monitoraggio)
- IP e subnet visibili nella pagina

#### 5.3 Server-Dev — Ambiente sviluppo (`dev.webfactory.local`)

Requisiti minimi:
- Titolo: "Ambiente di Sviluppo — WebFactory Dev Lab"
- Avviso: "Ambiente di TEST — Non usare in produzione"
- Lista progetti in corso (inventati, almeno 3)
- Versione dell'ambiente (es: "Ambiente: Node.js 20 / PHP 8.2")

> ⚠️ Le 3 pagine devono essere **chiaramente distinguibili** a colpo d'occhio. Pagine identiche o quasi identiche non ricevono punteggio pieno.

---

### Requisito 6 — Test di Connettività Completo *(15 pt)*

Verifica che **ogni PC** possa raggiungere **tutti e 3 i siti** per nome DNS.

Compila la tabella dei test (✅ successo / ❌ fallimento):

| PC Client | URL Testata | Pagina ricevuta | Risultato |
|-----------|-------------|----------------|-----------|
| Admin-PC1 | `http://www.webfactory.local` | Sito pubblico | |
| Admin-PC1 | `http://admin.webfactory.local` | Pannello admin | |
| Admin-PC1 | `http://dev.webfactory.local` | Ambiente dev | |
| Admin-PC2 | `http://www.webfactory.local` | Sito pubblico | |
| Admin-PC2 | `http://admin.webfactory.local` | Pannello admin | |
| Admin-PC2 | `http://dev.webfactory.local` | Ambiente dev | |
| Dev-PC1 | `http://www.webfactory.local` | Sito pubblico | |
| Dev-PC1 | `http://admin.webfactory.local` | Pannello admin | |
| Dev-PC1 | `http://dev.webfactory.local` | Ambiente dev | |
| Dev-PC2 | `http://www.webfactory.local` | Sito pubblico | |
| Dev-PC2 | `http://admin.webfactory.local` | Pannello admin | |
| Dev-PC2 | `http://dev.webfactory.local` | Ambiente dev | |

> Tutti i 12 test devono dare esito positivo per ottenere il punteggio massimo.

---

### Requisito 7 — Documentazione e Relazione *(10 pt)*

Prepara una breve relazione (anche su foglio o documento digitale) che includa:

1. **Schema topologico** disegnato a mano o con PT (con tutti gli IP annotati)
2. **Piano di indirizzamento** compilato (tabella del Requisito 1)
3. **Tabella dei test** compilata con risultati reali (Requisito 6)
4. **Problemi incontrati**: descrivi almeno un problema che hai incontrato e come l'hai risolto
5. **Screenshot richiesti**: almeno 5 screenshot significativi (topologia, DNS, browser su almeno 2 siti diversi, ping inter-subnet)

---

## 📊 Rubrica di Valutazione

| Requisito | Criterio | Punti |
|-----------|---------|-------|
| **1 — Piano indirizz.** | Piano completo, corretto, coerente con /26 | 15 |
| **2 — Topologia PT** | Dispositivi corretti, cavi giusti, link verdi | 15 |
| **3 — IP e Routing** | Tutti gli IP configurati, ping inter-subnet funzionante | 10 |
| **4 — DNS** | Tutti i record A presenti, DNS funzionante su tutti i PC | 15 |
| **5 — Pagine HTML** | 3 pagine distinte, contenuto appropriato, HTML valido | 20 |
| **6 — Test connett.** | Tutti i 12 test superati con documentazione | 15 |
| **7 — Documentazione** | Relazione completa con schema, tabelle, screenshot | 10 |
| **TOTALE** | | **100** |

### 🌟 Bonus (fino a +15 punti)

| Bonus | Descrizione | Punti extra |
|-------|-------------|-------------|
| **CSS Inline** | Aggiunta di stili CSS inline alle pagine HTML (colori, font, layout) | +5 |
| **Personalizzazione HTML avanzata** | Tabelle HTML, liste ordinate/non ordinate, immagini ASCII art elaborate | +5 |
| **Troubleshooting documentato** | Sezione nella relazione con almeno 2 problemi reali incontrati + soluzioni adottate | +5 |

---

## 📋 Checklist Finale

Prima di consegnare, verifica:

- [ ] File salvato come `es04b_webfactory.pkt`
- [ ] Piano di indirizzamento completamente compilato
- [ ] Router con 3 interfacce attive e routing funzionante
- [ ] Server DNS con tutti i 4 record A
- [ ] 3 server web con pagine HTML distinte e personalizzate
- [ ] Tutti i PC hanno DNS impostato a `172.16.0.5`
- [ ] 12/12 test nella tabella connettività completati
- [ ] Relazione con schema topologico e almeno 5 screenshot
- [ ] Nome e data sulla relazione

---

> 💡 **Suggerimento**: Configura e testa un pezzo alla volta. Prima fai funzionare la Subnet 1 (server farm), poi aggiungi la Subnet 2, infine la Subnet 3. Testa il DNS solo dopo aver verificato la connettività IP di base.
