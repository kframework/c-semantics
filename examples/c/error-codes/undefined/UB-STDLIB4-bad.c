#include<stdlib.h>

void foo() {
  exit(0);
}

int main() {
  atexit(foo);
}
