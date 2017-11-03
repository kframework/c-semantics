#include <stddef.h>
enum e {
      x = offsetof(struct {int x; int y;}, y),
};

int main(void) {
      struct s {int a; int b;};
      return x != offsetof(struct s, b);
}
