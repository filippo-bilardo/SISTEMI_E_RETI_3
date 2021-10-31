/* 
http://groups.di.unipi.it/~cardillo/labso/files/lez05/sys-02-file.pdf
mycopy src trg: crea una copia del file src e la chiama trg 
*/

#include <stdlib.h>
#include <stdio.h>
#include <sys/file.h>

#define BUFFSIZE 8192

int main(int argc, char *argv[]) {
  int fdSource; /* file descriptor per il file origine */
  int fdTarget; /* file descriptor per il file copia*/
  int n;
  char buf[BUFFSIZE]; /* buffer di transizione */

  fdSource = open(argv[1], O_RDONLY);
  fdTarget = open(argv[2], O_WRONLY | O_CREAT, 0600);

  /* copia il file sorgente sul target a blocchi di BUFFSIZE byte */
  while( (n = read(fdSource, buf, BUFFSIZE)) > 0) {
    if(write(fdTarget, buf, n) != n) {
      perror("write error");
      exit(1);
    }
  }
}

