int main(void) {
      int n = 2;

      sizeof(int(*[--n]));

      return n != 1; // Unspecified whether n == 1 or n == 2.
}
