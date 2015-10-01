#include<stdio.h>

struct first {
  char padding;
  unsigned char _0 : 1;
  unsigned char _1 : 1;
  unsigned char _2 : 1;
  unsigned char _3 : 1;
  unsigned char _4 : 1;
  unsigned char _5 : 1;
  unsigned char _6 : 1;
  unsigned char _7 : 1;
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
