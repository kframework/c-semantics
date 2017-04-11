// Based on the Toyota ITC benchmark.
#include <stdlib.h>

typedef struct {
      signed int a : 7;
      signed int b : 7;
} s;

int main (void) {
      s * s = malloc (5*sizeof(s));
      s->b = s->a;
}

