#include <stdlib.h>
static int i;

void
check(x)
     int x;
{
  if (!x)
    abort();
}

int main()
{
  int *p = &i;

  check(p != (void *)0);
  exit (0);
}
