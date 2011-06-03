#include <stdlib.h>
int v;
void f();
int main ()
{
  f ();
  exit (0);
}

int h1 ()
{
  return 0;
}

int h2 (e)
     int *e;
{
  if (e != &v)
    abort ();
  return 0;
}

int g (c)
     char *c;
{
  int i;
  int b;

  do
    {
      i = h1 ();
      if (i == -1)
	return 0;
      else if (i == 1)
	h1 ();
    }
  while (i == 1);

  do
    b = h2 (&v);
  while (i == 5);

  if (i != 2)
    return b;
  *c = 'a';

  return 0;
}


void f ()
{
  char c;
  g (&c);
}
