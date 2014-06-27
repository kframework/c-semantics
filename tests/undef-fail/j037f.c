int main(void) {
      int x = 10;
      int* a;
      long* b;
      void* p;

      a = &x;
      p = a;
      b = p;
      *b;
      return 0;
}
