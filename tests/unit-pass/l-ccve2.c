#include <stdio.h>

int main(int argc, char** argv) {
  unsigned short i = (unsigned short)~0u;
  unsigned short j = ~0u;
  return !(i != 0 && j != 0);
}
