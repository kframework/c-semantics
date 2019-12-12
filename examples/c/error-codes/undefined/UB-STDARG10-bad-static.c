#include<stdarg.h>

void foo(register int x, ...) {
  va_list ap;
  va_start(ap, x);
  va_end(ap);
}

int main() {
  
  foo(1, 2);
}
