#include<stdlib.h>
typedef struct {
  struct {
    struct {
      int x1;
    } x2;
  } x3;
} x4;
x4 x7[] = {{.x3.x2 = {.x1 = 1}}};

struct {
  struct {
    struct {
      int x1;
    };
  };
} y[] = {{.x1 = 1}};

struct {
  struct {
    struct {
      int x1;
    };
  };
} z[] = {{1}};

struct {
  int x1;
  struct {
    struct {
      int x2;
    };
    int x3;
  };
} w[] = {{1, 2, 3}};

int main() {
  if (x7[0].x3.x2.x1 != 1) abort();
  if (y[0].x1 != 1) abort();
  if (z[0].x1 != 1) abort();
  if (w[0].x2 != 2) abort();
}
