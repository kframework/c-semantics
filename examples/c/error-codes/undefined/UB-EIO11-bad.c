#include <string.h>
int main(void) {
      char* err = strerror(0);
      *err = 'x';
}
