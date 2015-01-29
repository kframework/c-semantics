#include <stdlib.h>
struct a
{
  unsigned int bitfield : 3;
};
void foo();
int main()
{
  struct a a;

  a.bitfield = 131;
  foo (a.bitfield);
  exit (0);
}

void foo(unsigned int z)
{
  if (z != 3)
    abort ();
}
