/* The composite type of int and an enum compatible with int might be
   either of the two types, but it isn't an unsigned type.  */
/* Origin: Joseph Myers <jsm@polyomino.org.uk> */

#include <limits.h>

#include <stdio.h>

extern void abort (void);
extern void exit (int);

signed int *p;
int *q;
int main (void)
{
  int x = INT_MIN;
  q = &x;
  if (*(1 ? q : p) > 0)
    abort ();
  exit (0);
}
