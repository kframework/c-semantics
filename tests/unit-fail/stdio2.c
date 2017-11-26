#include <stdio.h>

int main(void) {
      FILE* f = fopen("stdio2.c", "r");
      char buf[100];
      setvbuf(f, buf, _IOFBF, 100);
      buf[2];
      fclose(f);
}
