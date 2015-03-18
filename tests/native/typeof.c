#include<stddef.h>
struct x {
  int foo;
  int bar;
};

int main() {
  struct x foo = {0, 0};
  int *x = NULL;
  const typeof(foo.foo) * ptr = x;
  const typeof(((struct x *)0)->foo) * ptr = x;
  return 0;
}
