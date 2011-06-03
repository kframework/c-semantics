#include <stdlib.h>

int n = 2;

int main ()
{
  int i, x = 45;

  for (i = 0; i < n; i++)
    {
      if (i != 0)
	x = ( i > 0 ) ? i : 0;
    }

  if (x != 1)
    abort ();
  exit (0);
}
