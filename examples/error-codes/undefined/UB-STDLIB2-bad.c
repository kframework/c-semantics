#include<stdlib.h>
int main() {
  int x = 0;
  free(&x);
  return 0;
}
