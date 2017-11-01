union u {
      long x;
      short y;
};

union u a[5];

int main(void) {
      long * p;
      short * q;

      a[2].x = 1;
      a[3].y = 1;

      p = (long*) &a[2].x;
      *p = 2;

      q = (short*) &a[3].y;
      *q = 2;

      q = (short*) &a[2].y;
      *q = 3;
}
