#include <stdlib.h>
int main(void) {
      int *a = malloc(sizeof(int [3]));
      a[1] = 0;
      a[2] = 0;
      a[0] = 1;
      struct s1 {int x; int y; } *b = malloc(sizeof(struct s1));
      b->x = 1;
      struct s2 {int x; int y; } *c = malloc(sizeof(struct s2 [3]));
      c[0].y = 1;
      c[1].x = 1;
      c[2].y = 0;
      struct s3 {int x; int y; int z[]; } *d = malloc(sizeof(struct s3) + sizeof(int [3]));
      d->z[1] = 0;
      d->z[2] = 1;
      d->z[0] = 0;
      return *a + b->x + c->y + c[1].x + d->z[2] - 5;
}
