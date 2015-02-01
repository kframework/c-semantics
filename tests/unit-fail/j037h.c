#include <stdlib.h>

int main(void) {
      int *p = malloc(sizeof(int));

      *(long*)p = 42;

      return *p;
}
