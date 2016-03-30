#include<stdlib.h>

void bar() {}

void foo() {
  at_quick_exit(bar);
}

int main() {
  at_quick_exit(foo);
  quick_exit(0);
}
