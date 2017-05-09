#include <stdio.h>
#include <stdarg.h>

va_list va;
int main(void) {
      vfprintf(stdout, "Nothing\n", va);
}
