#include<assert.h>
struct A {
  int x, y;
  A(int x, int y) : x(x), y(y) {}
};

int main() {
  A *x = new A(3, 4);
  A y(5, 6);
  assert(x->x == 3);
  assert(x->y == 4);
  assert(y.x == 5);
  assert(y.y == 6);
}
