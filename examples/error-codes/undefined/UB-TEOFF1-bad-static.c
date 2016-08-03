#include <stddef.h>
int main(void) {
      struct s { int m : 5; };
      return offsetof(struct s, m);
}
