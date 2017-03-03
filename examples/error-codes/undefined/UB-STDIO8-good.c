#include <stdio.h>

char tmp[L_tmpnam];

int main(void) {

      tmpnam(tmp);

      FILE * f = fopen(tmp, "w+");
      fclose(f);
      remove(tmp);

      f = fopen(tmp, "wx");
      fclose(f);
      remove(tmp);

      f = fopen(tmp, "ab+");
      fclose(f);
      remove(tmp);
}
