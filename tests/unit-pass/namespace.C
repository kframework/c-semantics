namespace foo {
    typedef int bar;
}

inline namespace x {}

namespace A {
      namespace B {
            int y;
      }
}

int main() {
  foo::bar x = 0;
  return x + A::B::y;
}
