# TESTO PROVA A038_ORD24
## ESAME DI STATO CONCLUSIVO DEL SECONDO CICLO DI ISTRUZIONE

**Sessione**: Ordinaria 2024  
**Seconda prova scritta**

---

**Ministero dell'istruzione e del merito**

**Classe di Concorso**: A038  
**Indirizzo**: ITIA - INFORMATICA E TELECOMUNICAZIONI ARTICOLAZIONE "INFORMATICA"  
*(Testo valevole anche per gli indirizzi quadriennali IT32)*

**Disciplina**: SISTEMI E RETI

---

## 📋 ISTRUZIONI

**Il candidato svolga la prima parte della prova e due tra i quesiti proposti nella seconda parte.**

---

## PRIMA PARTE

### Contesto

L'amministrazione di una **Regione italiana**, attraverso una società appositamente creata, ha recentemente sviluppato una **infrastruttura di comunicazione in fibra ottica**, allo scopo di fornire connettività a banda larga ad Enti locali, scuole e strutture sanitarie pubbliche presenti in tutto il suo territorio. 

In particolare, in ambito sanitario, la società gestisce anche un **data-center** che raccoglie tutti i **dati sanitari dei cittadini** residenti in regione, relativi alle prestazioni sanitarie erogate dalle strutture pubbliche (**fascicolo sanitario elettronico**).

I dati raccolti nel fascicolo sanitario elettronico di ciascun paziente possono essere di **vari formati e dimensioni** in quanto riguardano, ad esempio:
- Gli **accertamenti diagnostici** (es. ecografia)
- Le **visite specialistiche** (es. visita cardiologica) 
- La relativa **documentazione** (referto, immagini diagnostiche, video …)

### Progetto di Estensione

All'interno della componente **M6C2** "*Innovazione, ricerca e digitalizzazione del Servizio Sanitario Nazionale*", prevista dalla **Missione 6 del PNRR**, la Regione intende **estendere la rete in fibra** già esistente, per offrire il servizio di connettività a banda larga a **tutte le strutture sanitarie private convenzionate**, in modo che anche i dati da loro prodotti possano direttamente confluire nel data-center regionale.

In tal modo, tutti i **cittadini** ed i **medici** chiamati a curarli, sia presso strutture sanitarie pubbliche che presso quelle private convenzionate, avranno a disposizione in un **unico luogo virtuale** (il fascicolo sanitario elettronico) tutte le informazioni sanitarie di loro interesse.

### Piano di Indirizzamento

Per differenziare le diverse tipologie di strutture connesse alla rete (Enti locali, scuole e strutture sanitarie pubbliche e private), la società regionale che gestisce l'infrastruttura in fibra ha adottato un **piano di indirizzamento utilizzando sottoreti della rete 10.0.0.0/8**; in particolare, a questo nuovo servizio di connettività verso le strutture sanitarie private convenzionate è stata assegnata la **sottorete 10.100.0.0/16**. 

Questa sottorete sarà finalizzata **esclusivamente all'interazione con il data-center** delle strutture sanitarie private convenzionate, ma **non offrirà loro servizi di accesso generalizzato ad Internet**.

### Requisiti del Progetto

Utilizzando gli indirizzi consentiti da questa sottorete, il progetto dovrà pertanto dettagliare un **piano di indirizzamento** che permetta di connettere un numero di strutture sanitarie private convenzionate che si stima essere **intorno alle 2000 in regione** (con possibili incrementi futuri), assegnando a ciascuna di esse la disponibilità di un **minimo di 8 indirizzi complessivi**.

Ogni struttura sanitaria privata convenzionata ovviamente dispone già di una propria **infrastruttura di rete locale interna**. La società regionale di gestione fornirà a tali strutture private convenzionate un **dispositivo per la connessione alla rete regionale**, configurato e controllato da remoto dalla società regionale stessa. 

Il progetto dovrà garantire che **ciascuna struttura collegata non possa accedere alle reti di tutte le altre strutture** connesse alla rete in fibra regionale.

---

### Richieste al Candidato

**Il candidato analizzi la realtà di riferimento e, formulate le opportune ipotesi aggiuntive, contribuisca alla stesura del progetto svolgendo i seguenti punti:**

#### 1. Infrastruttura di Rete e Schema

Sviluppi una **descrizione di massima**, anche supportata da uno **schema grafico**, dell'infrastruttura di rete in fibra pre-esistente (che connette Enti locali, scuole e strutture sanitarie pubbliche) e di come questa si evolverà per implementare il nuovo servizio per le strutture sanitarie private convenzionate, con opportune **esemplificazioni degli indirizzamenti IP adottati**.

#### 2. Dispositivo per Strutture Private

Indichi la **tipologia e le caratteristiche hardware** (es: numero e tipologia delle singole porte) del dispositivo che sarà fornito ad ogni struttura sanitaria privata convenzionata, nonché i **dettagli relativi alla eventuale configurazione di rete** delle sue porte; espliciti anche i **servizi** che ritiene debbano essere configurati su tale dispositivo.

#### 3. Connessione alla LAN Esistente

Considerando le caratteristiche della LAN pre-esistente in una ipotetica struttura sanitaria privata convenzionata, specifichi con quali **eventuali apparati aggiuntivi o riconfigurazioni** degli apparati già esistenti tale rete verrà connessa con la rete in fibra regionale, **esemplificando opportunamente**.

#### 4. Sicurezza dei Dati

Data la natura **sensibile dei dati** trattati, espliciti le **principali misure** che è opportuno adottare per garantirne un trattamento con **adeguata sicurezza**, sia per la loro **archiviazione** che per i **trasferimenti da e per il data-center**; in particolare il candidato specifichi le **modalità e la schedulazione temporale** con cui le strutture sanitarie trasferiscono al data-center regionale i dati delle prestazioni sanitarie da loro effettuate.

---

## SECONDA PARTE

**Svolgere DUE quesiti a scelta tra i seguenti:**

### I. Strategie contro perdita dati

In relazione al tema proposto nella prima parte, si prevedano le **strategie da adottare in caso di malfunzionamenti** della connessione in fase di trasferimento dati e sui sistemi di archiviazione, allo scopo di **evitare possibili perdite di dati**.

### II. Autenticazione qualificata cittadini

In relazione al tema proposto nella prima parte, il candidato descriva le possibili forme di **autenticazione qualificata (a più fattori)** per consentire al singolo cittadino di **consultare via web** tutti i dati del proprio fascicolo sanitario elettronico (accertamenti e visite specialistiche).

### III. Web server accessibile da Internet

Una piccola azienda dispone di un normale collegamento ad Internet a banda larga, con un **router** a cui è assegnato un **solo indirizzo IP pubblico statico**. Nella rete interna alla piccola azienda esiste un **web server locale** che si vuole rendere accessibile da Internet sia tramite **protocollo HTTP che HTTPS**, e si vuole rendere gestibile da remoto tramite **protocollo SSH**. 

Il candidato descriva la **configurazione del router** necessaria per raggiungere lo scopo, motivando nel dettaglio le scelte fatte ed elencando i **comandi utilizzabili**.

### IV. Troubleshooting connettività Internet

All'interno di una azienda con una propria LAN, un **tecnico di help-desk** riceve la segnalazione di un utente circa l'impossibilità di "*navigare su Internet*". 

Si descrivano i **passi** e gli **opportuni strumenti** da utilizzare per individuare **tre possibili cause del problema**.

---

## 📝 NOTE

**Durata massima della prova**: 6 ore

**È consentito**:
- L'uso di manuali tecnici
- L'uso di calcolatrici scientifiche o grafiche purché non siano dotate della capacità di elaborazione simbolica algebrica e non abbiano la disponibilità di connessione a Internet
- L'uso del dizionario bilingue (italiano-lingua del paese di provenienza) per i candidati di madrelingua non italiana

**Non è consentito** lasciare l'Istituto prima che siano trascorse 3 ore dalla consegna della traccia.

---

**Fine del testo della prova**
