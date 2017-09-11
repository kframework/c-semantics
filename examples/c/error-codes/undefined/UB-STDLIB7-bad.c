#include <stdlib.h>

int main(void) {
      char* s = aligned_alloc(8, 15);
      s[2] = 0;
      return s[2];
}
