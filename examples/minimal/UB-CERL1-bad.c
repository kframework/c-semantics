int main(void) {
      struct {int x; } a;
      struct {int x; } b;

      int* p = &a.x;
      int* q = &b.x;

      if (&p < &q) {
            return 0;
      }
}
