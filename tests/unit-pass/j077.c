#include <stdlib.h>
int f(int a[static 5]) {
      return 0;
}

int main(void) {
      int a[5];
      int *b = malloc(sizeof(int) * 5);
      return f(a) + f(b);
}
