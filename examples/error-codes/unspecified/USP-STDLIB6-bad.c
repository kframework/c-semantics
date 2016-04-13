#include<stdlib.h>
void foo() {}
void bar() {
  at_quick_exit(foo);
}

int main() {
  at_quick_exit(bar);
  quick_exit(0);
}
