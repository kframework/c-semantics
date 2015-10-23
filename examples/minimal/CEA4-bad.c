int main() {
  int x = 0;
  int *y = &x;
  y = x - y;
  return 0;
}
