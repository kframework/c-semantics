// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
typedef struct { int  i1; } st1;
typedef struct { int  i2; } st2;
void f(st1* s1p, st2* s2p) {
  s1p->i1 = 2;
  s2p->i2 = 3;
  printf("f: s1p->i1 = %i\n",s1p->i1);
}
int main() {
  st1 s = {.i1 = 1}; 
  st1 * s1p = &s;
  st2 * s2p;
  s2p = (st2*)s1p;
  f(s1p, s2p); // defined behaviour?
  printf("s.i1=%i  s1p->i1=%i  s2p->i2=%i\n",
         s.i1,s1p->i1,s2p->i2);
}
