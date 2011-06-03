#include <stdlib.h>
int
f (int a)
{
  return ((a >= 0 && a <= 10) && ! (a >= 0));
}

int main ()
{
  if (f (0))
    abort ();
  exit (0);
}
