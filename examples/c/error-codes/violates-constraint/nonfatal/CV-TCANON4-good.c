int main() {
      const int a = 1 << 0;
      register int b = 1 << 1;
      volatile int c = 1 << 2;
      _Atomic int d = 1 << 3;

      return (a + b + c + d) ^ 0xf;
}
