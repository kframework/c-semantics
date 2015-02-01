int main(void) {
      int x = 5;
      int y = 6;
      int * restrict p = &x;
      int * restrict q = &x;

      p = q;

      return 0;
}
