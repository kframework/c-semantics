// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <stdalign.h>
int main() {
  _Alignas(float) unsigned char c[sizeof(float)];
  float *fp = (float *)c;
  *fp=1.0; // does this have defined behaviour?
  printf("*fp=%f\n",*fp);
}
