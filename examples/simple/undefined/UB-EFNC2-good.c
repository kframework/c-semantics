#include<stddef.h>
void func() {}

int main() {
  void (*foo)() = func;
  foo();
  return 0;
}
