#include <stdio.h>
struct s { int i; };

int f(void) {
      static int x = 0;

      ++x;

      struct s* a = &((struct s) { x });

      if (x < 2) {
            f();
      }
      return a->i;
}

int main(void) {
      return f() != 1;
}
