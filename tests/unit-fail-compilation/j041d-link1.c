int f(int * restrict *);

int main(void) {
      int p = 42;
      int * restrict ptr = &p;
      return f(&ptr);
}
