#include<stdio.h>
#include<stdlib.h>
struct first {
  char a;
  unsigned b : 6;
  unsigned c : 1;
  unsigned d : 2;
  int e;
  unsigned f : 2;
  unsigned g : 6;
  unsigned h : 2;
  char i;
};

union second {
  struct first x;
  unsigned char y[12];
};

union second foo = {.x={17, 31, 0, 3, 300, 3, 63, 0, 127}};

int main() {
  if (sizeof(struct first) != 12)
    abort();
  if (foo.x.a != 17 || foo.x.b != 31 || foo.x.c != 0 || foo.x.d != 3 || foo.x.e != 300 
   || foo.x.f != 3  || foo.x.g != 63  || foo.x.h != 0 || foo.x.i != 127)
    abort();
  if (foo.y[8] != 255)
    abort();
  return 0;
}
