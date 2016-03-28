#include<stdlib.h>

void bar() {}

void foo() {
  atexit(bar);
}

int main() {
  atexit(foo);
  exit(0);
}
