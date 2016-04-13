#include<stddef.h>

int main() {
  void *x = &x;
  if (x != NULL) {}
  return 0;
}
