#include <stdio.h>
#include <stdarg.h>

void
printArgsNoRet(int a1,  float a2,  char a3,  double a4,  char* a5,
               int a6,  float a7,  char a8,  double a9,  char* a10,
               int a11, float a12, char a13, double a14, char* a15)
{
  printf("\nprintArgsNoRet with 15 arguments:\n");
  printf("\tArgs 1-5  : %d %d %c %d %c\n", a1,  (int)(10*a2),  a3,  (int)(10*a4),  *a5);
  printf("\tArgs 6-10 : %d %d %c %d %c\n", a6,  (int)(10*a7),  a8,  (int)(10*a9),  *a10);
  printf("\tArgs 11-14: %d %d %c %d %c\n", a11, (int)(10*a12), a13, (int)(10*a14), *a15);
  printf("\n");
  return;
}


int
main(int argc, char** argv)
{
  printArgsNoRet(1,  2.1,  'c', 4.1,  "e",
                 6,  7.1,  'h', 9.1,  "j",
                 11, 12.1, 'm', 14.1, "o");
  return 0;
}
