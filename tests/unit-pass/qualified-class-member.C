extern "C" void abort();
struct A {
  int x;
  void foo() {
    A::x = 0;
  }

  A() { x = 5; }
};

int main() {
  A x;
  x.foo();
  if (x.x != 0) abort();
}
