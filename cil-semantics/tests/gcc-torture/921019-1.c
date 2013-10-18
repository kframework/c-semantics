#include <stdlib.h>
void *foo[]={(void *)&("X"[0])};

int main ()
{
  if (((char*)foo[0])[0] != 'X')
    abort ();
  exit (0);
}
