#include<stdlib.h>
int main() {
  if (sizeof(3 / 0) != sizeof(int))
    abort();
  if (sizeof(NULL) != sizeof(void *))
    abort();
  if (sizeof(+ 5.0) != sizeof(double))
    abort();
  if (sizeof(sizeof(int)) != sizeof(size_t))
    abort();
  if (sizeof(sizeof(5)) != sizeof(size_t))
    abort();
  return 0;
}
