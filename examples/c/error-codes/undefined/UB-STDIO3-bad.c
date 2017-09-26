#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>

int vasprintf(char ** restrict, const char * restrict, va_list);

va_list va;
int main(void) {
      vprintf("Nothing\n", va);

      char s[100];

      vsprintf(s, "Nothing\n", va);

      printf("%s", s);

      vsnprintf(s, 100, "Nothing\n", va);

      printf("%s", s);

      vfprintf(stdout, "Nothing\n", va);

      char * s2;
      vasprintf(&s2, "Nothing\n", va);

      printf("%s", s2);

      free(s2);
}
