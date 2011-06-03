#include <stdlib.h>
static double f (float a);
static double (*fp) (float a);

int main ()
{
  fp = f;
  if (fp ((float) 1) != 1.0)
    abort ();
  exit (0);
}

static double
f (float a)
{
  return a;
}
