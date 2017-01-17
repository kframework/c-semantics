#include <stdlib.h>

int main(void) {
      long *p = malloc(sizeof(long));

      *(long long*)p = 42;

      return *p;
}
