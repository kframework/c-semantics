#include <stdlib.h>
int f(int a[static 5]) {
      return 0;
}

int main(void) {
      int *a = malloc(sizeof(int) * 2);
      return f(a);
}
