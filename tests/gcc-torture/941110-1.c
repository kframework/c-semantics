#include <stdlib.h>
int f (const int x)
{
  int y = 0;
  y = x ? y : -y;
  {
    const int *p = &x;
  }
  return y;
}

int main ()
{
  if (f (0))
    abort ();
  exit (0);
}
