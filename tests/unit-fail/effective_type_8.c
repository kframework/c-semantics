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
  ((st1 *)p)->c1 = 'A';
  // is this free of undefined behaviour?
  ((st2 *)p)->f2 = 1.0;
  printf("((st2 *)p)->f2=%f\n",((st2 *)p)->f2);
}
