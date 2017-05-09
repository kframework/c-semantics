#include<stddef.h>
void func() {}

int main() {
  void (*foo)() = NULL;
  foo();
  return 0;
}
