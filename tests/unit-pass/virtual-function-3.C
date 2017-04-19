#include<stdlib.h>

struct A {
  virtual void foo() { abort(); }
};

struct B : A {
  void foo() {}
};

struct C : A {
  void foo() {}
};

struct D : B, C {
  void foo() { abort(); }
};

int main() {
  B b;
  b.foo();
  A *a = &b;
  a->foo();
  C c;
  c.foo();
  a = &c;
  a->foo();
}
