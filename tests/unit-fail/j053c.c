int main(void) {
      int a[3] = {0};
      int b;

      int *p = &a[0] + 3;
      int *q = &b;

      if (&p <= &q) {
            return 0;
      }
}
