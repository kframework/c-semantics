#include<stdarg.h>

void foo(char x, int y, ...) {
  va_list ap;
  va_start(ap, y);
  va_end(ap);
}

int main() {
  foo(1, 0, 2);
}
