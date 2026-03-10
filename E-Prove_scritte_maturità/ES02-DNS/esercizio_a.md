# Esercitazione — Configurazione DNS Interno in Cisco Packet Tracer

**Tempo stimato:** 3–4 ore  
**Difficoltà:** ⭐⭐ (Base–Intermedia)  
**Modalità:** Individuale o coppie

---

## Obiettivo

Configurare un server DNS interno in una rete locale simulata con Cisco Packet Tracer. Al termine dell'esercitazione i client della rete saranno in grado di raggiungere i server aziendali usando nomi simbolici (es. `www.azienda.local`) invece degli indirizzi IP.

---

## 📋 Documentazione richiesta

| # | Screenshot | STEP |
|---|-----------|------|
| 📸 1 | Topologia — dispositivi posizionati (senza cavi) | STEP 2 |
| 📸 2 | Topologia — cavi collegati, tutti i link verdi | STEP 2 |
| 📸 3 | IP Configuration di almeno 2 PC e del Server DNS | STEP 3 |
| 📸 4 | GUI DNS Server — scheda Services → DNS con i record configurati | STEP 4 |
| 📸 5 | GUI Web Server — scheda Services → HTTP, pagina index.html | STEP 5 |
| 📸 6 | IP Configuration di un PC client con DNS impostato | STEP 6 |
| 📸 7 | Ping `www.azienda.local` da un PC client — risposta OK | STEP 7 |
| 📸 8 | Browser simulato PT aperto su `http://www.azienda.local` | STEP 7 |
| 📸 9 | Output `ipconfig /all` e `nslookup` da un PC client | STEP 8 |
| 📸 10 | Salvataggio file `es02a_dns.pkt` | STEP 9 |

---

## Architettura

### Dispositivi

| Dispositivo | Modello | Ruolo |
|-------------|---------|-------|
| Router0 | Cisco 2901 | Gateway della rete `192.168.1.0/24` |
| Switch0 | Cisco 2960-24TT | Switch di accesso |
| Server-DNS | Generic Server | Server DNS interno |
| Server-Web | Generic Server | Web server aziendale |
| Server-Mail | Generic Server | Mail server aziendale |
| PC0 | PC | Client utente |
| PC1 | PC | Client utente |
| PC2 | PC | Client utente |

### Topologia

```
                          [Router0]
                         Gi0/0: 192.168.1.1
                              |
                         (Gi0/0 trunk)
                              |
                         [Switch0]
                    __________|__________
                   /     |       |       \
             [DNS]   [Web]   [Mail]  [PC0][PC1][PC2]
           .10       .20      .30    .100  .101  .102
```

---

## STEP 1: Piano di Indirizzamento

**Rete:** `192.168.1.0/24` — Subnet Mask: `255.255.255.0`  
**Gateway:** `192.168.1.1` (Router0)  
**DNS:** `192.168.1.10` (Server-DNS)

| Dispositivo | Interfaccia | Indirizzo IP | Subnet Mask | Default Gateway | DNS Server |
|-------------|-------------|--------------|-------------|-----------------|------------|
| **Router0** | GigabitEthernet0/0 | 192.168.1.1 | 255.255.255.0 | — | — |
| **Server-DNS** | FastEthernet0 | 192.168.1.10 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| **Server-Web** | FastEthernet0 | 192.168.1.20 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| **Server-Mail** | FastEthernet0 | 192.168.1.30 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| **PC0** | FastEthernet0 | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| **PC1** | FastEthernet0 | 192.168.1.101 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| **PC2** | FastEthernet0 | 192.168.1.102 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |

### Record DNS da configurare

| Nome (FQDN) | Tipo | Valore (IP) |
|-------------|------|-------------|
| `dns.azienda.local` | A | 192.168.1.10 |
| `www.azienda.local` | A | 192.168.1.20 |
| `mail.azienda.local` | A | 192.168.1.30 |
| `router.azienda.local` | A | 192.168.1.1 |

---

## STEP 2: Creazione Topologia in Cisco Packet Tracer

### 2.1 Posizionamento Dispositivi

1. Apri **Cisco Packet Tracer**
2. Dal pannello dispositivi in basso:
   - **Routers** → **2900 Series** → trascina **2901** × 1 → rinomina `Router0`
   - **Switches** → **2960** → trascina **2960-24TT** × 1 → rinomina `Switch0`
   - **End Devices** → **Server** → trascina × 3 → rinomina `Server-DNS`, `Server-Web`, `Server-Mail`
   - **End Devices** → **PC** → trascina × 3 → rinomina `PC0`, `PC1`, `PC2`
3. Disponi i dispositivi in modo ordinato (Router in alto, Switch al centro, gli altri sotto)

> 📸 **Screenshot 1** — Topologia con tutti i dispositivi posizionati e rinominati (prima dei cavi)

### 2.2 Collegamento Cavi

Usa il cavo **Copper Straight-Through** per tutti i collegamenti:

| Da | Porta | A | Porta |
|----|-------|---|-------|
| Router0 | GigabitEthernet0/0 | Switch0 | FastEthernet0/1 |
| Server-DNS | FastEthernet0 | Switch0 | FastEthernet0/2 |
| Server-Web | FastEthernet0 | Switch0 | FastEthernet0/3 |
| Server-Mail | FastEthernet0 | Switch0 | FastEthernet0/4 |
| PC0 | FastEthernet0 | Switch0 | FastEthernet0/5 |
| PC1 | FastEthernet0 | Switch0 | FastEthernet0/6 |
| PC2 | FastEthernet0 | Switch0 | FastEthernet0/7 |

> 💡 Dopo il collegamento, attendi qualche secondo finché tutti i link diventano **verdi**.

> 📸 **Screenshot 2** — Topologia completa con cavi collegati e link verdi

---

## STEP 3: Configurazione IP di tutti i Dispositivi

### Router0

Fai doppio clic su **Router0** → scheda **CLI** → premi Invio per attivare la console:

```
Router> enable
Router# configure terminal
Router(config)# interface GigabitEthernet0/0
Router(config-if)# ip address 192.168.1.1 255.255.255.0
Router(config-if)# no shutdown
Router(config-if)# description Gateway-LAN
Router(config-if)# exit
Router(config)# end
Router# write memory
```

### Server-DNS

Fai doppio clic su **Server-DNS** → scheda **Config** → **FastEthernet0**:

| Campo | Valore |
|-------|--------|
| IP Address | `192.168.1.10` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | `192.168.1.1` |
| DNS Server | `192.168.1.10` |

### Server-Web

| Campo | Valore |
|-------|--------|
| IP Address | `192.168.1.20` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | `192.168.1.1` |
| DNS Server | `192.168.1.10` |

### Server-Mail

| Campo | Valore |
|-------|--------|
| IP Address | `192.168.1.30` |
| Subnet Mask | `255.255.255.0` |
| Default Gateway | `192.168.1.1` |
| DNS Server | `192.168.1.10` |

### PC0, PC1, PC2

Per ogni PC: doppio clic → scheda **Config** → **FastEthernet0** (oppure scheda **Desktop** → **IP Configuration**):

| Dispositivo | IP Address | Subnet Mask | Gateway | DNS Server |
|-------------|------------|-------------|---------|------------|
| PC0 | 192.168.1.100 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| PC1 | 192.168.1.101 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |
| PC2 | 192.168.1.102 | 255.255.255.0 | 192.168.1.1 | 192.168.1.10 |

> ⚠️ Assicurati di impostare il campo **DNS Server** su tutti i dispositivi a `192.168.1.10`.

> 📸 **Screenshot 3** — IP Configuration di almeno 2 PC e del Server-DNS

---

## STEP 4: Configurazione Servizio DNS sul Server DNS

1. Fai doppio clic su **Server-DNS**
2. Vai alla scheda **Services** → seleziona **DNS** nel menu laterale
3. Verifica che **DNS Service** sia impostato su **ON**
4. Aggiungi i record DNS uno per uno usando i campi in fondo alla pagina:

### Aggiungere il record `dns.azienda.local`

| Campo | Valore |
|-------|--------|
| Name | `dns.azienda.local` |
| Type | `A Record` |
| Address | `192.168.1.10` |

Clicca **Add** ✅

### Aggiungere il record `www.azienda.local`

| Campo | Valore |
|-------|--------|
| Name | `www.azienda.local` |
| Type | `A Record` |
| Address | `192.168.1.20` |

Clicca **Add** ✅

### Aggiungere il record `mail.azienda.local`

| Campo | Valore |
|-------|--------|
| Name | `mail.azienda.local` |
| Type | `A Record` |
| Address | `192.168.1.30` |

Clicca **Add** ✅

### Aggiungere il record `router.azienda.local`

| Campo | Valore |
|-------|--------|
| Name | `router.azienda.local` |
| Type | `A Record` |
| Address | `192.168.1.1` |

Clicca **Add** ✅

La tabella dei record DNS dovrebbe apparire così:

| Name | Type | Detail |
|------|------|--------|
| dns.azienda.local | A Record | 192.168.1.10 |
| www.azienda.local | A Record | 192.168.1.20 |
| mail.azienda.local | A Record | 192.168.1.30 |
| router.azienda.local | A Record | 192.168.1.1 |

> 💡 In Packet Tracer il DNS gestisce solo record di tipo **A** (indirizzo IPv4) nella versione base. I record CNAME e MX non sono supportati nella GUI standard.

> 📸 **Screenshot 4** — Scheda Services → DNS con tutti e 4 i record visibili e il servizio ON

---

## STEP 5: Configurazione Web Server

1. Fai doppio clic su **Server-Web**
2. Vai alla scheda **Services** → **HTTP**
3. Verifica che **HTTP** sia **ON** e **HTTPS** sia **ON**
4. Nella lista dei file, clicca su `index.html` → **Edit**
5. Sostituisci il contenuto con una pagina personalizzata:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Azienda.Local - Portale Interno</title>
</head>
<body>
  <h1>Benvenuto nel portale di Azienda.Local</h1>
  <p>Questo sito è raggiungibile tramite DNS interno.</p>
  <p>Server IP: 192.168.1.20</p>
  <hr>
  <p><em>Rete aziendale - accesso riservato</em></p>
</body>
</html>
```

6. Clicca **Save** per salvare le modifiche

> 📸 **Screenshot 5** — Scheda Services → HTTP del Server-Web con la pagina index.html modificata

---

## STEP 6: Verifica Configurazione DNS sui Client

Per ogni PC client verifica che il campo DNS Server sia correttamente impostato:

1. Fai doppio clic su **PC0** → scheda **Desktop** → **IP Configuration**
2. Controlla che il campo **DNS Server** contenga `192.168.1.10`
3. Ripeti per **PC1** e **PC2**

> ⚠️ Se il campo DNS Server è vuoto o errato, la risoluzione dei nomi **non funzionerà** anche se la rete è raggiungibile via IP.

> 📸 **Screenshot 6** — IP Configuration di un PC client con il campo DNS Server impostato a `192.168.1.10`

---

## STEP 7: Test Risoluzione Nomi

### Test con ping per nome

Da **PC0** → scheda **Desktop** → **Command Prompt**:

```
C:\> ping www.azienda.local
```

Output atteso:
```
Pinging www.azienda.local [192.168.1.20] with 32 bytes of data:
Reply from 192.168.1.20: bytes=32 time<1ms TTL=128
Reply from 192.168.1.20: bytes=32 time<1ms TTL=128
Reply from 192.168.1.20: bytes=32 time<1ms TTL=128
Reply from 192.168.1.20: bytes=32 time<1ms TTL=128

Ping statistics for 192.168.1.20:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss)
```

✅ Il fatto che appaia `[192.168.1.20]` conferma che il DNS ha risolto correttamente il nome.

Prova anche:
```
C:\> ping mail.azienda.local
C:\> ping router.azienda.local
```

### Test con il Browser

Da **PC0** → scheda **Desktop** → **Web Browser**:
1. Nel campo URL digita: `http://www.azienda.local`
2. Premi **Go**
3. Dovresti vedere la pagina HTML personalizzata del Server-Web

> 📸 **Screenshot 7** — Output del ping a `www.azienda.local` con risposta IP risolta

> 📸 **Screenshot 8** — Browser simulato con la pagina `http://www.azienda.local` caricata correttamente

---

## STEP 8: Verifica e Comandi di Debug

Da **PC0** → scheda **Desktop** → **Command Prompt**:

### ipconfig /all
```
C:\> ipconfig /all
```

Controlla:
- **IPv4 Address**: `192.168.1.100`
- **Default Gateway**: `192.168.1.1`
- **DNS Servers**: `192.168.1.10` ← deve essere presente!

### nslookup
```
C:\> nslookup www.azienda.local
```

Output atteso:
```
Server:  dns.azienda.local
Address: 192.168.1.10

Name:    www.azienda.local
Address: 192.168.1.20
```

```
C:\> nslookup mail.azienda.local
```

Output atteso:
```
Server:  dns.azienda.local
Address: 192.168.1.10

Name:    mail.azienda.local
Address: 192.168.1.30
```

### Ping di verifica completa

```
C:\> ping dns.azienda.local
C:\> ping www.azienda.local
C:\> ping mail.azienda.local
C:\> ping router.azienda.local
```

> 📸 **Screenshot 9** — Output di `ipconfig /all` e `nslookup www.azienda.local` dallo stesso PC client

---

## STEP 9: Salvataggio del File

1. Dal menu **File** → **Save As...**
2. Salva con il nome: `es02a_dns.pkt`
3. Salva nella cartella del tuo progetto

> 📸 **Screenshot 10** — Finestra di salvataggio del file `es02a_dns.pkt`

---

## 🔧 Troubleshooting

### ❌ Il ping per nome non funziona ma il ping per IP sì

**Causa probabile:** Il DNS Server non è stato impostato correttamente nel client.  
**Soluzione:** Apri IP Configuration del PC e verifica che DNS Server sia `192.168.1.10`.

### ❌ Il ping per IP non funziona

**Causa probabile:** Errore nella configurazione IP del client o dell'interfaccia del Router.  
**Soluzione:** Verifica con `ipconfig /all` che IP, mask e gateway siano corretti. Controlla che l'interfaccia `Gi0/0` del Router sia attiva (`no shutdown`).

### ❌ nslookup risponde "DNS request timed out"

**Causa probabile:** Il servizio DNS sul Server-DNS è disabilitato (OFF).  
**Soluzione:** Apri Server-DNS → Services → DNS → imposta il toggle su **ON**.

### ❌ Il browser non apre la pagina

**Causa probabile:** Il servizio HTTP del Server-Web è disabilitato.  
**Soluzione:** Apri Server-Web → Services → HTTP → verifica che HTTP sia **ON**.

### ❌ nslookup mostra IP errato

**Causa probabile:** Il record DNS è stato inserito con un errore di battitura.  
**Soluzione:** Apri Server-DNS → Services → DNS → individua il record errato, rimuovilo con il pulsante **Remove** e ricrealo correttamente.

---

## 📝 Note Tecniche

> 💡 In Packet Tracer il servizio DNS supporta principalmente record di tipo **A** tramite la GUI grafica. In ambienti reali si configurano anche record AAAA, CNAME, MX, PTR, ecc.

> 💡 Il dominio `.local` è una convenzione comune per i domini DNS ad uso esclusivamente interno (non raggiungibili da Internet).

> ⚠️ Il router in questa topologia non è strettamente necessario per la comunicazione all'interno della stessa subnet `/24`, ma è buona pratica includerlo come gateway e per simulare un ambiente aziendale realistico.

> 💡 Per testare più scenari, prova a modificare uno dei record DNS (es. cambia l'IP di `www.azienda.local`) e verifica che il ping per nome rifletta immediatamente il cambiamento.
