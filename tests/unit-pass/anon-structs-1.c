#include<stdlib.h>

union outer {
  int ident0;
  struct {
    int ident1;
  };
  struct {
    int ident2;
  };
};

int main() {
  union outer foo;
  foo.ident2 = 42;
  union outer bar;
  bar.ident1 = 7;
  union outer baz;
  baz.ident0 = 3;

  if (foo.ident2 != 42 || bar.ident1 != 7 || baz.ident0 != 3) exit(EXIT_FAILURE);

  return 0;
}

