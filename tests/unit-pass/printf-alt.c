#include<stdio.h>

int main() {
  printf("%#o\n", 0U);
  printf("%#.0o\n", 0U);
  printf("%#.2o\n", 10U);
  printf("%#.2o\n", 1U);
  printf("%#.2o\n", 100U);
  printf("%#.0x\n", 0U);
  printf("%#.2x\n", 0x10U);
  printf("%#.2x\n", 0x1U);
  printf("%#.2x\n", 0x100U);
  printf("%#x\n", 0U);
  printf("%#X\n", 0U);
  printf("%#x\n", 123U);
  printf("%#X\n", 123U);
  printf("%#8x\n", 123U);
  printf("%#08x\n", 123U);
  printf("%#12.8x\n", 123U);
}
