#include <stdlib.h>
static double one = 1.0;

int f()
{
  int colinear;
  colinear = (one == 0.0);
  if (colinear)
    abort ();
  return colinear;
}
int main()
{
  if (f()) abort();
  exit (0);
}
