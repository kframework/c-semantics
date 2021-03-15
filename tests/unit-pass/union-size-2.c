#include <stdint.h>
#include <stdlib.h>

union A {
  uint16_t a;
  union B {
    uint32_t b;
  };
  union B c;
};

int main() {
  if(sizeof(union A) != 4)
      abort();
  return 0;
}
