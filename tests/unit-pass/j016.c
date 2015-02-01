void f(int n, int (*a)[n]) { }

int main(void) {
      int a[5] = {0};
      int (*b)[5] = &a;
      f(5, b);

      return 0;
}
