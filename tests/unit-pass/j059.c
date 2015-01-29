struct s { int x; };
union u { int x; int y; };

typedef int arr[];
typedef struct s s;
typedef union u u;

int main(void) {
      int a[] = {0};
      struct s b;
      union u c;
      struct s d = {0};
      union u e = {0};

      arr f = {0}, g = {0, 1};
      s h;
      u i;
      return 0;
}
