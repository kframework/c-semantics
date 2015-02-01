#include <stdlib.h>
int
f(long long x)
{
  x >>= 8;
  return x & 0xff;
}

int main()
{
  if (f(0x0123456789ABCDEFLL) != 0xCD)
    abort();
  exit (0);
}
