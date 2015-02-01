#include <limits.h>

int main(void) {
      unsigned s = 1;

      1 << s;
      1 >> s;

      s = sizeof(unsigned) * CHAR_BIT - 1;

      ((unsigned)1) << s;
      1 >> s;

      return 0;

}
