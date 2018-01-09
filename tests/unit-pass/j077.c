#include <stdlib.h>
int f1(int a[static 5]) {
      a[4] = 1;
      return a[4];
}

int f2(int a[static restrict 5]) {
      a[3] = -1;
      return a[3];
}

int f3(int a[restrict const static 5]) {
      return a[2];
}

int f4(int a[restrict const 5]) {
      return a[1];
}

int main(void) {
      int a[5] = {0};
      int *b = calloc(5, sizeof(int));

      int a1 = f1(a);
      int b1 = f1(b);
      int a2 = f2(a);
      int b2 = f2(b);
      int a3 = f3(a);
      int b3 = f3(b);
      int a4 = f4(a);
      int b4 = f4(b);

      return a1 + b1 + a2 + b2 + a3 + b3 + a4 + b4;
}
