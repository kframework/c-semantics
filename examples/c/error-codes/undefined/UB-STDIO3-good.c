#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

int vasprintf(char ** restrict, const char * restrict, va_list);

void f(int x, ...) {
      va_list va;
      va_start(va, x);
      vprintf("The number 5: %d\n", va);
      va_end(va);

      char s[100];

      va_start(va, x);
      vsprintf(s, "The number 5: %d\n", va);
      va_end(va);

      printf("%s", s);

      va_start(va, x);
      vsnprintf(s, 100, "The number 5: %d\n", va);
      va_end(va);

      printf("%s", s);

      va_start(va, x);
      vfprintf(stdout, "The number 5: %d\n", va);
      va_end(va);

      char * s2;

      va_start(va, x);
      vasprintf(&s2, "The number 5: %d\n", va);
      va_end(va);

      printf("%s", s2);

      free(s2);
}

int main(void) {
      f(0, 5);
}
