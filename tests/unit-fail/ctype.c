#include <ctype.h>

int main() {
      for (int c = -2; c != 257; ++c) {
            unsigned x = 0;

            x |= (_Bool) isalnum(c)  << 0;
            x |= (_Bool) isalpha(c)  << 1;
            x |= (_Bool) iscntrl(c)  << 2;
            x |= (_Bool) isdigit(c)  << 3;
            x |= (_Bool) isgraph(c)  << 4;
            x |= (_Bool) islower(c)  << 5;
            x |= (_Bool) isprint(c)  << 6;
            x |= (_Bool) ispunct(c)  << 7;
            x |= (_Bool) isspace(c)  << 8;
            x |= (_Bool) isupper(c)  << 9;
            x |= (_Bool) isxdigit(c) << 10;
      }
}
