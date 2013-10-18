#include <stdlib.h>
#include <stddef.h>
/* PR target/21297 */
//;
extern int memcmp (const char *, const char *, size_t);
extern void abort ();

void
foo (char *x)
{
  int i;
  for (i = 0; i < 2; i++);
  x[i + i] = '\0';
}

void
bar (char *x)
{
  int i;
  for (i = 0; i < 2; i++);
  x[i + i + i + i] = '\0';
}

int main (void)
{
  char x[] = "IJKLMNOPQR";
  foo (x);
  if (memcmp (x, "IJKL\0NOPQR", sizeof x) != 0)
    abort ();
  x[4] = 'M';
  bar (x);
  if (memcmp (x, "IJKLMNOP\0R", sizeof x) != 0)
    abort ();
  return 0;
}
