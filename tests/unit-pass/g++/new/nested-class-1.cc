struct A {
  struct B {
    typedef int T;
  };
  B::T x;
};

int main() {
  return 0;
}
