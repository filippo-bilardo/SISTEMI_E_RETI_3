//==========================================================================================
// Project:  TCPServer_ServerMinimo.c
// Date:     28/03/22
// Author:   Filippo Bilardo
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//
//  Esempio di utilizzo dei Socket Server. Creazione di un server che ascolta le
//  connessioni entranti sulla porta 8888. 
//  Ricevuta la richiesta di connessione accetta la connessione e visualizza a schermo
//  i dati inviati dal client (per semplicità utilizziamo un browser come client)
//
// Ver   Date       Comment
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// 1.0   24/03/20   Versione iniziale (da codice del 23/11/16)
// 1.1   10/04/20   Suddivisione codice in routine e gestione del segnale SIGINT
// 1.2   28/03/22   
//==========================================================================================
//------------------------------------------------------------------------------------------
//=== Includes =============================================================================
//------------------------------------------------------------------------------------------
#include <arpa/inet.h>     // inet_aton, sockaddr_in
#include <signal.h>        // signal, costanti
#include <stdlib.h>        // exit
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>    // sockaddr_in
#include <netdb.h>         // gethostbyname
#include <fcntl.h>
#include <arpa/inet.h>     // inet_addr
#include <unistd.h>        // read, write, close
#include <stdlib.h>        // exit
#include <stdio.h>         // printf
#include <string.h>        // strlen
#include <errno.h>         // errno

//------------------------------------------------------------------------------------------
//=== Constants ============================================================================
//------------------------------------------------------------------------------------------
#define MAXPENDING 4     // Numero di connessioni contemporanee consentite
#define ERR_SIGINT 1     // Codice di errore per la chiusura del programma anticipata CTRL-C

//------------------------------------------------------------------------------------------
//=== Local variables ======================================================================
//------------------------------------------------------------------------------------------
int listenSockId;

//------------------------------------------------------------------------------------------
//=== Function prototypes ==================================================================
//------------------------------------------------------------------------------------------
void handler_signal(int signum);
int TCPServer_CreaSocket(short Porta);
int TCPServer_RiceviInvia(int sockId);
int ChiudiSocket(int sockId);
int TCPServer_ServerMinimo();

//------------------------------------------------------------------------------------------
//=== Local function prototypes ============================================================
//------------------------------------------------------------------------------------------
void handler_signal(int signum) {

  if (signum == SIGINT) {
    printf("\n[handler] Ricevuto il segnale SIGINT (CTRL-C)\n"); 
    printf("[handler] Chiusura del socket server id=%d\n",listenSockId); 
    ChiudiSocket(listenSockId);  //Chiudo il socket.
    exit(ERR_SIGINT);  //Termino il programma con il codice di errore ERR_SIGINT 
  }
}
//------------------------------------------------------------------------------------------
int TCPServer_CreaSocket(short Porta) {

  int sockId, status;

  //1. Creazione socket
  sockId=socket(AF_INET, SOCK_STREAM, 0);
  if(sockId<0) {perror("Errore nell'apertura del socket"); return sockId;}

  //2. Bind del socket
  //Tipo di indirizzo per il server
  struct sockaddr_in servaddr;
  // Filling server information
  //memset(&servaddr, 0, sizeof(servaddr)); //Azzera l'intera struttura dati
  servaddr.sin_family = AF_INET; // IPv4
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port = htons(Porta);
  memset(servaddr.sin_zero, 0, 8); //Imposta a zero 8 char di .sin_zero
  status=bind(sockId, (struct sockaddr*)&servaddr, sizeof(servaddr));
  if(status<0) {perror("Errore nel bind del socket"); return status;}
  //alternativa:
  //struct hostent *host;
  //host=gethostbyname(SrvName);
  //memcpy(&servaddr.sin_addr, host->h_addr_list[0], host->h_length);
  /*
  //Il socket deve essere non bloccante
  status=fcntl(sockId, F_SETFL, O_NONBLOCK);
  //Configurazione del socket.
  //SO_REUSEADDR->previene l'errore "Address already in use"
  int opt_on = 1;
  status=setsockopt(sockId, SOL_SOCKET, SO_REUSEADDR, &opt_on, sizeof(opt_on));
  */

  //3. - facciamo accettare fino a MAXPENDING richieste di servizio
  //contemporanee (che finiranno nella coda delle connessioni).
  status=listen(sockId, MAXPENDING);
  if(status<0) {perror("Errore nella chiamata della funzione listen"); return status;}

  return sockId;
}

//------------------------------------------------------------------------------------------
int TCPServer_RiceviInvia(int sockId) {

  int readByte, status;
  char buffer[1024];

  //5. Lettura dei dati dal socket (messaggio ricevuto)
  readByte=read(sockId, buffer, sizeof(buffer)-1);
  if(readByte<=0) {perror("Errore nella lettura dei dati"); return readByte;}
  buffer[readByte]='\0';  //Aggiusto la lunghezza...
  //Stampiamo i dati ricevuti dal client
  printf("---------------------------------------------\n");
  printf("Richiesta ricevuta dal client:\n%s\n", buffer);
  printf("---------------------------------------------\n");

  //6. Invio risposta al client
  //Invio risposta al client
  /*
  char answer[1024];
  strcpy(answer,"HTTP/1.1 200 OK\r\n");
  strcat(answer,"Connection: close\r\n");
  strcat(answer,"Content-Type: text/plain\r\n");
  strcat(answer,"\r\n");
  strcat(answer,"<h1>Ciao 5L</h1>");
  write(sockId, answer, strlen(answer)); */

  char answer[1024];
  strcpy(answer,"Saluti dal server TCP.\r\n");
  strcat(answer,"Ritornate presto!\r\n");
  status=write(sockId, answer, strlen(answer));
  if(status<0) {perror("Errore nell'invio dei dati"); return status;}
  //Stampiamo i dati inviati al client
  printf("---------------------------------------------\n");
  printf("Invio risposta al client:\n%s\n",answer);
  printf("---------------------------------------------\n");

  return 0;
}

//------------------------------------------------------------------------------------------
int ChiudiSocket(int sockId) {

  int status = close(sockId);
  if(status<0) perror("Errore nella chiusura del socket");
  return status;
}
//------------------------------------------------------------------------------------------
int TCPServer_ServerMinimo() {

  int newSockId;
  struct sockaddr_in cliAddr;
  socklen_t cliAddrLen = sizeof(cliAddr);

  //Ports 0-1023 system or well-known ports > BISOGNA essere root per lanciare il processo
  //Ports 1024-49151 user or registered ports > non servere essere root per lanciare il processo
  //Ports 49152-65535 dynamic/private/ephemeral ports
  //Creo il socket sul server che ascolta sulla porta ...
  listenSockId=TCPServer_CreaSocket(8888);

  printf("---------------------------------------------\n");
  printf("Server: Attendo connessioni..(premere CTRL-C per chiudere il server)\n");
  printf("---------------------------------------------\n");
  for(;;)
  {
    //Aspetta la richiesta dal client
    //il ciclo while serve per gestire in sequenza altre richieste
    if ((newSockId=accept(listenSockId,(struct sockaddr *)&cliAddr,&cliAddrLen)) != -1)
    {
      //TODO: se vogliamo gestire piu' comunicazioni client contemporanee dobbiamo
      // avviare un nuovo processo o thread per gestire le connessione
      printf("Connession con il client: %s:%d\n",inet_ntoa(cliAddr.sin_addr), ntohs(cliAddr.sin_port));
      TCPServer_RiceviInvia(newSockId);
      printf("Chiusura della connessione con il client\n\n");
      ChiudiSocket(newSockId);
    }
  }
}
//------------------------------------------------------------------------------------------
//=== Main =================================================================================
//------------------------------------------------------------------------------------------
int main(int argc,char* argv[]) {

  signal(SIGINT, handler_signal);     // Interrupt (ANSI)
  TCPServer_ServerMinimo();
  return 0;
}
