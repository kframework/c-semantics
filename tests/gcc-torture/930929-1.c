#include <stdlib.h>
int sub1 (i)
     int i;
{
  return i - (5 - i);
}

int sub2 (i)
     int i;
{
  return i + (5 + i);
}

int sub3 (i)
     int i;
{
  return i - (5 + i);
}

int sub4 (i)
     int i;
{
  return i + (5 - i);
}

int main()
{
  if (sub1 (20) != 35)
    abort ();
  if (sub2 (20) != 45)
    abort ();
  if (sub3 (20) != -5)
    abort ();
  if (sub4 (20) != 5)
    abort ();
  exit (0);
}
