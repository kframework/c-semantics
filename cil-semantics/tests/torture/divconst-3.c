#include <stdlib.h>
long long
f (long long x)
{
  return x / 10000000000LL;
}

int main ()
{
  if (f (10000000000LL) != 1 || f (100000000000LL) != 10)
    abort ();
  exit (0);
}
