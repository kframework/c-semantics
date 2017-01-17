int main(void) {
      long x = 10;
      long* a;
      long long* b;
      void* p;

      a = &x;
      p = a;
      b = p;
      *b;
      return 0;
}
