struct {
      unsigned : sizeof(unsigned) * 8;
      unsigned x;
} s;

int main(void) {
      return *((unsigned*)&s);
}
