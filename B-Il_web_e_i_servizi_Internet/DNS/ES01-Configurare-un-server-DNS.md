## Esercitazione 01: Configurazione Rete e Servizi Base (Packet Tracer)

**Obiettivo:** Configurare una piccola rete LAN con servizi Web e DNS e verificarne il corretto funzionamento utilizzando sia indirizzi IP che nomi di dominio.

### Guida su youtube
- [Configurare un server DNS in Packet Tracer](https://www.youtube.com/watch?v=XpI99fazgF8)

### Istruzioni per l'Allestimento (Packet Tracer)

1.  **Aggiungi Dispositivi:** Posiziona i seguenti dispositivi nell'area di lavoro:
    * **2 PC** (PC-Studenti)
    * **1 Switch** (2960 o simile)
    * **1 Server Web** (Server-WEB)
    * **1 Server DNS** (Server-DNS)
2.  **Cablaggio:** Collega tutti i dispositivi allo **Switch** utilizzando cavi **Straight-Through** (Cavo dritto). Utilizza la funzione *Automatically Choose Connection Type* per velocizzare.
3.  **Definizione della Rete:** Utilizzeremo la rete **192.168.10.0/24**.

### Passaggi di Configurazione

#### 1. Configurazione Indirizzi IP Statici

Configura l'indirizzamento IP statico su tutti gli host (PC e Server). **Non configurare il Default Gateway in questa fase**.

| Dispositivo | Indirizzo IP | Subnet Mask |
| :--- | :--- | :--- |
| **PC-Studenti 1** | 192.168.10.10 | 255.255.255.0 |
| **PC-Studenti 2** | 192.168.10.11 | 255.255.255.0 |
| **Server-WEB** | 192.168.10.100 | 255.255.255.0 |
| **Server-DNS** | 192.168.10.200 | 255.255.255.0 |

#### 2. Configurazione del Servizio Web (HTTP)

1.  Sul **Server-WEB** (192.168.10.100), vai su **Services** $\rightarrow$ **HTTP**.
2.  Assicurati che i servizi **HTTP** e **HTTPS** siano **On**.
3.  Modifica la pagina `index.html` per includere un messaggio di benvenuto personalizzato (es. "Benvenuti sul Web Server di [Nome dello Studente]").

#### 3. Configurazione del Servizio DNS

1.  Sul **Server-DNS** (192.168.10.200), vai su **Services** $\rightarrow$ **DNS**.
2.  Imposta il servizio DNS su **On**.
3.  Aggiungi i seguenti **Record A** per mappare i nomi di dominio agli indirizzi IP:

| Domain Name | Type | Address |
| :--- | :--- | :--- |
| **aula.local** | A Record | 192.168.10.100 |
| **webserver.local** | A Record | 192.168.10.100 |

#### 4. Configurazione del DNS Server sugli Host

Torna su ogni PC (PC-Studenti 1 e 2) e sul **Server-WEB** (192.168.10.100) e configura l'indirizzo IP del **Server-DNS** (192.168.10.200) nel campo **DNS Server** all'interno della configurazione IP.

### Richieste di Verifica e Test

Gli studenti devono eseguire e documentare i seguenti test:

1.  **Test di Connettività Base (Ping):**
    * Dal **PC-Studenti 1**, apri il **Command Prompt**.
    * Esegui un **ping** verso il **Server-WEB** utilizzando l'indirizzo IP (**192.168.10.100**).
    * *Domanda:* La comunicazione ha avuto successo? Spiega perché (risposta attesa: Sì, sono nella stessa sottorete).
2.  **Test del Servizio Web (Indirizzo IP):**
    * Dal **PC-Studenti 2**, apri il **Web Browser**.
    * Digita l'indirizzo IP del server: `192.168.10.100`
    * *Domanda:* Sei riuscito a visualizzare la pagina web personalizzata?
3.  **Test del Servizio DNS (Nome di Dominio):**
    * Dal **PC-Studenti 1**, apri il **Web Browser**.
    * Digita il primo nome di dominio: `aula.local`
    * Digita il secondo nome di dominio: `webserver.local`
    * *Domanda:* La risoluzione del nome ha funzionato? Cosa dimostra questo risultato riguardo la configurazione del DNS Server?
4.  **Verifica DNS (Command Line):**
    * Dal **PC-Studenti 2**, apri il **Command Prompt**.
    * Esegui un **ping** verso `aula.local`.
    * *Domanda:* La richiesta di ping ha mostrato l'indirizzo IP risolto? Qual è l'indirizzo IP che è stato risolto? (risposta attesa: 192.168.10.100).

### Consegna
Gli studenti devono documentare i risultati dei test, rispondere alle domande poste e fornire screenshot delle configurazioni e dei risultati ottenuti. La consegna deve essere effettuata con un documento Google su classroom.