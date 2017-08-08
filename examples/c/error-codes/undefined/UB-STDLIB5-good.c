#include<stdlib.h>

void foo() {
}

int main() {
  at_quick_exit(foo);
  quick_exit(0);
}
