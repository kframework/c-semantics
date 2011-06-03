#include <stdlib.h>
/* The bit-field below would have a problem if __INT_MAX__ is too
   small.  */
#if __INT_MAX__ < 2147483647
int main (void)
{
  exit (0);
}
#else
int f ()
{
  struct {
    int x : 18;
    int y : 14;
  } foo;

  foo.x = 10;
  foo.y = 20;

  return foo.y;
}

int main ()
{
  if (f () != 20)
    abort ();
  exit (0);
}
#endif
