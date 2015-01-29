struct s;

int f(struct s s) {
      return 0;
}

struct s { int x; } s;

int main(void) {
      return f(s);
}
