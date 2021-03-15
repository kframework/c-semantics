#include <stdint.h>
#include <stdlib.h>

struct A {
  uint16_t a;
  union B {
    uint16_t b;
  };
};

int main() {
  if(sizeof(struct A) != 2)
      abort();
  return 0;
}
