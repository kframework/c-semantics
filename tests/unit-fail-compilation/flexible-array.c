#include <stdlib.h>

struct fam {
      int a;
      int fam[];
};

struct container {
      int b;
      struct fam f;  // <-------------- flagged by gcc as compiler extension
};

int main(void) {
      struct container * c = malloc(100 * sizeof(int));
      c->b = 1;
      c->f.a = 2;
      c->f.fam[5] = 3;
      return c->f.fam[5];
}

