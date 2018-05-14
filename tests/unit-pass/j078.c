int a(void) {
      return 0;
}

int b(void) {
      _Thread_local static int x;
      x = 0;
      return x;
}

int c(void) {
      auto int x;
      x = 0;
      return x;
}

int d(void) {
      static int x;
      x = 0;
      return x;
}

int e(void) {
      const int x = 0;
      return x;
}

int f(void) {
      int * restrict p;
      return 0;
}

int g(void) {
      volatile int x;
      volatile int * volatile y;
      x = 0;
      y = (volatile int * volatile) &x;
      return x + *y;
}

int h(void) {
      _Atomic int x;
      _Atomic int * _Atomic y;
      x = 0;
      y = (_Atomic int * _Atomic) &x;
      return x + *y;
}

int i(void) {
      const _Atomic volatile int x = 0;
      const _Atomic volatile int * const _Atomic volatile y = (const _Atomic volatile int * const _Atomic volatile) &x;
      return x + *y;
}

int main(void) {
      return a() + b() + c() + d() + e() + f() + g() + h() + i();
}
