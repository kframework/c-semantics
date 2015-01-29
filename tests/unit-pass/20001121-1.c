#include <stdlib.h>
double d;

static __inline__ double foo (void)
{
  return d;
}

static __inline__ int bar (void)
{
  foo();
  return 0;
}

int main (void)
{
  if (bar ())
    abort ();
  exit (0);
}
