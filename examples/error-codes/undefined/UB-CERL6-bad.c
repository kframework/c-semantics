#include<stddef.h>

int main() {
  void *x = &x;
  if (NULL < x) {}
  return 0;
}
