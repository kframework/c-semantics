#include<stdlib.h>
int *x;
int main() {
  x = malloc(4);
  *x = 5;
  free(x);
  *x;
  return 0;
}
