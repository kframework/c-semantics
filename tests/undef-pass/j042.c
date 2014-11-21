_Atomic struct s {
      int x;
} s = { 0 };

_Atomic union u {
      int x;
} u = { 0 };

int main(void) {
      struct s t = s;
      union u v = u;
      return 0;
}

