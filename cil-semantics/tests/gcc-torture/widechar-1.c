#include <stdlib.h>
#define C L'\400'

#if C
#define zero (!C)
#else
#define zero C
#endif

int main()
{
  if (zero != 0)
    abort ();
  exit (0);
}
