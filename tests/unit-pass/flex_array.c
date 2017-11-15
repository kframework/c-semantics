#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
struct s {
      int x;
      int f1[];
};

union u {
      struct s a;
      struct { int x; int y; int z; int w; } b;
};

union ux {
      struct s a;
      struct { int x; int y; int z; int w; } b;
      struct { int x; int y; int z; int w; int u; int f2[]; } c;
};

union u so;

int main(void) {
      if (offsetof(struct s, x) >= offsetof(struct s, f1))
            abort();

      union u ao = {0};
      union u * po = malloc(sizeof(union u) + 32);
      ao.b.w = 1;
      so.b.w = 2;
      po->b.w = 3;

      printf("%d\n", ao.a.f1[2]);
      printf("%d\n", ao.b.w);
      printf("%d\n", so.a.f1[2]);
      printf("%d\n", so.b.w);
      printf("%d\n", po->a.f1[2]);
      printf("%d\n", po->b.w);

      ao.b.x = 4;
      so.b.x = 5;
      po->b.x = 6;

      printf("%d\n", ao.a.x);
      printf("%d\n", ao.b.x);
      printf("%d\n", so.a.x);
      printf("%d\n", so.b.x);
      printf("%d\n", po->a.x);
      printf("%d\n", po->b.x);

      po->a.f1[5] = 9;

      printf("%d\n", po->a.f1[5]);
      printf("%d\n", po->b.x);

      sizeof(ao);
      sizeof(ao.a);
      sizeof(ao.b);
      sizeof(so);
      sizeof(so.a);
      sizeof(so.b);
      sizeof(*po);
      sizeof(po->a);
      sizeof(po->b);

      union ux * px = malloc(sizeof(union ux) + 32);
      px->b.w = 10;
      px->c.u = 11;
      printf("%d\n", px->b.w);

      printf("%d\n", px->a.f1[2]);
      printf("%d\n", px->a.f1[3]);

      printf("%d\n", px->b.w);
      printf("%d\n", px->c.w);

      px->a.f1[2] = 13;
      printf("%d\n", px->a.f1[2]);
      printf("%d\n", px->c.u);

      px->c.f2[2] = 13;
      printf("%d\n", px->c.f2[2]);
      printf("%d\n", px->a.f1[2]);

      sizeof(*px);
      sizeof(px->a);
      sizeof(px->b);
      sizeof(px->c);
}
