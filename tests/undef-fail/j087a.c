#include <stdarg.h>

int f(int x, int y) {
      va_list ap;
      va_start(ap, y);
      int z = va_arg(ap, int);
      va_end(ap);
      return z;
}
int main(void) {
      return f(5, 6);
}
