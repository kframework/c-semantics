struct s {
      unsigned:32;
      int x;
} s;

int main(void) {
      return *((unsigned*)&s);
}
