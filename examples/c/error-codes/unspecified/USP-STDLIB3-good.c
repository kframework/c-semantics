#include<stdlib.h>
void foo() {}
void bar() {
  foo();
}

int main() {
  atexit(bar);
}
