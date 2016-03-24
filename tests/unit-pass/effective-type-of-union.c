#include<stdio.h>

struct first {
  char padding;
  unsigned _0 : 1;
  unsigned _1 : 1;
  unsigned _2 : 1;
  unsigned _3 : 1;
  unsigned _4 : 1;
  unsigned _5 : 1;
  unsigned _6 : 1;
  unsigned _7 : 1;
};

struct third {
  char padding;
  unsigned char value;
};

union second {
  struct first bits;
  struct third value;
};

union second foo;

int main() {
  foo.value.value = 0;
  foo.bits._0 = 1;
  foo.bits._7 = 1;
  printf("%d %d\n", foo.bits._0, foo.value.value);

  return 0;
}
