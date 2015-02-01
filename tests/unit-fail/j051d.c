#include <limits.h>

int main(void) {
      int s = sizeof(int) * CHAR_BIT;

      1 >> s;

      return 0;
}
