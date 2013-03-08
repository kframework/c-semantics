#include <stdio.h>

void p1 (c, f1, s, d1, i, f2, l, d2)
char c; float f1; short s; double d1; int i; float f2; long l; double d2;
{
  printf("%c %d %d %d %d %d %d %d\n", c, (int)(100*f1), s, (int)(100*d1),i, (int)(100*f2), l, (int)(100*d2));
}

void p2 (char c, float f1, short s, double d1, int i, float f2, long l, double d2)
{
  printf("%c %d %d %d %d %d %d %d\n", c, (int)(100*f1), s, (int)(100*d1),i, (int)(100*f2), l, (int)(100*d2));
}

int main(int argc, char *argv[]) {
  p1 ('a', 4.0, 1, 5.0, 2, 4.0, 3, 5.0);
  p2 ('a', 4.0, 1, 5.0, 2, 4.0, 3, 5.0);
  return 0;
}

