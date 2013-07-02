#include <stdlib.h>
#include <limits.h>

int n = 0;

void g (int i)
{
  n++;
}

void f (int m)
{
  int i;
  i = m;
  do
    {
      g (i * INT_MAX / 2);
    }
  while (--i > 0);
}

int main ()
{
  f (4);
  if (n != 4)
    abort ();
  exit (0);
}
