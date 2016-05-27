// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <stdint.h>
int main() {
  int32_t x;
  uint16_t y;
  x = 0x44332211;
  y = *(uint16_t *)&x; // defined behaviour?
  printf("x=%i  y=0x%x\n",x,y);
}
