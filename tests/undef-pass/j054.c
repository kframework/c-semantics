#include <stdlib.h>

struct big_type {
      int arr[32];
};
union u {
      struct s1 { long long c; struct big_type bt1; } sub1;
      struct s1 { long long x; struct big_type bt2; } sub1;
} obj;

int main(void) {
      obj.sub2.bt2 = obj.sub1.bt1;

      long long *p = malloc(sizeof(long long));

      *p = 5;

      *p = *(long long*)p;

      return 0;
}
