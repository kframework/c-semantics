#include<stdlib.h>

int main() {
  char *foo = malloc(10);
  int *bar = (int *)(foo + 8);
  *bar = 5;
  return 0;
}
