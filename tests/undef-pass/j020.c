struct s s0;

struct s {
      int x;
};

enum e;
enum e e0;
enum e {x, y, z};

int a[];

int main(void) {
      struct s s1 = s0;
      enum e e1 = e0;
      a[0] = 0;
      return a[0] + e1 + s1.x;
}

int a[] = {1, 2, 3};
