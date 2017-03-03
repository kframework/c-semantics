#include <stdio.h>

char buf[32];
char tmp[L_tmpnam];

int main(void) {

      tmpnam(tmp);

      FILE * f = fopen(tmp, "w+");
      fwrite(buf, 1, 32, f);
      rewind(f);
      fread(buf, 1, 1, f);
      fflush(f); // Undefined.
      fclose(f);

      f = fopen(tmp, "r");
      fflush(f); // Undefined.
      fclose(f);

      remove(tmp);
}
