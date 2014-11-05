int a(void) {
      return 0;
}

int c(void) {
      auto int x;
      return 0;
}

int d(void) {
      static int x;
      return 0;
}

int e(void) {
      const int x = 0;
      return 0;
}

int f(void) {
      int* restrict p;
      return 0;
}

int g(void) {
      volatile int x;
      return 0;
}

int h(void) {
      _Atomic int x;
      return 0;
}

int main(void) {
      return 0;
}
