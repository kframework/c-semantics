int b=2;
struct X {
  int f() {
    return g(1);
  }
  int g(int i = b) {
    return i;
  }

  int g(double j, int i = 5) {
    return 5;
  }

  static int b;
};

int X::b = 1;

int main() {
  X x;
  return x.f() - 1;
}