#include <stdarg.h>

int f(int x, int y, ...) {
      va_list ap, ap2;
      va_start(ap, y);
      va_copy(ap2, ap);
      int z = va_arg(ap, int);
      va_end(ap);
      return z;
}
int main(void) {
      return f(5, 6, 0);
}
