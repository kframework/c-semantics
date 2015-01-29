struct {
      unsigned:sizeof(unsigned);
      unsigned x;
} s;

int main(void) {
      return *((unsigned*)&s);
}
