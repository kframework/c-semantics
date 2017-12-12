#include <stdio.h>

char tmp[L_tmpnam];

int main(void) {
      FILE * f;

      tmpnam(tmp);
      f = fopen(tmp, "w+");
      fclose(f);
}
