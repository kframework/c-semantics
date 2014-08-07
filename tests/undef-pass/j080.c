struct s {
      unsigned:32;
      int x;
} s;

int main(void) {
      struct s t = s;
      return s.x;
}
