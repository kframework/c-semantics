#include<stdlib.h>
int main() {
  if (sizeof(3 / 0) != sizeof(int))
    abort();
  if (sizeof(NULL) != sizeof(void *))
    abort();
  if (sizeof(+ 5.0) != sizeof(double))
    abort();
  return 0;
}
