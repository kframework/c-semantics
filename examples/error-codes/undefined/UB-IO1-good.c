#include <stdio.h>
int main(void) {
      FILE * f = tmpfile();
      char buf[32] = {0};

      fwrite(buf, 1, 32, f);
      fwrite(buf, 1, 32, f);
      fflush(f);
      rewind(f);

      fwrite(buf, 1, 32, f);
      fflush(f);
      fread(buf, 1, 1, f);
      rewind(f);
      fwrite(buf, 1, 32, f);
      fwrite(buf, 1, 32, f);
      fflush(f);
      rewind(f);
      fread(buf, 1, 32, f);
      fread(buf, 1, 32, f);
      fwrite(buf, 1, 32, f);

      rewind(f);
      fflush(f);

      fclose(f);
}
