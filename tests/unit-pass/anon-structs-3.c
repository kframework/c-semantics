#include<stdlib.h>

union outer {
  struct {
    int ident1;
    struct {
      int ident2;
      struct {
        int ident3;
      };
    };
  };
};

int main() {
  union outer bar;
  bar.ident3 = 42;
  if (bar.ident3 != 42) exit(EXIT_FAILURE);
  return 0;
}

