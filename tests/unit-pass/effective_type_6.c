#include<stdlib.h>

struct foo {
  int x;
  char *y;
};

struct bar {
  struct foo x;
};

struct baz {
      double x;
      int y;
};

int main() {
  void *p = calloc(sizeof(struct foo), 1);
  int *p2 = (int *)p;
  *p2 = 1;
  struct foo *p3 = (struct foo *)p;
  p3->y = "foo";
  struct bar *p4 = p;
  p4->x.y = "bar";
  struct bar (*p5)[1] = p;
  (*p5)[0].x.y = "baz";
  free(p);
  struct baz *q = malloc(2 * sizeof(struct baz));
  q[1].x = 0.0;
  q[1];
  free(q);
}

