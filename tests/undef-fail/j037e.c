int main(void) {
      int x = 10;
      int* a;
      long* b;

      a = &x;
      b = (long*)a;
      *b;
      return 0;
}
