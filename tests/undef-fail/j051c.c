#include <limits.h>

int main(void) {
      int s = sizeof(unsigned) * CHAR_BIT;

      ((unsigned)1) << s;

      return 0;
}
