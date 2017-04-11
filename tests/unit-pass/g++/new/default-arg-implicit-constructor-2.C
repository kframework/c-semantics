struct A {
  A (int x, int y = 5) {}
};

int f(A x) {
  return 0;
}

int main() {
  return f(1);
}