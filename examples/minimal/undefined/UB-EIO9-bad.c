volatile struct {
  int x;
} foo;

int main() {
  int *y = (int *)&foo.x;
  return *y;
}
