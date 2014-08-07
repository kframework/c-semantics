#include <stdlib.h>

int main(void) {
      long long *p = malloc(sizeof(long long));

      *p = 5;

      *p = *(short*)p;

      return 0;
}
