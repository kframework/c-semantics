#include <stdio.h>
#include <stdarg.h>

void f(int x, ...) {
      va_list va;
      char s[100];
      va_start(va, x);
      vsprintf(s, "The number 5: %d\n", va);
      va_end(va);

      printf("%s", s);
}

int main(void) {
      f(0, 5);
}
