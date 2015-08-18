int f(int a, int b) {
      return 0;
}

int main(void) {
      int x = 0;
      f(x = 0, x); f(x, x = 0);
      return 0;
}
