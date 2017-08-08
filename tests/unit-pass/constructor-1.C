#include<assert.h>
struct A {
  int x;
  A(int x) { this->x = x; }
};

int main() {
  A x(0);
  A y(5);
  assert(x.x == 0);
  assert(y.x == 5);
}
