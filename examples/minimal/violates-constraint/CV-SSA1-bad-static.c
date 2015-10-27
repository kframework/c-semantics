#include<assert.h>

int main() {
  int x = 5;
  static_assert(x == 5, "x should be five");
  return 0;
}
