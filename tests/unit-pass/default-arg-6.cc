int f(int, int=3);

int f(int x = 4, int y) {
  return x - y;
}

int main() {
  return f() - 1;
}