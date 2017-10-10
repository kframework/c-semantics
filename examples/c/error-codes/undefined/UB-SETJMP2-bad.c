#include <setjmp.h>

jmp_buf b;

int f(void) {
      return setjmp(b);
}

int main(void) {
      int r = 0;
      r = f();
      if (!r) longjmp(b, 1);
}
