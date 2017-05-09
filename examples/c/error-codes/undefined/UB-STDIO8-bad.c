#include <stdio.h>

char tmp[L_tmpnam];

int main(void) {

      tmpnam(tmp);

      FILE * f = fopen(tmp, "+w"); // Undefined.
      fclose(f);

      f = fopen(tmp, "x"); // Undefined.
      fclose(f);

      f = fopen(tmp, "abc"); // Undefined.
      fclose(f);
}
