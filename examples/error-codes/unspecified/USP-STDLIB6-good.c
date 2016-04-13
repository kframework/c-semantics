#include<stdlib.h>
void foo() {}
void bar() {
  foo();
}

int main() {
  at_quick_exit(bar);
  quick_exit(0);
}
