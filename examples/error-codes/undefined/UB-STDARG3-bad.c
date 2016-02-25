#include <stdarg.h>

va_list ap;

int f(int x, int y, ...) {
      va_list ap2;
      int z = va_arg(ap, int);
      return z;
}
int main(void) {
      return f(5, 6, 0);
}
