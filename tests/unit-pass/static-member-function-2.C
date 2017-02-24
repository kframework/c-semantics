struct s {
  static int f(int x, int y) { return x + y; };
};

int f(int x, int y) {
  return x - y;
}

int main() {
  return f(1, 1);
}