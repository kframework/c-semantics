#include <stddef.h>

void foo(int x, int (*y)[*]);

void foo(int x, int (*y)[x + 1]) {
      sizeof(0 ? NULL : y);
      sizeof(0 ? y : (int (*) [5]) NULL);
}

void f(int n, int (*)[n]);
void f(int n, int (*)[n]);

void f(int n, int (*a)[n]) { }

int main(void) {
      int a[5] = {0};
      int (*b)[5] = &a;
      f(5, b);
      sizeof(0 ? (int (*) [5]) NULL : NULL);

      int x = 5;
      sizeof(0 ? (int (*) [5]) NULL : (int (*) [x]) NULL);

      sizeof(0 ? (void (*) (int (*p)[5])) NULL : (void (*) (int (*p)[*])) NULL);

      sizeof(0 ? (void (*) (int (*p)[*])) NULL : (void (*) (int (*p) [*])) NULL);

      sizeof(0 ? NULL : NULL);

      sizeof(0 ? 0 : NULL);

      return 0;
}
