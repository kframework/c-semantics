#include <string.h>

int main() {
      int x = 1;
      float y = 1;
      double z = 1;
      int * p = &x;
      return memcmp(&x, &x, sizeof(x))
          || memcmp(&y, &y, sizeof(y))
          || memcmp(&z, &z, sizeof(z))
          || memcmp(&p, &p, sizeof(z));
}
