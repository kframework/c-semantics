#include <stddef.h>
int main(void) {
      struct s { int m; };
      return offsetof(struct s, m);
}
