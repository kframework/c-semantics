#include <stdio.h>
#include <stdarg.h>

va_list va;
int main(void) {
      char s[100];
      vsnprintf(s, 100, "Nothing\n", va);

      printf("%s", s);
}
