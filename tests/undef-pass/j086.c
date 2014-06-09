struct s { int x; } s;

int f(struct s s) {
      return 0;
}

union u { int x; } u;

int g(union u u) {
      return 0;
}

int main(void) {
      return f(s) + g(u);
}
