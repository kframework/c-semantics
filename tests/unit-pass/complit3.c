struct x {
  int y;
};
int main() {
  struct x foo = {0};
  foo = 1 ? foo : (struct x){0};
  return 0;
}
