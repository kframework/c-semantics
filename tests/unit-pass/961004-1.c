#include <stdlib.h>
int k = 0;

int main()
{
  int i;
  int j;

  for (i = 0; i < 2; i++)
    {
      if (k)
	{
	  if (j != 2)
	    abort ();
	}
      else
	{
	  j = 2;
	  k++;
	}
    }
  exit (0);
}
