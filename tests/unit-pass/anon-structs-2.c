#include <stdlib.h>
struct outer {
  int bar;
  union {
    struct {
      int ident0;
    };
  };
};

int main() {
  struct outer foo;
  foo.ident0 = 3;
  if (foo.ident0 != 3) exit(EXIT_FAILURE);
  return 0;
}

