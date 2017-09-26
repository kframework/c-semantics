#include <errno.h>
#include <string.h>

int main(void) {
      char* err = strerror(EBADF);

      *err = 'x';
}
