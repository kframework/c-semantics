#include<stdlib.h>

int main() {
  int *foo = malloc(12);
  int *bar = foo + 2;
  *bar = 5;
  return 0;
}
