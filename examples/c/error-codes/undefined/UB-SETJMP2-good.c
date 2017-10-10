#include <setjmp.h>

jmp_buf b;

int main(void) {
      int r = 0;
      r = setjmp(b);
      if (!r) longjmp(b, 1);
}
