#include <stdlib.h>

int main(void) {
      int (*p)[10] = malloc(sizeof(int) * 10);

      (*p)[1] = 42;

      (*(long(*)[10])p)[1] = 42;

      return (*p)[1];
}
