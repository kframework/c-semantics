int f(int a, int b) {
      return 0;
}

int foo (int *p1, int *p2) {
      return (*p1)++ + (*p2)++;
}

int main(void) {
      int x = 0;
      int y = 0;
      (x = 1) + y;
      x + (y = 1);
      (x = 1) / (y = 1);
      f(x = 0, y);
      ++x + y;

      "hi0"[0] + x++;
      "hi1"[0] + x++ + "hi2"[0];

      foo (&x, &y);

      return 0;
}
