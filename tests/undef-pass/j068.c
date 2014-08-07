int f(int* restrict a, int* restrict b) {
      *a = 3;
      return 0;
}

int g(const int* restrict a, int* b) {
      *b;
      *a;
      return 0;
}

// this example is loosely based on an example in sentence 1509 in http://www.knosof.co.uk/cbook/cbook.html
int g2();

int f2(int * restrict p) {
      g2(p);
      return *p;
}

int main(void) {
      int a = 5;
      f(&a, &a);
      g(&a, &a);

      int x = 5;
      return f2(&x) == 5;
}

int g2(int * p) {
      *p = 10;
      return 0;
}
