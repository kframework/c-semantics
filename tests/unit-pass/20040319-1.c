#include <stdlib.h>
int
blah (int zzz)
{
  int foo;
  if (zzz >= 0)
    return 1;
  foo = (zzz >= 0 ? (zzz) : -(zzz));
  return foo;
}

int main()
{
  if (blah (-1) != 1)
    abort ();
  else
    exit (0);
}
