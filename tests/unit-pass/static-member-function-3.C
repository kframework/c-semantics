struct s {
  static int f(int x, int y);
};

int s::f(int x, int y) { return x + y; }

int main() {
  return s::f(-1, 1);
}