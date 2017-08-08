#include <stdio.h>

char buf[32];
char tmp[L_tmpnam];

int main(void) {
      tmpnam(tmp);

      FILE * f = fopen(tmp, "w+");

      fwrite(buf, 1, 32, f);
      fflush(f);
      fclose(f);

      f = fopen(tmp, "r+");
      fflush(f);
      fclose(f);

      remove(tmp);
}
