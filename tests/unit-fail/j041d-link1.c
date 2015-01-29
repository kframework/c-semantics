int f(int * restrict);

int main(void) {
      int p = 42;
      return f(&p);
}
