#include <stdlib.h>
#include <stddef.h>
void f (int *p, int **q)
{
  int i;
  for (i = 0; i < 40; i++)
    {
      *q++ = &p[i];
    }
}

int main ()
{
  void *p;
  int *q[40];
  size_t start;

  /* Find the signed middle of the address space.  */
  if (sizeof(start) == sizeof(int))
    start = (size_t) __INT_MAX__;
  else if (sizeof(start) == sizeof(long))
    start = (size_t) __LONG_MAX__;
  else if (sizeof(start) == sizeof(long long))
    start = (size_t) __LONG_LONG_MAX__;
  else
    return 0;

  /* Arbitrarily align the pointer.  */
  start &= -32;

  /* Pretend that's good enough to start address arithmetic.  */
  p = (void *)start;

  /* Verify that GIV replacement computes the correct results.  */
  q[39] = 0;
  f (p, q);
  if (q[39] != (int *)p + 39)
    abort ();

  return 0;
}
