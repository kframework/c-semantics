// Courtesy of Robby Findler.
#include <stdio.h>

unsigned long f() {
  double d = -0.5;
  return d * (1 << 30);
}

int main() {
  printf("0x%lx\n",f());
}
