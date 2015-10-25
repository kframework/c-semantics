int main() {
  volatile int x;
  volatile int *y = &x;
  *y = 5;
  return 0;
}
