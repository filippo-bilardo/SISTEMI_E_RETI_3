# AB42 - ESAME DI STATO (Sessione ordinaria 2019)
## Seconda prova scritta

> Trascrizione da PDF in formato Markdown (estrazione testo tramite PyPDF2).

---

## Pagina 1

Pag.  1/3 Sessione ordinaria 201 9
Seconda prova scritta

Ministero dell’Istruzione, dell’ Università e della Ricerca

ESAME DI STATO DI ISTRUZIONE SECONDARIA SUPERIORE

Indirizzo:  ITIA - INFORMATICA E TELECOMUNICAZIONI
ARTICOLAZIONE INFORMATICA
Tema di: INFORMATICA e  SISTEMI E RETI
Il candidato svolga la prima parte della prova e due tra i quesiti proposti nella seconda parte.
PRIMA PARTE
Per favorire il turismo culturale, l’Assessorato al Turismo di una città d’arte di medie dimensioni intende
realizzare un’infrastruttura tecnologica che offra ai visitatori un servizio per la fruizione di contenuti
multimediali che descrivono i “punti di i nteresse” (Point Of Interest = POI) di tipo monumentale
(es. chiese, luoghi storici, …) e artistico ( es. musei, mostre, …) distribuiti nel centro storico della città.
Per il servizio, si è deciso di erogare i contenuti multimediali sotto forma di pagine web, secondo due
possibili formati denominati “pagina multimediale di base” e “pagina multimediale avanzata”.
Nella pagina multimediale di base sono previsti:
- un video di presentazione breve del POI della durata tipica di un minuto esclusivamente in italiano con sottotitoli in inglese;
- un massimo di tre immagini relative al POI (es. dettagli architettonici, quadri, ...) con relativa didascalia in italiano ed inglese.
Nella pagina multimediale avanzata sono previsti:
- un video di presentazione approfondita del POI della durata tipica di cinque minuti in una fra 7 possibili lingue compreso l’italiano;
- una galleria di una ventina di immagini con relativa descrizione (tipicamente intorno ai 500 caratteri) in una fra 7 possibili lingue compreso l’italiano.

Il vis itatore, acquistando il servizio in uno dei chioschi (InfoPoint) dislocati nella città, riceverà un biglietto
con cui potrà avere accesso ai due tipi di pagina sulla base di tre possibili tariffe:
- “tariffa base”: permette la fruizione di una pagina mult imediale di base per ciascun POI;
- “tariffa intermedia”: consente la fruizione di pagine multimediali avanzate per tre POI a scelta
dell’utente e pagine di base per gli altri;
- “tariffa piena”: consente la fruizione di pagine multimediali avanzate per o gni POI della città.

Il biglietto acquistato riporta la password di accesso ai contenuti, univoca per ciascun visitatore, associata al
tipo di tariffa pagata e con validità giornaliera.


---

## Pagina 2

Pag.  2/3 Sessione ordinaria 201 9
Seconda prova scritta

Ministero dell’Istruzione, dell’ Università e della Ricerca

ESAME DI STATO DI ISTRUZIONE SECONDARIA SUPERIORE

Indirizzo:  ITIA - INFORMATICA E TELECOMUNICAZIONI
ARTICOLAZIONE INFORMATICA
Tema di: INFORMATICA e  SISTEMI E RETI

In relazione alle funzionalità che il servizio dovrà offrire, l’Assessorato richiede che siano soddisfatti i
seguenti vincoli progettuali:
- la consultazione delle pagine multimediali sia abilitata esclusivamente ai dispositivi (minitablet) forniti all’atto dell’acquisto del biglietto, previa consegna di un documento di identità o di un numero di carta di credito valida;
- per facilitare l’aggiornamento periodico dei contenuti esistenti e l’inserimento di nuovi, gli stessi non siano memorizzati sui dispositivi utilizzati dagli utenti ma su sistemi server;
- l’accesso alle pagine multimediali sia effettuabile solo dopo l’inserimento, all’inizio della visita, della password presente nel biglietto;
- l’accesso alle pagine multimediali relative ad un POI debba avvenire solo in prossimità o all’interno del POI stesso;
- la restituzione dei dispositivi (minitablet) possa avvenire presso l’InfoPoint che ha in custodia il documento di identità oppure presso un qualsiasi InfoPoint se il visitatore ha optato per lasciare il numero di carta di credito valida.

Il candidato analizzi la realtà di riferimento e, fatte le opportune ipotesi aggiuntive, indivi dui una soluzione
che a suo motivato giudizio sia la più idonea a sviluppare i seguenti punti:
1. il progetto, anche mediante rappresentazioni grafiche, dell’infrastruttura tecnologica ed informatica
necessaria a gestire il servizio nel suo complesso, dettagliando:
a) l’architettura della rete e le caratteristiche del o dei sistemi server, motivando anche la scelta
dei luoghi in cui installare questi ultimi;
b) le modalità di comunicazione tra server e dispositivi consegnati ai visitatori, descrivendo
protoco lli e servizi software da implementare per gestire la rete e fornire le pagine;
c) gli elementi dell’infrastruttura utili a limitare la fruizione delle pagine multimediali
esclusivamente in prossimità o all’interno dei POI a cui si riferiscono;
2. il progetto de lla base di dati per la gestione del servizio sopra descritto: in particolare si richiedono il
modello concettuale ed il corrispondente modello logico;
3. la progettazione delle pagine web che consentono all’utente, in possesso di biglietto con tariffa base,
la fruizione dei contenuti multimediali relativi al POI presso cui si trova,  codificandone una porzione
significativa in un linguaggio a scelta;
4. l’analisi di massima delle possibili modalità di gestione delle tre fasce tariffarie, delle opzioni offerte
all’utente per  la scelta dei tre POI nel caso della tariffa intermedia, e della scelta della lingua nel caso
delle tariffe intermedia e piena.


---

## Pagina 3

Pag.  3/3 Sessione ordinaria 201 9
Seconda prova scritta

Ministero dell’Istruzione, dell’ Università e della Ricerca

ESAME DI STATO DI ISTRUZIONE SECONDARIA SUPERIORE

Indirizzo:  ITIA - INFORMATICA E TELECOMUNICAZIONI
ARTICOLAZIONE INFORMATICA
Tema di: INFORMATICA e  SISTEMI E RETI
SECONDA PARTE
Il candidato risponda a due quesiti a scelta tra quelli sotto riportati.

I. In relazione al tema proposto nella prima parte, si vuole offrire ai visitatori la possibilità di inserire
via web un commento ed un voto di gradimento su ogni POI visitato. Effettuata a tale scopo una
opportuna integrazione della base di dati, si realizzi, codificandola in un linguaggio a scelta, una
pagina web che consent e la visualizzazione della me dia dei voti ricevuti da ciascun POI.
II. In relazione al tema proposto nella prima parte, si discuta la possibilità di allargare la fruizione dei
contenuti multimediali anche ai dispositivi personali degli utenti. In particolare, si analizzino le
seguenti due  ipotesi alternative:
- uso limitato ai soli dispositivi (minitablet) forniti all’atto dell’acquisto del biglietto, come sopra descritto: si individuino possibili soluzioni per impedire l’accesso alle pagine multimediali attraverso dispositivi non forniti dagli InfoPoint;
- uso consentito ai dispositivi personali degli utenti (es. smartphone): si descriva una possibile integrazione del servizio volta a consentire la fruizione dei contenuti direttamente ad un singolo dispositivo di proprietà del visitatore, pur mantenendo i vincoli di fruibilità in base alla tariffa associata al biglietto.
III. Nella realizzazione e gestione di una base di dati accessibile da categorie di utenti con differenti
ruoli, sono di rilevante importanza gli aspetti relativi alla sicurezza d ei dati. Ad esempio , si supponga
che nella realtà scolastica il personale della “Segreteria Alunni” non debba accedere ai dati del
personale docente, il personale della “Segreteria Docenti” non debba accedere all’elenco dei fornitori
della scuola, ecc. Il candidato approfondisca la tematica proposta discutendo gli strumenti offerti dai
sistemi DBMS per creare utenze che abbiano un accesso libero alla totalità dei dati o limitato a parte
di essi, in termini di operazioni consentite, in base al ruolo ricopert o nell’organizzazione. Produca
quindi esempi significativi, nel contesto proposto della segreteria scolastica, nel linguaggio fornito
dal DBMS di sua conoscenza.
IV. Per le aziende che dispongono di sedi dislocate in varie località sorge spesso la necessità di
consentire al personale l’accesso ai sistemi da postazioni remote. Il candidato discuta le tipologie e i
protocolli di accesso remoto ai sistemi, indicando in particolare le possibilità offerte dalle
connessioni VPN. Sviluppi poi esempi nel caso di una az ienda che ha due sedi operative e agenti
commerciali che, muovendosi sul territorio, hanno necessità di collegarsi al sistema informativo
aziendale.
__________________
Durata massima della prova: 6 ore.
È consentito soltanto l’uso dei manuali dei linguagg i di programmazione (language reference) e  di calcolatrici scientifiche e/o
grafiche purché non siano dotate di capacità di calcolo simbolico (O.M. n. 205 Art. 17 comma 9).
È consentito l’uso del dizionario bilingue (italiano -lingua del paese di provenienz a) per i candidati di madrelingua non italiana.
Non è consentito lasciare l’Istituto prima che siano trascorse 3 ore dall’inizio della prova.
