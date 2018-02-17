int main() {
      const a = 1 << 0;
      register b = 1 << 1;
      volatile c = 1 << 2;
      _Atomic d = 1 << 3;

      return (a + b + c + d) ^ 0xf;
}
