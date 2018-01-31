#include <stdint.h>

int main() {
      int x = 0;
      x = ((uintptr_t) x) % 8;
      return 0;
}
