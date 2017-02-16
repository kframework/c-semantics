#include <stdio.h>
#include <stdlib.h>

int
main (void)
{
  double d;
  int c;

  FILE* f = tmpfile();
  fprintf(f, "%s", "+ foo");
  rewind(f);

  if (fscanf (f, "%lg", &d) != 0)
    {
      printf ("scanf didn't failed\n");
      exit (1);
    }
  c = getc (f);
  if (c != ' ')
    {
      printf ("c is `%c', not ` '\n", c);
      exit (1);
    }

  return 0;
}
