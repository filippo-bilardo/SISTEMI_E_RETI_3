# A038 - ESAME DI STATO CONCLUSIVO DEL SECONDO CICLO DI ISTRUZIONE

**Sessione suppletiva 2024**  
**Seconda prova scritta**

---

## Informazioni Generali

**Ministero dell'istruzione e del merito**

**Indirizzo**: ITIA - INFORMATICA E TELECOMUNICAZIONI ARTICOLAZIONE "INFORMATICA"  
(Testo valevole anche per gli indirizzi quadriennali IT32)

**Disciplina**: SISTEMI E RETI

**Durata massima della prova**: 6 ore

---

## Istruzioni

Il candidato svolga la **prima parte** della prova e **due tra i quesiti** proposti nella seconda parte.

### Note

- È consentito l'uso di manuali tecnici e di calcolatrici scientifiche o grafiche purché non siano dotate della capacità di elaborazione simbolica algebrica e non abbiano la disponibilità di connessione a Internet.
- È consentito l'uso del dizionario bilingue (italiano-lingua del paese di provenienza) per i candidati di madrelingua non italiana.
- Non è consentito lasciare l'Istituto prima che siano trascorse 3 ore dalla consegna della traccia.

---

## PRIMA PARTE

### Gestione eventi con grandi folle

Una città italiana di interesse turistico internazionale ha deciso di sperimentare un nuovo sistema di monitoraggio del flusso delle persone in occasione di grandi eventi (culturali, artistici, sportivi). A tali eventi, che si svolgono in un preciso luogo della città, si potrà accedere unicamente mediante biglietti a pagamento o anche gratuiti.

Nell'intera area del comune saranno presenti **punti di informazione automatici (totem)**, basati su touch screen, dove l'utente potrà informarsi su uno o più eventi e acquistare il biglietto in autonomia.

Per la gestione del sistema di monitoraggio del flusso delle persone in occasione di un evento, viene messa a disposizione una **sede operativa** composta da due piani:

- **Primo piano**: sarà presente un'area dedicata all'assistenza pre- e post-vendita dei biglietti, dove gli operatori potranno svolgere le loro mansioni.
- **Secondo piano**: sarà presente la sala di controllo dove il personale addetto, attraverso telecamere di sorveglianza, potrà visionare le immagini in diretta dei luoghi interessati dagli eventi.

Uno degli obiettivi è quello di ridurre il sovraffollamento nelle aree critiche e poter intervenire con prontezza in caso di necessità.

In punti strategici della città, verranno infatti collocate **telecamere di monitoraggio** e **dispositivi azionabili a distanza** (per esempio semafori, barriere a scomparsa, pannelli informativi o altro) che permetteranno di gestire al meglio il flusso di persone verso il luogo dell'evento, anche con l'ausilio di personale in loco. I dispositivi, azionabili a distanza, verranno gestiti attraverso un **server HTTP interno al dispositivo stesso**, accessibile da remoto.

Nell'area circostante l'evento (ad esempio un concerto) sarà presente personale addetto alla validazione degli ingressi all'evento, all'assistenza e al pronto intervento. Per lo svolgimento delle proprie mansioni, il personale in loco sarà dotato di un **dispositivo mobile** con il quale può comunicare con la sede operativa ed essere costantemente aggiornato sullo stato dei dispositivi azionabili a distanza sopra citati.

---

### Richieste

Il candidato analizzi la realtà di riferimento e, formulate le opportune ipotesi aggiuntive, svolga i seguenti punti:

#### 1. Schema generale del sistema

Sviluppi una descrizione di massima, anche supportata da uno **schema grafico** che presenti il sistema (organizzazione della rete informatica della sede operativa, modalità di connessione con le telecamere per il monitoraggio e i dispositivi remoti e loro attivazione e gestione), e ne ponga in evidenza i vari componenti hardware e software necessari, motivando le scelte effettuate.

#### 2. Comunicazione con personale in loco

Descriva in modo dettagliato le possibili modalità di comunicazione tra la sede operativa ed il personale in loco dedicato alla gestione del flusso delle persone partecipanti all'evento, anche in relazione alla validazione dei biglietti di ingresso.

#### 3. Tecnologie di comunicazione con totem

Definisca le tecnologie di comunicazione tra la sede operativa e i punti di informazione (totem) dislocati sull'intera area del comune.

#### 4. Continuità di servizio

Descriva la modalità attraverso le quali sarà possibile evitare interruzioni di servizio.

---

## SECONDA PARTE

### Quesito I - Gestione filmati e immagini

In relazione al tema proposto nella prima parte, si consideri la gestione dei filmati e delle immagini che vengono trasmessi dalle telecamere per il monitoraggio, e si propongano soluzioni per il relativo salvataggio all'interno dell'infrastruttura della sede centrale oppure nel cloud, definendone vantaggi e svantaggi.

---

### Quesito II - Gestione dispositivi remoti HTTP

In relazione al tema proposto nella prima parte, si discuta come possono essere attivati e gestiti i dispositivi remoti dotati di server HTTP interno, utilizzando i metodi propri di questo protocollo, fornendo opportune esemplificazioni.

---

### Quesito III - Tecnologie wireless a corto raggio

Il candidato illustri caratteristiche e possibili campi di applicazione di due tecnologie di comunicazione wireless a corto raggio quali, ad esempio, sistemi basati su RFID, NFC, Bluetooth Low Energy (BLE), IEEE 802.15.4.

---

### Quesito IV - Troubleshooting DNS/Risoluzione nomi

In una rete locale è presente un host con la seguente configurazione:

```
hostname:         pcserverlab
IP address:       192.168.1.15/24
Default Gateway:  192.168.1.1
DNS1:             192.168.1.2
DNS2:             212.14.128.1
```

Effettuando da un altro PC della rete il ping all'IP Address di tale host, con il comando:

```cmd
C:\Users\admin>ping 192.168.1.15
```

si ottiene in risposta:

```
Esecuzione di Ping 192.168.1.15 con 32 byte di dati:
Risposta da 192.168.1.15: byte=32 durata=41ms TTL=56
Risposta da 192.168.1.15: byte=32 durata=32ms TTL=56
Risposta da 192.168.1.15: byte=32 durata=52ms TTL=56
Risposta da 192.168.1.15: byte=32 durata=38ms TTL=56
...
```

mentre effettuando il comando:

```cmd
C:\Users\admin>ping pcserverlab
```

si ottiene in risposta:

```
Impossibile trovare l'host pcserverlab. Verificare che il nome sia corretto e riprovare.
```

Inoltre, effettuando il comando:

```cmd
C:\Users\admin>ping www.istruzione.it
```

si ottiene la risposta:

```
Risposta da 92.123.181.19: byte=32 durata=20ms TTL=49
Risposta da 92.123.181.19: byte=32 durata=26ms TTL=49
Risposta da 92.123.181.19: byte=32 durata=214ms TTL=49
Risposta da 92.123.181.19: byte=32 durata=18ms TTL=49
...
```

Il candidato discuta le possibili cause di tale anomalia; ipotizzando di essere il responsabile dell'infrastruttura di rete, discuta quali passi successivi compirebbe per identificare il problema e porvi rimedio.

---

**Fine del testo d'esame**
