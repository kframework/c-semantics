#include <limits.h>
#include <stdlib.h>

int main(void) {
  void *ptr0 = malloc(ULONG_MAX);
  if (ptr0 != NULL) {
    abort();
  }
}
