#include<stdlib.h>

int FOO = 5;

void bar() {
  if (FOO != 5) abort();
}

int main() {
  enum {
    FOO
  };
  if (FOO != 0) abort();
  bar();
  return 0;
}
