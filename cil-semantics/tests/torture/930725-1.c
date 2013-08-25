#include <string.h>
#include <stdlib.h>
int v;

char *
g ()
{
  return "";
}

char *
f ()
{
  return (v == 0 ? g () : "abc");
}

int main ()
{
  v = 1;
  if (!strcmp (f (), "abc"))
    exit (0);
  abort();
}
