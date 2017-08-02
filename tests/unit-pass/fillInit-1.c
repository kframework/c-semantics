#include<stdlib.h>

struct foo {
  int x;
};

int main() {
  struct foo y = {1};
  struct foo z[2] = {y, y};
  if (z[0].x != 1) abort();
  if (z[1].x != 1) abort();
}
