_Atomic struct s {
      int x;
} s;

_Atomic union u {
      int x;
} u;

int main(void) {
      struct s t = s;
      union u v = u;
      return 0;
}

