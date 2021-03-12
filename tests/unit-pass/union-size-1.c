#include <stdint.h>
#include <stdlib.h>

union A {
  uint16_t a;
  union B {
    uint32_t b;
  };
};

int main() {
  if(sizeof(union A) != 2)
      abort();
  return 0;
}
