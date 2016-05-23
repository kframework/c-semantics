int main() {
  float a;
  float *b = &a;
  int x;
  int *y = &x;
  y != (int *)b;
  return 0;
}
