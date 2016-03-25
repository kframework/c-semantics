void foo(int x) {}
void bar(int y) {}

int main() {
  void (*baz)(int) = 0 ? foo : bar;
  baz(0);
}
