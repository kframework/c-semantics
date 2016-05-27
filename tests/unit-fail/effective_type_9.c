// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
typedef struct { char c1; float f1; } st1;
typedef struct { char c2; float f2; } st2;
int main() {
  assert(sizeof(st1)==sizeof(st2));
  assert(offsetof(st1,c1)==offsetof(st2,c2));
  assert(offsetof(st1,f1)==offsetof(st2,f2));
  void *p = malloc(sizeof(st1)); assert (p != NULL);
  st1 s1 = { .c1='A', .f1=1.0};
  *((st1 *)p) = s1;
  // is this free of undefined behaviour?
  float f = ((st2 *)p)->f2;
  printf("f=%f\n",f);
}
