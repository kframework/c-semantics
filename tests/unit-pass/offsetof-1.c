#include<stddef.h>
#include<stdlib.h>

struct bar {
  short y;
};

struct foo {
  short x[4];
  struct bar z[4];
};

int main() {
  int offset = offsetof(struct foo, x);
  if (offset != 0)
    abort();
  offset = offsetof(struct foo, x[2]);
  if (offset != 4)
    abort();
  offset = offsetof(struct foo, z[0].y);
  if (offset != 8)
    abort();
  return 0;
}
