#include <stdlib.h>
int f ()
{
  int var = 7;

  if ((var/7) == 1)
    return var/7;
  return 0;
}

int main ()
{
  if (f () != 1)
    abort ();
  exit (0);
}
