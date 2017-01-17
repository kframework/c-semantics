int main(void) {
      long x = 10;
      long* a;
      long long* b;

      a = &x;
      b = (long long*)a;
      *b;
      return 0;
}
