int x = 0;
int f(int y = x) {
  x++;
  return y;
}

int main() {
  return f() + f() + f() - 3;
}