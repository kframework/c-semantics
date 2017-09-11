#include <stdlib.h>

int main(void) {
      char* user = getenv("USER");

      *user = 'x';
}
