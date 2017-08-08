#include <stdio.h>
#include <stdarg.h>

va_list va;
int main(void) {
      char s[100];
      vsprintf(s, "Nothing\n", va);

      printf("%s", s);
}
