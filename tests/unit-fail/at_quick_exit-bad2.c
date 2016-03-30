#include<stdlib.h>

void foo(void) {
  quick_exit(0);
}

int main() {
  atexit(foo);
  exit(0);
}
