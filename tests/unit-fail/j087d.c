#include <stdarg.h>

int f(int x, int y) {
      va_list ap;
      va_end(ap);
      return 0;
}
int main(void) {
      return f(5, 6);
}
