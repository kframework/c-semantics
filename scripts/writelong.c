#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

int main(int argc, char ** argv) {
      if (argc != 2) exit(EXIT_FAILURE);

      long long ll = atoll(argv[1]);
      int64_t i64 = (int64_t)ll;
      fwrite(&i64, sizeof(i64), 1, stdout);

      exit(EXIT_SUCCESS);
}
