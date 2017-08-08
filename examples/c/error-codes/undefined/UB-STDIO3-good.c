#include <stdio.h>
#include <stdarg.h>

void f(int x, ...) {
      va_list va;
      va_start(va, x);
      vprintf("The number 5: %d\n", va);
      va_end(va);
}

int main(void) {
      f(0, 5);
}
