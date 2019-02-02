#include <stdlib.h>

int main(void) {
      char * nothing = getenv("NOT_IN_ENV_456");
      if (nothing) abort();


      char * user = getenv("PATH");
      *user = 'x';
}
