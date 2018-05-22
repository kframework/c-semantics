#include <stdint.h>

union U {
   uint32_t  a;
   uint8_t  b;
};

union U u;

int main() {
      u.b = 1;

      --u.a;

      int tab[] = {0, 1, 2};

      return tab[u.b];
}
