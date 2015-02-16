int main(void) {
      char x;
      _Alignas(32) int *p = (int*) &x;

      return 0;
}
