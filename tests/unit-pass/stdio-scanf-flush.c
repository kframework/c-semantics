#include <stdio.h>
#include <stdlib.h>

int main(void) {
  int val;

  FILE *fp = fopen("/dev/null", "r");
  printf("Hello world");

  setvbuf(fp, NULL, _IOLBF, 0);

  fscanf(fp, "%d", &val);

  return 0;
}
