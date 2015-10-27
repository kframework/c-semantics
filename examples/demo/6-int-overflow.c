// KCC is also able to detect integer overflow operations that occur while the
// program is executing.
int main() {
  short int a = 1024;
  int i;
  for (i = 0; i < 10; i++) {
    a *= 2;
  }
  return a;
}
