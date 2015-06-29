int main(void) {
      _Alignas(32) int x;
      _Alignas(32) int *p;

      int y;
      int *q;

      p = &x;
      q = &y;

      return 0;
}
