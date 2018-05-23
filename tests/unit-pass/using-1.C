extern "C" void abort();
namespace A {
  void f(int) {}
}

using A::f;

namespace A {
  void f(char) { abort(); }
}

int main() {
  f('a');
}
