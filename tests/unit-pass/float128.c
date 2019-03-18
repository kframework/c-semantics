#include <stdlib.h>
__float128 C = 5;
__float128 U = 1;
__float128 Y2 = 11;
__float128 Y1 = 17;
__float128 X, Y, Z, T, R, S;
int main ()
{
  X = (C + U) * Y2;
  Y = C - U - U;
  Z = C + U + U;
  T = (C - U) * Y1;
  X = X - (Z + U);
  R = Y * Y1;
  S = Z * Y2;
  T = T - Y;
  Y = (U - Y) + R;
  Z = S - (Z + U + U);
  R = (Y2 + U) * Y1;
  Y1 = Y2 * Y1;
  R = R - Y2;
  Y1 = Y1 - 0.5L;
  if (Z != 68. || Y != 49. || X != 58. || Y1 != 186.5 || R != 193. || S != 77.
      || T != 65. || Y2 != 11.)
    abort ();
  exit (0);
}
