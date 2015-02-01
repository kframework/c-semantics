#include <stdlib.h>
void foo(int *bar)
{
  *bar = 8;
}

int bugger()
{
  int oldDepth, newDepth;

  foo(&oldDepth);

  switch (oldDepth)
    {
    case 8:
    case 500:
      newDepth = 8;
      break;

    case 5000:
      newDepth = 500;
      break;

    default:
      newDepth = 17;
      break;
    }

  return newDepth - oldDepth;
}

int main()
{
  if (bugger() != 0)
    abort ();
  exit (0);
}
