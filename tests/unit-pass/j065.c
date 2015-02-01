int f(volatile int* x) {
      return *x;
}

int main(void) {
      volatile int x = 5;
      *(volatile int*)&x;
      f(&x);

      return 0;
}
