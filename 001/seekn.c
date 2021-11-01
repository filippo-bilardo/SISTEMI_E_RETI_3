/* File: seekn.c
Specifica: seek file n start - scrive sullo stdout (al piu’) gli
n bytes di file dopo i primi start bytes. Se start e’
negativo, legge a partire dalla fine del file.
http://groups.di.unipi.it/~cardillo/labso/files/docs/dispensa.pdf
*/

/* include per chiamate sui file */
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>  /* serve per la perror */
#include <stdlib.h> /* serve per la exit   */
#include <string.h> /* serve per strlen    */
#include <errno.h>  /* serve per errno     */
#include <unistd.h> /* serve per la write  */


/* macro di utilita’ */
#define IFERROR(s,m) if((s)==-1) {perror(m); exit(errno);}
#define IFERROR3(s,m,c) if((s)==-1) {perror(m); c;}
#define WRITE(m) IFERROR(write(STDOUT,m,strlen(m)), m);
#define WRITELN(m) WRITE(m);WRITE("\n");
#define STDIN  0
#define STDOUT 1
#define STDERR 2

int main(int argc, char *argv[])
{
  int fd, start, n, letti;
  char *buffer;
  
  /* controlla argomenti */
  if( argc != 4){
    WRITELN("Usage: seekn filename n start");
    exit(0);
  }
  n = atoi(argv[2]);
  start = atoi(argv[3]);
  if( n <= 0 ) {
    WRITELN("n must be positive");
    exit(1);
  }
  
  /* apertura del file */
  IFERROR(fd = open(argv[1],O_RDONLY), argv[1]);
  
  /* posizionamento */
  if( start >= 0 ) {
    IFERROR(lseek(fd,start,SEEK_SET),argv[1]);
  } else {
    IFERROR(lseek(fd,start,SEEK_END),argv[1]);
  }
  
  /* alloca memoria */
  if( (buffer = (char*) malloc( n )) == NULL ) {
    WRITELN("No more memory");
    exit(-1);
  }
  
  /* lettura */
  IFERROR(letti = read(fd,buffer,n),argv[1]);
 
  /* stampa in output */
  IFERROR(write(STDOUT,buffer,letti),"stdout");
 
  /* chiusura file */
  IFERROR(close(fd),argv[1]);
  
  return(0);
}
