int b = 2;
struct X {
  int i = b;
  static int b;
};

int X::b = 1;

int main() {
  X x;
  return x.i - 1;
}