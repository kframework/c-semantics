struct X {
  int mem2() {return b;}
  static int b;
};

int X::b = 1;

int main() {
  X x;
  return x.mem2() - 1;
}