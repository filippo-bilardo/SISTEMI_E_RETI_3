/* 
http://groups.di.unipi.it/~cardillo/labso/files/lez05/sys-02-file.pdf
invert <file>: stampa il file di testo in input invertito.
*/

#include <stdlib.h>
#include <stdio.h>
#include <sys/file.h>

int main(int argc, char *argv[]) {

  int fd;
  char buff;
  const int charSize = sizeof(char);
  
  if(argc != 2) {
    printf("invert: Usage invert <txtFile>\n");
    exit(1);
  }
  
  fd = open(argv[1], O_RDONLY);
  /* Si posiziona alla fine del file + 1*/
  lseek(fd, 1, SEEK_END);
  /* legge il file al contrario: ad ogni passo sposta il puntatore di
  due passi indietro, perche' la lettura lo aggiorna */
  while(lseek(fd, -2*charSize, SEEK_CUR) != -1) {
    read(fd, &buff, charSize);
    printf("%c", buff);
  }
}
