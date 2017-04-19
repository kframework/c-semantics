#include<stdlib.h>

struct A {
  virtual void foo() { abort(); }
};

struct B : A {
  void foo() { abort(); }
};

struct C : A {
  void foo() { abort(); }
};

struct D : B, C {
  void foo() {}
};

int main() {
  D d;
  d.foo();
  A *a = (B*)&d;
  a->foo();
  a = (C*)&d;
  a->foo();
  B *b = &d;
  b->foo();
  C *c = &d;
  c->foo();
}
