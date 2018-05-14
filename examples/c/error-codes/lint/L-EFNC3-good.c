static int f(int);

int g(int x) {
      if (x) return f(x);
      return 0;
}

int f(int x) {
      return g(!x);
}

int main(void) {
      return f(1);
}
