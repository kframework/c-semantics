#include <stdint.h>
#include <stdlib.h>

struct A {
  uint16_t a;
  union B {
    uint16_t b;
  };
  union B c;
};

int main() {
  if(sizeof(struct A) != 4)
      abort();
  return 0;
}
