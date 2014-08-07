union u;

int f(union u u) {
      return 0;
}

union u { int x; } u;

int main(void) {
      return f(u);
}
