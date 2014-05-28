#include <stdlib.h>

int main(void) {
      int (*p)[10] = malloc(sizeof(int) * 10);

      (*p)[1] = 42;

      (*(long(*)[3])p)[1] = 42;
      
      (*p)[1];
}
