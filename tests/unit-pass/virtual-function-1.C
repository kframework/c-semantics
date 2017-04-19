#include<stdlib.h>

struct A {
  virtual void foo() { abort(); }
};

struct B : A {
  void foo() {}
};

int main() {
  B b;
  A *a = &b;
  a->foo();
  b.foo();
}
