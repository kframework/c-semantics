int main(void) {
      int a[4][5] = {0};
      a[2][3];

      int b[4][3] = {0}; // theoretically 4 * 3 memory slots
      int z = b[0][0]; // but not allowed to go out of bounds in any dimension

      int c[4][5] = {0};
      *(*c + 2 + 2);

      return 0;
}
