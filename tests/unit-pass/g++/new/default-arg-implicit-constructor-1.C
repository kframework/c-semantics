struct A {
  A (int x, int y = 5) {}
};

int f(A x) {
  return 0;
}

int main() {
  A obj(1);
  return f(obj);
}