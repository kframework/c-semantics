#include <stdlib.h>
int f()
{
  return (unsigned char)("\377"[0]);
}

int main()
{
  if (f() != (unsigned char)(0377))
    abort();
  exit (0);
}
