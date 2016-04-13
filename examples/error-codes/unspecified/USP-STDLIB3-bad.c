#include<stdlib.h>
void foo() {}
void bar() {
  atexit(foo);
}

int main() {
  atexit(bar);
}
