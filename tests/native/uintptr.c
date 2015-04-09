#include<assert.h>
#include<stdint.h>
#include<stdlib.h>

int main() {
  int *x = malloc(4);
  *x = 5;
  void *y = (void *)x;
  uintptr_t ptr = (uintptr_t) y;
  void *z = (void *)ptr;
  int *w = (int *)z;
  assert(*w == 5);
  return 0;
}
