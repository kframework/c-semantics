#include<stdlib.h>

struct outer {
  int ident0;
  struct {
    int ident1;
  };
  struct {
    int ident2;
  };
};

int main() {
  struct outer foo;
  foo.ident2 = 42;
  foo.ident1 = 7;
  foo.ident0 = 3;

  if (foo.ident2 != 42 || foo.ident1 != 7 || foo.ident0 != 3) exit(EXIT_FAILURE);

  return 0;
}

