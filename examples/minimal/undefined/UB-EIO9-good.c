volatile struct {
  int x;
} foo;

int main() {
  volatile int *y = &foo.x;
  return *y;
}
