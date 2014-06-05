int f(int* restrict a, int* restrict b) {
      *a = 3;
      return 0;
}

int g(const int* restrict a, int* b) {
      *b;
      *a;
      return 0;
}

int main(void) {
      int a = 5;
      f(&a, &a);
      g(&a, &a);
}
