#include <stddef.h>
int main(void) {
      struct s { signed int m : 5; };
      return offsetof(struct s, m);
}
