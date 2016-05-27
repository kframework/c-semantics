int f(int *x, long *y) {
      *x = 0;
      *y = 1;
      return *x;
}

int main(void) {
      union {int x; long y;} U;
      U.x = 0;
      return f(&U.x, &U.y);
}
