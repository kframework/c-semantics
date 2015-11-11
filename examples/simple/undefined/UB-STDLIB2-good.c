#include<stdlib.h>
int main() {
  int *x = malloc(4);
  *x = 0;
  free(x);
  return 0;
}
