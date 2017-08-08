#include <stdio.h>

fpos_t pos1, pos2, posz;
char tmp1[L_tmpnam], tmp2[L_tmpnam];

int main(void) {
      tmpnam(tmp1);
      tmpnam(tmp2);

      FILE * f1 = fopen(tmp1, "w+");
      fgetpos(f1, &pos1);

      FILE * f2 = fopen(tmp2, "w+");
      fgetpos(f2, &pos2);

      fsetpos(f1, &pos1);
      fsetpos(f2, &pos2);

      fsetpos(f1, &posz); // Undefined.
      fsetpos(f1, &pos2); // Undefined.
      fsetpos(f2, &pos1); // Undefined.

      fclose(f1);
      fclose(f2);

      remove(tmp1);
      remove(tmp2);
}
