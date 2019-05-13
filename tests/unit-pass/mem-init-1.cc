#include<assert.h>
struct A {
  int x;
  A(int x) : x(x) {}
};

struct B : A {
  B(int x) : A(x) {}
};

int main() {
  B x(0);
  assert(x.x == 0);
  B y(5);
  assert(y.x == 5);
}
