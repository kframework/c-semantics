static void *x = &x;

int main() {
  int y;
  x = &y;
  return 0;
}
