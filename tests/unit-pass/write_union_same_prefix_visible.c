// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
typedef struct { int  i1; float f1; char c1; } st1;
typedef struct { int  i2; float f2; double d2; } st2;
typedef union { st1 m1; st2 m2; } un;
int main() {
  un u = {.m1 = {.i1 = 1, .f1 = 1.0, .c1 = 'a'}};
  u.m2.i2 = 2; // is this free of undef.beh.?
  printf("u.m1.i1=%i  u.m2.i2=%i\n",u.m1.i1,u.m2.i2);
}

