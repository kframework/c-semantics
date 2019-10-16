#include <stdlib.h>
struct {
  unsigned int a:4;
  unsigned int :4;
  unsigned int b:4;
  unsigned int c:4;
} x = { 2,3,4 };

int main ()
{
  if (x.a != 2)
    abort ();
  if (x.b != 3)
    abort ();
  if (x.c != 4)
    abort ();
  exit (0);
}
