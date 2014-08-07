struct s {
      int x;
      int y;
};

int main(void) {
      struct s s0 = {0};
      struct s s1 = {0, 1};
      struct s s2 = s1;
      return s0.x + s1.x + s2.x;
}
