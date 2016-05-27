// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <assert.h>
typedef struct { char c1; float f1; } st1;
int main() {
  void *p = malloc(sizeof(st1)); assert (p != NULL);
  st1 s1 = { .c1='A', .f1=1.0};
  *((st1 *)p) = s1;
  float *pf = &(((st1 *)p)->f1);
  // is this free of undefined behaviour?
  float f = *pf;
  //printf("f=%f\n",f);
}
