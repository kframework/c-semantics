int main() {
  struct foo {
    int x;
  };
  {
    struct foo x;
  }
  void *x = 0 ? (struct foo *) 0 : (void *)0;
}
