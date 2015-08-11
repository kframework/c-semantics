#include<stdlib.h>
int main() {
  if (sizeof(3 / 0) != sizeof(int))
    abort();
  if (sizeof(NULL) != sizeof(void *))
    abort();
  return 0;
}
