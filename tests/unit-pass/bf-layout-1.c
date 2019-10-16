#include <stdlib.h>
struct { signed int f8:8; signed int f24:24; } a;
struct { signed int f32:32; } b;

int main ()
{
  if (sizeof (a) != sizeof (b))
    abort ();
  exit (0);
}
