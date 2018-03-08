#include <stdlib.h>
struct S
{
  char f1;
  int f2[2];
};

struct S object = {'X', 8, 9};

int main ()
{
  struct S ss[100000] = {{'X', 8, 9}};
  if (object.f1 != 'X' || object.f2[0] != 8 || object.f2[1] != 9)
    abort ();
  if (ss[0].f1 != 'X' || ss[0].f2[0] != 8 || ss[0].f2[1] != 9)
    abort ();
  exit (0);
}

