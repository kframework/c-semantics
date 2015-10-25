#include<assert.h>

enum {
  x = 5
};

int main() {
  static_assert(x == 5, "x should be five");
  return 0;
}
