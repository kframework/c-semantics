int test1(void) {
      goto test1a;
      int x = 0; // we skip over the init (although the memory is allocated)
test1a:
      x = 0;
      return x;
}

union U0 {
      int x;
};

int main(void) {
      int x = 0;
      x;

      float y = 0;
      y;

      int* p = 0;
      p;

      unsigned char uc;
      &uc;
      uc;

      union U0 u = {0};
      u;

      return test1();
}
