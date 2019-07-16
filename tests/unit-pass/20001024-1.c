#include <stdlib.h>
struct a;

extern int baz (struct a *restrict x);

struct a {
  long v;
  long w;
};

struct b {
  struct a c;
  struct a d;
};

int bar (int x, const struct b *restrict y, struct b *restrict z)
{
  if (y->c.v || y->c.w != 250000 || y->d.v || y->d.w != 250000)
    abort();
  return 0;
}

void foo(void)
{
  struct b x;
  x.c.v = 0;
  x.c.w = 250000;
  x.d = x.c;
  bar(0, &x, ((void *)0));
}

int main()
{
  foo();
  exit(0);
}
