#include<stddef.h>
#include<stdint.h>
int main() {
  volatile int x = 15;
  int y = ((size_t)&x & (sizeof(x) - 1));
  intptr_t z = ((intptr_t)&x & -4l);
  int w = (int *)z - &x;
  return y + w;
}
