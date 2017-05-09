#include<stdlib.h>

void foo() {
  quick_exit(0);
}

int main() {
  at_quick_exit(foo);
  quick_exit(0);
}
