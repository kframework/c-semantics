#include <string.h>
#include <stdlib.h>

void* memset(void* dest, int value, size_t len) {
      unsigned char *ptr = (unsigned char*)dest;
      while (len-- > 0) {
            *ptr++ = value;
      }
      return dest;
}
