int main(void) {
      struct s { int m : 5; } t;
      &t.m;
}
