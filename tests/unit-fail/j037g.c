#include <stdlib.h>

int main(void) {
      long (*p)[10] = malloc(sizeof(long) * 10);

      (*p)[1] = 42;

      (*(long long(*)[10])p)[1] = 42;

      return (*p)[1];
}
