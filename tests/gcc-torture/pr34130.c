#include <math.h>
#include <stdlib.h>
extern void abort (void);
int foo (int i)
{
  return -2 * abs(i - 2);
}
int main()
{
  if (foo(1) != -2
      || foo(3) != -2)
    abort ();
  return 0;
}
