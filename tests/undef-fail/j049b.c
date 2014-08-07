int main(void) {
      int a[4][3] = {0}; // theoretically 4 * 3 memory slots
      int z = a[0][4]; // but not allowed to go out of bounds in any dimension
      return 0;
}
