#include <stdarg.h>

int f(int x, int y) {
      va_list ap = NULL, ap2 = NULL;
      va_copy(ap2, ap);
      return 0;
}
int main(void) {
      return f(5, 6);
}
