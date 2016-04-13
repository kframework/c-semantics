#include<stdlib.h>

int main() {
  char *foo = malloc(12);
  int *bar = (int *)(foo + 8);
  *bar = 5;
  return 0;
}
