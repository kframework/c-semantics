int f(int a, int b) {
      return 0;
}

int main(void) {
      int x = 0;
      int y = 0;
      (x = 1) + y;
      (x = 1) / (y = 1);
      f(x = 0, y);
      ++x + y;

      return 0;
}
