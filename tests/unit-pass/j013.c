struct {
      int x;
      int y;
} s;

int main(void) {
      unsigned char x;

      *((unsigned char*) &s.x) = x;

      return 0;
}
