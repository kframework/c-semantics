// From the cerberus project: http://www.cl.cam.ac.uk/~pes20/cerberus/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdalign.h>
int main() {
  _Alignas(float) unsigned char c[sizeof(float)];
  // c has effective type char array
  float f=1.0;
  memcpy((void*)c, (const void*)(&f), sizeof(float));
  // c still has effective type char array
  float *fp = (float *) malloc(sizeof(float));
  // the malloc'd region initially has no effective type
  memcpy((void*)fp, (const void*)c, sizeof(float));
  // does the following have defined behaviour? 
  // (the ISO text says the malloc'd region has effective 
  // type unsigned char array, not float, and hence that 
  // the following read has undefined behaviour)
  float g = *fp;
  //printf("g=%f\n",g);
}
