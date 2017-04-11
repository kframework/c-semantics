int b=2;
struct X {
  int f() {
    return g();
  }
  int g(int i = b) {
    return i;
  }
  static int b;
};

int X::b = 1;

int main() {
  X x;
  return x.f() - 1;
}