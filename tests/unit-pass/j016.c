#include <stddef.h>
#include <stdlib.h>

double maximum(int n, int m, double a[n][m]);
double maximum(int n, int m, double a[*][*]);
double maximum(int n, int m, double a[ ][*]);
double maximum(int n, int m, double a[ ][m]) { return 0.0; }

void foo(int x, int (*y)[*]);

void foo(int x, int (*y)[x + 1]) {
      if (sizeof(0 ? NULL : y) != sizeof(y))
            abort();
}

void f(int n, int (*)[n]);
void f(int n, int (*)[n]);

void f(int n, int a[][n]) { }

int main(void) {
      int a[5] = {0};
      int (*b)[5] = &a;
      f(5, b);
      if (sizeof(0 ? (int (*) [5]) NULL : NULL) != sizeof(0 ? (int (*) [5]) NULL : NULL))
            abort();

      if (sizeof(0 ? (void (*) (int (*p)[5])) NULL : (void (*) (int (*p)[*])) NULL) != sizeof(void (*) (int (*p)[5])))
            abort();

      if (sizeof(0 ? (void (*) (int (*p) [*])) NULL : (void (*) (int (*p) [*])) NULL) != sizeof(void (*) (int (*p) [*])))
            abort();

      if (sizeof(0 ? NULL : NULL) != sizeof(NULL))
            abort();

      // The right operand of the conditional is a null pointer constant.
      if (sizeof(0 ? (void*) (1/0) : (char) 0) != sizeof(void*))
            abort();

      // The left operand of the conditional is a null pointer constant.
      if (sizeof (0? (void*)(sizeof(int[1]) - sizeof(int[1])) : main) != sizeof(&main))
            abort();

      // Both operands are null pointer constants.
      if (sizeof(0 ? (char) 0 : (void*) 0) != sizeof(void*))
            abort();

      int u = 5, v = 5;

      if ((0 ? (int (*) [u]) NULL : (int (*) [v]) NULL) != (int (*) [u]) NULL)
            abort();

      int as[5];
      foo(4, &as);

      return 0;
}
