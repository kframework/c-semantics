// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <inttypes.h>
#include <assert.h>
void f(uint32_t *p1, float *p2) {
  *p1 = 2;
  *p2 = 3.0; // does this have defined behaviour?
  // printf("f: *p1 = %" PRIu32 "\n",*p1);
}
int main() {
  assert(sizeof(uint32_t)==sizeof(float));
  uint32_t i = 1;
  uint32_t *p1 = &i;
  float *p2;
  p2 = (float *)p1;
  f(p1, p2);
  // printf("i=%" PRIu32 "  *p1=%" PRIu32 
  //        "  *p2=%f\n",i,*p1,*p2);
}
