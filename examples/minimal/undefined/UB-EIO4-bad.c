int main() {
  volatile int x;
  int *y = (int *)&x;
  *y = 5;
  return 0;
}
