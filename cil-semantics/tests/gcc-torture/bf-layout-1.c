#include <stdlib.h>
struct { int f8:8; int f24:24; } a;
struct { int f32:32; } b;

int main ()
{
  if (sizeof (a) != sizeof (b))
    abort ();
  exit (0);
}
